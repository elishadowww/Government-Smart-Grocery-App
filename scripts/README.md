# PriceCatcher → Firestore import

Loads the Malaysia PriceCatcher CSV exports into the Firestore collections
consumed by the Flutter app (see `lib/core/constants/firestore_constants.dart`
for the schema).

**This is currently tuned for Firebase Spark (free tier) and a university
prototype, not production scale.** The full PriceCatcher history is ~22.7
million rows across a year of monthly files — nowhere near Spark's 20,000
writes/day and 50,000 reads/day quota. So by default this script:

- Imports `lookup_item.csv` and `lookup_premise.csv` **completely** (a few
  thousand rows each — trivial for the quota).
- Imports **only the single most recent monthly price CSV**, and writes
  **only** to `latest_prices` — never to the full `prices` history
  collection.
- Still won't usually fit a whole month in one run on its own (a month can
  have 100K+ distinct item/premise pairs). See "Fitting in the daily
  quota" below for the two ways to handle that.

Product Search, Price Comparison, Shopping List cost totals, and Budget
tracking all read from `products` + `supermarkets` + `latest_prices` —
none of them need price history, so this scope is enough for a fully
working prototype. Price Trends (which does need history) will just show
"not enough data yet" until you later opt into `--with-history` — see
below.

## Setup

```bash
cd scripts
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

Download a service account key for the Firebase project (Project Settings
→ Service Accounts → Generate new private key). **Never commit this
file** — it's already covered by the repo `.gitignore` (this repo keeps it
at `keys/firebase-admin.json`).

Place the CSVs somewhere local, e.g. a `data/` folder at the repo root
(also gitignored):

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

```bash
python3 import_pricecatcher.py \
  --credentials ../keys/firebase-admin.json \
  --items ../data/lookup_item.csv \
  --premises ../data/lookup_premise.csv \
  --prices ../data/pricecatcher/
```

Pointed at a directory, the default (Spark-safe) mode automatically picks
just the most recent file by filename — you don't need to name it
explicitly, and next month you run the exact same command to pick up
whatever's newest then.

## Fitting in the daily quota

Even one month's worth of `latest_prices` (deduplicated to one row per
item/premise pair) can be **~200K+ documents** — over 10x Spark's daily
write cap. Two ways to handle that, and you can combine them:

### Option A — scope to specific states, get a working demo today

```bash
python3 import_pricecatcher.py \
  --credentials ../keys/firebase-admin.json \
  --skip-products --skip-supermarkets \
  --prices ../data/pricecatcher/ \
  --states "Melaka,Negeri Sembilan,Perlis,W.P. Labuan"
```

`--states` filters to premises in the given states (must match
`lookup_premise.csv`'s `state` column exactly — comma-separated, spaces
around commas are fine). This is the fastest path to a fully working
demo: small states like Labuan (~1.6K premise/item pairs), Perlis (~3.2K),
Putrajaya (~3.6K), or Melaka (~5.6K) — even a handful combined — comfortably
fit a single run. It still exercises every feature end-to-end (search,
comparison, shopping list, budget), just over fewer stores.

### Option B — no filter, cap writes per run, resume across days

```bash
python3 import_pricecatcher.py \
  --credentials ../keys/firebase-admin.json \
  --skip-products --skip-supermarkets \
  --prices ../data/pricecatcher/ \
  --max-writes 15000
```

`--max-writes` stops the run once that many `latest_prices` docs have been
written (15000 leaves headroom under the 20K/day cap for anything else you
do that day). It writes a small checkpoint file next to the CSV
(`pricecatcher_2026-07.csv.synced.tsv`, gitignored along with the rest of
`data/`) recording which pairs are already synced. **Run the exact same
command again** once the quota resets (next day, or after upgrading) —
already-synced pairs are neither re-read nor re-written, so each run only
spends quota on what's actually left. Eventually a run reports `pending: 0`
and you're fully caught up for that month.

You can combine both — `--states` to shrink total scope, `--max-writes` as
a safety net in case that scope still doesn't fit in one run.

## Later: real historical data (Price Trends)

Nothing about the schema changes when you're ready for this — `prices`
already exists, just unpopulated. Once you're on Blaze (or otherwise have
quota to spare):

```bash
python3 import_pricecatcher.py \
  --credentials ../keys/firebase-admin.json \
  --skip-products --skip-supermarkets \
  --prices ../data/pricecatcher/ \
  --with-history
```

`--with-history` processes **every** file in the folder (in filename
order — name them so sorted order is chronological, e.g.
`pricecatcher_2026-01.csv`, `pricecatcher_2026-02.csv`, ...), writing full
history to `prices` in addition to advancing `latest_prices` across all
months. This is the same import logic used for the current-month-only
path — turning it on later is a flag, not a rewrite. Expect this to be
slow and to cost real money at full scale; see the note on Firestore
pricing from earlier in this project's history before running it
unscoped.

## How imports stay safe to re-run

- **Nothing is replaced.** `prices` doc ids are derived from
  `{item_code}_{premise_code}_{date}`; the script checks (in batches, not
  one-by-one) whether an id already exists before writing, so historical
  records are never overwritten.
- **`latest_prices` only moves forward.** For each (item, premise), the
  script compares the row's date against whatever is currently stored and
  only upserts if the new date is strictly newer — importing an older
  backfill month after newer data won't regress the "current price" view.
- **Codes are normalized across files.** `lookup_premise.csv` stores
  `premise_code` as `"2.0"` (a spreadsheet float artifact) while
  `pricecatcher.csv` stores the same premise as `"2"` — left as-is, every
  price row would fail to join to its supermarket. Both are normalized to
  the same canonical form before use.
- **Malformed rows are logged and skipped, not fatal.** Every importer
  validates required fields (non-empty `item_code`/`premise_code`/`name`/
  `date`, a parseable `price`) after trimming whitespace. A bad row (e.g.
  an empty `premise_code`, or the `-1` / `-1.0` sentinel row PriceCatcher
  uses as an "unmatched" placeholder) is logged with its row number and
  reason, then skipped — it never aborts the run.

## Other flags

- `--dry-run` — parse and count rows without writing anything.
- `--since 2026-06-01` — only import price rows with date >= this value.
- `--limit 5000` — only read the first N rows per file (quick smoke test).
- `--skip-products` / `--skip-supermarkets` / `--skip-prices` — skip a
  section entirely.

## Output

```
--states filter matches 1573 premises: ['W.P. Labuan']
Latest-only mode: importing pricecatcher_2026-07.csv, skipping 11 older file(s) in ../data/pricecatcher/ (pass --with-history to import all of them)
Importing ../data/pricecatcher/pricecatcher_2026-07.csv ...
  SKIP row 48213: missing premise_code
  pricecatcher_2026-07.csv: 1573 pairs seen (0 already synced), 1573 newly written, 0 already up to date, 0 pending, 1 rows skipped (malformed)

=== Import Summary ===
Files processed:            1
New price records imported: 0
Duplicate records skipped:  0
latest_prices newly written:  1573
latest_prices already synced (this run): 0
Malformed rows skipped:     1
  - missing premise_code: 1
```

`import_products`/`import_supermarkets` print their own analogous summary
(imported count, skipped count, and a breakdown by skip reason).
