# Usamos una imagen oficial de PHP compatible con ARM
FROM php:8.2-fpm-bullseye

# Establecemos el directorio de trabajo
WORKDIR /app

# Instalamos git y otras dependencias necesarias
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    && docker-php-ext-install sockets zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_port=9003" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.idekey=VSCODE" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
    



# Instalamos Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copiamos el binario de Composer y RoadRunner
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
COPY --from=spiralscout/roadrunner:2.4.2 /usr/bin/rr /usr/bin/rr

# Copiamos el resto de los archivos de la aplicación
COPY . .

# Eliminamos los directorios y archivos que no necesitamos
RUN rm -rf /app/vendor
RUN rm -rf /app/composer.lock

# Instalamos los paquetes requeridos por Octane y RoadRunner
RUN composer clear-cache
RUN composer install --no-scripts --no-autoloader

RUN composer require laravel/octane:^1.0 spiral/roadrunner:^2.4 --with-all-dependencies

# Instalamos el paquete JWTAuth
RUN composer require tymon/jwt-auth

# Publicamos los archivos de configuración del paquete JWTAuth
RUN php artisan vendor:publish --provider="Tymon\JWTAuth\Providers\LaravelServiceProvider" --force

# Generamos la clave JWT
RUN php artisan jwt:secret

# Copiamos el archivo de entorno de ejemplo
COPY .env.example .env

# Creamos el directorio para los logs
RUN mkdir -p /app/storage/logs

# Instalar dependencias de Composer
#RUN composer require fruitcake/laravel-cors:^2.2 --with-all-dependencies

# Publicar la configuración de CORS
#RUN php artisan vendor:publish --provider="Fruitcake\Cors\CorsServiceProvider"

# Limpiar la cache de la aplicación
RUN php artisan cache:clear
RUN php artisan view:clear
RUN php artisan config:clear

# Generar la clave JWT (si es necesario)
RUN php artisan jwt:secret

# Instalamos e iniciamos Octane con el servidor Swoole
RUN php artisan octane:install --server="swoole"

# Copiamos el archivo de configuración de supervisord
COPY supervisord.conf /etc/supervisord.conf

# Exponemos el puerto 8000
EXPOSE 8010

# Instalamos supervisord
RUN apt-get update && apt-get install -y supervisor bash

# Copiamos el archivo de configuración de supervisord
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Configuramos el CMD para iniciar supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
