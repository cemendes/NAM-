#!/bin/bash
trap "rm -r dudu.* > /dev/null 2>&1 ; pkill -t $MYTTY tailf ; pkill -t $MYTTY tcpdump ; echo \"It worked \" ; exit" SIGHUP SIGINT SIGTERM SIGUSR1
/usr/bin/tailf /var/opt/novell/nam/logs/idp/tomcat/catalina.out > dudu.log &
/usr/sbin/tcpdump -s 65535 -i any -w dudu.pcap -C 200 -Z root > /dev/null 2>&1 &
echo "About to kill the script"
sleep 2
TRAP=`/usr/bin/pgrep -f trap.sh`
echo $TRAP
pkill -15 $TRAP

grep -i -E "warning.*artifact|severe|AxisFault"  | grep -vE "WSS1408|WSSTUBE0025|AM#200104101|AM#200104100|AM#200104112|AM#200104111|AM#200102016|100104105|tomcat-users.xml"
