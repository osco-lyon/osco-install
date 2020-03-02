#!/bin/bash
#
# Authors : Thomas André, Victor Bonnin, Jérémy Kalsron, Pierre Niogret, Bénédicte Thomas
# License : GPLv3 or later
#
# Script d'installation des applications OSCO

#
# Serveur Go
#

# Clonage du dépôt
git clone https://github.com/osco-lyon/osco-server

# Installation du connecteur PostgreSQL pq
go get github.com/lib/pq

# Compilation de l'application
go build -o osco-server/osco-server osco-server/osco_server.go 

# Déploiement de l'application
mv osco-server/osco-server mv /usr/local/bin/

# Déploiement et activation du fichier de configuration systemd
mv conf/osco-server.service /etc/systemd/system/
systemctl enable osco-server.service

#
# Client HTML
#

# Déploiement de l'application
mkdir -p /var/www/ && git clone https://github.com/osco-lyon/osco-client /var/www/osco_html/
rm -Rf /var/www/osco_html/.git