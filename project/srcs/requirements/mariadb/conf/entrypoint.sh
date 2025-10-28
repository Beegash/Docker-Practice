#!/bin/bash
set -e

if [ -f /run/secrets/db_password.txt ]; then
    echo "[MariaDB] Loading secrets from files..."
    DB_PASS=$(cat /run/secrets/db_password.txt)
    DB_ROOT=$(cat /run/secrets/db_root_password.txt)
fi

: "${DB_NAME:?ERROR: DB_NAME environment variable is not set}"
: "${DB_USER:?ERROR: DB_USER environment variable is not set}"
: "${DB_PASS:?ERROR: DB_PASS is not set}"
: "${DB_ROOT:?ERROR: DB_ROOT is not set}"

echo "[MariaDB] Starting initialization..."

mkdir -p /var/lib/mysql /var/run/mysqld /var/log/mysql
chown -R mysql:mysql /var/lib/mysql /var/run/mysqld /var/log/mysql
chmod 750 /var/lib/mysql

if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "[MariaDB] Fresh installation detected. Initializing database..."
  
  mysql_install_db --basedir=/usr --datadir=/var/lib/mysql --user=mysql --rpm > /dev/null
  
  if [ $? -ne 0 ]; then
    echo "[MariaDB] ERROR: mysql_install_db failed!"
    exit 1
  fi
  
  tfile="$(mktemp)"
  if [ ! -f "$tfile" ]; then
    echo "[MariaDB] ERROR: Failed to create temporary file!"
    exit 1
  fi
  
  cat > "$tfile" <<-EOSQL
		USE mysql;
		FLUSH PRIVILEGES;
		
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT}';
		GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
		
		DELETE FROM mysql.user WHERE User='';
		DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
		DROP DATABASE IF EXISTS test;
		DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
		
		CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
		CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
		GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
		
		FLUSH PRIVILEGES;
	EOSQL
  
  echo "[MariaDB] Bootstrapping database with initial configuration..."
  /usr/bin/mysqld --user=mysql --bootstrap --verbose=0 < "$tfile"
  
  if [ $? -ne 0 ]; then
    echo "[MariaDB] ERROR: Bootstrap failed!"
    rm -f "$tfile"
    exit 1
  fi
  
  rm -f "$tfile"
  echo "[MariaDB] Database initialized successfully!"
else
  echo "[MariaDB] Existing database found. Skipping initialization."
fi

echo "[MariaDB] Starting MariaDB server..."
exec /usr/bin/mysqld --user=mysql --console
