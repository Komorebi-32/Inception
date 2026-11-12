# Inception: cooking recipe (subject v5.3)

How to produce every file of the project, in order, so that each line can be defended and each line of the evaluation grid passes.
Replace `<login>` everywhere with your 42 login (domain `<login>.42.fr`, data in `/home/<login>/data`).

> Understand before you paste (subject ch. IV "AI Instructions"): anything below you cannot explain in defense is a liability. Type it yourself, run it, break it, fix it.

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
3. A grade badge is a claim, not proof. A repo that shows the subject version (a `subject.pdf`/`subject.txt` saying "Version: 5.3", or a README linking the v5.3 PDF) is stronger evidence for the version, and a stated validation date is stronger evidence for the grade. Ask peers on your campus for repos they know passed recently.
4. For every repo you keep, read in this order: compose file, then each Dockerfile, then each entrypoint script, then the Makefile. Note anything that differs from section 5-7 and decide why. Never paste; re-type.
5. Add what you learn here (name, link, claim, what you took from it).

### 0.2 Repos already collected (found 2026-11-12, not verified by me)

| Repo | Claim | What it shows |
|---|---|---|
| [Nesplee/INCEPTION](https://github.com/Nesplee/INCEPTION) | 125/100, "Validated on July 9, 2026" | USER_DOC + DEV_DOC, `.env.example`, bonus services |
| [sys-harmony/42_Inception](https://github.com/sys-harmony/42_Inception) | 125/100 badge | USER_DOC + DEV_DOC, new README first line, Docker secrets, fail-fast checks in startup scripts |
| [tigran-sargsyan-w/Inception](https://github.com/tigran-sargsyan-w/Inception) | 125/100, Debian bookworm | USER_DOC + DEV_DOC, `secrets/` |
| [aziddineelm/Inception](https://github.com/aziddineelm/Inception) | "125/100" next to bonus services | USER_DOC + DEV_DOC, new README first line |
| [KeroBeros68/42-Inception](https://github.com/KeroBeros68/42-Inception) | no grade stated; README says "version 5.3" | secrets, `.env.example`, Alpine 3.23, full bonus set |
| [JaxzTan/Inception](https://github.com/JaxzTan/Inception) | no grade stated; links the v5.3 subject | USER_DOC + DEV_DOC, small clean layout |

None of the four 125/100 repos states the subject version, and the two v5.3 repos show no grade. Treat them all as unverified references.

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
| GitHub repos | Reference material only, see 0.2. Nothing copied. |

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
- [ ] `README.md` at root. First line (italic): `*This project has been created as part of the 42 curriculum by <login>.*`
- [ ] README sections: Description, Instructions, Resources (including how AI was used, for which tasks/parts), plus Project description with comparisons: **VM vs Docker, Secrets vs Env vars, Docker network vs Host network, Volumes vs Bind mounts**. In English.
- [ ] `USER_DOC.md` (services, start/stop, access site + admin panel, where credentials are, how to check services run).
- [ ] `DEV_DOC.md` (prerequisites, setup from scratch incl. secrets, Makefile + compose usage, container/volume commands, where data lives and how it persists).

### Live checks
- [ ] Only port 443 reachable; `http://<login>.42.fr` (port 80) refuses; `https://<login>.42.fr` shows the installed site (not the WP installer).
- [ ] TLS v1.2 or v1.3 demonstrated (self-signed warning is fine).
- [ ] One non-empty Dockerfile per service; `docker compose ps` shows all containers up.
- [ ] `docker network ls` shows the project network; be ready to explain Docker networks.
- [ ] WordPress container: no NGINX inside. Volume check: `docker volume ls`, `docker volume inspect <name>` output contains `/home/<login>/data/`.
- [ ] Add a comment as the normal WP user. Log in as admin; admin username must **not** contain `admin`/`Admin`/`administrator`. Edit a page in the dashboard and see it change on the site.
- [ ] MariaDB container: no NGINX inside; same volume check; explain how to log into the DB; DB not empty. WP DB has **2 users**, one of them the admin.
- [ ] **Persistence**: reboot the VM, `docker compose` up again, everything (site edits, DB) is still there.
- [ ] **Configuration modification**: the reviewer picks a service and a new port; you change it, rebuild, restart, and it still works. Practice this (section 9).
- [ ] Containers restart on crash (`restart:` policy).
- [ ] You can explain: how Docker and compose work; image with vs without compose; Docker vs VMs; why the directory structure is what it is.

### Bonus (only if mandatory is flawless): redis cache, FTP server on the WP volume, static site (no PHP), Adminer, free-choice service. One Dockerfile each. Extra ports allowed.

---

## 2. Decisions to make first (and what to answer in defense)

| Decision | Recommendation | Why |
|---|---|---|
| Base image | `debian:bookworm` (Debian 12) | Debian 13 "trixie" is the current stable as of Nov 2026, so the penultimate is bookworm. **Re-check on debian.org/releases the day you build.** If you prefer Alpine, check alpinelinux.org/releases and take the second most recent branch. |
| Tag | Pin it (`debian:bookworm`, or a dated tag), never `latest` | Subject forbids `latest`. Your notes doubt whether `-slim` variants are accepted: plain `debian:bookworm` is the safe choice, ask staff before using `-slim`. |
| Alpine vs Debian | Debian | Your notes: Alpine is lighter but has less documentation and more manual setup (musl, apk); the subject is more about services than image size. Goinfre is capped at 30 GB, but Debian fits. |
| Secrets | Docker secrets for all passwords; `.env` only for non-secret values (domain, usernames, db name) | Subject: `.env` mandatory, secrets strongly recommended; passwords in git = failure. |
| Volumes | Named volumes with `driver_opts` pointing at `/home/<login>/data/...` | Subject forbids bind mounts for these two, but requires data under `/home/<login>/data`. |
| PHP | php-fpm on TCP 9000 | Matches the subject diagram (WordPress+PHP ↔ NGINX on 9000). |
| TLS cert | Self-signed, generated with `openssl` at container start | No cert or key in git. |

Debian bookworm package versions: PHP **8.2**, MariaDB **10.11**. Binary names: `php-fpm8.2`, `mariadbd` / `mariadb-admin` (older `mysqld`/`mysqladmin` still exist as links).

---

## 3. Target layout

```
<repo>/
├── Makefile
├── README.md   USER_DOC.md   DEV_DOC.md
├── .gitignore                  # secrets/  srcs/.env
├── secrets/                    # NOT committed (generated by `make secrets`)
│   ├── credentials.txt         # wp admin + wp user logins, for the evaluator
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env                    # NOT committed; commit .env.example instead
    ├── .env.example
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/    { Dockerfile, .dockerignore, conf/50-inception.cnf, tools/entrypoint.sh }
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
- Install `sudo` (as root), `ssh` (copy-paste is much easier; same steps as Born2beRoot, root login disabled), `vim`, `make`.

### 4.2 Docker install
```sh
sudo apt install -y ca-certificates curl gnupg lsb-release                      # dependencies
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg   # Docker's key
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null   # Docker's repo
sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
docker --version && docker compose version
```
**Correction to your notes:** they use `download.docker.com/linux/ubuntu` in both the key and repo lines. On a Debian VM use `linux/debian`, as above.

### 4.3 Your user
```sh
sudo usermod -aG docker <login>
newgrp docker            # refresh group membership in the current shell, otherwise `docker` still says permission denied
```
Check disk use as you go: `du -sh /sgoinfre/goinfre/Perso/<login>` (30 GB quota).

### 4.4 Project host prep
1. Create the data dirs: `mkdir -p /home/<login>/data/mariadb /home/<login>/data/wordpress`.
2. Map the domain: add `127.0.0.1 <login>.42.fr` to `/etc/hosts` (`sudo`).
3. `.gitignore`:
   ```
   secrets/
   srcs/.env
   ```
   If you use a `.env`, never push it: your notes (and the grid) say that is a **0**. Commit `.env.example` instead.

---

## 5. Config files

### 5.1 `srcs/.env.example` (copy to `srcs/.env`, no passwords inside)
```env
DOMAIN_NAME=<login>.42.fr
DATA_DIR=/home/<login>/data

MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_HOST=mariadb

WP_TITLE=Inception
WP_ADMIN_USER=<login>_boss          # must NOT contain admin/Admin/administrator
WP_ADMIN_EMAIL=<login>@student.42.fr
WP_USER=editor
WP_USER_EMAIL=editor@student.42.fr
```

### 5.2 Secrets: `secrets/` (created by `make secrets`, see 7)
`db_root_password.txt`, `db_password.txt`, `credentials.txt` (WP admin password on line 1, WP user password on line 2). The subject's tree shows exactly these three.

### 5.3 `srcs/docker-compose.yml`
No `version:` key (Compose v2). Only NGINX publishes a port.
```yaml
services:
  mariadb:
    build: ./requirements/mariadb
    image: mariadb
    container_name: mariadb
    restart: unless-stopped
    env_file: .env
    secrets: [db_root_password, db_password]
    volumes:
      - db_data:/var/lib/mysql
    networks: [inception]
    healthcheck:
      test: ["CMD-SHELL", "mariadb-admin ping -h localhost --silent"]
      interval: 5s
      timeout: 3s
      retries: 20

  wordpress:
    build: ./requirements/wordpress
    image: wordpress
    container_name: wordpress
    restart: unless-stopped
    env_file: .env
    secrets: [db_password, credentials]
    volumes:
      - wp_data:/var/www/html
    networks: [inception]
    depends_on:
      mariadb:
        condition: service_healthy

  nginx:
    build: ./requirements/nginx
    image: nginx
    container_name: nginx
    restart: unless-stopped
    env_file: .env
    ports:
      - "443:443"
    volumes:
      - wp_data:/var/www/html:ro
    networks: [inception]
    depends_on: [wordpress]

networks:
  inception:
    driver: bridge

volumes:
  db_data:
    driver: local
    driver_opts: { type: none, o: bind, device: "${DATA_DIR}/mariadb" }
  wp_data:
    driver: local
    driver_opts: { type: none, o: bind, device: "${DATA_DIR}/wordpress" }

secrets:
  db_root_password: { file: ../secrets/db_root_password.txt }
  db_password:      { file: ../secrets/db_password.txt }
  credentials:      { file: ../secrets/credentials.txt }
```
Things to be able to explain:
- `image: nginx` next to `build:` names the built image after the service (subject rule). It does not pull anything.
- Volume `o: bind` is the local driver mounting a host dir; it is still a **Docker named volume** (shows in `docker volume ls`, and `inspect` shows the device path under `/home/<login>/data`). A `- /host/path:/ctr/path` line in a service would be a bind mount, which is forbidden here.
- `restart: unless-stopped` satisfies "restart in case of a crash".
- `${DATA_DIR}` is read from `srcs/.env` (compose auto-loads `.env` next to the yml for substitution).
- Containers reach each other by service name (`mariadb`, `wordpress`) via Docker's DNS on the `inception` network.

---

## 6. The three images

General rules for all three Dockerfiles: `FROM debian:bookworm`; install in one `RUN` with `apt-get update && apt-get install -y --no-install-recommends ... && rm -rf /var/lib/apt/lists/*`; **no password anywhere**; `ENTRYPOINT` = your script (shebang, `#!/bin/sh`), and the script ends with `exec <daemon in foreground>` so the daemon is PID 1 and receives `SIGTERM`.

### 6.1 MariaDB

`requirements/mariadb/Dockerfile`
```dockerfile
FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
        mariadb-server mariadb-client \
    && rm -rf /var/lib/apt/lists/*

COPY conf/50-inception.cnf /etc/mysql/mariadb.conf.d/50-inception.cnf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && mkdir -p /run/mysqld && chown mysql:mysql /run/mysqld

EXPOSE 3306
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
```

`conf/50-inception.cnf`
```ini
[mysqld]
bind-address = 0.0.0.0
```
(Default is localhost only; other containers could not connect.)

`tools/entrypoint.sh`: the logic is "first boot: init the data dir, create DB and users with a temporary server that is **not** reachable from the network, stop it; every boot: `exec` the real server".
```sh
#!/bin/sh
set -e

DB_PASS=$(cat /run/secrets/db_password)
ROOT_PASS=$(cat /run/secrets/db_root_password)

mkdir -p /run/mysqld && chown mysql:mysql /run/mysqld

if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    chown -R mysql:mysql /var/lib/mysql
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null

    mariadbd --user=mysql --skip-networking &      # temporary, build-time-style bootstrap
    TMP_PID=$!
    for i in $(seq 1 30); do                       # bounded wait, NOT an infinite loop
        mariadb-admin ping --silent && break
        sleep 1
    done

    mariadb <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASS}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    mariadb-admin -uroot -p"${ROOT_PASS}" shutdown
    wait "$TMP_PID"
fi

exec mariadbd --user=mysql
```
Careful: this script starts a background process once during init. The grid forbids background commands **in the ENTRYPOINT** when they are used to keep the container alive (`nginx & bash`). Here the temporary server is stopped before the script ends and the final process is `exec`'d in the foreground. Be ready to explain that distinction. If you want zero risk, run the bootstrap with `mariadbd --bootstrap < init.sql` (reads SQL from stdin, no background process); it is a good alternative to know about.

**Variant from your notes (known to work in your project).** Instead of `mariadbd --skip-networking &`:
1. Remove stale `/var/run/mysqld/mysqld.pid` and `mysqld.sock` at every start. After a crash or brutal stop MariaDB sees them and refuses to start, believing an instance is still running.
2. `mkdir -p /var/run/mysqld && chown mysql:mysql /var/run/mysqld`.
3. Keep a **flag file** next to the data dir. Install only if the flag or the DB directory is missing, so an interrupted install is redone and a finished one is skipped.
4. First boot: `service mariadb start`, wait with a **bounded** loop until it answers, create the database and the user from `.env`/secrets, `FLUSH PRIVILEGES`, then stop it (`mysqladmin shutdown`).
5. Final step: `exec mysqld_safe --bind-address=0.0.0.0` (foreground, becomes PID 1; `0.0.0.0` so other containers can connect, default is `127.0.0.1` only).

Why the shutdown matters (say this in defense): Docker watches **PID 1** only. PID 1 here is your entrypoint script; a service started in the background keeps the port busy and would not be PID 1. So the temporary server is stopped, then `exec` replaces the shell with the real server (same idea as `execve()` in pipex/minishell/webserv). Both variants rely on stopping the temporary server before `exec`, which is why they are consistent with the grid's "no background process" rule.

### 6.2 WordPress + php-fpm

`requirements/wordpress/Dockerfile`
```dockerfile
FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
        php8.2-fpm php8.2-mysql php8.2-curl php8.2-gd php8.2-intl \
        php8.2-mbstring php8.2-xml php8.2-zip php8.2-cli \
        mariadb-client curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /usr/local/bin/wp \
        https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh && mkdir -p /run/php /var/www/html

WORKDIR /var/www/html
EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
```
`conf/www.conf` : start from the stock pool file (`docker run --rm debian:bookworm cat /etc/php/8.2/fpm/pool.d/www.conf` after installing php8.2-fpm, or copy it out of a throwaway container) and change only:
```ini
listen = 9000          ; was a unix socket; NGINX is in another container, so TCP
clear_env = no         ; php-fpm would otherwise drop env vars
```
(`listen = 9000` binds all interfaces inside the container, which is what NGINX on the same network needs.)

`tools/entrypoint.sh`
```sh
#!/bin/sh
set -e

DB_PASS=$(cat /run/secrets/db_password)
WP_ADMIN_PASS=$(sed -n 1p /run/secrets/credentials)
WP_USER_PASS=$(sed -n 2p /run/secrets/credentials)

cd /var/www/html

if [ ! -f wp-config.php ]; then
    wp core download --allow-root

    for i in $(seq 1 30); do
        mariadb-admin ping -h"${MYSQL_HOST}" -u"${MYSQL_USER}" -p"${DB_PASS}" --silent && break
        sleep 1
    done

    wp config create --allow-root \
        --dbname="${MYSQL_DATABASE}" --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASS}" --dbhost="${MYSQL_HOST}"

    wp core install --allow-root \
        --url="https://${DOMAIN_NAME}" --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" --admin_password="${WP_ADMIN_PASS}" \
        --admin_email="${WP_ADMIN_EMAIL}" --skip-email

    wp user create "${WP_USER}" "${WP_USER_EMAIL}" --role=author \
        --user_pass="${WP_USER_PASS}" --allow-root

    chown -R www-data:www-data /var/www/html
fi

exec php-fpm8.2 -F
```
Notes:
- Everything runs at **container start**, not at build: the volume is empty at build time and the DB does not exist yet. This is the build-vs-run distinction the evaluators probe.
- `-F` keeps php-fpm in the foreground (PID 1). Without it, it daemonizes and the container exits.
- The `if [ ! -f wp-config.php ]` guard is what makes the reboot/persistence test pass: second start does not reinstall.
- The `for ... seq 1 30` loops are bounded retries, not infinite loops.
- Two WP users, one admin (name without "admin"), as the subject requires.
- Your notes: the `sed`/`grep` on the pool file was the most painful part. Its job is to make php-fpm listen on port 9000 on all interfaces instead of a unix socket. Shipping a ready `conf/www.conf` (as above) avoids runtime `sed`; if you keep `sed`, always check the result with `grep -n '^listen' /etc/php/8.2/fpm/pool.d/www.conf` inside the container.
- Your notes: create the PHP runtime dir (`/run/php`) and give `www-data` ownership of the WordPress files; the WP and MariaDB dirs live in volumes but are mounted into the containers, so ownership must be set at runtime, not at build.
- Your notes: keeping the apt `RUN` and the wp-cli `RUN` separate costs one extra layer but is easier to debug; merging them gives a smaller image. Either is defensible.

### 6.3 NGINX with TLS

`requirements/nginx/Dockerfile`
```dockerfile
FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
        nginx openssl gettext-base \
    && rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf.template /etc/nginx/nginx.conf.template
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 443
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
```

`conf/nginx.conf.template`
```nginx
user www-data;
worker_processes auto;
pid /run/nginx.pid;
error_log /dev/stderr;

events { worker_connections 1024; }

http {
    include /etc/nginx/mime.types;
    access_log /dev/stdout;

    server {
        listen 443 ssl;
        listen [::]:443 ssl;
        server_name ${DOMAIN_NAME};

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_certificate     /etc/nginx/ssl/server.crt;
        ssl_certificate_key /etc/nginx/ssl/server.key;

        root /var/www/html;
        index index.php index.html;

        location / {
            try_files $uri $uri/ /index.php?$args;
        }

        location ~ \.php$ {
            include fastcgi_params;
            fastcgi_pass wordpress:9000;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        }
    }
}
```
No `listen 80` block at all: that is how "http must not connect" is satisfied (and the port is not published anyway). Logs go to stdout/stderr so `docker logs` works. `${DOMAIN_NAME}` is replaced by envsubst, which is restricted below so NGINX's own `$uri`, `$document_root` variables are left alone.

`tools/entrypoint.sh`
```sh
#!/bin/sh
set -e

mkdir -p /etc/nginx/ssl
if [ ! -f /etc/nginx/ssl/server.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/server.key -out /etc/nginx/ssl/server.crt \
        -subj "/C=FR/O=42/CN=${DOMAIN_NAME}"
fi

envsubst '${DOMAIN_NAME}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

exec nginx -g 'daemon off;'
```

Your notes: here the Dockerfile generates the certificate with a longer `openssl` command and ends with `CMD ["nginx", "-g", "daemon off;"]` (no script needed, so `CMD` instead of `ENTRYPOINT`). `daemon off` matters because NGINX daemonizes by default, PID 1 would exit and the container would stop. Both this and the entrypoint-script version above are valid.

### 6.4 `.dockerignore` (each service folder)
```
.git
*.md
```

---

## 7. Makefile (repo root)

Must build through compose and create the dirs and secrets it needs.
```make
LOGIN    := <login>
DATA_DIR := /home/$(LOGIN)/data
COMPOSE  := docker compose -f srcs/docker-compose.yml

all: up

up: secrets env
	mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

# Generate secrets once, never overwrite, never committed.
secrets:
	@mkdir -p secrets
	@[ -s secrets/db_root_password.txt ] || openssl rand -base64 18 > secrets/db_root_password.txt
	@[ -s secrets/db_password.txt ]      || openssl rand -base64 18 > secrets/db_password.txt
	@[ -s secrets/credentials.txt ]      || { openssl rand -base64 12 > secrets/credentials.txt; openssl rand -base64 12 >> secrets/credentials.txt; }

env:
	@[ -f srcs/.env ] || cp srcs/.env.example srcs/.env

clean: down
	docker system prune -af

# Also wipes persistent data. Use for a clean-slate defense.
fclean: down
	docker system prune -af --volumes
	sudo rm -rf $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress

re: fclean all

.PHONY: all up down stop start logs ps secrets env clean fclean re
```
Mind: Makefile recipes need real TABs. `sudo rm` is needed because files written by the containers are owned by root/www-data/mysql. `make secrets` runs on the evaluator's machine after `git clone`, so no password is ever in the repo; point them to `secrets/credentials.txt` from USER_DOC (the grid says secrets files "created during the evaluation" are fine).

---

## 8. Documentation templates

### README.md
```md
*This project has been created as part of the 42 curriculum by <login>.*

## Description
Goal, overview of the stack (NGINX → php-fpm/WordPress → MariaDB), what Docker is used for here, sources included in the repo.

### Design choices and comparisons
- Virtual Machines vs Docker: ...
- Secrets vs Environment Variables: ...
- Docker Network vs Host Network: ...
- Docker Volumes vs Bind Mounts: ...

## Instructions
Prerequisites, `make`, how to reach https://<login>.42.fr, how to stop/clean.

## Resources
- Docs and articles actually read (Docker docs, NGINX docs, WordPress/WP-CLI docs, ...)
- AI usage: which tasks (e.g. explaining PID 1, reviewing Dockerfiles), which parts of the project, what you verified yourself.
```
### USER_DOC.md
Services provided; `make` / `make down` / `make stop` / `make start`; URLs (`https://<login>.42.fr`, `https://<login>.42.fr/wp-admin`); where credentials live (`secrets/credentials.txt`, `secrets/db_*.txt`) and how to change them; checks (`make ps`, `docker compose ps`, `curl -k https://<login>.42.fr`, `make logs`).
### DEV_DOC.md
Prerequisites (Docker, compose plugin, `/etc/hosts`, `/home/<login>/data`); config files (`srcs/.env`, `secrets/`); build and launch (`make`, compose commands); manage containers/volumes (`docker exec -it mariadb sh`, `docker volume ls/inspect`, `docker compose logs`); data location (`/home/<login>/data/{mariadb,wordpress}`) and why it survives `down` and reboot.

---

## 9. Verify like the evaluator

Run these in order from a clean wipe (section 1 command), then `make`.
```sh
docker compose -f srcs/docker-compose.yml ps                 # 3 services Up
docker network ls                                            # inception network
docker volume ls; docker volume inspect srcs_wp_data         # path contains /home/<login>/data
curl -k -I https://<login>.42.fr                             # 200/301, via TLS
curl -I http://<login>.42.fr                                 # must fail (connection refused)
openssl s_client -connect <login>.42.fr:443 -tls1_1 </dev/null   # must fail
openssl s_client -connect <login>.42.fr:443 -tls1_2 </dev/null   # must succeed
docker exec -it mariadb mariadb -uroot -p"$(cat secrets/db_root_password.txt)" -e 'SHOW DATABASES; SELECT user FROM wordpress.wp_users;'
docker exec wordpress ps -o pid,cmd 1                        # PID 1 is php-fpm8.2, not a shell
docker kill wordpress; sleep 5; docker compose -f srcs/docker-compose.yml ps   # restarted
grep -rnE 'tail -f|sleep infinity|while true|--link|links:|network: host|latest' srcs Makefile   # must print nothing
git grep -nIE 'password|passwd|secret' -- . ':!*.md'         # nothing sensitive
```
Then in the browser: leave a comment as the author; log in as the admin; edit a page; reload the site; reboot the VM; `make`; check the edit is still there.

**Practice the "configuration modification" step**: e.g. have NGINX listen on 8443. Change `listen 8443 ssl;` in the template, `"8443:8443"` in compose, `make re` (or `docker compose up -d --build`), then `https://<login>.42.fr:8443`. Do it once with a timer; also try changing the php-fpm port (both `www.conf` and `fastcgi_pass`) and the MariaDB port.

---

## 10. Pitfalls that cost people the project

| Pitfall | Fix |
|---|---|
| Container exits immediately | Main process daemonized. Use `nginx -g 'daemon off;'`, `php-fpm8.2 -F`, `mariadbd`. End the entrypoint with `exec`. |
| `php-fpm8.2: unable to bind` / `/run/php missing` | `mkdir -p /run/php` in the Dockerfile. |
| WordPress cannot reach DB on first boot | MariaDB healthcheck + `depends_on: service_healthy`, plus the bounded retry loop in the WP entrypoint. |
| NGINX shows 404 / downloads PHP | NGINX must mount the same `wp_data` volume (read-only is fine) and `SCRIPT_FILENAME` must resolve; `fastcgi_pass wordpress:9000`. |
| Permission errors on the volume | Host dirs exist before `up`; `chown www-data` inside the WP entrypoint; `chown mysql` for MariaDB. |
| Works once, breaks after `make re` | Init steps not guarded, or old data left in `/home/<login>/data` (use `make fclean` for a true clean slate). |
| DB changes ignored after editing the entrypoint | The `if [ ! -d /var/lib/mysql/$MYSQL_DATABASE ]` guard skips init when the volume already has data. Wipe the data dir. |
| Cert warning "bad domain" | `CN`/`server_name` must equal `<login>.42.fr`. |
| `.env` or secrets committed | `git rm --cached`, add to `.gitignore`; if already pushed, rotate and rewrite history. Instant 0 otherwise. |
| MariaDB will not restart after a crash | Stale `mysqld.pid` / `mysqld.sock`: delete them at the start of the entrypoint. |
| Docker install fails on the Debian VM | You copied an Ubuntu repo line; use `download.docker.com/linux/debian`. |
| `permission denied` on `docker` right after `usermod -aG docker` | `newgrp docker` or log out/in. |
| Admin name rejected by the grid | No `admin`/`Admin`/`administrator` substring anywhere in the name. |

---

## 11. Bonus ideas (only after the mandatory part is flawless)

Each = own Dockerfile + service in compose, same rules (no `latest`, no infinite loop, foreground PID 1).
- **Redis cache**: `redis-server --protected-mode no --bind 0.0.0.0` in the foreground; in WP set `WP_REDIS_HOST=redis` and install the Redis Object Cache plugin through WP-CLI.
- **FTP** (vsftpd / pure-ftpd): mount `wp_data` read-write; passive port range must be published; password from a secret.
- **Static site** (no PHP): tiny NGINX container serving HTML/CSS; route it through the main NGINX by a second `server_name` or a separate published port.
- **Adminer**: `adminer.php` served with php-fpm or `php -S`, proxied by NGINX (`/adminer`).
- **Free choice**: pick something you can explain in 2 minutes (e.g. a monitoring tool), and know why it is useful.

---

## 12. Defense talking points (from your notes, in English, short)

Say these in your own words; the evaluator wants simple terms.

**How Docker and compose work.** Docker does containerization: a container is an isolated environment that runs an app with its dependencies while **sharing the host kernel**. A VM has its own OS and needs a hypervisor that reserves CPU/RAM, which makes it heavier and slower; Docker is often called a lightweight VM, but it just launches a process. Isolation = **namespaces** (processes, network, filesystem, users: the container thinks its process is PID 1 while the host sees a normal PID) + **cgroups** (limits memory, CPU, disk I/O). Docker Compose describes in one YAML how the containers, networks and volumes fit together, so one command builds and runs everything. `dockerd` is the daemon managing images, containers, networks, volumes; the `docker` CLI talks to it.

**Image with vs without compose.** An image is a read-only template built from a Dockerfile (Dockerfile -> image -> container); on its own it does nothing and you chain `docker build` then `docker run` with many flags by hand. With compose, one `docker compose up` builds and wires everything, and after editing one Dockerfile only that image is rebuilt (cache).

**Docker vs VMs.** Lightweight; easier to share; easy to modify and rebuild; layers give caching and sharing (the Debian base layer is stored once). Downsides to admit: weaker isolation (shared kernel), a Linux host cannot run Windows containers.

**Directory structure.** One Dockerfile/folder per service = microservice architecture, each service with one responsibility and independent; volumes are separated from the rest; `secrets/` is outside `srcs/` so it is never committed; the Makefile launches everything from the root.

**Docker network.** It lets containers talk to each other, with an internal DNS (containers resolve each other by service name), like a Netpractice network managed for you. A **bridge** network isolates the project: containers only talk to each other, and only NGINX is exposed outside (port 443) as the reverse proxy. `network: host` would remove that isolation, hence forbidden.

**Volumes.** The container's writable layer disappears with the container; volumes keep DB and site files independent of the container lifecycle, so nothing restarts from zero.

**Other terms they may ask.** Reverse proxy (server in front of other services, handles traffic and security); TLS/HTTPS (port 443 instead of 80); PID 1 and why `exec` / foreground; `ENTRYPOINT` vs `CMD` (entrypoint makes the container behave like an executable); why `apt-get clean`/`rm -rf /var/lib/apt/lists/*` and `--no-install-recommends` (smaller layers; you measured the size difference with `docker images`/`docker history`, keep the before/after screenshots); why `&&` in a `RUN` (stop at the first failure and keep it one layer).

**Change a port live.** Prepare all of them in advance: NGINX (`listen` + compose `ports`), php-fpm (`listen` in the pool file + `fastcgi_pass`), MariaDB (`port` in its conf + `MYSQL_HOST`/connection settings in WP). Time yourself.

---

## 13. Docker commands cheat sheet

```sh
docker build -t <name> <dir>     # build an image from a Dockerfile
docker run --rm -it <image> sh   # run a container from an image
docker ps -a                     # list containers (running or not)
docker stop <container>          # stop
docker rm <container>            # remove (its writable layer is lost)
docker images -a                 # list images
docker history <image>           # layers and their sizes; metadata steps show 0B
docker inspect <image|container> # config JSON (Cmd, Env, ExposedPorts, Mounts, Networks)
docker exec -it mariadb sh       # shell inside a running container
docker compose -f srcs/docker-compose.yml ps | logs -f | up -d --build | down
docker volume ls / inspect <v>   # see where the data really lives
```
Checking MariaDB by hand (from your notes): `docker exec -it mariadb sh`, then `mariadb -u root -p` (root password from `secrets/db_root_password.txt`), then `SHOW DATABASES;`, `USE wordpress;`, `SHOW TABLES;`, `SELECT user_login FROM wp_users;`.
