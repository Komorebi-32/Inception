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
#
# How the line below is read:
#   1. `${DB_NAME:-}`  value of DB_NAME, or "" if it is unset or empty, thanks
#                      to the `:-`. Without it, `set -u` would abort here with
#                      a generic message.
#   2. `[ -n "..." ]`  a command that prints nothing and exits with 0 (success)
#                      if the string is non-empty, 1 (failure) if it is empty.
#   3. `A || B`        run A; run B ONLY IF A failed. So `fail` runs only when
#                      DB_NAME is empty, and prints our own message. `set -e`
#                      does not exit on the failing `[`, because `||` handles it.
# The variables themselves are not set in this script: compose injects every
# KEY=value of srcs/.env (`env_file: .env`) into the container's environment
# before this script starts.
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
# The server runs as the unprivileged `mysql` user, so it must be able to
# write to two places:
#   /run/mysqld  socket and PID file. Not in the volume: we create it here, as
#                root, so it must be handed to `mysql`.
#   $DATADIR     the volume, mounted at start, owned by whoever owns the host
#                folder (not `mysql`). That is why it is fixed here at runtime
#                and not in the Dockerfile: the mount hides what the image had.
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld "$DATADIR"
# After a crash (or `docker kill`), the old PID/socket files can stay behind
# inside the container. MariaDB would think another server is still running
# and refuse to start, so delete them. `-f`: no error if they do not exist.
rm -f /run/mysqld/mysqld.pid /run/mysqld/mysqld.sock

# --- 3. First boot only: create the database, the user and the passwords ----
if [ ! -f "$MARKER" ]; then
    echo "[mariadb] first start: initialising the database"

    # Create MariaDB's own system tables in an empty data directory. They are
    # the server's bookkeeping, stored in a special database named `mysql` (name
    # kept from MySQL, MariaDB's origin): accounts and password hashes
    # (`global_priv`, seen through the `user` view), privileges per database /
    # table / column (`db`, `tables_priv`, `columns_priv`), stored procedures,
    # time zones... Without them the server cannot tell who may connect.
    # CREATE USER and GRANT below ultimately just add rows to these tables.
    # Skipped if they already exist (e.g. a previous attempt crashed after this
    # step).
    #   --user=mysql     files are created owned by the mysql user
    #   --skip-test-db   do not create the demo `test` database
    #   > /dev/null      hide the long, normal output
    if [ ! -d "$DATADIR/mysql" ]; then
        mariadb-install-db --user=mysql --datadir="$DATADIR" --skip-test-db > /dev/null
    fi

    # "Bootstrap", for a database: the server sets up its own initial state
    # using nothing but itself (from the idea of pulling yourself up by your own
    # bootstraps). The usual way, starting a server, waiting for it, connecting
    # a client, then stopping it, would leave an unsecured server listening on
    # the network and need a background process. A container lives exactly as
    # long as its PID 1, and the real server must be that PID 1 (see the `exec`
    # at the end), so no helper server may be left running in the background.
    #
    # --bootstrap: start the server WITHOUT networking, read SQL statements from
    # standard input, execute them, then exit. This runs in the FOREGROUND
    # (no `&`, no background server to wait for and kill), so nothing is left
    # running when we reach the final `exec`. The SQL comes from the heredoc
    # below: everything between `<<EOF` and the closing `EOF` is sent to stdin,
    # after the shell has replaced ${...} with the values of the variables.
    #   FLUSH PRIVILEGES          in bootstrap mode the privilege tables are not
    #                             loaded yet; this loads them so that ALTER USER
    #                             and GRANT work. There is no second FLUSH at the
    #                             end: ALTER USER, CREATE USER and GRANT already
    #                             update the privileges in memory themselves, and
    #                             the server exits right after. (A FLUSH is only
    #                             needed after editing the `mysql.*` tables by
    #                             hand.)
    #   ALTER USER root           give root a password (on Debian, root can
    #                             otherwise log in from inside the container
    #                             with no password at all).
    #   `backticks`               quote a database name in SQL; escaped as \`
    #                             because a bare ` means "run a command" in sh.
    #   CHARACTER SET utf8mb4     which characters can be stored and how they are
    #                             encoded: real UTF-8 (up to 4 bytes), so all of
    #                             Unicode including emoji. MariaDB's older `utf8`
    #                             is a 3-byte subset. WordPress expects utf8mb4.
    #   COLLATE utf8mb4_unicode_ci  the rules to COMPARE and SORT strings: Unicode
    #                             ordering (`unicode`), case-insensitive (`ci`),
    #                             so 'Anna' = 'anna'. A collation belongs to one
    #                             character set, hence the same name prefix.
    #   'user'@'host'             a MariaDB account is a PAIR: who you are and
    #                             where you connect from. The same name from two
    #                             hosts is two different accounts. Here:
    #                             'root'@'localhost'  root, only from inside this
    #                                                 container.
    #                             '${DB_USER}'@'%'    the WordPress user from ANY
    #                                                 host ('%' is the wildcard),
    #                                                 needed because WordPress is
    #                                                 another container with its
    #                                                 own IP address.
    #   GRANT ... ON db.*         that user gets every right on the WordPress
    #                             database only, not on the whole server.
    mariadbd --user=mysql --datadir="$DATADIR" --bootstrap <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASS}';
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
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
