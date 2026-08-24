# Methodology & limitations — CATCHMENT

Written as the project is built, not after. Each entry below was found
during exploration of the raw files, empirically — never assumed.

## Regional scope: Bay of Plenty–Waiariki

Confirmed against `data/raw/directory.csv`, `Education Region` column.

- **Exact value in the source:** `Bay of Plenty, Waiariki`
- **Territorial Authorities under it (7):** Kawerau District, Ōpōtiki
  District, Rotorua District, Taupo District, Tauranga City, Western Bay
  of Plenty District, Whakatane District.

This does **not** match the Bay of Plenty Regional Council boundary.
`Education Region` is a Ministry of Education administrative grouping
("Waiariki") that includes Rotorua and Taupo districts, which most
people would associate with Waikato, not Bay of Plenty. Filtering by
Regional Council instead of Education Region would have silently
dropped Rotorua and Taupo from the whole analysis.

**Decision:** scope this project to `Education Region = 'Bay of Plenty, Waiariki'`,
not to Regional Council.

## Known data quality issues (source, not ours)

- **`directory.csv` has a 16-row metadata preamble** before the real
  header (title, description, footnotes, and the Directory Builder's
  filter selections). Header is at row 17, data starts at row 18. Any
  load script needs to skip these rows explicitly, not assume row 1 is
  the header.
- **Macron usage in `directory.csv` is inconsistent.** Example: `Town /
  City` shows "Opotiki" (no macrons) for every row in that town, when
  the correct spelling is "Ōpōtiki". This is a source data quality issue,
  not something to hand-edit in the raw file — it will be corrected via
  a versioned lookup table at load time, not by editing `data/raw/`.

## `Total School Roll` blanks in `directory.csv`

66 of 2578 rows have a blank `Total School Roll` (snapshot as at 1 July
2026): 13 are `Proposed` (not yet open, expected). Of the 53 `Open`
schools with a blank roll, 39 are `Activity Centre` (14) or `Teen Parent
Unit` (25) — alternative-provision types whose roll is likely counted
under a host school, not a data error. The remaining 14 are ordinary
school types (Composite, Contributing, Full Primary, Secondary) with
names suggesting recently opened institutions (e.g. "Griffin Academy",
which also appears in the Proposed-opening list) — most likely opened
too recently to have a roll recorded in this snapshot yet.

Not a blocker: this project's actual roll analysis uses the 16-year
time-series file (`data/raw/2-Student-rolls-by-school-2010-2025-v2.xlsx`),
not this snapshot column.

## `.` vs `0` in the age/year-level breakdown columns

Confirmed empirically (not from a footnote): in
`2-Student-rolls-by-school-2010-2025-v2.xlsx`, secondary-only schools
show `.` across every primary-age column (Age 5–12), while genuine small
counts (1, 2, 3...) do appear as real numbers elsewhere in the same age
breakdown for other schools — e.g. Rotorua Boys' High School Age 21 = 5,
Ambury Park Centre Age 13 = 1. This rules out privacy suppression as the
explanation. `.` means the age/year-level combination does not apply to
that school's type; `0` means it applies and the real count is zero.
When unpivoting these wide columns into `fact_roll` rows, `.` cells are
dropped (no measurement exists), `0` cells are loaded as a real zero.

One exception found: School ID 345 (Pacific Christian School) has `.`
across every single age column, including ones that should apply — not
yet explained, flagged for follow-up, not blocking.

## Source footnotes (from the workbook itself, verbatim)

- "Maori Language Learning Figures exclude Alternative Education
  Students, from 2010 onwards IFP students, and from 2013 onward
  Secondary-Tertiary students." — the definition of who counts toward
  Māori Language Immersion Level figures changed twice within the
  2010–2025 series. Relevant only if this project uses those columns.
- "A small number of single sex schools can have some students of the
  opposite sex on their roll. These students can not access the
  education they need at other schools in the area." — a single-sex
  school is not guaranteed 100% one gender in the `Gender` breakdown;
  this is a known, legitimate exception, not a data error.
- "July roll return student rolls exclude Health camps." — scope note on
  what counts as a school for the roll return.
- "Prior to 2009 Students under a Ministry of Foreign Affairs and Trade
  (MFAT) Scholarship are included with International Fee Paying (IFP)."
  — another mid-series definition change: MFAT scholarship students are
  bundled into IFP before 2009, presumably broken out separately from
  2009 onward. Matters only if this project analyses IFP/MFAT figures
  across the 2009 boundary.

