#!/bin/bash

# Configuración SSH
USER=" "
HOST=" "
PORT=22
PASSWORD=" "

# Lista de carpetas a sincronizar (en el servidor remoto)
declare -a FOLDERS=(
    "/path/remoto/carpeta1"
    "/path/remoto/carpeta2"
    "/path/remoto/carpeta3"
)

# Carpeta local donde se sincronizarán las carpetas remotas
LOCAL_DIR="/path/local/dir"

# Comprobar si sshpass está instalado
if ! command -v sshpass &>/dev/null; then
    echo "sshpass no está instalado. Instalándolo..."
    sudo apt-get install sshpass -y
fi

# Ejecutar rsync para cada carpeta remota
for REMOTE_DIR in "${FOLDERS[@]}"; do
    sshpass -p "$PASSWORD" rsync -avz -e "ssh -p $PORT" "$USER@$HOST:$REMOTE_DIR" "$LOCAL_DIR"
done

echo "Sincronización completada."
