FROM debian:bookworm

RUN apt-get update
RUN apt-get install -y mariadb-server
RUN rm -rf /var/lib/apt/lists/*
RUN mariadb-install-db

ENTRYPOINT ["/usr/local/bin/init.sh"]
