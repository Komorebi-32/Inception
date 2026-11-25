# Inception: cooking recipe (subject v5.3)

How to produce every file of the project, in order, so that each line can be defended and each line of the evaluation grid passes.
Replace `bkaras-g` everywhere with your 42 login (domain `bkaras-g.42.fr`, data in `/home/bkaras-g/data`).

> Understand before you paste (subject ch. IV "AI Instructions"): anything below you cannot explain in defense is a liability. Type it yourself, run it, break it, fix it.

**How to read the files below.** Every file of sections 5 to 7 is complete and commented line by line. The comments are part of the file: keep them while you learn, then trim them to what you would say out loud in defense. Each comment explains what the line does and why it is there. Comment syntax differs by file type: `#` in Dockerfiles, shell, YAML, Makefile, `.env`, NGINX and MariaDB files; `;` in the PHP-FPM file.

**Tested.** On 2026-11-13 these exact files (with `bkaras-g` = `ktest`) were built and run from an empty data folder with Docker 29.9 / Compose v5.6. Section 9.1 lists what was checked and the bugs that the test found in the previous version of this recipe.

---

## 0. Gather more data first (to raise the quality of this recipe)

This recipe is only as good as what it was built from. Before you freeze your own files, spend 30-45 minutes widening the base. Do it in this order.

### 0.1 Find more repos manually
1. GitHub search, sorted by "Recently updated" (repos from 2026 follow the newest subject):
   - `https://github.com/search?q=42+inception&type=repositories&s=updated&o=desc`
   - `https://github.com/search?q=filename%3ADEV_DOC.md+inception&type=code`  (DEV_DOC.md / USER_DOC.md only exist since the late-2025 subject)
   - `https://github.com/search?q=filename%3AUSER_DOC.md+inception&type=code`
   - `https://github.com/search?q=%22created+as+part+of+the+42+curriculum%22+inception&type=code`  (new README first-line rule)
   - `https://github.com/search?q=inception+%22125%2F100%22&type=code`  (READMEs that state a grade)
2. Keep a repo only if it has: `srcs/` + root Makefile, `USER_DOC.md` + `DEV_DOC.md`, README first line in the new format, passwords in `secrets/` (not in committed `.env`), `FROM debian:bookworm` or the matching Alpine. Reject `bullseye`, `latest`, `links:`, `tail -f`, committed passwords.
3. A grade badge is a claim, not proof (see 0.2: three of six "recent" repos still use the old base image). A repo that shows the subject version (a `subject.pdf`/`subject.txt` saying "Version: 5.3") is stronger evidence for the version, and a stated validation date is stronger evidence for the grade. Ask peers on your campus for repos they know passed recently.
4. For every repo you keep, read in this order: compose file, then each Dockerfile, then each entrypoint script, then the Makefile. Note anything that differs from sections 5-7 and decide why. Never paste; re-type.
5. Add what you learn to 0.2 (name, link, claim, what you took from it).

### 0.2 Repos analysed (cloned and read on 2026-11-13)

All compose files, Dockerfiles, entrypoint scripts, config files, Makefiles, READMEs, USER_DOCs and DEV_DOCs of these six repos were read. Verdict per repo and what this recipe took from it:

