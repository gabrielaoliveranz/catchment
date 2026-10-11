# Methodology & limitations, CATCHMENT

Written as the project is built, not after. Each entry below was found
during exploration of the raw files, empirically, never assumed.

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
  not something to hand-edit in the raw file, it will be corrected via
  a versioned lookup table at load time, not by editing `data/raw/`.

## `Total School Roll` blanks in `directory.csv`

66 of 2578 rows have a blank `Total School Roll` (snapshot as at 1 July
2026): 13 are `Proposed` (not yet open, expected). Of the 53 `Open`
schools with a blank roll, 39 are `Activity Centre` (14) or `Teen Parent
Unit` (25), alternative-provision types whose roll is likely counted
under a host school, not a data error. The remaining 14 are ordinary
school types (Composite, Contributing, Full Primary, Secondary) with
names suggesting recently opened institutions (e.g. "Griffin Academy",
which also appears in the Proposed-opening list), most likely opened
too recently to have a roll recorded in this snapshot yet.

Not a blocker: this project's actual roll analysis uses the 16-year
time-series file (`data/raw/2-Student-rolls-by-school-2010-2025-v2.xlsx`),
not this snapshot column.

## `.` vs `0` in the age/year-level breakdown columns

Confirmed empirically (not from a footnote): in
`2-Student-rolls-by-school-2010-2025-v2.xlsx`, secondary-only schools
show `.` across every primary-age column (Age 5–12), while genuine small
counts (1, 2, 3...) do appear as real numbers elsewhere in the same age
breakdown for other schools, e.g. Rotorua Boys' High School Age 21 = 5,
Ambury Park Centre Age 13 = 1. This rules out privacy suppression as the
explanation. `.` means the age/year-level combination does not apply to
that school's type; `0` means it applies and the real count is zero.
When unpivoting these wide columns into `fact_roll` rows, `.` cells are
dropped (no measurement exists), `0` cells are loaded as a real zero.

One exception found: School ID 345 (Pacific Christian School) has `.`
across every single age column, including ones that should apply, not
yet explained, flagged for follow-up, not blocking.

## Source footnotes (from the workbook itself, verbatim)

- "Maori Language Learning Figures exclude Alternative Education
  Students, from 2010 onwards IFP students, and from 2013 onward
  Secondary-Tertiary students.", the definition of who counts toward
  Māori Language Immersion Level figures changed twice within the
  2010–2025 series. Relevant only if this project uses those columns.
- "A small number of single sex schools can have some students of the
  opposite sex on their roll. These students can not access the
  education they need at other schools in the area.", a single-sex
  school is not guaranteed 100% one gender in the `Gender` breakdown;
  this is a known, legitimate exception, not a data error.
- "July roll return student rolls exclude Health camps.", scope note on
  what counts as a school for the roll return.
- "Prior to 2009 Students under a Ministry of Foreign Affairs and Trade
  (MFAT) Scholarship are included with International Fee Paying (IFP)."
 , another mid-series definition change: MFAT scholarship students are
  bundled into IFP before 2009, presumably broken out separately from
  2009 onward. Matters only if this project analyses IFP/MFAT figures
  across the 2009 boundary.

## Two different placeholder symbols in the roll workbook, do not conflate

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

Found: School ID `-1`, School Name "Charter Schools", an aggregate row
(all charter schools summed), not a real individual school. Type,
Authority, Gender etc. are "Not Applicable"; roll figures are real
numbers. A negative ID is the giveaway. **Must be excluded from
`dim_school`/`fact_roll` when loading**, or it corrupts every regional
total. Still checking whether other aggregate rows exist (e.g. a
national total row), do not finalise the load filter until confirmed.

## Confirmed: exactly two aggregate pseudo-rows in the roll workbook

Checked the full sorted list of distinct School ID values (-1 to 99999).
Exactly two are not real schools:

- `-1`, "Charter Schools" (all charter schools summed)
- `99999`, "NZ Total" (national total)

**Load rule:** `WHERE school_id NOT IN (-1, 99999)` when loading
`fact_roll`/`dim_school` from this file. Re-check this list whenever a
new year's data is added, no guarantee the Ministry won't introduce a
third aggregate row (e.g. a regional total) in a future release.

## Ethnicity basis confirmed for the year/ethnicity CSV (source #2)

