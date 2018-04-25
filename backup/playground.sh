#!/bin/bash

checksrvcycle () {
    PROD_SRVS=(L4DVEPAP2789 L4DVEPAP2790 L4DVEPAP2791 L4DVEPAP2792 L4DVIPAP2788 l98vepap2898 l98vepap2899 l98vepap2901 l98vepap2902 l98vipap2897 L4DVIPAP2788)
    QC_SRVS=(L4dveqap2744  NAMIdp.novell.com L4dveqap2745 L4dveqap2746 L4dveqap2747 L4dviqap2750)
    DEV_SRVS=(l4dvidap2646 l4dvidap2647 l4dvidap2648)
    for i in ${PROD_SRVS[@]}; do
        if [[ $i == $HOSTNAME ]]; then
            PLATFORM="PROD $PLATFORM"
            exit 0
        fi
    done
    for i in ${QC_SRVS[@]}; do
        if [[ $i == $HOSTNAME ]]; then
            PLATFORM="QC $PLATFORM"
            exit 0
        fi
    done
    for i in ${DEV_SRVS[@]}; do
        if [[ $i == $HOSTNAME ]]; then
            PLATFORM="DEV $PLATFORM"
            exit 0
        fi
    done
}


checksrvcycle

  #     if [[ -z $1 ]]; then
  #       for i in ${PROD_SRVS[@]}; do
  #         if [[ $i == $HOSTNAME ]]; then
  #
  #         elif [[ $i == $QC_SRVS ]]; then
  #           PLATFORM="QC $PLATFORM"
  #         fi
  #     fi
  # done


