--- Authors : Thomas André, Victor Bonnin, Jérémy Kalsron, Pierre Niogret, Bénédicte Thomas
--- License : GPLv3 or later

--- fonction pour le calcul du chemin le plus securise
CREATE OR REPLACE FUNCTION itineraire_secu (n1 numeric, n2 numeric, n3 numeric, n4 numeric)
    RETURNS TABLE (
        geojson json
    )
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        json_build_object('type', 'FeatureCollection', 'features', json_agg(json_build_object('type', 'Feature', 'geometry', ST_AsGeoJSON (b.the_geom)::json, 'properties', json_build_object('length', b.length_m, 'ida', b.ida)))) AS geojson
    FROM
        pgr_dijkstra ('
                 SELECT gid as id, source, target,
                         secu_cost_risk as cost, secu_reverse_cost_risk as reverse_cost FROM ways',
            (
                SELECT
                    ways_vertices_pgr.id
                FROM
                    ways_vertices_pgr,
                    st_distance ((ST_SetSRID (ST_MakePoint (n1, n2), 4326)), ways_vertices_pgr.the_geom)
                ORDER BY
                    st_distance ASC
                LIMIT 1),
            (
                SELECT
                    ways_vertices_pgr.id
                FROM
                    ways_vertices_pgr,
                    st_distance ((ST_SetSRID (ST_MakePoint (n3, n4), 4326)), ways_vertices_pgr.the_geom)
                ORDER BY
                    st_distance ASC
                LIMIT 1),
            TRUE) a
        INNER JOIN ways b ON (a.edge = b.gid);
END;
$$
LANGUAGE plpgsql;

---  fonction pour le calcul du chemin le plus amenage
CREATE OR REPLACE FUNCTION itineraire_amenag (n1 numeric, n2 numeric, n3 numeric, n4 numeric)
    RETURNS TABLE (
        geojson json
    )
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        json_build_object('type', 'FeatureCollection', 'features', json_agg(json_build_object('type', 'Feature', 'geometry', ST_AsGeoJSON (b.the_geom)::json, 'properties', json_build_object('length', b.length_m, 'ida', b.ida)))) AS geojson
    FROM
        pgr_dijkstra ('
                 SELECT gid as id, source, target,
                         amenag_cost_risk as cost, amenag_reverse_cost_risk as reverse_cost FROM ways',
            (
                SELECT
                    ways_vertices_pgr.id
                FROM
                    ways_vertices_pgr,
                    st_distance ((ST_SetSRID (ST_MakePoint (n1, n2), 4326)), ways_vertices_pgr.the_geom)
                ORDER BY
                    st_distance ASC
                LIMIT 1),
            (
                SELECT
                    ways_vertices_pgr.id
                FROM
                    ways_vertices_pgr,
                    st_distance ((ST_SetSRID (ST_MakePoint (n3, n4), 4326)), ways_vertices_pgr.the_geom)
                ORDER BY
                    st_distance ASC
                LIMIT 1),
            TRUE) a
        INNER JOIN ways b ON (a.edge = b.gid);
END;
$$
LANGUAGE plpgsql;

--- fonction pour le calcul du chemin le plus court
CREATE OR REPLACE FUNCTION itineraire_court (n1 numeric, n2 numeric, n3 numeric, n4 numeric)
    RETURNS TABLE (
        geojson json
    )
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        json_build_object('type', 'FeatureCollection', 'features', json_agg(json_build_object('type', 'Feature', 'geometry', ST_AsGeoJSON (b.the_geom)::json, 'properties', json_build_object('length', b.length_m, 'ida', b.ida)))) AS geojson
    FROM
        pgr_dijkstra ('
                 SELECT gid as id, source, target,
                         court_cost_risk as cost, court_reverse_cost_risk as reverse_cost FROM ways',
            (
                SELECT
                    ways_vertices_pgr.id
                FROM
                    ways_vertices_pgr,
                    st_distance ((ST_SetSRID (ST_MakePoint (n1, n2), 4326)), ways_vertices_pgr.the_geom)
                ORDER BY
                    st_distance ASC
                LIMIT 1),
            (
                SELECT
                    ways_vertices_pgr.id
                FROM
                    ways_vertices_pgr,
                    st_distance ((ST_SetSRID (ST_MakePoint (n3, n4), 4326)), ways_vertices_pgr.the_geom)
                ORDER BY
                    st_distance ASC
                LIMIT 1),
            TRUE) a
        INNER JOIN ways b ON (a.edge = b.gid);
