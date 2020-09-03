#!/bin/bash

set -ueo pipefail

log_success() { echo -e "\033[0m\033[1;92m${*}\033[0m"; }

current_tag=$(git describe --tags "$(git rev-list --tags --max-count=1)")

read -p "Tag [patch]? " -r new_tag

here=$(pwd)

tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)

cd "${tmp_dir:?}"

npm init -y 1>/dev/null 2>&1
git init
npm version "${current_tag:?}"
npm version "${new_tag:-patch}"
new_tag=$(git describe --tag)

cd "${here:?}"

git tag "${new_tag:?}"

log_success "created git tag ${new_tag:?}"

git push origin main
git push origin main --tags

log_success "pushed new tag"
