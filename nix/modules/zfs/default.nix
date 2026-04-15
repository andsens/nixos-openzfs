{ ... }:
{
  lib,
  ...
}:
{
  options.openzfs = {
    enable = lib.mkEnableOption "enable zfs support";
  };
  imports = [
    ./boot.nix
    ./units.nix
    ./zed.nix
    ./zfs-load-encrypted-key.nix
  ];
}
