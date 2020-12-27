FROM alpine:edge

LABEL Maintainer="Bhaskar KC <xlinkerz@gmai.com>"
LABEL Description="PHP Server with PHP-FPM 8 and Nginx"

# At the time of writing this file,
#   Nginx version is 1.18 on alpine edge
#   PHP version is 8.0

# TODO: once PHP8 is stable in alpine linux remove testing repo.
RUN apk --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing add \
        php8 php8-fpm php8-opcache php8-mysqli php8-json php8-exif php8-tokenizer \
        php8-openssl php8-soap php8-zlib php8-xml php8-phar php8-dom php8-curl\
        php8-intl php8-xmlwriter php8-xmlreader php8-ctype php8-session \
        php8-simplexml php8-mbstring php8-gd php8-zip \
        nginx supervisor bash curl tzdata mysql-client && \
        rm /etc/nginx/conf.d/default.conf && \
        ln -s /usr/bin/php8 /usr/bin/php

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/php-fpm.conf /etc/php8/php-fpm.d/www.conf
COPY conf/php.ini /etc/php8/conf.d/custom.ini
COPY conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY entrypoint.sh /run/

RUN chmod +x /run/entrypoint.sh

WORKDIR /var/www/html

RUN mkdir ./vendor && chown -R nobody.nobody vendor/
RUN chown -R nobody.nobody /run && \
  chown -R nobody.nobody /var/lib/nginx && \
  chown -R nobody.nobody /var/log/nginx

USER nobody

# Expose nginx http server port
EXPOSE 3000

CMD ["/bin/bash",  "/run/entrypoint.sh"]

# Server Healthcheck
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:3000/fpm-ping
