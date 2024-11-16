#!/bin/sh

EXEDIR="$(dirname "$0")"
EXEDIR="$(cd "$EXEDIR"; pwd)"

[ -z "$1" ] && exit 1

for HOST in $@; do
	echo "$HOST" >> $EXEDIR/unblock.list
	echo "$HOST"
done

$EXEDIR/update_unblock.sh
