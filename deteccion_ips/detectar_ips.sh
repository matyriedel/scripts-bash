#!/bin/bash

# Puerto a monitorear
PUERTO=23002
# Tamaño máximo de paquetes
TAM_MAX=100
# Archivo temporal de IPs detectadas
IP_LOG="/tmp/ip_detectadas.txt"

# Obtener interfaz desde el argumento, o preguntar si no se pasó
INTERFAZ="$1"
if [[ -z "$INTERFAZ" ]]; then
    read -p "🔧 Ingresá el nombre de la interfaz de red (ej: eth0, ens3, enp0s3): " INTERFAZ
fi

# Validar si la interfaz existe
if ! ip link show "$INTERFAZ" &>/dev/null; then
    echo "❌ Interfaz '$INTERFAZ' no existe. Abortando."
    exit 1
fi

# Limpiar archivo de IPs
> "$IP_LOG"

echo "📡 Escuchando en interfaz '$INTERFAZ', puerto UDP $PUERTO (paquetes <= $TAM_MAX bytes)..."
echo "Mostrando IPs únicas y su información WHOIS:"
echo

# Ejecutar tcpdump y procesar en tiempo real
sudo tcpdump -nn -l -i "$INTERFAZ" "udp and dst port $PUERTO and len <= $TAM_MAX" 2>/dev/null | \
while read -r line; do
    # Extraer IP de origen correctamente
    IP=$(echo "$line" | grep -oP '^\d{2}:\d{2}:\d{2}\.\d{6} IP \K[0-9.]+(?=\.\d+ >)')

    if [[ $IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        if ! grep -q "$IP" "$IP_LOG"; then
            echo "🔹 IP detectada: $IP"
            echo "$IP" >> "$IP_LOG"

            if command -v whois &> /dev/null; then
                echo "🌐 WHOIS info:"
                whois "$IP" | grep -E 'OrgName|org-name|country|CIDR|NetName|inetnum' | sed 's/^/   /'
            else
                echo "⚠️ whois no está instalado. Ejecutá: sudo apt install whois"
            fi
            echo "--------------------------------------------"
        fi
    fi
done
