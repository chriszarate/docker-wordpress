FROM php:7.0-apache

RUN apt-get update \
    && apt-get install -y --force-yes --no-install-recommends less libxml2-dev \
    && docker-php-ext-install mysqli opcache soap \
    && rm -rf /var/lib/apt/lists/*

RUN pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && rm -rf /tmp/pear/

RUN { \
      echo ''; \
      echo 'xdebug.remote_enable=1'; \
      echo 'xdebug.remote_port="9000"'; \
    } >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Enable error reporting.
# https://github.com/docker-library/php/issues/153
RUN { \
      echo 'error_reporting=E_ALL'; \
      echo 'log_errors=On'; \
    } > /usr/local/etc/php/conf.d/errors.ini

# Make Zend Opcache stat files on every request instead of every 60s.
# https://github.com/docker-library/wordpress/pull/103
RUN { \
      echo 'opcache.memory_consumption=128'; \
      echo 'opcache.interned_strings_buffer=8'; \
      echo 'opcache.max_accelerated_files=4000'; \
      echo 'opcache.revalidate_freq=0'; \
      echo 'opcache.fast_shutdown=1'; \
      echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN a2enmod rewrite

VOLUME /var/www/html

ENV WORDPRESS_VERSION 4.7.1
ENV WORDPRESS_SHA1 8e56ba56c10a3f245c616b13e46bd996f63793d6

# Download WordPress.
RUN curl -o wordpress.tar.gz -SL https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz \
    && echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c - \
    && tar -xzf wordpress.tar.gz -C /usr/src/ \
    && rm wordpress.tar.gz \
    && chown -R www-data:www-data /usr/src/wordpress

# Download WordPress testing suite.
RUN curl -o wordpress-dev.tar.gz -SL https://github.com/WordPress/wordpress-develop/tarball/master \
    && mkdir -p /tmp/wordpress/latest \
    && tar -xzf wordpress-dev.tar.gz  --strip-components 1 -C /tmp/wordpress/latest \
    && rm wordpress-dev.tar.gz

RUN curl -sSL -o /usr/local/bin/phpunit "https://phar.phpunit.de/phpunit.phar" \
    && chmod +x /usr/local/bin/phpunit

RUN { \
      echo '#!/usr/bin/env sh'; \
      echo 'runuser -l www-data -s /bin/sh -c "cd $PHPUNIT_TEST_DIR; WP_ABSPATH=/tmp/wordpress/latest/src/ WP_TESTS_DIR=/tmp/wordpress/latest/tests/phpunit /usr/local/bin/phpunit $*"'; \
    } > /usr/local/bin/tests \
    && chmod +x /usr/local/bin/tests

RUN curl -sSL -o /usr/local/bin/wp-cli "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" \
    && chmod +x /usr/local/bin/wp-cli

RUN mkdir -p /etc/wp-cli

RUN { \
      echo 'path: /var/www/html'; \
      echo 'url: project.dev'; \
      echo 'apache_modules:'; \
      echo '  - mod_rewrite'; \
    } > /etc/wp-cli/config.yml

RUN { \
      echo '#!/usr/bin/env sh'; \
      echo 'runuser -l www-data -s /bin/sh -c "WP_CLI_CONFIG_PATH=/etc/wp-cli/config.yml /usr/local/bin/wp-cli $*"'; \
    } > /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp

RUN curl -sSL "https://getcomposer.org/installer" | php \
    && mv composer.phar /usr/local/bin/composer

RUN { \
      echo '<IfModule mod_rewrite.c>'; \
      echo '  RewriteEngine On'; \
      echo '  RewriteBase /'; \
      echo '  RewriteRule ^index\.php$ - [L]'; \
      echo '  RewriteCond %{REQUEST_FILENAME} !-f'; \
      echo '  RewriteCond %{REQUEST_FILENAME} !-d'; \
      echo '  RewriteRule . /index.php [L]'; \
      echo '</IfModule>'; \
    } > /usr/src/wordpress/.htaccess

COPY docker-entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["apache2-foreground"]
