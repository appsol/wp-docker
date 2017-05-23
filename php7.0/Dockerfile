FROM php:7.0-apache

RUN a2enmod rewrite expires

# install the PHP extensions we need
RUN apt-get update && apt-get install -y libpng12-dev libjpeg-dev && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
    && docker-php-ext-install gd mysqli opcache

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=60'; \
        echo 'opcache.fast_shutdown=1'; \
        echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN { \
        echo 'error_reporting=30711'; \
        echo 'display_errors=0'; \
    } > /usr/local/etc/php/conf.d/wordpress.ini

# Install WP-CLI
WORKDIR /tmp
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp-cli.phar
RUN ./wp-cli.phar cli update --yes --allow-root
RUN ./wp-cli.phar cli version --allow-root
RUN mv wp-cli.phar /usr/local/bin/wp

COPY wp.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wp.sh

VOLUME /var/www/html
WORKDIR /var/www/html/

ENTRYPOINT ["wp.sh"]
CMD ["apache2-foreground"]