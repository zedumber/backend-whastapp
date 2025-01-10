# Usamos una imagen oficial de PHP compatible con ARM
FROM php:8.2-fpm-alpine

# Instalamos dependencias necesarias, incluyendo supervisord y sockets
RUN apk add --no-cache bash curl git libpng-dev libjpeg-turbo-dev freetype-dev zip supervisor openssl \
    && docker-php-ext-install pdo pdo_mysql gd sockets

# Establecemos el directorio de trabajo
WORKDIR /var/www/html

# Instalamos Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copiamos los archivos de la aplicación
COPY . .

# Instalamos las dependencias de Composer
RUN composer install --optimize-autoloader --no-dev

# Cambiamos los permisos para que el servidor pueda escribir en el almacenamiento
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Instalamos el paquete JWTAuth
RUN composer require tymon/jwt-auth

# Publicamos los archivos de configuración del paquete JWTAuth
RUN php artisan vendor:publish --provider="Tymon\JWTAuth\Providers\LaravelServiceProvider" --force

# Generamos la clave JWT
RUN php artisan jwt:secret

# Publicamos la configuración de CORS
RUN php artisan vendor:publish --provider="Fruitcake\Cors\CorsServiceProvider"

# Limpiamos y cacheamos la configuración de la aplicación
RUN php artisan cache:clear && php artisan view:clear && php artisan config:cache

# Exponemos el puerto 8001
EXPOSE 8001

# Copiamos la configuración de supervisord
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Comando por defecto para iniciar supervisord
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
