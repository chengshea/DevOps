#!/bin/bash

declare -A hn=(["192.168.56.101"]="node01" ["192.168.56.108"]="node02" ["192.168.56.109"]="node03")

local=$(ip a | grep 192  | sed  's/\(.*\)\(192\.168\.56\..*\)\/\(.*\)/\2/g')

chang(){
	hostnamectl set-hostname  $1
	sed -i s#setHostname#$1#g  /etc/hosts
}



for key in ${!hn[@]}
do
    echo $local"===" $key
    [ "$local" == "$key" ] && {  chang ${hn[$key]} && exit 1;}
    echo  $key
done