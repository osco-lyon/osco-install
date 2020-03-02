--- Authors : Thomas André, Victor Bonnin, Jérémy Kalsron, Pierre Niogret, Bénédicte Thomas
--- License : GPLv3 or later

-- création des routes nettoyées
CREATE TABLE ways_clean AS
WITH ways_comp AS (
    SELECT
        ways.*,
        osm_ways.tags
    FROM
        ways
    LEFT JOIN osm_ways ON ways.osm_id = osm_ways.osm_id
)
SELECT
    *
FROM
    ways_comp
WHERE
    tags -> 'highway' NOT IN (
        'footway', 'pedestrian')
    OR exist (
        tags,
        'bicycle'
);

--- remplacement de la table ways par ways_clean
DROP TABLE ways;

ALTER TABLE ways_clean RENAME TO ways;

--- création des index des routes nettoyées ---
CREATE INDEX ways_pkey ON ways USING btree (gid);

CREATE INDEX ways_the_geom_idx ON ways USING gist (the_geom);

--- création des vertices des routes nettoyées ---
CREATE TABLE ways_clean_vertices_pgr AS
SELECT
    v.*
FROM
    ways_vertices_pgr v,
    ways c
WHERE
    st_touches (v.the_geom, c.the_geom);

--- remplacement de la table ways_vertices_pgr par ways_clean_vertices_pgr
DROP TABLE ways_vertices_pgr;

ALTER TABLE ways_clean_vertices_pgr RENAME TO ways_vertices_pgr;

--- création des index des vertices des routes nettoyées ---
CREATE INDEX ways_vertices_pgr_pkey ON ways_vertices_pgr USING btree (id);

CREATE INDEX ways_vertices_pgr_the_geom_idx ON ways_vertices_pgr USING gist (the_geom);

--- suppression des tables inutiles ---
DROP TABLE osm_nodes;

DROP TABLE osm_ways;

DROP TABLE osm_relations;

DROP TABLE pointsofinterest;

