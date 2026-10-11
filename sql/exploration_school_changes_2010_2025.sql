-- Exploration: School closures/mergers/new schools, historical 2010-2025 (source #4b)
-- Author: Gabriela Olivera | CATCHMENT
-- DB: Catchment (SQL Server, localhost\gabyg)
-- Purpose: scratch queries to verify the 5 staging tables loaded from
--          source #4b (New, Closures, Mergers, Name Changes, School Type
--          Changes) after the Power Query combine + BULK INSERT. Not
--          meant to run top-to-bottom as a build step, see
--          sql/staging_school_changes_2010_2025.sql for that.

-- Duplicate check on the candidate key (school_no + event_year) across
-- all 5 tables at once. Empty result = no duplicates found.


USE Catchment

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




-- Inspect: rows behind the duplicate-key findings above (source #4b)

SELECT * FROM staging_new_schools_2010_2025 WHERE school_no = '621' AND event_year = '2010';

SELECT * FROM staging_closures_2010_2025 WHERE school_no IN ('1637','3728') AND event_year = '2010';

SELECT * FROM staging_closures_2010_2025 WHERE school_no = 'School contact details available at:';

SELECT * FROM staging_name_changes_2010_2025 WHERE (school_no = '1' AND event_year = '2018') OR (school_no = '15' AND event_year = '2020') OR (school_no = '16' AND event_year = '2023') OR (school_no = '13' AND event_year = '2024');

SELECT * FROM staging_school_type_changes_2010_2025 WHERE (school_no = '1167' AND event_year = '2010') OR (school_no = '600' AND event_year = '2010') OR (school_no = '1' AND event_year IN ('2020','2021'));

SELECT TOP 5 * FROM staging_school_type_changes_2010_2025 WHERE school_no IS NULL AND event_year = '2024';



DELETE FROM staging_closures_2010_2025 WHERE school_no = 'School contact details available at:';