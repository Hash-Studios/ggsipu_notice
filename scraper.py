from flask import Flask, render_template
from bs4 import BeautifulSoup
import requests
from urllib import parse
import pyrebase
from config import config

firebase = pyrebase.initialize_app(config)
db = firebase.database()
print("Initialised Pyrebase")


def _scrap_notice_tr(tr):
    tds = tr.find_all('td')
    if len(tds) != 2:
        return None
    notice_a = tds[0].a
    if notice_a:
        notice_txt = notice_a.text
        dwd_url = notice_a.get("href", None)
        if not dwd_url or not notice_txt:
            return None
        notice_date = tds[1].text
        if not notice_date:
            return None
        title = " ".join(notice_txt.split())
        title = title.translate(str.maketrans({"_":  r"\_",
                                               "*":  r"\*",
                                               "`":  r"\`"}))
        dwd_url = parse.quote(dwd_url.strip())
        return {"date": notice_date.strip(), "title": title, "url": dwd_url.strip()}
    else:
        return None


def only_new_notice_tr(tag):
    return tag.name == 'tr' and not tag.has_attr('id') and not tag.has_attr('style')


notices = []
source = requests.get('http://www.ipu.ac.in/notices.php').text
soup = BeautifulSoup(source, 'html.parser')
print("Loaded Website")

rows = soup.tbody.find_all(only_new_notice_tr)
for links in rows:
    notice = _scrap_notice_tr(links)
    if notice:
        notices.append(notice)
print("Fetched Notices")

notices_db = db.child("notices").get()
if notices_db.val():
    print("Database found")
    if notices[0] == notices_db.val()[0]:
        print("Data not Changed")
    else:
        print("Data Changed")
        for index in range(len(notices)):
            if notices[index] != notices_db.val()[index]:
                db.child("notices").child(str(index)).set(notices[index])
        print("Data Updated")
else:
    print("Database not found")
    for index in range(len(notices)):
        db.child("notices").child(str(index)).set(notices[index])
