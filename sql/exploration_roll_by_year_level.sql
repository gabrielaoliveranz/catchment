-- Exploration: Roll by funding year level & ethnicity (source #2)
-- Author: Gabriela Olivera | CATCHMENT
-- DB: Catchment (SQL Server, localhost\gabyg)
-- Purpose: scratch queries to inspect staging_roll_by_year_level after
--          the load. Not meant to run top-to-bottom as a build step, --          see sql/staging_roll_by_year_level.sql for that.

-- Quick look at the first 100 rows loaded, to sanity-check that columns
-- line up with the CSV header and the order makes sense.
-- NOTE: no ORDER BY, so this is physical/insertion order, not a
-- representative sample across years (see METHODOLOGY.md).

USE Catchment

SELECT TOP (100) *
FROM staging_roll_by_year_level;

-- Check: trailing \r on equi_group (BULK INSERT used ROWTERMINATOR = '\n'
-- but the file's real line ending is \r\n).
-- Resolved: no stray \r found, see METHODOLOGY.md.

SELECT TOP (20) equi_group, LEN(equi_group), ASCII(RIGHT(equi_group, 1))
FROM staging_roll_by_year_level;


SELECT TOP (20) equi_group, LEN(equi_group), ASCII(RIGHT(equi_group, 1))
FROM staging_roll_by_year_level
WHERE equi_group IS NOT NULL;

-- Check: is equi_band/equi_group null only for years before 2023?
-- Resolved: NULL 2016-2018, populated 2019-2025, see METHODOLOGY.md.

SELECT  year_as_at_1_july, COUNT(*)AS total_count, COUNT (equi_band) AS equi_band, COUNT (equi_group) AS equi_group
FROM staging_roll_by_year_level
GROUP BY year_as_at_1_july
ORDER BY year_as_at_1_july;


-- Check: is student_age null across the WHOLE table (all 709,153 rows),
-- not just this 100-row sample?
-- Resolved: yes, NULL in all 709,153 rows, 100% of the table.

SELECT COUNT (*) total_count, COUNT (student_age) AS student_age
FROM staging_roll_by_year_level;


-- Check: duplicate rows for school + year + year level + ethnicity?
-- Resolved: no duplicates, see METHODOLOGY.md.

SELECT 
 (SELECT COUNT(*) FROM staging_roll_by_year_level) AS total_count,
 COUNT (*) AS unique_combinations
FROM (
    SELECT DISTINCT school_id, year_as_at_1_july, student_year_level, student_ethnic_group
    FROM staging_roll_by_year_level
) AS combos;

-- Column list + declared type/length from the system catalog, used to
-- plan the truncation and macron checks below.

SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'staging_roll_by_year_level'
ORDER BY ORDINAL_POSITION;

-- Check: any value truncated by NVARCHAR(255)? (MAX(LEN(col)) near 255
-- would be suspicious.)
-- Resolved: no risk, longest value is school_name at 60 chars.
-- (Built with SSMS Find & Replace + regex instead of typing 23 lines
-- by hand: ^(.+)$ → MAX(LEN($1)) AS $1,)

SELECT 

MAX(LEN(students_values
)) AS students_values
,MAX(LEN(year_as_at_1_july
)) AS year_as_at_1_july
,MAX(LEN(student_year_level
)) AS student_year_level
,MAX(LEN(student_year_level_group
)) AS student_year_level_group
,MAX(LEN(school_id
)) AS school_id
,MAX(LEN(student_ethnic_group
)) AS student_ethnic_group
,MAX(LEN(student_age
)) AS student_age
,MAX(LEN(school_name
)) AS school_name
,MAX(LEN(school_sector
)) AS school_sector
,MAX(LEN(school_type
)) AS school_type
,MAX(LEN(school_authority
)) AS school_authority
,MAX(LEN(school_gender
)) AS school_gender
,MAX(LEN(school_affiliation_type
)) AS school_affiliation_type
,MAX(LEN(school_affiliation
)) AS school_affiliation
,MAX(LEN(school_maori_medium_peak_body_affiliation
)) AS school_maori_medium_peak_body_affiliation
,MAX(LEN(education_region
)) AS education_region
,MAX(LEN(regional_council
)) AS regional_council
,MAX(LEN(territorial_authority
)) AS territorial_authority
,MAX(LEN(moe_local_office
)) AS moe_local_office
,MAX(LEN(te_mahau_rohe
)) AS te_mahau_rohe
,MAX(LEN(takiwa
)) AS takiwa
,MAX(LEN(equi_band
)) AS equi_band
,MAX(LEN(equi_group)) AS equi_group

FROM staging_roll_by_year_level; 



-- Check: did macrons (e.g. "Māori") survive the BULK INSERT intact?
-- Resolved (visual check): "Māori" appears correctly in
-- student_ethnic_group. Stricter byte-level check (UNICODE()) optional.

SELECT DISTINCT student_ethnic_group
FROM staging_roll_by_year_level; 


-- Check: does the macron in "Māori" hold the correct Unicode code point
-- (257 = "ā") across every matching row, not just visually?
-- Resolved: single group, 257, across all 166,987 matching rows, no
-- corrupted rows mixed in.

SELECT 
 COUNT(*) AS total_count, 
 UNICODE(SUBSTRING(student_ethnic_group, 2, 1)) AS unicode_check
FROM staging_roll_by_year_level
WHERE student_ethnic_group LIKE 'M_ori'
GROUP BY UNICODE(SUBSTRING(student_ethnic_group, 2, 1));

