
/****************************************************************************
 * Stored Procedures                                                        *
 ****************************************************************************/

DROP FUNCTION IF EXISTS lgd_tryparse_boolean(v TEXT);
CREATE FUNCTION lgd_tryparse_boolean(v TEXT) RETURNS BOOL AS
$$
DECLARE
BEGIN
    RETURN
        CASE
            WHEN (v ~* 'true'  OR v ~* 'yes' OR v = '1') THEN TRUE
            WHEN (v ~* 'false' OR v ~* 'no'  OR v = '0') THEN FALSE
            ELSE NULL
        END;
END;
$$
    LANGUAGE 'plpgsql'
    IMMUTABLE
    RETURNS NULL ON NULL INPUT;



DROP FUNCTION IF EXISTS lgd_tryparse_int(str TEXT);
CREATE FUNCTION lgd_tryparse_int(str TEXT) RETURNS INT8 AS
$$
DECLARE
BEGIN
    RETURN str::int8;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$
    LANGUAGE 'plpgsql'
    IMMUTABLE
    RETURNS NULL ON NULL INPUT;


DROP FUNCTION IF EXISTS lgd_tryparse_float(str TEXT);
CREATE FUNCTION lgd_tryparse_float(str TEXT) RETURNS FLOAT AS
$$
DECLARE
BEGIN
    RETURN str::float;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$
    LANGUAGE 'plpgsql'
    IMMUTABLE
    RETURNS NULL ON NULL INPUT;

/****************************************************************************
 * Mapping tables                                                           *
 ****************************************************************************/

-- TODO: Potentially can be removed
CREATE TABLE simple_polys (
    way_id BIGINT PRIMARY KEY NOT NULL,
    area float NOT NULL
);

-- TODO: Not Null constraint
SELECT AddGeometryColumn('simple_polys', 'polygon', 4326, 'GEOMETRY', 2);
CREATE INDEX idx_simple_polys_polygon ON simple_polys USING GIST(polygon);


DROP TYPE IF EXISTS lgd_datatype;
CREATE TYPE lgd_datatype AS ENUM ('boolean', 'int', 'float');


DROP TABLE IF EXISTS lgd_map_datatype;
CREATE TABLE lgd_map_datatype (
    k text PRIMARY KEY NOT NULL,
    datatype lgd_datatype NOT NULL
);

DROP INDEX IF EXISTS idx_lgd_map_datatype;
CREATE INDEX idx_lgd_map_datatype_k ON lgd_map_datatype(k);

DROP INDEX IF EXISTS idx_lgd_map_datatype_datatype;
CREATE INDEX idx_lgd_map_datatype_datatype ON lgd_map_datatype(datatype);

--DROP INDEX IF EXISTS idx_lgd_map_datatype_datatype;
--CREATE INDEX idx_lgd_map_datatype_datatype_k ON lgd_map_datatype(datatype, k);

DROP TABLE IF EXISTS lgd_map_literal;
CREATE TABLE lgd_map_literal (
    k text NOT NULL,
    property text NOT NULL,
    language text NOT NULL,

    /* Avoid duplicates */
    UNIQUE(k, property, language)
);

CREATE INDEX idx_lgd_map_literal_k ON lgd_map_literal(k);
CREATE INDEX idx_lgd_map_literal_property ON lgd_map_literal(property);
CREATE INDEX idx_lgd_map_literal_language ON lgd_map_literal(language);
--CREATE INDEX idx_lgd_map_literal_property_language ON lgd_map_literal(property, language);
--CREATE INDEX idx_lgd_map_literal_language_property ON lgd_map_literal(language, property);


DROP TABLE IF EXISTS lgd_map_label;
CREATE TABLE lgd_map_label (
    k TEXT NOT NULL,
    v TEXT NOT NULL,
    language VARCHAR(16) NOT NULL,
    label TEXT NOT NULL,

    /* Avoid duplicates */
    UNIQUE(k, v, language, label)
);

/* Index for searching by label */
CREATE INDEX idx_lgd_map_label_label ON lgd_map_label(label);
--CREATE INDEX idx_lgd_map_label_label_language ON lgd_map_label(label, language);

/* Index for searching by language */
CREATE INDEX idx_lgd_map_label_language ON lgd_map_label(language);
--CREATE INDEX idx_lgd_map_label_language_label ON lgd_map_label(language, label);

