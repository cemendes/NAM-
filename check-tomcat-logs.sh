#!/bin/bash


    if [[ -d /var/opt/novell/nam/logs/idp/tomcat ]]; then
        PLATFORM=IDP
        CATALINA=/var/opt/novell/nam/logs/idp/tomcat/catalina.out
        OUTPUT=`grep -i -E "warning.*artifact|severe" $CATALINA | grep -vE "WSS1408|WSSTUBE0025|AM#200104101|AM#200104100|AM#200104112|AM#200104111|AM#200102016|100104105|tomcat-users.xml"`
    else
        PLATFORM=ESP
        CATALINA=/var/opt/novell/nam/logs/mag/tomcat/catalina.out
        OUTPUT=`grep -i -E "warning.*artifact|severe" $CATALINA`
    fi

JUNK1=/tmp/junk1.txt
JUNK2=/tmp/junk2.txt

    if [ ! -f $JUNK1 ]; then
        touch $JUNK1
    elif [ ! -f $JUNK2 ]; then
        touch $JUNK2
    fi

echo $OUTPUT > $JUNK1

cmp -s $JUNK1 $JUNK2

   if [[ $? -ne 0 ]]; then
       cat $JUNK1 > $JUNK2
       mail -s "$PLATFORM has issues" carlos.mendes@microfocus.com < $JUNK1
   fi