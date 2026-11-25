# Inception: what is left for you (manual steps)

The project files are written (Makefile, `srcs/`, README, USER_DOC, DEV_DOC) and were tested in Docker on the Fedora machine (2026-11-17, login `ktest`: build, HTTPS, admin login, TLS, two users, crash restart). What remains needs a human: the VM, your login, a browser, and the defense. Do the steps in order; each one has a check so you know it worked. Section numbers (§) refer to [cooking_recipe.md](cooking_recipe.md).

---

## 1. On this machine: save the work

- [x] Read the diff before committing: `git status`, `git diff`, and skim every new file. Each line has a comment; anything you cannot explain is a defense risk.
- [x] Check that no secret is about to be committed: `git status --short` must not list `secrets/` nor `srcs/.env` (they are in `.gitignore`).
- [x] Commit and push to GitHub: `git add -A && git commit -m "Implement Inception" && git push`.
  - Check: on github.com/Komorebi-32/Inception you see `srcs/.env.example` but **no** `secrets/` folder and **no** `srcs/.env`.

## 2. Create the VM (VirtualBox, at school)

- [x] Download the Debian 12 "bookworm" netinst ISO (amd64): the "bookworm" page on https://www.debian.org/releases/ links to the installer. Bookworm is the right choice **today** because Debian 13 "trixie" is the current stable. Re-check https://www.debian.org/releases/ the day you build.
- [x] Store the VM where the quota allows it: `/sgoinfre/goinfre/Perso/bkaras-g` (30 GB limit; check with `du -sh /sgoinfre/goinfre/Perso/bkaras-g`).
- [x] New VM: type Linux / Debian 64-bit, 2 CPUs (more if available), 4096 MB RAM, dynamically allocated disk of 20 GB, network "NAT".
- [x] VirtualBox → VM settings → Network → Advanced → Port Forwarding: add a rule `ssh`, host port `4242`, guest port `22` (for SSH from the host, like Born2beRoot).
  - Check: the VM boots on the ISO.

## 3. Install Debian in the VM

- [x] Language English, your keyboard layout, hostname `bkaras-g` (anything works, your login is simplest).
- [x] Set a root password, then create the normal user: **user name = your 42 login, exactly** (lowercase). The Makefile takes the login from `whoami`, so this decides the domain `bkaras-g.42.fr` and the data path `/home/bkaras-g/data`.
- [x] Partitioning: "Guided - use entire disk", all files in one partition.
- [x] Software selection: tick **Xfce** (a desktop with a browser is needed: the evaluator opens the site in the VM's browser, and `bkaras-g.42.fr` only exists in the VM's `/etc/hosts`), **SSH server** and **standard system utilities**. Untick GNOME and "web server".
- [x] Install GRUB on the disk, reboot, remove the ISO.
  - Check: you can log into the Xfce desktop as `bkaras-g`.

## 4. First configuration of the VM

In a terminal of the VM:
- [x] `su -` (root password), then `apt update && apt install -y sudo vim make git curl openssl ca-certificates`.
- [x] `usermod -aG sudo bkaras-g`, then `exit` twice and log in again.
  - Check: `sudo whoami` prints `root`.
- [x] `sudo apt install -y firefox-esr` if Firefox is not already there.
- [x] Optional but recommended: from the host, `ssh -p 4242 bkaras-g@localhost` works (copy-paste is easier); VS Code "Remote - SSH" on the same address lets you edit files in the VM.
- [x] Optional: in `/etc/ssh/sshd_config`, `PermitRootLogin no`, then `sudo systemctl restart ssh` (same as Born2beRoot).

## 5. Install Docker in the VM

