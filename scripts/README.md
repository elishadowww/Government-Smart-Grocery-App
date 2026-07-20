# PriceCatcher → Firestore import

One-off/repeatable script that loads the Malaysia PriceCatcher CSV exports
into the Firestore collections consumed by the Flutter app (see
`lib/core/constants/firestore_constants.dart` for the schema).

## Setup

```bash
cd scripts
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

Download a service account key for the `smart-grocery-3b932` Firebase
project (Project Settings → Service Accounts → Generate new private key).
**Never commit this file** — it's already covered by the repo `.gitignore`.

Place the CSVs somewhere local, e.g. a `data/` folder at the repo root
(also gitignored). PriceCatcher ships `lookup_item.csv` and
`lookup_premise.csv` once and a new price file every month — keep the
monthly files in their own folder, named so that sorted filenames are also
chronological order:

```
data/
  lookup_item.csv
  lookup_premise.csv
  pricecatcher/
    pricecatcher_2026-06.csv
    pricecatcher_2026-07.csv
    ...
```

## Run

Initial load (lookups + every monthly price file found in the folder, in
filename order):

```bash
python3 import_pricecatcher.py \
  --credentials /path/to/serviceAccountKey.json \
  --items ../data/lookup_item.csv \
  --premises ../data/lookup_premise.csv \
  --prices ../data/pricecatcher/
```

Monthly update, once a new PriceCatcher file drops (lookups rarely change,
so skip re-importing them):

```bash
python3 import_pricecatcher.py \
  --credentials /path/to/serviceAccountKey.json \
  --skip-products --skip-supermarkets \
  --prices ../data/pricecatcher/pricecatcher_2026-08.csv
```

`--prices` accepts either a single file or a directory — pass just the new
month's file and the rest of the folder is left untouched.

### How monthly imports stay safe

- **Nothing is replaced.** Every `prices` doc id is derived from
  `{item_code}_{premise_code}_{date}`. Before writing, the script checks
  (in batches, not one-by-one) whether that id already exists and skips it
  if so — existing historical records are never overwritten.
- **Duplicates are automatic no-ops.** Re-running the same file, or an
  overlapping file, just re-detects the existing docs and skips them —
  safe to re-run after a failure or to re-import a month you're unsure
  was fully loaded.
- **`latest_prices` only moves forward.** For each (item, premise), the
  script compares the row's date against whatever is currently stored in
  `latest_prices` and only upserts it if the new date is strictly newer.
  Importing an old backfill month after newer data is already loaded
  won't regress the "current price" view.

Useful flags:

- `--dry-run` — parse and count rows without writing anything, to sanity
  check a file first.
- `--since 2026-06-01` — only import price rows with date >= this value.
- `--limit 5000` — cap rows processed per file, for a quick smoke test.
- `--skip-products` / `--skip-supermarkets` / `--skip-prices` — skip a
  section entirely.

### Malformed rows

Every importer (`products`, `supermarkets`, `prices`) validates required
fields per row — non-empty `item_code`/`premise_code`/`date`, a parseable
`price` — after trimming whitespace from every field. A bad row (e.g. an
empty `premise_code`, which previously crashed the whole import trying to
write to `supermarkets/`) is logged with its row number and reason, then
skipped; it never aborts the run.

### Output

Each malformed row is logged as it's found, each file prints its own
one-line result, and a final summary covers everything processed in that
run:

```
Importing ../data/pricecatcher/pricecatcher_2026-07.csv ...
  SKIP row 48213: missing premise_code
  SKIP row 91887: invalid price
  pricecatcher_2026-07.csv: 812343 new, 0 duplicates skipped, 154211 latest_prices updated, 2 rows skipped (malformed)

=== Import Summary ===
Files processed:            1
New price records imported: 812343
Duplicate records skipped:  0
latest_prices updated:      154211
Malformed rows skipped:     2
  - missing premise_code: 1
  - invalid price: 1
```

`import_products`/`import_supermarkets` print their own analogous summary
(imported count, skipped count, and a breakdown by reason).
