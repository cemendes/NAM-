#!/bin/bash
#Variables used in the script
JUNK1=/apps/NetIQ/tmp/junk1.txt
JUNK2=/apps/NetIQ/tmp/junk2.txt
EXCLUDE_ERRORS='WSS1408|WSSTUBE0025|AM#200104101|AM#200104100|AM#200104102|AM#200104112|AM#200104111|AM#200102016|100104105|tomcat-users.xml|\(without an AxisFault\)|Log file\(s\) have crossed|Warning\: Invalid resource key\: SOAP fault\: Artifact resolution failed at IDP. No prefix!|net.microfocus.impersonation.service.v1.application.ImpersonationApplication|    Level: SEVERE|Could not get client certificate| Loading Trusted Provider \: \{1\}|Error verifying metadata certificates while loading trusted provider'
#INCLUDE_ERRORS='SOAP fault: Artifact resolution failed at IDP </amLogEntry>|severe|AxisFault'
INCLUDE_ERRORS='IDP response failed to authenticate'
PROD_SRVS=(L4DVEPAP2789 L4DVEPAP2790 l4dvepap2791 l4dvepap2792)
DR_SRVS=(l98vepap2898 l98vepap2899 l98vepap2901 l98vepap2902)
PROD_SRVS=(l4dvepap2789 l4dvepap2790 l4dvepap2791 l4dvepap2792 l4dvipap2788 l4dvipap2788)
QC_SRVS=(l4dveqap2744 l4dveqap2745 l4dveqap2746 l4dveqap2747 l4dviqap2750)
DEV_SRVS=(l4dvidap2646 l4dvidap2647 l4dvidap2648)
SAND_SRVS=(l4dvidap2269 l4dvidap2270 l4dvidap2277)
NUM_OCCURRENCES=""
CATALINA=""
CATALINA_GZ=""

# Create empty files. If the files do not exist, the first time they are created it will generate a false positive and an email with an empty body
#will be sent.
    if [ ! -f $JUNK1 ]; then
        touch $JUNK1
        chmod 666 $junk1
    elif [ ! -f $JUNK2 ]; then
        touch $JUNK2
        chmod 666 $JUNK2
    fi

#Check if the server is an IDP or an ESP
    if [[ -d /var/opt/novell/nam/logs/idp/tomcat ]]; then
        PLATFORM=IDP
        CATALINA=/var/opt/novell/nam/logs/idp/tomcat/catalina.out
        CATALINA_GZ=/var/opt/novell/nam/logs/idp/tomcat/catalina.out-`date +%Y%m%d`-*
        zgrep -i -E "$INCLUDE_ERRORS" $CATALINA $CATALINA_GZ | grep -vE "$EXCLUDE_ERRORS" > $JUNK1
    else
        PLATFORM=ESP
        CATALINA=/var/opt/novell/nam/logs/mag/tomcat/catalina.out
        CATALINA_GZ=/var/opt/novell/nam/logs/mag/tomcat/catalina.out-`date +%Y%m%d`-*
        zgrep -i -E "$INCLUDE_ERRORS" $CATALINA $CATALINA_GZ | grep -vE "$EXCLUDE_ERRORS" > $JUNK1
    fi

# check_lifecycle () {
#     echo $1
#     local -n array=$1
#     echo "${array}"
#     # if [[ ${#PLATFORM} -eq 3 ]]; then
#     #     for i in $1; do
#     #         if [[ $i == $HOSTNAME ]]; then
#     #         PLATFORM="PROD $PLATFORM"
#     #         break
#     #         fi
#     #     done
#     # fi
# }
# check_lifecycle "${PROD_SRVS[@]}"
#Determine the server lifecycle.
    if [[ ${#PLATFORM} -eq 3 ]]; then
        for i in ${PROD_SRVS[@]}; do
            if [[ $i == $HOSTNAME ]]; then
            PLATFORM="PROD $PLATFORM"
            break
            fi
        done
    fi
    if [[ ${#PLATFORM} -eq 3 ]]; then
        for i in ${QC_SRVS[@]}; do
            if [[ $i == $HOSTNAME ]]; then
            PLATFORM="QC $PLATFORM"
            break
            fi
        done
    fi
    if [[ ${#PLATFORM} -eq 3 ]]; then
        for i in ${DEV_SRVS[@]}; do
            if [[ $i == $HOSTNAME ]]; then
            PLATFORM="DEV $PLATFORM"
            break
            fi
        done
    fi
    if [[ ${#PLATFORM} -eq 3 ]]; then
        for i in ${SAND_SRVS[@]}; do
            if [[ $i == $HOSTNAME ]]; then
            PLATFORM="SAN $PLATFORM"
            break
            fi
        done
    fi

    if [[ ${#PLATFORM} -eq 3 ]]; then
    for i in ${DR_SRVS[@]}; do
        if [[ $i == $HOSTNAME ]]; then
        PLATFORM="DR $PLATFORM"
        break
        fi
    done
    fi
    #     if [[]]; then
    #         break

    #         break
    #     fi
    # done
    # for i in ${QC_SRVS[@]}; do
    #     if [[ ${#PLATFORM} -ne 3 ]]; then
    #         break
    #     elif [[ $i == $HOSTNAME ]]; then
    #         PLATFORM="QC $PLATFORM"
    #         break
    #     fi
    # done
    # for i in ${DEV_SRVS[@]}; do
    #     if [[ ${#PLATFORM} -ne 3 ]]; then
    #         break
    #     elif [[ $i == $HOSTNAME ]]; then
    #         PLATFORM="DEV $PLATFORM"
    #         break
    #     fi
    # done
    # for i in ${SAND_SRVS[@]}; do
    #     if [[ ${#PLATFORM} -ne 3 ]]; then
    #         break
    #     elif [[ $i == $HOSTNAME ]]; then
    #         PLATFORM="Sandbox $PLATFORM"
    #         break
    #     fi
    # done

#Number of error messages in the file.
NUM_OCCURRENCES=`wc -l $JUNK1 | cut -d' ' -f 1`

#Logic to avoid sending the same message every time. It will only send a new message if a new error occurred.
cmp -s $JUNK1 $JUNK2

   if [[ $? -ne 0 && -s $JUNK1 ]]; then
       cat $JUNK1 > $JUNK2
       mail -r $HOSTNAME -s "$PLATFORM - SEVERE or WARNING errors: $NUM_OCCURRENCES total" carlos.mendes@microfocus.com < $JUNK1
   fi
