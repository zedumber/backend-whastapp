#!/bin/sh

# Instalamos RoadRunner si no está disponible
if [ ! -f vendor/bin/rr ]; then
    echo "RoadRunner no encontrado. Instalando..."
    composer install --optimize-autoloader --no-dev
    vendor/bin/rr get
fi

# Ejecutamos supervisord
exec "$@"
