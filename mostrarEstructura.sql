SELECT 
    utc.table_name,
    utc.column_name,
    utc.data_type,
    utc.data_length,
    utc.data_precision,
    utc.data_scale,
    utc.nullable,
    (
      SELECT 'PK'
      FROM user_constraints pk
      JOIN user_cons_columns pkk ON pk.constraint_name = pkk.constraint_name
      WHERE pk.constraint_type = 'P'
        AND pk.table_name = utc.table_name
        AND pkk.column_name = utc.column_name
    ) AS primary_key
FROM user_tab_columns utc
ORDER BY utc.table_name, utc.column_id;

SELECT 
    c.constraint_name,
    c.table_name AS tabla_hija,
    cc.column_name AS columna_hija,
    c_r.table_name AS tabla_padre,
    cc_r.column_name AS columna_padre
FROM user_constraints c
JOIN user_cons_columns cc
  ON c.constraint_name = cc.constraint_name
JOIN user_constraints c_r
  ON c.r_constraint_name = c_r.constraint_name
JOIN user_cons_columns cc_r
  ON c_r.constraint_name = cc_r.constraint_name
WHERE c.constraint_type = 'R'
ORDER BY tabla_hija, constraint_name;

SELECT
    ui.index_name,
    ui.table_name,
    uic.column_name,
    ui.uniqueness
FROM user_indexes ui
JOIN user_ind_columns uic
  ON ui.index_name = uic.index_name
ORDER BY ui.table_name, ui.index_name, uic.column_position;

SELECT 
    uc.constraint_name,
    uc.constraint_type,
    uc.table_name,
    ucc.column_name,
    uc.search_condition
FROM user_constraints uc
LEFT JOIN user_cons_columns ucc
  ON uc.constraint_name = ucc.constraint_name
ORDER BY uc.table_name, uc.constraint_type, uc.constraint_name;

SELECT 
    t.table_name,
    LISTAGG(c.constraint_type, ', ') WITHIN GROUP (ORDER BY c.constraint_type) AS constraints
FROM user_tables t
LEFT JOIN user_constraints c ON t.table_name = c.table_name
GROUP BY t.table_name
ORDER BY t.table_name;

SELECT
    c.table_name || '.' || cc.column_name AS hijo,
    ' → ' AS relación,
    c_r.table_name || '.' || cc_r.column_name AS padre,
    c.constraint_name AS fk
FROM user_constraints c
JOIN user_cons_columns cc   ON c.constraint_name = cc.constraint_name
JOIN user_constraints c_r   ON c.r_constraint_name = c_r.constraint_name
JOIN user_cons_columns cc_r ON c_r.constraint_name = cc_r.constraint_name
WHERE c.constraint_type = 'R'
ORDER BY hijo;

WITH x AS (
    SELECT DBMS_XMLGEN.getxmltype(
             'SELECT table_name, column_name, data_default FROM user_tab_cols'
           ) AS xml
    FROM dual
)
SELECT 
    EXTRACTVALUE(VALUE(t), '/ROW/TABLE_NAME') AS table_name,
    EXTRACTVALUE(VALUE(t), '/ROW/COLUMN_NAME') AS column_name,
    EXTRACTVALUE(VALUE(t), '/ROW/DATA_DEFAULT') AS data_default
FROM x,
     TABLE(XMLSEQUENCE(EXTRACT(x.xml, '/ROWSET/ROW'))) t
WHERE EXTRACTVALUE(VALUE(t), '/ROW/DATA_DEFAULT') LIKE '%ISEQ$%'
ORDER BY table_name, column_name;

SELECT *
FROM ACADEMICO.ESTUDIANTE;

SELECT cols.table_name, cols.column_name, cons.constraint_name
FROM user_constraints cons
JOIN user_cons_columns cols ON cons.constraint_name = cols.constraint_name
WHERE cons.constraint_type = 'P'
ORDER BY cols.table_name;

SELECT a.constraint_name, a.table_name, a.column_name,
       c_pk.table_name r_table_name, c_pk.column_name r_column_name
FROM user_cons_columns a
JOIN user_constraints c ON a.constraint_name = c.constraint_name
JOIN user_cons_columns c_pk ON c.r_constraint_name = c_pk.constraint_name
WHERE c.constraint_type = 'R'
ORDER BY a.table_name;

SELECT index_name, table_name, uniqueness
FROM user_indexes;
SELECT index_name, column_name, column_position
FROM user_ind_columns;








