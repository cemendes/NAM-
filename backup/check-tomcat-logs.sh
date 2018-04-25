#!/bin/bash
#Variables used in the script
JUNK1=/tmp/junk1.txt
JUNK2=/tmp/junk2.txt
EXCLUDE_ERRORS="WSS1408|WSSTUBE0025|AM#200104101|AM#200104100|AM#200104112|AM#200104111|AM#200102016|100104105|tomcat-users.xml|(without an AxisFault)"
INCLUDE_ERRORS="warning.*artifact|severe|AxisFault"
PROD_SRVS=(L4DVEPAP2789 NAMIdp.novell.com L4DVEPAP2790 L4DVEPAP2791 L4DVEPAP2792 L4DVIPAP2788 l98vepap2898 l98vepap2899 l98vepap2901 l98vepap2902 l98vipap2897 L4DVIPAP2788)
QC_SRVS=(L4dveqap2744 L4dveqap2745 L4dveqap2746 L4dveqap2747 L4dviqap2750)
DEV_SRVS=(l4dvidap2646 l4dvidap2647 l4dvidap2648)
SAND_SRVS=(L4dvidap2269 L4dvidap2270 L4dvidap2277)
NUM_OCCURRENCES=""
CATALINA=""

# Create empty files. If the files do not exist, the first time they are created it will generate a false positive and an email with an empty body
#will be sent.
    if [ ! -f $JUNK1 ]; then
        touch $JUNK1
    elif [ ! -f $JUNK2 ]; then
        touch $JUNK2
    fi

#Check if the server is an IDP or an ESP
    if [[ -d /var/opt/novell/nam/logs/idp/tomcat ]]; then
        PLATFORM=IDP
        #CATALINA=/var/opt/novell/nam/logs/idp/tomcat/catalina.out
        CATALINA=/var/opt/novell/nam/logs/idp/tomcat/catalina.out-`date +%Y%m%d`-*
        grep -i -E "$INCLUDE_ERRORS" $CATALINA | grep -vE "$EXCLUDE_ERRORS" > $JUNK1
    else
        PLATFORM=ESP
        #CATALINA=/var/opt/novell/nam/logs/mag/tomcat/catalina.out
        CATALINA=/var/opt/novell/nam/logs/mag/tomcat/catalina.out-`date +%Y%m%d`-*
        grep -i -E "$INCLUDE_ERRORS" $CATALINA | grep -vE "$EXCLUDE_ERRORS" > $JUNK1
    fi

#Determine the server lifecycle
    for i in ${PROD_SRVS[@]}; do
        if [[ ${#PLATFORM} -ne 3 ]]; then
            break
        elif [[ $i == $HOSTNAME ]]; then
            PLATFORM="PROD $PLATFORM"
            break
        fi
    done
    for i in ${QC_SRVS[@]}; do
        if [[ ${#PLATFORM} -ne 3 ]]; then
            break
        elif [[ $i == $HOSTNAME ]]; then
            PLATFORM="QC $PLATFORM"
            break
        fi
    done
    for i in ${DEV_SRVS[@]}; do
        if [[ ${#PLATFORM} -ne 3 ]]; then
            break
        elif [[ $i == $HOSTNAME ]]; then
            PLATFORM="DEV $PLATFORM"
            break
        fi
    done
    for i in ${SAND_SRVS[@]}; do
        if [[ ${#PLATFORM} -ne 3 ]]; then
            break
        elif [[ $i == $HOSTNAME ]]; then
            PLATFORM="Sandbox $PLATFORM"
            break
        fi
    done

#Number of error messages in the file.
NUM_OCCURRENCES=`wc -l $JUNK1 | cut -d' ' -f 1`

#Logic to avoid sending the same message every time. It will only send a new message if a new error occurred.
cmp -s $JUNK1 $JUNK2
   if [[ $? -ne 0 && -s $JUNK1 ]]; then
       cat $JUNK1 > $JUNK2
       mail -s "$PLATFORM has seen SEVERE or WARNING errors $NUM_OCCURRENCES times" carlos.mendes@microfocus.com < $JUNK1
   fi