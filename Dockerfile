FROM debian:buster
COPY . /tmp/install_osco
WORKDIR /tmp/install_osco
RUN chmod +x *.sh &&\
 ./init_db.sh &&\
 ./populate_db.sh &&\
 ./install_goapp.sh
ENTRYPOINT su - postgres -c "/usr/lib/postgresql/11/bin/postgres -D /var/lib/postgresql/11/main -c config_file=/etc/postgresql/11/main/postgresql.conf &" && /usr/local/bin/osco-server