Verified: School ID 1, year 2025, sum of `Students` by
`Student: Ethnic Group` (excluding the "Total" row) = 83; the file's own
Total row for that school-year = 74. 83 > 74 confirms **total response**
basis (a student can be counted in more than one ethnic group). This
file has only one ethnicity classification, no separate "prioritised"
column exists here, unlike the Excel roll workbook (source #1), which
carries both bases side by side.

## Correction: source #2's actual year coverage

The filename says "2014-2025", the actual data, verified against the
`Year` filter in the file itself, only goes from **2016 to 2025** (10
years), not 2014. Never trust a filename over the data. This widens the
coverage gap with source #1 (the Excel roll workbook, 2010–2025): the
fine-grained grain (school × year × year level × ethnicity) is only
available for 2016–2025, six fewer years than the school-level roll
history.

## Mergers: successor school lives in free text, not a clean column

Confirmed with a real 2013 example (School No 3027 Strathmore Community
School merged with 2917 Miramar South School): both rows in the Mergers
sheet carry the same `Comments = "Closure - Merger"`, nothing
distinguishes the continuing school from the one that closed except the
free-text `Notes` field ("3027 is the continuing school, merged with
2917"). Populating `school_status_history.successor_school_id` will
require parsing this text, not reading a column. The intro sheet also
warns that sometimes the "continuing" school itself gets issued a brand
new School ID for administrative integrity, this example doesn't show
that case, but it's documented as happening. Confirm the Notes wording
is consistent across years before writing a parser, not yet checked
across more than one example.

## Decision: analysis scoped to 2016–2025, not the full 2010–2025

The Excel roll workbook (source #1) covers 2010–2025, but only at
school × year grain, ethnicity is a school-year total, not split by
year level. The year/ethnicity CSV (source #2) has the full grain this
project needs (school × year × year level × ethnicity), but only covers
2016–2025 (verified against the file itself, not the filename, see
above).

Questions 2 and 9 (cohort progression, and retention/attrition by
ethnicity) need year level and ethnicity in the same row. That
combination doesn't exist for 2010–2015 in any source. Rather than
answer some questions on a longer window and others on a shorter one, which would make every chart's date range mean something different
depending on which query produced it, **the whole project is scoped to
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
2. Error persisted but changed to `State 2`, a different state means a
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
`\r\n` (confirmed by inspecting the raw bytes directly, not assumed),
but the working load uses `ROWTERMINATOR = '\n'` only. That means each
row's real terminator is being split as `\r` (kept as data) + `\n`
(consumed as the terminator), the trailing `\r` may be landing at the
end of the last column (`equi_group`) of every row. Before trusting this
table for anything downstream, check for a trailing `\r` in the last
column, e.g. compare `LEN(equi_group)` / `ASCII(RIGHT(equi_group, 1))`
against what's expected (ASCII 13 = `\r` would confirm it). Not yet run, next session's first step.

## `directory.csv` byte-level checks (confirmed via `Format-Hex`, not assumed)

- Starts with a UTF-8 BOM (`EF BB BF`), visible as the mojibake `ï»¿` if
  the file is read with a non-UTF-8-aware tool/codepage. Different from
  source #2's CSV, which has no BOM (see the BULK INSERT section above).
- Line ending is `\r\n` (confirmed: `0D 0A` immediately after the last
  populated cell, e.g. offset `0x4E`-`0x4F`), same convention as source #2.

## Trailing `\r` check on `equi_group`, resolved, no bug

Checked with `SELECT TOP (20) equi_group, LEN(equi_group), ASCII(RIGHT(equi_group, 1)) FROM staging_roll_by_year_level`,
once with no filter (returned clean `NULL` for all three columns, no
phantom character on an empty field) and once with `WHERE equi_group IS
NOT NULL` (returned e.g. `'More'`, `LEN = 4`, `ASCII(last char) = 101`, matches "More" exactly, no extra byte). Despite `BULK INSERT` using
`ROWTERMINATOR = '\n'` against a file whose real line ending is `\r\n`,
no stray `\r` landed in the last column. The open item from the BULK
INSERT section above is closed, the load is clean on this front.

## `equi_band`/`equi_group` null pattern by year, corrects the 2023 assumption in PLAN.md

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
2022, replaced by the Equity Index, that's still correct, and confirmed
against the source (Education Counts, "School Equity Index Bands and
Groups" guideline page: "Equity Index Bands and Groups will be
introduced for socioeconomic reporting on schools for data from 2023 and
beyond"). But the same source also says: "to allow comparison, the
Ministry uses the Equity Index for 2023 funding with education data from
2019-2022", the Ministry calculated it retroactively back to 2019, four
years before it became the official measure. 2023 is when EQI became
official; 2019 is when this column actually starts being populated in
the data. Both facts are true, they just answer different questions.

**Corrected boundary for this table:** NULL for 2016-2018, populated for
2019-2025.

Source: https://www.educationcounts.govt.nz/data-services/guidelines/school-equity-index-bands-and-groups

## `definition`, sub-classification only assigned to specific school types (source #3)

**Query:**

    SELECT school_type, COUNT(*) AS total_count, COUNT(definition) AS definition
    FROM staging_directory
    GROUP BY school_type
    ORDER BY school_type;

**Result:** 40 of 2578 rows have a non-null `definition`, concentrated almost
entirely in `school_type = 'Specialist School'` (36 of 38), with a handful of
isolated cases under `Secondary (Year 7-15)` (1 of 118) and
`Secondary (Year 9-15)` (3 of 236), all 4 tagged "Secondary Māori Boarding
School".

**The 2 Specialist School exceptions:**

    SELECT school_type, definition, school_name, status
    FROM staging_directory
    WHERE school_type = 'Specialist School' AND definition IS NULL;

Both rows are schools with `status = 'Proposed'` and a future opening date
(Te Ohanui / Palmerston North Specialist School, 2027-07-19; Drury
Specialist School, 2028-02-08), not yet operating, so the Ministry hasn't
assigned them a sub-classification yet.

## `takiwa`, fully NULL across all rows (source #3)

Same pattern as `student_age` in source #2: 0 of 2578 rows have a value.
Not a load error, confirmed against the raw CSV. Excluded from analysis.

## `Decile`, discontinued after 2022, fully NULL 2023-2025 (source #1)

**Source:** `data/raw/2-Student-rolls-by-school-2010-2025-v2.xlsx`, "Combined"
sheet (16 yearly sheets stacked into one long table, 40,649 rows: School ID,
School Name, Decile, Type, Authority, Regional Council, Education Region,
TA with Auckland Local Board, Total, Year).

Row count with a non-null `Decile` value, by year:

    2010-2022: 100% of rows have a value
    2023: 0 of 2538
    2024: 0 of 2533
    2025: 0 of 2529

Clean cutoff at 2023, matches "trap #1" in the project plan: decile stopped
being the Ministry's official reporting metric after 2022. Lines up with the
`equi_band`/`equi_group` finding in source #2 (Equity Index populated from
2019 onward): 2019-2022 is a four-year window where the Ministry reported
both metrics in parallel before dropping decile entirely in 2023.

## Load decision: source #1 loaded from the original `Combined` query, not a raw rebuild (source #1)

Source #1 (`2-Student-rolls-by-school-2010-2025-v2.xlsx`) already had a
Power Query `Combined` built for an earlier Excel/Upwork deliverable,
which silently excludes the two pseudo-total rows (School ID -1 and
99999) and drops rows that fail numeric type conversion (footer/citation
text embedded in the per-year sheets, e.g. "Source: Ministry of
Education", landing in what should be a numeric column). That's a
departure from this project's own convention for sources #2 and #3,
where staging = a raw, untyped mirror and every exclusion happens
visibly in SQL.

A from-scratch rebuild in Power Query (duplicating the 16 yearly queries,
retyping 3 columns per query to text, recombining) was attempted to
preserve raw fidelity, but was abandoned after Excel crashed mid-edit and
the work was lost. Given the time cost, the decision was made to load
from the original `Combined` query as-is rather than rebuild.

**Consequence:** for this one source, the pseudo-total and malformed-row
exclusion already happened upstream, in Power Query, not visibly in SQL
like the other sources. Documented here as the deviation; not something
to "fix" later unless the raw-mirror rebuild is revisited.

## `staging_student_rolls` row count reconciliation (source #1)

`Combined` sheet in Excel: last row with data (via Ctrl+Down on column A)
= row 40649; header is row 1, so 40648 data rows. `BULK INSERT` reported
`(40648 rows affected)`, exact match, confirms nothing was lost between
the Excel export and the SQL load.

## `staging_student_rolls` verification checklist (source #1)

- **Candidate key:** `school_id + roll_year`. Checked with
  `GROUP BY school_id, roll_year HAVING COUNT(*) > 1`, empty result set,
  zero duplicates.
- **Truncation:** `MAX(LEN(...))` across every column, max found = 60
  characters, far under the `NVARCHAR(255)` ceiling. No truncation.
- **Macron integrity:** 190 rows in `school_name` contain a genuine "a"
  with macron. See the SQL Server gotcha below, the first two attempts
  at this check silently returned the whole table instead of a real
  filter.

## SQL Server gotcha: Unicode literals and accent-sensitive comparison (source #1)

Checking for macrons with `WHERE school_name LIKE '%a-macron%'` returned
every row in the table, looked like the filter wasn't working at all.
Two separate causes, both had to be fixed:

1. **Missing `N` prefix.** A string literal without `N` is non-Unicode;
   SQL Server silently converts it to the database's default code page
   before comparing, which can't represent the macron and loses/mangles
   it. Fix: prefix the literal with `N`, e.g. `N'%a-macron%'`.
2. **Accent-insensitive collation.** Even with the `N` prefix, the
   column's default collation treats a macron vowel and its plain
   equivalent as equal for comparison purposes, so the pattern matched
   almost every row (nearly all of them contain a plain vowel). Fix:
   override the collation for just this comparison with
   `COLLATE Latin1_General_100_CS_AS` (accent-sensitive).

Only one macron vowel needs checking, the mechanism (UTF-8 load + `N`
prefix + accent-sensitive collation) is the same regardless of which
vowel is searched for, nothing vowel-specific about it.

## `Decile` null pattern reconfirmed directly against `staging_student_rolls` (source #1)

Same cutoff reconfirmed from the loaded table itself, not just the raw
Excel inspection above:

    SELECT roll_year, COUNT(*) AS total_rows, COUNT(decile) AS rows_with_decile
    FROM staging_student_rolls
    GROUP BY roll_year
    ORDER BY roll_year;

2010-2022: 100% populated every year (e.g. 2577/2577 in 2010). 2023-2025:
0/2538, 0/2533, 0/2529. Same clean cutoff, confirmed at the SQL layer.
Per-year row counts here are slightly lower than the raw per-year Excel
sheet counts noted above (e.g. 2577 vs 2587 for 2010), expected, since
`Combined` already excludes the pseudo-total and malformed rows (see the
load-decision entry above).

## Source #4a structure: 7 sheets, only 5 usable (source #4a)

`School-closures-mergers-and-new-March-2026.xlsx` has 7 sheets, not the 3-4
expected from the plan. Inspected with openpyxl before building anything:

- **Introduction**: cover/instructions page, not data. Not loaded.
- **New**: new schools. Loaded.
- **Closures**: school closures. Loaded.
- **Mergers**: **zero data rows this period.** Just the header and a
  boilerplate "School contact details available at: New Zealand Schools |
  Education Counts" note, plus an unrelated Excel data-validation dropdown
  list further down the sheet (not real data either). Not a load error,   there were genuinely no mergers in this snapshot window. Real merger
  history is expected from source #4b (2004-2025 historical).
- **Name Changes**: loaded. See header mismatch below.
- **School Type Changes**: loaded, headers match the data correctly.
- **Definition-Authority Changes**: loaded, headers match the data
  correctly.

## `Name Changes` sheet: header labels don't match the actual columns (source #4a)

The source header reads: School No, New School Name, **City or Region**,
**School Type**, School Authority, Effective From, Previous Name.

The actual values don't follow that order, confirmed against multiple
rows (e.g. School No 145, "Rangitaiki College"): the column labelled
"City or Region" actually holds a school type value ("Secondary (Year
9-15)"), the column labelled "School Type" actually holds an authority
value ("State"), and the real region ("Bay of Plenty/Waiariki") sits one
column further right than its own label. Verified against several rows,
not a one-off typo in a single row.

**Staging table columns are named for what the data really is**, not what
the mislabeled source header says, see `staging_name_changes` definition
for the exact mapping.

## `BULK INSERT` on source #4a CSVs: `FORMAT='CSV'` + `FIELDQUOTE` triggers `IID_IColumnsInfo` (source #4a)

Loading the 5 small CSVs exported from source #4a's sheets (11-69 rows
each) with the same `WITH` options that worked for sources #1-#3
(`FORMAT = 'CSV'`, `FIELDQUOTE = '"'`, `ROWTERMINATOR = '\n'`,
`BATCHSIZE = 50000`) failed on all 5 with:

    Msg 7301, Level 16, State 2
    Cannot obtain the required interface ("IID_IColumnsInfo") from OLE DB
    provider "BULK" for linked server "(null)".

Ruled out: file lock (closed Excel fully, confirmed no `~$` lock files in
`data/raw/`), and CSV encoding (re-exported with "CSV UTF-8" instead of
plain "CSV"). Neither fixed it.

**Fix:** drop `FORMAT = 'CSV'` and `FIELDQUOTE = '"'` entirely and use the
classic `BULK INSERT` syntax instead:

    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '\n',
        CODEPAGE = '65001',
        TABLOCK
    );

Known provider bug with `FORMAT = 'CSV'` on small/simple CSV files. Safe
to drop `FIELDQUOTE` here because none of these 5 sheets have commas
embedded inside a field value, would need to be reconsidered for a file
that does.

## Excel "used range" padding rows loaded as blank rows (source #4a)

After fixing the `BULK INSERT` above, all 5 tables loaded far more rows
than expected (117, 90, 124, 109, and 65,513, the last one almost
identical to the phantom `max_row = 65514` openpyxl reported for
"Definition-Authority Changes" during the initial structure inspection
above). Cause: several sheets in this workbook have an Excel "used range"
that extends thousands of rows past the real data (formatting applied
far beyond the visible table, a common Excel artifact). Exporting to CSV
wrote every one of those phantom rows as a blank line, and `BULK INSERT`
loaded them as real, mostly-NULL rows.

**Fix:** not a business-logic exclusion like the pseudo-total rows in
source #1, this is Excel export noise, not source content, so removing
it belongs in staging, not a later query:

    DELETE FROM staging_new_schools WHERE school_no IS NULL;
    DELETE FROM staging_closures WHERE school_no IS NULL;
    DELETE FROM staging_name_changes WHERE school_no IS NULL;
    DELETE FROM staging_school_type_changes WHERE school_no IS NULL;
    DELETE FROM staging_definition_authority_changes WHERE school_no IS NULL;

**Correction to the sheet row counts quoted in the structure-inspection
entry above:** those counts (42, 46, 69, 53, 11) were off by one each, the openpyxl script that produced them counted non-empty cells in column
A starting at row 1, which counted the header text ("School No") as a
row. Real data-row counts, confirmed after the cleanup above, are 41, 45,
68, 52 and 10.

## Decision: source 4b (historical mergers/closures/new schools) scoped to 2010-2025, not the full 2004-2025

The 22 yearly workbooks in `data/raw/2004-2025-School-Mergers/` do not share
a consistent structure across the full range. Checked every file's sheet
names (openpyxl for `.xlsx`, xlrd for the older `.xls` files):

- **2004-2007** (`.xls`): 4 sheets, "Read Me First"/"Read this first",
  Mergers, Closures, **New Schools** (named differently than later years'
  "New"). No Name Changes, School Type Changes, or Definition-Authority
  Changes sheets at all.
- **2008**: an outlier, only 2 sheets, "Read Me First" and a single
  combined **"All changes"** sheet (not split by event type like every
  other year).
- **2009**: transitional, Introduction, New, Closures, Mergers (4 sheets,
  still missing the 3 "changes" sheets).
- **2010-2025**: stable 7-sheet structure (Introduction, New, Closures,
  Mergers, Name Changes, School Type Changes, Definition-Authority
  Changes), identical to source #4a's single-snapshot workbook, and
  directly combinable across years. (2011-2013 also carry a stray empty
  "Sheet1", ignored.)

**Decision:** load only **2010-2025** (16 years) into
staging, same structure as source #4a, enabling a clean, homogeneous
year-over-year comparison. 2004-2009 are documented here as a known gap,
not loaded, would need separate, year-specific handling (3 different
schemas across just 6 years) that isn't worth the time cost right now.
Same reasoning as the earlier decision to scope the year/ethnicity
analysis to 2016-2025 instead of the full available range: consistent
structure across every year analysed beats a few extra years that would
need special-case treatment.

## Power Query "Combine Files from a Folder" build for source #4b (2010-2025)

Built one query per sheet type in `data/raw/4b-combine-workbook.xlsx`,
combining the 16 yearly workbooks (2010-2025) filtered via `Folder.Files`.
Pattern per query: `Source` (folder listing) -> `Filtered Rows` (excludes
the 6 pre-2010 filenames) -> `Added Custom` (adds a column pulling the
target sheet via `Excel.Workbook([Content], true){[Name="<SheetName>"]}[Data]`)
-> expand -> remove 100%-empty columns -> remove file-metadata columns
(Content, Extension, Date accessed/modified/created, Attributes, Folder
Path) -> add a `Year` column via `Text.Start([Name], 4)`.

### Bug: `.xls` files' `Excel.Workbook` Item/Kind matching fails

Filtering the nested sheet table with `{[Item="New", Kind="Sheet"]}`
raised `Expression.Error: The key didn't match any rows in the table` for
the 4 `.xls` (2010-2013) files only. The sheet genuinely exists (confirmed
independently with Python/xlrd), `.xls` files' `Excel.Workbook` output
also lists internal named ranges (`Name$FilterDatabase`,
`Name$Print_Area`) alongside the real sheets, which confuses the
`Item`+`Kind` match. **Fix:** filter on `{[Name="New"]}` only (drop the
`Kind="Sheet"` constraint), works uniformly across `.xls` and `.xlsx`.

### Bug: double header promotion

`Excel.Workbook([Content], true)`'s second argument already promotes
headers. Wrapping the result in an additional `Table.PromoteHeaders(...)`
call (following earlier, now-corrected guidance) consumed the real header
row a second time and promoted a real data row instead, surfaced as data
values ("628", "TKKM o Tia te Matangi") appearing as column names in the
Expand dialog. **Fix:** never add `Table.PromoteHeaders` on top of
`Excel.Workbook(..., true)`; use the plain
`Excel.Workbook([Content], true){[Name="<Sheet>"]}[Data]` formula.

### Bug: single-row drill-down instead of a full expand (Name Changes)

While rebuilding the Name Changes query, a click landed directly on a
"Table" value inside one data row instead of the column header's expand
icon. This produced `#"Closures Data" = #"Removed Columns"{0}[Closures Data]`, `{0}` indexes a single row, so every step after it only ever saw the
first file's (2010) data, silently dropping 2011-2025. Caught before
loading to SQL by checking the Applied Steps formula bar. **Fix:** always
expand via the column header's ⇄ icon (`Table.ExpandTableColumn`), never
by clicking into an individual cell's nested table value.

### Bug: Closures/School Type Changes/Definition-Authority Changes carry hundreds of phantom "F" and "Column" fields

Same "used range" artifact as source #4a, amplified by combining 16 files.
Closures alone showed 248 generic F-columns in the Expand dialog (only F11
and F13 ever had real data). **Fix:** a dynamic cleanup step added after
expand, independent of the exact phantom-column count:

    Table.SelectColumns(
        <PrevStep>,
        List.Select(
            Table.ColumnNames(<PrevStep>),
            each List.NonNullCount(Table.Column(<PrevStep>, _)) > 0
        )
    )

### Finding: some sheets carry two header variants for the same conceptual column

Mergers, Name Changes, and School Type Changes each expanded to show
**both** an underscore-spaced header ("Effective _Day") **and** a version
with a literal line break in the header text ("Effective \nDay") as two
separate columns, different years used different header formatting for
the same field, so Power Query's combine treated them as distinct columns
instead of merging them. School Type Changes additionally carries a
**second, entirely different column-naming scheme** for several years, "School No.", "SchoolName", "NewType", "Region", "EffectiveFromDate",
"PreviousType" (camelCase/no-space style) alongside the normal
"School No" / "School Name" / "School Type" style columns.

**Decision:** loaded both variants as separate columns in staging (raw,
untouched, per the staging convention) rather than reconciling in Power
Query. Reconciliation (coalescing the two variants into one logical
column) is deferred to the exploration/star-schema stage, where it
belongs as a visible business-logic decision rather than a silent Power
Query transformation.

### Row counts after load (`DELETE ... WHERE school_no IS NULL`, or
`school_no IS NULL AND school_no_2 IS NULL` for School Type Changes, which
has the dual-schema issue above)

| Table | Loaded | Deleted (padding) | Real rows | ~/year (16 yrs) |
|---|---|---|---|---|
| `staging_new_schools_2010_2025` | 1,691 | 1,281 | 410 | ~26 |
| `staging_closures_2010_2025` | 1,525 | 719 | 806 | ~50 |
| `staging_mergers_2010_2025` | 1,536 | 953 | 583 | ~36 |
| `staging_name_changes_2010_2025` | 1,817 | 901 | 916 | ~57 |
| `staging_school_type_changes_2010_2025` | 1,582 | 900 | 682 | ~43 |

All 5 counts are plausible relative to each other (closures > mergers >
new schools; name/type changes more frequent administrative events than
structural ones).

### Lesson: save the .xlsx workbook, not just the CSV export

After finishing the "New" query, only the CSV was exported, the
underlying `.xlsx` workbook (with all the Power Query steps) was never
saved. Closing Excel lost every built step (filter, custom column, expand,
Year column), though the already-exported "New" data itself was safe in
SQL. **Fix going forward:** save `4b-combine-workbook.xlsx` explicitly
(Close & Load first, then File > Save) after finishing each sheet-type
query, in addition to the CSV export, so the Power Query steps survive
across sessions.

## Decision: Definition-Authority Changes (source #4b) not loaded

Combining this sheet across all 16 years (2010-2025) hit the same "used
range" padding problem as the other 4b sheets, but far more severely, row counts climbed past 30 million during the Removed Empty Columns step
(vs. low thousands for New/Closures/Mergers/Name Changes/School Type
Changes), consistent with the extreme phantom `max_row = 65,514` already
found for this exact sheet in source #4a's single-snapshot inspection.
Reordering the cleanup (filter padding rows out by a single key column
before the expensive per-column empty-check) would likely fix the
performance problem, but the data itself is not needed: of the 6 sheet
types in this source, only New/Closures/Mergers feed `school_status_history`
(the core merger/closure/opening tracking table), and Name Changes/School
Type Changes add historical context already captured. Definition-Authority
Changes is an administrative reclassification log with no planned use in
any of the 6 window-function analyses. **Decision:** scoped out, same as
the national roll-projections source (#5, "context only, not loaded")
and the pre-2010 years of this same source. Not loaded; no staging table
created.

## Duplicate-key check on source #4b staging tables (school_no + event_year)

Ran a `GROUP BY school_no, event_year HAVING COUNT(*) > 1` check across all
5 loaded tables. Found three distinct, unrelated issues, none of them a
Power Query or load bug:

**1. Footer text leaking into `school_no` (staging_closures_2010_2025).**
14 rows had `school_no = 'School contact details available at:'`, a
boilerplate note sitting inside the sheet's used range, picked up as a
row with every other column NULL. Not caught by the earlier
`WHERE school_no IS NULL` cleanup because this value isn't NULL, it's a
literal string. **Fixed:**

    DELETE FROM staging_closures_2010_2025
    WHERE school_no = 'School contact details available at:';

(14 rows removed.)

**2. Genuine exact-duplicate rows within a single source file**: e.g.
`school_no 600` and `1167` in `staging_school_type_changes_2010_2025`,
2010, each appear twice with byte-for-byte identical data (same
`source_file`, same every column). Confirmed not a combine artifact (the
2010 workbook appears exactly once in `Folder.Files`). Most likely the
source spreadsheet itself has the row entered twice. **Not fixed in
staging** (staging stays a raw mirror); flagged here for exclusion with
`SELECT DISTINCT` or a dedup step at the exploration/star-schema stage.

**3. Column-shifted "legacy" rows in `name_changes` and
`school_type_changes`.** For several `school_no` values (1, 13, 15, 16
seen so far), alongside one normal/clean row there's a second row where
the real values are shifted into the wrong staging columns, e.g. one row
has `school_name = 'January'`, `city_or_region = '2008'`,
`column11 = 'January'`, `column13 = '2006'`. This pattern repeats
identically in both `name_changes` and `school_type_changes`, and the
same malformed row for `school_no = 1` appears in both the 2020 and 2021
yearly workbooks, consistent with a data-entry error in the original
Ministry spreadsheet that got carried forward from year to year rather
than something introduced by this ETL. **Not fixed in staging** (raw
mirror convention); flagged here as a known source data-quality issue to
filter out at the exploration/star-schema stage, likely detectable by a
rule such as "school_name looks like a month name" or by diffing against
the clean row with the same `school_no`.

**Decision:** none of these 3 issues block moving on, #1 is cleaned up
in staging, #2 and #3 are documented and deferred to the exploration
stage (same convention as the pseudo-total exclusion in source #1: raw
in staging, visible exclusion logic later in SQL).

## Star schema build (2026-10-11)

With all staging tables loaded (source #1 school rolls, source #2 roll
by year level/ethnicity, source #3 directory, source #4b historical
school changes), built the full star schema: `dim_area`, `dim_school`,
`dim_year`, `dim_year_level`, `dim_ethnicity`, `fact_roll`,
`school_status_history`. Full DDL + population script:
`sql/star_schema.sql`.

**`fact_roll` grain decision.** Two options were on the table: a simple
`school + year` total-roll grain from source #1 (covers the full
2010-2025 range, no breakdown) vs. a `school + year + year_level +
ethnicity` grain from source #2's `staging_roll_by_year_level` (only
covers 2014-2025, but supports the planned year-level and ethnicity
trend analyses much better). Went with the richer grain, `fact_roll`
is 2014-2025 only, with no data for 2010-2013. `student_age`, present
in the source but not part of the chosen grain, is summed away via
`GROUP BY` + `SUM(students_values)`.

**`dim_school` is type-1 (current attributes only), not type-2.**
Historical changes, mergers, closures, name/type changes, are not
tracked as slowly-changing dimension history on `dim_school` itself;
they live separately in `school_status_history`, built as a straight
union of the 5 source #4b staging tables (New, Closures, Mergers, Name
Changes, School Type Changes). The dual header-variant columns already
documented above (`effective_day` vs `effective_day_2`, `school_no` vs
`school_no_2` for type changes) are resolved with `COALESCE` at this
stage.

