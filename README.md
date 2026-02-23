# npm Supply Chain Security Demo

A minimal local demo of a supply chain attack: a victim project depends on `@demo/some-library` with version range `1.1.x`. You play the attacker, publish a malicious 1.1.4 with a `postinstall` script to a local registry, then run `npm install` in the victim project so 1.1.4 is installed and the script runs.

## Prerequisites

- Docker (and Docker Compose)
- Node.js and npm

## Setup

1. **Start the local registry (Verdaccio)**

   ```bash
   docker compose up -d
   ```

   The registry will be at `http://localhost:4873`.

2. **Publish the benign version (1.1.3)**

   From the repo root:

   ```bash
   cd some-library
   npm publish --registry http://localhost:4873
   cd ..
   ```

   Publishing uses the local registry and a fake auth token (see `some-library/.npmrc`); the Verdaccio config allows anonymous publish so the token is not validated.

3. **Install in the victim project**

   ```bash
   cd example-project
   npm install
   ```

   You should get `@demo/some-library@1.1.3` (no postinstall).

## Demo: “Attack” and install malicious 1.1.4

1. **Play attacker**: edit `some-library/package.json`:
   - Set `"version": "1.1.4"`.
   - Add a `postinstall` script, e.g.:
     ```json
     "scripts": {
       "postinstall": "node -e \"console.log('Malicious postinstall ran!')\""
     }
     ```

2. **Publish the malicious version**

   ```bash
   cd some-library
   npm publish --registry http://localhost:4873
   cd ..
   ```

3. **In the victim project, reinstall**

   ```bash
   cd example-project
   rm -rf node_modules package-lock.json
   npm install
   ```

   npm resolves `1.1.x` to 1.1.4 from the local registry and runs the malicious `postinstall`.

## Layout

- **`example-project/`** – Victim app; depends on `@demo/some-library` with range `1.1.x`, uses `.npmrc` so the `@demo` scope points at the local registry.
- **`some-library/`** – The package you control; publish as 1.1.3 (benign) then 1.1.4 (malicious postinstall) to Verdaccio.
- **`docker-compose.yml`** – Runs Verdaccio on port 4873.

## Stop Verdaccio

```bash
docker compose down
```

This stops the container but **does not** clear the registry: package data lives in a named volume and persists. To **clear the registry** (e.g. for a fresh demo), remove the volumes as well:

```bash
docker compose down -v
```

The next `docker compose up -d` will then start with an empty registry.
