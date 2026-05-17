{ inputs, ... }:
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.openzfs;
  autoDecryptPools = lib.filterAttrs (pool: { autoDecrypt, ... }: autoDecrypt) cfg.pools;
in
{
  imports = [ inputs.setup-secrets.nixosModules.default ];
  config = lib.mkIf (lib.length (builtins.attrNames autoDecryptPools) > 0) {
    setup-secrets.enable = true;
    systemd.services."zfs-load-encrypted-key@" = {
      description = "Load the ZFS encryption key for pool '%I'";
      unitConfig = {
        DefaultDependencies = false;
        ConditionPathExists = "/etc/credstore.encrypted/%I.zfs-key";
      };
      after = [ "zfs-import.target" ];
      serviceConfig = {
        Type = "oneshot";
        LoadCredentialEncrypted = "%I.zfs-key:/etc/credstore.encrypted/%I.zfs-key";
        ExecStart = ''${lib.getExe' pkgs.zfs "zfs"} load-key -L "file://%d/%I.zfs-key" "%I"'';
      };
    };
    systemd.services."zfs-load-key@" = rec {
      overrideStrategy = "asDropin";
      wants = [ "zfs-load-encrypted-key@%i.service" ];
      after = wants;
    };
    setup-secrets = {
      sources = lib.mapAttrs' (
        pool: spec:
        lib.nameValuePair "ZFS_ENCRYPTION_KEY_${pool}" {
          description = "ZFS Encrypion key for ${pool}";
          cmd = "${lib.getExe' pkgs.systemd "systemd-creds"} decrypt /etc/credstore.encrypted/media.zfs-key";
        }
      ) autoDecryptPools;
      destinations = lib.mapAttrsToList (pool: spec: {
        logPrefix = "ZFS Encrypion key for ${pool}";
        requires = [ "ZFS_ENCRYPTION_KEY_${pool}" ];
        cmd = lib.getExe (
          pkgs.writeShellScriptBin "zfs-encrypt-key-tpm2.sh" ''
            umask 700
            keyfile=$(mktemp --suffix zfs-key)
            trap "rm -f \"$keyfile\"" EXIT
            printf "%s" "$ZFS_ENCRYPTION_KEY_${pool}" >"$keyfile"
            mkdir -p /etc/credstore.encrypted/
            ${lib.getExe' pkgs.systemd "systemd-creds"} encrypt --tpm2-device=auto --tpm2-pcrs=${lib.join "+" (map builtins.toString spec.tpmPCRs)} "$keyfile" "/etc/credstore.encrypted/${pool}.zfs-key"
          ''
        );
      }) autoDecryptPools;
    };
  };
}
