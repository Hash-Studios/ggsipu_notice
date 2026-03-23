import hashlib
import logging
import time
import firebase_admin
from firebase_admin import firestore, messaging
from firebase_functions import scheduler_fn
from algoliasearch.search.client import SearchClientSync
from bs4 import BeautifulSoup
from urllib import parse
import requests

firebase_admin.initialize_app()

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
log = logging.getLogger(__name__)

NOTICES_URL = "http://www.ipu.ac.in/notices.php"
NOTICES_BASE = "http://www.ipu.ac.in"
HEADERS = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}

ALGOLIA_APP_ID = "RAD0PLRXFT"
ALGOLIA_API_KEY = "6cc1a9d32007dd9440d259c3cd9b4bc3"
ALGOLIA_INDEX_NAME = "notices"

FETCH_RETRIES = 3
FETCH_RETRY_DELAY = 5  # seconds between retries

PRIORITY_TAGS = {"result", "datesheet", "exam", "examination", "merit", "counselling"}

COLLEGES = [
    "usict", "usit", "usct", "usms", "uslls", "usbt",
    "usmc", "usap", "msit", "usar", "usdi", "bvce", "gtbit",
]

TAGS = [
    "ph.d", "b.tech", "b.sc", "m.sc", "m.tech", "cet", "theory",
    "result", "merit", "scholar", "research", "revised", "annual",
    "practical", "hackathon", "counselling", "date", "datesheet",
    "final", "exam", "examination", "time", "last", "calendar",
    "schedule", "proposed",
]


# ── Scraping helpers ──────────────────────────────────────────────────────────

def _is_notice_row(tag):
    return tag.name == "tr" and not tag.has_attr("id") and not tag.has_attr("style")


def _parse_row(tr):
    tds = tr.find_all("td")
    if len(tds) != 2:
        return None
    a = tds[0].a
    if not a:
        return None
    title_raw = a.text
    url = a.get("href", None)
    date = tds[1].text.strip()
    if not title_raw or not url or not date:
        return None
    title = " ".join(title_raw.split())
    title = title.translate(str.maketrans({"_": r"\_", "*": r"\*", "`": r"\`"}))
    url = url.strip()
    if url.startswith("/"):
        url = NOTICES_BASE + url
    url = parse.quote(url, safe=":/?=&#")
    college = _check_college(title)
    tags = _check_tags(title)
    priority = bool(PRIORITY_TAGS & set(tags))
    return {
        "title": title,
        "url": url,
        "date": date,
        "college": college,
        "tags": tags,
        "priority": priority,
    }


def _check_college(title: str) -> str:
    lower = title.lower()
    for c in COLLEGES:
        if c in lower:
            return c
    return ""


def _check_tags(title: str) -> list:
    lower = title.lower()
    return [t for t in TAGS if t in lower]


def _notice_id(url: str) -> str:
    """Stable Firestore document ID derived from the notice URL."""
    return hashlib.md5(url.encode()).hexdigest()


def fetch_notices() -> list:
    """Fetch and parse notices from the IPU website with retry logic."""
    last_exc = None
    for attempt in range(1, FETCH_RETRIES + 1):
        try:
            resp = requests.get(NOTICES_URL, headers=HEADERS, timeout=30)
            resp.raise_for_status()
            soup = BeautifulSoup(resp.text, "html.parser")
            if not soup.tbody:
                raise ValueError("No <tbody> found — site structure may have changed")
            rows = soup.tbody.find_all(_is_notice_row)
            notices = [n for n in (_parse_row(tr) for tr in rows) if n]
            return notices
        except Exception as e:
            last_exc = e
            if attempt < FETCH_RETRIES:
                log.warning(f"Fetch attempt {attempt} failed: {e} — retrying in {FETCH_RETRY_DELAY}s")
                time.sleep(FETCH_RETRY_DELAY)
    raise last_exc


# ── Firestore helpers ─────────────────────────────────────────────────────────

def _save_new_notices(fs_client, notices: list) -> list:
    """
    Write notices that don't already exist in Firestore.
    Uses URL-derived doc ID for natural deduplication.
    Returns the list of actually-new notices.
    """
    col = fs_client.collection("notices")
    new_notices = []
    for notice in notices:
        doc_id = _notice_id(notice["url"])
        ref = col.document(doc_id)
        if not ref.get().exists:
            ref.set({**notice, "createdAt": firestore.SERVER_TIMESTAMP, "isArchived": False})
            new_notices.append(notice)
    if new_notices:
        log.info(f"Saved {len(new_notices)} new notice(s) to Firestore")
    return new_notices


def _index_notices(new_notices: list):
    """Push new notices to Algolia index."""
    client = SearchClientSync(ALGOLIA_APP_ID, ALGOLIA_API_KEY)
    records = [
        {**n, "objectID": _notice_id(n["url"])}
        for n in new_notices
    ]
    client.save_objects(ALGOLIA_INDEX_NAME, records)
    log.info(f"Indexed {len(records)} notice(s) in Algolia")


