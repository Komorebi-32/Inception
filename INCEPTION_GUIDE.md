# Inception (subject v5.3) — Learning Guide

> Goal: finish by **Friday 13 Nov 2026** and, more importantly, understand how Docker works well enough to defend every line you submit (the subject's AI rules say the same: only submit what you can explain).

Contents
0. Reality check on sources
1. Docker basics and vocabulary
2. The subject explained (rule by rule)
3. How to proceed (architecture, order of work, hints, pitfalls)
4. Schedule Tue → Fri
5. Defense cheat-sheet

---

## 0. Reality check on sources

I searched for tutorials and GitHub repos. Honest findings:

- **No repo I found ships the v5.3 PDF.** The closest I could verify is [razuline/42Paris](https://github.com/razuline/42Paris/tree/main/Inception), which contains a **v5.2** PDF (already has USER_DOC.md / DEV_DOC.md, "penultimate stable" rule). I can't diff 5.2 vs 5.3 for you; treat your own PDF as the only truth. Notably, check that the rules you read in *your* PDF (secrets, `.env`, README "AI usage", no `latest`) are satisfied, because several older repos predate them.
- **The well-starred repos are old.** The most starred is [vbachele/Inception](https://github.com/vbachele/Inception) (~269★, last push 2024) which has a tutorial-style README, but it targets an older subject. The repos matching the recent subject (with USER_DOC/DEV_DOC) are small: [LLuisPP/42Cursus](https://github.com/LLuisPP/42Cursus/tree/main/inception) (23★), [Sabofxx/42](https://github.com/Sabofxx/42/tree/main/tronc-commun-42/inception) (14★), [razuline/42Paris](https://github.com/razuline/42Paris/tree/main/Inception) (11★), [slowTake/hiveStudy](https://github.com/slowTake/hiveStudy/tree/main/Rank5/Inception), [d3bvstack/Inception](https://github.com/d3bvstack/Inception) (README follows the new "created as part of the 42 curriculum" first-line rule).
- Other repos (older subject, still good for understanding): [waltergcc/42-inception](https://github.com/waltergcc/42-inception) (18★, has a full guide), [mcombeau/inception](https://github.com/mcombeau/inception), [llefranc/42_inception](https://github.com/llefranc/42_inception), [alexnik42/inception](https://github.com/alexnik42/inception).
- Tutorials: [DEV Community — "Docker, NGINX, WordPress, MariaDB tutorial Inception42"](https://dev.to/alejiri/docker-nginx-wordpress-mariadb-tutorial-inception42-1eok) and the [Zenn article by justhiro](https://zenn.dev/justhiro/articles/c454cc1fbc784e) (incremental build; the author warns it deviates from the spec). I only saw search summaries of these, not the full pages.
- Things I did notice in the repos I read (LLuisPP): `FROM debian:bullseye` is **too old** now (see §2 "penultimate"), and the compose passes passwords through `env_file` rather than Docker secrets — don't copy that; v5.3 says secrets are strongly recommended.

**Use repos to compare, not to copy.** Your evaluators will ask you to modify things live.

---

## 1. Docker basics and vocabulary

### 1.1 The big idea
A **container** is just a normal Linux **process** (or a small tree of processes) that the kernel isolates so it *thinks* it has its own machine. No second kernel, no hardware emulation. Isolation comes from kernel features:
- **Namespaces**: limit what the process can *see*. It gets its own private copy of a system table instead of the host's global one. Inside, your process is PID 1 (on the host it is just a normal PID like 4821).
- **cgroups**: limit what the process can *use* (CPU/RAM/IO).
- **Capabilities / seccomp**: limit what the process can *do* (privileges, syscalls).
- **Union filesystem (overlayfs)**: the container's filesystem is stacked read-only layers (the image) + a thin writable layer on top.

**Namespace, in general**: a named scope in which names are unique and have meaning (two "Anna" in two different families are different people; `std::string` vs `mylib::string` in C++). Etymology: *name* (Old English *nama*, PIE *\*h₁nómn̥*, cf. Latin *nomen*) + *space* (Latin *spatium*, "room, area") = "a space of names". Linux reuses the idea for system resources: "PID 1" resolves to a different process depending on which PID namespace you are in.

| Linux namespace | What the container sees |
|---|---|
| **PID** | only its own process tree (main process = PID 1) |
| **NET** | its own `eth0`, IP, routing table, ports (two containers can both listen on 80) |
| **MNT** | its own filesystem root `/`, built from the image (host files invisible unless mounted) |
| **USER** | its own UID/GID mapping (root inside can be unprivileged on the host) |
| **UTS** | its own hostname |
| **IPC** | its own shared memory / message queues |

Try it: `docker run --rm alpine ps` shows 1-2 processes; `docker run --rm --pid=host alpine ps` shows the host's (PID namespace shared).

Why it matters for Inception: containers reach each other by service name because each has its own NET namespace; data survives only in volumes because the MNT view is discarded with the container; PID 1 behaviour decides whether the container lives or dies.

### 1.2 VM vs container (README asks you to compare!)
| | Virtual machine | Docker container |
|---|---|---|
| What's virtualised | Hardware (hypervisor runs a full guest OS + kernel) | The OS view (shares host kernel) |
| Size / start | GBs, minutes | MBs, ~seconds |
| Isolation | Strong (separate kernel) | Weaker (shared kernel) |
| Use | Run a whole OS | Run one app/process with its dependencies |

Note the irony: the subject makes you run Docker **inside a VM**. The VM is your "host".

### 1.3 Vocabulary
- **Image**: read-only template, built from a Dockerfile. Like a class. It has **2 parts**:
  1. **Layers**: the stack of filesystem diffs (the files).
  2. **Config**: a small JSON of startup settings (default command, env vars, exposed ports, workdir, user). See it with `docker inspect <image>`.
- **Layer**: one read-only slice of filesystem holding only the files added/changed/deleted by one build step. Layers are merged by overlayfs into a single view; if a file exists in several layers, the top one wins. Only instructions that touch files (`FROM`, `RUN`, `COPY`/`ADD`) add content; `CMD`, `ENV`, `EXPOSE` only change metadata.
  ```
  ┌─────────────────────────┐
  │ container layer (R/W)   │ ← created at `docker run`, deleted with the container
  ├─────────────────────────┤
  │ layer 3: COPY conf      │ ┐
  │ layer 2: RUN apt install│ │ image layers, read-only
  │ layer 1: FROM debian    │ ┘
  └─────────────────────────┘
  ```
  - **Why this design**: (1) *caching*: unchanged step + everything before it is reused; (2) *sharing*: ten images on `debian:bookworm` store that base once on disk; (3) *cheap containers*: a container only adds a thin writable layer, and **copy-on-write** copies a modified file up into it, leaving the original intact.
  - **A layer is a frozen record of what one instruction changed; once built it can never be edited.** That immutability is what makes the design work:
    1. *Safe caching*: an unchangeable layer can be reused whenever the instruction and everything before it are identical, with no need to re-check it.
    2. *Safe sharing*: ten images on `debian:bookworm` point to the same layer, stored and downloaded once. No image can alter it and corrupt the others.
    3. *Many containers from one image*: they all read the same read-only layers, each with only its own thin writable layer, so a container cannot damage the image or its neighbours.
    4. *Reproducibility*: layers are identified by a hash of their content (`sha256:...`), so the image you tested is exactly the image everyone runs ("works on my machine" solved).
    5. *Cheap distribution*: push/pull only transfers the layers the other side does not already have.
  - **Gotcha (the cost of immutability)**: a later layer cannot reach back and delete a file from an earlier one. It only records a small "whiteout" marker saying "this path is deleted". overlayfs then hides the file in the merged view (`ls` shows nothing), but the earlier layer still contains the bytes, so the image does not shrink and anyone pulling it downloads them.
    ```dockerfile
    # BAD: layer 2 keeps ~40 MB of apt lists forever, layer 3 only hides them
    RUN apt-get update && apt-get install -y mariadb-server
    RUN rm -rf /var/lib/apt/lists/*

    # GOOD: Docker snapshots the filesystem at the END of the instruction,
    # when the lists have already been deleted, so they are never in the layer
    RUN apt-get update && apt-get install -y mariadb-server \
        && rm -rf /var/lib/apt/lists/*
    ```
    Same rule for anything temporary (downloaded archives, build tools): download, use and delete inside a single `RUN`. Analogy: committing a big file to git and then committing its deletion leaves the repo as big as before. Check with `docker history <image>`; a `rm` in its own layer shows `0B`.
  - **`&&` vs `;` inside a `RUN`** (separate issue): with `cmd1 ; cmd2` only the exit status of the last command counts, so a failed `apt-get update` goes unnoticed if the install succeeds. With `&&` the first failure fails the build. Separate `RUN` lines also stop the build on failure; the reasons to prefer one `RUN` are the cleanup rule above and avoiding a stale cached `apt-get update` layer feeding a later `apt-get install`.
- **Container**: a running (or stopped) instance of an image. Like an object. **Container = image (read-only layers) + one writable layer + isolated process (namespaces/cgroups).** Many containers can come from one image and share its layers. Deleting the container discards the writable layer, hence volumes for persistent data.
- **Dockerfile**: text recipe to build an image. Instructions that change files (`FROM`, `RUN`, `COPY`/`ADD`) create a **layer**; metadata instructions (`CMD`, `ENTRYPOINT`, `ENV`, `EXPOSE`, `USER`, `LABEL`, `VOLUME`) only edit the image **config** and add no files (`0B` in `docker history`). They still take part in the build cache.
  - `FROM` base image · `RUN` execute at **build** time · `COPY`/`ADD` copy files in · `ENV` set env var · `ARG` build-time variable · `WORKDIR` · `EXPOSE` documentation of a port (does *not* publish it) · `USER` · `ENTRYPOINT` the fixed program to run · `CMD` default arguments/command (overridable) · `VOLUME`.
- **Build vs run time**: `RUN` happens once when building the image; `ENTRYPOINT/CMD` happens each time a container starts. This distinction explains 80% of Inception bugs (e.g. you can't create the WordPress DB at build time because the volume/DB isn't there yet).
- **Layer cache**: each instruction's layer is cached; changing a line invalidates it and all lines below. Put rarely-changing stuff (package install) first, frequently-changing stuff (your files) last.
- **Base image / tag**: `debian:bookworm` — name:tag. `latest` is a moving tag → forbidden by the subject (reproducibility).
- **Registry / Docker Hub**: server hosting images. The subject forbids pulling ready-made images (except the Alpine/Debian base) — you build everything.
- **Docker daemon (`dockerd`)** and **Docker CLI**: the CLI (`docker …`) talks to the daemon that does the work.
- **Docker Compose**: tool + `docker-compose.yml` describing a multi-container app (services, networks, volumes, secrets) so one command (`docker compose up`) builds and runs it all.
  - **service**: a definition in compose (name, build context, ports, volumes…). **container**: the running instance of a service.
- **Build context**: the directory sent to the daemon for `COPY` (compose `build:`). `.dockerignore` excludes files from it.
- **Port mapping / publishing** (`ports: "443:443"`): host port → container port. **EXPOSE** alone does not publish. Containers on the same network reach each other on container ports *without* publishing.
- **Network**
  - **bridge** (default for compose): private virtual network; containers resolve each other **by service name** via Docker's built-in DNS (`mariadb` resolves to its IP). This is what you need.
  - **host**: container shares the host's network stack (no isolation) → **forbidden**.
  - `--link` / `links:` legacy way to connect containers → **forbidden**.
- **Volume** (storage that outlives the container)
  - **Named volume**: managed by Docker, referenced by name. Exists in `/var/lib/docker/volumes/…` by default.
  - **Bind mount**: maps a specific host path directly into the container (`/host/path:/container/path`). Tied to host layout, bypasses Docker's management.
  - Why the subject cares: container filesystem is ephemeral (delete container → data gone). Volumes keep DB and site files.
- **Environment variable**: key/value passed to the process (`environment:` or `env_file:`). Visible via `docker inspect` and `/proc` → fine for non-secrets (domain name, usernames).
- **`.env` file**: file of `KEY=value`; compose reads it for `${VAR}` substitution in the yml, and `env_file:` injects it into containers.
- **Docker secrets**: sensitive values stored as files mounted at `/run/secrets/<name>` in containers that are granted them (compose `secrets:` top-level + per-service). Not in env, not in `docker inspect`, not in the image. Your entrypoint reads the file (`$(cat /run/secrets/db_password)`).
- **Env vars vs secrets** (README comparison): env = simple, leaky; secrets = file-based, scoped per service, safer.
- **Entrypoint script**: shell script run at container start to configure then `exec` the real daemon.
- **PID 1**: the first process in a container. If it exits, the container stops. It receives `docker stop`'s SIGTERM; if it's a shell script that doesn't forward signals or `exec`, shutdown is slow/ugly (10s then SIGKILL). It also should reap zombie children. → Use `exec daemon` as the last line.
- **Foreground vs daemon**: a container must run its main service in the **foreground**. Daemonizing (nginx default, `php-fpm` default) forks into background → PID 1 exits → container dies. That's why people write `tail -f`/`sleep infinity` hacks, which the subject **forbids**. Correct: `nginx -g "daemon off;"`, `php-fpm8.2 -F`, `mariadbd`/`mysqld_safe`.
- **Restart policy** (`restart: always` / `unless-stopped` / `on-failure`): the daemon restarts a crashed container. Required by the subject.
- **Healthcheck / depends_on**: ordering and readiness (`depends_on: condition: service_healthy`).
- **Dangling image / prune**: `docker system prune` cleans unused stuff.
- **Image name = service name**: with `build:` plus `image: nginx` you set the image tag to the service name (subject requirement).

### 1.4 Vocabulary of the stack itself
- **NGINX** (pronounced "engine-x"): a high-performance **web server**, a program that listens on a port, receives HTTP(S) requests from browsers, and sends back responses. NGINX is also commonly used as a **reverse proxy** and TLS terminator. Written by Igor Sysoev (first release 2004) to solve the "C10k problem" (handling 10,000+ simultaneous connections).
  - **Why it is fast**: event-driven and asynchronous. A few **worker processes** each handle thousands of connections in a non-blocking loop, instead of one thread/process per connection (the Apache prefork model). Low RAM, scales well, which also makes it a good fit for a small container.
  - **What it does**:
    1. **Serves static files** (HTML, CSS, JS, images) directly from disk, very efficiently.
    2. **Terminates TLS**: it holds the certificate/key, decrypts HTTPS from the browser, and talks plain traffic to backends on the private network. Only NGINX needs to expose port 443.
    3. **Reverse proxies / gateways to backends**: for dynamic requests it forwards to another program and relays the answer. For PHP it speaks **FastCGI** to php-fpm, because NGINX cannot execute PHP itself.
  - **Config model** (`/etc/nginx/nginx.conf` or a file in `conf.d/`): nested blocks of directives.
    - `server { }`: a virtual host (`listen 443 ssl; server_name login.42.fr;`).
    - `location { }`: rules matched against the URL path.
    - Master process reads the config and manages the workers.
  - **Minimal Inception shape**:
    ```nginx
    server {
        listen 443 ssl;
        server_name login.42.fr;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_certificate     /etc/nginx/ssl/cert.crt;
        ssl_certificate_key /etc/nginx/ssl/cert.key;
        root /var/www/html;                 # WordPress files (shared volume)
        index index.php;

        location / { try_files $uri $uri/ /index.php?$args; }   # static file, else WordPress
        location ~ \.php$ {                                     # PHP -> php-fpm
            include fastcgi_params;
            fastcgi_pass wordpress:9000;                        # service name via Docker DNS
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        }
    }
    ```
    NGINX needs to see the WordPress files (static assets, and `SCRIPT_FILENAME` must resolve) so it mounts the same WP volume as the wordpress container.
  - **Docker gotcha**: NGINX daemonizes by default, which makes PID 1 exit and the container die. Run it in the foreground: `nginx -g "daemon off;"`.
- **TLS / SSL certificate**: encryption for HTTPS. You create a **self-signed** certificate with `openssl` (browser will warn — fine). Restrict to `TLSv1.2 TLSv1.3` (`ssl_protocols`).
- **WordPress**: PHP CMS. **PHP-FPM** (FastCGI Process Manager): PHP application server that listens on a port (9000) and executes PHP scripts on request. NGINX can't run PHP itself; it speaks **FastCGI** to php-fpm (`fastcgi_pass wordpress:9000`).
- **MariaDB**: MySQL-compatible database server, port 3306.
- **WP-CLI (`wp`)**: command line tool to download WordPress, create `wp-config.php`, install, add users — lets you automate setup in your entrypoint script instead of clicking through the web installer.
- **Reverse proxy**: server that receives client requests and forwards to a backend.
- **DNS / `/etc/hosts`**: the domain `login.42.fr` doesn't exist publicly; you map it to your VM's IP (usually `127.0.0.1`) in `/etc/hosts`.
- **Alpine vs Debian**: Alpine = tiny (musl libc, apk). Debian = bigger, familiar (glibc, apt). Either is allowed.
- **Makefile**: the entry point that calls `docker compose`.

---

## 2. The subject explained

### 2.1 What you build
Three containers on one private Docker network, only NGINX reachable from outside:

```
 browser ──443/TLS──► [ nginx ] ──9000/FastCGI──► [ wordpress + php-fpm ] ──3306──► [ mariadb ]
                          │                              │                              │
                          └──── volume: WP files ────────┘                         volume: DB files
```
Both volumes physically live in `/home/<login>/data` on the host.

### 2.2 General rules (ch. III)
- Work in a **VM**.
- All config in a **`srcs/`** folder; **Makefile at repo root** that builds images through `docker-compose.yml`.

### 2.3 Mandatory rules (ch. V), decoded
| Rule | What it means for you |
|---|---|
| `docker compose` | Use Compose v2 (`docker compose`, not `docker-compose`). |
| Image name = service name | `nginx`, `wordpress`, `mariadb`. |
| One service per container | Don't put nginx and php in the same container. |
| Alpine or Debian, **penultimate stable** | Not the latest stable, the one before. Check debian.org/releases and alpinelinux.org/releases **today**. As of my knowledge Debian stable is 13 "trixie" so penultimate = 12 "bookworm"; verify, and be ready to justify. `bullseye` (seen in some repos) is too old. |
| Write your own Dockerfiles, one per service, built via compose from the Makefile | No `image: wordpress:latest`, no pulling nginx/mariadb images. Only `FROM debian:<tag>` / `alpine:<tag>`. |
| NGINX with TLSv1.2/1.3 only | `ssl_protocols TLSv1.2 TLSv1.3;` + self-signed cert. |
| WordPress + php-fpm only, no nginx | php-fpm listens on 9000 (not a unix socket). |
| MariaDB only, no nginx | |
| Volume #1: WP database, volume #2: WP site files | NGINX also mounts the WP files volume (it serves static assets and needs the PHP files' paths). |
| **Named volumes, no bind mounts**; data stored in `/home/login/data` | Contradictory-looking. The common solution: declare a *named* volume with `driver: local` and `driver_opts: {type: none, o: bind, device: /home/login/data/xxx}`. Docker sees a named volume; data lands in the right host folder. Create the folders first (Makefile). Be ready to explain this at the defense and re-read the PDF wording ("Docker named volumes… Bind mounts are not allowed"). |
| A docker network | Declare a `networks:` block and attach every service. |
| Restart on crash | `restart: always` (or `unless-stopped`). |
| No `network: host`, `--link`, `links:` | And the `networks:` key **must** be present. |
| **No infinite-loop hacks**: `tail -f`, `bash`, `sleep infinity`, `while true` as entrypoint/command | The real daemon must be PID 1 in the foreground. Read about PID 1. |
| Two DB users, one admin; admin username must not contain admin/administrator | e.g. admin user `boss42`, second user `editor`. Create them via WP-CLI. The DB itself also needs a non-root user for WordPress. |
| Domain `login.42.fr` → local IP | `/etc/hosts` entry. |
| No `latest` tag | Pin your base image version. |
| **No passwords in Dockerfiles** | Pass at runtime. |
| `.env` mandatory for env variables; Docker secrets strongly recommended for confidential data | `.env` in `srcs/` for non-secret config (DOMAIN_NAME, MYSQL_USER, MYSQL_DATABASE…). Passwords → `secrets/` files → compose `secrets:`. |
| **Credentials in Git = project failure** | `.gitignore` for `.env` and `secrets/` **before your first commit**. If a password enters Git history once, rewriting history is needed. |
| NGINX is the only entrypoint, port 443 only | Only nginx has `ports:`. wordpress/mariadb use `expose`/nothing. No port 80. |

### 2.4 Expected tree (page 10)
```
Makefile
secrets/ credentials.txt  db_password.txt  db_root_password.txt   (gitignored)
srcs/
  docker-compose.yml
  .env                                                            (gitignored)
  requirements/
    mariadb/   Dockerfile  .dockerignore  conf/  tools/
    nginx/     Dockerfile  .dockerignore  conf/  tools/
    wordpress/ Dockerfile  .dockerignore  conf/  tools/
    bonus/  tools/
README.md  USER_DOC.md  DEV_DOC.md
```
Note `secrets/` sits at the repo root, outside `srcs/`.

### 2.5 Documentation (ch. VI–VII)
- **README.md** (English): first line in italics: *This project has been created as part of the 42 curriculum by \<login\>.*; sections **Description**, **Instructions**, **Resources** (classic references **and how AI was used: for which tasks/parts**), plus a project-description section explaining Docker use and comparing **VM vs Docker, Secrets vs Env vars, Docker network vs host network, Volumes vs bind mounts**.
- **USER_DOC.md**: what the services are, start/stop, reach site and admin panel, where credentials are, how to check things run.
- **DEV_DOC.md**: set up from scratch, build/launch with Makefile+compose, useful container/volume commands, where data lives and how it persists.
- Write these as you go (10 minutes per milestone), not on Friday night.

### 2.6 Bonus (ch. VIII)
Only graded if mandatory is **perfect**. Options: Redis cache for WP, FTP server on the WP volume, static site (no PHP), Adminer, a service of your choice. Each its own Dockerfile/container. Skip unless done early; Friday is tight.

### 2.7 Evaluation
Expect to be asked to change something small live (e.g. change a port, add a user, change a config). So know where each setting lives.

---

## 3. How to proceed

### 3.1 Principles
1. **Get one container working standalone, then compose it, then connect the next.** Don't write all three at once.
2. Debug by running things by hand first: `docker run -it debian:bookworm bash` (for exploration only, not in the project), install the package, find the config file, learn what command starts it in foreground, *then* write that down as a Dockerfile.
3. Everything configurable goes through env vars/secrets so entrypoint scripts stay generic.
4. Rebuild loop: `docker compose up --build`, read logs (`docker compose logs -f <service>`).

### 3.2 VM setup (Tue morning)
- VM with Debian/Ubuntu (check what your school allows), 2 CPU, 2–4 GB RAM, ~20 GB disk, shared clipboard / SSH from your host to work comfortably in VS Code.
- Install Docker Engine + compose plugin (from Docker's official apt repo), add yourself to the `docker` group, `make`, `openssl`, `git`.
- Add `127.0.0.1 login.42.fr` to `/etc/hosts`.
- Create `/home/<login>/data/{mariadb,wordpress}`.
- `git init`, write `.gitignore` (`.env`, `secrets/`) and commit it **first**.

### 3.3 Order of work and hints per service

**A. Skeleton + Makefile.** Targets: `all` (create data dirs, `docker compose -f srcs/docker-compose.yml up -d --build`), `down`, `clean`, `fclean` (also remove volumes + data), `re`. Hint: use `-f` and `--env-file` if the `.env` lives in `srcs/`.

**B. MariaDB container** (the easiest to verify).
- Dockerfile: `FROM debian:<penultimate>`; `apt-get install mariadb-server`; copy config + entrypoint; `ENTRYPOINT`.
- Config: it must listen on all interfaces (`bind-address = 0.0.0.0`) so wordpress can reach it (default is localhost only).
- Entrypoint logic to think through yourself:
  1. Is the data dir already initialised (volume not empty)? If not, initialise (`mariadb-install-db`).
  2. Start the server temporarily, run SQL: create database, create user with password (read from the secret file), set the root password, flush privileges, shut down the temporary server.
  3. `exec` the server in the foreground as PID 1.
- Why step 1 matters: the volume persists, so the script must be **idempotent** (rerunning must not break).
- Test: `docker exec -it mariadb mariadb -u <user> -p` and list databases.

**C. NGINX container.**
- Dockerfile: install `nginx` and `openssl`; generate a self-signed cert (at build time is OK since it's not a secret you commit, or at start in the entrypoint); copy `nginx.conf`.
- Config pieces: `listen 443 ssl;`, `ssl_protocols TLSv1.2 TLSv1.3;`, `ssl_certificate(_key)`, `server_name login.42.fr;`, `root /var/www/html;`, `index index.php`, `location ~ \.php$ { include fastcgi params; fastcgi_pass wordpress:9000; … }`.
- Run: `CMD ["nginx", "-g", "daemon off;"]`. Test it first with a static index.html: `curl -k https://login.42.fr`, and `openssl s_client -connect login.42.fr:443 -tls1_1` should fail while `-tls1_2` works.

**D. WordPress + php-fpm container.**
- Dockerfile: install `php-fpm`, `php-mysql` (mysqli), `curl`, `mariadb-client` (to wait for DB), plus whatever WP needs (e.g. `php-curl php-gd php-mbstring php-xml php-zip`); download `wp-cli.phar`.
- php-fpm pool config: `listen = 0.0.0.0:9000` (default is a unix socket / localhost). Make sure the run dir (`/run/php`) exists.
- Entrypoint logic:
  1. Wait for MariaDB to accept connections (loop with a bounded retry, **not** an infinite hack; or healthcheck + `depends_on`).
  2. If `wp-config.php` doesn't exist: `wp core download`, `wp config create` (DB host `mariadb`, creds from secrets/env), `wp core install` (URL `https://login.42.fr`, admin user without "admin"), `wp user create` for the second user.
  3. `exec php-fpm<version> -F`.
- Permissions: files owned by `www-data`, which both php-fpm and nginx should be able to read.

**E. Compose file.** Think through each service: `build`, `image` (= service name), `container_name`, `env_file`, `secrets`, `volumes`, `networks`, `restart`, `depends_on`. Top-level: `networks`, `volumes` (named, with the `driver_opts` trick), `secrets` (`file: ../secrets/db_password.txt`). Only nginx gets `ports: ["443:443"]`.

**F. Validate against the subject** (checklist at the end of §5), then write the docs.

### 3.4 Pitfalls I see most often
- Container exits immediately → the main process daemonised or crashed. `docker compose logs`.
- WordPress can't connect → wrong host (should be the **service name**), MariaDB bound to 127.0.0.1, user created for `localhost` only (use `'%'`), or DB not ready yet.
- 502 Bad Gateway → nginx can't reach `wordpress:9000` (php-fpm listening on a socket or localhost).
- "File not found" on PHP → nginx and php-fpm see WP files at different paths; mount the same volume at the same path.
- Volume has old data after you change passwords → the init script doesn't rerun; `make fclean` wipes `/home/login/data` (needs sudo since files are root-owned).
- Secrets copied into image via `COPY` or `ARG` → leaks. Read them at runtime only.
- Windows line endings in shell scripts (`\r`) → "bad interpreter".
- Forgetting `exec` in the entrypoint → daemon isn't PID 1 → slow `docker stop`.

### 3.5 How we'll work together
You write the Dockerfile/entrypoint; I explain concepts, answer "why", and review what you wrote (I'll point at bugs rather than hand you the fix unless you're stuck). Questions you should be able to answer before moving to the next step are given in §5.

---

## 4. Schedule (today is Tue 10 Nov → Fri 13 Nov)

| When | Milestone | Done when |
|---|---|---|
| **Tue** | Read this guide + subject. VM ready, Docker installed, repo skeleton + `.gitignore`. Do the official Docker "get started" tutorial parts on images/containers/volumes/networks. Hello-world Dockerfile. MariaDB container working standalone. | `docker exec` into MariaDB, see your DB and user. |
| **Wed** | NGINX (TLS) + WordPress/php-fpm containers. Compose file with network + volumes. | `https://login.42.fr` shows the WP installation done by script, two users exist. |
| **Thu** | Secrets/`.env` clean-up, restart policy, persistence test (`down`, `up`, data still there), Makefile polish, README + USER_DOC + DEV_DOC. Check every rule in the subject. | Fresh clone + `make` works from zero. |
| **Fri** | Buffer, peer review (find a classmate, explain it out loud), defense prep. Bonus only if everything is perfect. | You can explain every file. |

---

## 5. Defense cheat-sheet

**Questions to be able to answer**
- Container vs VM? Image vs container? What does `docker compose up` do?
- Why is nginx the only entry point? How does nginx talk to WordPress? to MariaDB?
- What is PID 1 and why `exec`/foreground? Why is `tail -f` bad?
- Named volume vs bind mount, and how your volumes end up in `/home/login/data`.
- Env vars vs secrets: where are yours and who can read them?
- How does DNS between containers work? Why does `mariadb` resolve?
- What happens on `docker stop`, on a crash, on VM reboot (restart policy)?
- How would you change the TLS version / add a user / change the port?

**Final checklist**
- [ ] VM; `srcs/` with config; Makefile at root builds via compose
- [ ] 3 images named nginx / wordpress / mariadb, built from penultimate Alpine/Debian, no `latest`
- [ ] No pulled images, no `network: host` / `links`; `networks:` present
- [ ] No `tail -f`, `sleep infinity`, `while true`, `bash` as the main process
- [ ] nginx: 443 only, TLS 1.2/1.3 only
- [ ] WP + php-fpm without nginx; MariaDB without nginx
- [ ] Two named volumes → `/home/login/data/...`
- [ ] Two WP users, admin name doesn't contain admin/administrator
- [ ] `login.42.fr` works
- [ ] `.env` used; secrets as Docker secrets; no password in Dockerfiles or Git (check `git log -p`)
- [ ] `restart` policy set; survives `docker kill` and VM reboot
- [ ] README (italic first line, Description/Instructions/Resources incl. AI usage, 4 comparisons), USER_DOC.md, DEV_DOC.md
