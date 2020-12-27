#!/usr/bin/env bash
# Author: Bhaskar K <xlinkerz@gmail.com>

# Exit on error.
set -e

# NOTE: there is no php8-xdebug package available in edge alpinelinux
# Enables XDEBUG if ENABLE_XDEBUG arg is passed to Docker.
maybe_enable_xdebug() {
    if [[ "$ENABLE_XDEBUG" != 'true' ]]; then
        echo "XDEBUG is not enabled."
        return
    fi

    echo "Enabling XDEBUG."

    sed -i -e "s/display_errors = off/display_errors = On/" /etc/php8/php-fpm.d/custom.ini
    sed -i -e "s/log_errors = On/display_errors = off/" /etc/php8/php-fpm.d/custom.ini

    # Exit script if config is already written.
    if grep -q ";Start debug config" /etc/php8/php-fpm.d/xdebug.ini; then
        return
    fi

    echo "
    ;Start debug config
    ;xdebug.remote_host=docker.for.linux.host.internal
    ; Following vlaues are interpolated from env var; if supplied.
    xdebug.idekey=$XDEBUG_IDKEY
    xdebug.remote_host=$XDEBUG_REMOTE_HOST
    xdebug.remote_port=$XDEBUG_REMOTE_PORT
    xdebug.remote_handler=dbgp
    zend_extension=xdebug.so
    xdebug.remote_enable=1
    xdebug.remote_autostart=1
    xdebug.profiler_enable_trigger=1
    xdebug.profiler_enable=1
    xdebug.profiler_output_name = xdebug.out%t
    xdebug.profiler_output_dir = /tmp/php-profiler
    xdebug.var_display_max_depth = -1
    xdebug.var_display_max_children = -1
    xdebug.var_display_max_data = -1" >>/etc/php8/php-fpm.d/xdebug.ini
}

composer_deps_install() {
    if [[ "$APP_ENV" == 'local' ]]; then
        echo 'For local development "vendor" dir is mapped into the container'
        return
    fi
    composer update --no-cache --no-dev
}

composer_deps_install

# For local development and debugging.
# maybe_enable_xdebug

# Let supervisord start nginx & php-fpm
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
