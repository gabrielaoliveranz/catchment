# Data model — CATCHMENT

The star schema below is derived from the analysis questions, not the
other way around. Kimball's four-step process: business process → grain
→ dimensions → facts. Deriving dimensions first, from the source files
alone, is guessing.

## Master question

Where in Bay of Plenty–Waiariki is school network capacity under
pressure, and where is there room to spare?

## Analysis questions

From the plan's SQL section, plus ethnicity questions added once a real
use for them was found (not added speculatively):

1. Year-over-year roll variation per school.
2. Cohort progression (e.g. Year 5 in year N vs Year 6 in year N+1) —
   retention and attrition.
3. Ranking of schools within each Territorial Authority by growth.
4. 3-year moving average of roll, to smooth annual noise.
5. Each school's share of its TA's total roll.
6. Capacity pressure signal (proxy): current roll vs. that school's own
   historical maximum.
7. Ethnic composition of a school's roll, by year.
8. **(proxy)** Ethnic composition of Year 13 (final secondary year) by
   school and year — a proxy for "who reaches the end of the schooling
   pathway", not a real graduation rate. This dataset has no completion,
   pass, or leaver-destination data.
9. Cohort retention/attrition (question 2), broken down by ethnicity —
   is attrition higher for some ethnicities, particularly at the
   transition into secondary school?

## Grain

Questions 1–9 all need a value per school **per year**; questions 2 and
9 additionally need **year level** (to track a cohort moving up); 7–9
need **ethnicity**. The finest grain any question needs is:

**one row = one school × one year × one year level × one ethnicity**

This matches the natural grain of source #2
(`10-Machine Readable-Roll by Funding year level ethnicity 2014-2025.csv`),
so no information is thrown away by loading at this grain.

## Why ethnicity stays in the grain even though only 3 of 9 questions use it

Collapsing ethnicity out at load time (summing it away) is a one-way
door — the raw source would need to be reprocessed from scratch to get
it back. Keeping it costs one extra dimension and a `GROUP BY`/`SUM()`
when a query doesn't care about it. Cheap to keep, expensive to lose.

(Which ethnicity basis — total response vs. prioritised — is used, and
why, is a separate decision: see `METHODOLOGY.md`.)

## Dimensions

- `dim_school` — school_id, name, name_ascii, type, sector, authority,
  ta, education_region, lat, lon, eqi, decile. Only attributes actually
  used by questions 1–9 or needed to label results for a reader.
  Contact details (email, phone, principal, address) are in the source
  but answer no question here, so they're excluded.
- `dim_year` — year, is_decile_era, is_eqi_era (decile → Equity Index
  changed mid-series in 2023; see `METHODOLOGY.md`).
- `dim_year_level` — funding_year_level, sector.
- `dim_ethnicity` — code, label, basis ('total_response' | 'prioritised').

## Facts

- `fact_roll` — headcount, at the grain above.

## Not yet decided

- `dim_area` (ta, education_region, regional_council) from the plan's
  original schema — may be redundant with attributes already on
  `dim_school` once we look at the real cardinality. Revisit once the
  DDL is being written.
