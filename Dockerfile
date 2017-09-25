FROM wordpress:4.8.2-php7.0-fpm-alpine

RUN apk --no-cache --update \
      add \
      autoconf \
      g++ \
      less \
      make \
      libxml2-dev \
    && docker-php-ext-install soap

RUN pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && rm -rf /tmp/pear/

RUN { \
      echo ''; \
      echo 'xdebug.remote_enable=1'; \
      echo 'xdebug.remote_port="9001"'; \
    } >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

VOLUME /var/www/html

RUN curl -sSL -o /usr/local/bin/wp "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" \
    && chmod +x /usr/local/bin/wp \
    && mkdir -p /etc/wp-cli \
    && chown www-data:www-data /etc/wp-cli

RUN { \
      echo 'path: /var/www/html'; \
      echo 'url: project.dev'; \
    } > /etc/wp-cli/config.yml

RUN echo "export WP_CLI_CONFIG_PATH=/etc/wp-cli/config.yml" > /etc/profile.d/wp-cli.sh

COPY docker-entrypoint.sh /usr/local/bin/
