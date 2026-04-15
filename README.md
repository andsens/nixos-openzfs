# nixos-zfs

The [NixOS ZFS implementation](https://github.com/NixOS/nixpkgs/blob/bd7d1b03e7694e91cb2159c16afa97799628f7ce/nixos/modules/tasks/filesystems/zfs.nix)
uses shell scripts to mount pools explicitly.  
Instead I prefer mounting filesystems using the systemd mount generator.  
This repo is almost a direct implementation of the [systemd units in the OpenZFS repo](https://github.com/openzfs/zfs/tree/6692b6e28a2f4fe241bc8e327aa9e59aaeb41edd/etc/systemd/system).  
Alterations include:

- Support for automatic pool decryption (either through TPM2 or some other way)
- Removal of the `systemd-udev-settle.service` dependency

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

Import and enable the module:

```nix
{ inputs, ... }:
{
  imports = [
    inputs.openzfs.nixosModules.default
  ];
  config = {
    openzfs.enable = true;
  };
}
```

To enable automatic mounting of your pools create a cache file for each pool,
then set the mountpoints _in that order_.  
The setting of the mountpoint generates a history event that triggers a refresh
of the cache file, which is used to determine which mounts to generate during
startup (see https://openzfs.github.io/openzfs-docs/man/v2.4/8/zfs-mount-generator.8.html#EXAMPLES
for more details).

```sh
$ sudo touch /etc/zfs/zfs-list.cache/tank
$ sudo zfs set mountpoint=/mnt/tank tank
```

You may also want to configure a hostId (see https://openzfs.github.io/openzfs-docs/Performance%20and%20Tuning/Module%20Parameters.html#spl-hostid):

```nix
{ ... }:
{
  config = {
    networking.hostId = "4a68cb86"; # head -c 8 /etc/machine-id
  };
}
```

## Automatic volume unlocking

Enable automatic unlocking of pools using SystemD `LoadCredentialEncrypted=`:

```nix
{ ... }:
{
  config = {
    openzfs.load-encrypted-key.enable = true;
    environment.systemPackages = [ inputs.openzfs.packages.${pkgs.stdenv.hostPlatform.system}.zfs-encrypt-key-tpm2 ];
  };
}
```

Encrypt and save the encryption passphrase using `zfs-encrypt-key-tpm2`:

```sh
$ sudo zfs-encrypt-key-tpm2 tank
🔐 Enter the key used to unlock 'tank' ••••••••••••••••
Encrypted ZFS passphrase for pool 'tank' has been written to '/etc/credstore.encrypted/tank.zfs-key'
```

PCRs 0+2+7+15 are used for TPM key locking. If you need something else just use
`systemd-creds encrypt <KEYFILE> /etc/credstore.encrypted/<POOLNAME>.zfs-key` directly.

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
    homelab.zfs.zed.literalSettings = ''
      . /etc/secrets.d/pushover-credentials.env
    '';
  };
}
```
