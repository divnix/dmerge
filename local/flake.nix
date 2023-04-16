{
  description = "Data Merge development shell";
  inputs.nosys.url = "github:divnix/nosys";
  inputs.namaka.url = "github:nix-community/namaka";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.devshell.url = "github:numtide/devshell";
  inputs.flake-compat.url = "github:edolstra/flake-compat?ref=refs/pull/55/head";
  outputs = inputs @ {
    nosys,
    flake-compat,
    ...
  }:
    nosys ((flake-compat ../.).inputs // inputs) (
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
        }
    );
}
