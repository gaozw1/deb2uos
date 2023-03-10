import requests
import pandas as pd
from bs4 import BeautifulSoup
# import pprint


def getDeb(url,headers):
    datas = []
    r = requests.get(url)
    if r.status_code != 200:
        raise Exception("Could not get page")

    rsoup = BeautifulSoup(r.text, "html.parser")

    dt_nodes = rsoup.find_all("dt")
    i=0
    for dt_node in dt_nodes:
        if "-data" in dt_node.text:
            continue
        i=i+1
#appName
        appName = dt_node.text
        print(appName)
        name=appName.split(" ")[0]
        version = appName.split(" ")[1]


        link = dt_node.find("a")
        homePageLink = rootUrl+link["href"]

        homePage = requests.get(homePageLink, headers=headers)
        if homePage.status_code!= 200:
            raise Exception("Could not get page")
        hSoup = BeautifulSoup(homePage.text, "html.parser")

#获取游戏主页链接
        res = getGameHomePageLink(hSoup)
        gameHomeLink = res[0]
        reverseDomain = res[1]
        if gameHomeLink == "none":
            reverseDomain = "com"




#获取描述
        gameInfo = getGameInfo(hSoup)

        
#获取下载链接

        downloadLinkArr = getDownloadLink(hSoup)
        fileNameArr = []
        appstorePkgName = reverseDomain +"." + name
        for downloadLink in downloadLinkArr:
            fileName = appName.split(" ")[0] + "_" +reverseDomain +"."+downloadLink.split("/")[-1]
            fileNameArr.append(fileName)
            

            write2Txt("downloadLinkData.txt","fileName: " + fileName)

            write2Txt("downloadLinkData.txt",downloadLink)

        print("-"*15)

        datas.append({
            "name": name,
            "version": version,
            "homePageLink": homePageLink,
            "gameHomeLink": gameHomeLink,
            "gameInfo": gameInfo,
            "appstorePkgName": appstorePkgName,
            "downloadLinkArr": downloadLinkArr
        })
        save2Excel(datas, "deb.xlsx")


        # pprint.pprint(datas)

    print("共"+str(i)+"个结果")
    write2Txt("info.txt", "共"+str(i)+"个结果")


def write2Txt(fileName, data):
    with open(fileName, "a") as f:
        f.write(data+"\n")
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
        return None
    else:
        download_nodes = soup.find("div", id="pdownload")
        for download_node in download_nodes.find_all("th"):
            if download_node.text in ["amd64","all","arm64"] :
                link = download_node.find("a")
                downloadPageLink = "https://packages.debian.org/"+link["href"]
                downloadPage = requests.get(downloadPageLink)
                if downloadPage.status_code!= 200:
                    raise Exception("Could not get page")
                dSoup = BeautifulSoup(downloadPage.text, "html.parser")
                download_nodes = dSoup.find_all("a")
                for download_node in download_nodes:
                    if download_node.text == "ftp.us.debian.org/debian":
                        downloadLink.append(download_node["href"])
          
        return downloadLink

def getGameHomePageLink(soup):
    gameHomeLink="none"
    reverseDomain="none"
    info_node = soup.find("div", id="pmoreinfo")
    for gameHome_node in info_node.find_all("li"):
        

        if "主页" in gameHome_node.text :
            gameHomeLink = gameHome_node.find("a")["href"]
            
            lk = gameHome_node.text.split("[")[1].split("]")[0].split(".")
            lk.reverse()
            reverseDomain = '.'.join(lk)
            
    return gameHomeLink, reverseDomain


def save2Excel(data, fileName):
    df = pd.DataFrame(data)
    df.to_excel(fileName, index=False)



if __name__== "__main__" :
    rootUrl="https://packages.debian.org/buster/games/"
    
    headers = {
    "Accept-Language": "zh-CN,zh;q=0.9"
    }
    getDeb(rootUrl, headers)
    