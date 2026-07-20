#!/usr/bin/env python3
"""Import Malaysia PriceCatcher CSV datasets into Firestore.

Populates three collections (see lib/core/constants/firestore_constants.dart
for the matching Dart-side field names):

    products        <- lookup_item.csv          (doc id = item_code)
    supermarkets    <- lookup_premise.csv        (doc id = premise_code)
    prices          <- pricecatcher*.csv         (doc id = {item_code}_{premise_code}_{date})
    latest_prices   <- pricecatcher*.csv         (doc id = {item_code}_{premise_code})

`latest_prices` is a materialized view holding only the most recent price
per (item, premise) pair, so price-comparison screens don't have to scan
full history to answer "what does this cost right now at each store".

PriceCatcher publishes a new price CSV every month. `--prices` accepts
either a single CSV or a directory of monthly CSVs (e.g. data/pricecatcher/),
which are imported one at a time in filename order. Each file is safe to
import independently and repeatedly:

  - Historical `prices` records are never overwritten or deleted — a row
    whose doc id already exists is counted as a skipped duplicate, not
    re-written.
  - `latest_prices` is only advanced when the imported row's date is
    strictly newer than whatever is currently stored for that
    (item, premise) pair, so importing an old backfill month after a
    newer month won't regress it.

CSV files are streamed row by row, never loaded fully into memory — a
single monthly PriceCatcher file can run into the hundreds of thousands of
rows. Firestore reads/writes are batched (~400 docs per round trip) rather
than done one row at a time.

Usage:
    # Single month
    python scripts/import_pricecatcher.py \\
        --credentials serviceAccountKey.json \\
        --items lookup_item.csv --premises lookup_premise.csv \\
        --prices data/pricecatcher_2026-07.csv

    # Whole folder of monthly files, in order
    python scripts/import_pricecatcher.py \\
        --credentials serviceAccountKey.json \\
        --skip-products --skip-supermarkets \\
        --prices data/pricecatcher/
"""

from __future__ import annotations

import argparse
import csv
import sys
from collections import Counter
from dataclasses import dataclass, field
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore

# Firestore caps batched writes at 500 operations; leave headroom. Also used
# as the chunk size for batched existence-check reads (get_all).
BATCH_LIMIT = 400


def init_firestore(credentials_path: str):
    cred = credentials.Certificate(credentials_path)
    firebase_admin.initialize_app(cred)
    return firestore.client()


def open_csv(path: Path):
    if not path.exists():
        sys.exit(f"CSV not found: {path}")
    return open(path, newline="", encoding="utf-8-sig")


def chunked(iterable, size: int):
    chunk = []
    for item in iterable:
        chunk.append(item)
        if len(chunk) >= size:
            yield chunk
            chunk = []
    if chunk:
        yield chunk


def clean_row(raw_row: dict) -> dict:
    """Strips whitespace from every field; tolerates missing/None values.

    Government CSV exports routinely have stray leading/trailing whitespace
    and occasional short rows (missing trailing columns), which csv.DictReader
    fills with None rather than raising — so every field access downstream
    goes through this rather than raw string ops.
    """
    return {k: (v or "").strip() for k, v in raw_row.items() if k is not None}


@dataclass
class RowImportStats:
    """Shared skip-tracking for the lookup CSV importers (products, supermarkets)."""

    imported: int = 0
    skipped: int = 0
    skip_reasons: Counter = field(default_factory=Counter)

    def skip(self, row_num: int, reason: str) -> None:
        print(f"  SKIP row {row_num}: {reason}")
        self.skipped += 1
        self.skip_reasons[reason] += 1

    def print_summary(self, label: str) -> None:
        print(f"\n{label}: imported {self.imported} docs, skipped {self.skipped} rows")
        for reason, count in self.skip_reasons.most_common():
            print(f"  - {reason}: {count}")


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


def import_products(db, csv_path: Path, dry_run: bool) -> RowImportStats:
    stats = RowImportStats()
    writer = BatchWriter(db, dry_run)
    with open_csv(csv_path) as f:
        # start=2: row 1 is the header, so this lines up with the CSV's own
        # row numbering when eyeballing the file.
        for row_num, raw_row in enumerate(csv.DictReader(f), start=2):
            row = clean_row(raw_row)
            item_code = row.get("item_code", "")
            name = row.get("item", "")

            if not item_code:
                stats.skip(row_num, "missing item_code")
                continue
            if not name:
                stats.skip(row_num, "missing item name")
                continue

            ref = db.collection("products").document(item_code)
            writer.set(ref, {
                "itemCode": item_code,
                "name": name,
                "nameLower": name.lower(),
                "unit": row.get("unit", ""),
                "itemGroup": row.get("item_group", ""),
                "itemCategory": row.get("item_category", ""),
            })
            stats.imported += 1
    writer.flush()
    stats.print_summary("products")
    return stats


