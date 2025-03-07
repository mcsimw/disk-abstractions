{ localFlake, ... }:
{ lib, config, options,... }:
let
  cfg = config.zfsonix;
in
{
  imports = [
    localFlake.nixosModules.zfs-rollback
  ];
  options.zfsonix = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the nixOnZfsos configuration.";
    };
    diskName = lib.mkOption {
      type = lib.types.str;
      description = "The name of the disk to be used.";
    };
    device = lib.mkOption {
      type = lib.types.path;
      description = "The block device path for the disk.";
    };
    ashift = lib.mkOption {
      type = lib.types.int;
      description = "The ashift value for ZFS (log₂ of the sector size).";
    };
    swapSize = lib.mkOption {
      type = lib.types.str;
      description = "The size of the swap partition. Accepts values like 1024M or 4G.";
    };
  };
  config = lib.mkIf cfg.enable (
    (import ./settings.nix {
      inherit (cfg) diskName;
      inherit lib options;
    })
    // (import ../../templates/zfsonix.nix {
      inherit (cfg)
        diskName
        device
        ashift
        swapSize
        ;
      inherit lib;
    })
  );
}
