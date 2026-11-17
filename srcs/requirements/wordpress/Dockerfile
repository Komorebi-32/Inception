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
