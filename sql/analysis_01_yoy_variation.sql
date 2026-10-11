-- Analysis 1/6: Year-over-year roll variation per school
-- Author: Gabriela Olivera | CATCHMENT
-- DB: Catchment (SQL Server, localhost\gabyg)
--
-- Question (CATCHMENT_plan_del_proyecto.md, section 4.1):
--   "Variacion interanual por escuela" -- how much does each school's roll
--   grow or shrink from one year to the next. Technique: LAG() over year.
--
-- Scope: region Bay of Plenty-Waiariki only.
--   Filter: dim_area.education_region = 'Bay of Plenty, Waiariki'
--   (confirmed 2026-10-11 via SSMS: 7 TAs -- Kawerau, Opotiki, Rotorua,
--   Taupo, Tauranga City, Western Bay of Plenty, Whakatane districts --
--   191 schools total.)
--
-- Source: staging_student_rolls (source #1), NOT fact_roll. Confirmed
--   2026-10-11 that fact_roll's ethnicity breakdown is total response
--   (not prioritised) -- summing fact_roll.students_count across
--   ethnicity_key overcounts the real roll by roughly 2x. source #1
--   carries the true per-school-per-year total directly, no ethnicity
--   split to worry about. It also covers 2010-2025 (fact_roll only has
--   2014-2025), so this query sees 6 extra years of history per school.
--
-- Built with Claude via direct computer-use control in SSMS, one-time
-- exception to the "I write every query" contract granted 2026-10-11
-- for time pressure (Gaby wrapping up the project same day).

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
    LAG(total_students) OVER (PARTITION BY school_key ORDER BY roll_year) AS prior_year_students,
    total_students - LAG(total_students) OVER (PARTITION BY school_key ORDER BY roll_year) AS change_abs,
    CAST(ROUND(
        100.0 * (total_students - LAG(total_students) OVER (PARTITION BY school_key ORDER BY roll_year))
        / NULLIF(LAG(total_students) OVER (PARTITION BY school_key ORDER BY roll_year), 0)
    , 1) AS DECIMAL(6,1)) AS change_pct
FROM roll_totals
ORDER BY school_name, roll_year;
GO
