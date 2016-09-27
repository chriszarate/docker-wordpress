# WordPress on Docker

This image provides WordPress on PHP7. It generally follows the approach of the
official WordPress Docker image and adds better defaults, WP-CLI, PHPUnit,
Composer, Xdebug, and the WordPress unit testing suite.

```
docker pull chriszarate/wordpress
```

Connect this image with a MySQL / MariaDB image or use my suggested
[Docker Compose](https://github.com/chriszarate/docker-wordpress-vip)
development setup.


## Environment variables

- `WORDPRESS_ACTIVATE_PLUGINS`: A space-separated list of plugin paths relative
  to `/var/www/html/wp-content/wp-content/plugins/` that should be activated
  when the container starts.

- `WORDPRESS_ACTIVATE_THEME` A theme path relative to `/var/www/html/wp-content/wp-content/themes/`
  that should be activated when the container starts.

- `WORDPRESS_CONFIG_EXTRA`: Additional PHP to append to `wp-config.php`.

- `WORDPRESS_DB_HOST`: Default "mysql".

- `WORDPRESS_DB_NAME`: Default "wordpress".

- `WORDPRESS_DB_USER`: Default "root".

- `WORDPRESS_DB_PASSWORD`: Default "wordpress".

- `WORDPRESS_SITE_USER`: Default "wordpress"

- `WORDPRESS_SITE_PASSWORD`: Default "wordpress"

- `WORDPRESS_SITE_EMAIL`: Default "admin@example.com"

- `WORDPRESS_SITE_TITLE`: Default "Project".

- `WORDPRESS_SITE_URL`: Default "http://project.dev/".


## WP-CLI

```sh
docker exec wordpress wp [command]
```


## Running tests (PHPUnit)

Set `PHPUNIT_TEST_DIR` to the path containing `phpunit.xml`.

```sh
docker exec wordpress tests
```

Other environment variables:

- `PHPUNIT_DB_HOST`: Default "localhost".

- `PHPUNIT_DB_NAME`: Default "wordpress_phpunit".

- `PHPUNIT_DB_USER`: Default "root".

- `PHPUNIT_DB_PASSWORD`: Default "".

- `PHPUNIT_WP_CONTENT_LINKS`: A space-separated list of paths, relative to
  `/var/www/html/wp-content/`, that should be symlinked into the WordPress unit
  test suite directory (`/tmp/wordpress/latest/`) so that they are available
  during testing. Provide the unit test suite directory using a Docker volume.


## Xdebug

Xdebug is installed but needs to be configured with an IDE key and the IP of
your local machine so that it can connect to your local debugging client.
Provide it via the `XDEBUG_CONFIG` environment variable, e.g.:

```
XDEBUG_CONFIG: "remote_host=x.x.x.x idekey=xdebug"
```

You can enable profiling by appending additional instructions, e.g.:

```
XDEBUG_CONFIG: "remote_host=x.x.x.x idekey=xdebug profiler_enable=1 profiler_output_name=%R.%t.out"
```

This will output cachegrind files (named after the request URI and timestamp) to
`/tmp` inside the WordPress container.
