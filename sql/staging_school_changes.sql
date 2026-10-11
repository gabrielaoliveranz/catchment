-- Staging: School closures, mergers & new schools, March 2026 snapshot (source #4a)
-- Author: Gabriela Olivera | CATCHMENT
-- DB: Catchment (SQL Server, localhost\gabyg)
-- Purpose: raw 1:1 load of 5 sheets from the school closures/mergers/
--          new-schools workbook, one staging table per sheet, no
--          transformation/types/constraints. The "Mergers" sheet has zero
--          rows for this period and is not loaded here.
--          Tables created: staging_new_schools, staging_closures,
--          staging_name_changes, staging_school_type_changes,
--          staging_definition_authority_changes.
--          See docs/METHODOLOGY.md for known file quirks (Name Changes
--          sheet has a mislabeled header, see inline comments below).


-- =========================================================
-- 1) New schools (source #4a, sheet "New")
-- =========================================================
USE Catchment;
GO

DROP TABLE IF EXISTS staging_new_schools;
GO

CREATE TABLE staging_new_schools (
	school_no        NVARCHAR(255),   -- "School No"
	school_name      NVARCHAR(255),   -- "School Name"
	city_or_region   NVARCHAR(255),   -- "City or Region"
	school_type      NVARCHAR(255),   -- "School Type"
	school_authority NVARCHAR(255),   -- "School Authority"
	effective_day    NVARCHAR(255),   -- "Effective Day"
	notes            NVARCHAR(255)    -- "Notes"
);
GO

BULK INSERT staging_new_schools
FROM 'C:\Users\gabyg\Proyectos\catchment\data\raw\4a-new-schools.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);
GO


-- =========================================================
-- 2) Closures (source #4a, sheet "Closures")
-- =========================================================
DROP TABLE IF EXISTS staging_closures;
GO

CREATE TABLE staging_closures (
	school_no           NVARCHAR(255),   -- "School No"
	school_name         NVARCHAR(255),   -- "School Name"
	city_or_region      NVARCHAR(255),   -- "City or Region"
	school_type         NVARCHAR(255),   -- "School Type"
	school_authority    NVARCHAR(255),   -- "School Authority"
	effective_day       NVARCHAR(255),   -- "Effective Day"
	effective_month     NVARCHAR(255),   -- "Effective Month"
	effective_year      NVARCHAR(255),   -- "Effective Year"
	reason_for_closure  NVARCHAR(255),   -- "Reason for Closure"
	notes               NVARCHAR(255)    -- "Notes"
);
GO

BULK INSERT staging_closures
FROM 'C:\Users\gabyg\Proyectos\catchment\data\raw\4a-closures.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);
GO


-- =========================================================
-- 3) Name changes (source #4a, sheet "Name Changes")
-- NOTE: the source header is mislabeled, it says "City or Region" in
-- position 3 and "School Type" in position 4, but the actual values are
-- swapped (position 3 holds school type values, position 4 holds
-- authority values, and region is actually in position 5). Columns here
-- are named for what the data really is, not what the source header says.
-- =========================================================
DROP TABLE IF EXISTS staging_name_changes;
GO

CREATE TABLE staging_name_changes (
	school_no        NVARCHAR(255),   -- "School No"
	new_school_name  NVARCHAR(255),   -- "New School Name"
	school_type      NVARCHAR(255),   -- source header says "City or Region", actually School Type
	school_authority NVARCHAR(255),   -- source header says "School Type", actually School Authority
	city_or_region   NVARCHAR(255),   -- source header says "School Authority", actually City or Region
	effective_from   NVARCHAR(255),   -- "Effective From"
	previous_name    NVARCHAR(255)    -- "Previous Name"
);
GO

BULK INSERT staging_name_changes
FROM 'C:\Users\gabyg\Proyectos\catchment\data\raw\4a-name-changes.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);
GO


-- =========================================================
-- 4) School type changes (source #4a, sheet "School Type Changes")
-- =========================================================
DROP TABLE IF EXISTS staging_school_type_changes;
GO

CREATE TABLE staging_school_type_changes (
	school_no            NVARCHAR(255),   -- "School No."
	school_name          NVARCHAR(255),   -- "SchoolName"
	new_type             NVARCHAR(255),   -- "NewType"
	region               NVARCHAR(255),   -- "Region"
	effective_from_date  NVARCHAR(255),   -- "EffectiveFromDate"
	previous_type        NVARCHAR(255)    -- "PreviousType"
);
GO

BULK INSERT staging_school_type_changes
FROM 'C:\Users\gabyg\Proyectos\catchment\data\raw\4a-school-type-changes.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);
GO


-- =========================================================
-- 5) Definition/authority changes (source #4a, sheet "Definition-Authority Changes")
-- =========================================================
DROP TABLE IF EXISTS staging_definition_authority_changes;
GO

CREATE TABLE staging_definition_authority_changes (
	school_no         NVARCHAR(255),   -- "School No"
	school_name       NVARCHAR(255),   -- "School Name"
	city_or_region    NVARCHAR(255),   -- "City or Region"
	school_type       NVARCHAR(255),   -- "School Type"
	school_authority  NVARCHAR(255),   -- "School Authority"
	effective_day     NVARCHAR(255),   -- "Effective Day"
	effective_month   NVARCHAR(255),   -- "Effective Month"
	effective_year    NVARCHAR(255),   -- "Effective Year"
	type_of_change    NVARCHAR(255),   -- "Type of Change"
	notes             NVARCHAR(255)    -- "Notes"
);
GO

BULK INSERT staging_definition_authority_changes
FROM 'C:\Users\gabyg\Proyectos\catchment\data\raw\4a-definition-authority-changes.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);
GO




-- Cleanup: Excel's "used range" extends far beyond the real data on several
-- sheets in this workbook (confirmed via openpyxl: this sheet showed up to
-- 65,514 "rows" when the real data is a fraction of that). The CSV export
-- wrote those as blank padding rows, which BULK INSERT loaded along with
-- the real data. Not real source content, removing them here completes
-- the raw load, it isn't a business-logic exclusion.

DELETE FROM staging_new_schools WHERE school_no IS NULL;

DELETE FROM staging_closures WHERE school_no IS NULL;

DELETE FROM staging_name_changes WHERE school_no IS NULL;

DELETE FROM staging_school_type_changes WHERE school_no IS NULL;

DELETE FROM staging_definition_authority_changes WHERE school_no IS NULL;



-- Check: does school_no work as a candidate key for this table (one row
-- per school per event), or are there duplicates?
-- Confirmed: empty result set, no school_no appears more than once.

SELECT school_no, COUNT(*) AS total_count
FROM staging_new_schools
GROUP BY school_no
HAVING COUNT(*) > 1;