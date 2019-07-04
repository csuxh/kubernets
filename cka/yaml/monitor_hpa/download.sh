#!/bin/bash
url_base='https://github.com/kubernetes-incubator/metrics-server/raw/master/deploy/1.8%2B/'
#list=`cat list`
for i in `cat list`
do
  wget ${url_base}${i}
done
