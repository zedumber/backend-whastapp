# Usamos una imagen oficial de PHP compatible con ARM
FROM php:8.2-cli-bullseye

# Establecemos el directorio de trabajo
WORKDIR /app

# Instalamos dependencias necesarias
RUN apt-get update && apt-get install -y \
    git unzip libzip-dev nano bash \
    && docker-php-ext-install zip sockets pdo pdo_mysql

# Instalamos Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copiamos los archivos de la aplicación
COPY . .

# Instalamos las dependencias de Laravel
RUN composer install --no-dev --optimize-autoloader

    # Instalamos Laravel Octane sin dependencias de desarrollo
RUN composer require laravel/octane \
&& php artisan octane:install --server=swoole


# Exponemos el puerto 8000
EXPOSE 8000

# Comando para iniciar Octane
CMD ["php", "artisan", "octane:start", "--server=swoole", "--host=0.0.0.0", "--port=8000"]
