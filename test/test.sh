#!/bin/bash
for deb in `ls inputs`
do
    if [ x$deb = x"deb.txt" ]||[ x$deb = x"download.sh" ];then
      continue
    fi
    echo $deb
done