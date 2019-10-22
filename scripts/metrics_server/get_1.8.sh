#!/bin/bash
base_url="https://raw.githubusercontent.com/kubernetes-incubator/metrics-server/master/deploy/1.8%2B/"
for file in `cat list`
do 
  wget -P 1.8+/ "${base_url}${file}"
  #echo "${base_url}${file}"
done
