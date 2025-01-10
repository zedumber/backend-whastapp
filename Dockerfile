# Usamos una imagen oficial de PHP compatible con ARM
FROM php:8.2-fpm-alpine

# Instalamos dependencias necesarias, incluyendo supervisord
RUN apk add --no-cache bash curl git libpng-dev libjpeg-turbo-dev freetype-dev zip supervisor openssl

# Establecemos el directorio de trabajo
WORKDIR /app

# Instalamos Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copiamos los archivos de la aplicación
COPY . /app

# Instalamos las dependencias de Composer
RUN composer install --optimize-autoloader --no-dev

# Instalamos el paquete JWTAuth
RUN composer require tymon/jwt-auth

# Publicamos los archivos de configuración del paquete JWTAuth
RUN php artisan vendor:publish --provider="Tymon\JWTAuth\Providers\LaravelServiceProvider" --force

# Generamos la clave JWT
RUN php artisan jwt:secret

# Instalamos Octane y RoadRunner
RUN composer require laravel/octane spiral/roadrunner --with-all-dependencies
RUN composer clear-cache
RUN composer install --no-scripts --no-autoloader
RUN composer require laravel/octane:^1.0 spiral

# Descarga manual del binario de RoadRunner para ARM
RUN curl -L -o rr.tar.gz https://github.com/roadrunner-server/roadrunner/releases/download/v2024.1.1/roadrunner-2024.1.1-linux-arm64.tar.gz \
    && tar -xvzf rr.tar.gz \
    && mv roadrunner-2024.1.1-linux-arm64/rr /app/vendor/bin/rr \
    && chmod +x /app/vendor/bin/rr \
    && rm -rf roadrunner-2024.1.1-linux-arm64 rr.tar.gz

# Copiamos el archivo .env
COPY .env.example .env

# Creamos el directorio para los logs
RUN mkdir -p /app/storage/logs

# Limpiamos la cache de la aplicación
RUN php artisan cache:clear
RUN php artisan view:clear
RUN php artisan config:clear

# Copiamos el script de entrada
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Configuramos el servidor manualmente
RUN echo "OCTANE_SERVER=roadrunner" >> .env

# Cacheamos la configuración
RUN php artisan config:cache

# Exponemos el puerto 8001
EXPOSE 8001

# Publicar la configuración de CORS
RUN php artisan vendor:publish --provider="Fruitcake\Cors\CorsServiceProvider"
RUN php artisan cache:clear
RUN php artisan view:clear
RUN php artisan config:clear

# Configuramos supervisord para administrar RoadRunner
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Cambiamos el entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Comando por defecto
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
