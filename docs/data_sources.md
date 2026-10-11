# Data sources, CATCHMENT

Registered 2026-08-19 (NZ time). Ministry of Education, via Education Counts.

| # | Source | URL | Status | Local path |
|---|---|---|---|---|
| 1 | Student rolls by school, 2010–2025 | https://www.educationcounts.govt.nz/statistics/school-rolls/downloads/2-Student-rolls-by-school-2010-2025-v2.xlsx | Downloaded | `data/raw/2-Student-rolls-by-school-2010-2025-v2.xlsx` |
| 2 | Roll by funding year level & ethnicity, 2014–2025 | https://www.educationcounts.govt.nz/__data/assets/file/0006/195360/10-Machine-readable-Roll-by-funding-year-level-ethnicity-2014-2025.zip | Downloaded (unzipped) | `data/raw/10-Machine Readable-Roll by Funding year level ethnicity 2014-2025.csv` |
| 3 | NZ schools directory | Builder UI: https://www.educationcounts.govt.nz/directories/list-of-nz-schools, "Download the whole directory" → CSV export. API base `https://catalogue.data.govt.nz/api/3/action/datastore_search_sql`, resource_id `4b292323-9fcc-41f8-814b-3c7b19cf14b3` | Downloaded | `data/raw/directory.csv` |
| 4a | School closures/mergers/new schools, 2026 | https://www.educationcounts.govt.nz/directories/6136/School-closures-mergers-and-new-March-2026.xlsx | Downloaded | `data/raw/School-closures-mergers-and-new-March-2026.xlsx` |
| 4b | School closures/mergers/new schools, 2004–2025 (historical) | https://www.educationcounts.govt.nz/__data/assets/file/0012/198957/school-mergers-closures-new-schools.zip | Downloaded (unzipped, one workbook per year) | `data/raw/2004-2025-School-Mergers/` |
| 5 | National school roll projections | https://www.educationcounts.govt.nz/statistics/national-school-roll-projection | Context only, not competing with it, just citing it |, |

## Database engine

Confirmed 2026-08-19: SQL Server 17.0.1000.7 running on `localhost`
(instance `Gaby86\gabyg`), verified by connecting from Azure Data Studio.

## Note on how URLs 2–4b were found

This session's cloud container has no direct network access to
educationcounts.govt.nz or catalogue.data.govt.nz (confirmed with
`curl`: `HTTP 000`, timeout, only an allowlist for package registries
like npm). URLs 2, 4a and 4b were found via WebFetch (which runs on
Anthropic's infrastructure, not in this container) reading the HTML of
Education Counts pages and extracting the literal `href`s. They were
verified by Gaby actually downloading each file.

Still pending: SHA256 hash and byte size for each downloaded file.

## Licence

Confirmed 2026 against `educationcounts.govt.nz/site-info/privacy`: Ministry
of Education open data (sources 1-5 above) is released under **CC BY 4.0
International**, commercial reuse permitted with attribution. Checked
directly against the primary source, not assumed from a secondary one.

## Note on source #4b scope

Only 2010-2025 (16 of the 22 yearly workbooks) was loaded into staging, 2004-2009 use 3 different, incompatible sheet structures across just 6
years and were left out as a documented gap. Within the loaded years, 5
of the 6 sheet types per workbook were loaded (New, Closures, Mergers,
Name Changes, School Type Changes); **Definition-Authority Changes was
not loaded** after a severe Excel "used range" performance problem (row
counts exceeded 30 million before cleanup) and a check that none of the
planned analyses need it. Full reasoning for both decisions is in
`METHODOLOGY.md`.

## Star schema

All staging tables (sources #1-#4b) feed into a star schema built
2026-10-11: `dim_area`, `dim_school`, `dim_year`, `dim_year_level`,
`dim_ethnicity`, `fact_roll`, `school_status_history`. Build script:
`sql/star_schema.sql`. Grain decision for `fact_roll`, two real bugs hit
during the build, and final row counts are documented in
`METHODOLOGY.md` under "Star schema build (2026-10-11)".
