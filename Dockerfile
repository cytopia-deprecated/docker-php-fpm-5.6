##
## PHP-FPM 5.6
##
FROM centos:7
MAINTAINER "cytopia" <cytopia@everythingcli.org>


##
## Bootstrap Scipts
##
COPY ./scripts/docker-install.sh /
COPY ./scripts/docker-entrypoint.sh /


##
## Install
##
RUN /docker-install.sh


##
## Ports
##
EXPOSE 9000


##
## Volumes
##
VOLUME /var/log/php-fpm


##
## Entrypoint
##
ENTRYPOINT ["/docker-entrypoint.sh"]
