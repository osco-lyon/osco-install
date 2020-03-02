# Installation OSCO

Suite de script bash et sql initialisant le serveur OSCO.

## Procédure d'installation

### Docker

Un Dockerfile est présent pour automatiser l'installation du serveur. Celui-ci installe PostgreSQL, peuple la base de données et lance l'application Go OSCO. Les ports utilisés sont les ports 80 pour le serveur HTTP et 5432 pour PostgreSQL. 

Après avoir cloné le dépôt, dans le dossier créé, lancer :
```bash
docker build . -t osco-server
```
Puis lancer le conteneur :
```bash
docker run -d -p 80:80 -p 5432:5432 osco-server
```

### Directe

Les scripts d'installation sont prévus pour être exécutés sur une Debian GNU/Linux Buster. Il faut exécuter dans l'ordre :

1. `./init_db.sh` installe les paquets nécessaires et initialise la base de données.
2. `./populate_db.sh` peuple la base de données en téléchargeant un export OSM.
3. `./install_goapp.sh` déploie l'application go servant l'api et le site web.

#### Procédure de mise à jour automatique

Le script ```populate_db.sh``` peut être exécuté régulièrement à l'aide d'un crontab pour mettre à jour le graphe. Ci-dessous un exemple pour effectuer une mise à jour quotidienne à 3h00 :

```bash
0 3 * * * /chemin/vers/populate_db.sh >> /var/log/import_osco.log 2>&1
```



