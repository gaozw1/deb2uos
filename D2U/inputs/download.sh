#!/bin/bash
if [[ $1 == "clear" ]]; then
    echo "clearing deb"
    rm -rf *.deb
else
    for file in `cat deb.txt`
    do
        link=`echo $file |awk -F'|' '{print $1}'`
        newName=`echo $file |awk -F'|' '{print $2}'`
        if [ -f $newName ];then
            continue
        fi
        echo -e "\033[34m[downloading]\033[0m" $newName
        wget $link
        mv "${link##*/}" "$newName"
    done
fi
echo "Finish~"