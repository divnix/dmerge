{
  description = "Data Merge development shell";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.devshell.url = "github:numtide/devshell";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.main.url = "path:../.";
  outputs = inputs: let
    inherit (inputs.nixpkgs) lib;
    eachSystem = f:
      lib.genAttrs
      lib.systems.flakeExposed
      (system:
        f (
          inputs.nixpkgs.legacyPackages.${system}.appendOverlays [inputs.devshell.overlays.default]
          // {namaka = inputs.main.inputs.namaka.packages.${system}.default;}
        ));
    inherit (lib.stringsWithDeps) noDepEntry;
  in {
    devShells = eachSystem (pkgs: {
      default = pkgs.devshell.mkShell {
        name = "Data Merge";
        commands = [
          {package = pkgs.treefmt;}
          {package = pkgs.namaka;}
        ];
        packages = [
          pkgs.alejandra
          pkgs.shfmt
          pkgs.nodePackages.prettier
          pkgs.nodePackages.prettier-plugin-toml
          pkgs.python3Packages.black
        ];
        devshell.startup.nodejs-setuphook = noDepEntry ''
          export NODE_PATH=${
            pkgs.nodePackages.prettier-plugin-toml
          }/lib/node_modules:$NODE_PATH
        '';
      };
    });
  };
}
