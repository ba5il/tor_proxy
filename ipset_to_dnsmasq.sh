#!/bin/sh

EXEDIR="$(dirname "$0")"
EXEDIR="$(cd "$EXEDIR"; pwd)"

cat /dev/null > $EXEDIR/unblock.dnsmasq

while read line || [ -n "$line" ]; do

  [ -z "$line" ] && continue
  [ "${line:0:1}" = "#" ] && continue

  echo $line | grep -Eq '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' && continue

  echo "ipset=/$line/unblock" >> $EXEDIR/unblock.dnsmasq

done < $EXEDIR/unblock.list
