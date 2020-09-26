#!/bin/sh

var=$1
temp=admin-token-zjqc5
cret=${var:-$temp}

kubectl describe  secrets $cret -n kube-system  | grep token: | awk '{print $2}'