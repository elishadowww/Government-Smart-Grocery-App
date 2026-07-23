# PriceCatcher SQLite database builder

Builds `assets/database/pricecatcher.db` locally from the PriceCatcher CSV
exports. This replaces the old Firestore importer — the database is now a
local file the Flutter app bundles as an asset, not a live cloud backend.

## Who needs to run this

Only whoever is producing/updating the database for the team. Everyone else
gets the finished `pricecatcher.db` from the project maintainer and places
it directly in `assets/database/` — see the root `README.md` for that path.
You don't need Python at all just to run the app.

## Setup

No external dependencies — this script only uses the Python standard
library. A virtualenv is optional but harmless:

```bash
cd tools/db_builder
python3 -m venv .venv && source .venv/bin/activate
```

You'll need the raw CSVs in place (not committed to git):

```
data/
  lookup_item.csv
  lookup_premise.csv
  pricecatcher/
    pricecatcher_2025-07.csv
    pricecatcher_2026-01.csv
    ... (all monthly files you want included)
```

## Run

```bash
python build_pricecatcher_db.py
```

Defaults assume the repo's normal layout (`../../data/...` in,
`../../assets/database/pricecatcher.db` out), so no arguments are usually
needed. Override any of them if your layout differs:

```bash
python build_pricecatcher_db.py \
  --items /path/to/lookup_item.csv \
  --premises /path/to/lookup_premise.csv \
  --prices /path/to/pricecatcher/ \
  --output /path/to/assets/database/pricecatcher.db
```

`--prices` accepts a single CSV or a directory — pointed at a directory, it
imports every `*.csv` in it. There's no quota and no per-run cap here (this
is a local file, not Firestore) — unlike the old importer, this script
always builds the **full history** in one shot, typically in well under a
minute even for the full multi-year dataset.

Every run wipes and rebuilds the output file from scratch — it's a
disposable build artifact, not something that accumulates state across
runs. Malformed rows (missing codes, unparseable prices, the CSVs'
sentinel "-1" placeholder rows) are logged with a row number and reason,
then skipped; a bad row never aborts the build.

## What it builds

- `products` — from `lookup_item.csv`
- `supermarkets` — from `lookup_premise.csv`
- `prices` — full history from every CSV under `--prices`
- `latest_prices` — derived automatically: the most recent price per
  (item, premise) pair, computed from `prices` after import. Nothing
  special to run for this — it's part of the same build.

## After building

1. Confirm `assets/database/pricecatcher.db` now exists (the script prints
   its final size and how long the build took).
2. Upload it to the team's shared location (e.g. Google Drive) so the rest
   of the team can grab it — see the root `README.md`.
3. Run the Flutter app — it picks up the new file automatically the next
   time it needs to (re)copy the local database. If you're testing a
   rebuild on a device/emulator that already ran the app before, uninstall
   the app first (or clear its data) so the stale previously-copied
   database doesn't linger — there's no version check, by design, to keep
   this simple.
