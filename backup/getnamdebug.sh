#!/bin/bash
MYDATE=`/bin/date +%F`
DEBUG_DIR=/var/opt/novell/debug
JUNK_DIR=$DEBUG_DIR/junk
MYTTY=`tty | cut -c6-10`
#PROD_SRVS=(L4DVEPAP2789 L4DVEPAP2790 L4DVEPAP2791 L4DVEPAP2792 L4DVIPAP2788 l98vepap2898 l98vepap2899 l98vepap2901 l98vepap2902 l98vipap2897 L4DVIPAP2788)
#QC_SRVS=(L4dveqap2744 L4dveqap2745 L4dveqap2746 L4dveqap2747 L4dviqap2750)
ERROR_MSG=SEVERE

    if [[ -d /var/opt/novell/nam/logs/idp/tomcat && -d /var/opt/novell/nam/logs/mag && -d /var/opt/novell/nam/logs/adminconsole ]]; then
        mkdir -p $JUNK_DIR/$HOSTNAME-APPLIANCE
        JUNK_DIR=$JUNK_DIR/$HOSTNAME-APPLIANCE
    elif [[ -d /var/opt/novell/nam/logs/idp/tomcat ]]; then
        mkdir -p $JUNK_DIR/$HOSTNAME-IDP
        JUNK_DIR=$JUNK_DIR/$HOSTNAME-IDP
    elif [[ -d /var/opt/novell/nam/logs/mag ]]; then
        mkdir -p $JUNK_DIR/$HOSTNAME-AG
        JUNK_DIR=$JUNK_DIR/$HOSTNAME-AG
    elif [[ -d /var/opt/novell/nam/logs/adminconsole ]]; then
        mkdir -p $JUNK_DIR/$HOSTNAME-AC
        JUNK_DIR=$JUNK_DIR/$HOSTNAME-AC
    fi

