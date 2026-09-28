-- Exploration: School directory (source #3)
-- Author: Gabriela Olivera | CATCHMENT
-- DB: Catchment (SQL Server, localhost\gabyg)
-- Purpose: sanity checks, duplicate/candidate-key check, truncation check,
--          and macron integrity check on staging_directory.
--          See docs/METHODOLOGY.md for known file quirks (metadata preamble,
--          consent-based blanks in Email/Principal, blank Total School Roll rows).

USE Catchment

-- Check: quick visual sanity check on staging_directory — do the columns
-- line up correctly after the load?

SELECT TOP (50) *
FROM staging_directory;


-- Check: is "definition" NULL in every row, as the 50-row sample suggested?
-- Resolved: no — 40 of 2578 rows have a value. The sample was misleading;
-- see METHODOLOGY.md for what those 40 rows turn out to be.

SELECT COUNT (*) total_count, COUNT (definition) AS definition
FROM staging_directory;


-- Check: what values does "definition" take when it's not NULL, and do
-- they cluster around a particular school_type?

SELECT definition, school_type
FROM staging_directory
WHERE definition IS NOT NULL;


-- Check: does EVERY row of each school_type actually have "definition"
-- populated, or just some?

SELECT  school_type, COUNT(*)AS total_count, COUNT (school_type) AS school_type_count, COUNT (definition) AS definition
FROM staging_directory
GROUP BY school_type
ORDER BY school_type;


-- Check: which specific "Specialist School" rows are missing "definition"?
-- Resolved: 2 rows, both status = 'Proposed' — schools that haven't opened
-- yet. See METHODOLOGY.md.

SELECT school_type, definition, school_name, status
FROM staging_directory
WHERE school_type = 'Specialist School' AND definition IS NULL;


-- Check: does school_number uniquely identify each row?
-- Resolved: 2578 total rows, 2578 distinct school_number — no duplicates.

SELECT 
	(SELECT COUNT(*) FROM staging_directory) AS total_count,
	COUNT(DISTINCT school_number) AS school_number_count
FROM staging_directory;



-- Check: any value truncated by NVARCHAR(255)? (MAX(LEN(col)) near 255
-- would be suspicious.)
-- Resolved: no risk — longest value is school_name at 82 chars. "takiwa"
-- returned NULL instead of a number — investigated below.

SELECT

MAX(LEN(school_number
)) AS school_number
,MAX(LEN(school_name
)) AS school_name
,MAX(LEN(telephone
)) AS telephone
,MAX(LEN(email
)) AS email
,MAX(LEN(principal
)) AS principal
,MAX(LEN(school_website
)) AS school_website
,MAX(LEN(street
)) AS street
,MAX(LEN(suburb
)) AS suburb
,MAX(LEN(town_city
)) AS town_city
,MAX(LEN(postal_address
)) AS postal_address
,MAX(LEN(postal_address_suburb
)) AS postal_address_suburb
,MAX(LEN(postal_address_city
)) AS postal_address_city
,MAX(LEN(postal_code
)) AS postal_code
,MAX(LEN(urban_rural
)) AS urban_rural
,MAX(LEN(school_type
)) AS school_type
,MAX(LEN(definition
)) AS definition
,MAX(LEN(authority
)) AS authority
,MAX(LEN(donations
)) AS donations
,MAX(LEN(gender_of_students
)) AS gender_of_students
,MAX(LEN(kme_peak_body
)) AS kme_peak_body
,MAX(LEN(takiwa
)) AS takiwa
,MAX(LEN(territorial_authority
)) AS territorial_authority
,MAX(LEN(regional_council
)) AS regional_council
,MAX(LEN(local_office
)) AS local_office
,MAX(LEN(education_region
)) AS education_region
,MAX(LEN(general_electorate
)) AS general_electorate
,MAX(LEN(maori_electorate
)) AS maori_electorate
,MAX(LEN(neighbourhood_sa2_code
)) AS neighbourhood_sa2_code
,MAX(LEN(neighbourhood_sa2
)) AS neighbourhood_sa2
,MAX(LEN(ward
)) AS ward
,MAX(LEN(latitude
)) AS latitude
,MAX(LEN(longitude
)) AS longitude
,MAX(LEN(enrolment_scheme
)) AS enrolment_scheme
,MAX(LEN(equity_index
)) AS equity_index
,MAX(LEN(total_school_roll
)) AS total_school_roll
,MAX(LEN(european_pakeka
)) AS european_pakeka
,MAX(LEN(maori
)) AS maori
,MAX(LEN(pacific
)) AS pacific
,MAX(LEN(asian
)) AS asian
,MAX(LEN(melaa
)) AS melaa
,MAX(LEN(other
)) AS other
,MAX(LEN(international
)) AS international
,MAX(LEN(isolation_index
)) AS isolation_index
,MAX(LEN(language_of_instruction
)) AS language_of_instruction
,MAX(LEN(boarding_facilities
)) AS boarding_facilities
,MAX(LEN(cohort_entry
)) AS cohort_entry
,MAX(LEN(status)) AS status

FROM staging_directory;

-- Check: does "takiwa" have any non-null value at all?
-- Resolved: 0 of 2578 — fully NULL, like student_age in source #2.

SELECT COUNT (*) total_count, COUNT (takiwa) AS takiwa
FROM staging_directory;


-- Check: does the macron in "Ōkaihau" hold the correct Unicode code point
-- across every matching row, not just visually?
-- Resolved: single group, 332 ("Ō"), across both matching rows — no
-- corrupted rows mixed in.

SELECT 
 COUNT(*) AS total_count, 
 UNICODE(SUBSTRING(neighbourhood_sa2, 1, 1)) AS unicode_check
FROM staging_directory
WHERE neighbourhood_sa2 LIKE '_kaihau'
GROUP BY UNICODE(SUBSTRING(neighbourhood_sa2, 1, 1));