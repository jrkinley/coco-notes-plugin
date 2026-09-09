# Artefacts

Reusable technical assets: flow definitions, configs, scripts, templates. Things you built once and
expect to reach for again.

Group by the tool or platform they belong to, then by what they are:

```
artefacts/
  openflow/
    jdbc-full-refresh/
      README.md              What it does, what it assumes, how to use it
      jdbc-full-refresh.json
```

Every artefact gets a README saying what it does and what it assumes. An exported JSON file with no
explanation is not reusable, it is just a file you are afraid to delete.

This is for things you made. Third-party reading goes in `reference/`.
