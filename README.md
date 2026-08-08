# reproduce-nix-16186

https://github.com/NixOS/nix/issues/16186

## brief

`Dockerfile RUN` nix flake fail with

```console
error: this system does not support the kernel namespaces that are required for sandboxing; use '--no-sandbox' to disable sandboxing
```

Seems due to `Dockerfile RUN` environment `unshare(CLONE_NEWNS)` failure.

## TODO

1. `Dockerfile RUN` environment `unshare(CLONE_NEWNS)` failure, is this a bug?

2. How to safely allow `unshare(CLONE_NEWNS)`?

3. If impossible to safely allow `unshare(CLONE_NEWNS)`, are there safe alternatives, or safe suggestions?

## background

`nix derivation` is similar to `PKGBUILD` `build()` function + `package()` function.

`nix derivation` create chroot jail, only which have fixed hash output , able to access network.

In normal cases, `non fixed output derivation` should be offline.

But when within flake within dockerfile, `non fixed output derivation` unexpectedly able to access network.

This seems caused by nix think `Dockerfile RUN` environment lack of kernel namespaces.

```console
error: this system does not support the kernel namespaces that are required for sandboxing; use '--no-sandbox' to disable sandboxing
```

But basic namespace test seems OK.

```console
#7 [3/6] RUN ls /proc/self/ns/cgroup && echo namespace OK
#7 CACHED
```

https://github.com/NixOS/nix/issues/16186#issuecomment-5193724577

xokdvium seems suggest this is caused by `Dockerfile RUN` environment `unshare(CLONE_NEWNS)` failure.

```console
0.184 unshare(CLONE_NEWNS)                    = -1 EPERM (Operation not permitted)
11.85 clone(child_stack=0x71f6e378eff0, flags=CLONE_NEWUSER|SIGCHLD) = -1 EPERM (Operation not permitted)
11.85 munmap(0x71f6e368f000, 1048576)         = 0
11.85 mmap(NULL, 1048576, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS|MAP_STACK, -1, 0) = 0x71f6e368f000
11.85 clone(child_stack=0x71f6e378eff0, flags=CLONE_NEWNS|CLONE_NEWPID|SIGCHLD) = -1 EPERM (Operation not permitted)
```

https://github.com/opencontainers/image-spec/issues/1331#issuecomment-5199600655

Also, cyphar seems suggest `CLONE_NEWUSER` might be dangerous.

> The kernel also requires `CAP_SYS_ADMIN` for all namespaces other than `CLONE_NEWUSER` but that is explicitly blocked by container runtimes because it has led to many kernel 0days that could be used as container escapes in the past.

> Some container runtimes let you adjust the security profile for builds, others don't -- consult their documentation.

I opened QA in `moby/buildkit` and `podman-container-tools/podman`.

https://github.com/moby/buildkit/discussions/7023

https://github.com/podman-container-tools/podman/discussions/29400

I'm out of my depth here, and it remains unclear to me.

Thus I decided to raise QA to issues.

## reproduce

Given `X` is `non fixed output derivation`.

When normally run flake, `X` is not able to access network.

```console
$ ./reproduce.sh normal_run_flake
reproduce> curl: (6) Could not resolve host: www.speedtest.net
reproduce> OK: network=offline
reproduce> err exit to prevent caching
--
       > curl: (6) Could not resolve host: www.speedtest.net
       > OK: network=offline
       > err exit to prevent caching
```

When within `Dockerfile RUN` run flake, `X` is unexpectely able to access network.

```console
$ ./reproduce.sh within_docker_run_flake
reproduce> ERR: network=online
reproduce> err exit to prevent caching
error: Cannot build '/nix/store/XXX-reproduce.drv'.
       Reason: builder failed with exit code 42.
       Output paths:
         /nix/store/XXX-reproduce
test failed
```

```console
$ ./reproduce.sh within_podman_run_flake
reproduce> ERR: network=online
reproduce> err exit to prevent caching
error: Cannot build '/nix/store/XXX-reproduce.drv'.
       Reason: builder failed with exit code 42.
       Output paths:
         /nix/store/XXX-reproduce
test failed
```

When within `Dockerfile RUN` run flake, and disable sandbox fallback, `nix` complain does not support the kernel namespaces.

```console
$ ./reproduce.sh within_docker_run_flake_without_fallback
error: this system does not support the kernel namespaces that are required for sandboxing; use '--no-sandbox' to disable sandboxing
test failed
```

```console
$ ./reproduce.sh within_podman_run_flake_without_fallback
error: this system does not support the kernel namespaces that are required for sandboxing; use '--no-sandbox' to disable sandboxing
test failed
```

When within docker within `Dockerfile RUN` run flake, `unshare` fail with `Operation not permitted`.

When within podman within `Dockerfile RUN` run flake, `nix` complain does not support the kernel namespaces.

https://github.com/podman-container-tools/podman/discussions/29400#discussioncomment-17922132

```console
$ ./reproduce.sh within_docker_unshare_run_flake_without_fallback
...
unshare: unshare failed: Operation not permitted
...
```

```console
$ ./reproduce.sh within_podman_unshare_run_flake_without_fallback
error: this system does not support the kernel namespaces that are required for sandboxing; use '--no-sandbox' to disable sandboxing
test failed
```
