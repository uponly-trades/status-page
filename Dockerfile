# ── Stage 1: PHP dependencies ─────────────────────────────────────────────
FROM composer:2.8 AS vendor

RUN git clone -b 3.x --depth=1 https://github.com/cachethq/cachet /app

WORKDIR /app

# Convert SSH remote to HTTPS so composer can pull without a key
RUN sed -i 's|git@github.com:cachethq/core.git|https://github.com/cachethq/core.git|g' composer.json

# Minimal .env so artisan commands don't blow up during install scripts
RUN cp .env.example .env && sed -i 's/APP_KEY=/APP_KEY=base64:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa=/' .env

RUN composer install \
    --no-dev \
    --no-interaction \
    --optimize-autoloader \
    --prefer-dist \
    --ignore-platform-reqs

# ── Stage 2: Node / Vite assets ───────────────────────────────────────────
FROM node:20-alpine AS assets

WORKDIR /app
COPY --from=vendor /app /app

RUN npm install && npm run build

# ── Stage 3: Runtime ──────────────────────────────────────────────────────
FROM php:8.2-fpm-alpine

RUN apk add --no-cache nginx supervisor curl icu-dev libzip-dev bzip2-dev \
 && docker-php-ext-install pdo pdo_sqlite mbstring bcmath pcntl ctype fileinfo opcache intl zip \
 && docker-php-ext-enable sodium

COPY --from=assets /app /var/www/html

WORKDIR /var/www/html

RUN mkdir -p storage/logs \
        storage/framework/cache/data \
        storage/framework/sessions \
        storage/framework/views \
        bootstrap/cache \
        database \
 && touch database/database.sqlite \
 && chown -R www-data:www-data storage bootstrap/cache database \
 && chmod -R 775 storage bootstrap/cache database \
 && rm -f /etc/nginx/http.d/default.conf

COPY nginx.conf      /etc/nginx/http.d/cachet.conf
COPY supervisord.conf /etc/supervisord.conf
COPY entrypoint.sh   /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8000
ENTRYPOINT ["/entrypoint.sh"]