**Two real bugs hit while building this (not the usual Power Query
performance traps, actual data-truncation failures):**

1. **`dim_school.donations` truncation.** First pass defined
   `donations NVARCHAR(50)`, assuming it held a short code.
   `staging_directory.donations` actually holds full sentences (e.g.
   *"Donations should not be requested, unless for a specific
   purpose..."*). SQL Server's `Msg 2628` truncation error aborted the
   whole `INSERT INTO dim_school` statement silently (no rows loaded),
   which in turn made the `fact_roll` load's join to `dim_school` match
   nothing, and because that join sat behind an unindexed scan over
   ~709k staging rows, it looked like a hang (2.5 minutes, cancelled)
   rather than an obvious empty-table error. Fixed by widening
   `dim_school`'s free-text columns generously (`NVARCHAR(500)`/`(255)`)
   rather than guessing a "safe" short width per column.
2. **`school_status_history` text-column truncation**, same root cause
   as the closures footer-text issue documented above, but showing up
   in different columns this time (junk text landing in `school_no`,
   `event_year`, `effective_month` across 3 of the 5 source tables).
   Fixed the same way: widened every text column on
   `school_status_history` to `NVARCHAR(255)`/`(500)` and left the junk
   rows in place raw, rather than chasing down each instance, same
   "filter visibly at the query stage" convention used for the other
   source #4b data-quality issues above. Anyone querying this table
   should expect a handful of junk rows.

**Performance note on the `fact_roll` load.** The join from
`staging_roll_by_year_level` (~709k rows) to `dim_school`,
`dim_year_level` and `dim_ethnicity` on text columns needs indexes on
those lookup columns, without `UX_dim_school_school_no`,
`IX_dim_year_level_lookup` and `IX_dim_ethnicity_lookup` (all created in
`star_schema.sql` right after the `CREATE TABLE`s), the load was still
running after 2.5 minutes and had to be cancelled; with the indexes in
place, the same load completed in about 20 seconds.

**Final row counts:**

| Table | Rows |
|---|---|
| `dim_area` | 2,234 |
| `dim_school` | 2,578 |
| `dim_year` | 16 |
| `dim_year_level` | 16 |
| `dim_ethnicity` | 8 |
| `fact_roll` | 703,080 |
| `school_status_history` | 3,383 (410 New, 583 Merger, 916 Name Change, 682 Type Change, 792 Closure) |

## Window-function analyses (2026-10-11)

The 6 analyses required by the project plan (`CATCHMENT_plan_del_proyecto.md`,
section 4) are in `sql/analysis_01_yoy_variation.sql` through
`sql/analysis_06_capacity_pressure.sql`, one file per question, all scoped
to `dim_area.education_region = 'Bay of Plenty, Waiariki'` (7 TAs, 191
schools, confirmed empirically in SSMS, see dim_area for the TA list).

**Key finding: fact_roll's ethnicity breakdown is total response, not
prioritised.** Verified empirically (5-school sample) that
`SUM(fact_roll.students_count)` collapsed across `ethnicity_key`
overcounts the real roll by roughly 2x (e.g. school 1000: 489 vs a true
217 in 2016). This is trampa #2 from the plan, confirmed real. As a
result, analyses 1, 3, 4, 5 and 6, all of which need a plain "total
students per school per year" figure, are built on `staging_student_rolls`
(source #1, the raw MoE rolls table, school+year grain, no ethnicity
split) instead of `fact_roll`. This also extends their coverage back to
2010 instead of fact_roll's 2014 start. Analysis 2 (cohort progression)
is the one exception: it needs a year-level breakdown that only
`fact_roll` has, so it still carries the ~2x inflation on both sides of
the comparison, fine for the retention ratio, not for absolute headcounts
(flagged in the query's own header comment).

Analysis 6 (capacity pressure) is explicitly a proxy signal (current roll
vs a school's own historical max), not a real capacity measurement, trampa #4 in the plan. Label it as a proxy anywhere it surfaces, including
in the Power BI report.

All 6 queries were run end-to-end in SSMS on 2026-10-11 with no errors;
row counts: analysis 1 = 2,939, analysis 2 = 151, analysis 3 = 189,
analysis 4 = 2,939, analysis 5 = 2,939, analysis 6 = 2,939.

