# CATCHMENT — plan del proyecto

**Pregunta:** ¿Dónde en Bay of Plenty–Waiariki está la capacidad escolar
bajo presión, y dónde está sobrando?

**Alcance:** mediano, 2–3 semanas. Ángulo: capacidad de la red.

**Por qué este proyecto:** tapa los tres huecos del portfolio actual —
SQL como protagonista, Power BI como entregable visible, y un dominio
que no es kiwi. Y es literalmente el trabajo del puesto de Network
Analyst del Ministerio de Educación al que te postulaste.

**El nombre** es una propuesta: *catchment* es el término real del
dominio (el área de la que una escuela toma sus alumnos), y rima con
Terroir — los dos hablan de territorio y de qué puede sostener. Cambialo
si se te ocurre algo mejor.

---

## 1. Fuentes de datos (verificadas el 19/08/2026)

Todas públicas, todas del Ministerio de Educación vía Education Counts.

| Fuente | Formato | Para qué |
|---|---|---|
| [Directorio de escuelas NZ](https://www.educationcounts.govt.nz/directories/list-of-nz-schools) | CSV + [API](https://www.educationcounts.govt.nz/directories/school-directory-api) | `dim_school`: tipo, autoridad, sector, TA, región, coordenadas, matrícula actual |
| [Matrícula por escuela 2010–2025](https://www.educationcounts.govt.nz/statistics/school-rolls/downloads/2-Student-rolls-by-school-2010-2025-v2.xlsx) | xlsx, 16 MB | Serie de 16 años, escuela por escuela — el corazón del análisis |
| [Matrícula por año de escolaridad y etnia 2014–2025](https://www.educationcounts.govt.nz/__data/assets/file/0006/195360/10-Machine-readable-Roll-by-funding-year-level-ethnicity-2014-2025.zip) | CSV comprimido | Grano fino: año de escolaridad × etnia |
| [Fusiones, cierres y aperturas](https://www.educationcounts.govt.nz/directories/6136) | tabla | Corregir series que "caen a cero" por cambio de límites, no por caída real |
| [Proyecciones nacionales de matrícula](https://www.educationcounts.govt.nz/statistics/national-school-roll-projection) | — | Contexto y comparación. **No competir con esto** — citarlo |
| [Servicios de educación temprana](https://www.educationcounts.govt.nz/directories/early-childhood-services-directory-api) | API | Opcional: los ECE de hoy son la primaria de mañana |

**Dato útil:** los tableros del propio Education Counts están hechos en
Power BI. Vas a usar la misma herramienta que ellos.

---

## 2. Base de datos

**Motor recomendado: SQL Server Express** (gratis). Dos razones: Power BI
se conecta de forma nativa sin drivers extra, y el stack Microsoft es muy
común en el sector público neozelandés. Verificalo vos misma en los
avisos que estás leyendo todos los días — fijate si dicen "SQL Server",
"T-SQL" o "PostgreSQL", y elegí en base a eso, no a mi opinión.

*Alternativa:* PostgreSQL, si preferís seguir con lo que ya conocés. El
diseño de abajo no cambia.

### Esquema estrella

```
fact_roll
  school_id        FK -> dim_school
  year_id          FK -> dim_year
  year_level_id    FK -> dim_year_level
  ethnicity_id     FK -> dim_ethnicity
  headcount        INT NOT NULL
  PK (school_id, year_id, year_level_id, ethnicity_id)

dim_school       school_id (nro MoE), name, name_ascii, type, sector,
                 authority, ta, education_region, lat, lon, eqi, decile
dim_year         year, is_decile_era, is_eqi_era
dim_year_level   funding_year_level, sector
dim_ethnicity    code, label, basis ('total_response' | 'prioritised')
dim_area         ta, education_region, regional_council

school_status_history
                 school_id, event_date, event_type (open/close/merge),
                 successor_school_id
```

### Reglas que no son opcionales

- **Verificá empíricamente que `school_id` es único** antes de usarlo
  como clave: `COUNT(*) = COUNT(DISTINCT school_id)`. No lo asumas
  porque se llame "id" — en Terroir `parcel_id` no lo era.
- **`name` con macrones, `name_ascii` para filtros.** Nunca al revés.
- **Claves foráneas e índices declarados**, no implícitos. La gracia de
  este proyecto es mostrar cómo se construye la base, así que el DDL es
  parte del entregable, no un medio.
- **Todo el DDL versionado en el repo** (`sql/01_schema.sql`, etc.),
  reproducible desde cero.

---

## 3. Las cuatro trampas del dataset

Esto es lo que distingue el proyecto. Cada una va documentada en
`METHODOLOGY.md` **y** en una página del reporte.

**1. Decile → Equity Index (2023).** El decile dejó de usarse para
reportar después de 2022; lo reemplazó el Equity Index. Son escalas
distintas. Una serie temporal que los mezcle miente. Decisión: cortar la
serie, o usar una sola era y decirlo.

**2. Etnia: "total response" vs "prioritised".** En *total response* un
alumno que se identifica como Māori y Asiático se cuenta en las dos, así
que las categorías no suman al total. En *prioritised* se cuenta una sola
vez, en el orden Māori → Pacific → Asian → MELAA → resto. El Ministerio
dice que *total response* es la forma preferida de reportar. Elegí una,
declarala, y **nunca sumes las categorías de total response** esperando
llegar al total.

**3. Fusiones y cierres.** Una escuela cuya matrícula cae a cero puede
haberse fusionado, no vaciado. Sin la tabla de estado, un análisis de
"escuelas en caída" va a estar lleno de falsos positivos. Hay que
reconciliar la serie con `school_status_history`.

**4. Capacidad no es un dato público.** Education Counts publica
matrícula, no capacidad edilicia. **Confirmá esto antes de escribir una
sola línea sobre "presión de capacidad".** Si no está publicada, tu
indicador es un *proxy* — por ejemplo la matrícula actual contra el
máximo histórico de esa misma escuela — y tiene que estar etiquetado como
proxy en todas partes, igual que las "projection bands" de Apophenia. No
lo llames capacidad si no lo medís.

**Bonus, ya sabés cómo termina:** el dataset está lleno de macrones —
Ōtūmoetai, Whakatāne, Ōpōtiki, Te Kura Kaupapa Māori o Te Kura Kokiri.
Y hay que confirmar contra el directorio **qué autoridades territoriales
componen exactamente la región Bay of Plenty–Waiariki**, en vez de
asumirlas. Un filtro de lugar mal armado ya te borró un distrito entero
una vez.

---

## 4. Análisis en SQL (window functions)

El punto es mostrar SQL de verdad, no `SELECT *`.

1. **Variación interanual por escuela** — `LAG()` sobre año
2. **Progresión de cohortes** — los de Year 5 en 2020 contra los de
   Year 6 en 2021: cuánto retiene cada escuela y cuánto se fuga
3. **Ranking dentro de cada TA** —
   `RANK() OVER (PARTITION BY ta ORDER BY growth DESC)`
4. **Media móvil de 3 años** para suavizar el ruido anual
5. **Participación de cada escuela en la matrícula de su TA** —
   `SUM() OVER (PARTITION BY ta, year)`
6. **Señal de presión** — matrícula actual contra el máximo histórico de
   la propia escuela (el proxy del punto 4 de arriba)

---

## 5. Reporte en Power BI

Cinco páginas:

1. **Overview** — tendencia regional, cantidad de escuelas, mayores
   subidas y bajadas
2. **Mapa** — escuelas coloreadas por crecimiento, usando lat/lon del
   directorio
3. **Detalle de escuela** — drill-through: 16 años de matrícula, mezcla
   por año de escolaridad
4. **Flujo de cohortes** — cómo avanza una cohorte por los niveles
5. **Método y limitaciones** — una página real dentro del reporte, no un
   pie de página. Casi nadie hace esto, y es lo que más te va a
   diferenciar

Medidas en DAX explícitas y nombradas, no columnas calculadas
improvisadas. Y macrones en todo lo que ve el lector; ASCII solo en las
claves.

---

## 6. Plan por semanas

**Semana 1 — datos y base**
- Descargar las fuentes, registrar fecha y URL de cada una
- Confirmar la lista real de TAs de Bay of Plenty–Waiariki
- Escribir el DDL, cargar, y correr los chequeos de integridad
- Reconciliar fusiones y cierres

**Semana 2 — análisis y reporte**
- Las seis consultas SQL, cada una en su archivo y documentada
- Construir el reporte en Power BI sobre esas vistas
- Escribir la página de método y limitaciones *mientras* construís, no
  al final

**Semana 3 — publicación**
- `README.md` y `METHODOLOGY.md`
- Repo público en GitHub, con el `.pbix` y capturas
- Agregarlo a gabrielaolivera.nz y a LinkedIn

---

## 7. Antes de empezar, tres decisiones

1. **Motor de base de datos** — mirá tres avisos de los que te
   interesan y fijate qué piden
2. **Dónde vive el repo** — OneDrive como Terroir, o Google Drive como
   Apophenia
3. **El nombre** — CATCHMENT es una propuesta, no una decisión
