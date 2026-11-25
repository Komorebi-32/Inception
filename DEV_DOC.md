# Developer documentation

How the project is built, configured and maintained.

## Prerequisites

- A Linux VM (Debian 12 here) where you have `sudo`, logged in as the user named after the 42 login (`bkaras-g`).
- Docker Engine and the Docker Compose v2 plugin (`docker compose version`), your user in the `docker` group.
- `make`, `git`, `openssl` (used by `make` to generate passwords).
- Free disk space: about 1.5 GB for the images, plus the site and database.

## Repository layout

```
Makefile                       entry point: generates config, runs docker compose
secrets/                       passwords (generated, git-ignored)
srcs/.env.example              template of the settings (committed)
srcs/.env                      settings actually used (generated, git-ignored)
srcs/docker-compose.yml        services, network, volumes, secrets
srcs/requirements/<service>/   Dockerfile, conf/ (config files), tools/entrypoint.sh
```

## Set up the environment from scratch

```sh
git clone <repository> inception && cd inception
make
```

`make` (target `up`) runs, in order:

| Step | Target | What it does |
|---|---|---|
| 1 | `secrets` | Creates `secrets/db_root_password.txt`, `secrets/db_password.txt`, `secrets/credentials.txt` with random values (`openssl rand -hex 12`) if they are missing or empty. Never overwrites. |
| 2 | `env` | Creates `srcs/.env` from `srcs/.env.example`, filling in the login, if it is missing or empty. Never overwrites. |
| 3 | `dirs` | Creates `/home/bkaras-g/data/mariadb` and `/home/bkaras-g/data/wordpress`. |
| 4 | `hosts` | Adds `127.0.0.1 bkaras-g.42.fr` to `/etc/hosts` if missing (sudo). |
| 5 | `up` | `docker compose -f srcs/docker-compose.yml up -d --build`. |

The login is the current Unix user (`whoami`). Override it with `make LOGIN=bkaras-g`; the Makefile refuses an empty login, `root`, or anything that is not a lowercase name.

### Configuration: `srcs/.env`

| Variable | Default | Used by |
|---|---|---|
| `DOMAIN_NAME` | `bkaras-g.42.fr` | NGINX `server_name` and certificate, WordPress URL |
| `DATA_DIR` | `/home/bkaras-g/data` | location of the two volumes (compose) |
| `NGINX_PORT` | `443` | published port and NGINX `listen`, WordPress URL |
| `WP_PORT` | `9000` | php-fpm `listen`, NGINX `fastcgi_pass` |
| `DB_PORT` | `3306` | `mariadbd --port`, WordPress `DB_HOST` |
| `DB_NAME`, `DB_USER`, `DB_HOST` | `wordpress`, `wpuser`, `mariadb` | database created by MariaDB and used by WordPress |
| `WP_VERSION`, `WP_TITLE` | `6.8.3`, `Inception` | WordPress download and site title |
| `WP_ADMIN_USER`, `WP_ADMIN_EMAIL` | `bkaras-g_boss`, ... | administrator (must not contain "admin") |
| `WP_USER`, `WP_USER_EMAIL` | `writer`, ... | second user, role author |

The variables are not called `MYSQL_*` on purpose: the `mariadb` client reads `MYSQL_HOST` from the environment, which would break `mariadb -uroot -p` inside the MariaDB container.

### Secrets

Declared at the bottom of `docker-compose.yml`, mounted read-only at `/run/secrets/<name>` in the containers that list them: `db_root_password` and `db_password` (mariadb), `db_password` and `credentials` (wordpress; line 1 admin password, line 2 author password). NGINX gets none.

## Build and launch

| Make target | Command |
|---|---|
| `make` / `make up` | prepare (see above) + `docker compose up -d --build` |
| `make down` | `docker compose down` (containers + network removed, volumes kept) |
| `make stop` / `make start` | `docker compose stop` / `start` |
| `make ps` / `make logs` | `docker compose ps` / `logs -f` |
| `make clean` | `docker compose down --rmi all` |
| `make fclean` | `down -v --rmi all`, `sudo rm -rf /home/bkaras-g/data`, `docker system prune -af` |
| `make re` | `fclean` + `all` |

Rebuild a single service after editing its files: `docker compose -f srcs/docker-compose.yml up -d --build <service>`.

Start order: MariaDB → (healthcheck `mariadb-admin ping` passes) → WordPress → (healthcheck: PID 1 is php-fpm, i.e. installation finished) → NGINX.

## Manage containers and volumes

```sh
docker compose -f srcs/docker-compose.yml ps        # state and health
docker logs -f wordpress                            # logs of one service
docker exec -it mariadb sh                          # shell inside a container
docker exec -it mariadb mariadb -uroot -p           # SQL console (secrets/db_root_password.txt)
docker exec -u www-data wordpress wp --path=/var/www/html user list   # WP-CLI
docker exec nginx cat /etc/nginx/nginx.conf         # config generated from the template
docker exec wordpress cat /proc/1/cmdline           # PID 1 is the daemon
docker network inspect inception                    # containers on the network and their IPs
docker volume ls                                    # mariadb_data, wordpress_data
docker volume inspect mariadb_data                  # "device": /home/bkaras-g/data/mariadb
```

## Where the data lives and how it persists

| Volume | In the container | On the VM |
|---|---|---|
| `mariadb_data` | `/var/lib/mysql` (mariadb) | `/home/bkaras-g/data/mariadb` |
| `wordpress_data` | `/var/www/html` (wordpress, and nginx read-only) | `/home/bkaras-g/data/wordpress` |

Both are named volumes of the `local` driver with `type: none, o: bind`: Docker manages them, the files are stored in the folders above. They survive `make down`, `make clean`, container re-creation and VM reboots; only `make fclean` deletes them.

First-boot work runs only once:
- MariaDB writes `/var/lib/mysql/.inception_initialized` after creating the database and the users; with that file present, the setup is skipped. Changing a database password or name in `secrets/` or `.env` therefore needs `make fclean && make`.
- WordPress checks each step separately (files downloaded, `wp-config.php` present, `wp core is-installed`, author exists). On every start it rewrites `DB_HOST` and the site URL from `.env`, so port changes are applied without reinstalling.

## Change a port

Edit the variable in `srcs/.env`, then run `make` (data kept; do not use `make re`, it deletes the data):

```sh
sed -i 's/^NGINX_PORT=.*/NGINX_PORT=8443/' srcs/.env && make
curl -k -I https://bkaras-g.42.fr:8443
```

Same for `WP_PORT` (php-fpm) and `DB_PORT` (MariaDB). `EXPOSE` in the Dockerfiles keeps the default value: it is documentation only.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| A container restarts in a loop | `docker logs <name>`: the entrypoints print `error: ...` when a variable or secret is missing. |
| `nginx` restarts while `wordpress` is down | Expected: NGINX cannot resolve `wordpress` at start; it recovers when WordPress is back. |
| Database or password change ignored | MariaDB setup already done (marker file). `make fclean && make`. |
| `permission denied` with `docker` | Add your user to the `docker` group and log in again. |
| `Invalid LOGIN` from make | Run make as your normal user (not with sudo), or `make LOGIN=bkaras-g`. |
