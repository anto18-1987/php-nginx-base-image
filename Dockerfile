FROM php:7.4-fpm-alpine

ENV COMPOSER_ALLOW_SUPERUSER=1

RUN apk add --no-cache \
		acl \
		shadow \
		nginx   \
		supervisor \
		curl \
		gzip \
		bash \
	;

RUN set -ex \
  	&& apk update \
    && apk add --no-cache libsodium \
    && apk add --no-cache --virtual build-dependencies g++ make autoconf libsodium-dev\
    && docker-php-source extract \
    && docker-php-ext-enable sodium \
    && docker-php-source delete \
    && cd  / && rm -fr /src \
    && apk del build-dependencies \
    && rm -rf /tmp/*

ARG APCU_VERSION=5.1.22
RUN set -eux; \
	apk add --no-cache --virtual .build-deps \
		$PHPIZE_DEPS \
		icu-dev \
		libzip-dev \
		zlib-dev \
	; \
	\
	docker-php-ext-configure zip; \
	docker-php-ext-install -j "$(getconf _NPROCESSORS_ONLN)" \
		intl \
		pdo \
		pdo_mysql \
		mysqli \
		zip \
	; \
	pecl install \
		apcu-${APCU_VERSION} \
	; \
	pecl clear-cache; \
	docker-php-ext-enable \
		apcu \
		opcache \
	; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-cache --virtual .api-phpexts-rundeps $runDeps; \
	\
	apk del .build-deps

COPY config/php/php.ini /usr/local/etc/php/php.ini


COPY config/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY config/supervisor.d/supervisor.ini /etc/supervisor.d/supervisor.ini

RUN chmod 644 /etc/supervisord.conf && touch /var/log/supervisord.log

RUN mkdir -p /run/nginx/ \
    && chmod 777 /var/log/supervisord.log

RUN usermod -u 1000 www-data

WORKDIR /var/www/

COPY config/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

ENTRYPOINT ["docker-entrypoint"]


CMD ["/usr/bin/supervisord", "--nodaemon", "--configuration", "/etc/supervisord.conf"]
