{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.openzfs.load-encrypted-key = {
    enable = lib.mkEnableOption "enable automatic unlocking of ZFS pools through SystemD LoadCredentialEncrypted=";
  };
  config = lib.mkIf config.openzfs.load-encrypted-key.enable {
    systemd.services."zfs-load-encrypted-key@" = {
      description = "Load the ZFS encryption key for pool '%I'";
      unitConfig = {
        DefaultDependencies = false;
        ConditionPathExists = "/etc/credstore.encrypted/%I.zfs-key";
      };
      after = [ "zfs-import.target" ];
      serviceConfig = {
        Type = "oneshot";
        # Generate with `zfs-encrypt-key-tpm2 POOLNAME`
        LoadCredentialEncrypted = "%I.zfs-key:/etc/credstore.encrypted/%I.zfs-key";
        ExecStart = ''${lib.getExe' pkgs.zfs "zfs"} load-key -L "file://%d/%I.zfs-key" "%I"'';
      };
    };
    systemd.services."zfs-load-key@" = rec {
      overrideStrategy = "asDropin";
      wants = [ "zfs-load-encrypted-key@%i.service" ];
      after = wants;
    };
  };
}
