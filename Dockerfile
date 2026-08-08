FROM public.ecr.aws/docker/library/archlinux:latest@sha256:592e11bd99ab579f933a0cb77a8f66e2f3ae57f5eafacf13aea44a6e98ef21ae

RUN \
  pacman-key --init \
  && pacman --noconfirm -Sy archlinux-keyring \
  && pacman --noconfirm -Syu nix

RUN ls /proc/self/ns/cgroup && echo namespace OK

COPY ./flake.nix /tmp/reproduce/
COPY ./generated/ /tmp/reproduce/generated/

ARG LAUNCHER=
ARG SUBSTITUTERS=
ARG EXTRA=

RUN \
  ${LAUNCHER} \
  nix \
    --extra-experimental-features nix-command \
    --extra-experimental-features flakes \
    run \
    --option substituters "${SUBSTITUTERS} https://cache.nixos.org/" \
    --option trusted-public-keys 'cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=' \
    ${EXTRA} \
    --print-build-logs \
    --verbose \
    --show-trace \
    /tmp/reproduce/
