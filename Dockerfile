FROM php:7.3-fpm-alpine3.12

LABEL maintainer="Cristian Romanescu cristian.romanescu@eaudeweb.ro"

EXPOSE 80

WORKDIR /usr/share/nginx/html/

ENV php_expose_php="On" php_max_execution_time="120" php_max_file_uploads="20" php_max_input_vars="10000" \
    php_log_errors="On" php_memory_limit="1024M" php_post_max_size="512M" php_upload_max_filesize="128M"

COPY php/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY php/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY composer-install.sh /tmp/composer-install.sh
COPY ./supervisord.conf /etc/supervisord.conf
COPY docker-entrypoint /docker-entrypoint

RUN chmod +x /docker-entrypoint && \
    apk add --no-cache --update nginx supervisor py3-pip py3-setuptools bzip2 libpng libjpeg-turbo libwebp freetype gettext libzip openldap libmemcached icu libxml2 cyrus-sasl imap-dev && \
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
    /tmp/composer-install.sh && \
    # Patch supervisor issue
    apk add --no-cache patch && cd /tmp && wget https://patch-diff.githubusercontent.com/raw/coderanger/supervisor-stdout/pull/18.patch && cd /usr/lib/python3.8/site-packages/ && patch -p1 < /tmp/18.patch && rm /tmp/18.patch && \
    rm -rf /tmp/* /var/cache/apk/* && \
    apk del .memcached-deps .phpize-deps .php-ext-deps

ENTRYPOINT ["/docker-entrypoint"]