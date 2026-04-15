{
  lib,
  systemd,
  writeShellScriptBin,
  ...
}:
writeShellScriptBin "zfs-encrypt-key-tpm2" ''
  fatal() { printf "%s\n" "$1" >&2; exit 1; }
  main() {
    [[ $# = 1 ]] || fatal "Usage: zfs-encrypt-key-tpm2 POOLNAME"
    [[ $(id -u) = 0 ]] || fatal "Must run as root"
    local pool=$1 keyfile
    keyfile=$(mktemp --suffix zfs-key)
    trap "rm -f \"$keyfile\"" EXIT
    ${lib.getExe' systemd "systemd-ask-password"} "Enter the key used to unlock '$pool'" >"$keyfile"
    mkdir -p /etc/credstore.encrypted/
    local encdest=/etc/credstore.encrypted/$pool.zfs-key
    ${lib.getExe' systemd "systemd-creds"} encrypt --tpm2-device=auto --tpm2-pcrs=0+2+7+15 "$keyfile" "$encdest"
    chmod go-r "$encdest"
    printf "Encrypted ZFS passphrase for pool '%s' has been written to '%s'\n" "$pool" "$encdest" >&2
  }
  main "$@"
''
