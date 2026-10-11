-- Analysis 5/6: Each school's share of its TA's total roll
-- Author: Gabriela Olivera | CATCHMENT
-- DB: Catchment (SQL Server, localhost\gabyg)
--
-- Question (CATCHMENT_plan_del_proyecto.md, section 4.5):
--   "Participacion de cada escuela en la matricula de su TA" --
--   SUM() OVER (PARTITION BY ta, year), then school_total / ta_total.
--
-- Scope: region Bay of Plenty-Waiariki only.
--   Filter: dim_area.education_region = 'Bay of Plenty, Waiariki'
--
-- Source: staging_student_rolls (source #1) -- same reasoning as
--   analysis_01.sql re: the total-response ethnicity overcount in
--   fact_roll. Using source #1 for both numerator and denominator avoids
--   that problem entirely here (no ethnicity dimension involved at all).
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
    territorial_authority,
    school_name,
    roll_year,
    total_students,
    SUM(total_students) OVER (PARTITION BY territorial_authority, roll_year) AS ta_total,
    CAST(ROUND(
        100.0 * total_students / NULLIF(SUM(total_students) OVER (PARTITION BY territorial_authority, roll_year), 0)
    , 2) AS DECIMAL(6,2)) AS share_of_ta_pct
FROM roll_totals
ORDER BY territorial_authority, roll_year, share_of_ta_pct DESC;
GO
