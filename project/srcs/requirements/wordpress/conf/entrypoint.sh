#!/bin/bash
set -e

if [ -f /run/secrets/db_password.txt ]; then
    echo "[WordPress] Loading secrets from files..."
    WP_DB_PASSWORD=$(cat /run/secrets/db_password.txt)
    WP_ADMIN_PASS=$(cat /run/secrets/wp_admin_password.txt)
fi

cd /var/www/html

echo "Waiting for MariaDB to be ready..."
DB_HOST_NAME=$(echo ${WP_DB_HOST} | cut -d':' -f1)
DB_PORT=$(echo ${WP_DB_HOST} | cut -d':' -f2)

MAX_RETRIES=30
RETRY_COUNT=0

until mysql -h"${DB_HOST_NAME}" -P"${DB_PORT}" -u"${WP_DB_USER}" -p"${WP_DB_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; do
    RETRY_COUNT=$((RETRY_COUNT+1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo "ERROR: Could not connect to MariaDB after $MAX_RETRIES attempts!"
        exit 1
    fi
    echo "MariaDB is unavailable (attempt $RETRY_COUNT/$MAX_RETRIES) - sleeping"
    sleep 3
done
echo "MariaDB is up and running!"

if [ ! -f wp-config.php ]; then
    echo "WordPress not found. Installing..."
    
    rm -rf /var/www/html/*
    
    wp core download --allow-root
    
    wp config create \
        --dbname="${WP_DB_NAME}" \
        --dbuser="${WP_DB_USER}" \
        --dbpass="${WP_DB_PASSWORD}" \
        --dbhost="${WP_DB_HOST}" \
        --allow-root
    
    wp core install \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASS}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --allow-root
    
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASS}" \
        --role=author \
        --allow-root
    
    echo "WordPress installation completed!"
else
    echo "WordPress is already installed."
fi

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo "Starting PHP-FPM..."

exec "$@"

