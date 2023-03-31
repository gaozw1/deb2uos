import requests
import pandas as pd
from bs4 import BeautifulSoup
import pprint


def getDeb(url, headers, type, appNameInappStore, pkgNameInAppStore):
    datas = []
    nameIndebian = []
    r = requests.get(url)
    if r.status_code != 200:
        print("Could not get page")
        return

    rsoup = BeautifulSoup(r.text, "html.parser")

    dt_nodes = rsoup.find_all("dt")
    try:
        for dt_node in dt_nodes:

            if "-data" in dt_node.text:
                continue

            # appName
            appName = dt_node.text

            # print(appName)
            appNameVersionArr = appName.split(" ")
            if len(appNameVersionArr) != 2 and len(appNameVersionArr) != 3:
                continue
            name = appNameVersionArr[0]

            version = appNameVersionArr[1]
            if spliter(name, appNameInappStore, pkgNameInAppStore):
                # print("[重复] "+name)
                # write2Txt("www.txt", name)
                continue
            link = dt_node.find("a")
            homePageLink = rootUrl + link["href"]

            homePage = requests.get(homePageLink, headers=headers)
            if homePage.status_code != 200:
                print("Could not get page")
                continue

            hSoup = BeautifulSoup(homePage.text, "html.parser")

            # 获取游戏主页链接
            res = getGameHomePageLink(hSoup)
            gameHomeLink = res[0]
            reverseDomain = res[1]
            developerName = res[2]
            if gameHomeLink == "none":
                reverseDomain = "com"

            # 获取描述
            gameInfo = getGameInfo(hSoup)

            # 获取下载链接

            downloadLinkArr = getDownloadLink(hSoup)
            if len(downloadLinkArr) == 0:
                continue
            fileNameArr = []
            appstorePkgName = reverseDomain + "." + name
            for downloadLink in downloadLinkArr:
                fileName = appName.split(" ")[0] + "_" + reverseDomain + "." + downloadLink.split("/")[-1]
                fileNameArr.append(fileName)

                write2Txt("downloadLinkData.txt", downloadLink + "|" + fileName)
            nameIndebian.append(name)
            print(appName)

            datas.append({
                "name": name,
                "version": version,
                "gameHomeLink": gameHomeLink,
                "developerName": developerName,
                "gameInfo": gameInfo,
                "type": type,
                "appstorePkgName": appstorePkgName,
                "homePageLink": homePageLink,
                "downloadLinkArr": downloadLinkArr
            })
    except Exception as e:
        write2Txt("error.txt", appName+" "+e)
        print(appName+" "+e)
    return datas


def write2Txt(fileName, data):
    with open(fileName, "a") as f:
        f.write(data + "\n")
        f.close()


def getGameInfo(soup):
    div_node = soup.find("div", id="pdesc")

    if div_node is None:
        return None
    else:
        return div_node.text


def getDownloadLink(soup):
    downloadLink = []
    div_node = soup.find("div", id="pdesc")
    if div_node is None:
        print("没有找到下载链接")
    else:
        download_nodes = soup.find("div", id="pdownload")
        for download_node in download_nodes.find_all("th"):
            if download_node.text in ["amd64", "arm64"]:
                link = download_node.find("a")
                downloadPageLink = "https://packages.debian.org/" + link["href"]
                downloadPage = requests.get(downloadPageLink)
                if downloadPage.status_code != 200:
                    print("Error!Could not get page: " + downloadPageLink)
                    return []
                dSoup = BeautifulSoup(downloadPage.text, "html.parser")
                download_nodes = dSoup.find_all("a")
                for download_node in download_nodes:
                    if download_node.text == "ftp.us.debian.org/debian":
                        downloadLink.append(download_node["href"])

    return downloadLink


def spliter(appName, data1, data2):
    if len(appName) > 3:
        if appName in data1:
            return 1
        for x in data2:
            if appName in x:
                return 1
    return 0


def getGameHomePageLink(soup):
    gameHomeLink = "none"
    reverseDomain = "none"
    developerName = "none"
    info_node = soup.find("div", id="pmoreinfo")
    for li_node in info_node.find_all("li"):
        if "主页" in li_node.text:
            gameHomeLink = li_node.find("a")["href"]
            lk = li_node.text.split("[")[1].split("]")[0].split(".")
            lk.reverse()
            reverseDomain = '.'.join(lk)

        if "开发者信息" in li_node.text:
            
            developerLink = li_node.find("a")["href"]
            if developerLink:    
                d = requests.get(developerLink)
                if d.status_code != 200:
                    print("Could not get page:"+developerLink)
            
                dsoup = BeautifulSoup(d.text, "html.parser")

                div_node = dsoup.find("div", id="dtracker-package-left")
                li_nodes = div_node.find_all("li", class_="list-group-item")
                for li_node in li_nodes:
                    if li_node.find("b"):
                        if "uploaders:" in li_node.find("b").text:
                            developerName = li_node.find("a").text
                            break

                        elif "maintainer:" in li_node.find("b").text:
                            developerName = li_node.find("a").text

    return gameHomeLink, reverseDomain, developerName


def save2Excel(fileName, data):
    df = pd.DataFrame(data)
    df.to_excel(fileName, index=False)


def readExcel():
    print("Start read from excel")
    appStoreDf = pd.read_excel("appStore_1678695568532.xlsx")
    appNameInappStore = appStoreDf.values[:, 0]
    pkgNameInAppStore = appStoreDf.values[:, 8]
    print("read Finished")
    return appNameInappStore, pkgNameInAppStore

def readTypeList():
    #读取typelist.list文件
    file = open("typelist.list",'r')
    typelist = file.readlines()
    file.close()
    return typelist

if __name__ == "__main__":
    # typeList = ["admin","comm","database","editors","education","electronics","embedded","gnome","gnu-r","gnustep","hamradio","graphics","mail","math","misc","science","sound","video","web","x11","xfce"]
    # typeList = ["x11","xfce"]
    typeList = readTypeList()
    rootUrl = "https://packages.debian.org/buster/"
    headers = {
        "Accept-Language": "zh-CN,zh;q=0.9"
    }
    nArr = readExcel()
    appNameInappStore = nArr[0]
    pkgNameInAppStore = nArr[1]
    allDatas = []
    for type in typeList:
        subUrl = rootUrl+type.rstrip()+"/"
        print(subUrl)
        datas = getDeb(subUrl, headers, type, appNameInappStore, pkgNameInAppStore)
        allDatas.extend(datas)
        exfileName = type+".xlsx"
        save2Excel(exfileName, datas)
    save2Excel("alldatas.xlsx", allDatas)
    
