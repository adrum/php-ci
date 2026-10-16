# PHP_VERSION is a major.minor (8.2, 8.3, ...). BASE_SUFFIX selects the
# official image flavor: "" for Debian (php:8.4) or "-cli-alpine".
ARG PHP_VERSION=8.4
ARG BASE_SUFFIX=""

FROM mlocati/php-extension-installer:2.11.34 AS installer
FROM composer:2 AS composer

FROM php:${PHP_VERSION}${BASE_SUFFIX}

LABEL org.opencontainers.image.source=https://github.com/adrum/php-ci

COPY --from=installer /usr/bin/install-php-extensions /usr/local/bin/
COPY --from=composer /usr/bin/composer /usr/local/bin/composer

# pcov is left loaded with its defaults (same as installing it in the job).
# Do not add a conf.d ini disabling it: conf.d is scanned after `php -c`,
# so it would override a project's coverage ini.
# The mysql/psql clients are needed for Laravel to load schema dumps.
RUN install-php-extensions intl bcmath pcov zip pdo_mysql pdo_pgsql gd exif pcntl redis \
    && if command -v apk >/dev/null; then \
        apk add --no-cache git unzip curl jq mariadb-client postgresql-client; \
    else \
        apt-get update \
        && apt-get install -y --no-install-recommends git unzip curl jq default-mysql-client postgresql-client \
        && rm -rf /var/lib/apt/lists/*; \
    fi

ENV COMPOSER_ALLOW_SUPERUSER=1
