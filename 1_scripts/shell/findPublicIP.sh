#!/bin/bash

## Check if provided IP Address is valid
if [[ ! "${1}" =~ (^([01]{,1}[0-9]{1,2}|2[0-4][0-9]|25[0-5])\.([01]{,1}[0-9]{1,2}|2[0-4][0-9]|25[0-5])\.([01]{,1}[0-9]{1,2}|2[0-4][0-9]|25[0-5])\.([01]{,1}[0-9]{1,2}|2[0-4][0-9]|25[0-5]))$ ]]; then
  raise error "${1} is an invalid ip to search for";
fi

externalMac=`cat /sys/class/net/external/address`

for pubV4 in `curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/${externalMac}/ipv4-associations/`
do
    privV4=`curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/${externalMac}/ipv4-associations/${pubV4}`
    if [ ${privV4} == ${1} ]; then
        echo "Private IP <${1}> maps to Public IP <${pubV4}>"
        exit
    fi
done

echo "Private IP <${1}> did NOT map to a Public IP"
