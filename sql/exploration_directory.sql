-- Exploration: School directory (source #3)
-- Author: Gabriela Olivera | CATCHMENT
-- DB: Catchment (SQL Server, localhost\gabyg)
-- Purpose: sanity checks, duplicate/candidate-key check, truncation check,
--          and macron integrity check on staging_directory.
--          See docs/METHODOLOGY.md for known file quirks (metadata preamble,
--          consent-based blanks in Email/Principal, blank Total School Roll rows).

USE Catchment

-- Check: quick visual sanity check on staging_directory, do the columns
-- line up correctly after the load?

SELECT TOP (50) *
FROM staging_directory;


-- Check: is "definition" NULL in every row, as the 50-row sample suggested?
-- Resolved: no, 40 of 2578 rows have a value. The sample was misleading;
-- see METHODOLOGY.md for what those 40 rows turn out to be.

SELECT 
	COUNT (*) total_count, 
	COUNT (definition) AS definition
FROM staging_directory;


-- Check: what values does "definition" take when it's not NULL, and do
-- they cluster around a particular school_type?

SELECT 
	definition, 
	school_type
FROM staging_directory
WHERE definition IS NOT NULL;


-- Check: does EVERY row of each school_type actually have "definition"
-- populated, or just some?

SELECT  
	school_type, 
	COUNT(*)AS total_count, 
	COUNT (school_type) AS school_type_count, 
	COUNT (definition) AS definition
FROM staging_directory
GROUP BY school_type
ORDER BY school_type;


-- Check: which specific "Specialist School" rows are missing "definition"?
-- Resolved: 2 rows, both status = 'Proposed', schools that haven't opened
-- yet. See METHODOLOGY.md.

SELECT 
	school_type, 
	definition, 
	school_name, 
	status
FROM staging_directory
WHERE school_type = 'Specialist School' AND definition IS NULL;


-- Check: does school_number uniquely identify each row?
-- Resolved: 2578 total rows, 2578 distinct school_number, no duplicates.

SELECT 
	(SELECT COUNT(*) FROM staging_directory) AS total_count,
	COUNT(DISTINCT school_number) AS school_number_count
FROM staging_directory;



-- Check: any value truncated by NVARCHAR(255)? (MAX(LEN(col)) near 255
-- would be suspicious.)
-- Resolved: no risk, longest value is school_name at 82 chars. "takiwa"
-- returned NULL instead of a number, investigated below.

SELECT
    MAX(LEN(school_number))         AS school_number_max_len,
    MAX(LEN(school_name))           AS school_name_max_len,
    MAX(LEN(telephone))             AS telephone_max_len,
    MAX(LEN(email))                 AS email_max_len,
    MAX(LEN(principal))             AS principal_max_len,
    MAX(LEN(school_website))        AS school_website_max_len,
    MAX(LEN(street))                AS street_max_len,
    MAX(LEN(suburb))                AS suburb_max_len,
    MAX(LEN(town_city))             AS town_city_max_len,
    MAX(LEN(postal_address))        AS postal_address_max_len,
    MAX(LEN(postal_address_suburb)) AS postal_address_suburb_max_len,
    MAX(LEN(postal_address_city))   AS postal_address_city_max_len,
    MAX(LEN(postal_code))           AS postal_code_max_len,
    MAX(LEN(urban_rural))           AS urban_rural_max_len,
    MAX(LEN(school_type))           AS school_type_max_len,
    MAX(LEN(definition))            AS definition_max_len,
    MAX(LEN(authority))             AS authority_max_len,
    MAX(LEN(donations))             AS donations_max_len,
    MAX(LEN(gender_of_students))    AS gender_of_students_max_len,
    MAX(LEN(kme_peak_body))         AS kme_peak_body_max_len,
    MAX(LEN(takiwa))                AS takiwa_max_len,
    MAX(LEN(territorial_authority)) AS territorial_authority_max_len,
    MAX(LEN(regional_council))      AS regional_council_max_len,
    MAX(LEN(local_office))          AS local_office_max_len,
    MAX(LEN(education_region))      AS education_region_max_len,
    MAX(LEN(general_electorate))    AS general_electorate_max_len,
    MAX(LEN(maori_electorate))      AS maori_electorate_max_len,
    MAX(LEN(neighbourhood_sa2_code))AS neighbourhood_sa2_code_max_len,
    MAX(LEN(neighbourhood_sa2))     AS neighbourhood_sa2_max_len,
    MAX(LEN(ward))                  AS ward_max_len,
    MAX(LEN(latitude))              AS latitude_max_len,
    MAX(LEN(longitude))             AS longitude_max_len,
    MAX(LEN(enrolment_scheme))      AS enrolment_scheme_max_len,
    MAX(LEN(equity_index))          AS equity_index_max_len,
    MAX(LEN(total_school_roll))     AS total_school_roll_max_len,
    MAX(LEN(european_pakeka))       AS european_pakeka_max_len,
    MAX(LEN(maori))                 AS maori_max_len,
    MAX(LEN(pacific))               AS pacific_max_len,
    MAX(LEN(asian))                 AS asian_max_len,
    MAX(LEN(melaa))                 AS melaa_max_len,
    MAX(LEN(other))                 AS other_max_len,
    MAX(LEN(international))         AS international_max_len,
    MAX(LEN(isolation_index))       AS isolation_index_max_len,
    MAX(LEN(language_of_instruction)) AS language_of_instruction_max_len,
    MAX(LEN(boarding_facilities))   AS boarding_facilities_max_len,
    MAX(LEN(cohort_entry))          AS cohort_entry_max_len,
    MAX(LEN(status))                AS status_max_len
FROM staging_directory;

-- Check: does "takiwa" have any non-null value at all?
-- Resolved: 0 of 2578, fully NULL, like student_age in source #2.

SELECT 
	COUNT (*) total_count, 
	COUNT (takiwa) AS takiwa
FROM staging_directory;


-- Check: does the macron in "Ōkaihau" hold the correct Unicode code point
-- across every matching row, not just visually?
-- Resolved: single group, 332 ("Ō"), across both matching rows, no
-- corrupted rows mixed in.

SELECT 
 COUNT(*) AS total_count, 
 UNICODE(SUBSTRING(neighbourhood_sa2, 1, 1)) AS unicode_check
FROM staging_directory
WHERE neighbourhood_sa2 LIKE '_kaihau'
GROUP BY UNICODE(SUBSTRING(neighbourhood_sa2, 1, 1));