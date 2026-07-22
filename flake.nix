{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    {
      # deadnix: skip
      self,
      nixpkgs,
    }:
    let
      system = "x86_64-linux";
      pkgs = import "${nixpkgs}" { inherit system; };

      reproduce = builtins.derivation {
        name = "reproduce";
        inherit system;

        builder = "${pkgs.bash}/bin/bash";
        args = [
          "-c"
          ''
            if ${pkgs.curl}/bin/curl https://www.speedtest.net/; then
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
