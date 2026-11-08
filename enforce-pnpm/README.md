# Enforce pnpm

Setup is in the [repo README](../README.md). Commands below start at the repo root.

Say: this project refuses npm. The engines field asks for pnpm.

`enforce-pnpm/app` is not published. Open `package.json` and show `engines`, then `.npmrc` with `engine-strict=true`.

```json
"engines": {
  "npm": "please-use-pnpm",
  "yarn": "please-use-pnpm",
  "bun": "please-use-pnpm",
  "pnpm": ">=10.26.0"
}
```

`please-use-pnpm` matches no real version of npm, yarn, or bun. `engine-strict=true` turns that mismatch into an error.

1. Install with npm. It fails.

   ```bash
   cd enforce-pnpm/app
   npm install
   ```

   npm exits with `EBADENGINE`. The message lists the required engines and the npm version you actually ran.

2. Install with pnpm. It works.

   ```bash
   cd enforce-pnpm/app
   pnpm install
   ```

   pnpm 10.26.0 or newer satisfies `engines.pnpm`, so the install finishes.
