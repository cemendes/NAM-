#!/bin/bash
#PROD_SRVS=(L4DVEPAP2789 L4DVEPAP2790 L4DVEPAP2791 L4DVEPAP2792 L4DVIPAP2788 l98vepap2898 l98vepap2899 l98vepap2901 l98vepap2902 l98vipap2897 L4DVIPAP2788)

JUNK1=/tmp/junk1.txt
JUNK2=/tmp/junk2.txt

    if [ ! -f $JUNK1 ]; then
        touch $JUNK1
    elif [ ! -f $JUNK2 ]; then
        touch $JUNK2
    fi

    if [[ -d /var/opt/novell/nam/logs/idp/tomcat ]]; then
        PLATFORM=IDP
        CATALINA=/var/opt/novell/nam/logs/idp/tomcat/catalina.out
        OUTPUT=`grep -i -E "warning.*artifact|severe" $CATALINA | grep -vE "WSS1408|WSSTUBE0025|AM#200104101|AM#200104100|AM#200104112|AM#200104111|AM#200102016|100104105|tomcat-users.xml" > $JUNK1`
    else
        PLATFORM=ESP
        CATALINA=/var/opt/novell/nam/logs/mag/tomcat/catalina.out
        OUTPUT=`grep -i -E "warning.*artifact|severe" $CATALINA > $JUNK1`
    fi

# checksrvcycle() {
      PROD_SRVS=(xuxu NAMIdp.novell.com NAMAG.novell.com bunda)
      QC_SRVS=(L4dveqap2744 L4dveqap2745 L4dveqap2746 L4dveqap2747 L4dviqap2750)
      for i in ${PROD_SRVS[@]}; do
        if [[ $i == $HOSTNAME ]]; then
        PLATFORM="PROD $PLATFORM"
        fi
      done
      for i in ${QC_SRVS[@]}; do
        if [[ $i == $HOSTNAME ]]; then
        PLATFORM="QC $PLATFORM"
        fi
      done
# }

NUM_OCCURRENCES=`wc -l $JUNK1 | cut -d' ' -f 1`

cmp -s $JUNK1 $JUNK2

   if [[ $? -ne 0 && -s $JUNK1 ]]; then
       cat $JUNK1 > $JUNK2
       mail -s "$PLATFORM has seen SEVERE or WARNING errors $NUM_OCCURRENCES times" carlos.mendes@microfocus.com < $JUNK1
   fi