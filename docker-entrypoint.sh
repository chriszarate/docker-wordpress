#!/usr/bin/env bash

set -ex

# Copy WordPress core.
if ! [ -e wp-includes/version.php ]; then
  tar cf - --one-file-system -C /usr/src/wordpress . | tar xf - --owner="$(id -u www-data)" --group="$(id -g www-data)"
  echo "WordPress has been successfully copied to $(pwd)"
fi

# Seed wp-content directory if requested.
if [ -d /tmp/wordpress/init-wp-content ]; then
  tar cf - --one-file-system -C /tmp/wordpress/init-wp-content . | tar xf - -C ./wp-content --owner="$(id -u www-data)" --group="$(id -g www-data)"
  echo "Seeded wp-content directory from /tmp/wordpress/init-wp-content."
fi

# Install certs if requested.
if [ -d /tmp/certs ]; then
  mkdir -p /usr/share/ca-certificates/local

  for cert in /tmp/certs/*.crt; do
    cp "$cert" "/usr/share/ca-certificates/local/$(basename "$cert")"
    echo "local/$(basename "$cert")" >> /etc/ca-certificates.conf
  done

  update-ca-certificates --fresh
  echo "Added certs from /tmp/certs."
fi

# Update WP-CLI config with current virtual host.
sed -i -E "s#^url: .*#url: ${WORDPRESS_SITE_URL:-http://project.dev}#" /etc/wp-cli/config.yml

# Create WordPress config.
if ! [ -f /var/www/html/wp-config.php ]; then
  runuser www-data -s /bin/sh -c "\
  wp config create \
    --dbhost=\"${WORDPRESS_DB_HOST:-mysql}\" \
    --dbname=\"${WORDPRESS_DB_NAME:-wordpress}\" \
    --dbuser=\"${WORDPRESS_DB_USER:-root}\" \
    --dbpass=\"$WORDPRESS_DB_PASSWORD\" \
    --skip-check \
    --extra-php <<PHP
$WORDPRESS_CONFIG_EXTRA
PHP"
fi

# Make sure uploads directory exists and is writeable.
chown www-data:www-data /var/www/html/wp-content
runuser www-data -s /bin/sh -c "mkdir -p /var/www/html/wp-content/uploads"

# MySQL may not be ready when container starts.
set +ex
while true; do
  if curl --fail --show-error --silent "${WORDPRESS_DB_HOST:-mysql}:3306" > /dev/null 2>&1; then break; fi
  echo "Waiting for MySQL to be ready...."
  sleep 3
done
set -ex

# Install WordPress.
runuser www-data -s /bin/sh -c "\
wp core $([ "$WORDPRESS_INSTALL_TYPE" == "multisite" ] && echo "multisite-install" || echo "install") \
  --title=\"${WORDPRESS_SITE_TITLE:-Project}\" \
  --admin_user=\"${WORDPRESS_SITE_USER:-wordpress}\" \
  --admin_password=\"${WORDPRESS_SITE_PASSWORD:-wordpress}\" \
  --admin_email=\"${WORDPRESS_SITE_EMAIL:-admin@example.com}\" \
  --url=\"${WORDPRESS_SITE_URL:-http://project.dev}\" \
  --skip-email"

# Update rewrite structure.
runuser www-data -s /bin/sh -c "\
wp option update permalink_structure \"${WORDPRESS_PERMALINK_STRUCTURE:-/%year%/%monthnum%/%postname%/}\" \
  --skip-themes \
  --skip-plugins"

# Activate plugins. Install if it cannot be found locally.
if [ -n "$WORDPRESS_ACTIVATE_PLUGINS" ]; then
  for plugin in $WORDPRESS_ACTIVATE_PLUGINS; do
    if ! [ -d "/var/www/html/wp-content/plugins/$plugin" ]; then
      runuser www-data -s /bin/sh -c "wp plugin install \"$plugin\""
    fi
  done

  # shellcheck disable=SC2086
  runuser www-data -s /bin/sh -c "wp plugin activate $WORDPRESS_ACTIVATE_PLUGINS"
fi

# Activate theme. Install if it cannot be found locally.
if [ -n "$WORDPRESS_ACTIVATE_THEME" ]; then
  if ! [ -d "/var/www/html/wp-content/themes/$WORDPRESS_ACTIVATE_THEME" ]; then
    runuser www-data -s /bin/sh -c "wp theme install \"$WORDPRESS_ACTIVATE_THEME\""
  fi

  runuser www-data -s /bin/sh -c "wp theme activate \"$WORDPRESS_ACTIVATE_THEME\""
fi

exec "$@"
