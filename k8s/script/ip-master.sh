#!/bin/bash

#	 nics=$(route -n | grep ^0.0.0.0 | awk '{print $8}') 
#	for nic in $nics
#	do
#	     ip=$(ifconfig $nic | grep -E 'inet\s+' | sed -E -e 's/inet\s+\S+://g' | awk '{print $1}')
#	    echo $ip [$nic]
#	done
ipAddr=$( ip route show | grep 'enp\|eth\|wlan\|ppp'| grep src | awk -F ' ' '{print $(NF-2)}')
echo $ipAddr
  
localName=$(echo $0 | sed 's/\(.*\)-\(.*\)\.\(.*\)/\2/g')
localmaster=https://192.168.99.161
masterIp=https://192.168.99.158
node02Ip=https://192.168.99.160





eval localIp=$(echo '$'local"$localName")

eval mIp=$(echo '$'"$localName"Ip)

echo $localName:$localIp  
echo $localName:$mIp