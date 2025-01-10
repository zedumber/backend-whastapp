# CARGAMOS IMAGEN DE PHP MODO ALPINE SUPER REDUCIDA
FROM elrincondeisma/octane:latest

# Establecemos el directorio de trabajo
WORKDIR /app

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

# Instalamos las dependencias de la aplicación
RUN composer install --no-scripts --no-autoloader

# Instalamos el paquete JWTAuth
RUN composer require tymon/jwt-auth

# Publicamos los archivos de configuración del paquete JWTAuth
RUN php artisan vendor:publish --provider="Tymon\JWTAuth\Providers\LaravelServiceProvider" --force

# Generamos la clave JWT
RUN php artisan jwt:secret

# Instalamos los paquetes requeridos por Octane y RoadRunner
RUN composer require laravel/octane spiral/roadrunner --with-all-dependencies


# Copiamos el archivo de entorno de ejemplo
COPY .env.example .env

# Creamos el directorio para los logs
RUN mkdir -p /app/storage/logs

# Limpiamos la cache de la aplicación
RUN php artisan cache:clear
RUN php artisan view:clear
RUN php artisan config:clear
RUN php artisan jwt:secret


# Instalamos e iniciamos Octane con el servidor Swoole
RUN php artisan octane:install --server="swoole"

#CMD php artisan octane:start --server="swoole" --host="0.0.0.0"


# Exponemos el puerto 8000
EXPOSE 8001

# Configuramos el crontab
#COPY crontab /etc/crontabs/root

# Copiamos el archivo de configuración de supervisord
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

