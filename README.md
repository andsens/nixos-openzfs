# nixos-zfs

The [NixOS ZFS implementation](https://github.com/NixOS/nixpkgs/blob/bd7d1b03e7694e91cb2159c16afa97799628f7ce/nixos/modules/tasks/filesystems/zfs.nix)
uses shell scripts to mount pools explicitly.  
Instead I prefer mounting filesystems using the systemd mount generator.  
This repo is almost a direct implementation of the [systemd units in the OpenZFS repo](https://github.com/openzfs/zfs/tree/6692b6e28a2f4fe241bc8e327aa9e59aaeb41edd/etc/systemd/system).  
Alterations include:

- Support for automatic pool decryption (either through TPM2 or some other way)
- Removal of the `systemd-udev-settle.service` dependency

For the full list of module options, see [docs/options.md](docs/options.md).

## Installation & usage

Add `nixos-openzfs` to your flake inputs:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    openzfs = {
      url = "github:andsens/nixos-openzfs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

Import and enable the module, then configure your pools:

```nix
{ inputs, ... }:
{
  imports = [
    inputs.openzfs.nixosModules.default
  ];
  config = {
    openzfs = {
      enable = true;
      pools.tank = {
        autoDecrypt = true;
        autoMount = true;
        tpmPCRs = [0, 2, 7, 15];
      };
    };
  };
}
```

Run `sudo setup-secrets` on your host to setup encrypted ZFS keys that are locked with your TPM.

You may also want to configure a hostId (see https://openzfs.github.io/openzfs-docs/Performance%20and%20Tuning/Module%20Parameters.html#spl-hostid):

```nix
{ ... }:
{
  config = {
    networking.hostId = "4a68cb86"; # head -c 8 /etc/machine-id
  };
}
```

## Scrubbing & trimming

Configure periodic scrubbing and TRIM'ing ov your pools by enabling the template
services (`monthly` and `weekly` are available, for a different config create
a SystemD timer that triggers `zfs-scrub@%i.service` and `zfs-trim@%i.service`
respectively):

```nix
{ ... }:
{
  config = {
    systemd.timers."zfs-scrub-monthly@tank" = {
      overrideStrategy = "asDropin";
      wantedBy = [ "timers.target" ];
    };
    systemd.timers."zfs-trim-weekly@tank" = {
      overrideStrategy = "asDropin";
      wantedBy = [ "timers.target" ];
    };
  };
}
```

### Event notifications

Configure credentials for your notification service with `setup-secrets`:

```nix
{ ... }:
{
  let
    pushoverCreds = "/etc/secrets.d/pushover-credentials.env";
  in
  config = {
    homelab.zfs.zed.literalSettings = ''
      . "${pushoverCreds}"
    '';
    setup-secrets = {
      sources.ZED_PUSHOVER_USER = {
        description = "ZFS Event Daemon Pushover user";
        cmd = ''
          source "${pushoverCreds}"
          printf "%s" "$ZED_PUSHOVER_USER"
        '';
      };
      sources.ZED_PUSHOVER_TOKEN = {
        description = "ZFS Event Daemon Pushover token";
        cmd = ''
          source "${pushoverCreds}"
          printf "%s" "$ZED_PUSHOVER_TOKEN"
        '';
      };
      destinations = [
        {
          logPrefix = "ZFS Event Daemon Pushover credentials";
          requires = [
            "ZED_PUSHOVER_USER"
            "ZED_PUSHOVER_TOKEN"
          ];
          cmd = ''
            umask 077
            printf "ZED_PUSHOVER_USER=%q\nZED_PUSHOVER_TOKEN=%q\n" "$ZED_PUSHOVER_USER" "$ZED_PUSHOVER_TOKEN" >"${pushoverCreds}"
          '';
        }
      ];
    };
  };
}
```