echo "These are the tarball files that exist at $DEBUG_DIR"
ls -la $DEBUG_DIR/*.tbz 2> /dev/null
printf "\n"
printf "What string do you want to add to the file name? For instance, add a word for the issue you are having\nand a letter or number in case you need to send multiple log files. \nFor instance: loginfailure-A"
printf "\n"
read ADDNAME

# IDP new file names
IDP_CATALINA=$JUNK_DIR/catalina.out-$MYDATE-AG-$HOSTNAME-$ADDNAME.log
IDP_TARBALL=$DEBUG_DIR/IDP-LOGS-$HOSTNAME-$MYDATE-$ADDNAME.tbz
IDP_PCAP=$JUNK_DIR/tcpdump-$MYDATE-IDP-$HOSTNAME-$ADDNAME.pcap

# AG new file names
AG_ERROR_LOG=$JUNK_DIR/error_log-$MYDATE-AG-$HOSTNAME-$ADDNAME.log
AG_HTTPHEADERS=$JUNK_DIR/httpheaders-$MYDATE-AG-$HOSTNAME-$ADDNAME.log
AG_SOAPMESSAGES=$JUNK_DIR/soapmessages-$MYDATE-AG-$HOSTNAME-$ADDNAME.log
AG_CATALINA=$JUNK_DIR/catalina.out-$MYDATE-AG-$HOSTNAME-$ADDNAME.log
AG_TARBALL=$DEBUG_DIR/AG-LOGS-$MYDATE-$HOSTNAME-$ADDNAME.tbz
AG_PCAP=$JUNK_DIR/tcpdump-$MYDATE-AG-$HOSTNAME-$ADDNAME.pcap

# AC new file names
AC_PCAP=$JUNK_DIR/tcpdump-$MYDATE-AC-$HOSTNAME-$ADDNAME.pcap
AC_TARBALL=$DEBUG_DIR/AC-LOGS-$MYDATE-$HOSTNAME-$ADDNAME.tbz
AC_CATALINA=$JUNK_DIR/catalina.out-$MYDATE-AC-$HOSTNAME-$ADDNAME.log
AC_APP_CC=$JUNK_DIR/app_cc.0.log-$MYDATE-AC-$HOSTNAME-$ADDNAME.log
AC_APP_SC=$JUNK_DIR/app_sc.0.log-$MYDATE-AC-$HOSTNAME-$ADDNAME.log
AC_MANAGER=$JUNK_DIR/manager.0.log-$MYDATE-AC-$HOSTNAME-$ADDNAME.log
AC_PLATFORM=$JUNK_DIR/platform.0.log-$MYDATE-AC-$HOSTNAME-$ADDNAME.log
AC_NDSD=$JUNK_DIR/ndsd.log-$MYDATE-AC-$HOSTNAME-$ADDNAME.log

# Appliance file names
APPLIANCE_TARBALL=$DEBUG_DIR/AG-APPLIANCE-LOGS-$MYDATE-$HOSTNAME-$ADDNAME.tbz




echo "Press CTRL + C to stop."

    if [[ -d /var/opt/novell/nam/logs/idp/tomcat && -d /var/opt/novell/nam/logs/mag && -d /var/opt/novell/nam/logs/adminconsole ]]; then
        trap "cd $DEBUG_DIR/junk ; tar cjvf $APPLIANCE_TARBALL * > /dev/null 2>&1 ; rm -r $HOSTNAME-APPLIANCE > /dev/null 2>&1 ; pkill -t $MYTTY tailf ; pkill -t $MYTTY tcpdump ; echo \"Tarball is at \" $APPLIANCE_TARBALL ; exit" SIGHUP SIGINT SIGTERM
        /usr/bin/tailf /var/opt/novell/nam/logs/idp/tomcat/catalina.out > $IDP_CATALINA &
        /usr/bin/tailf /var/opt/novell/nam/logs/mag/tomcat/catalina.out > $AG_CATALINA &
        /usr/bin/tailf /var/opt/novell/nam/logs/mag/apache2/error_log > $AG_ERROR_LOG &
        /usr/bin/tailf /var/opt/novell/nam/logs/mag/apache2/httpheaders > $AG_HTTPHEADERS &
        /usr/bin/tailf /var/opt/novell/nam/logs/mag/apache2/soapmessages > $AG_SOAPMESSAGES &
        /usr/bin/tailf /var/opt/novell/nam/logs/adminconsole/tomcat/catalina.out > $AC_CATALINA &
        /usr/bin/tailf /var/opt/novell/nam/logs/adminconsole/volera/app_cc.0.log > $AC_APP_CC &
        /usr/bin/tailf /var/opt/novell/nam/logs/adminconsole/volera/app_sc.0.log > $AC_APP_SC &
        /usr/bin/tailf /var/opt/novell/nam/logs/adminconsole/volera/manager.0.log > $AC_MANAGER &
        /usr/bin/tailf /var/opt/novell/nam/logs/adminconsole/volera/platform.0.log > $AC_PLATFORM &
        /usr/bin/tailf /var/opt/novell/eDirectory/log/ndsd.log > $AC_NDSD &
        /usr/bin/less /var/log/messages > /tmp/junk33
        /usr/sbin/tcpdump -s 65535 -i any -w $APPLIANCE_TARBALL -C 200 -Z root > /dev/null 2>&1
    elif [[ -d /var/opt/novell/nam/logs/idp/tomcat ]]; then
        trap "cd $DEBUG_DIR/junk ; tar cjvf $IDP_TARBALL * > /dev/null 2>&1 ; rm -r $HOSTNAME-IDP > /dev/null 2>&1 ; pkill -t $MYTTY tailf ; pkill -t $MYTTY tcpdump ; echo \"Tarball is at \" $IDP_TARBALL ; exit" SIGHUP SIGINT SIGTERM SIGUSR1
        /usr/bin/tailf /var/opt/novell/nam/logs/idp/tomcat/catalina.out > $IDP_CATALINA &
        /usr/sbin/tcpdump -s 65535 -i any -w $IDP_PCAP -C 200 -Z root > /dev/null 2>&1 &
        echo "About to kill the script"
        tailf $IDP_CATALINA | grep -i --color -m1 -h "$1" &>/dev/null;
        kill -15 $$
    elif [ -d /var/opt/novell/nam/logs/mag ]; then
        trap "cd $DEBUG_DIR/junk ; tar cjvf $AG_TARBALL * > /dev/null 2>&1 ; rm -r $HOSTNAME-AG > /dev/null 2>&1 ; pkill -t $MYTTY tailf ; pkill -t $MYTTY tcpdump ; echo \"Tarball is at \" $AG_TARBALL ; exit" SIGHUP SIGINT SIGTERM
        /usr/bin/tailf /var/opt/novell/nam/logs/mag/tomcat/catalina.out > $AG_CATALINA &
        /usr/bin/tailf /var/opt/novell/nam/logs/mag/apache2/error_log > $AG_ERROR_LOG &
        /usr/bin/tailf /var/opt/novell/nam/logs/mag/apache2/httpheaders > $AG_HTTPHEADERS &
        /usr/bin/tailf /var/opt/novell/nam/logs/mag/apache2/soapmessages > $AG_SOAPMESSAGES &
        /usr/sbin/tcpdump -s 65535 -i any -w $AG_PCAP -C 200 -Z root > /dev/null 2>&1
    elif [[ -d /opt/novell/nam/adminconsole ]]; then
        trap "cd $DEBUG_DIR/junk ; tar cjvf $AC_TARBALL * > /dev/null 2>&1 ; rm -r $HOSTNAME-AC > /dev/null 2>&1 ; pkill -t $MYTTY tailf ; pkill -t $MYTTY tcpdump ; echo \"Tarball is at \" $AC_TARBALL ; exit" SIGHUP SIGINT SIGTERM
        /usr/bin/tailf /var/opt/novell/nam/logs/adminconsole/tomcat/catalina.out > $AC_CATALINA &
        /usr/bin/tailf /var/opt/novell/nam/logs/adminconsole/volera/app_cc.0.log > $AC_APP_CC &
        /usr/bin/tailf /var/opt/novell/nam/logs/adminconsole/volera/app_sc.0.log > $AC_APP_SC &
        /usr/bin/tailf /var/opt/novell/nam/logs/adminconsole/volera/manager.0.log > $AC_MANAGER &
        /usr/bin/tailf /var/opt/novell/nam/logs/adminconsole/volera/platform.0.log > $AC_PLATFORM &
        /usr/bin/tailf /var/opt/novell/eDirectory/log/ndsd.log > $AC_NDSD &
        /usr/sbin/tcpdump -s 65535 -i any -w $AC_PCAP -C 200 -Z root > /dev/null 2>&1
    fi