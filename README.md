*This project has been created as part of the 42 curriculum by <login>.*

# Inception

## Description

Inception sets up a small web infrastructure with Docker Compose, inside a virtual machine. A WordPress site is served over HTTPS only, by three containers that each run one service:

```
                 host (VM)                          Docker network "inception" (bridge)
 browser ──HTTPS :443──► ┌─────────┐  FastCGI :9000  ┌─────────────────────┐  SQL :3306  ┌─────────┐
                         │  nginx  │ ──────────────► │ wordpress + php-fpm │ ──────────► │ mariadb │
                         └────┬────┘                 └──────────┬──────────┘             └────┬────┘
                              │ read-only                       │                             │
                              └──────── wordpress_data ─────────┘                       mariadb_data
                                  /home/<login>/data/wordpress                    /home/<login>/data/mariadb
```

| Service | Image | Role |
|---|---|---|
| `nginx` | `nginx:inception` | Only entry point. Terminates TLS (v1.2/v1.3, self-signed certificate) on port 443, serves static files, passes `.php` requests to php-fpm. |
| `wordpress` | `wordpress:inception` | php-fpm 8.2 running WordPress. Installs and configures WordPress with WP-CLI on first start (admin + one author). |
| `mariadb` | `mariadb:inception` | MariaDB 10.11. Creates the WordPress database and its user on first start. |

Every image is built from `debian:bookworm` (the penultimate stable Debian) by a Dockerfile in `srcs/requirements/<service>/`. Nothing else is pulled from Docker Hub.

### Project description and design choices

**How Docker is used here.** Each service has its own folder with a `Dockerfile` (installs the software), a `conf/` folder (configuration files copied into the image) and a `tools/entrypoint.sh` (runs at container start). The entrypoint does the work that needs the volume, the network or a secret: creating the database, installing WordPress, generating the TLS certificate. It ends with `exec` of the daemon in the foreground, so the daemon is PID 1, receives Docker's stop signal and makes the container stop if it crashes (`restart: unless-stopped` then restarts it). `srcs/docker-compose.yml` ties the three services, the network, the two volumes and the three secrets together; the root `Makefile` generates what is missing (secrets, `srcs/.env`, data folders, `/etc/hosts` entry) and runs compose.

Main choices:
- All passwords are Docker secrets, generated on the machine by `make` and never committed. `srcs/.env` holds only non-secret settings (domain, user names, database name, ports).
- Every port is a variable in `srcs/.env` and every configuration reads it, so a port can be changed in one place.
- First-boot work is guarded (marker file for MariaDB, one check per WP-CLI step) so a restart or a reboot never reinstalls anything.
- MariaDB's first-boot SQL runs with `mariadbd --bootstrap`, in the foreground: no temporary server in the background.

**Virtual Machines vs Docker.** A virtual machine emulates a whole computer: a hypervisor reserves CPU and memory for it and it boots its own kernel and operating system. A container is only an isolated process of the host: it shares the host's kernel, and isolation comes from kernel features (namespaces for what the process can see, cgroups for what it can use). Containers therefore start in a second, use far less memory and disk, and images are built from shared, cached layers. The price is weaker isolation (one kernel for all) and no other operating system kernel. This project uses both: the VM provides a machine where we are root, Docker runs the services inside it.

**Secrets vs Environment Variables.** Environment variables are convenient for configuration but leak easily: they show in `docker inspect`, in `/proc/<pid>/environ`, are inherited by every child process and often end up in logs or committed `.env` files. Docker secrets are files mounted read-only at `/run/secrets/<name>`, only in the containers that list them, and are never part of the image. Here the three passwords are secrets; the `.env` file contains nothing confidential.

**Docker Network vs Host Network.** With `network: host` a container uses the VM's network directly: every port it opens is open on the VM, and there is no isolation between services. A user-defined bridge network is a private virtual network: containers on it reach each other by service name through Docker's internal DNS (`wordpress` resolves `mariadb`), and nothing is reachable from outside except the ports explicitly published. Only NGINX publishes a port (443).

