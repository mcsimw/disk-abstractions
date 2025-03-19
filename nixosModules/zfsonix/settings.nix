{
  diskName,
  lib,
  options,
  ...
}:

lib.mkMerge [
  {
    boot = {
      kernelParams = [ "nohibernate" ];
      tmp.cleanOnBoot = true;
    };

    fileSystems = {
      "/".neededForBoot = true;
      "/persist".neededForBoot = true;
      "/mnt/${diskName}".neededForBoot = true;
    };

    zfs-rollback = {
      enable = true;
      snapshot = "blank";
      volume = "${diskName}-zfsos/faketmpfs";
    };
  }
  (lib.optionalAttrs (options ? environment.persistence && !(options ? preservation)) {
    environment.persistence."/persist" = {
      enable = true;
      hideMounts = true;
      directories = [
        "/var/lib/nixos"
        "/var/log"
        "/var/lib/systemd/coredump"
      ];
    };
  })
  (lib.optionalAttrs (options ? preservation) {
    preservation = {
      preserveAt."/persistent" = {
        directories = [
          "/var/lib/nixos"
          "/var/log"
          "/var/lib/systemd/coredump"
        ];
      };
    };
  })
]
