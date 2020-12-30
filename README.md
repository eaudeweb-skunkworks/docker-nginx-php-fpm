# docker-nginx-php-fpm
Docker image with NGINX and PHP-FPM using supervisord

This image is ready to run applications PHP-FPM applications such as Drupal.

Extensions: `bz2`, `gd`, `gettext`, `imap`, `intl`, `ldap`, `mysqli`, `opcache`, `pdo_mysql`, `sockets`, `xmlrpc`, `zip`

# Build & run locally

```shell
# ./build.sh
# docker run -it --rm --name php56 -e php_memory_limit=2048M cristiroma/nginx-php-fpm:php56
```

# Running tests locally before commit

```
# Modify the docker-compose.test.yml to use the docker image and comment "build: context"
./build.sh
docker-compose -f docker-compose.test.yml up
# Modify back docker-compose.test.yml to use the "build: context"
```

# docker-compose.yml example

See `docker-compose.test.yml`