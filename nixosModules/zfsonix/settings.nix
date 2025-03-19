{
  diskName,
  lib,
  options,
  ...
}:
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
// lib.optionalAttrs (options ? preservation) {
  preservation.preserveAt."/persist".directories = [
    "/var/lib/nixos"
    "/var/log"
    "/var/lib/systemd/coredump"
  ];
}
