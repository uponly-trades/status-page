#!/bin/sh
set -e
cd /var/www/html

# Write .env from container environment
cat > .env << EOF
APP_NAME=${APP_NAME:-Cachet}
APP_ENV=production
APP_KEY=${APP_KEY}
APP_DEBUG=false
APP_URL=${APP_URL:-http://localhost}
APP_TIMEZONE=${APP_TIMEZONE:-UTC}
APP_LOCALE=en

DB_CONNECTION=sqlite
DB_DATABASE=/var/www/html/database/database.sqlite

CACHE_STORE=database
SESSION_DRIVER=database
QUEUE_CONNECTION=sync

LOG_CHANNEL=stderr
LOG_LEVEL=warning

CACHET_BEACON=false
CACHET_TRUSTED_PROXIES=*
EOF

# Ensure SQLite file exists and is owned correctly
touch database/database.sqlite
chown www-data:www-data database/database.sqlite

php artisan migrate --force --no-interaction

php artisan config:cache
php artisan route:cache
php artisan view:cache

exec /usr/bin/supervisord -c /etc/supervisord.conf
