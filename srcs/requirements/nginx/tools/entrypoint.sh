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
