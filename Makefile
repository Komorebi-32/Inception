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
#   grep -qE    quiet (-q: only the exit status matters, found / not found),
#               extended regex (-E)
#   (^|[[:space:]])DOMAIN([[:space:]]|$$)
#               the domain must be a WHOLE entry, bordered by whitespace or the
#               line ends. `grep -w` is not enough: it counts a dot as a word
#               border, so the installer's line "127.0.1.1 jdoe.jdoe.42.fr jdoe"
#               would match "jdoe.42.fr" and the entry would never be added.
#               ($$ is a literal $ in a Makefile.)
#   sudo tee -a append as root (a plain `>>` would run without sudo rights)
hosts:
	@grep -qE '(^|[[:space:]])$(DOMAIN)([[:space:]]|$$)' /etc/hosts || echo "127.0.0.1 $(DOMAIN)" | sudo tee -a /etc/hosts > /dev/null

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
