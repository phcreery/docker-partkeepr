FROM php:7.1-apache
LABEL maintainer="Markus Hubig <mhubig@gmail.com>"
# LABEL version="1.4.0-20"
LABEL version="git"
ENV REPO https://github.com/partkeepr/partkeepr.git

ENV PARTKEEPR_VERSION 1.4.0

RUN set -ex \
    && apt-get update && apt-get install -y \
        bsdtar \
        libcurl4-openssl-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libicu-dev \
        libxml2-dev \
        libpng-dev \
        libldap2-dev \
        cron \
        git \
        wget \
    --no-install-recommends && rm -r /var/lib/apt/lists/* \
    \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) curl ldap bcmath gd dom intl opcache pdo pdo_mysql \
    \
    && pecl install apcu_bc-beta \
    && docker-php-ext-enable apcu

COPY install-composer.sh /
RUN cd / && ./install-composer.sh

RUN cd /var/www/html \
    && git clone ${REPO} . \
    && cp app/config/parameters.php.dist app/config/parameters.php \
    && php /composer.phar config --global github-protocols https \
    && php -d memory_limit=-1 /composer.phar install \
    && chown -R www-data:www-data /var/www/html \
    \
    && a2enmod rewrite

COPY crontab /etc/cron.d/partkeepr
COPY info.php /var/www/html/web/info.php
COPY php.ini /usr/local/etc/php/php.ini
COPY apache.conf /etc/apache2/sites-available/000-default.conf
COPY docker-php-entrypoint mkparameters parameters.template /usr/local/bin/

VOLUME ["/var/www/html/data", "/var/www/html/web"]

ENTRYPOINT ["docker-php-entrypoint"]
CMD ["apache2-foreground"]