END;
$$
LANGUAGE plpgsql;

--- fonction pour le calcul du chemin utilisateur
CREATE OR REPLACE FUNCTION itineraire_perso (n1 numeric, n2 numeric, n3 numeric, n4 numeric, n5 numeric, n6 numeric, n7 numeric)
    RETURNS TABLE (
        geojson json
    )
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        json_build_object('type', 'FeatureCollection', 'features', json_agg(json_build_object('type', 'Feature', 'geometry', ST_AsGeoJSON (b.the_geom)::json, 'properties', json_build_object('length', b.length_m, 'ida', b.ida)))) AS geojson
    FROM
        pgr_dijkstra ('
                 SELECT gid as id, source, target,
                         ((qualite_route_recodee*' || n5 || '+vitesse_recode*' || n6 || '+qualite_cyclable_recodee*' || n7 || ')/(1/(length_m+1))) as cost, ((qualite_route_recodee*' || n5 || '+vitesse_recode*' || n6 || '+qualite_cyclable_recodee_reverse*' || n7 || ')/(1/(length_m+1))) as reverse_cost FROM ways',
            (
                SELECT
                    ways_vertices_pgr.id
                FROM
                    ways_vertices_pgr,
                    st_distance ((ST_SetSRID (ST_MakePoint (n1, n2), 4326)), ways_vertices_pgr.the_geom)
                ORDER BY
                    st_distance ASC
                LIMIT 1),
            (
                SELECT
                    ways_vertices_pgr.id
                FROM
                    ways_vertices_pgr,
                    st_distance ((ST_SetSRID (ST_MakePoint (n3, n4), 4326)), ways_vertices_pgr.the_geom)
                ORDER BY
                    st_distance ASC
                LIMIT 1),
            TRUE) a
        INNER JOIN ways b ON (a.edge = b.gid);
END;
$$
LANGUAGE plpgsql;

--- fonction de récupération d'entités dont certains attributs sont manquants
CREATE OR REPLACE FUNCTION contrib_items (n1 numeric, n2 numeric, n3 numeric, n4 numeric, _arr varchar[], n5 numeric)
    RETURNS TABLE (
        geojson json
    )
    AS $$
BEGIN
    RETURN QUERY WITH aa AS (
        SELECT
            osm_id,
            the_geom
        FROM
            ways
        WHERE
            ways.the_geom && st_makeenvelope (n1,
                n2,
                n3,
                n4,
                4326)
            AND NOT tags ?& ARRAY[_arr]
        ORDER BY
            random()
        LIMIT (n5))
SELECT
    json_build_object('type', 'FeatureCollection', 'features', json_agg(json_build_object('type', 'Feature', 'geometry', ST_AsGeoJSON (aa.the_geom)::json, 'properties', json_build_object('osm_id', aa.osm_id)))) AS geojson
FROM
    aa;
END;
$$
LANGUAGE plpgsql;

--- fonction utilitaire pour convertir une chaîne de caractères en entier
CREATE OR REPLACE FUNCTION stoi (s text)
    RETURNS integer
    AS $BODY$
    SELECT
        CASE WHEN trim(s)
        SIMILAR TO '[0-9]+' THEN
            CAST(trim(s) AS integer)
        ELSE
            NULL
        END;

$BODY$
LANGUAGE 'sql'
IMMUTABLE STRICT;
