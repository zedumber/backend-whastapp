# Usamos una imagen oficial de PHP compatible con ARM
FROM php:8.2-fpm-bullseye

# Establecemos el directorio de trabajo
WORKDIR /app

# Instalamos dependencias necesarias
RUN apt-get update && apt-get install -y \
    git unzip libzip-dev nano supervisor bash \
    && docker-php-ext-install zip sockets pdo pdo_mysql

# Instalamos Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copiamos los archivos de la aplicación
COPY . .

# Instalamos las dependencias de Laravel
RUN composer install --no-dev --optimize-autoloader

# Exponemos el puerto 9000 (PHP-FPM)
EXPOSE 9000

# Iniciar PHP-FPM
CMD ["php-fpm"]
