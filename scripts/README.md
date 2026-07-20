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

Place the three CSVs somewhere local, e.g. a `data/` folder at the repo
root (also gitignored):

```
data/
  lookup_item.csv
  lookup_premise.csv
  pricecatcher.csv
  pricecatcher/
```

## Run

```bash
python3 import_pricecatcher.py \
  --credentials /path/to/serviceAccountKey.json \
  --items ../data/lookup_item.csv \
  --premises ../data/lookup_premise.csv \
  --prices ../data/pricecatcher.csv
```

Useful flags:

- `--dry-run` — parse and count rows without writing anything, to sanity
  check the CSVs first.
- `--since 2026-06-01` — only import price rows from that date onward.
  PriceCatcher's full history is large; scope the initial import to a
  recent window and widen it later if needed.
- `--limit 5000` — cap the number of price rows processed, for a quick
  smoke test end-to-end.
- `--skip-products` / `--skip-supermarkets` / `--skip-prices` — re-run just
  one part (e.g. re-import prices only after the first successful load).

The script is idempotent: document ids are derived deterministically from
`item_code` / `premise_code` / `date`, so re-running it upserts rather than
duplicating data.
