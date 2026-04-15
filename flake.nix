{
  description = "NixOS OpenZFS";
  inputs = {
    systems.url = "github:nix-systems/default-linux";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs =
    {
      systems,
      flake-parts,
      nixpkgs,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      {
        flake-parts-lib,
        self,
        lib,
        ...
      }@mkFlakeArgs:
      let
        inherit (flake-parts-lib) importApply;
      in
      {
        systems = import systems;
        flake = {
          nixosModules = {
            default = args: { imports = [ (importApply ./nix/modules/zfs mkFlakeArgs) ]; };
          };
        };
        perSystem =
          { pkgs, system, ... }:
          {
            packages = {
              zfs-encrypt-key-tpm2 = pkgs.callPackage ./nix/packages/zfs-encrypt-key-tpm2 { };
            };
          };
      }
    );
}
