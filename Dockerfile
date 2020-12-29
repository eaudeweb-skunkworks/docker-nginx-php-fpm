FROM php:5.6-fpm-alpine3.8

LABEL maintainer="Cristian Romanescu cristian.romanescu@eaudeweb.ro"

EXPOSE 80

WORKDIR /usr/share/nginx/html/

ARG APCU_VERSION=5.1.19

ENV php_expose_php="On" php_max_execution_time="120" php_max_file_uploads="20" php_max_input_vars="10000" \
    php_log_errors="On" php_memory_limit="1024M" php_post_max_size="512M" php_upload_max_filesize="128M"

COPY composer-install.sh /tmp/composer-install.sh
COPY docker-entrypoint /docker-entrypoint
COPY php/php.ini /usr/local/etc/php/php.ini
COPY php/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY php/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisord.conf

RUN chmod +x /docker-entrypoint && \
    apk add --no-cache --update --virtual .phpize-deps $PHPIZE_DEPS && \
    apk add --no-cache --update nginx apache2-utils sudo bash py-pip py3-pip py3-setuptools bzip2 libmcrypt libpng libjpeg-turbo libvpx libvpx-dev libwebp freetype gettext libzip openldap libmemcached icu libxml2 cyrus-sasl imap-dev mysql-client && \
    apk add --no-cache --update --virtual .php-ext-deps libbz2 bzip2-dev cyrus-sasl-dev freetype-dev gettext-dev git icu icu-dev krb5-dev libjpeg-turbo-dev libmcrypt-dev libmemcached-dev libpng-dev libwebp-dev libressl-dev libxml2-dev libzip-dev openldap-dev zlib-dev && \
    python3 -m pip install --upgrade pip && \
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-vpx-dir=/usr/include && \
    docker-php-ext-configure intl && \
    docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
    docker-php-ext-configure ldap --with-libdir=lib/ && \
    docker-php-ext-install -j$(nproc) bz2 gd gettext imap intl ldap mcrypt mysqli opcache pdo_mysql sockets xmlrpc zip && \
    pecl install memcached-2.2.0 igbinary-2.0.8 && docker-php-ext-enable igbinary memcached && \
    /tmp/composer-install.sh && composer self-update --1 && \
    apk add --no-cache patch && pip3 install supervisor wheel git+https://github.com/coderanger/supervisor-stdout && cd /tmp && wget https://patch-diff.githubusercontent.com/raw/coderanger/supervisor-stdout/pull/18.patch && cd /usr/lib/python3.6/site-packages/ && patch -p1 < /tmp/18.patch && rm /tmp/18.patch && \
    rm -rf /tmp/* /var/cache/apk/* && apk del .phpize-deps .php-ext-deps

ENTRYPOINT ["/docker-entrypoint"]