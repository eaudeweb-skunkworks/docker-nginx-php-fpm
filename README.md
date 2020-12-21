# docker-nginx-php-fpm
Docker image with NGINX and PHP-FPM using supervisord

This image is ready to run applications PHP-FPM applications such as Drupal.

Extensions: `bz2`, `gd`, `gettext`, `imap`, `intl`, `ldap`, `mysqli`, `opcache`, `pdo_mysql`, `sockets`, `xmlrpc`, `zip`

# Build & run locally

```shell
# ./build.sh
# docker run -it --rm --name php80 -e php_memory_limit=2048M cristiroma/nginx-php-fpm:php80
```

# Running tests locally before commit

```
docker-compose -f docker-compose.test.yml up
```

# Using the image

## docker-compose.yml example

See `docker-compose.test.yml`

## Installing a CRON job

When starting, the image looks into environment for variable `CRON_SCHEDULE_COMMAND` and installs the job  into `/etc/crontabs/root`. Example:

```dotenv
CRON_SCHEDULE_COMMAND="* * * * * cd /usr/share/nginx/html && sudo -E -u www-data ./vendor/bin/drush core:cron --uri=${DRUPAL_URL}"
CRON_SCHEDULE_COMMAND1="*/30 * * * * cd /usr/share/nginx/html && sudo -E -u www-data ./vendor/bin/drush core:cron --uri=${DRUPAL_URL}"
CRON_SCHEDULE_COMMAND2="* * * * * cd /usr/share/nginx/html && sudo -E -u www-data ./vendor/bin/drush core:cron --uri=${DRUPAL_URL}"
```