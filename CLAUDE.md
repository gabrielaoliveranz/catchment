# CLAUDE.md — reglas de pie para CATCHMENT

Destiladas de bugs reales en Terroir y Apophenia (project_kickoff_checklist.md)
más las convenciones específicas de este proyecto. No son sugerencias.

## Contrato de aprendizaje (no negociable)

- Gaby escribe cada consulta SQL y cada medida DAX. Nunca consultas
  terminadas para copiar.
- Orden por etapa: exploración (la hace Gaby) → teoría → Gaby escribe →
  predicción antes de ejecutar → si está mal, explicar por qué antes de
  corregir → Gaby explica la consulta correcta con sus palabras.

## Rutas y estructura

- Un solo lugar define `PROJECT_ROOT`; todo lo demás deriva de ahí. Nunca
  hardcodear rutas absolutas de esta máquina en scripts, config o SQL.
- `data/raw/` y `data/processed/` están en `.gitignore`. Los crudos de
  Education Counts NO van al repo — son públicos y reproducibles. Cada
  fuente queda registrada en `docs/data_sources.md` con URL exacta y
  fecha de descarga.

## Git

- Commits separados para arreglos vs. features. Documentación aparte.
- No reescribir historia después de pushear.
- Git operado siempre desde la terminal local de Gaby, nunca desde el
  puente device_bash de esta sesión (el bridge no puede hacer unlink de
  archivos — deja `.git/index.lock` huérfano y puede corromper el repo).
- Un solo clone local. Nunca en carpeta sincronizada con OneDrive/Google
  Drive (riesgo de corrupción de `.git` durante escritura concurrente).

## Integridad de datos

- Verificar que una clave candidata es realmente única antes de usarla
  para join: `COUNT(*) = COUNT(DISTINCT key)`. Nunca asumir por el nombre.
- Nunca hardcodear un nombre de campo o código de categoría de memoria —
  confirmarlo contra una respuesta real de la fuente primero.
- Verificar el alcance geográfico/de dominio empíricamente (qué TAs
  componen Bay of Plenty–Waiariki), no asumirlo de la documentación.
- Clave de join siempre ASCII; todo lo que ve un lector lleva macrones.
  Nunca "arreglar" la clave agregándole el macrón — reintroduce la
  fragilidad. Cualquier export/UI nuevo bindeado directo a la clave se
  asume con este bug hasta que se revise.
- Una columna con un solo valor distinto es inútil — chequear
  cardinalidad por columna durante el perfilado.
- Un indicador de "presión de capacidad" es un proxy (matrícula actual
  vs. máximo histórico) porque la capacidad edilicia no es un dato
  público. Etiquetarlo como proxy en todas partes, siempre.
- decile → Equity Index (2023) es un cambio de definición a mitad de
  serie. Cortar la serie en el límite o usar una sola era, y decirlo.
- Etnia "total response" no suma al total (multi-conteo); "prioritised"
  sí. Elegir una, declararla, nunca sumar categorías de total response
  esperando llegar al 100%.
- Una escuela con matrícula en cero puede haberse fusionado, no vaciado
  — reconciliar siempre contra `school_status_history` antes de reportar
  "escuelas en caída".

## Verificación que verifica de verdad

- Confirmar contenido, no presencia. Que un archivo exista no significa
  que diga lo correcto.
- Re-correr cada chequeo después del cambio y leer la salida real — citar
  un chequeo de antes del cambio como si fuera la verificación final es
  una falla silenciosa.
- Un exit code limpio no es un resultado limpio.
- Un archivo guardado en una app GUI puede no estar guardado de verdad:
  cerrar y reabrir para confirmar antes de dar por hecho el cambio.

## Cifras y trazabilidad

- Toda cifra reportada nombra el script o consulta que la produce.
- La misma cifra en más de un lugar (README, reporte Power BI, LinkedIn,
  portfolio) diverge tarde o temprano — listar cada copia la primera vez
  que se duplica un número, y re-chequearlas todas cuando cambie la
  fuente.

## Estilo

- Ortografía en-NZ en todo texto en inglés (colour, analyse, organise,
  licence sustantivo, modelling).
- Español para explicaciones/instrucciones; código, nombres de archivo y
  contenido del proyecto en inglés.

## Tests

- Cualquier función lógica nueva (parsing, reconciliación de fusiones,
  cálculo de proxy) se testea en el mismo commit que la introduce.
- Los tests corren sobre fixtures chicas en memoria, nunca contra la DB
  real o los archivos descargados.
- Un bug encontrado en un cálculo obtiene un test de regresión que nombra
  el bug.
