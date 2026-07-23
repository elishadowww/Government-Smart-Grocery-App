#!/usr/bin/env python3
"""Build the local SQLite database backing the PriceCatcher catalog.

Reads the same three PriceCatcher CSV sources as before:

    lookup_item.csv     -> products
    lookup_premise.csv  -> supermarkets
    pricecatcher/*.csv  -> prices (full history) + latest_prices (derived)

...and writes a single SQLite file instead of pushing to Firestore. This is
a local build artifact, not a live backend: there's no daily quota, no
network, and no partial/incremental state to manage across runs — every run
wipes and rebuilds the output file from scratch. Re-run it whenever the CSV
inputs change (e.g. a new monthly PriceCatcher file arrives).

The output is NOT meant to be committed to git (it's large, and the whole
point of this script is that it's cheaply reproducible from the CSVs).
Default output path is assets/database/pricecatcher.db, which the Flutter
app copies into its local storage on first launch. See tools/db_builder/README.md.

Usage:
    python build_pricecatcher_db.py \\
        --items ../../data/lookup_item.csv \\
        --premises ../../data/lookup_premise.csv \\
        --prices ../../data/pricecatcher/

All defaults already point at ../../data relative to this script and
../../assets/database/pricecatcher.db for the output, so in the common case
(repo layout unchanged) you can just run:

    python build_pricecatcher_db.py
"""

from __future__ import annotations

import argparse
import csv
import sqlite3
import sys
import time
from collections import Counter
from dataclasses import dataclass, field
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parents[1]

INSERT_BATCH_SIZE = 5000


def open_csv(path: Path):
    if not path.exists():
        sys.exit(f"CSV not found: {path}")
    return open(path, newline="", encoding="utf-8-sig")


def clean_row(raw_row: dict) -> dict:
    """Strips whitespace from every field; tolerates missing/None values."""
    return {k: (v or "").strip() for k, v in raw_row.items() if k is not None}


def normalize_code(value: str) -> str:
    """Canonicalizes an item/premise code across files that disagree on format.

    lookup_premise.csv stores premise_code as "2.0" (a spreadsheet float
    artifact); pricecatcher.csv stores the same premise as "2". Left
    unnormalized, every price row's premise_code would fail to match the
    supermarket row it's supposed to join to.
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
class RowStats:
    imported: int = 0
    skipped: int = 0
    skip_reasons: Counter = field(default_factory=Counter)

    def skip(self, row_num: int, reason: str) -> None:
        print(f"  SKIP row {row_num}: {reason}")
        self.skipped += 1
        self.skip_reasons[reason] += 1

    def print_summary(self, label: str) -> None:
        print(f"{label}: imported {self.imported:,} rows, skipped {self.skipped:,} rows")
        for reason, count in self.skip_reasons.most_common():
            print(f"  - {reason}: {count}")


SCHEMA = """
CREATE TABLE products (
    item_code     TEXT PRIMARY KEY,
    name          TEXT NOT NULL,
    name_lower    TEXT NOT NULL,
    unit          TEXT,
    item_group    TEXT,
    item_category TEXT
);

CREATE TABLE supermarkets (
    premise_code  TEXT PRIMARY KEY,
    name          TEXT NOT NULL,
    address       TEXT,
    premise_type  TEXT,
    district      TEXT,
    state         TEXT
);

