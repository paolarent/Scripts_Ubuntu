#!/bin/bash

#Configurar la IP estática (SERVIDOR)
configurar_ip_estatica() {
    local ip="$1"
    local ARCHIVO_NETPLAN="/etc/netplan/50-cloud-init.yaml"
    local ADAPTADOR2="enp0s8"

sudo bash -c "cat > $ARCHIVO_NETPLAN" <<EOL
network:
version: 2
ethernets:
    enp0s3:
    dhcp4: true
    $ADAPTADOR2:
    dhcp4: no
    addresses:
        - $ip/24
    nameservers:
        addresses:
        - 8.8.8.8
        - 1.1.1.1
EOL

    echo "Configurando IP estática..."

    sudo netplan apply  #Confirmar cambios y aplicarlos
    echo "...CAMBIOS APLICADOS, IP ESTATICA CONFIGURADA..."
}