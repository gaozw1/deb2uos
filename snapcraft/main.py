import requests
import pandas as pd
from bs4 import BeautifulSoup


def requestLink(url):
    r = requests.get(url,timeout=(30,30))

    if r.status_code != 200:
        print("Could not get page:")
        write2Txt("link.txt","none")
        return
    print("requesting: " + url)
    name = url.split("/", -1)
    hasLink = 0
    homeArr = []
    rsoup = BeautifulSoup(r.text, "html.parser")
    div_nodes = rsoup.find_all("div", class_="col-4")
    for div_node in div_nodes:
        a_nodes = div_node.find_all("a")
        if a_nodes is not None:
            for a in a_nodes:
                if a.text in ["Developer website", "Contact James Tigert"]:
                    link = a["href"]
                    homeArr.append(link)
                    print(link)
                    hasLink = 1
    if not hasLink:
        print("无")

    datas=({
        "name": name,
        "snapLink": url,
        "homePage": homeArr
    })
    # 每个循环保存一次，防止请求超时数据丢失
    return datas


def getlink():
    Df = pd.read_excel("new.xlsx")
    linkArr = Df.values[:, 1]
    return linkArr


def write2Txt(fileName, data):
    with open(fileName, "a") as f:
        f.write(data + "\n")
        f.close()

def save2Excel(data):
    df = pd.DataFrame(data)
    df.to_excel("link.xlsx", index=False)

if __name__ == "__main__":
    rootUrl = "https://packages.debian.org/buster/games/"

    headers = {
        "Accept-Language": "zh-CN,zh;q=0.9"
    }
    print("start read from excel")
    linkArr = getlink()
    print("read over")
    # datas=[]
    # i=1
    # print(linkArr)
    # save2Excel(linkArr[0])
    # save2Excel(linkArr[1])
    # save2Excel(linkArr[2])
    for url in linkArr:
        datas=requestLink(url)
        save2Excel(datas)
    