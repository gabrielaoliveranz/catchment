-- Analysis 4/6: 3-year moving average of roll per school
-- Author: Gabriela Olivera | CATCHMENT
-- DB: Catchment (SQL Server, localhost\gabyg)
--
-- Question (CATCHMENT_plan_del_proyecto.md, section 4.4):
--   3-year moving average to smooth out year-to-year noise.
--
-- Scope: region Bay of Plenty-Waiariki only.
--   Filter: dim_area.education_region = 'Bay of Plenty, Waiariki'
--
-- Source: staging_student_rolls (source #1) -- same reasoning as
--   analysis_01.sql re: the total-response ethnicity overcount in
--   fact_roll.
--
-- Caveat: the first two years per school (2010, 2011) average over fewer
--   than 3 points, since ROWS BETWEEN clips at the partition start
--   instead of erroring. n_years_in_window flags this -- filter to = 3
--   downstream (Power BI) if partial-window rows shouldn't be shown as a
--   real "3-year" average.
--
-- Built with Claude via direct computer-use control in SSMS, one-time
-- exception to the "I write every query" contract granted 2026-10-11.

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
    AVG(total_students) OVER (
        PARTITION BY school_key ORDER BY roll_year
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_3yr,
    COUNT(*) OVER (
        PARTITION BY school_key ORDER BY roll_year
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS n_years_in_window
FROM roll_totals
ORDER BY school_name, roll_year;
GO
