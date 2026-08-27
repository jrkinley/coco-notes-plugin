---
name: slides-deploy
description: "Deploy a static HTML deck (or any static site/app) to Snowflake, via either a self-contained container on Snowpark Container Services (nginx) or Snowflake App Runtime. Asks which method to use, checks permissions first, then deploys and updates in place without changing the URL. Use when: hosting an HTML deck on Snowflake, deploying slides to SPCS or App Runtime, publishing a site to Snowflake, updating a deployed deck, granting viewers access, fixing ERROR_FORBIDDEN. Triggers: deploy to SPCS, App Runtime, snow app deploy, host on Snowflake, deploy slides, deploy deck, Snowpark Container Services, nginx on Snowflake, ALTER SERVICE, endpoint access, ERROR_FORBIDDEN."
---

# Deploy Slides to Snowflake

Host a finished deck (`index.html` + `assets/`, incl. images and audio) on Snowflake so colleagues or customers can open it in a browser. Pairs with `slides-build` (the deck) and `slides-narrate` (the audio).

There are **two deployment methods**. This skill supports both; ask the user which they want, then follow that path. **Always run the permissions check for the chosen path first, and stop if the user cannot complete the deploy.**

## Choosing a method

| | Container on SPCS | Snowflake App Runtime |
| --- | --- | --- |
| What it is | Package the HTML, assets, audio and an `nginx` config into a Docker image and run it as an SPCS **service** on a compute pool. | `snow app deploy` uploads your project; Snowflake builds and runs it as an **Application Service**. No Docker, no compute pool to manage. |
| Best when | You have raw SPCS permissions (compute pool, image repo, CREATE SERVICE, BIND SERVICE ENDPOINT) and want a fully self-contained artifact you control. | You have an App Runtime deploy role (or account-admin setup is done) and prefer not to manage Docker or a compute pool. |
| Serves static HTML? | Yes, natively via nginx. | App Runtime is Node.js-focused (Next.js). A pure static deck needs a tiny Node static-file server wrapper (see that path). |
| Trade-off | You own the Dockerfile, build, and image push. Most control, most steps. | Snowflake owns build and infra. Fewer steps, but Node wrapper needed for static content, and sharing requires shared deploy defaults. |

The author chose the **container** path for the AstraZeneca deck: it is self-contained, and the available Snowhouse permissions allowed deploying a container to a compute pool. Someone with App Runtime permissions who would rather avoid Docker may prefer the **App Runtime** path. Neither is universally correct; it depends on the user's permissions and preference.

**Deploy and any git commit are gated on explicit user approval.** Do not deploy or commit without it.

## Step 0: Ask which method

Use the question tool. Present the two options with the trade-offs above, and let the user choose. Then go to that path's permission check.

---

# Path A: Container on SPCS (nginx)

