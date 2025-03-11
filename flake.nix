{
  description = "disk-abstractions";
  inputs = {
    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
    };
    genesis-nix = {
      type = "github";
      owner = "mcsimw";
      repo = "genesis-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        treefmt-nix.follows = "flake-parts";
      };
    };
    flake-parts = {
      type = "github";
      owner = "hercules-ci";
      repo = "flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix = {
      type = "github";
      owner = "numtide";
      repo = "treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { self, lib, ... }:
      {
        perSystem =
          { pkgs, ... }:
          {
            treefmt = {
              projectRootFile = "flake.nix";
              programs = {
                nixfmt.enable = true;
                deadnix.enable = true;
                statix.enable = true;
                shfmt.enable = true;
                dos2unix.enable = true;
              };
            };
            packages.disk-partitioner = import ./scripts/partitioner/script.nix { inherit pkgs inputs self; };
          };
        imports = [
          inputs.treefmt-nix.flakeModule
        ];
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        flake = {
          nixosModules = {
            zfs-rollback = import ./nixosModules/zfs-rollback.nix;
            zfsonix = lib.modules.importApply ./nixosModules/zfsonix {
              localFlake = self;
            };
          };
        };
      }
    );
}
