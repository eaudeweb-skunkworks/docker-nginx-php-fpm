FROM php:8.0-fpm-alpine3.12

LABEL maintainer="Cristian Romanescu cristian.romanescu@eaudeweb.ro"

EXPOSE 80

WORKDIR /usr/share/nginx/html/

ARG APCU_VERSION=5.1.19

ENV PHP_INI_OVERRIDES="expose_php=On;max_execution_time=120;max_file_uploads=20;max_input_vars=10000;log_errors=On;memory_limit=1024M;post_max_size=512M;upload_max_filesize=128M;date.timezone=UTC"

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
    apk add --no-cache --update nginx apache2-utils sudo bash supervisor py3-pip py3-setuptools bzip2 libpng libjpeg-turbo libwebp freetype gettext libzip openldap libmemcached icu libxml2 cyrus-sasl imap-dev mysql-client && \
    apk add --no-cache --update --virtual .php-ext-deps bzip2-dev cyrus-sasl-dev freetype-dev gettext-dev git icu icu-dev krb5-dev libjpeg-turbo-dev libmemcached-dev libpng-dev libwebp-dev openssl-dev libxml2-dev libzip-dev openldap-dev zlib-dev && \
    pip install wheel git+https://github.com/coderanger/supervisor-stdout && \
    docker-php-ext-configure gd --with-webp=/usr/include/ --with-freetype=/usr/include/ --with-jpeg=/usr/include/ && \
    docker-php-ext-configure intl && \
    docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
    docker-php-ext-configure ldap --with-libdir=lib/ && \
    docker-php-ext-install -j$(nproc) bz2 gd gettext imap intl ldap mysqli opcache pdo_mysql sockets zip && \
    # Install igbinary (memcached's deps)
    printf "no" | pecl install apcu-${APCU_VERSION} igbinary && \
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
    docker-php-ext-enable apcu igbinary memcached && \
    /tmp/composer-install.sh && \
    # Patch supervisor issue
    apk add --no-cache patch && cd /tmp && wget https://patch-diff.githubusercontent.com/raw/coderanger/supervisor-stdout/pull/18.patch && cd /usr/lib/python3.8/site-packages/ && patch -p1 < /tmp/18.patch && rm /tmp/18.patch && \
    apk del .phpize-deps .php-ext-deps && \
    rm -rf /tmp/* /var/cache/apk/*

ENTRYPOINT ["/docker-entrypoint"]