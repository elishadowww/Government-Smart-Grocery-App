#!/usr/bin/env python3
"""Import Malaysia PriceCatcher CSV datasets into Firestore.

Populates three collections (see lib/core/constants/firestore_constants.dart
for the matching Dart-side field names):

    products        <- lookup_item.csv       (doc id = item_code)
    supermarkets    <- lookup_premise.csv    (doc id = premise_code)
    latest_prices   <- pricecatcher*.csv     (doc id = {item_code}_{premise_code})
    prices          <- pricecatcher*.csv     (doc id = {item_code}_{premise_code}_{date}, opt-in only)

DESIGN FOR FIREBASE SPARK (FREE TIER), NOT PRODUCTION SCALE
-------------------------------------------------------------------------
The full PriceCatcher history is ~22.7 million rows across a year's worth
of monthly files. Spark caps every project at 20,000 writes/day and 50,000
reads/day — nowhere near enough to bulk-load that. So, by default, this
script:

  - Imports `products` and `supermarkets` in full (a few thousand rows —
    trivially within quota).
  - Imports ONLY the single most recent monthly price CSV, and writes ONLY
    to `latest_prices` (skips the full `prices` history collection
    entirely). This is enough to power current-price features — product
    search, price comparison, shopping-list cost totals, and budget
    tracking all read from `latest_prices`, never from history.
  - Still won't usually fit a whole month in one run (a single month can
    have 100K+ distinct item/premise pairs). Two ways to handle that
    without ever exceeding quota:
      1. `--states "Sabah,W.P. Labuan"` — scope to specific states, small
         enough to finish in one run. Good for "get a working demo today".
      2. `--max-writes 15000` — cap writes per run and just re-run the
         same command again after the daily quota resets. A local
         checkpoint file (`<csv>.synced.tsv`, next to the CSV) remembers
         which pairs are already synced, so a resumed run never re-reads
         or re-writes them — it only spends today's quota on what's left.

`--with-history` restores the old production-scale behavior (writes full
history for every file in a folder, in filename order) for later, once
you're on the Blaze plan or otherwise have quota to spare. The Firestore
schema doesn't change either way, so turning it on later is a flag flip,
not a redesign — `prices` already exists and is simply unpopulated until
then.

Rows with a missing required field, or an unparseable price, are logged
(row number + reason) and skipped rather than aborting the run — Malaysian
government CSV exports are not perfectly clean (e.g. blank premise_code
rows, or `premise_code` written as "2.0" in one file and "2" in another —
this script normalizes that so joins across files don't silently break).

CSV files are streamed row by row, never loaded fully into memory.

Usage:
    # Everyday case: lookups in full, latest month only, scoped to fit
    # comfortably in Spark's daily quota
    python scripts/import_pricecatcher.py \\
        --credentials keys/firebase-admin.json \\
        --items data/lookup_item.csv --premises data/lookup_premise.csv \\
        --prices data/pricecatcher/ \\
        --states "Melaka,Negeri Sembilan,Perlis,W.P. Labuan"

    # No state filter: cap writes per run, re-run daily until fully synced
    python scripts/import_pricecatcher.py \\
        --credentials keys/firebase-admin.json \\
        --skip-products --skip-supermarkets \\
        --prices data/pricecatcher/ --max-writes 15000

    # Later, once you have real quota: full history, every month, in order
    python scripts/import_pricecatcher.py \\
        --credentials keys/firebase-admin.json \\
        --skip-products --skip-supermarkets \\
        --prices data/pricecatcher/ --with-history
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


def normalize_code(value: str) -> str:
    """Canonicalizes an item/premise code across files that disagree on format.

    lookup_premise.csv stores premise_code as "2.0" (a spreadsheet float
    artifact); pricecatcher.csv stores the same premise as "2". Left
    unnormalized, every price row's premiseCode would fail to match the
    supermarket doc id it's supposed to join to. Non-numeric codes pass
    through unchanged.
    """
    value = (value or "").strip()
    if not value:
        return value
    try:
        as_float = float(value)
    except ValueError:
        return value
    if as_float.is_integer():
        return str(int(as_float))
    return value


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
            item_code = normalize_code(row.get("item_code", ""))
            name = row.get("item", "")

            if not item_code:
                stats.skip(row_num, "missing item_code")
                continue
            if not name:
                # Also catches the "-1" sentinel row some PriceCatcher
                # exports use as a placeholder / unmatched-item bucket.
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
            premise_code = normalize_code(row.get("premise_code", ""))
            name = row.get("premise", "")

            if not premise_code:
                stats.skip(row_num, "missing premise_code")
                continue
            if not name:
                # Same "-1" sentinel-row pattern as lookup_item.csv.
                stats.skip(row_num, "missing premise name")
                continue

            ref = db.collection("supermarkets").document(premise_code)
            writer.set(ref, {
                "premiseCode": premise_code,
                "name": name,
                "address": row.get("address", ""),
                "premiseType": row.get("premise_type", ""),
                "district": row.get("district", ""),
                "state": row.get("state", ""),
            })
            stats.imported += 1
    writer.flush()
    stats.print_summary("supermarkets")
    return stats


def load_premise_states(csv_path: Path) -> dict[str, str]:
    """Builds a normalized premise_code -> state map, purely for local
    filtering (the `--states` flag) — never written to Firestore itself."""
    states: dict[str, str] = {}
    with open_csv(csv_path) as f:
        for raw_row in csv.DictReader(f):
            row = clean_row(raw_row)
            code = normalize_code(row.get("premise_code", ""))
            if code:
                states[code] = row.get("state", "")
    return states


def load_checkpoint(path: Path) -> set[tuple[str, str]]:
    """Loads (item_code, premise_code) pairs already confirmed synced to
    `latest_prices` by a previous run against this same CSV."""
    if not path.exists():
        return set()
    done: set[tuple[str, str]] = set()
    with open(path, encoding="utf-8") as f:
        for line in f:
            item, _, premise = line.rstrip("\n").partition("\t")
            if item and premise:
                done.add((item, premise))
    return done


def append_checkpoint(path: Path, keys) -> None:
    if not keys:
        return
    with open(path, "a", encoding="utf-8") as f:
        for item, premise in keys:
            f.write(f"{item}\t{premise}\n")


@dataclass
class ImportStats:
    files_processed: int = 0
    new_records: int = 0
    duplicates_skipped: int = 0
    latest_updated: int = 0
    latest_unchanged: int = 0
    latest_pending: int = 0
    rows_malformed: int = 0
    skip_reasons: Counter = field(default_factory=Counter)

    def __iadd__(self, other: "ImportStats") -> "ImportStats":
        self.files_processed += other.files_processed
        self.new_records += other.new_records
        self.duplicates_skipped += other.duplicates_skipped
        self.latest_updated += other.latest_updated
        self.latest_unchanged += other.latest_unchanged
        self.latest_pending += other.latest_pending
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
        print(f"latest_prices newly written:{self.latest_updated:>6}")
        print(f"latest_prices already synced (this run): {self.latest_unchanged}")
        if self.latest_pending:
            print(f"latest_prices still pending:{self.latest_pending:>6}  <- re-run tomorrow (or after quota resets) to continue")
        print(f"Malformed rows skipped:     {self.rows_malformed}")
        for reason, count in self.skip_reasons.most_common():
            print(f"  - {reason}: {count}")


def _read_price_rows(
    csv_path: Path,
    since: str | None,
    limit: int | None,
    stats: ImportStats,
    premise_states: dict[str, str] | None,
    states_filter: set[str] | None,
):
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
            item_code = normalize_code(row.get("item_code", ""))
            premise_code = normalize_code(row.get("premise_code", ""))
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

            if states_filter is not None:
                state = (premise_states or {}).get(premise_code)
                if state not in states_filter:
                    continue  # outside the requested scope, not malformed

            if since and date_str < since:
                continue  # outside the requested window, not malformed

            yield item_code, premise_code, date_str, price


def _import_prices_chunk(db, chunk: list[tuple[str, str, str, float]], dry_run: bool, stats: ImportStats) -> None:
    """Writes only the rows in `chunk` whose `prices` doc doesn't already exist.

    Only used under --with-history — the default Spark-safe path never
    touches the `prices` collection at all.
    """
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
    max_writes: int | None,
) -> set[tuple[str, str]]:
    """Upserts `latest_prices` only where `candidates` is newer than what's stored.

    Stops once `max_writes` new docs have been written in this call (if
    set), leaving whatever's left for a future run — callers are expected
    to persist the returned `settled` set to a checkpoint so that future
    run doesn't have to re-read (and re-pay for) work already done here.

    Returns the set of (item, premise) keys now confirmed settled — either
    just written, or already up to date — safe to never check again for
    this month's data.
    """
    settled: set[tuple[str, str]] = set()
    keys = list(candidates.keys())

    for key_chunk in chunked(keys, BATCH_LIMIT):
        if max_writes is not None and stats.latest_updated >= max_writes:
            break

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
            if max_writes is not None and stats.latest_updated >= max_writes:
                break  # leave the rest of this chunk (and beyond) for next run

            new_date, new_price = candidates[(item, premise)]
            current_date = existing_dates.get(ref.id)
            if current_date is not None and current_date >= new_date:
                stats.latest_unchanged += 1
                settled.add((item, premise))  # already up to date — never recheck
                continue

            stats.latest_updated += 1
            settled.add((item, premise))
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

    return settled


def import_prices_file(
    db,
    csv_path: Path,
    dry_run: bool,
    since: str | None = None,
    limit: int | None = None,
    with_history: bool = False,
    premise_states: dict[str, str] | None = None,
    states_filter: set[str] | None = None,
    max_writes: int | None = None,
    checkpoint_path: Path | None = None,
) -> ImportStats:
    """Imports one monthly PriceCatcher CSV. Safe to re-run / re-order.

    Default (with_history=False): never writes to the `prices` history
    collection. Aggregates locally, then upserts only `latest_prices`,
    skipping (via checkpoint) and capping (via max_writes) writes to stay
    inside Firestore's free-tier daily quota.
    """
    stats = ImportStats(files_processed=1)

    checkpoint = load_checkpoint(checkpoint_path) if checkpoint_path else set()
    if checkpoint:
        print(f"  resuming {csv_path.name}: {len(checkpoint):,} pairs already synced from a previous run")

    latest_in_file: dict[tuple[str, str], tuple[str, float]] = {}
    row_stream = _read_price_rows(csv_path, since, limit, stats, premise_states, states_filter)

    if with_history:
        for chunk in chunked(row_stream, BATCH_LIMIT):
            _import_prices_chunk(db, chunk, dry_run, stats)
            for item, premise, date, price in chunk:
                key = (item, premise)
                current = latest_in_file.get(key)
                if current is None or date >= current[0]:
                    latest_in_file[key] = (date, price)
    else:
        for item, premise, date, price in row_stream:
            key = (item, premise)
            current = latest_in_file.get(key)
            if current is None or date >= current[0]:
                latest_in_file[key] = (date, price)

    candidates = {k: v for k, v in latest_in_file.items() if k not in checkpoint}
    already_synced = len(latest_in_file) - len(candidates)

    settled = _advance_latest_prices(db, candidates, dry_run, stats, max_writes)
    stats.latest_pending = len(candidates) - len(settled)

    if checkpoint_path and not dry_run:
        append_checkpoint(checkpoint_path, sorted(settled))

    print(
        f"  {csv_path.name}: {len(latest_in_file):,} pairs seen "
        f"({already_synced:,} already synced), "
        f"{stats.latest_updated:,} newly written, "
        f"{stats.latest_unchanged:,} already up to date, "
        f"{stats.latest_pending:,} pending, "
        + (f"{stats.new_records:,} history rows new, " if with_history else "")
        + f"{stats.rows_malformed:,} rows skipped (malformed)"
    )
    if stats.latest_pending:
        print(f"  -> quota reached; re-run the same command later to continue {csv_path.name}")
    return stats


def import_prices(
    db,
    prices_path: Path,
    dry_run: bool,
    since: str | None,
    limit: int | None,
    with_history: bool,
    premise_states: dict[str, str] | None,
    states_filter: set[str] | None,
    max_writes: int | None,
) -> ImportStats:
    """Resolves `prices_path` to the file(s) to import, then imports them.

    With --with-history: a single CSV, or every *.csv in a directory in
    filename order (name files so sorted order is chronological, e.g.
    pricecatcher_2026-01.csv, pricecatcher_2026-02.csv, ...) — builds full
    history plus the true cross-month latest price.

    Without --with-history (the default): a single CSV as given, or — if
    given a directory — only the most recent file in it (highest sorted
    filename). This is what "import only the latest month" means in
    practice: no need to even read the older files.
    """
    if prices_path.is_dir():
        files = sorted(prices_path.glob("*.csv"))
        if not files:
            sys.exit(f"No CSV files found in {prices_path}")
        if not with_history:
            skipped = files[:-1]
            files = files[-1:]
            if skipped:
                print(
                    f"Latest-only mode: importing {files[0].name}, "
                    f"skipping {len(skipped)} older file(s) in {prices_path} "
                    "(pass --with-history to import all of them)"
                )
    else:
        files = [prices_path]

    total = ImportStats()
    for f in files:
        print(f"Importing {f} ...")
        checkpoint_path = f.parent / f"{f.name}.synced.tsv"
        total += import_prices_file(
            db, f, dry_run, since, limit,
            with_history=with_history,
            premise_states=premise_states,
            states_filter=states_filter,
            max_writes=max_writes,
            checkpoint_path=checkpoint_path,
        )
    return total


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--credentials", required=True, help="Path to Firebase service account JSON key")
    parser.add_argument("--items", default="data/lookup_item.csv", help="Path to lookup_item.csv")
    parser.add_argument("--premises", default="data/lookup_premise.csv", help="Path to lookup_premise.csv")
    parser.add_argument(
        "--prices",
        default="data/pricecatcher/",
        help="Path to a pricecatcher CSV, or a directory of monthly CSVs",
    )
    parser.add_argument("--since", default=None, help="Only import price rows with date >= YYYY-MM-DD")
    parser.add_argument("--limit", type=int, default=None, help="Only read the first N price rows per file (for testing)")
    parser.add_argument(
        "--states",
        default=None,
        help='Comma-separated state names to scope the price import to, e.g. "Melaka,Perlis,W.P. Labuan" '
             "(must match lookup_premise.csv's state column exactly). Keeps a single run comfortably "
             "within Spark's daily quota.",
    )
    parser.add_argument(
        "--max-writes",
        type=int,
        default=None,
        help="Cap latest_prices writes for this run (e.g. 15000, safely under Spark's 20K/day limit). "
             "Re-run the same command after the quota resets to continue where it left off.",
    )
    parser.add_argument(
        "--with-history",
        action="store_true",
        help="Also write full price history to the `prices` collection, and process every file in "
             "--prices if it's a directory. Needs far more quota than Spark's free tier provides — "
             "intended for once you're on Blaze (or otherwise have quota to spare).",
    )
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
        premise_states = None
        states_filter = None
        if args.states:
            states_filter = {s.strip() for s in args.states.split(",") if s.strip()}
            premise_states = load_premise_states(Path(args.premises))
            matched = sum(1 for s in premise_states.values() if s in states_filter)
            if matched == 0:
                available = sorted(set(premise_states.values()))
                sys.exit(
                    f"--states matched 0 premises. Available states in {args.premises}:\n  "
                    + "\n  ".join(available)
                )
            print(f"--states filter matches {matched:,} premises: {sorted(states_filter)}")

        stats = import_prices(
            db, Path(args.prices), args.dry_run, args.since, args.limit,
            with_history=args.with_history,
            premise_states=premise_states,
            states_filter=states_filter,
            max_writes=args.max_writes,
        )
        stats.print_summary()

    if args.dry_run:
        print("\nDry run complete — no writes were made.")


if __name__ == "__main__":
    main()
