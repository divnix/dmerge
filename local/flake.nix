{
  description = "Data Merge development shell";
  inputs.nosys.url = "github:divnix/nosys";
  inputs.namaka.url = "github:nix-community/namaka/v0.2.0";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.devshell.url = "github:numtide/devshell";
  inputs.call-flake.url = "github:divnix/call-flake";
  outputs = inputs @ {
    nosys,
    call-flake,
    ...
  }:
    nosys ((call-flake ../.).inputs // inputs) (
      {
        self,
        namaka,
        nixpkgs,
        devshell,
        ...
      }:
        with nixpkgs.legacyPackages;
        with nixpkgs.legacyPackages.nodePackages;
        with devshell.legacyPackages; let
          inherit (lib.stringsWithDeps) noDepEntry;
          checkMod = {
            commands = [{package = treefmt;}];
            packages = [alejandra shfmt nodePackages.prettier nodePackages.prettier-plugin-toml];
            devshell.startup.nodejs-setuphook = noDepEntry ''
              export NODE_PATH=${nodePackages.prettier-plugin-toml}/lib/node_modules:$NODE_PATH
            '';
          };
        in {
          devShells = {
            check = mkShell {
              name = "Data Merge (Check)";
              imports = [checkMod];
            };
            default = mkShell {
              name = "Data Merge";
              imports = [checkMod];
              commands = [
                {package = namaka.packages.default;}
                {
                  package = cocogitto;
                  name = "cog";
                }
              ];
            };
          };
          checks = namaka.lib.load {
            src = ../tests;
            inputs = call-flake ../.;
          };
        }
    );
}
