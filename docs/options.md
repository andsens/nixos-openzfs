## openzfs\.enable

Whether to enable enable zfs support\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [nix/modules/zfs/default\.nix](https://github.com/andsens/nixos-openzfs/blob/main/nix/modules/zfs/default.nix)



## openzfs\.pools



ZFS Pools to configure



*Type:*
attribute set of (submodule)



*Default:*

```nix
{ }
```

*Declared by:*
 - [nix/modules/zfs/default\.nix](https://github.com/andsens/nixos-openzfs/blob/main/nix/modules/zfs/default.nix)



## openzfs\.pools\.\<name>\.autoDecrypt



Whether to enable automatic decryption of the pool at boot\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [nix/modules/zfs/default\.nix](https://github.com/andsens/nixos-openzfs/blob/main/nix/modules/zfs/default.nix)



## openzfs\.pools\.\<name>\.autoMount



Whether to enable automatic mounting of the pool at boot\.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [nix/modules/zfs/default\.nix](https://github.com/andsens/nixos-openzfs/blob/main/nix/modules/zfs/default.nix)



## openzfs\.pools\.\<name>\.tpmPCRs



List of PCRs to use for locking the decryption key



*Type:*
list of signed integer



*Default:*

```nix
[
  0
  2
  7
  15
]
```

*Declared by:*
 - [nix/modules/zfs/default\.nix](https://github.com/andsens/nixos-openzfs/blob/main/nix/modules/zfs/default.nix)



## openzfs\.zed\.literalSettings



Additional settings for zed\.rc that will be appended to the rendered form of ` openzfs.zed.settings `\.
Useful when configuring e\.g\. credentials that should not be part of the nix store\.



*Type:*
strings concatenated with “\\n”



*Example:*

```nix
openzfs.zed.literalSettings = ''
  . /etc/zfs/pushover-credentials.sh
'';

where /etc/zfs/pushover-credentials.sh is:
ZED_PUSHOVER_TOKEN="6bw51jqdwro0to3cv8lzardoae2zc4"
ZED_PUSHOVER_USER="gAFC9TEEdyayByq0pMtMHWopFq7kQ9"

```

*Declared by:*
 - [nix/modules/zfs/zed\.nix](https://github.com/andsens/nixos-openzfs/blob/main/nix/modules/zfs/zed.nix)



## openzfs\.zed\.settings



ZFS Event Daemon /etc/zfs/zed\.d/zed\.rc content

See
` zed(8) `
for details on ZED and the scripts in /etc/zfs/zed\.d to find the possible variables



*Type:*
attribute set of (string or signed integer or boolean or list of string)



*Default:*

```nix
{ }
```



*Example:*

```nix
{
  ZED_DEBUG_LOG = "/tmp/zed.debug.log";

  ZED_EMAIL_ADDR = [ "root" ];
  ZED_EMAIL_PROG = "mail";
  ZED_EMAIL_OPTS = "-s '@SUBJECT@' @ADDRESS@";

  ZED_NOTIFY_INTERVAL_SECS = 3600;
  ZED_NOTIFY_VERBOSE = false;

  ZED_USE_ENCLOSURE_LEDS = true;
  ZED_SCRUB_AFTER_RESILVER = false;
}

```

*Declared by:*
 - [nix/modules/zfs/zed\.nix](https://github.com/andsens/nixos-openzfs/blob/main/nix/modules/zfs/zed.nix)



## openzfs\.zed\.zedlets



List of zedlets to enable\.



*Type:*
list of string



*Default:*

```nix
[ ]
```



*Example:*

```nix
''
  [
    "deadman-slot_off.sh"
    "trim_finish-notify.sh"
  ]
''
```

*Declared by:*
 - [nix/modules/zfs/zed\.nix](https://github.com/andsens/nixos-openzfs/blob/main/nix/modules/zfs/zed.nix)



## openzfs\.zed\.zeventNotify



List of zevents for which to send notifications, uses the generic-notify\.sh zedlet\.



*Type:*
list of string



*Default:*

```nix
[ ]
```



*Example:*

```nix
"[ \"probe_failure\" ]"
```

*Declared by:*
 - [nix/modules/zfs/zed\.nix](https://github.com/andsens/nixos-openzfs/blob/main/nix/modules/zfs/zed.nix)