/* Index for joins on (k, v) */
CREATE INDEX idx_lgd_map_label_k ON lgd_map_label(k);
CREATE INDEX idx_lgd_map_label_v ON lgd_map_label(v);
--CREATE INDEX idx_lgd_map_label_k_v ON lgd_map_label(v, k);


DROP TABLE IF EXISTS lgd_map_resource_k;
CREATE TABLE lgd_map_resource_k (
    k text NOT NULL,
    property text NOT NULL,
    object text NOT NULL
);

CREATE INDEX idx_lgd_map_resource_k_k ON lgd_map_resource_k USING btree (k);
CREATE INDEX idx_lgd_map_resource_k_property ON lgd_map_resource_k USING btree (property);
CREATE INDEX idx_lgd_map_resource_k_object ON lgd_map_resource_k USING btree (object);
--CREATE INDEX idx_lgd_map_resource_k_property_object ON lgd_map_resource_k USING btree (property, object);
--CREATE INDEX idx_lgd_map_resource_k_object_property ON lgd_map_resource_k USING btree (object, property);



DROP TABLE IF EXISTS lgd_map_resource_kv;
CREATE TABLE lgd_map_resource_kv (
    k text NOT NULL,
    v text NOT NULL,
    property text NOT NULL,
    object text NOT NULL
);

/* Avoid multi column indexes */
CREATE INDEX idx_lgd_map_resource_kv_v ON lgd_map_resource_kv USING btree (v);
CREATE INDEX idx_lgd_map_resource_kv_k ON lgd_map_resource_kv USING btree (k);
CREATE INDEX idx_lgd_map_resource_kv_property ON lgd_map_resource_kv USING btree (property);
CREATE INDEX idx_lgd_map_resource_kv_object ON lgd_map_resource_kv USING btree (object);
/*
CREATE INDEX idx_lgd_map_resource_kv_v_k ON lgd_map_resource_kv USING btree (v, k);
CREATE INDEX idx_lgd_map_resource_kv_k_v ON lgd_map_resource_kv USING btree (k, v);
CREATE INDEX idx_lgd_map_resource_kv_property_object ON lgd_map_resource_kv USING btree (property, object);
CREATE INDEX idx_lgd_map_resource_kv_object_property ON lgd_map_resource_kv USING btree (object, property);
*/



CREATE TABLE lgd_map_resource_prefix (
    k text NOT NULL,
    property text NOT NULL,
--    object_prefix prefix_range NOT NULL,
    object_prefix text NOT NULL,
    post_processing text NOT NULL
);

--CREATE INDEX idx_lgd_map_resource_prefix_prefix ON lgd_map_resource_prefix USING gist (object_prefix);
CREATE INDEX idx_lgd_map_resource_prefix_prefix ON lgd_map_resource_prefix USING btree (object_prefix);
CREATE INDEX idx_lgd_map_resource_prefix_k ON lgd_map_resource_prefix USING btree (k);


CREATE TABLE lgd_map_property (
    k text NOT NULL,
    property text NOT NULL
);

CREATE INDEX idx_lgd_map_property_k ON lgd_map_property USING btree (k);
CREATE INDEX idx_lgd_map_property_property ON lgd_map_property USING btree (property);



CREATE VIEW lgd_resource_label AS
 SELECT b.object AS resource, a.label, a.language
   FROM lgd_map_label a
   JOIN lgd_map_resource_kv b USING (k, v);



/* Interlinks */
DROP TABLE IF EXISTS "lgd_interlinks";
CREATE TABLE "lgd_interlinks" (
        "source" text,

        "s" text NOT NULL,
        "o" text NOT NULL,

        "o_local_name" text,

        /* Avoid duplicates per source*/
        UNIQUE("s", "o", "source")
);

CREATE INDEX "idx_lgd_interlinks_s" ON "lgd_interlinks"("s");
CREATE INDEX "idx_lgd_interlinks_o" ON "lgd_interlinks"("o");


CREATE TABLE lgd_relation_geoms(
    relation_id BIGINT PRIMARY KEY NOT NULL
--    geom geometry NOT NULL
)
;

SELECT AddGeometryColumn('lgd_relation_geoms', 'geom', 4326, 'GEOMETRY', 2);
CREATE INDEX idx_lgd_relation_geoms_geom ON lgd_relation_geoms USING GIST(geom);
