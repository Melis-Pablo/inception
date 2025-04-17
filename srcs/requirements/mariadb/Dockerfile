# Penultimate stable version of Debian (Bullseye)
FROM debian:bullseye

# Update packages and install MariaDB server
RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy configuration file
COPY ./conf/my.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Copy initialization script
COPY ./tools/init-db.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-db.sh

# Create directory for run socket
RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld

# Expose MariaDB port
EXPOSE 3306

# Set entrypoint to our initialization script
ENTRYPOINT ["init-db.sh"]

# MariaDB as the main process (PID 1)
CMD ["mysqld", "--user=mysql"]