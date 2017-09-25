#!/usr/bin/env bash

set -ex

ROOT_DIR=/var/www/html
WEB_USER=www-data

# Copy WordPress core.
if ! [ -e wp-includes/version.php ]; then
  tar cf - --one-file-system -C /usr/src/wordpress . | tar xf - --owner="$(id -u $WEB_USER)" --group="$(id -g $WEB_USER)"
  echo "WordPress has been successfully copied to $(pwd)"
fi

# Seed wp-content directory if requested.
if [ -d /tmp/wordpress/init-wp-content ]; then
  tar cf - --one-file-system -C /tmp/wordpress/init-wp-content . | tar xf - -C ./wp-content --owner="$(id -u $WEB_USER)" --group="$(id -g $WEB_USER)"
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
if ! [ -f $ROOT_DIR/wp-config.php ]; then
  runuser $WEB_USER -s /bin/sh -c "\
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
mkdir -p $ROOT_DIR/wp-content/uploads
chown $WEB_USER:$WEB_USER $ROOT_DIR/wp-content
chown -R $WEB_USER:$WEB_USER $ROOT_DIR/wp-content/uploads

# MySQL may not be ready when container starts.
set +ex
while true; do
  if curl --fail --show-error --silent "${WORDPRESS_DB_HOST:-mysql}:3306" > /dev/null 2>&1; then break; fi
  echo "Waiting for MySQL to be ready...."
  sleep 3
done
set -ex

# Install WordPress.
runuser $WEB_USER -s /bin/sh -c "\
wp core $([ "$WORDPRESS_INSTALL_TYPE" == "multisite" ] && echo "multisite-install" || echo "install") \
  --title=\"${WORDPRESS_SITE_TITLE:-Project}\" \
  --admin_user=\"${WORDPRESS_SITE_USER:-wordpress}\" \
  --admin_password=\"${WORDPRESS_SITE_PASSWORD:-wordpress}\" \
  --admin_email=\"${WORDPRESS_SITE_EMAIL:-admin@example.com}\" \
  --url=\"${WORDPRESS_SITE_URL:-http://project.dev}\" \
  --skip-email"

# Update rewrite structure.
runuser $WEB_USER -s /bin/sh -c "\
wp option update permalink_structure \"${WORDPRESS_PERMALINK_STRUCTURE:-/%year%/%monthnum%/%postname%/}\" \
  --skip-themes \
  --skip-plugins"

# Activate plugins. Install if it cannot be found locally.
if [ -n "$WORDPRESS_ACTIVATE_PLUGINS" ]; then
  for plugin in $WORDPRESS_ACTIVATE_PLUGINS; do
    if ! [ -d "$ROOT_DIR/wp-content/plugins/$plugin" ]; then
      runuser $WEB_USER -s /bin/sh -c "wp plugin install \"$plugin\""
    fi
  done

  # shellcheck disable=SC2086
  runuser $WEB_USER -s /bin/sh -c "wp plugin activate $WORDPRESS_ACTIVATE_PLUGINS"
fi

# Activate theme. Install if it cannot be found locally.
if [ -n "$WORDPRESS_ACTIVATE_THEME" ]; then
  if ! [ -d "$ROOT_DIR/wp-content/themes/$WORDPRESS_ACTIVATE_THEME" ]; then
    runuser $WEB_USER -s /bin/sh -c "wp theme install \"$WORDPRESS_ACTIVATE_THEME\""
  fi

  runuser $WEB_USER -s /bin/sh -c "wp theme activate \"$WORDPRESS_ACTIVATE_THEME\""
fi

exec "$@"
