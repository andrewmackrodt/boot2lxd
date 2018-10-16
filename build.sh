#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

cd "$(dirname "${BASH_SOURCE[0]}")"

echo "Emptying build folder" >&2
find build -mindepth 1 -maxdepth 1 -type d -not -name boxes -exec rm -rf {} \;
find build -maxdepth 1 -type f -not -name .gitignore -exec rm -f {} \;
mkdir -p build/files build/templates

# copy .dist files if the target doesn't exist
for f in $(find . -maxdepth 1 -type f -name '*.dist'); do
    src=${f:2}
    dst=${src::${#src}-5}
    if [[ ! -f "$dst" ]]; then
        echo "Copying $src to $dst" >&2
        cp "$src" "$dst"
    fi
done

if [[ ! -f files/insecure_private_key ]]; then
    echo "Generating boot2lxd insecure_private_key" >&2
    ssh-keygen -t rsa -N '' -f files/insecure_private_key >/dev/null
    # delete the public key, regenerate it during the build
    rm files/insecure_private_key.pub
fi

# copy files to build folder
echo "Copying files" >&2
cp -r files build
grep -E '^[A-Z][A-Z0-9_]*=' .env > build/.env
echo "BOOT2LXD_PUBLIC_KEY='$(ssh-keygen -y -f files/insecure_private_key | head -n1) boot2lxd insecure private key'" >> build/.env

# source environment file
. build/.env

# generate templates after variable substitution - fragile!
echo "Generating templates" >&2
vars=$(sed -E 's/^([^=]+)=.*/\1/' build/.env)
for f in $(find templates -type f); do
    contents=$(cat "$f")
    for var in $vars; do
        contents=$(echo "$contents" | sed -E "s#\{\{ $var \}\}#${!var}#gI")
    done
    echo "$contents" > "build/$f"
done

# detect the ubuntu point release if not specified
if [[ "${OS_VERSION:-}" == "" ]]; then
    echo -n "Detecting $OS_CODENAME release " >&2
    OS_VERSION=$(curl -s "$OS_BASEPATH/SHA256SUMS" | grep 'server-amd64' | sed -E 's/.+?ubuntu-(.+?)-server-amd64.+/\1/' | tail -n1)
    echo "$OS_VERSION" >&2
    echo "OS_VERSION=$OS_VERSION" >> build/.env
    vars=$vars$'\n'OS_VERSION
fi

# construct packer -var arguments - fragile!
packer_vars=()
for var in $vars; do
    packer_var=$(echo "$var" | tr '[:upper:]' '[:lower:]')
    packer_vars+=("-var")
    packer_vars+=("$packer_var=${!var}")
done

echo "Starting build" >&2
packer build -on-error=ask "${packer_vars[@]}" boot2lxd.json
