# Usamos una imagen oficial de PHP compatible con ARM
FROM php:8.2-fpm-bullseye

# Instalamos dependencias necesarias
RUN apt-get update && apt-get install -y \
    bash curl git libpng-dev libjpeg62-turbo-dev libfreetype6-dev zip libssl-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_mysql gd sockets

# Instalamos dependencias necesarias
RUN apt-get add --no-cache bash curl git libpng-dev libjpeg-turbo-dev freetype-dev zip openssl \
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

# Instalamos y configuramos JWTAuth
RUN composer require tymon/jwt-auth \
    && php artisan vendor:publish --provider="Tymon\JWTAuth\Providers\LaravelServiceProvider" --force \
    && php artisan jwt:secret

# Configuración de CORS
RUN php artisan vendor:publish --provider="Fruitcake\Cors\CorsServiceProvider"

# Limpiamos y cacheamos la configuración de la aplicación
RUN php artisan cache:clear && php artisan view:clear && php artisan config:cache

# Exponemos el puerto 9000
EXPOSE 8001

# Comando de inicio para PHP-FPM
CMD ["php-fpm"]