CREATE TABLE prices (
    item_code    TEXT NOT NULL,
    premise_code TEXT NOT NULL,
    date         TEXT NOT NULL,
    price        REAL NOT NULL
);
"""
# No primary key / index on `prices` at creation time — with ~20M+ rows,
# maintaining a composite-key index on every single insert makes a bulk
# load dramatically slower (and bloats the file, since SQLite has to
# rebalance the index B-tree incrementally). Indexes are added once, in
# one pass, after all rows are in — see build_indexes().


def build_schema(conn: sqlite3.Connection) -> None:
    conn.executescript(SCHEMA)


def import_products(conn: sqlite3.Connection, csv_path: Path) -> RowStats:
    stats = RowStats()
    rows = []
    with open_csv(csv_path) as f:
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

            rows.append((
                item_code, name, name.lower(),
                row.get("unit", ""), row.get("item_group", ""), row.get("item_category", ""),
            ))
            stats.imported += 1

    conn.executemany(
        "INSERT INTO products (item_code, name, name_lower, unit, item_group, item_category) "
        "VALUES (?, ?, ?, ?, ?, ?)",
        rows,
    )
    stats.print_summary("products")
    return stats


def import_supermarkets(conn: sqlite3.Connection, csv_path: Path) -> RowStats:
    stats = RowStats()
    rows = []
    with open_csv(csv_path) as f:
        for row_num, raw_row in enumerate(csv.DictReader(f), start=2):
            row = clean_row(raw_row)
            premise_code = normalize_code(row.get("premise_code", ""))
            name = row.get("premise", "")

            if not premise_code:
                stats.skip(row_num, "missing premise_code")
                continue
            if not name:
                stats.skip(row_num, "missing premise name")
                continue

            rows.append((
                premise_code, name, row.get("address", ""),
                row.get("premise_type", ""), row.get("district", ""), row.get("state", ""),
            ))
            stats.imported += 1

    conn.executemany(
        "INSERT INTO supermarkets (premise_code, name, address, premise_type, district, state) "
        "VALUES (?, ?, ?, ?, ?, ?)",
        rows,
    )
    stats.print_summary("supermarkets")
    return stats


def import_prices_file(conn: sqlite3.Connection, csv_path: Path, stats: RowStats) -> None:
    batch = []
    with open_csv(csv_path) as f:
        for row_num, raw_row in enumerate(csv.DictReader(f), start=2):
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

            batch.append((item_code, premise_code, date_str, price))
            stats.imported += 1
            if len(batch) >= INSERT_BATCH_SIZE:
                _flush_price_batch(conn, batch)
                batch = []

    _flush_price_batch(conn, batch)


def _flush_price_batch(conn: sqlite3.Connection, batch: list[tuple]) -> None:
    if not batch:
        return
    conn.executemany(
        "INSERT INTO prices (item_code, premise_code, date, price) VALUES (?, ?, ?, ?)",
        batch,
    )


def import_prices(conn: sqlite3.Connection, prices_path: Path) -> RowStats:
    if prices_path.is_dir():
        files = sorted(prices_path.glob("*.csv"))
        if not files:
            sys.exit(f"No CSV files found in {prices_path}")
    else:
        files = [prices_path]

    stats = RowStats()
    for f in files:
        print(f"Importing {f.name} ...")
        import_prices_file(conn, f, stats)

    stats.print_summary(f"prices ({len(files)} file(s))")
    return stats


def build_latest_prices(conn: sqlite3.Connection) -> int:
    """One row per (item_code, premise_code): the most recent price seen
    across every imported month. Ties on date are broken arbitrarily but
    deterministically by SQLite's ROW_NUMBER() — a real duplicate exact
    (item, premise, date) row can't happen since that's the prices table's
    primary key.
    """
    conn.execute("""
        CREATE TABLE latest_prices AS
        SELECT item_code, premise_code, date, price FROM (
            SELECT item_code, premise_code, date, price,
                   ROW_NUMBER() OVER (
                       PARTITION BY item_code, premise_code
                       ORDER BY date DESC
                   ) AS rn
            FROM prices
        )
        WHERE rn = 1
    """)
    return conn.execute("SELECT COUNT(*) FROM latest_prices").fetchone()[0]


def build_indexes(conn: sqlite3.Connection) -> None:
    # Only idx_prices_item_date is needed on the big table: every history
    # query filters by item_code first (premise_code, when present, is
    # always a secondary filter on top of it — see PriceRepository.getHistory)
    # so a second (premise_code, date) index would just be dead weight on
    # a 20M+ row table.
    conn.executescript("""
        CREATE INDEX idx_prices_item_date ON prices (item_code, date);
        CREATE UNIQUE INDEX idx_latest_prices_pk ON latest_prices (item_code, premise_code);
        CREATE INDEX idx_latest_prices_item_price ON latest_prices (item_code, price);
        CREATE INDEX idx_supermarkets_state ON supermarkets (state);
        CREATE INDEX idx_supermarkets_district ON supermarkets (district);
        CREATE INDEX idx_products_category ON products (item_category);
    """)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--items", default=str(PROJECT_ROOT / "data" / "lookup_item.csv"))
    parser.add_argument("--premises", default=str(PROJECT_ROOT / "data" / "lookup_premise.csv"))
    parser.add_argument("--prices", default=str(PROJECT_ROOT / "data" / "pricecatcher"))
    parser.add_argument("--output", default=str(PROJECT_ROOT / "assets" / "database" / "pricecatcher.db"))
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    if output_path.exists():
        output_path.unlink()

    start = time.time()
    conn = sqlite3.connect(output_path)
    # This is a disposable build artifact, not a live database — trade
    # durability for build speed.
    conn.execute("PRAGMA synchronous = OFF")
    conn.execute("PRAGMA journal_mode = MEMORY")

    try:
        build_schema(conn)
        import_products(conn, Path(args.items))
        import_supermarkets(conn, Path(args.premises))
        import_prices(conn, Path(args.prices))

        print("Building latest_prices ...")
        latest_count = build_latest_prices(conn)
        print(f"latest_prices: {latest_count:,} rows")

        print("Building indexes ...")
        build_indexes(conn)

        conn.commit()
    finally:
        conn.close()

    elapsed = time.time() - start
    size_mb = output_path.stat().st_size / (1024 * 1024)
    print(f"\nDone in {elapsed:.1f}s -> {output_path} ({size_mb:.1f} MB)")


if __name__ == "__main__":
    main()
