-- Staging: School directory (source #3)
-- Author: Gabriela Olivera | CATCHMENT
-- DB: Catchment (SQL Server, localhost\gabyg)
-- Purpose: raw 1:1 load of the MoE directory CSV, no transformation/types/constraints.
--          See docs/METHODOLOGY.md for known file quirks (16-row metadata
--          preamble, header at row 17, UTF-8 BOM, quoted commas in values).

USE Catchment;
GO

DROP TABLE IF EXISTS staging_directory;
GO

CREATE TABLE staging_directory (
	school_number      NVARCHAR(255),       -- "School Number"
	school_name        NVARCHAR(255),       -- "School Name"
	telephone          NVARCHAR(255),       -- "Telephone"
	email              NVARCHAR(255),       -- "Email^"
	principal          NVARCHAR(255),       -- "Principal*"
	school_website     NVARCHAR(255),       -- "School Website"
	street			   NVARCHAR(255),	    -- "Street"
	suburb			   NVARCHAR(255),       -- "Suburb"
	town_city          NVARCHAR(255),       -- "Town / City"
	postal_address     NVARCHAR(255),       -- "Postal Address"
	postal_address_suburb  NVARCHAR(255),   -- "Postal Address Suburb"
	postal_address_city    NVARCHAR(255),   -- "Postal Address City"
	postal_code        NVARCHAR(255),       -- "Postal Code"
	urban_rural        NVARCHAR(255),       -- "Urban/Rural"
	school_type        NVARCHAR(255),       -- "School Type"
	definition         NVARCHAR(255),       -- "Definition"
	authority          NVARCHAR(255),       -- "Authority"
	donations	       NVARCHAR(255),       -- "Donations"
	gender_of_students     NVARCHAR(255),   -- "Gender of Students"
	kme_peak_body      NVARCHAR(255),       -- "KME Peak Body"
	takiwa             NVARCHAR(255),       -- "Takiwā"
	territorial_authority  NVARCHAR(255),   -- "Territorial Authority"
    regional_council   NVARCHAR(255),       -- "Regional Council"
	local_office       NVARCHAR(255),       -- "Local Office"
	education_region   NVARCHAR(255),       -- "Education Region"
	general_electorate     NVARCHAR(255),   -- "General Electorate"
	maori_electorate   NVARCHAR(255),       -- "Māori Electorate"
	neighbourhood_sa2_code NVARCHAR(255),   -- "Neighbourhood (SA2 code)"
	neighbourhood_sa2      NVARCHAR(255),   -- "Neighbourhood (SA2)"
	ward               NVARCHAR(255),       -- "Ward"
	latitude           NVARCHAR(255),       -- "Latitude"
	longitude          NVARCHAR(255),       -- "Longitude"
	enrolment_scheme   NVARCHAR(255),       -- "Enrolment Scheme"
	equity_index       NVARCHAR(255),       -- "Equity Index (EQI)"
	total_school_roll  NVARCHAR(255),       -- "Total School Roll"
	european_pakeka    NVARCHAR(255),       -- "European / Pākehā"
	maori              NVARCHAR(255),       -- "Māori"
	pacific            NVARCHAR(255),       -- "Pacific"
	asian              NVARCHAR(255),       -- "Asian"
	melaa              NVARCHAR(255),       -- "MELAA"
	other              NVARCHAR(255),       -- "Other"
	international      NVARCHAR(255),       -- "International"
	isolation_index    NVARCHAR(255),       -- "Isolation Index"
	language_of_instruction NVARCHAR(255),  -- "Language of Instruction"
	boarding_facilities     NVARCHAR(255),  -- "Boarding Facilities"
	cohort_entry       NVARCHAR(255),       -- "Cohort Entry"
	status             NVARCHAR(255)       -- "Status"
);
GO


BULK INSERT staging_directory 
FROM 'C:\Users\gabyg\Proyectos\catchment\data\raw\directory.csv'
WITH (
    FORMAT = 'CSV',            -- treat the file as real CSV, respecting quoted fields
    FIRSTROW = 18,              -- skip rows 1-17: 16 metadata rows + the header row
    FIELDQUOTE = '"',           -- values wrapped in "..." count as one field, even with a comma inside
    FIELDTERMINATOR = ',',      -- comma separates one column from the next
    ROWTERMINATOR = '\n',       -- same convention as source #2's MoE CSV; worked on the first try here
    CODEPAGE = '65001',         -- read the file as UTF-8, so macrons (e.g. Māori) load correctly
    BATCHSIZE = 50000,          -- load in chunks of 50k rows instead of one giant transaction
    TABLOCK                     -- lock the whole table during load, for faster bulk performance
);
