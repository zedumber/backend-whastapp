# Usamos una imagen oficial de PHP compatible con ARM
FROM php:8.2-fpm-bullseye

# Establecemos el directorio de trabajo
WORKDIR /app

# Instalamos git, dependencias necesarias, y otras herramientas
RUN apt-get update && apt-get install -y \
    git \
    libssl-dev \
    libpcre3-dev \
    unzip \
    libzip-dev \
    curl \
    supervisor \
    procps \
    nano \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Instalamos Xdebug
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_port=9003" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.idekey=VSCODE" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Instalamos Swoole
RUN pecl install swoole \
    && docker-php-ext-enable swoole

# Instalamos Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Instalamos RoadRunner
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
COPY --from=spiralscout/roadrunner:2.4.2 /usr/bin/rr /usr/bin/rr

# Copiamos el resto de los archivos de la aplicación
COPY . .

# Eliminamos los directorios y archivos que no necesitamos
RUN rm -rf /app/vendor && rm -rf /app/composer.lock

# Instalamos los paquetes requeridos por Octane y RoadRunner
RUN composer clear-cache \
    && composer install --no-scripts --no-autoloader \
    && composer require laravel/octane:^1.0 spiral/roadrunner:^2.4 --with-all-dependencies \
    && composer require tymon/jwt-auth

# Publicamos los archivos de configuración de JWTAuth
RUN php artisan vendor:publish --provider="Tymon\JWTAuth\Providers\LaravelServiceProvider" --force

# Generamos la clave JWT
RUN php artisan jwt:secret

# Copiamos el archivo de entorno de ejemplo
COPY .env.example .env

# Creamos el directorio para los logs
RUN mkdir -p /app/storage/logs

# Limpiar la cache de la aplicación
RUN php artisan cache:clear \
    && php artisan view:clear \
    && php artisan config:clear

# Instalamos e iniciamos Octane con el servidor Swoole
RUN php artisan octane:install --server="swoole"

# Configuramos supervisord para iniciar Octane
COPY supervisord.conf /etc/supervisord.conf

# Exponemos el puerto 8000
EXPOSE 8000

# Instalamos supervisord
RUN apt-get update && apt-get install -y supervisor

# Crear el directorio antes de mover el archivo de RoadRunner
RUN mkdir -p /var/www/html/vendor/bin/ \
    && curl -L -o rr.tar.gz https://github.com/roadrunner-server/roadrunner/releases/download/v2024.1.1/roadrunner-2024.1.1-linux-arm64.tar.gz \
    && tar -xvzf rr.tar.gz \
    && mv roadrunner-2024.1.1-linux-arm64/rr /var/www/html/vendor/bin/rr \
    && chmod +x /var/www/html/vendor/bin/rr \
    && rm -rf roadrunner-2024.1.1-linux-arm64 rr.tar.gz

# Configuramos el CMD para iniciar Octane
CMD ["php", "artisan", "octane:start", "--server=swoole", "--host=0.0.0.0", "--port=8000"]
