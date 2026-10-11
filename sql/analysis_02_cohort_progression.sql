-- Analysis 2/6: Cohort progression (retention / leakage per school)
-- Author: Gabriela Olivera | CATCHMENT
-- DB: Catchment (SQL Server, localhost\gabyg)
--
-- Question (CATCHMENT_plan_del_proyecto.md, section 4.2):
--   "Progresion de cohortes" -- students in Year 5 in 2020 vs Year 6 in
--   2021: how much of that cohort each school retains, how much leaks.
--
-- Scope: region Bay of Plenty-Waiariki only.
--   Filter: dim_area.education_region = 'Bay of Plenty, Waiariki'
--
-- Source: fact_roll (the only table with a year_level breakdown --
--   staging_student_rolls/source #1 is school+year only). This means the
--   ~2x total-response ethnicity overcount (confirmed 2026-10-11, see
--   analysis_01.sql) is baked into both sides of this comparison. That's
--   fine for the retention RATIO (both sides inflated the same way), but
--   the absolute counts below are NOT real headcounts -- don't report
--   them as such without this caveat.
--
-- Caveat: a drop here can mean genuine leakage to another school, a
--   school closure/merger (check school_status_history before calling it
--   "leakage" -- trampa #3 in the plan), or normal cohort-size change
--   unrelated to capacity. This query surfaces the raw retention number;
--   it does not attempt to separate those causes.
--
USE Catchment;
GO

WITH cohort_base AS (
    SELECT
        ds.school_key,
        ds.school_name,
        da.territorial_authority,
        fr.year_key,
        dyl.student_year_level,
        SUM(fr.students_count) AS total_students   -- total-response inflated, see header
    FROM fact_roll fr
    JOIN dim_school ds      ON fr.school_key = ds.school_key
    JOIN dim_area da        ON da.area_key = ds.area_key
    JOIN dim_year_level dyl ON fr.year_level_key = dyl.year_level_key
    WHERE da.education_region = 'Bay of Plenty, Waiariki'
      AND (
            (fr.year_key = 2020 AND dyl.student_year_level = 'Year 5')
         OR (fr.year_key = 2021 AND dyl.student_year_level = 'Year 6')
          )
    GROUP BY ds.school_key, ds.school_name, da.territorial_authority, fr.year_key, dyl.student_year_level
)
SELECT
    y5.school_name,
    y5.territorial_authority,
    y5.total_students AS year5_2020_count,
    y6.total_students AS year6_2021_count,
    y6.total_students - y5.total_students AS change_abs,
    CAST(ROUND(100.0 * (y6.total_students - y5.total_students) / NULLIF(y5.total_students, 0), 1) AS DECIMAL(6,1)) AS change_pct
FROM cohort_base y5
JOIN cohort_base y6
    ON y5.school_key = y6.school_key
   AND y5.year_key = 2020 AND y5.student_year_level = 'Year 5'
   AND y6.year_key = 2021 AND y6.student_year_level = 'Year 6'
ORDER BY change_pct ASC;
GO
