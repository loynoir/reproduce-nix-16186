ARG substituter=

FROM public.ecr.aws/docker/library/archlinux:latest@sha256:592e11bd99ab579f933a0cb77a8f66e2f3ae57f5eafacf13aea44a6e98ef21ae

RUN \
  pacman-key --init \
  && pacman --noconfirm -Sy archlinux-keyring \
  && pacman --noconfirm -Syu nix

COPY ./flake.nix ./flake.lock /tmp/reproduce/

RUN \
  nix \
    --extra-experimental-features nix-command \
    --extra-experimental-features flakes \
    run \
    --option substituters "${substituter} https://cache.nixos.org/" \
    --option trusted-public-keys 'cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=' \
    --print-build-logs \
    --verbose \
    --show-trace \
    /tmp/reproduce/
