-- 🔹 Reemplaza USR_ADMIN por el usuario que estás habilitando en ORDS
GRANT INHERIT PRIVILEGES ON USER ORDS_METADATA TO USR_ADMIN;
GRANT INHERIT PRIVILEGES ON USER ORDS_PUBLIC_USER TO USR_ADMIN;

GRANT CREATE SESSION TO USR_ADMIN;
GRANT CREATE PROCEDURE TO USR_ADMIN;
GRANT CREATE TABLE TO USR_ADMIN;
GRANT CREATE VIEW TO USR_ADMIN;
GRANT CREATE SEQUENCE TO USR_ADMIN;

BEGIN
    ORDS.enable_schema(
        p_enabled => TRUE,
        p_schema  => 'USR_ADMIN',  -- cambia por tu usuario
        p_url_mapping_pattern => 'academico',
        p_auto_rest_auth => TRUE
    );
    COMMIT;
END;
/