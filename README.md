# reproduce-nix-16186

https://github.com/NixOS/nix/issues/16186

## bug

Non fixed output derivation unexpectedly able to access network when within flake within dockerfile

## description

Non fixed output derivation is usually not able to access network.

But when within flake within dockerfile, non fixed output derivation unexpectedly able to access network.

Is this a bug?

If not, how to make non fixed output derivation not able to access network when within flake within dockerfile?

## actual

Non fixed output derivation unexpectedly able to access network when within flake within dockerfile

```console
$ ./reproduce.sh
repdoduce normal flake
reproduce> curl: (6) Could not resolve host: www.speedtest.net
reproduce> OK: network=offline
reproduce> err exit to prevent caching
--
       > curl: (6) Could not resolve host: www.speedtest.net
       > OK: network=offline
       > err exit to prevent caching
OK: repdoduce normal flake

repdoduce flake within dockerfile
reproduce> ERR: network=online
reproduce> err exit to prevent caching
--
reproduce> ERR: network=online
reproduce> err exit to prevent caching
ERR
```

## expected

Non fixed output derivation not able to access network when within flake within dockerfile

```console
$ ./reproduce.sh
repdoduce normal flake
reproduce> curl: (6) Could not resolve host: www.speedtest.net
reproduce> OK: network=offline
reproduce> err exit to prevent caching
--
       > curl: (6) Could not resolve host: www.speedtest.net
       > OK: network=offline
       > err exit to prevent caching
OK: repdoduce normal flake

repdoduce flake within dockerfile
reproduce> curl: (6) Could not resolve host: www.speedtest.net
reproduce> OK: network=offline
reproduce> err exit to prevent caching
--
       > curl: (6) Could not resolve host: www.speedtest.net
       > OK: network=offline
       > err exit to prevent caching
OK: repdoduce flake within dockerfile
```
