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

# Verificamos que el binario de RR existe y lo descargamos
RUN if [ -f vendor/bin/rr ]; then vendor/bin/rr get; else echo "RoadRunner binario no encontrado"; fi


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

# Creamos el archivo .rr.yaml en la raíz del proyecto
#RUN echo "http:\n  address: 0.0.0.0:8001" > /app/.rr.yaml

# Configuramos el servidor manualmente
RUN echo "OCTANE_SERVER=roadrunner" >> .env

# Cacheamos la configuración
RUN php artisan config:cache

# Exponemos el puerto 8001
EXPOSE 8001

# Configuramos supervisord para administrar RoadRunner
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
# Cambiamos el entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Comando por defecto
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
