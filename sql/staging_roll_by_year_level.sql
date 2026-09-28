-- Staging: Roll by funding year level & ethnicity (source #2)
-- Author: Gabriela Olivera | CATCHMENT
-- DB: Catchment (SQL Server, localhost\gabyg)
-- Purpose: raw 1:1 load of the MoE CSV, no transformation/types/constraints.
--          See docs/METHODOLOGY.md for the BULK INSERT debugging history
--          (3 failures before landing on the options below).

USE Catchment;
GO

DROP TABLE IF EXISTS staging_roll_by_year_level;
GO

CREATE TABLE staging_roll_by_year_level (
    students_values             NVARCHAR(255),   -- "Students (? Values)"
    year_as_at_1_july           NVARCHAR(255),   -- "Year: As at 1 July"
    student_year_level          NVARCHAR(255),   -- "Student: Year level"
    student_year_level_group    NVARCHAR(255),   -- "Student: Year level group"
    school_id                   NVARCHAR(255),   -- "School: ID"
    student_ethnic_group        NVARCHAR(255),   -- "Student: Ethnic Group"
    student_age                 NVARCHAR(255),   -- "Student_age"
    school_name                 NVARCHAR(255),   -- "School: Name"
    school_sector                NVARCHAR(255),   -- "School: Sector"
    school_type                 NVARCHAR(255),   -- "School: Type"
    school_authority             NVARCHAR(255),   -- "School: Authority"
    school_gender                NVARCHAR(255),   -- "School: Gender"
    school_affiliation_type      NVARCHAR(255),   -- "School: Affiliation Type"
    school_affiliation           NVARCHAR(255),   -- "School: Affiliation"
    school_maori_medium_peak_body_affiliation   NVARCHAR(255),   -- "School: Māori Medium Peak Body Affiliation"
    education_region             NVARCHAR(255),   -- "Region: Education Region"
    regional_council             NVARCHAR(255),   -- "Region: Regional Council"
    territorial_authority        NVARCHAR(255),   -- "Region: Territorial Authority"
    moe_local_office             NVARCHAR(255),   -- "Region: MOE Local office"
    te_mahau_rohe                NVARCHAR(255),   -- "Te Mahau Rohe"
    takiwa                       NVARCHAR(255),   -- "Takiwa"
    equi_band                    NVARCHAR(255),   -- "EQI Band"
    equi_group                   NVARCHAR(255)    -- "EQI Group"
);
GO

BULK INSERT staging_roll_by_year_level
FROM 'C:\Users\gabyg\Proyectos\catchment\data\raw\10-Machine Readable-Roll by Funding year level ethnicity 2014-2025.csv'
WITH (
    FORMAT = 'CSV',            -- treat the file as real CSV, respecting quoted fields
    FIRSTROW = 2,               -- skip row 1 (the header)
    FIELDQUOTE = '"',           -- values wrapped in "..." count as one field, even with a comma inside
    FIELDTERMINATOR = ',',      -- comma separates one column from the next
    ROWTERMINATOR = '\n',       -- marks the end of each row (see METHODOLOGY.md — \r\n failed, \n worked)
    CODEPAGE = '65001',         -- read the file as UTF-8, so macrons (e.g. Māori) load correctly
    BATCHSIZE = 50000,          -- load in chunks of 50k rows instead of one giant transaction
    TABLOCK                     -- lock the whole table during load, for faster bulk performance
);