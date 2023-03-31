def readTypeList():
    #读取typelist.list文件
    file = open("../debCrawler/typelist.list",'r')
    typelist = file.readlines()
    file.close()
    return typelist

if __name__ == "__main__":

    typeList = readTypeList()
    rootUrl = "https://packages.debian.org/buster/"
    for type in typeList:
        if type.rstrip().startswith("#"):
            continue 
        subUrl = rootUrl+type.rstrip()+"/"
        print(subUrl)