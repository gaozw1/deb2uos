# deb2uos
本工程目前有两个功能已经实现，还有两个功能目前暂未实现
```bash
.
├── D2U             将Debian下的deb文件转换成UOS的deb文件
├── debCrawler      收集[https://packages.debian.org/buster/]此站点下的deb包
├── README.md
├── Snap2Deb        暂未实现。将Ubuntu下的snap包转换成UOS下的deb包
├── snapcraft       暂不考虑实现，已有现成“轮子”。抓取snapcraft站点下的网址
└── test            编码中用于测试问题模块
```
## D2U 
`deb2uos.sh`  
将deb包转化为符合uos标准的deb包

使用方法：
1. 将下载的包放到debs目录，并将这些包改名为`应用名_包名_版本号_架构[amd64,arm,arm64]`格式，
例如：`Minder_com.github.phase1geo.minder_1.9.2-1_amd64.deb`
2. 执行脚本
- `./deb2uos.sh` 无参数：清理冗余文件，如：日志文件、src、outputs文件中上次的输出结果
- `./deb2uos.sh build` build参数：开始转化
3. 转换完成的包在会输出到output目录中

也可以：
1. 将debCrawler工程中`downloadLinkData.txt`中的链接复制到`D2U/inputs/deb.txt`中
2. 进入`input`目录
- 运行`./download.sh`，会自动下载`deb.txt`中的内容，并自动改名，符合上述规范
- 运行`./download.sh clear`会自动清除`inputs`目录中的deb文件


## debCrawler
`getDebianDeb.py`  
爬取指定页面的deb包内容以及下载链接。可以在  

使用方法
`./venv/bin/python3.7 getDebianDeb.py`

注意：重新爬取数据之前建议手动删除
`downloadLinkData.txt`
`all.xlsx`
`*.xlsx`
除了`appStore_1678695568532.xlsx`这个文件！