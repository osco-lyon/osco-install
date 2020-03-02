#!/bin/bash
#
# Authors : Thomas André, Victor Bonnin, Jérémy Kalsron, Pierre Niogret, Bénédicte Thomas
# License : GPLv3 or later
#
# Script d'initialisation d'OSCO

# Mise à jour des dépôts et de la distribution
apt update && apt upgrade -y

# Installation des dépendances
apt install -y postgresql-11-pgrouting osm2pgrouting osmctools git golang

# Autorisation d'accès depuis une machine distante
echo "listen_addresses = '*'" >> /etc/postgresql/11/main/postgresql.conf
echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/11/main/pg_hba.conf

# Autorisation de connexion par mot de passe depuis la machine locale
sed -i 's/local   all             all                                     peer/local   all             all                                     md5/g' /etc/postgresql/11/main/pg_hba.conf

# Lancement du service
service postgresql start

# Création de l'utilisateur Linux osco
useradd -m -p 20GeoNum20 osco

# Création de la BDD et de l'utilisateur PostgreSQL osco
su - postgres -c "psql -c \"CREATE DATABASE osco;\"" 
su - postgres -c "psql -c \"CREATE ROLE osco WITH LOGIN PASSWORD '20GeoNum20';\""
su - postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE osco to osco;\""

# Ajout des extensions à la BDD
su - postgres -c "psql -d osco -c \"CREATE EXTENSION postgis; CREATE EXTENSION pgrouting; CREATE EXTENSION hstore\""

# Ajout des fonctions développées à la BDD
pwd=$(pwd)
su - postgres -c "psql -d osco -f $pwd/sql/functions.sql"
