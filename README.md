# deb2uos
## deb2uos.sh
将deb包转化为符合uos标准的deb包

1. 将下载的包放到debs目录，并将这些包改名为`应用名_包名_版本号_架构[amd64,arm,arm64]`格式，
例如：`Minder_com.github.phase1geo.minder_1.9.2-1_amd64.deb`
2. 执行脚本
- `./deb2uos.sh` 无参数：清理冗余文件
- `./deb2uos.sh build` build参数：开始转化
3. 转换完成的包在会输出到output目录中

## getDebianDeb.py
爬取指定页面的deb包内容以及下载链接

`python3 getDebianDeb.py`
