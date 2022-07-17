FROM chialab/php:7.1-apache
LABEL maintainer="Markus Hubig <mhubig@gmail.com>"
LABEL version="1.4.0-20"

ENV REPO https://github.com/partkeepr/partkeepr.git
ENV PARTKEEPR_VERSION 1.4.0
ENV PARTKEEPR_INSTALL_SRC git

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
    # && docker-php-ext-install -j$(nproc) curl ldap bcmath gd dom intl opcache pdo pdo_mysql \
    \
    && pecl install apcu_bc-beta \
    && docker-php-ext-enable apcu \
    \
    && if [ "${PARTKEEPR_INSTALL_SRC}" == "git" ]; then \
        cd /var/www/html \
        && composer self-update 1.4.1 \
        && git clone ${REPO} . \
        && cp app/config/parameters.php.dist app/config/parameters.php \
        && composer install \
    ; else \
        cd /var/www/html \
        && curl -sL https://downloads.partkeepr.org/partkeepr-${PARTKEEPR_VERSION}.tbz2 \
            |bsdtar --strip-components=1 -xvf- \
    ; fi \
    \
    && ls -la /var/www/html/ \
    && chown -R www-data:www-data /var/www/html \
    && a2enmod rewrite \
    \ 
    && if [[ -z "${PARTKEEPR_BASE_URL}" ]]; then \
        printf "framework: \n    assets: \n        base_urls: \n            - http://localhost' \n" \
        > /var/www/html/app/config/config_custom.yml \
    ; else \
        printf "framework: \n    assets: \n        base_urls: \n            - '%s' \n" \
        ${PARTKEEPR_BASE_URL} > /var/www/html/app/config/config_custom.yml \
    ; fi

COPY crontab /etc/cron.d/partkeepr
COPY info.php /var/www/html/web/info.php
COPY php.ini /usr/local/etc/php/php.ini
COPY apache.conf /etc/apache2/sites-available/000-default.conf
COPY docker-php-entrypoint mkparameters parameters.template /usr/local/bin/

VOLUME ["/var/www/html/data", "/var/www/html/web"]

ENTRYPOINT ["docker-php-entrypoint"]
CMD ["apache2-foreground"]
