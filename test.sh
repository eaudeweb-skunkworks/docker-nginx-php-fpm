#!/usr/bin/env sh

set -e

sed -i '/supervisord --nodaemon/d' /docker-entrypoint

/docker-entrypoint

php -i | grep 'expose_php => Off'
php -i | grep 'max_file_uploads => 120'
php -i | grep 'max_input_vars => 10'
php -i | grep 'log_errors => On'
php -i | grep 'memory_limit => 1G'
php -i | grep 'post_max_size => 1G'
php -i | grep 'upload_max_filesize => 1G'
