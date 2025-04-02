#!/bin/bash

# GRE Tunnel Config Script
# -------------------------
# Uso: ./setup_gre.sh
# Personalizá las variables de abajo si es necesario

### Configuración
LOCAL_IP="IP"
REMOTE_IP="IP"
GRE_INTERFACE="gre-gg"
GRE_IP_LOCAL="10.x.x.x"
GRE_IP_REMOTE="10.x.x.x"
GRE_NETMASK="/30"
OUT_IF="eth0"

### Crear túnel GRE
echo "[+] Creando interfaz GRE..."
ip tunnel add $GRE_INTERFACE mode gre remote $REMOTE_IP local $LOCAL_IP dev $OUT_IF

### Asignar IP y activar interfaz
echo "[+] Asignando IP $GRE_IP_LOCAL$GRE_NETMASK a $GRE_INTERFACE..."
ip addr add $GRE_IP_LOCAL$GRE_NETMASK dev $GRE_INTERFACE
ip link set $GRE_INTERFACE up

### Habilitar forwarding
echo "[+] Activando IP forwarding..."
sysctl -w net.ipv4.ip_forward=1

### Reglas iptables
echo "[+] Configurando reglas iptables..."

# Forwarding
iptables -A FORWARD -i $OUT_IF -o $GRE_INTERFACE -j ACCEPT
iptables -A FORWARD -i $GRE_INTERFACE -o $OUT_IF -j ACCEPT

# NAT
iptables -t nat -A POSTROUTING -s $REMOTE_IP -o $OUT_IF -j MASQUERADE
iptables -t nat -A POSTROUTING -o $OUT_IF -j MASQUERADE

# DNAT (TCP)
for PORT in 2300 2303 23002; do
    iptables -t nat -A PREROUTING -i $OUT_IF -p tcp --dport $PORT -j DNAT --to-destination $GRE_IP_REMOTE:$PORT
done

# DNAT (UDP)
for PORT in 2300 2303 23002; do
    iptables -t nat -A PREROUTING -i $OUT_IF -p udp --dport $PORT -j DNAT --to-destination $GRE_IP_REMOTE:$PORT
done

### Mostrar estado
echo -e "\n[+] Estado del túnel GRE:"
ip tunnel show $GRE_INTERFACE
ip addr show $GRE_INTERFACE

echo -e "\n[+] Reglas iptables relevantes:"
iptables -L -v -n | grep $GRE_INTERFACE
iptables -t nat -L -v -n | grep $GRE_IP_REMOTE

echo -e "\n[✓] Túnel GRE configurado exitosamente."