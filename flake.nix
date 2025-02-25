{
  description = "My new flake with merged nixosModules";
  inputs = {
    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
    };
    nix-genesis = {
      type = "github";
      owner = "mcsimw";
      repo = "nix-genesis";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      type = "github";
      owner = "hercules-ci";
      repo = "flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { self, lib, ... }:
      {
        perSystem.treefmt = {
          projectRootFile = "flake.nix";
          programs = {
            nixfmt.enable = true;
            deadnix.enable = true;
            statix.enable = true;
            dos2unix.enable = true;
          };
        };
        imports = [
          inputs.treefmt-nix.flakeModule
        ];
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        flake.nixosModules = {
          zfs-rollback = import ./nixosModules/zfs-rollback.nix;
          zfsonix = lib.modules.importApply ./nixosModules/zfsonix {
           localFlake = self;
          };
        };
      }
    );
}
