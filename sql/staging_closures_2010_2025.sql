-- Staging: Closures, 2010-2025 (source #4b)
-- Author: Gabriela Olivera | CATCHMENT
-- DB: Catchment (SQL Server, localhost\gabyg)
-- Purpose: raw 1:1 load of the "Closures" sheet combined across 16 yearly
--          workbooks (2010-2025), no transformation/types/constraints.
--          Scoped to 2010-2025 only — see docs/METHODOLOGY.md.
--          Of 248 generic "F" columns found on expand (Excel's inflated
--          used-range artifact, same issue as source #4a), only F11 and
--          F13 had any real data and were kept; the rest were 100% empty
--          and dropped automatically in Power Query before export.
USE Catchment;
GO

DROP TABLE IF EXISTS staging_closures_2010_2025;
GO

CREATE TABLE staging_closures_2010_2025 (
	source_file         NVARCHAR(255),   -- "Name" (source filename, traceability)
	school_no           NVARCHAR(255),   -- "Closures Data.School No"
	school_name         NVARCHAR(255),   -- "Closures Data.School Name"
	city_or_region      NVARCHAR(255),   -- "Closures Data.City or Region"
	school_type         NVARCHAR(255),   -- "Closures Data.School Type"
	school_authority    NVARCHAR(255),   -- "Closures Data.School Authority"
	effective_day       NVARCHAR(255),   -- "Closures Data.Effective _Day"
	effective_month     NVARCHAR(255),   -- "Closures Data.Effective _Month"
	effective_year      NVARCHAR(255),   -- "Closures Data.Effective _Year"
	reason_for_closure  NVARCHAR(255),   -- "Closures Data.Reason for Closure"
	f11                 NVARCHAR(255),   -- "Closures Data.F11" — content not yet identified
	f13                 NVARCHAR(255),   -- "Closures Data.F13" — content not yet identified
	notes               NVARCHAR(255),   -- "Closures Data.Notes"
	event_year          NVARCHAR(255)    -- "Year" (extracted from source filename)
);
GO

BULK INSERT staging_closures_2010_2025
FROM 'C:\Users\gabyg\Proyectos\catchment\data\raw\4b-closures-2010-2025.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);
GO

-- Cleanup: same Excel "used range" padding-row issue as source #4a/#4b's
-- "New" table — not a business-logic exclusion, completes the raw load.
DELETE FROM staging_closures_2010_2025 WHERE school_no IS NULL;
GO
-- Cleanup: boilerplate footer text ("School contact details available at:")
-- leaking into school_no on 14 rows, from the sheet's used-range padding.
-- Not caught by the NULL-based cleanup above since this value isn't NULL.
-- See docs/METHODOLOGY.md.
DELETE FROM staging_closures_2010_2025 WHERE school_no = 'School contact details available at:';
GO
