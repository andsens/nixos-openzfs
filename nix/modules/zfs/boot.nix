{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.openzfs.enable {
    services.udev.packages = [ pkgs.zfs ];
    boot = {
      # https://github.com/NixOS/nixpkgs/blob/203b1670b3a057675672c0ec8b32a5f896bbb807/nixos/modules/tasks/filesystems/zfs.nix#L704-L714
      kernelModules = [ "zfs" ];
      extraModulePackages = [ config.boot.kernelPackages.${pkgs.zfs.kernelModuleAttribute} ];
      initrd.kernelModules = [ "zfs" ];

      # https://github.com/openzfs/zfs/issues/260
      # https://github.com/openzfs/zfs/issues/12842
      # https://github.com/NixOS/nixpkgs/issues/106093
      kernelParams = lib.optionals (!config.boot.zfs.allowHibernation) [ "nohibernate" ];
    };
  };
}
