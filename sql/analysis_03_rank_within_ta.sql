-- Analysis 3/6: Ranking within each territorial authority
-- Author: Gabriela Olivera | CATCHMENT
-- DB: Catchment (SQL Server, localhost\gabyg)
--
-- Question (CATCHMENT_plan_del_proyecto.md, section 4.3):
--   "Ranking dentro de cada TA" -- RANK() OVER (PARTITION BY ta ORDER BY
--   growth DESC): which schools grow fastest within their own TA.
--
-- Scope: region Bay of Plenty-Waiariki only.
--   Filter: dim_area.education_region = 'Bay of Plenty, Waiariki'
--   Partition column: dim_area.territorial_authority (7 TAs in-region).
--
-- Growth definition: latest available year's YoY % change per school
--   (same metric as analysis_01.change_pct, for each school's most
--   recent year) -- i.e. "who's growing fastest right now", which is
--   the version most useful for a capacity-pressure report. Schools with
--   only one year of data (no prior year to compare) are excluded.
--
-- Source: staging_student_rolls (source #1) -- same reasoning as
--   analysis_01.sql re: the total-response ethnicity overcount in
--   fact_roll.
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
),
yoy AS (
    SELECT
        *,
        LAG(total_students) OVER (PARTITION BY school_key ORDER BY roll_year) AS prior_year_students,
        ROW_NUMBER() OVER (PARTITION BY school_key ORDER BY roll_year DESC)   AS rn_latest
    FROM roll_totals
),
latest_growth AS (
    SELECT
        school_key, school_name, territorial_authority, roll_year AS latest_year,
        total_students,
        CAST(ROUND(100.0 * (total_students - prior_year_students) / NULLIF(prior_year_students, 0), 1) AS DECIMAL(6,1)) AS growth_pct
    FROM yoy
    WHERE rn_latest = 1 AND prior_year_students IS NOT NULL
)
SELECT
    territorial_authority,
    school_name,
    latest_year,
    total_students,
    growth_pct,
    RANK() OVER (PARTITION BY territorial_authority ORDER BY growth_pct DESC) AS rank_in_ta
FROM latest_growth
ORDER BY territorial_authority, rank_in_ta;
GO
