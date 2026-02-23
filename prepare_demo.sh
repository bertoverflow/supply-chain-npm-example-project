#!/usr/bin/env bash

# delete old npm packages
docker compose down -v

docker compose up -d

rm -rf example-project/node_modules
rm -rf example-project/package-lock.json
rm -rf some-library/node_modules
rm -rf some-library/package-lock.json
rm -rf some-other-library/node_modules
rm -rf some-other-library/package-lock.json

cd some-library
npm publish --registry http://localhost:4873

cd ../some-other-library
npm publish --registry http://localhost:4873
