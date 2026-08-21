# Methodology & limitations — CATCHMENT

Written as the project is built, not after. Each entry below was found
during exploration of the raw files, empirically — never assumed.

## Regional scope: Bay of Plenty–Waiariki

Confirmed against `data/raw/directory.csv`, `Education Region` column.

- **Exact value in the source:** `Bay of Plenty, Waiariki`
- **Territorial Authorities under it (7):** Kawerau District, Ōpōtiki
  District, Rotorua District, Taupo District, Tauranga City, Western Bay
  of Plenty District, Whakatane District.

This does **not** match the Bay of Plenty Regional Council boundary.
`Education Region` is a Ministry of Education administrative grouping
("Waiariki") that includes Rotorua and Taupo districts, which most
people would associate with Waikato, not Bay of Plenty. Filtering by
Regional Council instead of Education Region would have silently
dropped Rotorua and Taupo from the whole analysis.

**Decision:** scope this project to `Education Region = 'Bay of Plenty, Waiariki'`,
not to Regional Council.

## Known data quality issues (source, not ours)

- **`directory.csv` has a 16-row metadata preamble** before the real
  header (title, description, footnotes, and the Directory Builder's
  filter selections). Header is at row 17, data starts at row 18. Any
  load script needs to skip these rows explicitly, not assume row 1 is
  the header.
- **Macron usage in `directory.csv` is inconsistent.** Example: `Town /
  City` shows "Opotiki" (no macrons) for every row in that town, when
  the correct spelling is "Ōpōtiki". This is a source data quality issue,
  not something to hand-edit in the raw file — it will be corrected via
  a versioned lookup table at load time, not by editing `data/raw/`.
