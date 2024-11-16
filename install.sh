#!/bin/sh

EXEDIR="$(dirname "$0")"
EXEDIR="$(cd "$EXEDIR"; pwd)"
JFFS_DNSMASQ=/jffs/configs/dnsmasq.conf.add
FW_SCRIPT=/jffs/scripts/firewall-start
INIT_SCRIPT=/jffs/scripts/init-start
TORRC=/opt/etc/tor/torrc
INIT_STR="modprobe ip_set;modprobe ip_set_hash_ip;modprobe ip_set_hash_net;modprobe ip_set_bitmap_ip;modprobe ip_set_list_set;modprobe xt_set;ipset create unblock hash:net"
PKGS="obfs4_nohf tor tor-geoip"
NO_PKGS=

for pkg in $PKGS; do
	opkg list-installed | grep -q $pkg || NO_PKGS="$NO_PKGS $pkg"
done
[ -n "$NO_PKGS" ] && echo "$NO_PKGS are not installed" && exit 1

#------------------ torrc setup -----------------------------
if [ -e $TORRC ]; then
	if ! grep -Rq "obfs4proxy" $TORRC; then
	  cat /dev/null > $TORRC
	  echo "User $USER" >> $TORRC
	  IP_ADDR=$(ifconfig | sed -n 's/.*inet addr:\(192[0-9.]\+\).*/\1/p') >> $TORRC
	  echo "TransPort $IP_ADDR:9141" >> $TORRC
	  cat $EXEDIR/torrc.default >> $TORRC
	  echo "%include $EXEDIR/bridges.conf" >> $TORRC
	else
	  echo "Tor conf file already set up"
	fi
else echo "Tor conf file not found"; fi

#------------- dnsmasq conf file setup --------------------------
if [ ! -e "$JFFS_DNSMASQ"  ]; then
        touch "$JFFS_DNSMASQ"
        chmod a+rx "$JFFS_DNSMASQ"
        echo "Creating $JFFS_DNSMASQ"
	echo "conf-file=$EXEDIR/unblock.dnsmasq" >> "$JFFS_DNSMASQ"
elif grep -Rq "conf-file=$EXEDIR/unblock.dnsmasq" "$JFFS_DNSMASQ"; then
        echo "conf-file line already exists in $JFFS_DNSMASQ"
else
        echo "conf-file=$EXEDIR/unblock.dnsmasq" >> "$JFFS_DNSMASQ"
        echo "Adding conf-file line to $JFFS_DNSMASQ"
fi

#------------- init-start script setup -------------------------
if [ ! -e "$INIT_SCRIPT"  ]; then
        touch "$INIT_SCRIPT"
        chmod a+rx "$INIT_SCRIPT"
        echo "Creating $INIT_SCRIPT"
	while [ -n "$INIT_STR" ]; do
	  echo ${INIT_STR%%;*} >> "$INIT_SCRIPT"
	  [ "$INIT_STR" = "${INIT_STR/;/}" ] && INIT_STR= || INIT_STR=${INIT_STR#*;}
	done	
else
	while [ -n "$INIT_STR" ]; do
	  if ! grep -Rq "${INIT_STR%%;*}" "$INIT_SCRIPT"; then
	    echo "Adding ${INIT_STR%%;*} to $INIT_SCRIPT"
	    echo "${INIT_STR%%;*}" >> "$INIT_SCRIPT"
	  else echo "${INIT_STR%%;*} already exists in $INIT_SCRIPT"
	  fi
	  [ "$INIT_STR" = "${INIT_STR/;/}" ] && INIT_STR= || INIT_STR=${INIT_STR#*;}
	done
fi

#-------------------- Adding to init.d ------------------------------
[ ! -e /opt/etc/init.d/S89unblock ] && ln -fs $EXEDIR/S89unblock /opt/etc/init.d/S89unblock || echo "Link to init.d already created"

#---------------------- Setting up CRON -----------------------------------
sed -i 's/root/$USER/g' /opt/etc/crontab
if ! grep -Rq "/ipset_from_hosts.sh" /opt/etc/crontab; then
	echo -e 00 06 \* \* \* $USER $EXEDIR/ipset_from_hosts.sh >> /opt/etc/crontab
	echo "Adding crontab record"
fi
