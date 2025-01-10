# Usamos una imagen oficial de PHP compatible con ARM
FROM php:8.2-fpm-alpine



# Instalamos dependencias necesarias, incluyendo supervisord
RUN apk add --no-cache bash curl git libpng-dev libjpeg-turbo-dev freetype-dev zip supervisor

# Establecemos el directorio de trabajo
WORKDIR /app

# Instalamos Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Instalamos las dependencias de la aplicación
COPY . /app

# Instalamos las dependencias de Composer
RUN composer install --no-scripts --no-autoloader

RUN apk add --no-cache php8.2-pcntl


# Instalamos el paquete JWTAuth
RUN composer require tymon/jwt-auth

# Publicamos los archivos de configuración del paquete JWTAuth
RUN php artisan vendor:publish --provider="Tymon\JWTAuth\Providers\LaravelServiceProvider" --force

# Generamos la clave JWT
RUN php artisan jwt:secret

# Instalamos Octane y RoadRunner
RUN composer require laravel/octane spiral/roadrunner --with-all-dependencies

# Copiamos el archivo .env
COPY .env.example .env

# Creamos el directorio para los logs
RUN mkdir -p /app/storage/logs

# Limpiamos la cache de la aplicación
RUN php artisan cache:clear
RUN php artisan view:clear
RUN php artisan config:clear

# Instalamos e iniciamos Octane con el servidor Swoole
RUN php artisan octane:install --server="swoole"

# Exponemos el puerto 8000
EXPOSE 8001

# Configuramos supervisord (si usas supervisor para administrar procesos)
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Comando por defecto (si usas supervisord)
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
