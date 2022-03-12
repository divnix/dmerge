{
  description = "Bitte Cells development shell";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.devshell.url = "github:numtide/devshell";
  inputs.alejandra.url = "github:kamadorueda/alejandra";
  inputs.alejandra.inputs.treefmt.url = "github:divnix/blank";
  inputs.std.url = "github:divnix/std";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = inputs:
    inputs.flake-utils.lib.eachSystem ["x86_64-linux" "x86_64-darwin"] (
      system: let
        inherit
          (inputs.std.deSystemize system inputs)
          main
          devshell
          nixpkgs
          alejandra
          treefmt
          ;
      in {
        devShells.default = devshell.legacyPackages.mkShell {
          name = "Data Merge";
          commands = [{package = nixpkgs.legacyPackages.treefmt;}];
          packages = [
            alejandra.defaultPackage
            nixpkgs.legacyPackages.shfmt
            nixpkgs.legacyPackages.nodePackages.prettier
            nixpkgs.legacyPackages.nodePackages.prettier-plugin-toml
            nixpkgs.legacyPackages.python3Packages.black
          ];
          devshell.startup.nodejs-setuphook = nixpkgs.lib.stringsWithDeps.noDepEntry ''
            export NODE_PATH=${
              nixpkgs.legacyPackages.nodePackages.prettier-plugin-toml
            }/lib/node_modules:$NODE_PATH
          '';
        };
      }
    );
}
