# WordPress development on Docker [DEPRECATED]

**NOTE:** This image is no longer updated. Unless you need Xdebug, I recommend
that you work instead from the official WordPress images, as shown in my
[Docker Compose WordPress development][development] repo.

---

## Environment variables

- `WORDPRESS_ACTIVATE_PLUGINS`: A space-separated list of plugin paths relative
  to `/var/www/html/wp-content/plugins/` that should be activated when the
  container starts. If a plugin cannot be found, an install will be attempted
  via `wp plugin install`.

- `WORDPRESS_ACTIVATE_THEME` A theme path relative to `/var/www/html/wp-content/themes/`
  that should be activated when the container starts. If the theme cannot be
  found, an install will be attempted via `wp theme install`.

- `WORDPRESS_CONFIG_EXTRA`: Additional PHP to append to `wp-config.php`.

- `WORDPRESS_DB_HOST`: Default "mysql".

- `WORDPRESS_DB_NAME`: Default "wordpress".

- `WORDPRESS_DB_USER`: Default "root".

- `WORDPRESS_DB_PASSWORD`: Default "".

- `WORDPRESS_INSTALL_TYPE`: Default "single" (use "multisite" for Multisite install).

- `WORDPRESS_PERMALINK_STRUCTURE`: Default "/%year%/%monthnum%/%postname%/"

- `WORDPRESS_SITE_USER`: Default "wordpress"

- `WORDPRESS_SITE_PASSWORD`: Default "wordpress"

- `WORDPRESS_SITE_EMAIL`: Default "admin@example.com"

- `WORDPRESS_SITE_TITLE`: Default "Project".

- `WORDPRESS_SITE_URL`: Default "http://project.dev".


## WP-CLI

Assuming you are running in the context of Docker Compose:

```sh
docker-compose exec --user www-data wordpress wp [command]
```


## Running tests (PHPUnit)

Previous versions of this image provided PHPUnit inside the container. However,
bundling a single version of PHPUnit was not very flexible. Additionally, users
did not have the opportunity to install their own test dependencies. I now
provide a(n optional) separate PHPUnit WordPress container that provides much
greater flexibility and isolation. Please see the README of my
[Docker Compose WordPress development][development] repo for instructions on how
to set this up.


## Xdebug

Xdebug is installed but needs the IP of your local machine to connect to your
local debugging client. Edit `.env` and populate the `DOCKER_LOCAL_IP`
environment variable with your machine's (local network) IP address. The default
`idekey` is `xdebug`.

```
XDEBUG_CONFIG: "remote_host=x.x.x.x idekey=xdebug"
```

You can enable profiling by appending additional instructions, e.g.:

```
XDEBUG_CONFIG: "remote_host=x.x.x.x idekey=xdebug profiler_enable=1 profiler_output_name=%R.%t.out"
```

This will output cachegrind files (named after the request URI and timestamp) to
`/tmp` inside the WordPress container.


## Seed `wp-content`

You can seed `wp-content` with files (e.g., an uploads folder) by mounting a
volume at `/tmp/wordpress/init-wp-content`. Everything in that folder will be
copied to your installation's `wp-content` folder.


## Provide trusted root certificates

Mount a folder of trusted root certificates to `/tmp/certs`. Any files in that
folder with a `.crt` extension will be added to the trusted certificate store.


[development]: https://github.com/chriszarate/docker-compose-wordpress
