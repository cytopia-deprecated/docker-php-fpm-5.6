FROM centos:7
MAINTAINER "cytopia" <cytopia@everythingcli.org>

# Copy scripts
COPY ./scripts/docker-install.sh /
COPY ./scripts/docker-entrypoint.sh /

# Install
RUN /docker-install.sh


##
## Become apache in order to have mounted files
## with apache user rights
##
#User apache

# Autostart
ENTRYPOINT ["/docker-entrypoint.sh"]



##
## Volumes
##
VOLUME /var/log/php-fpm


##
## Entrypoint
##
ENTRYPOINT ["/docker-entrypoint.sh"]


##
## Ports
##
# xdebug
EXPOSE 9000
# php-fpm
EXPOSE 9001


##
## Start
##
#CMD ["/usr/sbin/php-fpm -F"]