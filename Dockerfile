# PHP_VERSION is a major.minor (8.2, 8.3, ...). BASE_SUFFIX selects the
# official image flavor: "" for Debian (php:8.4) or "-cli-alpine".
ARG PHP_VERSION=8.4
ARG BASE_SUFFIX=""

FROM mlocati/php-extension-installer:2.13.2 AS installer
FROM composer:2 AS composer

FROM php:${PHP_VERSION}${BASE_SUFFIX}

LABEL org.opencontainers.image.source=https://github.com/adrum/php-ci

COPY --from=installer /usr/bin/install-php-extensions /usr/local/bin/
COPY --from=composer /usr/bin/composer /usr/local/bin/composer

# pcov is left loaded with its defaults (same as installing it in the job).
# Do not add a conf.d ini disabling it: conf.d is scanned after `php -c`,
# so it would override a project's coverage ini.
# The mysql/psql clients are needed for Laravel to load schema dumps.
# PHP 8.6 images no longer bundle mbstring; on older versions it is built in and skipped.
ARG PHP_VERSION
RUN pecl=" pcov redis"; [ "$PHP_VERSION" = "8.6" ] && pecl=""; \
    install-php-extensions mbstring intl bcmath zip pdo_mysql pdo_pgsql gd exif pcntl$pecl \
    && if command -v apk >/dev/null; then \
        apk add --no-cache git unzip curl jq mariadb-client postgresql-client; \
    else \
        apt-get update \
        && apt-get install -y --no-install-recommends git unzip curl jq default-mysql-client postgresql-client \
        && rm -rf /var/lib/apt/lists/*; \
    fi

# The latest releases of pcov (1.0.12) and phpredis (6.3.0) do not compile on
# PHP 8.6, so 8.6 builds them from pinned commits until releases support it:
# pcov from https://github.com/krakjoe/pcov/pull/134 and phpredis from develop.
ARG PCOV_86_COMMIT=f04029fa86ae58c6dfff8049de8433669dbf1394
ARG PHPREDIS_86_COMMIT=a6ce1e60b3e81ce3b25174aa5aaefd5590dc64fd
RUN if [ "$PHP_VERSION" = "8.6" ]; then \
        set -e; \
        build() { \
            mkdir "/tmp/$1"; \
            curl -fsSL "https://codeload.github.com/$2/tar.gz/$3" | tar -xz -C "/tmp/$1" --strip-components=1; \
            cd "/tmp/$1"; \
            phpize; ./configure --enable-"$1"; make -j"$(nproc)"; make install; \
            cd /; rm -rf "/tmp/$1"; \
            docker-php-ext-enable "$1"; \
        }; \
        if command -v apk >/dev/null; then apk add --no-cache --virtual .ext-build $PHPIZE_DEPS; fi; \
        build pcov krakjoe/pcov "$PCOV_86_COMMIT"; \
        build redis phpredis/phpredis "$PHPREDIS_86_COMMIT"; \
        if command -v apk >/dev/null; then apk del --no-network .ext-build; fi; \
    fi

ENV COMPOSER_ALLOW_SUPERUSER=1