- [x] Run the commands of §4.2 (Docker's Debian repository, **`linux/debian`**, not `linux/ubuntu`).
- [x] `sudo usermod -aG docker bkaras-g`, then log out of the desktop and log in again (or `newgrp docker` in the current terminal).
  - Check: `docker run --rm debian:bookworm echo ok` prints `ok` **without** sudo, and `docker compose version` prints v2 or later.
- [x] Take a VirtualBox snapshot now ("Docker installed"): you can come back to it if anything breaks later.

## 6. Get the project into the VM

- [x] `git clone https://github.com/Komorebi-32/Inception.git ~/inception && cd ~/inception`. If the repo is private, use a GitHub personal access token as the password, or add an SSH key to GitHub.
- [x] Check the login the Makefile will use: `whoami` must print your 42 login. If it does not, either fix the user or always run `make LOGIN=bkaras-g`.
- [x] Put your login in the docs (the README's first line must contain it):
  ```sh
  sed -i 's/bkaras-g/YOUR_LOGIN/g' README.md USER_DOC.md DEV_DOC.md
  head -1 README.md   # *This project has been created as part of the 42 curriculum by YOUR_LOGIN.*
  ```
  Do **not** run this sed on `srcs/.env.example` or the Makefile: there `bkaras-g` is a placeholder that `make` fills in.

## 7. First run

- [x] `make`. It asks your sudo password once (to add `127.0.0.1 bkaras-g.42.fr` to `/etc/hosts`). The first build takes a few minutes (packages + WordPress download).
- [x] `make ps`: three containers `Up`, `mariadb` and `wordpress` `(healthy)`.
- [x] `make logs`: lines prefixed `[mariadb]`, `[wordpress]`, `[nginx]`, no `error:` line. Ctrl-C to quit.
  - If something fails, the line `[service] error: ...` says what is missing; §10 of the recipe lists the known pitfalls.
- [x] `ls secrets/`: three files; `cat secrets/credentials.txt`: line 1 = admin password, line 2 = author password.
- [x] `grep -E 'WP_ADMIN_USER|WP_USER=' srcs/.env`: the admin is `bkaras-g_boss`, the author `writer`. Change them in `srcs/.env` **before** the first `make` if you prefer other names (never containing "admin"); after the first run a change needs `make fclean && make`.

## 8. Browser checks (Firefox in the VM)

- [x] `https://bkaras-g.42.fr`: warning about the certificate → *Advanced* → *Accept the risk and continue*. The site "Inception" shows (not the WordPress installer).
- [x] HTTP must be refused. Check it in a terminal, not in Firefox (Firefox's "HTTPS-First" and the address bar history silently switch to `https://`, so the page opens even though the server refuses HTTP): `curl -v http://bkaras-g.42.fr` must end with `Failed to connect ... port 80 ... Connection refused`. To show it in Firefox anyway: Settings → Privacy & Security → disable HTTPS-Only / HTTPS-First, then type the full `http://` URL.
- [ ] Padlock → certificate details: issued to `bkaras-g.42.fr`, connection TLS 1.2 or 1.3.
- [ ] Log in at `https://bkaras-g.42.fr/wp-admin` as `writer` (password line 2), open the "Hello world!" post, leave a comment. Log out.
- [ ] Log in as `bkaras-g_boss` (password line 1). *Pages* → *Sample Page* → edit the text → *Update*. Open the page on the site: the change is there.

## 9. Evaluator rehearsal (terminal)

- [ ] Run every command of §9.2 in order and compare with the expected result written next to it.
- [ ] Database: `docker exec -it mariadb mariadb -uroot -p` (password: `secrets/db_root_password.txt`), then `SHOW DATABASES;`, `USE wordpress;`, `SHOW TABLES;`, `SELECT user_login FROM wp_users;` → two users. `exit`.
- [ ] Crash test: `docker exec wordpress kill 1`, wait 10 s, `make ps`: WordPress is up again. (Not `docker kill`: Docker treats that as a manual stop and does not restart.)
- [ ] Port change drill (§9.3), with a timer, once per service:
  - NGINX: `NGINX_PORT=8443` in `srcs/.env` → `make` → `https://bkaras-g.42.fr:8443` works in Firefox, `:443` no longer does.
  - php-fpm: `WP_PORT=9001` → `make` → site still works; `docker exec nginx grep fastcgi_pass /etc/nginx/nginx.conf` shows 9001.
  - MariaDB: `DB_PORT=3307` → `make` → site still works; `docker exec wordpress grep DB_HOST /var/www/html/wp-config.php` shows 3307.
  - Put the three values back (443, 9000, 3306) → `make`.
- [ ] Persistence: `sudo reboot`. After login: `cd ~/inception && make ps` (the containers came back by themselves; run `make` if not). The comment and the page edit are still there.
- [ ] Clean slate, as the evaluator does before starting: `make fclean`, then the wipe command of §1, then `make`. Everything rebuilds and the site is a fresh install (new passwords are **not** generated: `secrets/` is kept on purpose).
- [ ] Fresh clone, as a new user of the repo would. Both copies share the compose project name and `/home/bkaras-g/data`, so first `make fclean` in `~/inception`. Then `cd /tmp && git clone https://github.com/Komorebi-32/Inception.git t && cd t && make`: it must work without any manual file (secrets and `.env` are generated). Then `make fclean` in `/tmp/t`, delete `/tmp/t`, and `cd ~/inception && make` again.

## 10. Documentation, in your own words

- [ ] README "AI usage": rewrite it so it says exactly what *you* did with AI and what you checked yourself. The evaluator may ask about it.
- [ ] README comparisons (VM vs Docker, Secrets vs env vars, Docker network vs host network, Volumes vs bind mounts): read them aloud; rephrase anything you would not say that way.
- [ ] USER_DOC / DEV_DOC: follow them once, word for word, on the VM. Fix any command that does not match what you see.
- [ ] Commit and push from the VM (or copy the changes back): `git add -A && git commit -m "Docs: login and AI usage" && git push`.

## 11. Submit to the 42 repository

- [ ] The evaluated repository is the one from the intra (Vogsphere), not GitHub. Add it: `git remote add vogsphere <url from the intra project page>` then `git push vogsphere main` (or the branch the intra expects).
- [ ] Clone the Vogsphere repo into an empty folder and check: `Makefile` and `srcs/` at the root, `README.md`, `USER_DOC.md`, `DEV_DOC.md` present, `git ls-files | grep -E 'secrets/|\.env$'` prints nothing.
- [ ] Decide what to leave out of the submission (`cooking_recipe.md`, `todo_human.md`, `INCEPTION_GUIDE.md`, `notion_Ben.md`, the subject PDF). Extra files are not forbidden, but the evaluator may read them: submit nothing you cannot defend.

## 12. Defense preparation

- [ ] For each file, explain every line without the comments (cover them): Dockerfiles, the three entrypoints, `www.conf`, the NGINX template, `99-inception.cnf`, `docker-compose.yml`, Makefile.
- [ ] Learn the talking points of §12 (Docker vs VM, compose, network, volumes, secrets, PID 1 and `exec`, `--bootstrap`, build time vs run time).
- [ ] Dry run with a peer acting as evaluator, using the grid (§1); write down every question you could not answer and add the answer to your notes.
- [ ] Ask peers who passed recently what their evaluator asked live (which service and port they had to change, DB login, reboot).
- [ ] The day before: VirtualBox snapshot "ready for defense"; check the base image is still the penultimate Debian; `make` once to be sure the build still works (packages and WordPress are downloaded at build/first start).

## 13. Optional: bonus

Only once everything above is flawless. §11 of the recipe lists the bonus services and which reference repos implement them well. Each needs its own Dockerfile, a service in compose, and the same rules (pinned base image, no infinite loop, daemon as PID 1).
