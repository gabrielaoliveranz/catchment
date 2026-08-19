# Data sources — CATCHMENT

Registered 2026-08-19 (NZ time). Ministry of Education, via Education Counts.

| # | Source | URL | Status | Local path |
|---|---|---|---|---|
| 1 | Student rolls by school, 2010–2025 | https://www.educationcounts.govt.nz/statistics/school-rolls/downloads/2-Student-rolls-by-school-2010-2025-v2.xlsx | On Gaby's machine (Downloads root), pending move into `data/raw/` | `data/raw/2-Student-rolls-by-school-2010-2025-v2.xlsx` |
| 2 | Roll by funding year level & ethnicity, 2014–2025 | https://www.educationcounts.govt.nz/__data/assets/file/0006/195360/10-Machine-readable-Roll-by-funding-year-level-ethnicity-2014-2025.zip | Not yet downloaded | — |
| 3 | NZ schools directory | Builder UI: https://www.educationcounts.govt.nz/directories/list-of-nz-schools — click "Download the whole directory" → export CSV. API base `https://catalogue.data.govt.nz/api/3/action/datastore_search_sql`, resource_id `4b292323-9fcc-41f8-814b-3c7b19cf14b3` | Not yet downloaded | — |
| 4a | School closures/mergers/new schools, 2026 | https://www.educationcounts.govt.nz/directories/6136/School-closures-mergers-and-new-March-2026.xlsx | Not yet downloaded | — |
| 4b | School closures/mergers/new schools, 2004–2025 (historical) | https://www.educationcounts.govt.nz/__data/assets/file/0012/198957/school-mergers-closures-new-schools.zip | Not yet downloaded | — |
| 5 | National school roll projections | https://www.educationcounts.govt.nz/statistics/national-school-roll-projection | Context only — no competir, citar | — |

## Motor de base de datos

Confirmado 2026-08-19: SQL Server 17.0.1000.7 corriendo en `localhost`
(instancia `Gaby86\gabyg`), verificado conectando desde Azure Data Studio.

## Nota sobre cómo se registraron las URLs 2–4b

El contenedor cloud de esta sesión no tiene salida de red directa a
educationcounts.govt.nz ni a catalogue.data.govt.nz (confirmado con `curl`:
`HTTP 000`, timeout — solo hay allowlist para registries de paquetes tipo
npm). Las URLs de 2, 4a y 4b se obtuvieron vía WebFetch (que corre en
infraestructura de Anthropic, no en este contenedor) leyendo el HTML de las
páginas de Education Counts y extrayendo los `href` literales. No están
verificadas por descarga real todavía — Gaby las confirma al bajarlas.

Pendiente: hash SHA256 y tamaño de cada archivo, a completar cuando estén
descargados.
