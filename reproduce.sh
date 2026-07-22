#!/bin/sh

set -euo pipefail

substituter="${substituter-}"

# strip docker log prefix `(#\d+ |)\d+(\.\d+ |)`
readonly STRIP_DOCKER_LOG_PREFIX='s@^(#[0-9]+ |)[0-9]+(\.[0-9]+ |)@@g'

read -p 'repdoduce normal flake' _

logfile=$(mktemp --dry-run /tmp/reproduce.XXXXXXXXXX)

{
  # deal with prevent caching err exit
  ! nix \
    --extra-experimental-features nix-command \
    --extra-experimental-features flakes \
    run \
    --option substituters "${substituter} https://cache.nixos.org/" \
    --option trusted-public-keys 'cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=' \
    --print-build-logs \
    --verbose \
    --show-trace \
    .
} >"${logfile:?}" 2>&1

grep -C 1 -F 'OK: network=offline' "${logfile:?}"

echo OK: repdoduce normal flake

echo
read -p 'repdoduce docker flake' _

{
  # deal with prevent caching err exit
  ! docker buildx build \
    --progress plain \
    --build-arg substituter="${substituter}" \
    .
} >"${logfile:?}" 2>&1

if ! grep -C 1 -F 'OK: network=offline' "${logfile:?}" | sed -re "${STRIP_DOCKER_LOG_PREFIX:?}"; then
  grep -A 1 -F 'ERR: network=online' "${logfile:?}" | sed -re "${STRIP_DOCKER_LOG_PREFIX:?}"
  echo ERR
  exit 1
fi

echo OK: repdoduce docker flake
