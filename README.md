# php-ci

PHP images for running Laravel (and other PHP) test suites in CI, without spending
the first minute of every job installing extensions and tools.

Built on the official [`php`](https://hub.docker.com/_/php) images, for `linux/amd64`
and `linux/arm64`, and published to GHCR.

## Tags

| PHP | Debian | Alpine |
| --- | --- | --- |
| 8.5 | `ghcr.io/adrum/php-ci:8.5` | `ghcr.io/adrum/php-ci:8.5-alpine` |
| 8.4 | `ghcr.io/adrum/php-ci:8.4` | `ghcr.io/adrum/php-ci:8.4-alpine` |
| 8.3 | `ghcr.io/adrum/php-ci:8.3` | `ghcr.io/adrum/php-ci:8.3-alpine` |
| 8.2 | `ghcr.io/adrum/php-ci:8.2` | `ghcr.io/adrum/php-ci:8.2-alpine` |
| 8.1 | `ghcr.io/adrum/php-ci:8.1` | `ghcr.io/adrum/php-ci:8.1-alpine` |
| 8.0 | `ghcr.io/adrum/php-ci:8.0` | `ghcr.io/adrum/php-ci:8.0-alpine` |
| 7.4 | `ghcr.io/adrum/php-ci:7.4` | `ghcr.io/adrum/php-ci:7.4-alpine` |

Debian tags are based on `php:<version>`, Alpine tags on `php:<version>-cli-alpine`.

PHP 8.1 and older are end of life upstream: their base images no longer receive PHP
patches, but OS packages and extensions are still refreshed weekly.

## What's included

Everything the official image ships (`pdo_sqlite`, `mbstring`, `curl`, `dom`, `openssl`,
`sodium`, `tokenizer`, ...), plus:

- **Extensions:** `intl`, `bcmath`, `zip`, `pdo_mysql`, `pdo_pgsql`, `gd`, `exif`,
  `pcntl`, `redis`, `pcov`
- **Tools:** `composer` (2.x), `git`, `unzip`, `curl`, `jq`, `mysql` and `psql` clients (used
  by Laravel to load schema dumps)

`COMPOSER_ALLOW_SUPERUSER=1` is set. Xdebug is not installed.

### Coverage with pcov

pcov is loaded with its default settings. No `conf.d` file overrides it, so a project
ini passed with `php -c` controls it:

```sh
XDEBUG_MODE=off php -c ci/files/test.ini vendor/bin/phpunit --coverage-text
```

## Usage

GitLab CI:

```yaml
test:
  image: ghcr.io/adrum/php-ci:8.4
  script:
    - composer install --no-interaction --prefer-dist
    - php artisan test
```

GitHub Actions:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    container: ghcr.io/adrum/php-ci:8.4
    steps:
      - uses: actions/checkout@v4
      - run: composer install --no-interaction --prefer-dist
      - run: php artisan test
```

## Updates

Images are rebuilt on every push to `main` and every Saturday. The weekly build
skips the build cache, so it picks up new PHP patch releases, base image updates, OS
packages and extension releases. Each image must pass [`tests/smoke.sh`](tests/smoke.sh)
before it is pushed.

## License

[MIT](LICENSE)
