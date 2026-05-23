{ inputs, ... }:
{
  lib,
  config,
  ...
}:
let
  cfg = config.openzfs;
  autoMountPools = lib.filterAttrs (pool: { autoMount, ... }: autoMount) cfg.pools;
in
{
  options.openzfs = {
    enable = lib.mkEnableOption "enable zfs support";
    pools = lib.mkOption {
      description = "ZFS Pools to configure";
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              autoDecrypt = lib.mkEnableOption "automatic decryption of the pool at boot";
              tpmPCRs = lib.mkOption {
                description = "List of PCRs to use for locking the decryption key";
                type = lib.types.listOf lib.types.int;
                default = [
                  0
                  2
                  7
                  15
                ];
              };
              autoMount = lib.mkEnableOption "automatic mounting of the pool at boot";
            };
          }
        )
      );
      default = { };
    };
  };
  imports = [
    ./boot.nix
    ./units.nix
    ./zed.nix
    (import ./encryption.nix { inherit inputs; })
  ];
  config = lib.mkIf cfg.enable {
    system.activationScripts.openzfs-setup-pools =
      lib.mkIf (lib.length (builtins.attrNames autoMountPools) > 0)
        {
          text = ''
            for pool in ${lib.escapeShellArgs (builtins.attrNames autoMountPools)}; do
              touch /etc/zfs/zfs-list.cache/$pool
              if [[ $(stat -c%s /etc/zfs/zfs-list.cache/$pool) = 0 ]]; then
                previousATime=$(zfs get -Ho value atime "$pool")
                case "$previousATime" in
                  on) zfs atime=off "$pool"; zfs atime=on "$pool" ;;
                  off) zfs atime=on "$pool"; zfs atime=off "$pool" ;;
                  *) printf "Unknown atime: %s" "$previousATime" >&2 ;;
                esac
              fi
            done
          '';
        };
  };
}