## Two different placeholder symbols in the roll workbook — do not conflate

- `.` (age/year-level columns): structural non-applicability. See above.
- `(x)` (Gender breakdown, "Another Gender"/"Not Stated" categories):
  genuine privacy suppression, stated explicitly in the source: values
  between 0 and 5 are suppressed, and secondary suppression also hides
  the second-highest value in the row so the true count can't be
  back-calculated by subtracting from the total.

## Known reporting lag: "Another Gender" / "Not Stated" gender categories

Source note (verbatim): counts for these categories will under-represent
reality for several years, because (1) most non-binary responses so far
come from schools whose student management system already supported
recording it, (2) students/whānau may not know their SMS can record it,
and (3) demographic data is typically only updated when a student starts
or changes school. Treat early-year "Another Gender"/"Not Stated" counts
as a floor, not the true count.

## Aggregate pseudo-rows in the roll workbook

Found: School ID `-1`, School Name "Charter Schools" — an aggregate row
(all charter schools summed), not a real individual school. Type,
Authority, Gender etc. are "Not Applicable"; roll figures are real
numbers. A negative ID is the giveaway. **Must be excluded from
`dim_school`/`fact_roll` when loading**, or it corrupts every regional
total. Still checking whether other aggregate rows exist (e.g. a
national total row) — do not finalise the load filter until confirmed.

## Confirmed: exactly two aggregate pseudo-rows in the roll workbook

Checked the full sorted list of distinct School ID values (-1 to 99999).
Exactly two are not real schools:

- `-1` — "Charter Schools" (all charter schools summed)
- `99999` — "NZ Total" (national total)

**Load rule:** `WHERE school_id NOT IN (-1, 99999)` when loading
`fact_roll`/`dim_school` from this file. Re-check this list whenever a
new year's data is added — no guarantee the Ministry won't introduce a
third aggregate row (e.g. a regional total) in a future release.

## Ethnicity basis confirmed for the year/ethnicity CSV (source #2)

Verified: School ID 1, year 2025 — sum of `Students` by
`Student: Ethnic Group` (excluding the "Total" row) = 83; the file's own
Total row for that school-year = 74. 83 > 74 confirms **total response**
basis (a student can be counted in more than one ethnic group). This
file has only one ethnicity classification — no separate "prioritised"
column exists here, unlike the Excel roll workbook (source #1), which
carries both bases side by side.

## Correction: source #2's actual year coverage

The filename says "2014-2025" — the actual data, verified against the
`Year` filter in the file itself, only goes from **2016 to 2025** (10
years), not 2014. Never trust a filename over the data. This widens the
coverage gap with source #1 (the Excel roll workbook, 2010–2025): the
fine-grained grain (school × year × year level × ethnicity) is only
available for 2016–2025, six fewer years than the school-level roll
history.

## Mergers: successor school lives in free text, not a clean column

Confirmed with a real 2013 example (School No 3027 Strathmore Community
School merged with 2917 Miramar South School): both rows in the Mergers
sheet carry the same `Comments = "Closure - Merger"` — nothing
distinguishes the continuing school from the one that closed except the
free-text `Notes` field ("3027 is the continuing school, merged with
2917"). Populating `school_status_history.successor_school_id` will
require parsing this text, not reading a column. The intro sheet also
warns that sometimes the "continuing" school itself gets issued a brand
new School ID for administrative integrity — this example doesn't show
that case, but it's documented as happening. Confirm the Notes wording
is consistent across years before writing a parser — not yet checked
across more than one example.

## Decision: analysis scoped to 2016–2025, not the full 2010–2025

The Excel roll workbook (source #1) covers 2010–2025, but only at
school × year grain — ethnicity is a school-year total, not split by
year level. The year/ethnicity CSV (source #2) has the full grain this
project needs (school × year × year level × ethnicity), but only covers
2016–2025 (verified against the file itself, not the filename — see
above).

Questions 2 and 9 (cohort progression, and retention/attrition by
ethnicity) need year level and ethnicity in the same row. That
combination doesn't exist for 2010–2015 in any source. Rather than
answer some questions on a longer window and others on a shorter one —
which would make every chart's date range mean something different
depending on which query produced it — **the whole project is scoped to
2016–2025**. Consistent grain across every year analysed, for every
question, beats four extra years of data that only some of the nine
questions could actually use.
