# npm Supply Chain Security Demo

Live demos for the talk. Four projects, one local registry. The steps for each demo are in that folder.

- [Attack](attack/README.md). You publish `@demo/some-library` and install it in `attack/app`.
- [pnpm build scripts](pnpm-scripts/README.md). The dependency already has a postinstall hook. You only install.
- [pnpm minimum release age](pnpm-release-age/README.md). You publish one new version, then install twice.
- [Enforce pnpm](enforce-pnpm/README.md). `npm install` is refused. `pnpm install` works.

Every command block in those READMEs starts at this repo root.

## Prerequisites

- Docker
- Node.js from `.nvmrc`, and npm
- pnpm, for the build-scripts, release-age, and enforce-pnpm demos

**IMPORTANT**

Comment out `ignore-scripts=true` in `$HOME/.npmrc` before the demo. Otherwise the postinstall never runs.

Comment out `min-release-age` in `$HOME/.npmrc` before the demo. A value there is in days, so a version you publish on stage is refused. pnpm 11 and 12 do not read that key. The release-age demo sets its own gate in `pnpm-workspace.yaml`.

A warning about an unset variable in your user `.npmrc` comes from that file. It is not part of the demo.

Corepack rewrites `package.json` with a `packageManager` field on the first pnpm command. Turn that off for the shell you present from:

```bash
export COREPACK_ENABLE_AUTO_PIN=0
```

## Setup

`prepare_demo.sh` puts the package files back to the committed baseline, wipes `node_modules` and lockfiles, starts Verdaccio with an empty registry, and publishes the three baseline versions.

Baselines:

- `@demo/some-library@1.1.3` — no postinstall. The attack starts here.
- `@demo/postinstall-library@1.0.0` — postinstall already in the package. Echo, then `exit 1`.
- `@demo/cooldown-library@1.0.0` — no postinstall. Has to be at least 10 minutes old before the release-age demo.

```bash
./prepare_demo.sh
```

The registry is at `http://localhost:4873`. Publish uses a fake token in each library's `.npmrc`. Verdaccio allows anonymous publish of `@demo/*`. Each app's `.npmrc` sends `@demo` installs to that registry. The enforce-pnpm demo does not use the registry.

By hand, from the repo root:

```bash
docker compose up -d
cd attack/library
npm publish --registry http://localhost:4873
cd ../../pnpm-scripts/library
npm publish --registry http://localhost:4873
cd ../../pnpm-release-age/library
npm publish --registry http://localhost:4873
cd ../..
```

## Stop and clear Verdaccio

```bash
docker compose down
```

This stops the container and keeps the packages. The named volume survives. `prepare_demo.sh` deletes that volume. To delete it by hand:

```bash
docker compose down -v
```

The next `docker compose up -d` then starts with an empty registry.
