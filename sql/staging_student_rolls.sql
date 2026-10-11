-- Staging: Student rolls 2010-2025 (source #1)
-- Author: Gabriela Olivera | CATCHMENT
-- DB: Catchment (SQL Server, localhost\gabyg)
-- Purpose: raw 1:1 load of the MoE student rolls CSV (Power Query "Combined"
--          query output, 16 yearly sheets stacked into one long table), no
--          transformation/types/constraints.
--          See docs/METHODOLOGY.md for known file quirks: pseudo-total rows
--          (School ID -1 and 99999) and malformed rows were already excluded
--          upstream by the source Power Query query, not by this staging
--          table; Decile is fully NULL from 2023 onward; source column
--          "Total" has trailing spaces in its header name.

USE Catchment;
GO

DROP TABLE IF EXISTS staging_student_rolls;
GO

CREATE TABLE staging_student_rolls (
	school_id               NVARCHAR(255),   -- "School ID"
	school_name             NVARCHAR(255),   -- "School Name"
	decile                  NVARCHAR(255),   -- "Decile" (NULL from 2023 onward, see METHODOLOGY.md)
	school_type             NVARCHAR(255),   -- "Type"
	authority                NVARCHAR(255),  -- "Authority"
	regional_council        NVARCHAR(255),   -- "Regional Council"
	education_region        NVARCHAR(255),   -- "Education Region"
	ta_auckland_local_board NVARCHAR(255),   -- "TA with Auckland Local Board"
	total_roll              NVARCHAR(255),   -- "Total" (source header has trailing spaces)
	roll_year                NVARCHAR(255)   -- "Year"
);
GO


BULK INSERT staging_student_rolls
FROM 'C:\Users\gabyg\Proyectos\catchment\data\raw\2-student-rolls-combined.csv'
WITH (
    FORMAT = 'CSV',            -- treat the file as real CSV, respecting quoted fields
    FIRSTROW = 2,               -- skip row 1, the header (no metadata preamble in this file)
    FIELDQUOTE = '"',           -- values wrapped in "..." count as one field, even with a comma inside
    FIELDTERMINATOR = ',',      -- comma separates one column from the next
    ROWTERMINATOR = '\n',       -- same convention as source #2/#3, worked on the first try
    CODEPAGE = '65001',         -- read the file as UTF-8, so macrons load correctly
    BATCHSIZE = 50000,          -- load in chunks of 50k rows instead of one giant transaction
    TABLOCK                     -- lock the whole table during load, for faster bulk performance
);