-- Star schema: CATCHMENT data warehouse
-- Author: Gabriela Olivera | CATCHMENT
-- DB: Catchment (SQL Server, localhost\gabyg)
-- Purpose: builds the full star schema (dim_area, dim_school, dim_year,
--          dim_year_level, dim_ethnicity, fact_roll,
--          school_status_history) from the staging tables loaded by
--          sql/staging_directory.sql, sql/staging_roll_by_year_level.sql
--          and the 5 source #4b staging scripts (New, Closures, Mergers,
--          Name Changes, School Type Changes). Run top-to-bottom.
--
-- Grain decision for fact_roll: school + year + year_level + ethnicity,
-- sourced from staging_roll_by_year_level (source #2, 2014-2025 only),
-- aggregated (SUMmed) across student_age, which is not part of the
-- grain. The alternative -- a simpler school+year total grain from
-- source #1, covering the full 2010-2025 range but with no year-level
-- or ethnicity breakdown -- was considered and set aside in favour of
-- this richer grain, since it serves the 6 planned window-function
-- analyses better. This means fact_roll has no data for 2010-2013.
--
USE Catchment;
GO

DROP TABLE IF EXISTS fact_roll;
DROP TABLE IF EXISTS school_status_history;
DROP TABLE IF EXISTS dim_school;
DROP TABLE IF EXISTS dim_area;
DROP TABLE IF EXISTS dim_year;
DROP TABLE IF EXISTS dim_year_level;
DROP TABLE IF EXISTS dim_ethnicity;
GO

-- ---------------------------------------------------------------
-- dim_area: distinct geographic attribute combinations, sourced
-- from staging_directory. One row per unique combo, so multiple
-- schools in the same area share a row (rather than repeating the
-- full address/electorate/SA2 text on every dim_school row).
-- ---------------------------------------------------------------
CREATE TABLE dim_area (
    area_key                INT IDENTITY(1,1) PRIMARY KEY,
    suburb                   NVARCHAR(255),
    town_city                NVARCHAR(255),
    postal_code              NVARCHAR(20),
    territorial_authority    NVARCHAR(255),
    regional_council         NVARCHAR(255),
    local_office             NVARCHAR(255),
    education_region         NVARCHAR(255),
    general_electorate       NVARCHAR(255),
    maori_electorate         NVARCHAR(255),
    neighbourhood_sa2_code   NVARCHAR(50),
    neighbourhood_sa2        NVARCHAR(255),
    ward                     NVARCHAR(255),
    takiwa                   NVARCHAR(255)
);
GO

-- ---------------------------------------------------------------
-- dim_school: one row per school_no, type-1 (current attributes
-- only, no history) from staging_directory. Historical changes
-- -- mergers, closures, name/type changes -- live in
-- school_status_history instead, not here.
--
-- NOTE: donations, kme_peak_body and a few other "directory" text
-- columns are widened to NVARCHAR(500)/(255) rather than a
-- shorter code-sized width. staging_directory.donations in
-- particular holds full sentences (e.g. "Donations should not be
-- requested, unless for a specific purpose..."), not a short code
-- -- a first pass at NVARCHAR(50) silently truncated and aborted
-- the whole INSERT (Msg 2628). Widened everything free-text here
-- generously to avoid the same failure on a column we haven't
-- inspected row-by-row.
-- ---------------------------------------------------------------
CREATE TABLE dim_school (
    school_key               INT IDENTITY(1,1) PRIMARY KEY,
    school_no                NVARCHAR(20) NOT NULL,
    school_name              NVARCHAR(255),
    school_type              NVARCHAR(255),
    authority                NVARCHAR(255),
    definition                NVARCHAR(255),
    gender_of_students        NVARCHAR(100),
    urban_rural               NVARCHAR(100),
    kme_peak_body              NVARCHAR(500),
    donations                 NVARCHAR(500),
    enrolment_scheme          NVARCHAR(255),
    isolation_index           NVARCHAR(100),
    equity_index              NVARCHAR(100),
    language_of_instruction   NVARCHAR(255),
    boarding_facilities       NVARCHAR(100),
    cohort_entry              NVARCHAR(100),
    status                    NVARCHAR(100),
    latitude                  NVARCHAR(50),
    longitude                 NVARCHAR(50),
    area_key                  INT NULL REFERENCES dim_area(area_key)
);
GO

-- dim_year: full 2010-2025 historical range, even though fact_roll
-- only populates 2014-2025 -- kept this wide so school_status_history
-- (which does span 2010-2025) can join to it later if needed.
CREATE TABLE dim_year (
    year_key INT PRIMARY KEY
);
GO

-- dim_year_level: distinct (student_year_level, student_year_level_group)
-- pairs from staging_roll_by_year_level.
CREATE TABLE dim_year_level (
    year_level_key INT IDENTITY(1,1) PRIMARY KEY,
    student_year_level NVARCHAR(50),
    student_year_level_group NVARCHAR(50)
);
GO

-- dim_ethnicity: distinct student_ethnic_group values from
-- staging_roll_by_year_level.
CREATE TABLE dim_ethnicity (
    ethnicity_key INT IDENTITY(1,1) PRIMARY KEY,
    student_ethnic_group NVARCHAR(100)
);
GO

-- fact_roll: grain = school + year + year_level + ethnicity (see
-- header comment for the grain decision and reasoning).
CREATE TABLE fact_roll (
    school_key     INT NOT NULL REFERENCES dim_school(school_key),
    year_key       INT NOT NULL REFERENCES dim_year(year_key),
    year_level_key INT NOT NULL REFERENCES dim_year_level(year_level_key),
    ethnicity_key  INT NOT NULL REFERENCES dim_ethnicity(ethnicity_key),
    students_count INT NOT NULL,
    PRIMARY KEY (school_key, year_key, year_level_key, ethnicity_key)
);
GO

-- school_status_history: union of the 5 source #4b staging tables
-- (New, Closures, Mergers, Name Changes, School Type Changes). Not
-- a conformed dimension in the usual sense -- more a historical
-- event log, one row per change event, kept separate from
-- dim_school (which is type-1 / current-state only).
--
-- NOTE: text columns here are NVARCHAR(255)/(500), wider than you'd
-- expect for what look like short codes (event_year, effective_day,
-- effective_month). Same root cause as the closures footer-text
-- issue already documented for source #4b: boilerplate/junk text
-- ("School contact details available at:", "merged wi...",
-- "Change - a...") leaks into several columns across these 5
-- tables from the sheets' used-range padding. A first pass at
-- realistic short widths truncated and aborted the INSERT (Msg
-- 2628) on 3 of the 5 source tables. Rather than chase down every
-- instance of this junk column by column under time pressure,
-- widened everything and left the junk rows in place raw -- same
-- "filter visibly at the query stage, don't fix silently upstream"
-- convention used for the rest of source #4b's known data-quality
-- issues (exact duplicates, column-shifted legacy rows). Anyone
-- querying this table for real analysis should expect a handful of
-- junk rows and filter on reasonable-looking values.
CREATE TABLE school_status_history (
    history_key     INT IDENTITY(1,1) PRIMARY KEY,
    school_no       NVARCHAR(255),
    school_name     NVARCHAR(255),
    event_type      NVARCHAR(50),
    event_year      NVARCHAR(255),
    effective_day   NVARCHAR(255),
    effective_month NVARCHAR(255),
    effective_year  NVARCHAR(255),
    details         NVARCHAR(500),
    source_table    NVARCHAR(100)
);
GO

-- Indexes on the columns fact_roll's load joins against. Without
-- these, matching staging_roll_by_year_level's ~709k rows against
-- dim_school/dim_year_level/dim_ethnicity on text columns is a full
-- scan per row -- the first attempt at this load, without these
-- indexes, was still running after 2.5 minutes and got cancelled;
-- with them, the same load (over the full dataset) took ~20s.
CREATE UNIQUE INDEX UX_dim_school_school_no ON dim_school(school_no);
CREATE INDEX IX_dim_year_level_lookup ON dim_year_level(student_year_level, student_year_level_group);
CREATE INDEX IX_dim_ethnicity_lookup ON dim_ethnicity(student_ethnic_group);
GO


-- =================================================================
-- Populate dimensions
-- =================================================================

INSERT INTO dim_area (suburb, town_city, postal_code, territorial_authority, regional_council, local_office, education_region, general_electorate, maori_electorate, neighbourhood_sa2_code, neighbourhood_sa2, ward, takiwa)
SELECT DISTINCT suburb, town_city, postal_code, territorial_authority, regional_council, local_office, education_region, general_electorate, maori_electorate, neighbourhood_sa2_code, neighbourhood_sa2, ward, takiwa
FROM staging_directory;
GO

-- Matched back to its dim_area row via the full combo of geographic
-- columns (ISNULL-wrapped so two NULLs compare equal, same pattern
-- used elsewhere in this project for staging duplicate checks).
INSERT INTO dim_school (school_no, school_name, school_type, authority, definition, gender_of_students, urban_rural, kme_peak_body, donations, enrolment_scheme, isolation_index, equity_index, language_of_instruction, boarding_facilities, cohort_entry, status, latitude, longitude, area_key)
SELECT d.school_number, d.school_name, d.school_type, d.authority, d.definition, d.gender_of_students, d.urban_rural, d.kme_peak_body, d.donations, d.enrolment_scheme, d.isolation_index, d.equity_index, d.language_of_instruction, d.boarding_facilities, d.cohort_entry, d.status, d.latitude, d.longitude, a.area_key
FROM staging_directory d
LEFT JOIN dim_area a
  ON  ISNULL(a.suburb,'')                 = ISNULL(d.suburb,'')
  AND ISNULL(a.town_city,'')              = ISNULL(d.town_city,'')
  AND ISNULL(a.postal_code,'')            = ISNULL(d.postal_code,'')
  AND ISNULL(a.territorial_authority,'')  = ISNULL(d.territorial_authority,'')
  AND ISNULL(a.regional_council,'')       = ISNULL(d.regional_council,'')
  AND ISNULL(a.local_office,'')           = ISNULL(d.local_office,'')
  AND ISNULL(a.education_region,'')       = ISNULL(d.education_region,'')
  AND ISNULL(a.general_electorate,'')     = ISNULL(d.general_electorate,'')
  AND ISNULL(a.maori_electorate,'')       = ISNULL(d.maori_electorate,'')
  AND ISNULL(a.neighbourhood_sa2_code,'') = ISNULL(d.neighbourhood_sa2_code,'')
  AND ISNULL(a.neighbourhood_sa2,'')      = ISNULL(d.neighbourhood_sa2,'')
  AND ISNULL(a.ward,'')                   = ISNULL(d.ward,'')
  AND ISNULL(a.takiwa,'')                 = ISNULL(d.takiwa,'')
WHERE d.school_number IS NOT NULL;
GO

INSERT INTO dim_year (year_key)
VALUES (2010),(2011),(2012),(2013),(2014),(2015),(2016),(2017),(2018),(2019),(2020),(2021),(2022),(2023),(2024),(2025);
GO

INSERT INTO dim_year_level (student_year_level, student_year_level_group)
SELECT DISTINCT student_year_level, student_year_level_group
FROM staging_roll_by_year_level
WHERE student_year_level IS NOT NULL;
GO

INSERT INTO dim_ethnicity (student_ethnic_group)
SELECT DISTINCT student_ethnic_group
FROM staging_roll_by_year_level
WHERE student_ethnic_group IS NOT NULL;
GO


-- =================================================================
-- Populate fact_roll
-- =================================================================

INSERT INTO fact_roll (school_key, year_key, year_level_key, ethnicity_key, students_count)
SELECT
    ds.school_key,
    dy.year_key,
    dyl.year_level_key,
    de.ethnicity_key,
    SUM(TRY_CAST(r.students_values AS INT)) AS students_count
FROM staging_roll_by_year_level r
JOIN dim_school ds      ON ds.school_no = r.school_id
JOIN dim_year dy        ON dy.year_key = TRY_CAST(r.year_as_at_1_july AS INT)
JOIN dim_year_level dyl ON dyl.student_year_level = r.student_year_level
                        AND ISNULL(dyl.student_year_level_group,'') = ISNULL(r.student_year_level_group,'')
JOIN dim_ethnicity de   ON de.student_ethnic_group = r.student_ethnic_group
WHERE TRY_CAST(r.students_values AS INT) IS NOT NULL
GROUP BY ds.school_key, dy.year_key, dyl.year_level_key, de.ethnicity_key;
GO


-- =================================================================
-- Populate school_status_history
--
-- Dual header-variant columns (effective_day vs effective_day_2,
-- school_no vs school_no_2 for type changes) are COALESCEd. See
-- docs/METHODOLOGY.md, "Power Query 'Combine Files from a Folder'
-- build for source #4b", for why those variants exist (two
-- different header spellings used across different years' sheets).
-- =================================================================

INSERT INTO school_status_history (school_no, school_name, event_type, event_year, effective_day, effective_month, effective_year, details, source_table)
SELECT school_no, school_name, 'New School', event_year, effective_day, effective_month, effective_year, notes, 'staging_new_schools_2010_2025'
FROM staging_new_schools_2010_2025
WHERE school_no IS NOT NULL;
GO

INSERT INTO school_status_history (school_no, school_name, event_type, event_year, effective_day, effective_month, effective_year, details, source_table)
SELECT school_no, school_name, 'Closure', event_year, effective_day, effective_month, effective_year, COALESCE(reason_for_closure, notes), 'staging_closures_2010_2025'
FROM staging_closures_2010_2025
WHERE school_no IS NOT NULL;
GO

INSERT INTO school_status_history (school_no, school_name, event_type, event_year, effective_day, effective_month, effective_year, details, source_table)
SELECT school_no, school_name, 'Merger', event_year,
    COALESCE(effective_day, effective_day_2),
    COALESCE(effective_month, effective_month_2),
    COALESCE(effective_year, effective_year_2),
    comments, 'staging_mergers_2010_2025'
FROM staging_mergers_2010_2025
WHERE school_no IS NOT NULL;
GO

INSERT INTO school_status_history (school_no, school_name, event_type, event_year, effective_day, effective_month, effective_year, details, source_table)
SELECT school_no, school_name, 'Name Change', event_year, effective_day, effective_month, effective_year, comment, 'staging_name_changes_2010_2025'
FROM staging_name_changes_2010_2025
WHERE school_no IS NOT NULL;
GO

INSERT INTO school_status_history (school_no, school_name, event_type, event_year, effective_day, effective_month, effective_year, details, source_table)
SELECT COALESCE(school_no, school_no_2), COALESCE(school_name, school_name_2), 'Type Change', event_year,
    COALESCE(effective_day, effective_day_2),
    COALESCE(effective_month, effective_month_2),
    COALESCE(effective_year, effective_year_2),
    COALESCE(notes, CONCAT('Previous type: ', previous_type, ' -> New type: ', new_type)),
    'staging_school_type_changes_2010_2025'
FROM staging_school_type_changes_2010_2025
WHERE COALESCE(school_no, school_no_2) IS NOT NULL;
GO


-- =================================================================
-- Sanity check row counts
-- =================================================================
SELECT 'dim_area' t, COUNT(*) c FROM dim_area
UNION ALL SELECT 'dim_school', COUNT(*) FROM dim_school
UNION ALL SELECT 'dim_year', COUNT(*) FROM dim_year
UNION ALL SELECT 'dim_year_level', COUNT(*) FROM dim_year_level
UNION ALL SELECT 'dim_ethnicity', COUNT(*) FROM dim_ethnicity
UNION ALL SELECT 'fact_roll', COUNT(*) FROM fact_roll
UNION ALL SELECT 'school_status_history', COUNT(*) FROM school_status_history;
GO