def _top_notice_exists(fs_client, notice: dict) -> bool:
    """Quick check: does the most recent scraped notice already exist in Firestore?"""
    doc_id = _notice_id(notice["url"])
    return fs_client.collection("notices").document(doc_id).get().exists


def _sync_archived_status(fs_client, current_urls: set):
    """
    Mark notices no longer on the IPU page as isArchived=True,
    and ensure current notices are isArchived=False.
    """
    col = fs_client.collection("notices")
    active_docs = col.where("isArchived", "==", False).stream()

    batch = fs_client.batch()
    count = 0
    for doc in active_docs:
        if doc.to_dict().get("url") not in current_urls:
            batch.update(doc.reference, {"isArchived": True})
            count += 1

    if count > 0:
        batch.commit()
        log.info(f"Archived {count} notice(s) no longer on the IPU page")


# ── FCM helpers ───────────────────────────────────────────────────────────────

def _send_notification(fs_client, title: str, body: str, url: str, tokens: list):
    if not tokens:
        log.info("No tokens to notify")
        return

    stale_tokens = []
    chunk_size = 500
    for i in range(0, len(tokens), chunk_size):
        chunk = tokens[i:i + chunk_size]
        msg = messaging.MulticastMessage(
            notification=messaging.Notification(title=title, body=body),
            data={"url": url},
            android=messaging.AndroidConfig(priority="high"),
            tokens=chunk,
        )
        resp = messaging.send_each_for_multicast(msg)
        log.info(f"FCM: {resp.success_count} sent, {resp.failure_count} failed")

        for j, r in enumerate(resp.responses):
            if not r.success and r.exception:
                code = getattr(r.exception, "code", None)
                if code in ("registration-token-not-registered", "invalid-registration-token"):
                    stale_tokens.append(chunk[j])

    if stale_tokens:
        _prune_tokens(fs_client, stale_tokens)


def _prune_tokens(fs_client, stale_tokens: list):
    """Remove dead FCM tokens from the Firestore fcm_tokens collection."""
    col = fs_client.collection("fcm_tokens")
    for token in stale_tokens:
        col.document(token).delete()
    log.info(f"Pruned {len(stale_tokens)} stale token(s)")


# ── Health helpers ────────────────────────────────────────────────────────────

def _update_health(fs_client, notices_fetched: int, new_count: int):
    """Write last-run metadata to Firestore for monitoring."""
    fs_client.collection("metadata").document("lastRun").set({
        "timestamp": firestore.SERVER_TIMESTAMP,
        "noticesFetched": notices_fetched,
        "newNotices": new_count,
    })


# ── Scheduled Cloud Function ──────────────────────────────────────────────────

@scheduler_fn.on_schedule(schedule="every 1 minutes", timezone="Asia/Kolkata")
def scrape_ipu_notices(event: scheduler_fn.ScheduledEvent) -> None:
    log.info("Scraper started")

    # 1. Fetch live notices (with retry)
    try:
        notices = fetch_notices()
    except Exception as e:
        log.error(f"All fetch attempts failed: {e}")
        return

    if not notices:
        log.warning("No notices found on page")
        return

    log.info(f"Fetched {len(notices)} notices")

    fs = firestore.client()
    current_urls = {n["url"] for n in notices}

    # 2. Sync archived status for notices that dropped off the page
    try:
        _sync_archived_status(fs, current_urls)
    except Exception as e:
        log.error(f"Archive sync error: {e}")

    # 3. Quick exit if nothing new
    if _top_notice_exists(fs, notices[0]):
        log.info("No change detected")
        return

    log.info("New notices detected — saving to Firestore")

    # 4. Save new notices (Firestore deduplicates by URL-derived doc ID)
    try:
        new_notices = _save_new_notices(fs, notices)
    except Exception as e:
        log.error(f"Firestore write error: {e}")
        return

    if not new_notices:
        log.info("No genuinely new notices after deduplication")
        _update_health(fs, len(notices), 0)
        return

    # 5. Index new notices in Algolia
    try:
        _index_notices(new_notices)
    except Exception as e:
        log.error(f"Algolia indexing error: {e}")

    # 6. Fetch FCM tokens from Firestore and notify
    tokens = []
    try:
        tokens = [doc.id for doc in fs.collection("fcm_tokens").stream()]
    except Exception as e:
        log.error(f"Could not fetch user tokens: {e}")

    try:
        first = new_notices[0]
        count = len(new_notices)
        if count == 1:
            notif_title = first["title"]
            notif_body = first["date"]
        else:
            notif_title = f"{count} new notices on IPU"
            notif_body = first["title"]
        _send_notification(fs, notif_title, notif_body, first["url"], tokens)
    except Exception as e:
        log.error(f"Notification error: {e}")

    # 7. Update health document
    try:
        _update_health(fs, len(notices), len(new_notices))
    except Exception as e:
        log.error(f"Health update error: {e}")

    log.info("Scraper run complete")
