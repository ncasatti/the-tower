#!/bin/sh
# Pin the server's LAN address on every NetworkManager media.
#
# Runs from nix/hosts/server/network.nix, which injects the values through
# the environment. Kept as a standalone file so it can be run and tested
# directly on the host:
#
#   NM_LAN_ADDRESS=192.168.100.4 NM_LAN_PREFIX=24 \
#   NM_LAN_GATEWAY=192.168.100.1 NM_LAN_DNS=192.168.100.1 \
#   NM_WIFI_PROFILE=Knet NM_WIRED_PROFILE=grid-wired NM_WIRED_IFACE=enp1s0f1 \
#   ./nm-static-lan.sh
#
# The WiFi PSK is never touched here: this repo is public, so the "Knet"
# profile stays a runtime artifact in /etc/NetworkManager/system-connections/
# and only its addressing is owned from here.

set -eu

ADDRESS="${NM_LAN_ADDRESS:?NM_LAN_ADDRESS required}"
PREFIX="${NM_LAN_PREFIX:?NM_LAN_PREFIX required}"
GATEWAY="${NM_LAN_GATEWAY:?NM_LAN_GATEWAY required}"
DNS="${NM_LAN_DNS:?NM_LAN_DNS required}"
WIFI_PROFILE="${NM_WIFI_PROFILE:?NM_WIFI_PROFILE required}"
WIRED_PROFILE="${NM_WIRED_PROFILE:?NM_WIRED_PROFILE required}"
WIRED_IFACE="${NM_WIRED_IFACE:?NM_WIRED_IFACE required}"

# Wait for NetworkManager to publish its profiles.
i=0
while [ "$i" -lt 30 ]; do
    if nmcli -t -f NAME connection show >/dev/null 2>&1; then
        break
    fi
    i=$((i + 1))
    sleep 1
done

has_profile() {
    nmcli -t -f NAME connection show 2>/dev/null | grep -qx "$1"
}

# `ipv4.dns-search ""` clears the search domain: the server resolves
# through Tailscale MagicDNS, not through this interface.
set_addressing() {
    nmcli connection modify "$1" \
        ipv4.method manual \
        "ipv4.addresses" "${ADDRESS}/${PREFIX}" \
        "ipv4.gateway" "${GATEWAY}" \
        "ipv4.dns" "${DNS}" \
        "ipv4.dns-search" ""
}

# --- WiFi: keep the PSK where it is, own only the addressing. ---
if has_profile "${WIFI_PROFILE}"; then
    current="$(nmcli -g ipv4.method,ipv4.addresses connection show "${WIFI_PROFILE}" 2>/dev/null || true)"
    case "${current}" in
        "manual${ADDRESS}/${PREFIX}"*)
            echo "${WIFI_PROFILE}: addressing already correct"
            ;;
        *)
            set_addressing "${WIFI_PROFILE}"
            echo "${WIFI_PROFILE}: set ${ADDRESS}/${PREFIX}"
            ;;
    esac
else
    echo "${WIFI_PROFILE}: profile not found, skipping" >&2
fi

# --- Ethernet: target media for the 1 GbE link to the ONT. ---
if has_profile "${WIRED_PROFILE}"; then
    set_addressing "${WIRED_PROFILE}"
    echo "${WIRED_PROFILE}: set ${ADDRESS}/${PREFIX}"
else
    nmcli connection add \
        type ethernet \
        ifname "${WIRED_IFACE}" \
        con-name "${WIRED_PROFILE}" \
        ipv4.method manual \
        "ipv4.addresses" "${ADDRESS}/${PREFIX}" \
        "ipv4.gateway" "${GATEWAY}" \
        "ipv4.dns" "${DNS}" \
        "ipv4.dns-search" "" \
        connection.autoconnect no
    echo "${WIRED_PROFILE}: created with ${ADDRESS}/${PREFIX} (autoconnect no)"
fi
