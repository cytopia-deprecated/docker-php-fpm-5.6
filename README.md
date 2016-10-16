# PHP-FPM 5.6 Docker

[![](https://images.microbadger.com/badges/version/cytopia/php-fpm-5.6.svg)](https://microbadger.com/images/cytopia/php-fpm-5.6 "php-fpm-5.6") [![](https://images.microbadger.com/badges/image/cytopia/php-fpm-5.6.svg)](https://microbadger.com/images/cytopia/php-fpm-5.6 "php-fpm-5.6") [![](https://images.microbadger.com/badges/license/cytopia/php-fpm-5.6.svg)](https://microbadger.com/images/cytopia/php-fpm-5.6 "php-fpm-5.6")

[![cytopia/php-fpm-5.6](http://dockeri.co/image/cytopia/php-fpm-5.6)](https://hub.docker.com/r/cytopia/php-fpm-5.6/)

**[php-fpm 5.4](https://github.com/cytopia/docker-php-fpm-5.4) | [php-fpm 5.5](https://github.com/cytopia/docker-php-fpm-5.5) | php-fpm 5.6 | [php-fpm 7.0](https://github.com/cytopia/docker-php-fpm-7.0) | [php-fpm 7.1](https://github.com/cytopia/docker-php-fpm-7.1)**

----

PHP-FPM 5.6 Docker on CentOS 7

This docker image is part of the **[devilbox](https://github.com/cytopia/devilbox)**

----

## Usage

Simple usage
```shell
$ docker run -i -t cytopia/php-fpm-5.6
```

Add php config directory to overwrite php.ini directives during startup.
```shell
$ docker run -i -v ~/.etc/php.d:/etc/php-custom.d -t cytopia/php-fpm-5.6
```


## Options


### Environmental variables

#### Required environmental variables

- None

#### Optional environmental variables

| Variable | Type | Description |
|----------|------|-------------|
| DEBUG_COMPOSE_ENTRYPOINT | bool | Show shell commands executed during start.<br/>Value: `0` or `1` |
| TIMEZONE | string | Set docker OS timezone as well as PHP timezone.<br/>(Example: `Europe/Berlin`) |
| FORWARD_MYSQL_PORT_TO_LOCALHOST | bool | Forward a remote MySQL server port to listen on this docker on `127.0.0.1`<br/>Value: `0` or `1` |
| MYSQL_REMOTE_ADDR | string | The remote IP address of the MySQL host from which to port-forward |
| MYSQL_REMOTE_PORT | int | The remote port of the MySQL host from which to port-forward |
| MYSQL_LOCAL_PORT | int | Forward the MySQL port to `127.0.0.1` to the specified local port |
| MOUNT_MYSQL_SOCKET_TO_LOCALDISK | bool | Mount a remote MySQL server socket to local disk on this docker.<br/>Value: `0` or `1` |
| MYSQL_SOCKET_PATH | string | Full socket path where the MySQL socket has been mounted on this docker. |
| PHP_XDEBUG_ENABLE | bool | Enable Xdebug.<br/>Value: `0` or `1` |
| PHP_XDEBUG_REMOTE_PORT | int | The port on your Host (where you run the IDE/editor to which xdebug should connect.) |
| PHP_XDEBUG_REMOTE_HOST | string | The IP address of your Host (where you run the IDE/editor to which xdebug should connect). |

### Default mount points

| Docker | Description |
|--------|-------------|
| /var/log/php-fpm | PHP-FPM log dir |
| /etc/php-custom.d | Custom user configuration files. Make sure to mount this folder to your host, where you have custom `*.ini` files. These files will then be copied to `/etc/php.d` during startup. |

### Default ports

| Docker | Description |
|--------|-------------|
| 9000   | PHP-FPM listening Port |
