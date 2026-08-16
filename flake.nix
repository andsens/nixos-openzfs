{
  description = "NixOS OpenZFS";
  inputs = {
    systems.url = "github:nix-systems/default-linux";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    setup-secrets = {
      url = "github:andsens/nix-setup-secrets";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    docs = {
      url = "github:andsens/nix-docs";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
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
        inputs,
        self,
        ...
      }:
      let
        inherit (flake-parts-lib) importApply;
      in
      {
        systems = import systems;
        flake.nixosModules.default = importApply ./nix/modules/zfs { inherit self inputs; };
        perSystem =
          { pkgs, lib, ... }:
          let
            options-docs = inputs.docs.lib.docs.options {
              inherit pkgs;
              modules = lib.attrValues self.nixosModules;
              repoPath = toString self;
              repoLinkPrefix = "https://github.com/andsens/nixos-openzfs/blob/main";
            };
          in
          {
            apps.update-docs.program = inputs.docs.lib.docs.updateRepo {
              inherit pkgs;
              paths."docs/options.md" = options-docs.optionsCommonMark;
            };
            packages.options-docs = options-docs.optionsCommonMark;
          };
      }
    );
}
