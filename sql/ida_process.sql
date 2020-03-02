--- Authors : Thomas André, Victor Bonnin, Jérémy Kalsron, Pierre Niogret, Bénédicte Thomas
--- License : GPLv3 or later

--- import des données pour la qualité des routes ---
ALTER TABLE ways
    ADD COLUMN qualite_route_recodee double precision;

UPDATE
    ways
SET
    qualite_route_recodee = (
        CASE WHEN (tags -> 'surface' = 'paved') THEN
            0.4
        WHEN (tags -> 'surface' = 'asphalt') THEN
            0.1
        WHEN (tags -> 'surface' = 'concrete') THEN
            0.1
        WHEN (tags -> 'surface' = 'concrete:lanes') THEN
            0.2
        WHEN (tags -> 'surface' = 'concrete:plates') THEN
            0.2
        WHEN (tags -> 'surface' = 'paving_stones') THEN
            0.3
        WHEN (tags -> 'surface' = 'sett') THEN
            0.4
        WHEN (tags -> 'surface' = 'unhewn_cobblestone') THEN
            0.7
        WHEN (tags -> 'surface' = 'cobblestone') THEN
            0.6
        WHEN (tags -> 'surface' = 'metal') THEN
            0.4
        WHEN (tags -> 'surface' = 'wood') THEN
            0.4
        WHEN (tags -> 'surface' = 'unpaved') THEN
            0.6
        WHEN (tags -> 'surface' = 'compacted') THEN
            0.4
        WHEN (tags -> 'surface' = 'fine_gravel') THEN
            0.4
        WHEN (tags -> 'surface' = 'gravel') THEN
            0.7
        WHEN (tags -> 'surface' = 'pebblestone') THEN
            0.7
        WHEN (tags -> 'surface' = 'dirt') THEN
            0.5
        WHEN (tags -> 'surface' = 'earth') THEN
            0.6
        WHEN (tags -> 'surface' = 'grass') THEN
            0.6
        WHEN (tags -> 'surface' = 'grass_paver') THEN
            0.6
        WHEN (tags -> 'surface' = 'ground') THEN
            0.5
        WHEN (tags -> 'surface' = 'mud') THEN
            0.8
        WHEN (tags -> 'surface' = 'sand') THEN
            0.9
        WHEN (tags -> 'surface' = 'woodchips') THEN
            0.8
        WHEN (tags -> 'surface' = 'snow') THEN
            0.9
        WHEN (tags -> 'surface' = 'ice') THEN
            0.9
        WHEN (tags -> 'surface' = 'salt') THEN
            0.7
        WHEN (tags -> 'surface' = 'clay') THEN
            0.7
        WHEN (tags -> 'surface' = 'tartan') THEN
            0.7
        WHEN (tags -> 'surface' = 'artificial_turf') THEN
            0.5
        WHEN (tags -> 'surface' = 'decoturf') THEN
            0.5
        WHEN (tags -> 'surface' = 'metal_grid') THEN
            0.5
        WHEN (tags -> 'surface' = 'carpet') THEN
            0.5
        ELSE
            0.1
        END);

--- Ajout d'une colonne pour recoder la vitesse en classe ---
ALTER TABLE ways
    ADD COLUMN vitesse_recode double precision;

UPDATE
    ways
SET
    vitesse_recode = (
        CASE WHEN stoi (tags -> 'maxspeed') BETWEEN 0 AND 30 THEN
            0.1
        WHEN stoi (tags -> 'maxspeed') BETWEEN 30 AND 51 THEN
            0.2
        WHEN stoi (tags -> 'maxspeed') BETWEEN 51 AND 70 THEN
            0.6
        WHEN stoi (tags -> 'maxspeed') BETWEEN 70 AND 80 THEN
            0.7
        WHEN stoi (tags -> 'maxspeed') BETWEEN 80 AND 130 THEN
            100
        ELSE
            CASE WHEN tags -> 'highway' IN ('path',
                'pedestrian',
                'footway')
                OR (tags -> 'highway' = 'cycleway') THEN
                0.1
            ELSE
                0.6
            END
        END);

--- ajout du nombre d'intersection ---
ALTER TABLE ways
    ADD COLUMN nintersect double precision;

WITH intersections AS (
    SELECT
        count(*),
        b.gid ---, b.the_geom ---
    FROM
        ways AS b,
        ways AS bp
    WHERE
        b.the_geom && bp.the_geom
        AND st_touches (b.the_geom,
            bp.the_geom)
    GROUP BY
        b.gid)
UPDATE
    ways
SET
    nintersect = count
FROM
    intersections
WHERE
    intersections.gid = ways.gid;

--- import des données pour le type des voies cyclables ---
ALTER TABLE ways
    ADD COLUMN qualite_cyclable_recodee double precision,
	ADD COLUMN qualite_cyclable_recodee_reverse double precision;

UPDATE
    ways
