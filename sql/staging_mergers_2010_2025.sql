USE Catchment;
GO
DROP TABLE IF EXISTS staging_mergers_2010_2025;
GO
CREATE TABLE staging_mergers_2010_2025 (
    source_file        NVARCHAR(255),
    school_no          NVARCHAR(255),
    school_name        NVARCHAR(255),
    city_or_region     NVARCHAR(255),
    school_type        NVARCHAR(255),
    school_authority   NVARCHAR(255),
    effective_day      NVARCHAR(255),
    effective_month    NVARCHAR(255),
    effective_year     NVARCHAR(255),
    comments            NVARCHAR(255),
    f11                 NVARCHAR(255),
    f13                 NVARCHAR(255),
    notes                NVARCHAR(255),
    effective_day_2     NVARCHAR(255),  -- duplicate header variant: "Effective \nDay" (line break in source)
    effective_month_2   NVARCHAR(255),  -- duplicate header variant: "Effective \nMonth"
    effective_year_2    NVARCHAR(255),  -- duplicate header variant: "Effective \nYear"
    column11             NVARCHAR(255),
    column13             NVARCHAR(255),
    event_year           NVARCHAR(255)  -- extracted Year
);
GO
BULK INSERT staging_mergers_2010_2025
FROM 'C:\Users\gabyg\Proyectos\catchment\data\raw\4b-mergers-2010-2025.csv'
WITH (FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='\n', CODEPAGE='65001', TABLOCK);
GO
DELETE FROM staging_mergers_2010_2025 WHERE school_no IS NULL;
GO