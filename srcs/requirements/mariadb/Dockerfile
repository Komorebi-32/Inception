# Base image: Debian 12 "bookworm", the penultimate stable Debian release
# (Debian 13 "trixie" is the current one). Always pin a codename, never `latest`.
FROM debian:bookworm

# One RUN = one image layer. `&&` chains the commands and stops at the first
# failure, so a broken install fails the build instead of producing a bad image.
# Using ; between the commands could have produced a bad image, since failure of 
# a command is ignored in this case as long as the next one succeeds.
#   apt-get update                 download the list of available packages
#   install -y                     answer "yes" to every prompt (no human to type it)
#   --no-install-recommends        skip optional extras -> smaller image
#   mariadb-server                 the database server (binary: mariadbd)
#   mariadb-client                 the `mariadb` and `mariadb-admin` command-line tools
#   rm -rf /var/lib/apt/lists/*    delete the package lists downloaded by `update`
#                                  (useless at runtime, saves ~20 MB in this layer)
#                                  MUST be in this same RUN: a layer is frozen once
#                                  built, so a `rm` in a later RUN could not delete
#                                  the files from this layer, it would only hide
#                                  them (a "whiteout" marker) and the image would
#                                  keep the full size. Docker snapshots the layer at
#                                  the END of the RUN, after the lists are gone.
#   rm -rf /var/lib/mysql/*        the Debian package ships an already-initialised
#                                  database here. We empty it so that our entrypoint
#                                  always initialises the database itself, with OUR
#                                  passwords, the first time the container starts.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        mariadb-server \
        mariadb-client \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/mysql/*

# Our server settings. MariaDB reads every *.cnf in this folder in alphabetical
# order and the LAST value wins. Debian's own 50-server.cnf says
# `bind-address = 127.0.0.1`, so our file must sort after it: hence "99-".
COPY conf/99-inception.cnf /etc/mysql/mariadb.conf.d/99-inception.cnf

# The startup script. /usr/local/bin is the conventional place for
# locally-added executables and is already in $PATH.
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

# COPY keeps the file mode of the source; make sure the script is executable
# even if the execute bit was lost (git on some systems, a zip download...).
RUN chmod +x /usr/local/bin/entrypoint.sh

# Documentation only: tells readers (and `docker inspect`) which port the
# service uses. It does NOT publish the port to the host; compose does not
# publish it either, so MariaDB is reachable only from the Docker network.
EXPOSE 3306

# The program Docker runs when the container starts. JSON ("exec") form: Docker
# runs the script directly, with no `sh -c` wrapper, so the script is PID 1
# until it `exec`s the real server.
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
