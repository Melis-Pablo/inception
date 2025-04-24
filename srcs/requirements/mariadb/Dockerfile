# Penultimate stable version of Debian (Bullseye)
FROM debian:bullseye

# Update packages and install MariaDB server
RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/run/mysqld /var/log/mysql \
    && chown -R mysql:mysql /var/run/mysqld /var/log/mysql \
    && chmod 750 /var/run/mysqld

# Copy configuration file and initialization script
COPY ./conf/my.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY ./tools/init-db.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-db.sh

# Expose MariaDB port
EXPOSE 3306

# Set entrypoint to our initialization script
ENTRYPOINT ["/usr/local/bin/init-db.sh"]

# MariaDB as the main process (PID 1)
CMD ["mysqld", "--user=mysql"]