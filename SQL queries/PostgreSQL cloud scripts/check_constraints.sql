-- check_constraints.sql
-- Schema to inspect
SET search_path TO fitness;

-----------------------------
-- 1) Primary keys (all)
-----------------------------
SELECT
  c.conname          AS constraint_name,
  c.conrelid::regclass AS table_name,
  'PRIMARY KEY'      AS type,
  pg_get_constraintdef(c.oid) AS definition
FROM pg_constraint c
JOIN pg_class t ON t.oid = c.conrelid
JOIN pg_namespace n ON n.oid = t.relnamespace
WHERE c.contype = 'p'
  AND n.nspname = 'fitness'
ORDER BY table_name, constraint_name;

-----------------------------
-- 2) Foreign keys (all)
-----------------------------
SELECT
  c.conname            AS constraint_name,
  c.conrelid::regclass AS table_name,
  'FOREIGN KEY'        AS type,
  pg_get_constraintdef(c.oid) AS definition
FROM pg_constraint c
JOIN pg_class t ON t.oid = c.conrelid
JOIN pg_namespace n ON n.oid = t.relnamespace
WHERE c.contype = 'f'
  AND n.nspname = 'fitness'
ORDER BY table_name, constraint_name;

-----------------------------
-- 3) Check constraints (all)
-----------------------------
SELECT
  c.conname            AS constraint_name,
  c.conrelid::regclass AS table_name,
  'CHECK'              AS type,
  pg_get_constraintdef(c.oid) AS definition
FROM pg_constraint c
JOIN pg_class t ON t.oid = c.conrelid
JOIN pg_namespace n ON n.oid = t.relnamespace
WHERE c.contype = 'c'
  AND n.nspname = 'fitness'
ORDER BY table_name, constraint_name;

-----------------------------
-- 4) NOT NULL columns (all)
-----------------------------
SELECT
  table_schema,
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'fitness'
  AND is_nullable = 'NO'
ORDER BY table_name, ordinal_position;

-----------------------------
-- 5) Indexes (all, incl. PK/unique)
-----------------------------
SELECT
  n.nspname      AS schema_name,
  t.relname      AS table_name,
  i.relname      AS index_name,
  pg_relation_size(i.oid) AS index_size_bytes,
  pg_get_indexdef(ix.indexrelid) AS index_def,
  ix.indisunique AS is_unique,
  ix.indisprimary AS is_primary
FROM pg_index ix
JOIN pg_class i ON i.oid = ix.indexrelid
JOIN pg_class t ON t.oid = ix.indrelid
JOIN pg_namespace n ON n.oid = t.relnamespace
WHERE n.nspname = 'fitness'
ORDER BY table_name, is_primary DESC, is_unique DESC, index_name;

-----------------------------
-- 6) Quick FK coverage check:
--    Shows FK columns that *lack* an index (recommended to index).
-----------------------------
WITH fk_cols AS (
  SELECT
    c.conrelid::regclass AS table_name,
    a.attname             AS column_name,
    (SELECT array_agg(attname ORDER BY attnum)
     FROM pg_attribute
     WHERE attrelid = c.conrelid
       AND attnum = ANY (SELECT unnest(conkey) FROM pg_constraint WHERE oid = c.oid)
       AND attnum > 0) AS fk_cols
  FROM pg_constraint c
  JOIN pg_class t ON t.oid = c.conrelid
  JOIN pg_namespace n ON n.oid = t.relnamespace
  JOIN pg_attribute a ON a.attrelid = t.oid
  WHERE c.contype = 'f'
    AND n.nspname = 'fitness'
    AND a.attnum = ANY (SELECT unnest(conkey) FROM pg_constraint WHERE oid = c.oid)
),
idx_cols AS (
  SELECT
    t.relname AS table_name,
    array_agg(pg_get_indexdef(i.indexrelid)) AS index_defs
  FROM pg_index i
  JOIN pg_class t ON t.oid = i.indrelid
  JOIN pg_namespace n ON n.oid = t.relnamespace
  WHERE n.nspname = 'fitness'
  GROUP BY t.relname
)
SELECT
  f.table_name,
  f.fk_cols AS fk_columns,
  CASE
    WHEN EXISTS (
      SELECT 1
      FROM unnest(f.fk_cols) AS fk_col
      WHERE NOT EXISTS (
        SELECT 1
        FROM idx_cols ic
        WHERE ic.table_name::text = f.table_name::text
          AND EXISTS (
            SELECT 1
            FROM unnest(ic.index_defs) AS idef
            WHERE idef ILIKE '%' || fk_col || '%'
          )
      )
    )
    THEN '⚠️ missing index for some FK column(s)'
    ELSE 'OK (indexes likely present)'
  END AS fk_index_coverage_hint
FROM fk_cols f
LEFT JOIN idx_cols i ON i.table_name::text = f.table_name::text
GROUP BY f.table_name, f.fk_cols
ORDER BY f.table_name;
