from apscheduler.schedulers.background import BackgroundScheduler
from pyfcm import FCMNotification
from flask import Flask, render_template
from bs4 import BeautifulSoup
import requests
from urllib import parse
import pyrebase
from config import config
from keys import api_key, registration_id


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


def sensor():

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
                    message_title = str(notices[index]['title'])
                    message_body = str(notices[index]['date'])
                    result = push_service.notify_single_device(
                        registration_id=registration_id, message_title=message_title, message_body=message_body)
                    print(result)
                    db.child("notices").child(str(index)).set(notices[index])
            print("Data Updated")
    else:
        print("Database not found")
        for index in range(len(notices)):
            db.child("notices").child(str(index)).set(notices[index])
    print("Scheduler run completed!")


push_service = FCMNotification(api_key=api_key)
print("Initialised Push Service")


firebase = pyrebase.initialize_app(config)
db = firebase.database()
print("Initialised Pyrebase")

sched = BackgroundScheduler(daemon=True)
sched.add_job(sensor, 'interval', seconds=20)
sched.start()

print("Started Scheduler")


app = Flask(__name__)


@app.route("/")
def home():
    return "Welcome, Services are running!"


if __name__ == "__main__":
    app.run()
