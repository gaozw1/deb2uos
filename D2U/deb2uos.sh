#!/bin/bash

#记录是否报错
ERRORSIGNL=0

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
  arch=`echo $fileName |awk -F_ '{print $4}'`
  if [ x$arch = x"amd64" ];then
    Arch="X86"
  elif [ x$arch = x"arm" ] || [ x$arch = x"arm64" ];then
    Arch="ARM"
  else 
  	echo "Err: 无此架构"
    errorLog "无此架构  "$deb
    ERRORSIGNL=1
  fi
  printLog ">fileName: "$fileName
  printLog ">appName: "$appName
  printLog ">packageName: "$packageName
  printLog ">version: "$version
  printLog ">arch: "$arch
}

function copySourceFile {
  find ./src/$1-$2/ -name "applications" |xargs -i cp -r {} $entriesPath
  if [[ -n `find ./src/$1-$2/ -name "icons"` ]];then
    find ./src/$1-$2/ -name "icons" |xargs -i cp -r {} $entriesPath
  elif [[ -n `find ./src/$1-$2/ -name "pixmaps"` ]];then
    find ./src/$1-$2/ -name "pixmaps" |xargs -i cp -r {} $entriesPath/icons
  else
    echo "Err: 缺少icon文件"
    errorLog "找不到icon文件  $deb"
    ERRORSIGNL=1
  fi
  mkdir $filesPath/files
  cp -r `ls -d ./src/$1-$2/* |grep -v DEBIAN|grep -v opt-tmp` $filesPath/files
  #清除多余文件
  rm -rf ./src/$1-$2/opt ./src/$1-$2/bin ./src/$1-$2/usr/bin ./src/$1-$2/usr/lib ./src/$1-$2/usr/etc ./src/$1-$2/etc ./src/$1-$2/var
  mv ./src/$1-$2/opt-tmp ./src/$1-$2/opt
  if [ $ERRORSIGNL = 1 ];then
      rm -rf ./src/$1-$2
  fi
  
}

function modifyName {
  sed -i "/.*Package:\ */c\Package: $1" src/$1-$2-$3/DEBIAN/control
  sed -i "/.*Architecture:\ */c\Architecture: $3" src/$1-$2-$3/DEBIAN/control
  if [[ -n `find ./src/$1-$2-$3/opt/apps/$1/entries/ -name "*.desktop"` ]];then
    desktopFile=""
    execPath=""
    execFileName=""
    newExecPath=""
    #可能有多个desktop文件
    for desktopFile in `find ./src/$1-$2-$3/opt/apps/$1/entries/applications/ -name "*.desktop"`
    do
    echo $desktopFile
      #可能有多组[Desktop Entry]，因此会有多个Exec
      execPath=`cat $desktopFile |grep Exec |awk -F" " '{print $1}'|awk -F= '{print $2}'|uniq`
      iconPath=`cat $desktopFile |grep Icon|awk -F= '{print $2}'|uniq`
      printLog "iconPath:"$iconPath
      #如果图标是绝对路径
      if [[ -n `echo $iconPath |grep /` ]];then
        newIconPath="/opt/apps/$1/files"$iconPath
        if [[ -f $newIconPath ]];then
        printLog "newIconPath: $newIconPath"
        else
        #图标路径不存在时，使用icons目录中的图标
        newIconPath="/opt/"`find ./src/$1-$2-$3/opt/apps/$1/entries/icons/ -name "*.*"|awk "FNR == 1"|awk -F/opt/ '{print $2}'`
        printLog "newIconPath: $newIconPath"
        fi
      fi
      sed -i "/.*Icon=*/c\Icon=$newIconPath"  $desktopFile
      execFileName=`echo ${execPath##*/} |tr -d '"'`
      find ./src/$1-$2-$3/opt/apps/$1/files -type f -name "$execFileName"| while read exe
      do
      printLog "exe: "$exe
        #判断可执行文件路径，若文件类型为ELF，或在files/usr/bin目录下，则默认是可执行文件
        if [[ -n `echo $exe|xargs -i file {} |grep ELF` ]] || [[ -n `echo $exe|grep "/files/usr/bin/"` ]] || [[ -n `echo $exe|grep "/files/usr/games"` ]]
          then
          echo "/opt/apps"`echo $exe |awk -F"opt/apps" '{print $2}'` > .newExecPath
          break
        fi
      done
      newExecPath=`cat .newExecPath`
      rm .newExecPath
      # echo "execPath:"$execPath
      # echo "execFileName:"$execFileName
      # echo "newExecPath:"$newExecPath
      
      printLog "execPath:"$execPath
      printLog "execFileName:"$execFileName
      printLog "newExecPath:"$newExecPath
      if [ x$newExecPath = x"" ];then
        echo "Err: 可执行文件路径为空"
        printLog $deb" 可执行文件路径为空"
        ERRORSIGNL=1
      else
      sed -i "/.*Exec=*/c\Exec=$newExecPath"  $desktopFile
      fi

      #删除“OnlyShowIn=”字段，避免程序不能在dde中显示
      sed -i '/OnlyShowIn=/d'  $desktopFile
    done
    
  else
    echo "Err: 缺少desktop文件"
    errorLog "无desktop文件  $deb"
    ERRORSIGNL=1
  fi
  if [ $ERRORSIGNL = 1 ];then
    rm -rf ./src/$1-$2-$3
  fi
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
    ERRORSIGNL=0
    if [ x$deb = x"deb.txt" ]||[ x$deb = x"download.sh" ];then
      continue
    fi
    printLog "----------"
    printLog $deb
    echo "-------"
    echo $deb
    printLog "[0%]start!"
    printLog "[10%]cutStr"
    cutStr $deb
    if [ $ERRORSIGNL = 1 ];then
      printLog "cutStr error"
      continue
    fi
    printLog "[20%]extract"
    extract $deb $packageName-$version-$arch
    if [ $ERRORSIGNL = 1 ];then
      printLog "extract error"
      continue
    fi
    printLog "[40%]initDir"
    initDir $appName $packageName $version $arch
    if [ $ERRORSIGNL = 1 ];then
      printLog "initDir error"
      continue
    fi
    printLog "[60%]copySourceFile"
    copySourceFile $packageName-$version $arch
    if [ $ERRORSIGNL = 1 ];then
      printLog "copySourceFile error"
      continue
    fi
    # exit 0
    printLog "[80%]modifyName"
    modifyName $packageName $version $arch
    if [ $ERRORSIGNL = 1 ];then
      printLog "modifyName error"
      continue
    fi
    printLog "[90%]build"
    build $packageName $version $arch $Arch 
    if [ $ERRORSIGNL = 1 ];then
      printLog "build error"
      continue
    fi
    printLog "[100%]Finished!"
    echo "[OK]"
  done
  
}

if [ x$1 = x"build" ];then
  echo "###### Start！######"
  main
  echo "###### Finish！######"
else 
  rm -rf src/* outputs/* log.txt error.txt
  echo "已清理完成"
  echo "执行./deb2uos.sh build"
fi
