#! /bin/bash
#
# Arch Linux installation script
#
# 2019-10 - Keith Patton - kaipee.co.uk

#################
# SHELL OPTIONS #
#################
set -u
#################

#############
# FUNCTIONS #
#############
exit_er()
{ # Check exit status of last command. If error (not 0) print message and stop execution
  if [[ "$?" -ne 0 ]]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')]: $@" >&2
    exit
  fi
}
exit_ok()
{ # Check exit status of last command. If success (return 0) print a success message and continue
  if [[ "$?" -eq 0 ]]; then
    echo "$@"
  fi
}
#############


printf '
################################################################
####                 Setting keyboard layout                ####
################################################################
'
read -p "Enter keyboard layout (example: uk): " _KB_LAYOUT
loadkeys "$_KB_LAYOUT"
exit_er "Error setting keyboard layout to $_KB_LAYOUT"
exit_ok "Success! Keyboard layout set to $_KB_LAYOUT"

printf '
################################################################
####                  Verifying Boot Mode                   ####
################################################################
'
ls /sys/firmware/efi/efivars > /dev/null
if [[ "$?" -eq 0 ]]; then
  _BOOT_MODE=EFI
else
  _BOOT_MODE=BIOS
fi
echo "Boot mode set to $_BOOT_MODE"

printf '
################################################################
####               Verifying internet access                ####
################################################################
'
echo "Checking network connectivity (assuming wired)..."
function net_check ()
{ # Ping Google DNS servers
  if ping -q -c 2 -W 1 google.com >/dev/null; then
    _NET_STATUS=up
  else
    _NET_STATUS=down
  fi
}

_NET_STATUS=down
_NET_COUNT=0
while [ "$_NET_STATUS" = "down" ]; do
  net_check
  printf "."
  if [ $_NET_COUNT -eq 20 ]; then
    echo "Restarting DHCP daemon..."
    systemctl restart dhcpcd
    exit_er "Error unable to restart DHCP daemon"
    exit_ok "Restarted DHCP daemon and retrying network"
    _NET_COUNT=-1
  fi
  _NET_COUNT=$(expr $_NET_COUNT + 1)
done
echo "Network is UP"
ip link
