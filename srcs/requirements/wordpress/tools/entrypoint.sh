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
