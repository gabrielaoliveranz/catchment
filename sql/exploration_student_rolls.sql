-- Exploration: Student rolls 2010-2025 (source #1)
-- Author: Gabriela Olivera | CATCHMENT
-- DB: Catchment (SQL Server, localhost\gabyg)
-- Purpose: sanity checks, duplicate/candidate-key check, truncation check,
--          and macron integrity check on staging_student_rolls.
--          See docs/METHODOLOGY.md for known file quirks (Decile fully NULL
--          from 2023 onward; pseudo-total rows and footer/citation-text rows
--          already excluded upstream by the source Power Query query).

USE Catchment

-- Check: quick visual sanity check on staging_student_rolls, do the columns
-- line up correctly after the load?

SELECT TOP (50) *
FROM staging_student_rolls;


-- Check: does Decile data stop being populated from 2023 onward, as expected
-- from the source Excel inspection (see METHODOLOGY.md)?
-- Confirmed: Decile is 100% populated 2010-2022, and fully NULL 2023-2025, -- a clean cutoff matching the Ministry's discontinuation of Decile after 2022.

SELECT 
	roll_year, 
	COUNT (*) AS total_rows, 
	COUNT (decile) AS rows_with_decile
FROM staging_student_rolls
GROUP BY roll_year
ORDER BY roll_year;


-- Check: does the combination of school_id + roll_year work as a candidate
-- key (one row per school per year), or are there duplicate rows?
-- Confirmed: empty result set, no school_id/roll_year combination appears
-- more than once, so school_id + roll_year is a clean candidate key.

SELECT
	school_id,
	COUNT (*) AS total_count,
	COUNT (school_id) AS count_school_id,
	COUNT (roll_year) AS count_roll_year
FROM staging_student_rolls
GROUP BY school_id, roll_year
HAVING COUNT(*) > 1
ORDER BY school_id;


-- Check: truncation. All columns are NVARCHAR(255), if any value was longer
-- than that in the source, SQL Server silently cut it to 255 characters.
-- A MAX(LEN(...)) of exactly 255 would be the red flag.

SELECT
    MAX(LEN(school_id))               AS school_id_max_len,
    MAX(LEN(school_name))             AS school_name_max_len,
    MAX(LEN(decile))                  AS decile_max_len,
    MAX(LEN(school_type))             AS school_type_max_len,
    MAX(LEN(authority))               AS authority_max_len,
    MAX(LEN(regional_council))        AS regional_council_max_len,
    MAX(LEN(education_region))        AS education_region_max_len,
    MAX(LEN(ta_auckland_local_board)) AS ta_auckland_local_board_max_len,
    MAX(LEN(total_roll))              AS total_roll_max_len,
    MAX(LEN(roll_year))               AS roll_year_max_len
FROM staging_student_rolls;



-- Check: macron integrity. Does school_name preserve macron vowels (ā, ē, ī,
-- ō, ū) correctly after the UTF-8 load, or did they get mangled/lost?
-- Note: the N prefix on the literal is required, without it, SQL Server
-- converts the string to the database's default non-Unicode code page and
-- the macron is lost before the comparison even runs. The COLLATE override
-- (..._CS_AS, accent-sensitive) is also required, the column's default
-- collation is accent-insensitive, so without it "ā" and "a" match as equal
-- and the query returns almost every row instead of just the real matches.
-- Confirmed: 190 school names contain a genuine macron, correctly preserved.


SELECT school_name
FROM staging_student_rolls
WHERE school_name LIKE N'%ā%' COLLATE Latin1_General_100_CS_AS;