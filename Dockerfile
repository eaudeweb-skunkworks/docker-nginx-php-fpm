FROM php:7.3-fpm-alpine3.12

LABEL maintainer="Cristian Romanescu <cristian.romanescu@eaudeweb.ro>"

EXPOSE 80

ENTRYPOINT ["supervisord", "--nodaemon", "--configuration", "/etc/supervisord.conf"]

RUN apk add --no-cache --update nginx supervisor py3-pip py3-setuptools bzip2 libpng libjpeg-turbo libwebp freetype gettext libzip openldap libmemcached icu libxml2 cyrus-sasl imap-dev && \
    apk add --no-cache --update --virtual .php-ext-deps bzip2-dev cyrus-sasl-dev freetype-dev gettext-dev git icu icu-dev krb5-dev libjpeg-turbo-dev libmemcached-dev libpng-dev libwebp-dev openssl-dev libxml2-dev libzip-dev openldap-dev zlib-dev && \
    pip install wheel git+https://github.com/coderanger/supervisor-stdout && \
    docker-php-ext-configure gd --with-webp-dir=/usr/include/ --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-configure intl && \
    docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
    docker-php-ext-configure ldap --with-libdir=lib/ && \
    docker-php-ext-install -j$(nproc) bz2 gd gettext imap intl ldap mysqli opcache pdo_mysql sockets xmlrpc zip && \
    apk add --no-cache --update --virtual .phpize-deps $PHPIZE_DEPS && \
    apk add --no-cache --update --virtual .memcached-deps && \
    # Install igbinary (memcached's deps)
    pecl install igbinary && \
    # Install memcached
    ( \
        pecl install --nobuild memcached && \
        cd "$(pecl config-get temp_dir)/memcached" && \
        phpize && \
        ./configure --enable-memcached-igbinary && \
        make -j$(nproc) && \
        make install && \
        cd /tmp/ \
    ) && \
    # Enable PHP extensions
    docker-php-ext-enable igbinary memcached && \
    rm -rf /tmp/* /var/cache/apk/* && \
    apk del .memcached-deps .phpize-deps .php-ext-deps

COPY php/php.ini /usr/local/etc/php/php.ini
COPY php/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY php/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf
COPY nginx/nginx.conf /etc/nginx/nginx.conf

COPY composer-install.sh /tmp/composer-install.sh
RUN  /tmp/composer-install.sh

# Supervisor config
COPY ./supervisord.conf /etc/supervisord.conf
