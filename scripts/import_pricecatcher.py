#!/usr/bin/env python3
"""Import Malaysia PriceCatcher CSV datasets into Firestore.

Populates three collections (see lib/core/constants/firestore_constants.dart
for the matching Dart-side field names):

    products        <- lookup_item.csv      (doc id = item_code)
    supermarkets    <- lookup_premise.csv   (doc id = premise_code)
    prices          <- pricecatcher.csv     (doc id = {item_code}_{premise_code}_{date})
    latest_prices   <- pricecatcher.csv     (doc id = {item_code}_{premise_code})

`latest_prices` is a materialized view holding only the most recent price
per (item, premise) pair, so price-comparison screens don't have to scan
full history to answer "what does this cost right now at each store".

CSV files are streamed row by row (not loaded fully into memory), since
PriceCatcher price files can run into the millions of rows.

Usage:
    python scripts/import_pricecatcher.py \\
        --credentials serviceAccountKey.json \\
        --items lookup_item.csv \\
        --premises lookup_premise.csv \\
        --prices pricecatcher.csv \\
        [--since 2026-01-01] [--limit 10000] [--dry-run]

Re-running is safe: every document id is deterministic, so imports are
idempotent upserts, not duplicating inserts.
"""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore

# Firestore caps batched writes at 500 operations; leave headroom.
BATCH_LIMIT = 400


def init_firestore(credentials_path: str):
    cred = credentials.Certificate(credentials_path)
    firebase_admin.initialize_app(cred)
    return firestore.client()


class BatchWriter:
    """Buffers Firestore `set` calls and commits every BATCH_LIMIT ops."""

    def __init__(self, db, dry_run: bool = False):
        self._db = db
        self.dry_run = dry_run
        self._batch = None if dry_run else db.batch()
        self._pending = 0
        self.total = 0

    def set(self, ref, data: dict, merge: bool = True) -> None:
        self.total += 1
        if self.dry_run:
            return
        self._batch.set(ref, data, merge=merge)
        self._pending += 1
        if self._pending >= BATCH_LIMIT:
            self.flush()

    def flush(self) -> None:
        if self.dry_run or self._pending == 0:
            return
        self._batch.commit()
        self._batch = self._db.batch()
        self._pending = 0


def open_csv(path: str):
    p = Path(path)
    if not p.exists():
        sys.exit(f"CSV not found: {path}")
    return open(p, newline="", encoding="utf-8-sig")


def import_products(db, csv_path: str, dry_run: bool) -> int:
    writer = BatchWriter(db, dry_run)
    with open_csv(csv_path) as f:
        for row in csv.DictReader(f):
            item_code = row["item_code"].strip()
            name = row["item"].strip()
            ref = db.collection("products").document(item_code)
            writer.set(ref, {
                "itemCode": item_code,
                "name": name,
                "nameLower": name.lower(),
                "unit": row["unit"].strip(),
                "itemGroup": row["item_group"].strip(),
                "itemCategory": row["item_category"].strip(),
            })
    writer.flush()
    print(f"products: upserted {writer.total} docs")
    return writer.total


def import_supermarkets(db, csv_path: str, dry_run: bool) -> int:
    writer = BatchWriter(db, dry_run)
    with open_csv(csv_path) as f:
        for row in csv.DictReader(f):
            premise_code = row["premise_code"].strip()
            ref = db.collection("supermarkets").document(premise_code)
            writer.set(ref, {
                "premiseCode": premise_code,
                "name": row["premise"].strip(),
                "address": row["address"].strip(),
                "premiseType": row["premise_type"].strip(),
                "district": row["district"].strip(),
                "state": row["state"].strip(),
            })
    writer.flush()
    print(f"supermarkets: upserted {writer.total} docs")
    return writer.total


def import_prices(db, csv_path: str, dry_run: bool, since: str | None, limit: int | None) -> tuple[int, int]:
    price_writer = BatchWriter(db, dry_run)
    latest: dict[tuple[str, str], tuple[str, float]] = {}
    skipped = 0

    with open_csv(csv_path) as f:
        for i, row in enumerate(csv.DictReader(f)):
            if limit is not None and i >= limit:
                break

            date_str = row["date"].strip()
            if since and date_str < since:
                continue

            item_code = row["item_code"].strip()
            premise_code = row["premise_code"].strip()
            try:
                price = float(row["price"])
            except (KeyError, ValueError):
                skipped += 1
                continue

            doc_id = f"{item_code}_{premise_code}_{date_str}"
            ref = db.collection("prices").document(doc_id)
            price_writer.set(ref, {
                "itemCode": item_code,
                "premiseCode": premise_code,
                "date": date_str,
                "price": price,
            })

            key = (item_code, premise_code)
            current = latest.get(key)
            if current is None or date_str >= current[0]:
                latest[key] = (date_str, price)

    price_writer.flush()
    print(f"prices: upserted {price_writer.total} docs ({skipped} rows skipped)")

    latest_writer = BatchWriter(db, dry_run)
    for (item_code, premise_code), (date_str, price) in latest.items():
        doc_id = f"{item_code}_{premise_code}"
        ref = db.collection("latest_prices").document(doc_id)
        latest_writer.set(ref, {
            "itemCode": item_code,
            "premiseCode": premise_code,
            "date": date_str,
            "price": price,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        })
    latest_writer.flush()
    print(f"latest_prices: upserted {latest_writer.total} docs")

    return price_writer.total, latest_writer.total


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--credentials", required=True, help="Path to Firebase service account JSON key")
    parser.add_argument("--items", default="data/lookup_item.csv", help="Path to lookup_item.csv")
    parser.add_argument("--premises", default="data/lookup_premise.csv", help="Path to lookup_premise.csv")
    parser.add_argument("--prices", default="data/pricecatcher.csv", help="Path to pricecatcher.csv")
    parser.add_argument("--since", default=None, help="Only import price rows with date >= YYYY-MM-DD")
    parser.add_argument("--limit", type=int, default=None, help="Only import the first N price rows (for testing)")
    parser.add_argument("--skip-products", action="store_true", help="Skip lookup_item.csv import")
    parser.add_argument("--skip-supermarkets", action="store_true", help="Skip lookup_premise.csv import")
    parser.add_argument("--skip-prices", action="store_true", help="Skip pricecatcher.csv import")
    parser.add_argument("--dry-run", action="store_true", help="Parse and count rows without writing to Firestore")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    db = init_firestore(args.credentials)

    if not args.skip_products:
        import_products(db, args.items, args.dry_run)
    if not args.skip_supermarkets:
        import_supermarkets(db, args.premises, args.dry_run)
    if not args.skip_prices:
        import_prices(db, args.prices, args.dry_run, args.since, args.limit)

    if args.dry_run:
        print("\nDry run complete — no writes were made.")


if __name__ == "__main__":
    main()
