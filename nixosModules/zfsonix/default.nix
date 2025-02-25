{ localFlake, ... }:
{ lib, config, ... }:
let
  cfg = config.zfsonix;
in
{
  options.zfsonix = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the nixOnZfsos configuration.";
    };
    diskName = lib.mkOption {
      type = lib.types.str;
      default = "zfsos-disk";
      description = "The name of the disk to be used.";
    };
    device = lib.mkOption {
      type = lib.types.path;
      default = "/dev/sdX";
      description = "The block device path for the disk.";
    };
    ashift = lib.mkOption {
      type = lib.types.int;
      default = 12;
      description = "The ashift value for ZFS (log₂ of the sector size).";
    };
    swapSize = lib.mkOption {
      type = lib.types.str;
      default = "2G";
      description = "The size of the swap partition.";
      check =
        value:
        let
          m = builtins.match "^[1-9][0-9]*(M|G)$" value;
        in
        m != null;
    };
  };
  config = lib.mkIf (cfg.enable && cfg.template == "zfsos") (
    { }
    // (
      (import ./settings.nix {
        inherit (cfg) diskName;
        inherit localFlake lib;
      })
      (import ../../templates/zfsonix.nix { inherit (cfg) diskName device ashift; })
    )
  );
}