def import_supermarkets(db, csv_path: Path, dry_run: bool) -> RowImportStats:
    stats = RowImportStats()
    writer = BatchWriter(db, dry_run)
    with open_csv(csv_path) as f:
        for row_num, raw_row in enumerate(csv.DictReader(f), start=2):
            row = clean_row(raw_row)
            premise_code = row.get("premise_code", "")

            if not premise_code:
                stats.skip(row_num, "missing premise_code")
                continue

            ref = db.collection("supermarkets").document(premise_code)
            writer.set(ref, {
                "premiseCode": premise_code,
                "name": row.get("premise", ""),
                "address": row.get("address", ""),
                "premiseType": row.get("premise_type", ""),
                "district": row.get("district", ""),
                "state": row.get("state", ""),
            })
            stats.imported += 1
    writer.flush()
    stats.print_summary("supermarkets")
    return stats


@dataclass
class ImportStats:
    files_processed: int = 0
    new_records: int = 0
    duplicates_skipped: int = 0
    latest_updated: int = 0
    rows_malformed: int = 0
    skip_reasons: Counter = field(default_factory=Counter)

    def __iadd__(self, other: "ImportStats") -> "ImportStats":
        self.files_processed += other.files_processed
        self.new_records += other.new_records
        self.duplicates_skipped += other.duplicates_skipped
        self.latest_updated += other.latest_updated
        self.rows_malformed += other.rows_malformed
        self.skip_reasons += other.skip_reasons
        return self

    def skip(self, row_num: int, reason: str) -> None:
        print(f"  SKIP row {row_num}: {reason}")
        self.rows_malformed += 1
        self.skip_reasons[reason] += 1

    def print_summary(self) -> None:
        print("\n=== Import Summary ===")
        print(f"Files processed:            {self.files_processed}")
        print(f"New price records imported: {self.new_records}")
        print(f"Duplicate records skipped:  {self.duplicates_skipped}")
        print(f"latest_prices updated:      {self.latest_updated}")
        print(f"Malformed rows skipped:     {self.rows_malformed}")
        for reason, count in self.skip_reasons.most_common():
            print(f"  - {reason}: {count}")


def _read_price_rows(csv_path: Path, since: str | None, limit: int | None, stats: ImportStats):
    """Streams (item_code, premise_code, date_str, price) tuples from one CSV.

    Rows missing a required key, or with an unparseable price, are logged
    and skipped rather than raising — one malformed row from a government
    export shouldn't abort the whole import.
    """
    with open_csv(csv_path) as f:
        for row_num, raw_row in enumerate(csv.DictReader(f), start=2):
            if limit is not None and (row_num - 2) >= limit:
                break

            row = clean_row(raw_row)
            item_code = row.get("item_code", "")
            premise_code = row.get("premise_code", "")
            date_str = row.get("date", "")
            price_raw = row.get("price", "")

            if not item_code:
                stats.skip(row_num, "missing item_code")
                continue
            if not premise_code:
                stats.skip(row_num, "missing premise_code")
                continue
            if not date_str:
                stats.skip(row_num, "missing date")
                continue

            try:
                price = float(price_raw)
            except ValueError:
                stats.skip(row_num, "invalid price")
                continue

            if since and date_str < since:
                continue  # outside the requested window, not malformed

            yield item_code, premise_code, date_str, price


def _import_prices_chunk(db, chunk: list[tuple[str, str, str, float]], dry_run: bool, stats: ImportStats) -> None:
    """Writes only the rows in `chunk` whose `prices` doc doesn't already exist."""
    refs = [
        db.collection("prices").document(f"{item}_{premise}_{date}")
        for item, premise, date, _price in chunk
    ]

    existing_ids: set[str] = set()
    if refs:
        for snap in db.get_all(refs):
            if snap.exists:
                existing_ids.add(snap.id)

    batch = None if dry_run else db.batch()
    pending = 0
    seen_in_chunk: set[str] = set()

    for (item, premise, date, price), ref in zip(chunk, refs):
        if ref.id in existing_ids or ref.id in seen_in_chunk:
            stats.duplicates_skipped += 1
            continue
        seen_in_chunk.add(ref.id)
        stats.new_records += 1
        if not dry_run:
            batch.set(ref, {
                "itemCode": item,
                "premiseCode": premise,
                "date": date,
                "price": price,
            })
            pending += 1

    if not dry_run and pending:
        batch.commit()


