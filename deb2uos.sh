#!/bin/bash

#解压包
function extract {
  
  dpkg-deb -R inputs/$1 src/$2
}

#初始化目录
function initDir {
  
  entriesPath=src/$2-$3-$4/opt-tmp/apps/$2/entries
  filesPath=src/$2-$3-$4/opt-tmp/apps/$2/
  mkdir -p $entriesPath
  mkdir -p $filesPath

cat > src/$2-$3-$4/opt-tmp/apps/$2/info << EOF  
  {
  "appid": "$2", 
  "name": "$1",
  "version": "$3",
  "arch": ["$4"],
  "permissions": {
    "autostart": false,
    "notification": false,
    "trayicon": false,
    "clipboard": false,
    "account": false,
    "bluetooth": false,
    "camera": false,
    "audio_record": false,
    "installed_apps": false
                }
  }  
EOF

find src/$2-$3-$4/DEBIAN/* |grep -v control |xargs rm -rf

}

#压缩新包
function build {
  dpkg-deb -b src/$1-$2-$3/ outputs/$1_$2_$4.deb &> /dev/null
}

#提取应用名、包名、版本号
function cutStr {
  
  fileName=`echo ${1%.*}`
  appName=`echo $fileName |awk -F_ '{print $1}'`
  packageName=`echo $fileName |awk -F_ '{print $2}'`
  version=`echo $fileName |awk -F_ '{print $3}'`
  Arch=`echo $fileName |awk -F_ '{print $4}'`
  if [ x$Arch = x"X86" ];then
    arch="amd64"
  elif [ x$Arch = x"ARM" ];then
    arch="arm64"
  else 
  	echo "无此架构"
    errorLog $deb
  fi
  printLog $fileName
  printLog $appName
  printLog $packageName
  printLog $version
  printLog $arch
}

function copySourceFile {
  find ./src/$1-$2/ -name "applications" |xargs -i cp -r {} $entriesPath
  find ./src/$1-$2/ -name "icons"  |xargs -i cp -r {} $entriesPath
  mkdir $filesPath/files
  cp -r `ls -d ./src/$1-$2/* |grep -v DEBIAN|grep -v opt-tmp` $filesPath/files
  rm -rf ./src/$1-$2/opt ./src/$1-$2/bin
  mv ./src/$1-$2/opt-tmp ./src/$1-$2/opt
}

function modifyName {
  sed -i "/.*Package:\ */c\Package: $1" src/$1-$2-$3/DEBIAN/control
  sed -i "/.*Architecture:\ */c\Architecture: $3" src/$1-$2-$3/DEBIAN/control
  for desktopFile in `find ./src/$1-$2-$3/opt/apps/$1/entries/applications/ -name "*.desktop"`
  do
    echo $desktopFile
    execPath=`cat $desktopFile |grep Exec |awk -F" " '{print $1}'|awk -F= '{print $2}'|uniq`
    execFileName=`echo ${execPath##*/} |tr -d '"'`
    newExecPath="/opt/apps"`find ./src/$1-$2-$3/opt/apps/$1/files -type f -name "$execFileName" |awk -F"opt/apps" '{print $2}'`
    echo "execPath:"$execPath
    echo "execFileName:"$execFileName
    echo "newExecPath:"$newExecPath
    # exit 0
    sed -i "/.*Exec=*/c\Exec=$newExecPath"  $desktopFile
  done
}

function printLog {
  echo $1 >> log.txt
}

function errorLog {
  echo $1 >> error.txt
}

function main {
  
  for deb in `ls inputs`
  do 
    printLog "----------"
    printLog $deb
    echo $deb
    printLog "[0%]start!"
    printLog "[10%]cutStr"
    cutStr $deb
    printLog "[20%]extract"
    extract $deb $packageName-$version-$arch
    printLog "[40%]initDir"
    initDir $appName $packageName $version $arch
    printLog "[60%]copySourceFile"
    copySourceFile $packageName-$version $arch
    printLog "[80%]modifyName"
    modifyName $packageName $version $arch
    printLog "[90%]build"
    build $packageName $version $arch $Arch 
    printLog "[100%]Finished!"
  done
  
}

if [ x$1 = x"build" ];then
  main
  echo "Finished！"
else 
  rm -rf src/* outputs/* log.txt error.txt
  echo "已清理完成"
  echo "执行./deb2uos.sh build"
fi
