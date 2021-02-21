#!/bin/bash
#
# Authors : Thomas André, Victor Bonnin, Jérémy Kalsron, Pierre Niogret, Bénédicte Thomas
# License : GPLv3 or later
#
# Import des données OSM à l'échelle du Grand Lyon dans la base de données

# Téléchargement des données à l'échelle de la région
# À remplacer par l'export pbf de la région voulue sur Geofabrik par exemple
wget http://download.geofabrik.de/europe/france/rhone-alpes-latest.osm.pbf -O export.pbf

# Limiter les données à une bounding box tout en conservant les routes coupées sur les bords
osmconvert export.pbf -b=4.6917,45.5570,5.0619,45.9392 --complete-ways > import.osm

# Conserver uniquement les ways de type highway pour alléger le traitement
osmfilter import.osm --keep="highway=" -o=_import.osm && rm import.osm && mv _import.osm import.osm

# Importer les données traitées dans pgRouting
osm2pgrouting -f import.osm -d osco -U osco -W 20GeoNum20 --clean --addnodes --tags --attributes --conf /usr/share/osm2pgrouting/mapconfig_for_bicycles.xml

# Suppression des fichiers téléchargés
rm export.pbf import.osm

# Export en variable d'environnement du mot de passe psql osco pour connexion non-interactive
export PGPASSWORD="20GeoNum20"

# Nettoyage des données téléchargées
psql -d osco -U osco -f sql/upgrade_ways.sql

# Calcul de l'indice de dangerosité
psql -d osco -U osco -f sql/ida_process.sql
