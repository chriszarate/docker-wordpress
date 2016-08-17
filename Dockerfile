FROM wordpress

RUN apt-get update \
    && apt-get install -y --force-yes --no-install-recommends less subversion \
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
RUN sed -i -E 's#(revalidate_freq)=[0-9]+#\1=0#' /usr/local/etc/php/conf.d/opcache-recommended.ini

# Download WordPress test bed.
RUN svn co --quiet --trust-server-cert --non-interactive https://develop.svn.wordpress.org/trunk /tmp/wordpress/latest \
    && chown -R www-data:www-data /tmp/wordpress/latest

RUN curl -sSL -o /usr/local/bin/phpunit "https://phar.phpunit.de/phpunit.phar" \
    && chmod +x /usr/local/bin/phpunit

RUN { \
      echo '#!/usr/bin/env sh'; \
      echo 'runuser -l www-data -s /bin/sh -c "cd $PHPUNIT_TEST_DIR; /usr/local/bin/phpunit $*"'; \
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
