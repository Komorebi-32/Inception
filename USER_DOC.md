# User documentation

How to run and use the Inception stack. Commands are run from the repository root, on the VM, as the user `bkaras-g`.

## Services provided

| Service | What it is | Reachable at |
|---|---|---|
| NGINX | The web server, HTTPS only (TLS 1.2 / 1.3) | `https://bkaras-g.42.fr` (port 443) |
| WordPress | The website and its administration panel | through NGINX: `https://bkaras-g.42.fr`, `https://bkaras-g.42.fr/wp-admin` |
| MariaDB | The database used by WordPress | only from inside the Docker network (not published) |

Plain HTTP (`http://bkaras-g.42.fr`, port 80) is not served at all: the connection is refused.

## Start and stop

| Command | Effect |
|---|---|
| `make` | First time: generates passwords and settings, builds and starts everything. Afterwards: starts the stack, rebuilding only what changed. |
| `make stop` | Stops the containers (nothing is removed). |
| `make start` | Starts the stopped containers again. |
| `make down` | Removes the containers and the network. Website and database are kept. |
| `make fclean` | **Deletes everything**, including the website content and the database. Asks for the sudo password. |

The containers restart by themselves after a crash and when the VM boots.

## Access the website and the administration panel

1. Open `https://bkaras-g.42.fr` in the VM's browser.
2. The browser warns that the certificate is not trusted: it is self-signed (made by the project, not by a certificate authority). Click *Advanced* → *Accept the risk and continue*.
3. Administration panel: `https://bkaras-g.42.fr/wp-admin`, log in with the administrator account.

Two WordPress accounts exist:

| Account | User name | Role |
|---|---|---|
| Administrator | value of `WP_ADMIN_USER` in `srcs/.env` | manages the site (pages, users, settings) |
| Author | value of `WP_USER` in `srcs/.env` | writes posts and comments |

## Credentials

| What | Where |
|---|---|
| WordPress administrator password | `secrets/credentials.txt`, line 1 |
| WordPress author password | `secrets/credentials.txt`, line 2 |
| MariaDB password of the WordPress database user | `secrets/db_password.txt` |
| MariaDB root password | `secrets/db_root_password.txt` |
| User names, e-mails, database name | `srcs/.env` |

The files in `secrets/` are created by `make` on this machine, readable only by you, and never committed to git. Show one with `cat secrets/credentials.txt`.

**Changing a password.** Passwords are applied only when the site is installed for the first time. Either change it in the WordPress panel (*Users* → *Profile*), or edit the file in `secrets/` and reinstall from scratch with `make fclean && make` (this deletes the site content).

## Check that the services run

```sh
make ps                                  # the three containers are "Up"; mariadb and wordpress "(healthy)"
make logs                                # live logs of the three services (Ctrl-C to quit)
curl -k -I https://bkaras-g.42.fr         # "HTTP/1.1 200 OK" (-k accepts the self-signed certificate)
curl -I http://bkaras-g.42.fr             # must fail: "Connection refused"
docker exec -it mariadb mariadb -uroot -p   # database console; password: secrets/db_root_password.txt
```

In the database console, `SHOW DATABASES;` lists `wordpress`, and `SELECT user_login FROM wordpress.wp_users;` lists the two accounts. Type `exit` to leave.

If the site does not answer: run `make ps` to see which container is not up, then `docker logs <name>` (`nginx`, `wordpress` or `mariadb`). Each service prints its own steps with a `[service]` prefix and stops with an explicit `error:` line when something is missing.
