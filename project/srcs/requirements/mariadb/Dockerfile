FROM alpine:3.21

RUN apk update && apk add --no-cache \
    mariadb \
    mariadb-client \
    bash \
    && rm -rf /var/cache/apk/*

RUN mkdir -p /var/run/mysqld /var/lib/mysql && \
    chown -R mysql:mysql /var/run/mysqld /var/lib/mysql

RUN mkdir -p /etc/my.cnf.d && \
    printf "[mysqld]\n\
# Network Configuration\n\
skip-host-cache\n\
skip-name-resolve\n\
bind-address=0.0.0.0\n\
port=3306\n\
\n\
# Character Set\n\
character-set-server=utf8mb4\n\
collation-server=utf8mb4_unicode_ci\n\
\n\
# Performance Optimization\n\
max_connections=100\n\
max_allowed_packet=64M\n\
table_open_cache=2000\n\
query_cache_size=32M\n\
query_cache_type=1\n\
\n\
# InnoDB Settings\n\
innodb_buffer_pool_size=256M\n\
innodb_log_file_size=64M\n\
innodb_flush_log_at_trx_commit=2\n\
innodb_flush_method=O_DIRECT\n\
\n\
# Logging\n\
log_error=/var/log/mysql/error.log\n\
slow_query_log=1\n\
slow_query_log_file=/var/log/mysql/slow.log\n\
long_query_time=2\n" > /etc/my.cnf.d/docker.cnf

RUN mkdir -p /var/log/mysql && \
    chown -R mysql:mysql /var/log/mysql

RUN sed -i '/skip-networking/d' /etc/my.cnf.d/mariadb-server.cnf

COPY conf/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3306

ENTRYPOINT ["/entrypoint.sh"]