**Docker Volumes vs Bind Mounts.** A bind mount maps a host path into a container; Docker does not manage it and the container depends on the host's folder layout. A named volume is created and tracked by Docker (`docker volume ls`, `docker volume inspect`), survives the removal of containers and can be shared between them. The subject requires named volumes stored under `/home/<login>/data`: the volumes `mariadb_data` and `wordpress_data` use the `local` driver with `type: none, o: bind`, which keeps them Docker named volumes while storing their data in that folder.

## Instructions

**Prerequisites.** A Linux VM with Docker Engine, the Docker Compose plugin, `make`, `openssl` and `sudo` rights, logged in as the user `<login>` (the Makefile uses the current user name as login; override with `make LOGIN=<login>`).

**Build and start.**
```sh
git clone <this repository> inception && cd inception
make
```
`make` creates the passwords in `secrets/`, `srcs/.env` from `srcs/.env.example`, the data folders `/home/<login>/data/{mariadb,wordpress}`, adds `127.0.0.1 <login>.42.fr` to `/etc/hosts` (asks for the sudo password once), then builds the three images and starts the containers. The first start takes about a minute (WordPress download and install).

**Use.** Open `https://<login>.42.fr` and accept the self-signed certificate warning. Administration: `https://<login>.42.fr/wp-admin`. User names are in `srcs/.env` (`WP_ADMIN_USER`, `WP_USER`), passwords in `secrets/credentials.txt` (line 1: admin, line 2: author).

**Stop and clean.**

| Command | Effect |
|---|---|
| `make stop` / `make start` | Stop / restart the containers, nothing removed |
| `make down` | Remove the containers and the network; data kept |
| `make clean` | Also remove the images |
| `make fclean` | Also remove the volumes, the data in `/home/<login>/data` and the Docker cache (asks for sudo) |
| `make re` | `fclean` then `make` |

See [USER_DOC.md](USER_DOC.md) for day-to-day use and [DEV_DOC.md](DEV_DOC.md) for development details.

## Resources

Documentation:
- Docker: Dockerfile reference — https://docs.docker.com/reference/dockerfile/
- Docker Compose file reference (services, networks, volumes, secrets, healthcheck) — https://docs.docker.com/reference/compose-file/
- Docker: restart policies, volumes, bridge networks — https://docs.docker.com/engine/
- NGINX: `ngx_http_ssl_module`, `ngx_http_fastcgi_module` — https://nginx.org/en/docs/
- MariaDB server documentation (`mariadb-install-db`, `mariadbd` options, `--bootstrap`) — https://mariadb.com/docs/
- PHP-FPM configuration — https://www.php.net/manual/en/install.fpm.configuration.php
- WP-CLI commands — https://developer.wordpress.org/cli/commands/
- Debian releases (choice of the penultimate stable) — https://www.debian.org/releases/

Other students' public repositories used for comparison (ideas only): sys-harmony/42_Inception, tigran-sargsyan-w/Inception, KeroBeros68/42-Inception, Nesplee/INCEPTION, aziddineelm/Inception, JaxzTan/Inception.

**AI usage.** Claude (Anthropic), used as a coding assistant, for these tasks:
- Comparing the six repositories above and summarising which implementation choices were best for each file.
- Writing a first version of the Dockerfiles, entrypoint scripts, compose file, Makefile and these documents, with a comment on every line explaining what it does and why.
- Running the stack in a test environment and checking it against the evaluation sheet (HTTPS only, TLS versions, two WordPress users, persistence, port change, restart after a crash). This found real bugs, e.g. MariaDB's configuration files being read alphabetically, and the NGINX host header losing the port.

Not delegated: understanding every line (each file was re-read and explained without notes), the VM installation and configuration, running and checking the project on the VM, and the defense.
