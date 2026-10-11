-- Analysis 6/6: Capacity pressure signal (current roll vs own historical max)
-- Author: Gabriela Olivera | CATCHMENT
-- DB: Catchment (SQL Server, localhost\gabyg)
--
-- Question (CATCHMENT_plan_del_proyecto.md, section 4.6):
--   Current roll vs each school's own historical maximum, as a proxy for
--   capacity pressure. This is trampa #4 in the plan: published school
--   "capacity" isn't a MoE data field here, so a school at/above its own
--   all-time high is a stand-in signal for "may be running out of room",
--   NOT a measurement of real physical capacity. Label it as a proxy
--   wherever it surfaces (this output, METHODOLOGY.md, the Power BI
--   page) -- never as a hard capacity number.
--
-- Scope: region Bay of Plenty-Waiariki only.
--   Filter: dim_area.education_region = 'Bay of Plenty, Waiariki'
--
-- Source: staging_student_rolls (source #1) -- same reasoning as
--   analysis_01.sql re: the total-response ethnicity overcount in
--   fact_roll. Also means "historical max" here covers 2010-2025, not
--   just fact_roll's 2014-2025 -- a real improvement for this one, since
--   a pre-2014 peak would otherwise be invisible.
--
-- Caveat: a school with very few years of data (e.g. newly opened) will
--   trivially read as "at its historical max" every year -- n_years_available
--   flags this so it can be filtered or footnoted downstream.
--
USE Catchment;
GO

WITH roll_totals AS (
    SELECT
        ds.school_key,
        ds.school_name,
        da.territorial_authority,
        TRY_CAST(ssr.roll_year AS INT)  AS roll_year,
        TRY_CAST(ssr.total_roll AS INT) AS total_students
    FROM staging_student_rolls ssr
    JOIN dim_school ds ON ds.school_no = ssr.school_id
    JOIN dim_area da   ON da.area_key = ds.area_key
    WHERE da.education_region = 'Bay of Plenty, Waiariki'
      AND TRY_CAST(ssr.total_roll AS INT) IS NOT NULL
      AND TRY_CAST(ssr.roll_year AS INT) IS NOT NULL
)
SELECT
    school_name,
    territorial_authority,
    roll_year,
    total_students,
    MAX(total_students) OVER (PARTITION BY school_key) AS historical_max,
    COUNT(*) OVER (PARTITION BY school_key) AS n_years_available,
    CASE WHEN total_students >= MAX(total_students) OVER (PARTITION BY school_key)
         THEN 1 ELSE 0 END AS at_or_above_max,
    CAST(ROUND(
        100.0 * total_students / NULLIF(MAX(total_students) OVER (PARTITION BY school_key), 0)
    , 1) AS DECIMAL(6,1)) AS pct_of_historical_max
FROM roll_totals
ORDER BY school_name, roll_year;
GO
