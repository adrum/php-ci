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
RUN pcov=pcov; [ "$PHP_VERSION" = "8.6" ] && pcov=""; \
    install-php-extensions mbstring intl bcmath $pcov zip pdo_mysql pdo_pgsql gd exif pcntl redis \
    && if command -v apk >/dev/null; then \
        apk add --no-cache git unzip curl jq mariadb-client postgresql-client; \
    else \
        apt-get update \
        && apt-get install -y --no-install-recommends git unzip curl jq default-mysql-client postgresql-client \
        && rm -rf /var/lib/apt/lists/*; \
    fi

# pcov 1.0.12 does not compile on PHP 8.6, so 8.6 builds it from
# https://github.com/krakjoe/pcov/pull/134 until a release supports it.
ARG PCOV_86_COMMIT=f04029fa86ae58c6dfff8049de8433669dbf1394
RUN if [ "$PHP_VERSION" = "8.6" ]; then \
        if command -v apk >/dev/null; then apk add --no-cache --virtual .pcov-build $PHPIZE_DEPS; fi \
        && mkdir /tmp/pcov \
        && curl -fsSL "https://codeload.github.com/krakjoe/pcov/tar.gz/$PCOV_86_COMMIT" | tar -xz -C /tmp/pcov --strip-components=1 \
        && cd /tmp/pcov \
        && phpize && ./configure --enable-pcov && make -j"$(nproc)" && make install \
        && docker-php-ext-enable pcov \
        && cd / && rm -rf /tmp/pcov \
        && if command -v apk >/dev/null; then apk del --no-network .pcov-build; fi; \
    fi

ENV COMPOSER_ALLOW_SUPERUSER=1
