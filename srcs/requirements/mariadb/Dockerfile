# Alpine for lighter Base OS (penultimate stable verison)
FROM alpine:3.20

# Install mariadb and dependencies
RUN apk update && apk add --no-cache \
    mariadb \
    mariadb-client \
    mariadb-common && \
    mkdir -p /run/mysqld && \
    chown -R mysql:mysql /run/mysqld && \
    mkdir -p /var/liv/mysql

# Copy custom MariaDb configuration
COPY conf/mariadb.conf /etc/my.cnf.d/mariadb-server.cnf

# Copy initialization script
COPY tools/init-db.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Set proper permissions
RUN chown -R mysql:mysql /var/lib/mysql

# Expose MariaDB Port
EXPOSE 3306

# Use proper initialization script as entrypoint
ENTRYPOINT [ "/docker-entrypoint.sh" ]

# Start MariaDB safely (no tail -f)
CMD ["mysqld", "--user=mysql"]