| Repo | Claim | Base image / secrets | Verdict | Taken into this recipe |
|---|---|---|---|---|
| [sys-harmony/42_Inception](https://github.com/sys-harmony/42_Inception) | 125/100 badge | `debian:12`, one Docker secret per password | Best overall design | MariaDB setup with `--bootstrap` (no background server); `.initialized` marker file; fail-fast checks on every variable; every port in `.env`; WordPress URL recomputed with the port on every start (`wp option update home/siteurl`), which makes the port-change test work; healthcheck that logs in with the root secret; `try_files $uri =404` and "deny dotfiles" in NGINX |
| [tigran-sargsyan-w/Inception](https://github.com/tigran-sargsyan-w/Inception) | 125/100, bookworm | `debian:bookworm`, secrets | Most careful code, best defense docs (`EVALUATION_GUIDE.md`) | `99-` prefix for the MariaDB config file; `rm -rf /var/lib/mysql/*` in the Dockerfile; WP-CLI pinned to a version; WP-CLI run as `www-data` (`runuser`); idempotent install steps (`wp core is-installed`, `wp user get`); admin-name check; bounded wait loops that fail loudly; `nginx -t` before start; `name:` on volumes; image tag `:inception`; `tr -d '\r\n'` when reading secrets; the "which tool answers which question" table (section 13). Not taken: certificates bind-mounted from the host (a bind mount, avoid), SQL template rendered to a temp file (the heredoc avoids writing passwords to disk) |
| [KeroBeros68/42-Inception](https://github.com/KeroBeros68/42-Inception) | no grade; README says "version 5.3" | `alpine:3.23`, secrets | Good, Alpine variant | `server_tokens off`; idea of a second `internal: true` network for the back end (bonus). Not taken: a `listen 80` redirect block (port 80 is not published, but an evaluator reading "listen 80" may fail you on "HTTP must not connect") |
| [Nesplee/INCEPTION](https://github.com/Nesplee/INCEPTION) | 125/100, "Validated on July 9, 2026" | `debian:bullseye`, passwords in `.env` | Old-subject code: `bullseye`, `version: '3'`, no `image:` names, `wordpress.org/latest.tar.gz`, certificate baked into the image with a hard-coded domain | Nothing beyond what others do better |
| [aziddineelm/Inception](https://github.com/aziddineelm/Inception) | "125/100" | `debian:bullseye`, passwords as compose env vars | Old base image, no secrets | README structure (the four comparisons as numbered subsections) |
| [JaxzTan/Inception](https://github.com/JaxzTan/Inception) | no grade; links the v5.3 subject | `debian:bullseye`, passwords in `.env` | Old base image, `apt-get upgrade`, `listen 80` block, certificate with hard-coded domain at build | Nothing |

**Lessons from the comparison.**
- Three of the six repos (two of them claiming 125/100 in 2026) still use `debian:bullseye`, which is no longer the penultimate stable. Badges and dates prove nothing about the current grid.
- Only sys-harmony handled the "change a port live" test fully. Even it would now break on a non-443 port because of a recent Debian NGINX change (pitfall in section 10); this recipe fixes that.
- All repos that pass `.env` with `env_file:` and name their variables `MYSQL_HOST` break `mariadb -uroot -p` inside the MariaDB container (section 10). They passed anyway, so evaluators may not test it, but this recipe avoids it.

### 0.3 Other inputs to feed in
- Your own notes: [notion_Ben.md](notion_Ben.md) (already merged into this recipe, see sections 4, 6, 12).
- Peers who passed recently: ask what the evaluator asked live (port change, DB login, which service they picked).
- Your own defense dry-run: do the checks of section 9 against a teammate acting as evaluator, then write down every question you could not answer.

---

## 0.4 Sources used and their status

| Source | Status |
|---|---|
| `en.subject.inception.pdf` (v5.3, in this folder) | Read fully. Authoritative. |
| `Grille correction inception.pdf` | Read fully. Reproduced as a checklist in section 1. |
| Notion page (private link) | Not readable by me (login required). Replaced by your export, `notion_Ben.md`, which is merged below. |
| GitHub repos | Six repos cloned and read on 2026-11-13, see 0.2. Ideas taken, files rewritten. |
| Test run | The files of sections 5-7 were built and run on 2026-11-13, see 9.1. |

---

## 1. Evaluation grid, as a checklist

Before the defense the evaluator runs this wipe, so your project must build from zero:
```sh
docker stop $(docker ps -qa); docker rm $(docker ps -qa); docker rmi -f $(docker images -qa); docker volume rm $(docker volume ls -q); docker network rm $(docker network ls -q) 2>/dev/null
```

### Instant-fail ("evaluation ends now")
- [ ] Any credential, API key or password committed in git (outside properly configured secrets files created at evaluation time) → **mark 0**.
- [ ] Missing work / wrong files / wrong filenames → 0.
- [ ] `network: host`, `links:` in compose, or `--link` anywhere (Makefile, scripts).
- [ ] No `networks:` in `docker-compose.yml`.
- [ ] `tail -f`, any background command (`nginx &`), or `bash`/`sh` used other than to run a script, in an ENTRYPOINT.
- [ ] `sleep infinity`, `tail -f /dev/null`, `while true` or any infinite loop in any script.
- [ ] A Dockerfile not starting with `FROM alpine:X.X` / `FROM debian:<codename>` of the **penultimate stable** release (or a local image).
- [ ] Image name different from its service name; ready-made image pulled / DockerHub used; `latest` tag.
- [ ] Containers not all built by the Makefile through docker compose, or one crashes.
- [ ] `srcs/` not at repo root, or Makefile not at repo root.

### Docs
- [ ] `README.md` at root. First line (italic): `*This project has been created as part of the 42 curriculum by bkaras-g.*`
- [ ] README sections: Description, Instructions, Resources (including how AI was used, for which tasks/parts), plus Project description with comparisons: **VM vs Docker, Secrets vs Env vars, Docker network vs Host network, Volumes vs Bind mounts**. In English.
- [ ] `USER_DOC.md` (services, start/stop, access site + admin panel, where credentials are, how to check services run).
- [ ] `DEV_DOC.md` (prerequisites, setup from scratch incl. secrets, Makefile + compose usage, container/volume commands, where data lives and how it persists).

### Live checks
- [ ] Only port 443 reachable; `http://bkaras-g.42.fr` (port 80) refuses; `https://bkaras-g.42.fr` shows the installed site (not the WP installer).
- [ ] TLS v1.2 or v1.3 demonstrated (self-signed warning is fine).
- [ ] One non-empty Dockerfile per service; `docker compose ps` shows all containers up.
- [ ] `docker network ls` shows the project network; be ready to explain Docker networks.
- [ ] WordPress container: no NGINX inside. Volume check: `docker volume ls`, `docker volume inspect <name>` output contains `/home/bkaras-g/data/`.
- [ ] Add a comment as the normal WP user. Log in as admin; admin username must **not** contain `admin`/`Admin`/`administrator`. Edit a page in the dashboard and see it change on the site.
- [ ] MariaDB container: no NGINX inside; same volume check; explain how to log into the DB; DB not empty. WP DB has **2 users**, one of them the admin.
- [ ] **Persistence**: reboot the VM, `docker compose` up again, everything (site edits, DB) is still there.
- [ ] **Configuration modification**: the reviewer picks a service and a new port; you change it, rebuild, restart, and it still works. Practice this (section 9.3).
- [ ] Containers restart on crash (`restart:` policy). Demonstrate with `docker exec <c> kill 1`, **not** `docker kill` (section 9.2).
- [ ] You can explain: how Docker and compose work; image with vs without compose; Docker vs VMs; why the directory structure is what it is.

### Bonus (only if mandatory is flawless): redis cache, FTP server on the WP volume, static site (no PHP), Adminer, free-choice service. One Dockerfile each. Extra ports allowed.

---

## 2. Decisions to make first (and what to answer in defense)

| Decision | Choice | Why |
|---|---|---|
| Base image | `debian:bookworm` (Debian 12) | Debian 13 "trixie" is the current stable as of Nov 2026, so the penultimate is bookworm. **Re-check on debian.org/releases the day you build.** If you prefer Alpine, check alpinelinux.org/releases and take the second most recent branch. |
| Tag | Pin it (`debian:bookworm`), never `latest` | Subject forbids `latest`. Your notes doubt whether `-slim` variants are accepted: plain `debian:bookworm` is the safe choice, ask staff before using `-slim`. |
| Alpine vs Debian | Debian | Your notes: Alpine is lighter but has less documentation and more manual setup (musl, apk); the subject is more about services than image size. Goinfre is capped at 30 GB, but Debian fits (the three images total ~1.3 GB). |
| Image names | `image: mariadb:inception` etc. | Same name as the service (subject rule). The explicit tag avoids compose's implicit `:latest`. |
| Secrets | Docker secrets for all passwords; `.env` only for non-secret values (domain, usernames, db name, ports) | Subject: `.env` mandatory, secrets strongly recommended; passwords in git = failure. |
| Volumes | Named volumes (`name: mariadb_data`, `wordpress_data`) with `driver_opts` pointing at `/home/bkaras-g/data/...` | Subject forbids bind mounts for these two, but requires data under `/home/bkaras-g/data`. |
| Ports | All three in `.env` (`NGINX_PORT`, `WP_PORT`, `DB_PORT`), read by every config | The live "change a port" test becomes a one-line edit + `make`. |
| Variable names | `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, never `MYSQL_*` | The `mariadb` client reads `MYSQL_HOST` from the environment (section 10). |
| MariaDB first boot | `mariadbd --bootstrap` fed by a heredoc | Runs SQL in the foreground with no network and no background process (sys-harmony, aziddineelm). |
| WordPress install | WP-CLI, pinned versions of WP-CLI and WordPress, run as `www-data`, one idempotent step at a time | Reproducible, no `--allow-root`, survives a crash in the middle of the first install (tigran). |
| PHP | php-fpm on TCP (`WP_PORT`, 9000) | Matches the subject diagram (WordPress+PHP ↔ NGINX on 9000). |
| TLS cert | Self-signed, generated with `openssl` at container start | No cert or key in git or in the image. |
| PID 1 | Each entrypoint ends with `exec <daemon in foreground>` | The daemon receives `SIGTERM` and its crash stops the container (restart policy). |

Debian bookworm package versions: PHP **8.2**, MariaDB **10.11**. Binary names: `php-fpm8.2`, `mariadbd` / `mariadb-admin` (older `mysqld`/`mysqladmin` still exist as links).

---

## 3. Target layout

```
<repo>/
├── Makefile
├── README.md   USER_DOC.md   DEV_DOC.md
├── .gitignore                  # secrets/  srcs/.env
├── secrets/                    # NOT committed (generated by `make secrets`)
│   ├── credentials.txt         # line 1: WP admin password, line 2: WP user password
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env                    # NOT committed (generated by `make env` from .env.example)
    ├── .env.example
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/    { Dockerfile, .dockerignore, conf/99-inception.cnf, tools/entrypoint.sh }
        ├── nginx/      { Dockerfile, .dockerignore, conf/nginx.conf.template, tools/entrypoint.sh }
        ├── wordpress/  { Dockerfile, .dockerignore, conf/www.conf, tools/entrypoint.sh }
        ├── bonus/
        └── tools/
```
This mirrors the subject's example tree. Why it makes sense (defense question): `srcs/` = everything that configures the app; one folder per service = one image per service; `conf/` = static config copied in, `tools/` = scripts; `secrets/` is outside `srcs/` so it can be git-ignored as a unit.

**Order of work** (from your notes, each step is testable before the next):
1. MariaDB Dockerfile + entrypoint, test it alone (`docker exec -it mariadb sh`, `mariadb -u root -p`).
2. A minimal `docker-compose.yml`, then the WordPress Dockerfile + entrypoint.
3. NGINX + TLS, then add network/volumes/secrets/restart policy to compose.
4. Makefile, then README / USER_DOC / DEV_DOC.
5. Defense prep (sections 9 and 12).

---

## 4. Host preparation (once, on the VM)

### 4.1 The VM (from your notes)
- The project must run in a VM; 42 machines give no root, and Docker needs root. VirtualBox with the school's setup works.
- Install **Debian bookworm** (the penultimate) in the VM. Trixie as the VM OS makes installing Docker more annoying; the VM version is not graded, the Dockerfile base is.
- No GUI is fine to start (guide used: goopensource.fr "debian-installation-sans-interface-graphique"). If you need a browser in the VM later: `sudo apt install -y xfce4 xfce4-goodies lightdm firefox-esr`.
- Install `sudo` (as root), `ssh` (copy-paste is much easier; same steps as Born2beRoot, root login disabled), `vim`, `make`, `git`.
- sys-harmony's `DEV_DOC.md` ("Full Project Tutorial") walks through the whole VM setup (VirtualBox, Debian install, sudo, network, SSH + VS Code, Docker) if you get stuck.

### 4.2 Docker install
```sh
# Tools needed to add Docker's own package repository
sudo apt install -y ca-certificates curl gnupg lsb-release
# Download Docker's signing key and store it in apt's keyring format (--dearmor)
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
# Declare Docker's repository for this CPU architecture and Debian codename
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# Install the engine, the CLI, containerd and the compose v2 plugin (`docker compose`)
sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
docker --version && docker compose version
```
**Correction to your notes:** they use `download.docker.com/linux/ubuntu` in both the key and repo lines. On a Debian VM use `linux/debian`, as above.

### 4.3 Your user
```sh
sudo usermod -aG docker bkaras-g   # add yourself to the docker group: use docker without sudo
newgrp docker                     # refresh group membership in the current shell, otherwise `docker` still says permission denied
```
Check disk use as you go: `du -sh /sgoinfre/goinfre/Perso/bkaras-g` (30 GB quota).

### 4.4 Project host prep
The Makefile (section 7) does all of it on `make`: creates `/home/bkaras-g/data/{mariadb,wordpress}`, adds `127.0.0.1 bkaras-g.42.fr` to `/etc/hosts` (asks for your sudo password once), generates `secrets/` and `srcs/.env`. To do it by hand: `mkdir -p /home/bkaras-g/data/mariadb /home/bkaras-g/data/wordpress` and `echo "127.0.0.1 bkaras-g.42.fr" | sudo tee -a /etc/hosts`.

---

## 5. Config files

### 5.1 `.gitignore` (repo root)
```sh
# Never commit passwords (instant 0) nor your local settings.
secrets/
srcs/.env
```
Your notes (and the grid): a pushed `.env` with passwords is a **0**. Here `.env` has no password, but it is generated anyway; commit `.env.example` instead.

### 5.2 `srcs/.env.example` (committed; `make` copies it to `srcs/.env` and fills `bkaras-g`)
```sh
# Copy this file to srcs/.env (`make` does it for you) and replace bkaras-g.
# Only NON-secret settings here. Passwords live in ../secrets/ (Docker secrets).
# Docker compose reads this file automatically because it sits next to
# docker-compose.yml: the values are used for ${...} substitution in the yml
# AND, through `env_file:`, given to the containers as environment variables.
# Format: KEY=value, no spaces around "=", no quotes needed.

# Domain of the site. /etc/hosts must map it to 127.0.0.1 (the Makefile does).
DOMAIN_NAME=bkaras-g.42.fr
# Host folder holding the two volumes (subject: /home/bkaras-g/data).
DATA_DIR=/home/bkaras-g/data

# Ports. Changing one of them here + `make` is enough for the live
# "configuration modification" test (section 9.3 of the recipe).
# NGINX_PORT is both the published host port and the port NGINX listens on.
NGINX_PORT=443
WP_PORT=9000
DB_PORT=3306

# Database: name of the WordPress database, its (non-root) user, and the host
# name of the database server = the compose service name.
# Do NOT call them MYSQL_HOST/MYSQL_USER...: the `mariadb` client reads
# MYSQL_HOST from the environment, so `mariadb -uroot -p` inside the mariadb
# container would connect over the network instead of locally and be refused.
DB_NAME=wordpress
DB_USER=wpuser
DB_HOST=mariadb

# WordPress. Pinned version: same site on every machine.
WP_VERSION=6.8.3
WP_TITLE=Inception
# Admin login: must NOT contain admin / Admin / administrator (subject rule).
WP_ADMIN_USER=bkaras-g_boss
WP_ADMIN_EMAIL=bkaras-g@student.42.fr
# Second, non-admin user (role "author").
WP_USER=writer
WP_USER_EMAIL=writer@student.42.fr
```

### 5.3 Secrets: `secrets/` (created by `make secrets`, see 7)
`db_root_password.txt`, `db_password.txt`, `credentials.txt` (WP admin password on line 1, WP user password on line 2). The subject's tree shows exactly these three. They are generated on the evaluator's machine after `git clone`, so no password is ever in the repo (the grid accepts secrets files "created during the evaluation"). Point the evaluator to `secrets/credentials.txt` from USER_DOC.

### 5.4 `srcs/docker-compose.yml`
```yaml
# Compose file: describes the whole stack (3 services, 1 network, 2 volumes,
# 3 secrets) so that one command builds and starts everything.
# No `version:` key: it is obsolete with Compose v2 (`docker compose`).

# Project name, used as a prefix for resources Docker names automatically.
# Without it, compose uses the folder name ("srcs").
name: inception

services:
  mariadb:
    # Build the image from the Dockerfile in this folder (nothing is pulled
    # from Docker Hub except the debian:bookworm base).
    build: ./requirements/mariadb
    # Name (and tag) of the image built above: same name as the service, as
    # the subject requires. An explicit tag avoids the implicit `:latest`.
    image: mariadb:inception
    # Fixed container name (otherwise "inception-mariadb-1"), handy for
    # `docker exec -it mariadb ...` during the defense.
    container_name: mariadb
    # Restart the container automatically if it crashes, and at boot, unless
    # we stopped it ourselves with `docker compose stop/down`.
    restart: unless-stopped
    # Give every KEY=value of .env to the container as environment variables.
    env_file: .env
    # Mount these secrets as read-only files /run/secrets/<name>.
    secrets:
      - db_root_password
      - db_password
    volumes:
      # Named volume (declared at the bottom) -> MariaDB's data folder.
      - mariadb_data:/var/lib/mysql
    networks:
      - inception
    # How Docker decides the service is ready, used by `depends_on` below.
    #   CMD-SHELL            run the test through `sh -c`, needed for $(...)
    #   mariadb-admin ping   asks the local server "are you alive?"
    #   -p"$$(cat ...)"      logs in as root with the secret, otherwise the
    #                        server logs "Access denied" every 5 s. `$$` is how
    #                        you write a literal `$` in a compose file (a single
    #                        `$` would be a compose ${VARIABLE}).
    #   interval/timeout     test every 5 s, each test may take 3 s
    #   retries              unhealthy after 10 consecutive failures
    #   start_period         failures during the first 30 s (first-boot
    #                        initialisation) do not count
    healthcheck:
      test: ["CMD-SHELL", "mariadb-admin ping -uroot -p\"$$(cat /run/secrets/db_root_password)\" --silent"]
      interval: 5s
      timeout: 3s
      retries: 10
      start_period: 30s

  wordpress:
    build: ./requirements/wordpress
    image: wordpress:inception
    container_name: wordpress
    restart: unless-stopped
    env_file: .env
    secrets:
      - db_password
      - credentials
    volumes:
      # The WordPress files. NGINX mounts the same volume to serve them.
      - wordpress_data:/var/www/html
    networks:
      - inception
    # Start only once MariaDB's healthcheck passes (not just "container started").
    depends_on:
      mariadb:
        condition: service_healthy
    # Healthy once PID 1 is php-fpm, i.e. the entrypoint finished installing
    # WordPress and `exec`ed php-fpm. /proc/1/comm = name of process 1.
    healthcheck:
      test: ["CMD-SHELL", "grep -q php-fpm /proc/1/comm"]
      interval: 5s
      timeout: 3s
      retries: 10
      start_period: 60s

  nginx:
    build: ./requirements/nginx
    image: nginx:inception
    container_name: nginx
    restart: unless-stopped
    env_file: .env
    # The ONLY published port: host port -> container port. Everything else
    # is reachable only inside the Docker network.
    # "${NGINX_PORT}" is substituted by compose from .env.
    ports:
      - "${NGINX_PORT}:${NGINX_PORT}"
    volumes:
      # Same WordPress files, read-only (:ro): NGINX only needs to read them.
      - wordpress_data:/var/www/html:ro
    networks:
      - inception
    # Start after WordPress is installed and php-fpm runs.
    depends_on:
      wordpress:
        condition: service_healthy

# User-defined bridge network: a private virtual network for the 3 containers.
# On it, containers find each other by service name (Docker's embedded DNS),
# and nothing is reachable from outside except the published port.
# `name:` fixes the real name to "inception" (otherwise "inception_inception").
networks:
  inception:
    name: inception
    driver: bridge

# Named volumes stored where the subject wants them (/home/bkaras-g/data).
#   driver: local + type: none + o: bind  -> the "local" volume driver mounts
#   an existing host folder (device). It is still a NAMED VOLUME managed by
#   Docker (`docker volume ls/inspect` show it), not a bind mount written in a
#   service as "- /host/path:/container/path", which the subject forbids here.
# `name:` gives the exact names mariadb_data / wordpress_data.
# The host folders must exist before `up` (the Makefile creates them).
volumes:
  mariadb_data:
    name: mariadb_data
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${DATA_DIR}/mariadb
  wordpress_data:
    name: wordpress_data
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${DATA_DIR}/wordpress

# Docker secrets: files on the host (outside git, created by `make secrets`),
# mounted into the containers that list them, at /run/secrets/<name>.
# Paths are relative to this compose file, hence "../secrets".
secrets:
  db_root_password:
    file: ../secrets/db_root_password.txt
  db_password:
    file: ../secrets/db_password.txt
  credentials:
    file: ../secrets/credentials.txt
```
Things to be able to explain:
- `image: nginx:inception` next to `build:` names the built image after the service (subject rule). It does not pull anything.
- `o: bind` is the local volume driver mounting a host folder; it is still a **Docker named volume** (shows in `docker volume ls`, and `docker volume inspect mariadb_data` shows the device path under `/home/bkaras-g/data`). A `- /host/path:/ctr/path` line in a service would be a bind mount, which is forbidden here.
- `restart: unless-stopped` satisfies "restart in case of a crash". It also brings the stack back after a VM reboot, because the Docker daemon starts at boot.
- `${DATA_DIR}` and `${NGINX_PORT}` are read from `srcs/.env` (compose auto-loads the `.env` next to the yml for substitution); `env_file: .env` additionally injects every line into the containers.
- Containers reach each other by service name (`mariadb`, `wordpress`) via Docker's DNS on the `inception` network.
- `depends_on` + `condition: service_healthy` orders the start: MariaDB healthy → WordPress installed and php-fpm running → NGINX.

---

## 6. The three images

General rules for all three Dockerfiles: `FROM debian:bookworm`; install in one `RUN` with `apt-get update && apt-get install -y --no-install-recommends ... && rm -rf /var/lib/apt/lists/*`; **no password anywhere**; `ENTRYPOINT` = your script (shebang `#!/bin/sh`), and the script ends with `exec <daemon in foreground>` so the daemon is PID 1 and receives `SIGTERM`. Everything that depends on the volume, the network or a secret (database creation, WordPress install, certificate) happens at **container start** in the entrypoint, not at build: at build time there is no volume, no network and no secret.

Each entrypoint has the same four parts: (1) check every variable and secret it needs and stop with a clear message if one is missing; (2) prepare directories and permissions; (3) do the first-boot work, guarded so that it runs only once; (4) `exec` the daemon.

### 6.1 MariaDB

`srcs/requirements/mariadb/Dockerfile`
```dockerfile
# Base image: Debian 12 "bookworm", the penultimate stable Debian release
# (Debian 13 "trixie" is the current one). Always pin a codename, never `latest`.
FROM debian:bookworm

# One RUN = one image layer. `&&` chains the commands and stops at the first
# failure, so a broken install fails the build instead of producing a bad image.
#   apt-get update                 download the list of available packages
#   install -y                     answer "yes" to every prompt (no human to type it)
#   --no-install-recommends        skip optional extras -> smaller image
#   mariadb-server                 the database server (binary: mariadbd)
#   mariadb-client                 the `mariadb` and `mariadb-admin` command-line tools
#   rm -rf /var/lib/apt/lists/*    delete the package lists downloaded by `update`
#                                  (useless at runtime, saves ~20 MB in this layer)
#   rm -rf /var/lib/mysql/*        the Debian package ships an already-initialised
#                                  database here. We empty it so that our entrypoint
#                                  always initialises the database itself, with OUR
#                                  passwords, the first time the container starts.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        mariadb-server \
        mariadb-client \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/mysql/*

# Our server settings. MariaDB reads every *.cnf in this folder in alphabetical
# order and the LAST value wins. Debian's own 50-server.cnf says
# `bind-address = 127.0.0.1`, so our file must sort after it: hence "99-".
COPY conf/99-inception.cnf /etc/mysql/mariadb.conf.d/99-inception.cnf

# The startup script. /usr/local/bin is the conventional place for
# locally-added executables and is already in $PATH.
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

# COPY keeps the file mode of the source; make sure the script is executable
# even if the execute bit was lost (git on some systems, a zip download...).
RUN chmod +x /usr/local/bin/entrypoint.sh

# Documentation only: tells readers (and `docker inspect`) which port the
# service uses. It does NOT publish the port to the host; compose does not
# publish it either, so MariaDB is reachable only from the Docker network.
EXPOSE 3306

# The program Docker runs when the container starts. JSON ("exec") form: Docker
# runs the script directly, with no `sh -c` wrapper, so the script is PID 1
# until it `exec`s the real server.
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
```

`srcs/requirements/mariadb/conf/99-inception.cnf`
```ini
# [mysqld] = the section read by the server (mariadbd). Other sections such as
# [client] are read by the command-line tools instead.
[mysqld]
# Listen on every network interface of the container. The default
# (127.0.0.1, set by Debian's 50-server.cnf) would accept connections only
# from inside this container, so WordPress could never reach the database.
# Safe here: port 3306 is not published, only the Docker network can reach it.
bind-address = 0.0.0.0
```

`srcs/requirements/mariadb/tools/entrypoint.sh`
```sh
#!/bin/sh
# `set -e`: stop the script as soon as a command fails (non-zero exit code).
# `set -u`: treat the use of an undefined variable as an error (catches typos
#           such as $DB_NAEM for $DB_NAME, instead of silently using "").
set -eu

# Paths used several times below, named once so they are easy to change.
DATADIR=/var/lib/mysql
# Marker file written only after a SUCCESSFUL first-time setup. It lives in the
# volume, so it survives container re-creation and VM reboots.
MARKER="$DATADIR/.inception_initialized"

# Small helper: print an error on stderr (so it shows in `docker logs`) and
# exit with status 1. The restart policy will then retry the container.
fail() {
    echo "[mariadb] error: $1" >&2
    exit 1
}

# --- 1. Fail fast if the configuration is incomplete ------------------------
# `${VAR:-}` expands to an empty string if VAR is unset (needed because of
# `set -u`); `[ -n "..." ]` is true when the string is not empty.
[ -n "${DB_NAME:-}" ] || fail "DB_NAME is not set (srcs/.env)"
[ -n "${DB_USER:-}" ] || fail "DB_USER is not set (srcs/.env)"
[ -n "${DB_PORT:-}" ] || fail "DB_PORT is not set (srcs/.env)"
# `[ -r file ]` is true when the file exists and is readable. Docker mounts
# each secret as a read-only file under /run/secrets/<name>.
[ -r /run/secrets/db_root_password ] || fail "secret db_root_password missing"
[ -r /run/secrets/db_password ]      || fail "secret db_password missing"

# Read the passwords from the secret files. `tr -d '\r\n'` deletes newline and
# carriage-return characters, so a file saved by an editor with a trailing
# newline (or Windows line endings) still gives the exact password.
ROOT_PASS=$(tr -d '\r\n' < /run/secrets/db_root_password)
DB_PASS=$(tr -d '\r\n' < /run/secrets/db_password)
[ -n "$ROOT_PASS" ] || fail "db_root_password is empty"
[ -n "$DB_PASS" ]   || fail "db_password is empty"

# --- 2. Runtime directories and ownership ------------------------------------
# /run/mysqld holds the server's socket and PID file. The server runs as the
# unprivileged `mysql` user, so that user must own it and the data directory.
# The data directory is the volume: its ownership comes from the host folder,
# which is why it is fixed here at runtime and not in the Dockerfile.
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld "$DATADIR"
# After a crash (or `docker kill`), the old PID/socket files can stay behind
# inside the container. MariaDB would think another server is still running
# and refuse to start, so delete them. `-f`: no error if they do not exist.
rm -f /run/mysqld/mysqld.pid /run/mysqld/mysqld.sock

# --- 3. First boot only: create the database, the user and the passwords ----
if [ ! -f "$MARKER" ]; then
    echo "[mariadb] first start: initialising the database"

    # Create MariaDB's own system tables (users, privileges...) in an empty
    # data directory. Skipped if they already exist (e.g. a previous attempt
    # crashed after this step).
    #   --user=mysql     files are created owned by the mysql user
    #   --skip-test-db   do not create the demo `test` database
    #   > /dev/null      hide the long, normal output
    if [ ! -d "$DATADIR/mysql" ]; then
        mariadb-install-db --user=mysql --datadir="$DATADIR" --skip-test-db > /dev/null
    fi

    # --bootstrap: start the server WITHOUT networking, read SQL statements from
    # standard input, execute them, then exit. This runs in the FOREGROUND
    # (no `&`, no background server to wait for and kill), so it cannot break
    # the "no background process" rule. The SQL comes from the heredoc below:
    # everything between `<<EOF` and the closing `EOF` is sent to stdin, after
    # the shell has replaced ${...} with the values of the variables.
    #   FLUSH PRIVILEGES (first)  in bootstrap mode the privilege tables are not
    #                             loaded yet; this loads them so that ALTER USER
    #                             and GRANT work.
    #   ALTER USER root           give root a password (on Debian, root can
    #                             otherwise log in from inside the container
    #                             with no password at all).
    #   `backticks`               quote a database name in SQL; escaped as \`
    #                             because a bare ` means "run a command" in sh.
    #   '${DB_USER}'@'%'          a user allowed to connect from ANY host ('%'),
    #                             needed because WordPress is another container
    #                             with its own IP address.
    #   GRANT ... ON db.*         that user gets every right on the WordPress
    #                             database only, not on the whole server.
    mariadbd --user=mysql --datadir="$DATADIR" --bootstrap <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASS}';
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    # Only reached if everything above succeeded (set -e). Next boots skip
    # this whole block, which is what makes the data persist.
    touch "$MARKER"
    echo "[mariadb] initialisation done"
fi

# --- 4. Hand over to the real server -----------------------------------------
# `exec` REPLACES this shell process with mariadbd (same idea as execve() in
# minishell/pipex). mariadbd therefore becomes PID 1: it receives Docker's
# SIGTERM on `docker stop` and shuts down cleanly, and if it crashes the
# container stops and the restart policy brings it back.
#   --user=mysql                  never run the server as root
#   --port=...                    port read from srcs/.env (easy to change live)
#   --console                     write the server log to stdout/stderr, so it
#                                 shows in `docker logs mariadb`
exec mariadbd --user=mysql --port="$DB_PORT" --console
```

**Alternatives you will see in other repos, and why this one was kept.**
- *Temporary server in the background* (`mariadbd --skip-networking &`, or `service mariadb start`, wait with a loop, run SQL, `mariadb-admin shutdown`, then `exec`). Works, and it is the variant in your notes (with `exec mysqld_safe --bind-address=0.0.0.0` at the end). But it puts a `&` / background process in the entrypoint, which you must then defend against the grid's "no background command" rule. `--bootstrap` has no background process at all.
- *`--init-file=init.sql` ending with `SHUTDOWN;`* (tigran). Also foreground, also fine, but it writes the SQL with the passwords to a temporary file first.
- *Guard on the database folder* (`if [ ! -d /var/lib/mysql/wordpress ]`). If the setup crashes after the folder was created, it never runs again. The marker file is written last, so an interrupted setup is redone.
- *`mysqld_safe`* as the final command: a wrapper script that restarts mariadbd itself. Not needed, Docker's restart policy already does that, and it makes PID 1 a shell script instead of the server.

### 6.2 WordPress + php-fpm

`srcs/requirements/wordpress/Dockerfile`
```dockerfile
# Same base as the other services (penultimate stable Debian, pinned).
FROM debian:bookworm

# Version of WP-CLI (the WordPress command-line tool) to install. Pinned so the
# build gives the same result next month. An ARG exists only during the build.
ARG WP_CLI_VERSION=2.12.0

# Install PHP and what WordPress needs. Bookworm ships PHP 8.2.
#   php8.2-fpm        PHP "FastCGI Process Manager": a long-running server that
#                     executes .php files for a web server (NGINX) over the
#                     network. Pulls php8.2-cli too, which WP-CLI needs.
#   php8.2-mysql      lets PHP talk to MariaDB (mysqli / PDO drivers)
#   php8.2-curl/-gd/-intl/-mbstring/-xml/-zip
#                     extensions WordPress uses: HTTP requests, image resizing,
#                     languages, multibyte text, XML/RSS, plugin .zip install
#   mariadb-client    the `mariadb` command, used to wait until the DB answers
#   curl              downloads WP-CLI just below
#   ca-certificates   root certificates, so curl and WP-CLI can verify HTTPS
#                     sites (github.com, wordpress.org)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        php8.2-fpm \
        php8.2-mysql \
        php8.2-curl \
        php8.2-gd \
        php8.2-intl \
        php8.2-mbstring \
        php8.2-xml \
        php8.2-zip \
        mariadb-client \
        curl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Download WP-CLI, a single PHP archive (.phar), and make it a command.
#   -f   fail on HTTP errors (404...) instead of saving the error page
#   -sS  silent, but still print errors
#   -L   follow redirects (GitHub release links redirect to a CDN)
#   -o   output file
# `wp --info` runs it once: if the download is broken, the build fails here.
RUN curl -fsSL -o /usr/local/bin/wp \
        "https://github.com/wp-cli/wp-cli/releases/download/v${WP_CLI_VERSION}/wp-cli-${WP_CLI_VERSION}.phar" \
    && chmod +x /usr/local/bin/wp \
    && wp --info --allow-root

# Directories the services need:
#   /run/php          php-fpm writes its PID file here (php-fpm.conf: pid =
#                     /run/php/php8.2-fpm.pid); it refuses to start without it
#   /var/www/html     the WordPress files (the volume is mounted on top of it)
#   /var/www/.wp-cli  WP-CLI's cache. We run WP-CLI as www-data, whose home
#                     directory is /var/www, so it must be writable by www-data
RUN mkdir -p /run/php /var/www/html /var/www/.wp-cli \
    && chown -R www-data:www-data /var/www

# Our PHP-FPM "pool" configuration (replaces the stock one, which listens on a
# Unix socket file that NGINX, in another container, could not reach).
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Default working directory for the entrypoint and for `docker exec`.
WORKDIR /var/www/html

# Documentation: php-fpm listens on 9000 (FastCGI) for NGINX. Not published.
EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
```

`srcs/requirements/wordpress/conf/www.conf` (the whole file; it replaces the stock pool file)
```ini
; PHP-FPM pool configuration. In this INI format, comments start with ";".
; A "pool" is a group of PHP worker processes sharing the same settings.
; The name between brackets is the pool name.
[www]

; Unix user and group the worker processes run as. The master process starts
; as root, then the workers drop to www-data: a hacked PHP script cannot then
; modify the system. www-data also owns the WordPress files.
user = www-data
group = www-data

; Where php-fpm waits for FastCGI requests from NGINX.
; Stock value: /run/php/php8.2-fpm.sock, a Unix socket, which is a file and
; only usable inside this container. NGINX is in ANOTHER container, so we
; listen on a TCP port instead. A bare port number = all interfaces.
; ${WP_PORT} is replaced by php-fpm with the environment variable WP_PORT
; (from srcs/.env), so changing the port is a one-line change in .env.
listen = ${WP_PORT}

; How many worker processes exist ("process manager").
;   dynamic: keep between min_spare and max_spare idle workers, never more than
;   max_children in total. Small numbers are plenty for a test site in a VM.
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3

; Send what PHP scripts print on stderr (warnings, errors) to php-fpm's own
; log instead of throwing it away, without the noisy prefix on each line.
; Combined with the -F flag at startup, it ends up in `docker logs wordpress`.
catch_workers_output = yes
decorate_workers_output = no
```

`srcs/requirements/wordpress/tools/entrypoint.sh`
```sh
#!/bin/sh
# Stop on the first error (-e) and on any undefined variable (-u).
set -eu

WP_PATH=/var/www/html

fail() {
    echo "[wordpress] error: $1" >&2
    exit 1
}

# Run WP-CLI as the www-data user instead of root.
#   runuser -u www-data --   run the following command as www-data
#   --path=...               where WordPress lives
# Benefit: every file WP-CLI creates is owned by www-data, the user php-fpm
# runs as, so no `chown -R` is needed and no `--allow-root` flag either.
# "$@" = all the arguments given to the function, each kept as one word.
wpcli() {
    runuser -u www-data -- wp --path="$WP_PATH" "$@"
}

# --- 1. Fail fast if the configuration is incomplete ------------------------
# Loop over the names of the required variables. `eval` builds and runs the
# line  value=${DOMAIN_NAME:-}  (etc.), i.e. reads the variable whose NAME is
# in $var. This avoids writing the same test twelve times.
for var in DOMAIN_NAME NGINX_PORT WP_PORT DB_HOST DB_PORT DB_NAME \
           DB_USER WP_VERSION WP_TITLE WP_ADMIN_USER WP_ADMIN_EMAIL \
           WP_USER WP_USER_EMAIL; do
    eval "value=\${$var:-}"
    [ -n "$value" ] || fail "$var is not set (srcs/.env)"
done
[ -r /run/secrets/db_password ] || fail "secret db_password missing"
[ -r /run/secrets/credentials ] || fail "secret credentials missing"

# Read the secrets. credentials.txt holds two lines:
#   line 1 = WordPress admin password, line 2 = WordPress user password.
#   sed -n 1p   print only line 1 (-n: print nothing unless told to)
#   tr -d '\r'  drop a Windows carriage return if the file has one
DB_PASS=$(tr -d '\r\n' < /run/secrets/db_password)
WP_ADMIN_PASS=$(sed -n 1p /run/secrets/credentials | tr -d '\r')
WP_USER_PASS=$(sed -n 2p /run/secrets/credentials | tr -d '\r')
[ -n "$DB_PASS" ]       || fail "db_password is empty"
[ -n "$WP_ADMIN_PASS" ] || fail "credentials: line 1 (admin password) is empty"
[ -n "$WP_USER_PASS" ]  || fail "credentials: line 2 (user password) is empty"

# Subject rule: the admin login must not contain admin/Admin/administrator.
#   tr '[:upper:]' '[:lower:]'   lowercase it, so "ADMIN" is caught too
#   case ... *admin*)            shell pattern: "admin" anywhere in the name
case "$(printf '%s' "$WP_ADMIN_USER" | tr '[:upper:]' '[:lower:]')" in
    *admin*) fail "WP_ADMIN_USER must not contain 'admin'" ;;
esac

# Public URL of the site. If NGINX is moved to another port during the
# defense, the URL must contain that port, otherwise WordPress redirects the
# browser back to the default port 443, where nothing listens any more.
if [ "$NGINX_PORT" = "443" ]; then
    SITE_URL="https://${DOMAIN_NAME}"
else
    SITE_URL="https://${DOMAIN_NAME}:${NGINX_PORT}"
fi

# The volume's top folder belongs to whoever created it on the host. Give it
# to www-data so WP-CLI (running as www-data) can write into it.
chown www-data:www-data "$WP_PATH"

# --- 2. Wait for the database -------------------------------------------------
# compose already waits for MariaDB's healthcheck, this is a second safety net.
# BOUNDED retry: at most 30 attempts, 1 s apart, then give up with an error
# (the restart policy restarts the container). Never an infinite loop.
#   MYSQL_PWD=...   gives the password through the environment of this single
#                   command, so it does not appear in `ps` output
#   --execute       run one SQL statement and quit; SELECT 1 is the cheapest
#                   possible "are you there?" query
#   >/dev/null 2>&1 hide both normal output and error messages while waiting
tries=0
until MYSQL_PWD="$DB_PASS" mariadb --host="$DB_HOST" --port="$DB_PORT" \
        --user="$DB_USER" --database="$DB_NAME" \
        --execute="SELECT 1" >/dev/null 2>&1; do
    tries=$((tries + 1))
    [ "$tries" -lt 30 ] || fail "MariaDB is not reachable at $DB_HOST:$DB_PORT"
    echo "[wordpress] waiting for MariaDB ($tries/30)..."
    sleep 1
done

# --- 3. Install WordPress, one idempotent step at a time ----------------------
# Each step checks whether it was already done. If the container crashed in
# the middle of the first install, the next start finishes the job instead of
# skipping everything (a single `if wp-config.php exists` guard would skip it).
# Everything happens at container START, not at build time: the volume is
# empty during `docker build` and the database does not exist yet.

# 3a. Download the WordPress PHP files (wp-load.php is one of them).
if [ ! -f "$WP_PATH/wp-load.php" ]; then
    echo "[wordpress] downloading WordPress $WP_VERSION"
    wpcli core download --version="$WP_VERSION"
fi

# 3b. Create wp-config.php, the file holding the database connection settings
#     and the random security keys (WP-CLI generates the keys).
if [ ! -f "$WP_PATH/wp-config.php" ]; then
    wpcli config create \
        --dbname="$DB_NAME" \
        --dbuser="$DB_USER" \
        --dbpass="$DB_PASS" \
        --dbhost="$DB_HOST:$DB_PORT"
fi

# 3c. Every start: write the current DB host:port into wp-config.php, so a
#     MariaDB port change in .env is picked up without reinstalling.
wpcli config set DB_HOST "$DB_HOST:$DB_PORT"

# 3d. Create the WordPress tables and the administrator account.
#     `core is-installed` exits 0 if the tables already exist.
#     --skip-email: there is no mail server, do not try to send the welcome mail.
if ! wpcli core is-installed 2>/dev/null; then
    echo "[wordpress] installing WordPress"
    wpcli core install \
        --url="$SITE_URL" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASS" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email
fi

# 3e. Every start: store the current public URL in the database (WordPress
#     keeps it in the options `home` and `siteurl`). Makes the NGINX port change
#     work: the site follows whatever NGINX_PORT is in .env.
wpcli option update home "$SITE_URL"
wpcli option update siteurl "$SITE_URL"

# 3f. The second, non-admin user required by the subject. Role "author": can
#     write and publish posts and comment, but cannot administer the site.
if ! wpcli user get "$WP_USER" >/dev/null 2>&1; then
    wpcli user create "$WP_USER" "$WP_USER_EMAIL" \
        --role=author \
        --user_pass="$WP_USER_PASS"
fi

# --- 4. Hand over to php-fpm --------------------------------------------------
# exec: php-fpm replaces this shell and becomes PID 1 (receives SIGTERM).
#   -F   stay in the Foreground. By default php-fpm daemonizes (forks into the
#        background and the parent exits): PID 1 would exit and Docker would
#        consider the container finished.
echo "[wordpress] ready, starting php-fpm on port $WP_PORT"
exec php-fpm8.2 -F
```
Notes:
- Your notes: the `sed` on the stock pool file was the most painful part. Shipping a complete `conf/www.conf` (above) removes it. To check the result inside the container: `docker exec wordpress grep -n '^listen' /etc/php/8.2/fpm/pool.d/www.conf` shows `listen = ${WP_PORT}`, and `docker exec wordpress cat /proc/net/tcp6` lists the listening port in hex (`2328` = 9000).
- `clear_env = no`, found in many repos, is not needed: WordPress reads its settings from `wp-config.php`, written by WP-CLI, not from environment variables.
- Your notes: keeping the apt `RUN` and the WP-CLI `RUN` separate costs one extra layer but is easier to debug; merging them gives a smaller image. Either is defensible.
- `wp option update` prints "Value passed ... is unchanged" on normal restarts: that is a success message, not an error.

### 6.3 NGINX with TLS

`srcs/requirements/nginx/Dockerfile`
```dockerfile
FROM debian:bookworm

#   nginx          the web server / reverse proxy, the only entry point (port 443)
#   openssl        generates the self-signed TLS certificate at startup
#   gettext-base   provides `envsubst`, which fills ${VARIABLES} into the
#                  config template at startup
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        nginx \
        openssl \
        gettext-base \
    && rm -rf /var/lib/apt/lists/*

# The config is a TEMPLATE (it contains ${DOMAIN_NAME}, ${NGINX_PORT}...);
# the entrypoint turns it into the real /etc/nginx/nginx.conf at startup.
COPY conf/nginx.conf.template /etc/nginx/nginx.conf.template
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Documentation: HTTPS port. Publishing it on the host is done in compose.
EXPOSE 443

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
```

`srcs/requirements/nginx/conf/nginx.conf.template`
```nginx
# Main NGINX configuration (replaces Debian's /etc/nginx/nginx.conf entirely,
# so Debian's default site in sites-enabled/ is never loaded).
# Syntax: `directive value;` and `block { ... }`. Every directive ends with ";".
# The ${UPPERCASE} variables are filled in by envsubst at container start. NGINX's own variables ($uri, $args...) are left untouched.

# The worker processes (the ones handling requests) run as www-data, not root.
user www-data;
# One worker per CPU core.
worker_processes auto;
# File where the master process writes its PID.
pid /run/nginx.pid;
# Errors go to the container's stderr -> visible with `docker logs nginx`.
error_log /dev/stderr;

events {
    # Max simultaneous connections per worker. 1024 is the usual default.
    worker_connections 1024;
}

http {
    # Maps file extensions to Content-Type headers (.css -> text/css...),
    # otherwise the browser would not apply stylesheets or run scripts.
    include /etc/nginx/mime.types;
    # Content-Type for unknown extensions: "binary file, download it".
    default_type application/octet-stream;
    # One log line per request, on stdout -> `docker logs nginx`.
    access_log /dev/stdout;
    # Do not reveal the NGINX version in headers and error pages.
    server_tokens off;

    # One "virtual server" = one site. There is NO `listen 80` anywhere:
    # plain HTTP is simply not served (and port 80 is not published either).
    server {
        # Accept TLS connections on the HTTPS port, IPv4 and IPv6 ([::]).
        listen ${NGINX_PORT} ssl;
        listen [::]:${NGINX_PORT} ssl;
        # Answer for this domain name (must match the certificate's name).
        server_name ${DOMAIN_NAME};

        # TLS: only versions 1.2 and 1.3 (subject rule). 1.0/1.1 are refused.
        ssl_protocols TLSv1.2 TLSv1.3;
        # Certificate (public) and private key, created by the entrypoint.
        ssl_certificate     /etc/nginx/ssl/inception.crt;
        ssl_certificate_key /etc/nginx/ssl/inception.key;

        # Folder served as the website: the WordPress volume, shared read-only
        # with this container. NGINX serves static files (images, CSS, JS)
        # itself and passes only .php files to php-fpm.
        root /var/www/html;
        # File to serve when a folder is requested ("/" -> "/index.php").
        index index.php index.html;

        # Every request that matches no more specific location below.
        location / {
            # Try, in order: the exact file, the folder, otherwise hand the
            # request to WordPress's index.php, which handles "pretty" URLs
            # like /2026/11/hello-world/ that are not real files.
            # $args = the query string (?p=1...), kept intact.
            try_files $uri $uri/ /index.php?$args;
        }

        # Requests for .php files (`~` = regular expression; \. = a literal dot;
        # $ = end of the path).
        location ~ \.php$ {
            # Security: only pass files that really exist. Otherwise, a request
            # like /uploads/image.jpg/x.php could make PHP execute an uploaded
            # file. Non-existent ones get 404.
            try_files $uri =404;
            # Standard FastCGI variables (request method, query string...),
            # shipped with NGINX.
            include fastcgi_params;
            # Send the request over FastCGI to php-fpm in the `wordpress`
            # container. "wordpress" is resolved by Docker's internal DNS:
            # on a user-defined network, service names are host names.
            fastcgi_pass wordpress:${WP_PORT};
            # Absolute path of the script php-fpm must run. Works because both
            # containers mount the same volume at the same path /var/www/html.
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            # Host name PHP sees. Debian's fastcgi_params sends `$host`, which
            # has NO port: on a non-443 port WordPress would see
            # "login.42.fr", compare it with its URL "login.42.fr:8443" and
            # redirect forever. `$http_host` (what the client typed) would work
            # but is untrusted input, so we send a fixed value computed by the
            # entrypoint. Declared after the include, so this one wins.
            fastcgi_param HTTP_HOST ${SITE_HOST};
        }

        # Never serve hidden files (.htaccess, .git, .env...).
        location ~ /\. {
            deny all;
        }
    }
}
```

`srcs/requirements/nginx/tools/entrypoint.sh`
```sh
#!/bin/sh
set -eu

fail() {
    echo "[nginx] error: $1" >&2
    exit 1
}

# --- 1. Fail fast if the configuration is incomplete ------------------------
[ -n "${DOMAIN_NAME:-}" ] || fail "DOMAIN_NAME is not set (srcs/.env)"
[ -n "${NGINX_PORT:-}" ]  || fail "NGINX_PORT is not set (srcs/.env)"
[ -n "${WP_PORT:-}" ]     || fail "WP_PORT is not set (srcs/.env)"

# --- 2. Self-signed TLS certificate -----------------------------------------
# Created at container start, never stored in git or in the image. The browser
# will warn "not trusted" because no certificate authority signed it: that is
# expected and accepted by the subject. Skipped if it already exists (restart).
#   req -x509            create a certificate directly (not a signing request)
#   -nodes               "no DES": do not encrypt the private key with a
#                        passphrase, NGINX must be able to read it unattended
#   -days 365            valid for one year
#   -newkey rsa:2048     generate a new 2048-bit RSA key pair at the same time
#   -keyout / -out       where to write the private key / the certificate
#   -subj                the certificate's identity, given inline instead of
#                        answering prompts. CN (Common Name) = the domain
#   -addext subjectAltName=DNS:...
#                        modern browsers ignore CN and only check this field
mkdir -p /etc/nginx/ssl
if [ ! -f /etc/nginx/ssl/inception.crt ]; then
    echo "[nginx] generating a self-signed certificate for $DOMAIN_NAME"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/C=FR/O=42/OU=Inception/CN=${DOMAIN_NAME}" \
        -addext "subjectAltName=DNS:${DOMAIN_NAME}" 2>/dev/null
    # Only root (the NGINX master process) may read the private key.
    chmod 600 /etc/nginx/ssl/inception.key
fi

# --- 3. Build the real config from the template -----------------------------
# SITE_HOST = the host part of the site URL, exactly as WordPress stores it:
# "login.42.fr" on the standard port 443, "login.42.fr:8443" on any other.
# It is passed to PHP as HTTP_HOST (see nginx.conf.template for why).
# `export` makes the variable visible to envsubst, a separate program.
if [ "$NGINX_PORT" = "443" ]; then
    SITE_HOST="$DOMAIN_NAME"
else
    SITE_HOST="$DOMAIN_NAME:$NGINX_PORT"
fi
export SITE_HOST

# envsubst replaces ${VAR} by the value of the environment variable VAR.
# The quoted list restricts it to OUR variables; without the list it would
# also replace NGINX's own $uri, $args... with empty strings.
# The single quotes keep the shell from expanding ${...} itself.
envsubst '${DOMAIN_NAME} ${NGINX_PORT} ${WP_PORT} ${SITE_HOST}' \
    < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Check the syntax before starting. A typo gives a clear error in
# `docker logs nginx` instead of a container that silently restarts.
nginx -t

# --- 4. Hand over to NGINX ---------------------------------------------------
# exec: NGINX becomes PID 1.
#   -g 'daemon off;'   extra directive given on the command line: do NOT
#                      daemonize (by default NGINX forks into the background,
#                      PID 1 would exit and the container would stop).
exec nginx -g 'daemon off;'
```
Your notes: there the Dockerfile generates the certificate at build time and ends with `CMD ["nginx", "-g", "daemon off;"]` (no script). That works too, but the domain is then frozen in the image and the private key is stored in an image layer; generating it at start avoids both.

### 6.4 `.dockerignore` (same file in each of the three service folders)
```sh
# Files NOT sent to the Docker daemon when building this image (the "build
# context"). Keeps the context small and makes sure no stray file ends up
# in an image by accident.
.git*
.env*
*.md
```

---

## 7. Makefile (repo root)

Must build through compose and create the folders, secrets and `.env` it needs, so that `git clone` + `make` works on a fresh VM.
```make
# Makefile at the repo root: the only entry point. `make` sets up everything
# and builds/starts the stack through docker compose (subject rule).
# Reminder: recipe lines (the indented commands) MUST start with a real TAB.
# A leading `@` hides the command itself and prints only its output.

# Your 42 login. Default: the Unix user running make, because on the VM your
# user IS your 42 login. Override it with `make LOGIN=jdoe`.
#   ?=               set it only if it was not given already (command line or
#                    environment variable)
#   $(shell whoami)  run the `whoami` command and use what it prints
LOGIN    ?= $(shell whoami)
# Refuse to go on with a login that is not a plain lowercase name: `root`
# (someone ran `sudo make`), or a placeholder such as "bkaras-g", which the
# shell would read as redirections in `rm -rf /home/bkaras-g/data`.
#   $(shell ... | grep -Ex ...)  prints the login back only if the whole of it
#                                (-x) matches the pattern (-E: extended regex)
#   ifeq (a,b) / ifneq (a,b)     true when a and b are equal / differ
#   $(error ...)                 stop make immediately with this message
ifeq ($(strip $(LOGIN)),)
$(error LOGIN is empty. Run: make LOGIN=<your 42 login>)
endif
ifneq ($(shell printf '%s' '$(LOGIN)' | grep -Ex '[a-z][a-z0-9_-]*'),$(LOGIN))
$(error Invalid LOGIN "$(LOGIN)". Run: make LOGIN=<your 42 login>)
endif
ifeq ($(LOGIN),root)
$(error Do not run make as root (no sudo), or pass LOGIN=<your 42 login>)
endif
DOMAIN   := $(LOGIN).42.fr
DATA_DIR := /home/$(LOGIN)/data
# -f: path of the compose file, since it is not in the current folder.
COMPOSE  := docker compose -f srcs/docker-compose.yml

# First target = default target: plain `make` runs `all`.
all: up

# Build the images (only what changed, thanks to the layer cache) and start
# the containers in the background (-d, "detached").
# Prerequisites run first: secrets, .env, data folders, /etc/hosts entry.
up: secrets env dirs hosts
	$(COMPOSE) up -d --build

# Stop AND remove the containers and the network. Volumes (the data) stay.
down:
	$(COMPOSE) down

# Stop the containers without removing them / start them again.
stop:
	$(COMPOSE) stop
start:
	$(COMPOSE) start

# Follow the logs of all services (Ctrl-C to quit) / list the containers.
logs:
	$(COMPOSE) logs -f
ps:
	$(COMPOSE) ps

# Generate the three secret files ONCE (never overwrite, never committed).
#   [ -s file ]          true if the file exists and is not empty
#   ||                   run the right side only if the left side failed
#   openssl rand -hex 12 24 random hexadecimal characters: strong, and safe to
#                        put inside SQL quotes or a shell command
#   chmod 600            readable only by you
# credentials.txt: line 1 = WordPress admin password, line 2 = user password.
secrets:
	@mkdir -p secrets
	@[ -s secrets/db_root_password.txt ] || openssl rand -hex 12 > secrets/db_root_password.txt
	@[ -s secrets/db_password.txt ]      || openssl rand -hex 12 > secrets/db_password.txt
	@[ -s secrets/credentials.txt ]      || { openssl rand -hex 12; openssl rand -hex 12; } > secrets/credentials.txt
	@chmod 600 secrets/*.txt

# Create srcs/.env from the committed template if it does not exist yet (or is
# empty), replacing every "bkaras-g" with $(LOGIN) (sed: s/old/new/g = replace
# all). An existing, filled .env is never overwritten: your edits are kept.
env:
	@[ -s srcs/.env ] || sed 's/bkaras-g/$(LOGIN)/g' srcs/.env.example > srcs/.env

# Host folders backing the two named volumes (they must exist before `up`).
# -p: create parents too, no error if they already exist.
dirs:
	@mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress

# Make bkaras-g.42.fr point to this machine, only if the line is missing.
#   grep -qw    quiet (-q: only the exit status matters, found / not found),
#               whole word (-w: "xjdoe.42.fr" does not count as "jdoe.42.fr")
#   sudo tee -a append as root (a plain `>>` would run without sudo rights)
hosts:
	@grep -qw "$(DOMAIN)" /etc/hosts || echo "127.0.0.1 $(DOMAIN)" | sudo tee -a /etc/hosts > /dev/null

# Remove the containers, the network AND the images built by this project.
clean:
	$(COMPOSE) down --rmi all

# Everything: also the Docker volume objects (-v) and the data on the host,
# then the whole Docker cache. The test refuses to run `rm -rf` if DATA_DIR
# is empty or "/". `sudo` because the containers wrote files as other users
# (mysql, www-data). Secrets and srcs/.env are kept.
fclean:
	$(COMPOSE) down -v --rmi all
	@[ -n "$(DATA_DIR)" ] && [ "$(DATA_DIR)" != "/" ] && sudo rm -rf "$(DATA_DIR)"
	docker system prune -af

# Full rebuild from a clean slate.
re: fclean all

# These targets are command names, not files: always run them, even if a file
# called "clean" or "secrets" exists. (`secrets` IS a folder, so this matters.)
.PHONY: all up down stop start logs ps secrets env dirs hosts clean fclean re
```
`LOGIN` defaults to your Unix user (`whoami`): on the VM your user is your 42 login. The Makefile stops with an error if the login is empty, `root` or not a plain lowercase name, so a placeholder like `bkaras-g` can never reach `sudo rm -rf` (the shell would read `bkaras-g` as redirections). `make env` also refills an *empty* `srcs/.env` (`-s` test).

Mind: recipes need real TABs (check with `cat -A Makefile`: TABs show as `^I`). `make fclean` asks for sudo because files written by the containers belong to other users (mysql, www-data).

---

## 8. Documentation templates

The repos in 0.2 converge on the same structure; sys-harmony and aziddineelm are good short models, tigran's are the most complete.

### README.md
```md
*This project has been created as part of the 42 curriculum by bkaras-g.*

## Description
Goal, overview of the stack (NGINX :443 → php-fpm/WordPress :9000 → MariaDB :3306, one container each, one bridge network, two named volumes), what Docker is used for here, sources included in the repo.

### Design choices and comparisons
1. Virtual Machines vs Docker: ...
2. Secrets vs Environment Variables: ...
3. Docker Network vs Host Network: ...
4. Docker Volumes vs Bind Mounts: ...

## Instructions
Prerequisites, `make`, how to reach https://bkaras-g.42.fr, where the passwords are, how to stop/clean.

## Resources
- Docs and articles actually read (Docker docs, NGINX docs, MariaDB docs, WordPress/WP-CLI docs, ...)
- AI usage: which tasks (e.g. explaining PID 1, reviewing Dockerfiles, comparing repos), which parts of the project, what you verified yourself.
```
### USER_DOC.md
Services provided; `make` / `make down` / `make stop` / `make start`; URLs (`https://bkaras-g.42.fr`, `https://bkaras-g.42.fr/wp-admin`); the browser warning about the self-signed certificate and how to accept it; where credentials live (`secrets/credentials.txt` line 1 = admin, line 2 = user; `secrets/db_*.txt`) and how to change them (edit the file, then `make fclean && make`, since passwords are only applied at first boot); checks (`make ps`, `curl -k https://bkaras-g.42.fr`, `make logs`).
### DEV_DOC.md
Prerequisites (Docker, compose plugin, `/etc/hosts`, `/home/bkaras-g/data`); config files (`srcs/.env` from `.env.example`, `secrets/`); build and launch (`make`, compose commands); manage containers/volumes (`docker exec -it mariadb sh`, `docker volume ls/inspect`, `docker compose logs`); data location (`/home/bkaras-g/data/{mariadb,wordpress}`) and why it survives `down` and reboot; how to change a port (section 9.3).

---

## 9. Verify like the evaluator

### 9.1 What was tested on 2026-11-13 (with these exact files)

Results, from an empty data folder, `bkaras-g` = `ktest`:
- `make secrets env dirs` then `docker compose up -d --build`: three images built, all three containers up, MariaDB and WordPress `healthy`.
- PID 1 is `mariadbd`, `php-fpm: master process`, `nginx: master process nginx -g daemon off;`.
- `https://ktest.42.fr` → 200 with the site title; `/wp-admin/` → redirect to the login page; a real admin login → dashboard 200; CSS served with the right type; `/.htaccess` → 403; a non-existent `.php` → 404.
- Port 80 refused; plain HTTP on the TLS port → 400; TLS 1.0 and 1.1 refused, TLS 1.2 and 1.3 accepted; certificate CN and SAN = the domain.
- Database: `bind_address 0.0.0.0`; database `wordpress`; users `ktest_boss` (administrator) and `writer` (author); root login inside the container works with the password and fails without it.
- Port change of all three at once (NGINX 4443→4444, php-fpm 9000→9001, MariaDB 3306→3307) by editing `.env` + `up -d --build`: site works on the new port, `DB_HOST` updated to `mariadb:3307`, existing post still there, old port closed. Back to 443/9000/3306: works.
- `docker exec <c> kill 1` on each container: each restarted (`RestartCount=1`). `docker compose down` + `up`: content still there.

Bugs this test found in the previous version of this recipe (all fixed above):
1. MariaDB config named `50-inception.cnf` was read *before* Debian's `50-server.cnf`, whose `bind-address = 127.0.0.1` won: WordPress could not connect. Now `99-inception.cnf`.
2. `MYSQL_HOST` in `.env` made `mariadb -uroot -p` inside the MariaDB container connect over the network and fail. Now `DB_HOST`.
3. On any NGINX port other than 443, WordPress redirected to itself forever (Debian's NGINX now sends the host without the port). Now `fastcgi_param HTTP_HOST ${SITE_HOST}`.
4. After a port change, WordPress kept its old URL. Now updated on every start.
5. `docker kill wordpress` was listed as a crash test: Docker treats it as a manual stop and does **not** restart the container.
6. `docker exec wordpress ps ...` fails: `ps` is not installed in `debian:bookworm`. Use `/proc/1/cmdline`.
7. The old healthcheck logged "Access denied for user root" every 5 seconds.

Not tested here: the `hosts` and `fclean` Makefile targets (they need sudo), a real VM reboot, and a browser (curl was used).

### 9.2 The evaluator's checks, in order
Run them from a clean wipe (section 1 command), then `make`.
```sh
# All three containers Up, MariaDB and WordPress (healthy)
docker compose -f srcs/docker-compose.yml ps
# The project network, then who is on it
docker network ls
docker network inspect inception --format '{{range .Containers}}{{.Name}} {{.IPv4Address}}{{println}}{{end}}'
# Docker DNS: service names resolve to network IPs
docker exec wordpress getent hosts mariadb
# Volumes: device must contain /home/bkaras-g/data
docker volume ls
docker volume inspect mariadb_data wordpress_data
# HTTPS works (-k: accept the self-signed certificate; -I: headers only)
curl -k -I https://bkaras-g.42.fr
# HTTP must fail: connection refused
curl -I http://bkaras-g.42.fr
# TLS 1.1 must fail, TLS 1.2 and 1.3 must succeed (look at the "Protocol" line)
openssl s_client -connect bkaras-g.42.fr:443 -tls1_1 </dev/null
openssl s_client -connect bkaras-g.42.fr:443 -tls1_2 </dev/null
openssl s_client -connect bkaras-g.42.fr:443 -tls1_3 </dev/null
# Log into the DB as root (password: secrets/db_root_password.txt), then:
#   SHOW DATABASES; USE wordpress; SHOW TABLES; SELECT user_login FROM wp_users;
docker exec -it mariadb mariadb -uroot -p
# PID 1 of each container is the daemon, not a shell
for c in mariadb wordpress nginx; do docker exec $c sh -c 'tr "\0" " " </proc/1/cmdline; echo'; done
# Crash test: kill PID 1 from inside, wait, check it came back
docker exec wordpress kill 1; sleep 10; docker inspect -f '{{.State.Status}} restarts={{.RestartCount}}' wordpress
# No forbidden pattern (only comments may match)
grep -rnE 'tail -f|sleep infinity|while true|--link|links:|network: host|network_mode|:latest' srcs Makefile
# Nothing sensitive tracked by git
git ls-files | grep -E 'secrets/|\.env$'
git grep -nIE 'password *=|passwd' -- . ':!*.md'
```
Then in the browser: log in as the author and leave a comment; log in as the admin; edit a page; reload the site; reboot the VM; `make`; check the edit is still there.

### 9.3 Practice the "configuration modification" step
Every port lives in `srcs/.env`, and every config reads it:

| Service | Variable | Used by |
|---|---|---|
| NGINX | `NGINX_PORT` | compose `ports:`, `listen` in the NGINX template, the site URL stored by WordPress, `HTTP_HOST` |
| php-fpm | `WP_PORT` | `listen` in `www.conf`, `fastcgi_pass` in the NGINX template |
| MariaDB | `DB_PORT` | `--port` of mariadbd, `DB_HOST` in `wp-config.php`, the wait loop |

Example, NGINX to 8443:
```sh
sed -i 's/^NGINX_PORT=.*/NGINX_PORT=8443/' srcs/.env   # or edit it with vim
make                                                     # = docker compose up -d --build: recreates what changed, data kept
docker compose -f srcs/docker-compose.yml ps             # nginx now shows 0.0.0.0:8443->8443/tcp
curl -k -I https://bkaras-g.42.fr:8443                    # 200; port 443 is now closed
```
Do it once with a timer for each of the three variables, then put them back. Be ready to show *where* the variable ends up (`docker exec nginx grep listen /etc/nginx/nginx.conf`, `docker exec wordpress grep DB_HOST /var/www/html/wp-config.php`). If the evaluator insists on editing a config file rather than `.env`, you know which line in which file to change from the table. Do **not** use `make re` for this: it wipes the data. `EXPOSE` in the Dockerfiles stays at the default value; it is documentation only and does not affect anything.

---

## 10. Pitfalls that cost people the project

| Pitfall | Fix |
|---|---|
| Container exits immediately | Main process daemonized. Use `nginx -g 'daemon off;'`, `php-fpm8.2 -F`, `mariadbd`. End the entrypoint with `exec`. |
| `php-fpm8.2` refuses to start, `/run/php` missing | `mkdir -p /run/php` in the Dockerfile. |
| WordPress cannot reach DB on first boot | MariaDB healthcheck + `depends_on: service_healthy`, plus the bounded retry loop in the WP entrypoint. |
| WordPress cannot reach DB at all, `bind-address` stays 127.0.0.1 | MariaDB reads `mariadb.conf.d/*.cnf` alphabetically, last value wins: name your file `99-...`, not `50-...` (Debian's `50-server.cnf` sets 127.0.0.1). Check: `SELECT @@bind_address;`. |
| `mariadb -uroot -p` inside the MariaDB container says "Access denied for user 'root'@'172.x.x.x'" | A `MYSQL_HOST` environment variable (from `env_file`) makes the client use TCP. Name variables `DB_*`. |
| Site redirects to itself forever on a non-443 port (`ERR_TOO_MANY_REDIRECTS`) | Debian NGINX's `fastcgi_params` sends `HTTP_HOST` without the port. Send `fastcgi_param HTTP_HOST <domain>:<port>` after the include (6.3). |
| After changing the NGINX port, the browser is sent back to port 443 | WordPress stores its URL in the DB (`home`, `siteurl`). Update it on every start (6.2, step 3e). |
| NGINX shows 404 / downloads PHP | NGINX must mount the same `wordpress_data` volume (read-only is fine) at the same path, and `SCRIPT_FILENAME` must resolve; `fastcgi_pass wordpress:<WP_PORT>`. |
| NGINX restarts in a loop while WordPress is down | Expected: `nginx -t` fails when the host name `wordpress` does not resolve. It recovers by itself when WordPress is back. |
| Permission errors on the volume | Host dirs exist before `up`; `chown` in the entrypoints (`mysql` for MariaDB, `www-data` for WordPress). |
| Works once, breaks after `make re` | Init steps not guarded, or old data left in `/home/bkaras-g/data` (use `make fclean` for a true clean slate). |
| DB/password changes ignored after editing the entrypoint or a secret | The marker file skips init when the volume already has data. `make fclean && make`. |
| Cert warning "bad domain" | `CN`, `subjectAltName` and `server_name` must equal `bkaras-g.42.fr`. |
| `.env` or secrets committed | `git rm --cached`, add to `.gitignore`; if already pushed, rotate and rewrite history. Instant 0 otherwise. |
| MariaDB will not restart after a crash | Stale `mysqld.pid` / `mysqld.sock`: deleted at the start of the entrypoint. |
| "Restart on crash" demo does nothing | `docker kill` / `docker stop` count as manual stops; the policy does not apply. Use `docker exec <c> kill 1`. |
| MariaDB logs `io_uring_queue_init() failed with EPERM` | Harmless warning on hosts that disable io_uring (seen on Fedora). MariaDB falls back to normal I/O. |
| Docker install fails on the Debian VM | You copied an Ubuntu repo line; use `download.docker.com/linux/debian`. |
| `permission denied` on `docker` right after `usermod -aG docker` | `newgrp docker` or log out/in. |
| Admin name rejected by the grid | No `admin`/`Admin`/`administrator` substring anywhere in the name (the WP entrypoint refuses to start otherwise). |

---

## 11. Bonus ideas (only after the mandatory part is flawless)

Each = own Dockerfile + service in compose, same rules (no `latest`, no infinite loop, foreground PID 1). All six repos of 0.2 except JaxzTan implement them; sys-harmony and KeroBeros68 are the cleanest references.
- **Redis cache**: `redis-server --protected-mode no --bind 0.0.0.0` in the foreground (or a `redis.conf` with a password from a secret, as sys-harmony does); in WP install the Redis Object Cache plugin with WP-CLI and set `WP_REDIS_HOST=redis`. Install `php8.2-redis` in the WordPress image.
- **FTP** (vsftpd / pure-ftpd): mount `wordpress_data` read-write; passive port range must be published; password from a secret.
- **Static site** (no PHP): tiny NGINX or lighttpd container serving HTML/CSS; route it through the main NGINX by a second `server_name` (subdomain, add it to `/etc/hosts` and to the certificate) or a separate published port.
- **Adminer**: `adminer.php` served with php-fpm, proxied by NGINX (`/adminer` or a subdomain).
- **Free choice**: pick something you can explain in 2 minutes (e.g. a monitoring tool), and know why it is useful.
- **Network isolation** (KeroBeros68): a second network `backend` with `internal: true` for MariaDB/Redis, so the database has no route to the outside at all. Good to talk about, but keep the mandatory part on one network unless you can explain both.

---

## 12. Defense talking points (from your notes, in English, short)

Say these in your own words; the evaluator wants simple terms.

**How Docker and compose work.** Docker does containerization: a container is an isolated environment that runs an app with its dependencies while **sharing the host kernel**. A VM has its own OS and needs a hypervisor that reserves CPU/RAM, which makes it heavier and slower; Docker is often called a lightweight VM, but it just launches a process. Isolation = **namespaces** (processes, network, filesystem, users: the container thinks its process is PID 1 while the host sees a normal PID) + **cgroups** (limits memory, CPU, disk I/O). Docker Compose describes in one YAML how the containers, networks and volumes fit together, so one command builds and runs everything. `dockerd` is the daemon managing images, containers, networks, volumes; the `docker` CLI talks to it.

**Image with vs without compose.** An image is a read-only template built from a Dockerfile (Dockerfile -> image -> container); on its own it does nothing and you chain `docker build` then `docker run` with many flags by hand (network, volumes, secrets, ports, restart policy, start order). With compose, one `docker compose up` builds and wires everything, and after editing one Dockerfile only that image is rebuilt (cache).

**Docker vs VMs.** Lightweight; easier to share; easy to modify and rebuild; layers give caching and sharing (the Debian base layer is stored once for the three images). Downsides to admit: weaker isolation (shared kernel), a Linux host cannot run Windows containers.

**Directory structure.** One Dockerfile/folder per service = microservice architecture, each service with one responsibility and independent; volumes are separated from the rest; `secrets/` is outside `srcs/` so it is never committed; the Makefile launches everything from the root.

**Docker network.** It lets containers talk to each other, with an internal DNS (containers resolve each other by service name: `docker exec wordpress getent hosts mariadb`), like a Netpractice network managed for you. A **bridge** network isolates the project: containers only talk to each other, and only NGINX is exposed outside (port 443) as the reverse proxy. `network: host` would put the containers directly on the host's network (every port they open is open on the VM, no isolation, no DNS by name), hence forbidden.

**Volumes vs bind mounts.** The container's writable layer disappears with the container; volumes keep DB and site files independent of the container lifecycle, so nothing restarts from zero. A named volume is created and tracked by Docker (`docker volume ls`); a bind mount is just a host path written in the service. Ours are named volumes whose storage location is a host folder, as the subject asks.

**Secrets vs environment variables.** Environment variables are visible in `docker inspect`, in `/proc/<pid>/environ`, and are inherited by every child process. Docker secrets are files mounted read-only only into the containers that list them, and never part of the image or of `docker inspect`'s env. Our `.env` holds only non-secret settings.

**PID 1 and `exec`.** Docker watches **PID 1** only. The entrypoint script starts as PID 1, does the setup, then `exec` replaces it with the daemon (same idea as `execve()` in pipex/minishell/webserv). So `docker stop` sends `SIGTERM` to the daemon itself (clean shutdown), and if the daemon dies the container stops and the restart policy restarts it. Without `exec`, the shell stays PID 1 and does not forward signals.

**Why `--bootstrap` is not a background process.** It runs in the foreground, reads the SQL from stdin, and exits before the script continues. No `&`, no server left running, nothing to wait for.

**Build time vs run time.** The Dockerfile installs software (build: no volume, no network, no secrets). The entrypoint configures it with the real data (run). That is why WordPress is downloaded and installed by the entrypoint, into the volume.

**Other terms they may ask.** Reverse proxy (server in front of other services, handles traffic and TLS); TLS/HTTPS (port 443 instead of 80); FastCGI (the protocol NGINX uses to ask php-fpm to run a PHP file); `ENTRYPOINT` vs `CMD` (entrypoint makes the container behave like an executable; `CMD` gives default arguments); why `rm -rf /var/lib/apt/lists/*` and `--no-install-recommends` (smaller layers; you measured the size difference with `docker images`/`docker history`, keep the before/after screenshots); why `&&` in a `RUN` (stop at the first failure and keep it one layer); healthcheck (a command Docker runs regularly to know if the service is really ready, used by `depends_on`).

**Change a port live.** Section 9.3. Time yourself.

---

## 13. Docker commands cheat sheet

```sh
docker build -t <name> <dir>     # build an image from a Dockerfile
docker run --rm -it <image> sh   # run a throwaway container from an image (removed on exit)
docker ps -a                     # list containers (running or not)
docker stop <container>          # stop (SIGTERM, then SIGKILL after 10 s)
docker rm <container>            # remove (its writable layer is lost)
docker images -a                 # list images
docker history <image>           # layers and their sizes; metadata steps show 0B
docker inspect <image|container> # config JSON (Cmd, Env, ExposedPorts, Mounts, Networks, RestartPolicy)
docker exec -it mariadb sh       # shell inside a running container
docker logs -f <container>       # what PID 1 prints (our entrypoints prefix their lines with [service])
docker compose -f srcs/docker-compose.yml ps | logs -f | up -d --build | down
docker volume ls / inspect <v>   # see where the data really lives
docker network inspect inception # which containers are on the network, with their IPs
```
Checking MariaDB by hand (from your notes): `docker exec -it mariadb mariadb -u root -p` (root password from `secrets/db_root_password.txt`), then `SHOW DATABASES;`, `USE wordpress;`, `SHOW TABLES;`, `SELECT user_login FROM wp_users;`.

Remember the tool for the question rather than every flag (from tigran's `EVALUATION_GUIDE.md`):

| Question | Tool |
|---|---|
| What is running? | `docker compose ps` / `docker ps` |
| Why did it fail? | `docker logs <c>` |
| What process is inside? | `docker top <c>` / `docker exec <c> cat /proc/1/cmdline` |
| How is a container configured? | `docker inspect <c>` |
| Where is persistent data? | `docker volume inspect <v>` |
| How are containers connected? | `docker network inspect inception` |
| Does Docker DNS work? | `docker exec wordpress getent hosts mariadb` |
| Does HTTPS work? | `curl -k -I https://bkaras-g.42.fr` |
| Which TLS version works? | `openssl s_client -connect bkaras-g.42.fr:443 -tls1_2` |
| Does MariaDB contain data? | `mariadb` client + SQL |
