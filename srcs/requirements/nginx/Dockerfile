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
