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

## `BULK INSERT` on the year-level/ethnicity CSV (source #2): three failures, one file

Loading `10-Machine Readable-Roll by Funding year level ethnicity 2014-2025.csv`
(709,153 rows) into `staging_roll_by_year_level` failed three times in a row,
each fix exposing the next cause. Recorded here so the debugging isn't repeated.

1. `Msg 7301, State 6` ("Cannot obtain the required interface IID_IColumnsInfo")
   with `FORMAT='CSV'` + `FIELDQUOTE='"'` + `ROWTERMINATOR='\r\n'`.
   Compatibility level (170) checked and ruled out as the cause.
   Fix tried: `ROWTERMINATOR = '\n'`.
2. Error persisted but changed to `State 2` — a different state means a
   different underlying cause, not a lingering instance of the first one.
   Ruled out an instance-level bug (SQL Server 2025 RTM, build
   17.0.1000.7) by loading a 1,000-row sample successfully. Ruled out file
   corruption via two independent checks: a PowerShell strict UTF-8
   validity pass (709,154 lines, zero invalid bytes) and a strict CSV
   parse via `Import-Csv` (709,153 rows, zero parse errors).
3. Real cause: no `BATCHSIZE`. Without it, `BULK INSERT` treats the whole
   file as one single transaction, and the instance couldn't sustain that
   as one unit at 709k rows. Fix: `BATCHSIZE = 50000`.

Load succeeded with all three fixes combined: 709,153 rows landed in
`staging_roll_by_year_level`.

**Open verification, not yet done:** the file's actual line ending is
`\r\n` (confirmed by inspecting the raw bytes directly — not assumed),
but the working load uses `ROWTERMINATOR = '\n'` only. That means each
row's real terminator is being split as `\r` (kept as data) + `\n`
(consumed as the terminator) — the trailing `\r` may be landing at the
end of the last column (`equi_group`) of every row. Before trusting this
table for anything downstream, check for a trailing `\r` in the last
column, e.g. compare `LEN(equi_group)` / `ASCII(RIGHT(equi_group, 1))`
against what's expected (ASCII 13 = `\r` would confirm it). Not yet run —
next session's first step.

## `directory.csv` byte-level checks (confirmed via `Format-Hex`, not assumed)

- Starts with a UTF-8 BOM (`EF BB BF`) — visible as the mojibake `ï»¿` if
  the file is read with a non-UTF-8-aware tool/codepage. Different from
  source #2's CSV, which has no BOM (see the BULK INSERT section above).
- Line ending is `\r\n` (confirmed: `0D 0A` immediately after the last
  populated cell, e.g. offset `0x4E`-`0x4F`), same convention as source #2.

## Trailing `\r` check on `equi_group` — resolved, no bug

Checked with `SELECT TOP (20) equi_group, LEN(equi_group), ASCII(RIGHT(equi_group, 1)) FROM staging_roll_by_year_level`,
once with no filter (returned clean `NULL` for all three columns — no
phantom character on an empty field) and once with `WHERE equi_group IS
NOT NULL` (returned e.g. `'More'`, `LEN = 4`, `ASCII(last char) = 101` —
matches "More" exactly, no extra byte). Despite `BULK INSERT` using
`ROWTERMINATOR = '\n'` against a file whose real line ending is `\r\n`,
no stray `\r` landed in the last column. The open item from the BULK
INSERT section above is closed — the load is clean on this front.

## `equi_band`/`equi_group` null pattern by year — corrects the 2023 assumption in PLAN.md

Checked with:

```sql
SELECT year_as_at_1_july,
       COUNT(*) AS total_count,
       COUNT(equi_band) AS equi_band,
       COUNT(equi_group) AS equi_group
FROM staging_roll_by_year_level
GROUP BY year_as_at_1_july
ORDER BY year_as_at_1_july;
```

Result: `equi_band`/`equi_group` are `0` (fully NULL) for 2016, 2017 and
2018, and exactly equal to `total_count` (fully populated) for every
year from 2019 through 2025. The boundary is 2019, not 2023.

PLAN.md's trap #1 said decile stopped being used for reporting after
2022, replaced by the Equity Index — that's still correct, and confirmed
against the source (Education Counts, "School Equity Index Bands and
Groups" guideline page: "Equity Index Bands and Groups will be
introduced for socioeconomic reporting on schools for data from 2023 and
beyond"). But the same source also says: "to allow comparison, the
Ministry uses the Equity Index for 2023 funding with education data from
2019-2022" — the Ministry calculated it retroactively back to 2019, four
years before it became the official measure. 2023 is when EQI became
official; 2019 is when this column actually starts being populated in
the data. Both facts are true, they just answer different questions.

**Corrected boundary for this table:** NULL for 2016-2018, populated for
2019-2025.

Source: https://www.educationcounts.govt.nz/data-services/guidelines/school-equity-index-bands-and-groups

## `definition` — sub-classification only assigned to specific school types (source #3)

**Query:**

    SELECT school_type, COUNT(*) AS total_count, COUNT(definition) AS definition
    FROM staging_directory
    GROUP BY school_type
    ORDER BY school_type;

**Result:** 40 of 2578 rows have a non-null `definition`, concentrated almost
entirely in `school_type = 'Specialist School'` (36 of 38), with a handful of
isolated cases under `Secondary (Year 7-15)` (1 of 118) and
`Secondary (Year 9-15)` (3 of 236) — all 4 tagged "Secondary Māori Boarding
School".

**The 2 Specialist School exceptions:**

    SELECT school_type, definition, school_name, status
    FROM staging_directory
    WHERE school_type = 'Specialist School' AND definition IS NULL;

Both rows are schools with `status = 'Proposed'` and a future opening date
(Te Ohanui / Palmerston North Specialist School, 2027-07-19; Drury
Specialist School, 2028-02-08) — not yet operating, so the Ministry hasn't
assigned them a sub-classification yet.

## `takiwa` — fully NULL across all rows (source #3)

Same pattern as `student_age` in source #2: 0 of 2578 rows have a value.
Not a load error — confirmed against the raw CSV. Excluded from analysis.
