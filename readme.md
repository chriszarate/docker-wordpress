# WordPress on Docker

This image extends the official WordPress Docker image, adding better defaults,
WP-CLI, PHPUnit, Composer, and the WordPress unit testing suite.

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

Set `PHPUNIT_TEST_DIR` to the path containing `phpunit.xml`. A configured
WordPress test suite is available in `/tmp/wordpress/latest/`.

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
  test suite directory so that they are available during testing.


## Xdebug

Xdebug is installed but needs the IP of your local machine to connect to your
local debugging client. Provide it via the `DOCKER_LOCAL_IP` environment
variable. The default `idekey` is `xdebug`.

You can enable profiling by appending instructions to `XDEBUG_CONFIG` in
`docker-compose.yml`, e.g.:

```
XDEBUG_CONFIG: "remote_host=${DOCKER_LOCAL_IP} idekey=xdebug profiler_enable=1 profiler_output_name=%R.%t.out"
```

This will output cachegrind files (named after the request URI and timestamp) to
`/tmp` inside the WordPress container.
