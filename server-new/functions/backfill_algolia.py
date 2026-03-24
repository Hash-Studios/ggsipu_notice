"""
One-time script to backfill all Firestore notices into Algolia.

Usage:
    python backfill_algolia.py [--service-account path/to/serviceAccount.json]

If --service-account is omitted, ADC (Application Default Credentials) is used.
"""

import argparse
import hashlib
import logging

import firebase_admin
from firebase_admin import credentials, firestore
from algoliasearch.search.client import SearchClientSync

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
log = logging.getLogger(__name__)

ALGOLIA_APP_ID = "RAD0PLRXFT"
ALGOLIA_API_KEY = "6cc1a9d32007dd9440d259c3cd9b4bc3"
ALGOLIA_INDEX_NAME = "notices"

BATCH_SIZE = 1000  # Algolia recommends ≤ 1000 objects per batch


def _notice_id(url: str) -> str:
    return hashlib.md5(url.encode()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description="Backfill Firestore notices to Algolia")
    parser.add_argument("--service-account", help="Path to Firebase service account JSON")
    args = parser.parse_args()

    # Initialise Firebase
    if args.service_account:
        cred = credentials.Certificate(args.service_account)
        firebase_admin.initialize_app(cred)
    else:
        firebase_admin.initialize_app()

    fs = firestore.client()

    log.info("Fetching all notices from Firestore...")
    docs = list(fs.collection("notices").stream())
    log.info(f"Found {len(docs)} notices")

    if not docs:
        log.info("Nothing to index.")
        return

    # Build Algolia records
    records = []
    for doc in docs:
        data = doc.to_dict()
        record = {}
        for k, v in data.items():
            # Convert Firestore Timestamps / datetime objects to ISO strings
            if hasattr(v, "isoformat"):
                record[k] = v.isoformat()
            else:
                record[k] = v
        record["objectID"] = doc.id
        # Ensure objectID matches the URL-derived MD5 if url is present
        if "url" in data and doc.id != _notice_id(data["url"]):
            log.warning(f"Doc ID mismatch for {doc.id}, using doc ID as objectID")
        records.append(record)

    # Push to Algolia in batches
    client = SearchClientSync(ALGOLIA_APP_ID, ALGOLIA_API_KEY)
    total = 0
    for i in range(0, len(records), BATCH_SIZE):
        batch = records[i : i + BATCH_SIZE]
        client.save_objects(ALGOLIA_INDEX_NAME, batch)
        total += len(batch)
        log.info(f"Indexed {total}/{len(records)} records...")

    log.info(f"Done. {total} notices indexed in Algolia.")


if __name__ == "__main__":
    main()
