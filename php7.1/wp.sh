#!/bin/bash
set -e

if [[ "$1" == apache2* ]] || [ "$1" == php-fpm ]; then
    wp --info --allow-root

    if ! [ -e index.php -a -d wp-content ]; then

        echo >&2 "WordPress not found in $(pwd) - installing now..."
        if [ "$(ls -A)" ]; then
            echo >&2 "WARNING: $(pwd) is not empty - press Ctrl+C now if this is an error!"
            ( set -x; ls -A; sleep 10 )
            rm -R ./*
        fi

        wp core download --path=wp --allow-root --debug
        wp core config \
            --allow-root \
            --path=wp \
            --skip-check \
            --dbname=${MYSQL_DATABASE:="wordpress"} \
            --dbuser=${MYSQL_USER:=root} \
            --dbpass=${MYSQL_PASSWORD:=MYSQL_ROOT_PASSWORD} \
            --dbhost=${WORDPRESS_DB_HOST:="mysql"} \
            --dbprefix=${WORDPRESS_TABLE_PREFIX:="wp_"} \
            --extra-php <<-EOPHP
define('WP_DEBUG', true );
define('WP_DEBUG_LOG',          true);  // Turn logging to wp-content/debug.log ON
define('WP_DEBUG_DISPLAY',      false); // Turn forced display OFF
define('SAVEQUERIES',           true); // Log database queries to an array
@ini_set('display_errors',      0);
@ini_set('error_reporting',    30711); // Hide unnecesary notices

/**
 * Spoof the Home and Site URLs
 */
define('WP_HOME', 'http://www.$DEV_DOMAIN');
define('WP_SITEURL', 'http://www.$DEV_DOMAIN/wp/');

/**
 * Let WordPress know we've moved our wp-content directory
 **/
define( 'WP_CONTENT_DIR', dirname( __FILE__ ) . '/wp-content' );
\$root = substr(\$_SERVER['PHP_SELF'], 0 , strpos(\$_SERVER['PHP_SELF'], 'wp/') ? strpos(\$_SERVER['PHP_SELF'], 'wp/') : strrpos(\$_SERVER['PHP_SELF'], '/'));
define( 'WP_CONTENT_URL', 'http://' . \$_SERVER['HTTP_HOST'] . \$root . '/wp-content' );
EOPHP

        echo >&2 "Created wp-config.php for ${DEV_DOMAIN}"

        wp core install \
            --allow-root \
            --path=wp \
            --url=http://www.${DEV_DOMAIN} \
            --title="${WORDPRESS_SITE_TITLE:='New Wordpress Site'}" \
            --admin_user="${WORDPRESS_ADMIN_USER:=admin}" \
            --admin_password="${WORDPRESS_ADMIN_PASS:=letmein123}" \
            --admin_email="${WORDPRESS_ADMIN_EMAIL:=noone@nowhere.org}" \

        echo >&2 "Installed Wordpress"

        wp option update siteurl "http://www.${DEV_DOMAIN}/wp" \
            --allow-root \
            --path=wp

        echo >&2 "Updated Site URL to http://www.${DEV_DOMAIN}/wp"

        wp option update home "http://www.${DEV_DOMAIN}" \
            --allow-root \
            --path=wp

        echo >&2 "Updated Home to http://www.${DEV_DOMAIN}"

        wp rewrite structure '/%category%/%post_id%-%postname%' \
            --allow-root \
            --path=wp

        echo >&2 "Changed the Permalink rewrite structure"

        wp rewrite flush \
            --allow-root \
            --path=wp

        echo >&2 "Flushed the Permalink cache"

        echo >&2 'Setup for wordpress install in wp/'
        mv wp/wp-content .
        echo >&2 'Moved wp-content/ into the site root'
        mv wp/index.php .
        sed -ri 's%/wp-blog-header.php%/wp/wp-blog-header.php%' index.php
        echo >&2 'Moved index.php into the site root and updated location of wp-blog-header.php'
        mv wp/wp-config.php .
        echo >&2 'Moved wp-config.php into the site root'
        
        echo >&2 "Complete! WordPress has been successfully copied to $(pwd)"

    fi

    chown -R www-data:www-data /var/www/html
    find /var/www/html -type f -exec chmod 666 {} \;
    find /var/www/html -type d -exec chmod 777 {} \;
fi

exec "$@"