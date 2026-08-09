#!/bin/sh
# shellcheck shell=bash
# shellcheck disable=SC2251

set -euo pipefail

assert_logfile_ok() {
  local logfile="${1:?}"

  # strip docker log prefix `(#\d+ |)\d+(\.\d+ |)`
  declare -r STRIP_DOCKER_LOG_PREFIX='s@^(#[0-9]+ |)[0-9]+(\.[0-9]+ |)@@g'

  if ! grep -C 1 -F 'OK: network=offline' "${logfile:?}" | sed -re "${STRIP_DOCKER_LOG_PREFIX:?}"; then
    # pretty log
    # remove docker log prefix
    # remove anti pattern
    # print lines after last line contains pattern X
    # print lines before first line contains pattern Y
    # make hash path pretty
    sed -re "${STRIP_DOCKER_LOG_PREFIX:?}" "${logfile:?}" \
      | grep -v 'Error: building at STEP' \
      | awk '/copying|downloading|building|\[[0-9]+\/[0-9]+\] RUN/{buf="";next}{buf=buf $0 ORS}END{printf "%s",buf}' \
      | awk '/---/{exit} 1' \
      | sed -r 's@/nix/store/[a-zA-Z0-9]{32}@/nix/store/XXX@g'

    echo test failed
    exit 42
  fi
}

normal_run_flake() {
  local logfile
  logfile=$(mktemp --dry-run ./log/reproduce.XXXXXXXXXX)

  mkdir -p ./log

  {
    # deal with prevent caching err exit
    ! nix \
      --extra-experimental-features nix-command \
      --extra-experimental-features flakes \
      run \
      --option substituters "${SUBSTITUTERS} https://cache.nixos.org/" \
      --option trusted-public-keys 'cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=' \
      --option sandbox-fallback false \
      --print-build-logs \
      --verbose \
      --show-trace \
      .
  } >"${logfile:?}" 2>&1

  assert_logfile_ok "${logfile}"
}

within_container_run_flake() {
  local logfile
  logfile=$(mktemp --dry-run ./log/reproduce.XXXXXXXXXX)

  mkdir -p ./log

  {
    # deal with prevent caching err exit
    ! "${engine:?}" buildx build \
      --progress plain \
      --build-arg LAUNCHER= \
      --build-arg SUBSTITUTERS="${SUBSTITUTERS}" \
      --build-arg EXTRA= \
      .
  } >"${logfile:?}" 2>&1

  assert_logfile_ok "${logfile}"
}

within_container_run_flake_without_fallback() {
  local logfile
  logfile=$(mktemp --dry-run ./log/reproduce.XXXXXXXXXX)

  mkdir -p ./log

  {
    # deal with prevent caching err exit
    ! "${engine:?}" buildx build \
      --progress plain \
      --build-arg LAUNCHER= \
      --build-arg SUBSTITUTERS="${SUBSTITUTERS}" \
      --build-arg EXTRA='--option sandbox-fallback false' \
      .
  } >"${logfile:?}" 2>&1

  assert_logfile_ok "${logfile}"
}

within_container_unshare_run_flake_without_fallback() {
  local logfile
  logfile=$(mktemp --dry-run ./log/reproduce.XXXXXXXXXX)

  mkdir -p ./log

  {
    # deal with prevent caching err exit
    ! "${engine:?}" buildx build \
      --progress plain \
      --build-arg LAUNCHER='unshare -Ur --map-users=all --map-groups=all' \
      --build-arg SUBSTITUTERS="${SUBSTITUTERS}" \
      --build-arg EXTRA='--option sandbox-fallback false' \
      .
  } >"${logfile:?}" 2>&1

  assert_logfile_ok "${logfile}"
}

{
  if [ -e ./.env/profile.sh ]; then
    # custom SUBSTITUTERS to use mirrors for faster reproduce
    source ./.env/profile.sh
  fi

  SUBSTITUTERS="${SUBSTITUTERS-}"

  mkdir -p ./download ./log
  if [ ! -e ./download/nixpkgs.tgz ]; then
    curl -fsSLo ./download/nixpkgs.tgz https://github.com/NixOS/nixpkgs/archive/b7c2ada94fe99c15b0dbcf4d11fd7850b957a436.tar.gz
  fi
}

case "${1-default}" in
  normal_run_flake)
    normal_run_flake
    ;;
  within_docker_run_flake)
    engine=docker within_container_run_flake
    ;;
  within_docker_run_flake_without_fallback)
    engine=docker within_container_run_flake_without_fallback
    ;;
  within_docker_unshare_run_flake_without_fallback)
    engine=docker within_container_unshare_run_flake_without_fallback
    ;;
  within_podman_run_flake)
    engine=podman within_container_run_flake
    ;;
  within_podman_run_flake_without_fallback)
    engine=podman within_container_run_flake_without_fallback
    ;;
  within_podman_unshare_run_flake_without_fallback)
    engine=podman within_container_unshare_run_flake_without_fallback
    ;;
  default)
    exit 42
    ;;
  *)
    exit 42
    ;;
esac