def _advance_latest_prices(
    db,
    candidates: dict[tuple[str, str], tuple[str, float]],
    dry_run: bool,
    stats: ImportStats,
) -> None:
    """Upserts `latest_prices` only where `candidates` is newer than what's stored."""
    keys = list(candidates.keys())

    for key_chunk in chunked(keys, BATCH_LIMIT):
        refs = [
            db.collection("latest_prices").document(f"{item}_{premise}")
            for item, premise in key_chunk
        ]

        existing_dates: dict[str, str] = {}
        if refs:
            for snap in db.get_all(refs):
                if snap.exists:
                    data = snap.to_dict() or {}
                    existing_dates[snap.id] = data.get("date", "")

        batch = None if dry_run else db.batch()
        pending = 0

        for (item, premise), ref in zip(key_chunk, refs):
            new_date, new_price = candidates[(item, premise)]
            current_date = existing_dates.get(ref.id)
            if current_date is not None and current_date >= new_date:
                continue  # what's stored is already as new or newer

            stats.latest_updated += 1
            if not dry_run:
                batch.set(ref, {
                    "itemCode": item,
                    "premiseCode": premise,
                    "date": new_date,
                    "price": new_price,
                    "updatedAt": firestore.SERVER_TIMESTAMP,
                })
                pending += 1

        if not dry_run and pending:
            batch.commit()


def import_prices_file(
    db,
    csv_path: Path,
    dry_run: bool,
    since: str | None = None,
    limit: int | None = None,
) -> ImportStats:
    """Imports one monthly PriceCatcher CSV. Safe to re-run / re-order."""
    stats = ImportStats(files_processed=1)

    # (item_code, premise_code) -> (date_str, price) for the newest row seen
    # *within this file*. Bounded by the number of distinct item/premise
    # pairs in a single month, not by row count, so this stays small even
    # for a file with hundreds of thousands of rows.
    latest_in_file: dict[tuple[str, str], tuple[str, float]] = {}

    for chunk in chunked(_read_price_rows(csv_path, since, limit, stats), BATCH_LIMIT):
        _import_prices_chunk(db, chunk, dry_run, stats)
        for item, premise, date, price in chunk:
            key = (item, premise)
            current = latest_in_file.get(key)
            if current is None or date >= current[0]:
                latest_in_file[key] = (date, price)

    _advance_latest_prices(db, latest_in_file, dry_run, stats)

    print(
        f"  {csv_path.name}: {stats.new_records} new, "
        f"{stats.duplicates_skipped} duplicates skipped, "
        f"{stats.latest_updated} latest_prices updated, "
        f"{stats.rows_malformed} rows skipped (malformed)"
    )
    return stats


def import_prices(
    db,
    prices_path: Path,
    dry_run: bool,
    since: str | None,
    limit: int | None,
) -> ImportStats:
    """Imports a single CSV, or every *.csv in a directory in filename order.

    Name monthly files so that sorted filenames are chronological order,
    e.g. pricecatcher_2026-01.csv, pricecatcher_2026-02.csv, ...
    """
    if prices_path.is_dir():
        files = sorted(prices_path.glob("*.csv"))
        if not files:
            sys.exit(f"No CSV files found in {prices_path}")
    else:
        files = [prices_path]

    total = ImportStats()
    for f in files:
        print(f"Importing {f} ...")
        total += import_prices_file(db, f, dry_run, since, limit)
    return total


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--credentials", required=True, help="Path to Firebase service account JSON key")
    parser.add_argument("--items", default="data/lookup_item.csv", help="Path to lookup_item.csv")
    parser.add_argument("--premises", default="data/lookup_premise.csv", help="Path to lookup_premise.csv")
    parser.add_argument(
        "--prices",
        default="data/pricecatcher.csv",
        help="Path to a single pricecatcher CSV, or a directory of monthly CSVs (imported in filename order)",
    )
    parser.add_argument("--since", default=None, help="Only import price rows with date >= YYYY-MM-DD")
    parser.add_argument("--limit", type=int, default=None, help="Only import the first N price rows per file (for testing)")
    parser.add_argument("--skip-products", action="store_true", help="Skip lookup_item.csv import")
    parser.add_argument("--skip-supermarkets", action="store_true", help="Skip lookup_premise.csv import")
    parser.add_argument("--skip-prices", action="store_true", help="Skip pricecatcher CSV import")
    parser.add_argument("--dry-run", action="store_true", help="Parse and count rows without writing to Firestore")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    db = init_firestore(args.credentials)

    if not args.skip_products:
        import_products(db, Path(args.items), args.dry_run)
    if not args.skip_supermarkets:
        import_supermarkets(db, Path(args.premises), args.dry_run)

    if not args.skip_prices:
        stats = import_prices(db, Path(args.prices), args.dry_run, args.since, args.limit)
        stats.print_summary()

    if args.dry_run:
        print("\nDry run complete — no writes were made.")


if __name__ == "__main__":
    main()
