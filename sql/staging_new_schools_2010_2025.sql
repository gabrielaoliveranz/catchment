-- Staging: New schools, 2010-2025 (source #4b)
-- Author: Gabriela Olivera | CATCHMENT
-- DB: Catchment (SQL Server, localhost\gabyg)
-- Purpose: raw 1:1 load of the "New" sheet combined across 16 yearly
--          workbooks (2010-2025), no transformation/types/constraints.
--          Scoped to 2010-2025 only, see docs/METHODOLOGY.md for why
--          2004-2009 were excluded (inconsistent sheet structure).
--          "F9"/"F10"/"F11"/"F13" are Power Query's generic names for
--          source columns with no clear header in some years' files;
--          F9 is confirmed to hold free-text notes.
USE Catchment;
GO

DROP TABLE IF EXISTS staging_new_schools_2010_2025;
GO

CREATE TABLE staging_new_schools_2010_2025 (
	source_file      NVARCHAR(255),   -- "Name" (source filename, traceability)
	school_no        NVARCHAR(255),   -- "New Data.School No"
	school_name      NVARCHAR(255),   -- "New Data.School Name"
	city_or_region   NVARCHAR(255),   -- "New Data.City or Region"
	school_type      NVARCHAR(255),   -- "New Data.School Type"
	school_authority NVARCHAR(255),   -- "New Data.School Authority"
	effective_day    NVARCHAR(255),   -- "New Data.Effective _Day"
	effective_month  NVARCHAR(255),   -- "New Data.Effective _Month"
	effective_year   NVARCHAR(255),   -- "New Data.Effective _Year"
	notes            NVARCHAR(255),   -- "New Data.F9", confirmed: free-text notes
	f10              NVARCHAR(255),   -- "New Data.F10", content not yet identified
	f11              NVARCHAR(255),   -- "New Data.F11", content not yet identified
	f13              NVARCHAR(255),   -- "New Data.F13", content not yet identified
	event_year       NVARCHAR(255)    -- "Year" (extracted from source filename)
);
GO

BULK INSERT staging_new_schools_2010_2025
FROM 'C:\Users\gabyg\Proyectos\catchment\data\raw\4b-new-schools-2010-2025.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);
GO

-- Cleanup: same Excel "used range" padding-row issue as source #4a, -- removing it here completes the raw load, it isn't a business-logic
-- exclusion. See docs/METHODOLOGY.md.
DELETE FROM staging_new_schools_2010_2025 WHERE school_no IS NULL;
GO