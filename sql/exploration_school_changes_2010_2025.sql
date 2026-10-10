-- Exploration: School closures/mergers/new schools, historical 2010-2025 (source #4b)
-- Author: Gabriela Olivera | CATCHMENT
-- DB: Catchment (SQL Server, localhost\gabyg)
-- Purpose: scratch queries to verify the 5 staging tables loaded from
--          source #4b (New, Closures, Mergers, Name Changes, School Type
--          Changes) after the Power Query combine + BULK INSERT. Not
--          meant to run top-to-bottom as a build step — see
--          sql/staging_new_schools_2010_2025.sql, staging_closures_2010_2025.sql,
--          staging_mergers_2010_2025.sql, staging_name_changes_2010_2025.sql
--          and staging_school_type_changes_2010_2025.sql for that.

-- Duplicate check on the candidate key (school_no + event_year) across
-- all 5 tables at once. Empty result = no duplicates found.
-- NOTE: run AFTER the staging scripts' DELETE cleanups (including the
-- footer-text delete added to staging_closures_2010_2025.sql), otherwise
-- the junk "School contact details available at:" rows will show up here
-- too.
SELECT 'new_schools' AS tabla, school_no, event_year, COUNT(*) AS total
FROM staging_new_schools_2010_2025
GROUP BY school_no, event_year
HAVING COUNT(*) > 1

UNION ALL

SELECT 'closures', school_no, event_year, COUNT(*)
FROM staging_closures_2010_2025
GROUP BY school_no, event_year
HAVING COUNT(*) > 1

UNION ALL

SELECT 'mergers', school_no, event_year, COUNT(*)
FROM staging_mergers_2010_2025
GROUP BY school_no, event_year
HAVING COUNT(*) > 1

UNION ALL

SELECT 'name_changes', school_no, event_year, COUNT(*)
FROM staging_name_changes_2010_2025
GROUP BY school_no, event_year
HAVING COUNT(*) > 1

UNION ALL

SELECT 'school_type_changes', school_no, event_year, COUNT(*)
FROM staging_school_type_changes_2010_2025
GROUP BY school_no, event_year
HAVING COUNT(*) > 1;

-- Findings from this check (2026-10-11), documented in full in
-- docs/METHODOLOGY.md under "Duplicate-key check on source #4b staging
-- tables":
--   1. Footer text ("School contact details available at:") leaking into
--      school_no in staging_closures_2010_2025 — fixed in staging (see
--      the DELETE added to staging_closures_2010_2025.sql).
--   2. Genuine exact-duplicate rows within a single source file (e.g.
--      school_no 600, 1167 in school_type_changes, 2010) — left raw in
--      staging, deferred to exploration/star-schema stage.
--   3. Column-shifted "legacy" rows in name_changes and
--      school_type_changes (e.g. school_name holding "January", a year
--      in city_or_region) — a source data-quality issue, not an ETL bug;
--      left raw in staging, deferred to exploration/star-schema stage.