SET
    qualite_cyclable_recodee = (
        CASE WHEN (tags -> 'highway' = 'cycleway')
            OR (tags -> 'cycleway' = 'track')
            OR (tags -> 'cycleway:right' = 'track')
            OR (tags -> 'bicycle' IN ('designated',
                    'permissive',
                    'yes')
                AND tags -> 'highway' IN ('path',
                    'pedestrian',
                    'service',
                    'footway')) THEN
            0.1 --- Pistes cyclables ---
        WHEN (tags -> 'cycleway' IN ('lane',
                'shared_lane'))
            OR (tags -> 'cycleway:right' LIKE '%lane%') THEN
            0.3 --- Bandes cyclables ---
        WHEN (tags -> 'cycleway' LIKE '%bus%')
            OR (tags -> 'cycleway:right' LIKE '%bus%') THEN
            0.2 --- Voies de bus partagées ---
        WHEN (tags -> 'bicycle' = 'dismount') THEN
            0.4 --- Chemin pied à terre ---
        ELSE
            0.5 --- Routes ---
        END),
	qualite_cyclable_recodee_reverse = (
        CASE WHEN (tags -> 'highway' = 'cycleway'
            AND exist (tags,
                'oneway')
            AND tags -> 'oneway' != 'yes')
            OR (tags -> 'highway' = 'cycleway'
                AND NOT exist (tags,
                    'oneway'))
            OR (tags -> 'cycleway:left' LIKE '%track%')
            OR (tags -> 'cycleway' = 'opposite_track')
            OR (tags -> 'bicycle' IN ('designated',
                    'permissive',
                    'yes')
                AND tags -> 'highway' IN ('path',
                    'pedestrian',
                    'service',
                    'footway')) THEN
            0.1 --- Piste cyclable ---
        WHEN (tags -> 'cycleway:left' LIKE '%lane%')
            OR (tags -> 'cycleway:left' LIKE '%opposite%')
            OR (tags -> 'cycleway' IN ('opposite',
                    'opposite_lane')) THEN
            0.7 --- Bande cyclable ---
        WHEN (tags -> 'cycle:left' LIKE '%bus%') THEN
            0.2 --- Voies de bus partagées  ---
        WHEN (tags -> 'bicycle' = 'dismount') THEN
            0.3 --- Chemin en pied à terre ---
        ELSE
            CASE WHEN (exist (tags,
                    'oneway:bicycle')
                AND tags -> 'oneway:bicycle' != 'yes')
                OR (exist (tags,
                        'oneway')
                    AND tags -> 'oneway' != 'yes')
                OR (NOT exist (tags,
                        'oneway')
                    AND NOT exist (tags,
                        'oneway:bicycle')) THEN
                0.5
            ELSE
                99999
            END --- Les autres ---
        END);

--- Gestion des rond-points ---
UPDATE
    ways
SET
    qualite_cyclable_recodee_reverse = (
        CASE WHEN (tags -> 'junction' = 'roundabout') THEN
            99999
        ELSE
            qualite_cyclable_recodee_reverse
        END);

--- Creation du champs IDA pour la carto
ALTER TABLE ways
    ADD COLUMN ida double precision;

ALTER TABLE ways
    ADD COLUMN qualite_cyclable_recodee_reverse_aff double precision DEFAULT 0;

UPDATE
    ways
SET
    qualite_cyclable_recodee_reverse_aff = 0.7
WHERE
    qualite_cyclable_recodee_reverse = 0.7;

UPDATE
    ways
SET
    ida = (qualite_route_recodee + vitesse_recode + qualite_cyclable_recodee + qualite_cyclable_recodee_reverse_aff);

--- Creation des champs de cout pour le chemin le plus securise
ALTER TABLE ways
    ADD COLUMN secu_cost_risk double precision,
	ADD COLUMN secu_reverse_cost_risk double precision;

--- Calcul du cout des routes : le plus securise ---
UPDATE
    ways
SET
    secu_cost_risk = (qualite_route_recodee + vitesse_recode + qualite_cyclable_recodee) / (1 / (length_m + 1)),
	secu_reverse_cost_risk = (qualite_route_recodee + vitesse_recode + qualite_cyclable_recodee_reverse) / (1 / (length_m + 1));

--- Creation des champs de cout pour le chemin le plus amenage
ALTER TABLE ways
    ADD COLUMN amenag_cost_risk double precision,
	ADD COLUMN amenag_reverse_cost_risk double precision;

--- Calcul du coût des routes : le plus amenage ---
UPDATE
    ways
SET
    amenag_cost_risk = (qualite_cyclable_recodee) / (1 / (length_m + 1)),
	amenag_reverse_cost_risk = (qualite_cyclable_recodee_reverse) / (1 / (length_m + 1));

--- Creation des champs de cout pour le chemin le plus court
ALTER TABLE ways
    ADD COLUMN court_cost_risk double precision,
	ADD COLUMN court_reverse_cost_risk double precision;

--- Calcul du coût des routes : le plus court ---
UPDATE
    ways
SET
    court_cost_risk = cost,
	court_reverse_cost_risk = reverse_cost;

