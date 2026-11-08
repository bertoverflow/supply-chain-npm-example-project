# pnpm build scripts

Setup is in the [repo README](../README.md). Commands below start at the repo root.

Say: this is a different project. It has a dependency with a postinstall hook. Let's see what happens when we install.

`pnpm-scripts/app` depends on `@demo/postinstall-library@1.0.0`. The hook is already in the published package. Open `pnpm-scripts/library/package.json` and show it. There is nothing to publish.

```json
"postinstall": "echo 'This is a malicious postinstall script!' && exit 1"
```

`pnpm-scripts/app/pnpm-workspace.yaml` sets `minimumReleaseAge: 0`. pnpm 12 otherwise waits one day, and a package published during setup would show up as a release-age exception. That is the next demo.

1. Install with pnpm.

   ```bash
   cd pnpm-scripts/app
   pnpm install
   ```

   pnpm exits with `ERR_PNPM_IGNORED_BUILDS`. The package is installed. The hook did not run. `strictDepBuilds` defaults to true. In a terminal, pnpm also writes a placeholder into `pnpm-scripts/app/pnpm-workspace.yaml`:

   ```yaml
   allowBuilds:
     '@demo/postinstall-library': set this to true or false
   ```

2. Approve that package. Naming it skips the checkbox UI. The command sets the placeholder to `true` and runs the hook immediately.

   ```bash
   cd pnpm-scripts/app
   pnpm approve-builds @demo/postinstall-library
   ```

   The room sees the echo, then the failure on `exit 1`. That failure is the moment to show.
