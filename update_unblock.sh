#!/bin/sh

if [ -z "$EXEDIR" ]; then
	EXEDIR="$(dirname "$0")"
	EXEDIR="$(cd "$EXEDIR"; pwd)"
fi

ipset flush unblock

$EXEDIR/ipset_to_dnsmasq.sh
service restart_dhcpd
sleep 3
$EXEDIR/ipset_from_hosts.sh
