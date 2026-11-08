# pnpm minimum release age

Setup is in the [repo README](../README.md). Commands below start at the repo root.

Say: this is a different project. It depends on `@demo/cooldown-library` with `^1.0.0`. `1.0.0` has been in the registry since setup. A new version just came out. Let's see which one gets installed.

`minimumReleaseAge` is minutes. pnpm 12 defaults to `1440` (1 day). This project sets `0` in `pnpm-release-age/app/pnpm-workspace.yaml`, so the first install takes the newest match. The setting applies to every dependency pnpm resolves. Here the dependency is direct, so the choice is visible in one `package.json`.

**Before you start:** `1.0.0` has to be at least 10 minutes old, and `1.0.1` brand new. `prepare_demo.sh` republishes `1.0.0`. If that publish is younger than 10 minutes, no version qualifies. pnpm exits with `ERR_PNPM_NO_MATURE_MATCHING_VERSION`. A terminal may offer to approve the young version. Do not approve it.

1. **Publish the new version.** In `pnpm-release-age/library/package.json`, set:

   ```json
   "version": "1.0.1"
   ```

   ```bash
   cd pnpm-release-age/library
   npm publish --registry http://localhost:4873
   ```

2. **Install with the gate off.** `pnpm-workspace.yaml` still says `minimumReleaseAge: 0`.

   ```bash
   cd pnpm-release-age/app
   rm -rf node_modules pnpm-lock.yaml
   pnpm install
   pnpm ls @demo/cooldown-library
   ```

   You should see `@demo/cooldown-library@1.0.1`.

3. **Turn the gate on.** In `pnpm-release-age/app/pnpm-workspace.yaml`, set:

   ```yaml
   minimumReleaseAge: 10
   ```

   Reinstall:

   ```bash
   cd pnpm-release-age/app
   rm -rf node_modules pnpm-lock.yaml
   pnpm install
   pnpm ls @demo/cooldown-library
   ```

   `1.0.1` is skipped. You should see `@demo/cooldown-library@1.0.0`.
