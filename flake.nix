{
  # inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    {
      # deadnix: skip
      self,
    }:
    let
      system = "x86_64-linux";

      # use local tarball for faster reproduce
      nixpkgs = builtins.fetchTarball {
        url = "./generated/nixpkgs.tgz";
        sha256 = "208b6b75becfba4d3946a3815996050b95fa5a5d6c26609f879316547c3988c3";
      };

      pkgs = import "${nixpkgs}" { inherit system; };

      reproduce = builtins.derivation {
        name = "reproduce";
        inherit system;

        builder = "${pkgs.bash}/bin/bash";
        args = [
          "-c"
          ''
            if ${pkgs.curl}/bin/curl -fsSL --connect-timeout 5 https://www.speedtest.net/ >/dev/null; then
              echo ERR: network=online
            else
              echo OK: network=offline
            fi

            echo err exit to prevent caching
            exit 42
          ''
        ];
      };
    in
    {
      packages.${system}.default = reproduce;
    };
}