An `nginx:alpine` container serves the deck on port 8080; a public SPCS endpoint gives a shareable HTTPS URL (behind the account's SSO).

## A1: Permission check (do this first, stop if not met)

The deploying role needs all of these. Verify before building anything; if any are missing, present exactly what is missing and **stop**, since a partial deploy wastes a build and leaves broken state.

Required:
- **Docker** running locally and the **`snow` CLI** with a connection to the target account (`<conn>`).
- **USAGE on a compute pool** to run the service.
- **An image repository** you can push to (READ/WRITE), or CREATE privilege to make one.
- **CREATE SERVICE** on the target schema.
- **BIND SERVICE ENDPOINT** (account-level) to expose a public endpoint.

Check with:
```sql
USE ROLE <role>;
SHOW GRANTS TO ROLE <role>;                 -- look for BIND SERVICE ENDPOINT, CREATE SERVICE, pool/repo usage
SHOW COMPUTE POOLS;                          -- a pool you have USAGE on, ideally ACTIVE
SHOW IMAGE REPOSITORIES IN SCHEMA <db>.<schema>;
```
If the role lacks any of these and cannot be granted them, stop and explain. Do not proceed on a "maybe".

## A2: Build files

Three files live beside `index.html`. Templates ship with this skill at `${CORTEX_PLUGIN_ROOT}/skills/slides-deploy/assets/`, and are always read through that prefix. The `assets/` the `Dockerfile` copies is the deck's own folder, which is why that one stays bare.
- `Dockerfile`: nginx:alpine, copies `index.html` and the deck's `assets/`, exposes 8080.
- `nginx.conf`: serves on 8080 **and answers `/healthcheck` with 200**. The SPCS readiness probe hits `/healthcheck`; without it the service never becomes READY.
- `.dockerignore`: keeps `.DS_Store`, `tools/`, zips, `Dockerfile`, and `.dockerignore` itself out of the image. Do not add `nginx.conf` to it: the `Dockerfile` copies that file, so excluding it fails the build.

Copy all three into the deck directory before building.

## A3: Build the amd64 image

SPCS runs amd64; build for that platform explicitly. `--provenance=false` avoids a multi-arch manifest the registry rejects.
```bash
cd <deck-dir>
docker build --provenance=false --platform linux/amd64 -t <image>:latest .
```

## A4: Push to the Snowflake image registry

```bash
snow spcs image-registry login -c <conn>
REG=<account>.registry.snowflakecomputing.com/<db>/<schema>/images/<image>:latest
docker tag <image>:latest "$REG"
docker push "$REG"
```
Registry host is lowercase; the repo path is case-sensitive.

## A5: Create or update the service

**Updating an existing service?** First capture the live spec so you reuse the exact container/endpoint names and probe, then change only the image:
```sql
DESCRIBE SERVICE <db>.<schema>.<service>;   -- copy the spec, note container/endpoint names + /healthcheck
```

**First-time create:**
```sql
USE ROLE <role>;
CREATE SERVICE <db>.<schema>.<service>
  IN COMPUTE POOL <pool>
  FROM SPECIFICATION $$
spec:
  containers:
  - name: "web"
    image: "<account>.registry.snowflakecomputing.com/<db>/<schema>/images/<image>:latest"
    readinessProbe:
      port: 8080
      path: "/healthcheck"
    resources:
      limits: { memory: "512M", cpu: "0.5" }
      requests: { memory: "256M", cpu: "0.25" }
  endpoints:
  - name: "web"
    port: 8080
    public: true
$$
  MIN_INSTANCES = 1
  MAX_INSTANCES = 1;
```

**Update in place (the common case).** Rebuild and push (A3 to A4), then `ALTER SERVICE` with the same spec. **Never drop and recreate**: that changes the public URL and breaks shared links.
```sql
USE ROLE <role>;
ALTER SERVICE <db>.<schema>.<service> FROM SPECIFICATION $$
<same spec>
$$;
```
`:latest` resolves to the newly pushed digest at apply time.

## A6: Verify and get the URL

The service takes a few seconds to roll to the new image. Wait, then poll:
```sql
SELECT SYSTEM$GET_SERVICE_STATUS('<db>.<schema>.<service>');  -- expect "status":"READY", restartCount 0, new image
SHOW ENDPOINTS IN SERVICE <db>.<schema>.<service>;            -- ingress_url
```
The endpoint sits behind the account's SSO. Do not authenticate on anyone's behalf. Endpoints may cache; a hard refresh helps after a redeploy.

## A7: Grant viewers access

A public SPCS endpoint still requires the `ALL_ENDPOINTS_USAGE` service role. `USAGE ON SERVICE` is not enough. Grant to a role each viewer holds, or `PUBLIC` for all account users:
```sql
USE ROLE <role>;
GRANT USAGE ON SCHEMA <db>.<schema> TO ROLE <target>;
GRANT SERVICE ROLE <db>.<schema>.<service>!ALL_ENDPOINTS_USAGE TO ROLE <target>;
-- Only if the service owner can grant it and viewers lack DB usage:
GRANT USAGE ON DATABASE <db> TO ROLE <target>;
```
Verify: `SHOW GRANTS OF SERVICE ROLE <db>.<schema>.<service>!ALL_ENDPOINTS_USAGE;`
Viewers must be users in the same Snowflake account.

## Path A troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| Service never READY | `/healthcheck` 404s | Ensure `nginx.conf` returns 200 on `/healthcheck` |
| Image not found | Wrong path/case | Use exact `/<db>/<schema>/images/<image>:latest` |
| Auth error on push | Expired login | Re-run `snow spcs image-registry login -c <conn>` |
| `ERROR_FORBIDDEN` in browser | Viewer role lacks endpoint grant | Grant `ALL_ENDPOINTS_USAGE` (A7) |
| Grant "insufficient privileges" on DATABASE | Role does not own the DB | Viewer likely already has DB usage; grant schema + endpoint role only |

```sql
SELECT SYSTEM$GET_SERVICE_LOGS('<db>.<schema>.<service>', 0, 'web');  -- container logs
```

---

# Path B: Snowflake App Runtime

`snow app deploy` uploads the project, Snowflake builds it remotely, and runs it as an Application Service at a stable `*.snowflakecomputing.app` URL (listens on port 8080, TLS terminated by Snowflake). No Docker, no compute pool provisioning.

Docs: https://docs.snowflake.com/en/developer-guide/snowflake-app-runtime/about-snowflake-app-runtime

## B1: Permission check (do this first, stop if not met)

App Runtime is designed for **Node.js** apps (Next.js). A static HTML deck must be wrapped in a minimal Node static-file server (see B2).

Required, depending on how the user wants to share:
- **`snow` CLI** with App Runtime support and a connection to the account.
- **A deploy role selected during account-administrator setup**, so deploys land in a **shared** database/schema you can grant to others. Without setup, `snow app deploy` targets your **personal database**, which **cannot be shared** with colleagues. Since the goal here is to share the deck, personal-database deploy usually fails the requirement: flag this and stop unless the user only needs it for themselves.
- If creating the service with SQL directly, **CREATE APPLICATION SERVICE** on the target schema.

Confirm account-admin setup is done (shared deploy defaults exist) and the current role is a valid deploy role. If not, present what is missing (typically: run account-administrator setup, or obtain a deploy role) and **stop**.

## B2: Wrap the static deck for Node

App Runtime builds Node projects, so add a tiny static server around the deck:
- `package.json` with a `start` script serving the folder on port 8080 (e.g. using the `serve` package or a 10-line Express/`http` server that serves `index.html` and `assets/`).
- Keep `index.html` and `assets/` as-is.
- `app.yml` install/build/run commands (or rely on auto-detection); `snowflake.yml` from `snow app setup` for upload paths and deploy destination.

The container listens on **port 8080** and users reach it over HTTPS at the app URL.

## B3: Set up and deploy

```bash
snow app setup     # generates snowflake.yml; pick the shared deploy destination
snow app deploy    # upload -> remote build -> create/upgrade Application Service; returns the live URL
```
Phase flags `--upload-only`, `--build-only`, `--deploy-only` let you retry a single failed phase. Later deploys upgrade the same service; the URL does not change.

## B4: Verify, share, operate

- The live URL is returned by `snow app deploy`.
- Status and logs: `SYSTEM$GET_APPLICATION_SERVICE_LOGS`, and see Observability for App Runtime.
- Share and operate via Application Service privileges: **USAGE** (access public endpoints), **MONITOR** (status/logs), **OPERATE** (suspend/resume/upgrade). Grant these to the roles that need them (see Access control for Snowflake App Runtime).

## Path B notes

- Public preview builds Node.js/Next.js; Python is planned. A static deck works via the Node wrapper in B2.
- Build egress is limited to npm and Google Fonts by default; a static deck typically needs nothing more.
- For team sharing, account-administrator setup must be complete so the deploy destination is a shared schema you can grant on.

---

## Output

A running deck on Snowflake with a stable HTTPS URL and viewer access configured, via whichever path the user chose. For Path A, optionally commit the build files (`Dockerfile`, `nginx.conf`, `.dockerignore`) so redeploys from a clean checkout are repeatable.
