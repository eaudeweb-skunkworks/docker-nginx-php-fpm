FROM php:8.3-fpm-bookworm

LABEL maintainer="Cristian Romanescu cristian.romanescu@eaudeweb.ro"

EXPOSE 80

WORKDIR /usr/share/nginx/html/

ENV PHP_INI_OVERRIDES="expose_php=On;max_execution_time=120;max_file_uploads=20;max_input_vars=10000;log_errors=On;memory_limit=1024M;post_max_size=512M;upload_max_filesize=128M;date.timezone=UTC"\
    SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.33/supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=71b0d58cc53f6bd72cf2f293e09e294b79c666d8 \
    SUPERCRONIC=supercronic-linux-amd64

COPY composer-install.sh /tmp/composer-install.sh

RUN DEBIAN_FRONTEND=noninteractive apt update && \
	apt upgrade -y && \
	apt install -y apache2-utils bash bzip2 gettext git imagemagick ldap-utils libbz2-dev libc-client-dev libfreetype6 libfreetype6-dev libicu-dev libicu72 libjpeg-dev libjpeg-tools libjpeg-turbo-progs libkrb5-dev libldap-common libldap-dev libmagickwand-dev libmemcached-dev libmemcached11 libpng-dev libpng16-16 libwebp-dev libwebp7 libxml2 libxml2-dev libzip-dev libzip4 mariadb-client net-tools nginx patch procps python3-pip sudo supervisor vim-tiny webp wget zlib1g zlib1g-dev && \
	pip install git+https://github.com/Supervisor/supervisor.git --break-system-packages && \
	pip install git+https://github.com/coderanger/supervisor-stdout.git --break-system-packages && \
    docker-php-ext-configure gd --with-webp=/usr/include/ --with-freetype=/usr/include/ --with-jpeg=/usr/include/ && \
    docker-php-ext-configure intl && \
    docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
    docker-php-ext-configure ldap --with-libdir=lib/ && \
    docker-php-ext-configure random && \
    docker-php-ext-install -j$(nproc) bz2 gd gettext imap intl ldap mysqli opcache pdo_mysql sockets zip && \
    # Install igbinary (memcached's deps)
    printf "no" | pecl install apcu igbinary && \
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
    pecl install imagick && \
    # Enable PHP extensions
    docker-php-ext-enable apcu igbinary imagick memcached && \
    /tmp/composer-install.sh && \
    DEBIAN_FRONTEND=noninteractive apt remove -y --purge libc-client-dev libkrb5-dev libldap-dev libfreetype6-dev libicu-dev libmagickwand-dev libmemcached-dev libpng-dev libjpeg-dev libwebp-dev libzip-dev libxml2-dev zlib1g-dev && \
	DEBIAN_FRONTEND=noninteractive apt autoremove -y && \
    DEBIAN_FRONTEND=noninteractive apt clean all && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/cache/apt/* && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    update-alternatives --install /usr/bin/vim vim /usr/bin/vim.tiny 10 && \
    mkdir /opt/nvm/ && export NVM_DIR="/opt/nvm" && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash && \
    curl -fsSLO "$SUPERCRONIC_URL" && \
    echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - && \
    chmod +x "$SUPERCRONIC" && \
    mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" && \
    ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

COPY docker-entrypoint /docker-entrypoint
COPY php/php.ini /usr/local/etc/php/php.ini
COPY php/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY php/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisord.conf

ENTRYPOINT ["/docker-entrypoint"]
