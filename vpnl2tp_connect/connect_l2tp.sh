#!/bin/bash

# CONFIGURACIÓN
VPN_SERVER="X.X.X.X"            # IP del MikroTik
VPN_USER="usuario_vpn"
VPN_PASSWORD="clave_vpn"
VPN_PSK="clave_secreta"
VPN_NAME="vpnmikrotik"

# INSTALACIÓN DE PAQUETES
echo "[+] Instalando paquetes necesarios..."
sudo yum install -y libreswan xl2tpd ppp

# CONFIGURAR IPSEC
echo "[+] Configurando IPsec..."
cat > /etc/ipsec.conf <<EOF
config setup
    nat_traversal=yes
    protostack=netkey
    virtual_private=%v4:0.0.0.0/0
    oe=off

conn $VPN_NAME
    auto=add
    left=%defaultroute
    leftid=%defaultroute
    right=$VPN_SERVER
    rightid=$VPN_SERVER
    type=transport
    authby=secret
    pfs=no
    ike=aes256-sha1;modp1024
    phase2alg=aes256-sha1
    keyingtries=3
    ikelifetime=8h
    keylife=1h
    dpddelay=30
    dpdtimeout=120
    dpdaction=clear
EOF

# CONFIGURAR SECRETOS IPSEC
cat > /etc/ipsec.secrets <<EOF
%any $VPN_SERVER : PSK "$VPN_PSK"
EOF

chmod 600 /etc/ipsec.secrets

# CONFIGURAR XL2TPD
echo "[+] Configurando xl2tpd..."
cat > /etc/xl2tpd/xl2tpd.conf <<EOF
[global]
port = 1701

[lns default]
ip range = 192.168.99.10-192.168.99.20
local ip = 192.168.99.1
require chap = yes
refuse pap = yes
require authentication = yes
name = $VPN_NAME
ppp debug = yes
pppoptfile = /etc/ppp/options.l2tpd.client
length bit = yes
hostname = $VPN_NAME
lns = $VPN_SERVER
EOF

# CONFIGURAR PPP
cat > /etc/ppp/options.l2tpd.client <<EOF
ipcp-accept-local
ipcp-accept-remote
refuse-eap
require-chap
noccp
noauth
idle 1800
mtu 1410
mru 1410
nodefaultroute
debug
lock
connect-delay 5000
name $VPN_USER
password $VPN_PASSWORD
EOF

chmod 600 /etc/ppp/options.l2tpd.client

# ARRANCAR SERVICIOS
echo "[+] Iniciando servicios..."
systemctl restart ipsec
systemctl enable ipsec
systemctl restart xl2tpd
systemctl enable xl2tpd

# ESTABLECER IPSEC
echo "[+] Estableciendo IPsec..."
ipsec auto --add $VPN_NAME
ipsec auto --up $VPN_NAME

sleep 3

# ESTABLECER TÚNEL L2TP
echo "[+] Estableciendo túnel L2TP..."
echo "c $VPN_NAME" > /var/run/xl2tpd/l2tp-control

sleep 5

# AGREGAR RUTA POR VPN (opcional)
# echo "[+] Agregando ruta estática..."
# ip route add 10.0.0.0/24 dev ppp0

# CHEQUEAR CONEXIÓN
echo "[+] Conexión VPN establecida. Interfaces activas:"
ip a | grep ppp

