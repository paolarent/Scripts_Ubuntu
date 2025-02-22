#!/bin/bash

#CONFIGURAR EL SERVICIO DHCP
configurar_DHCP() {
    local ip="$1"
    local RANGO_IP_INICIO="$2"
    local RANGO_IP_FIN="$3"
    local ADAPTADOR2="enp0s8"

    #Obtener los primeros tres octetos de la IP
    PRIMEROS_TRES_OCTETOS=$(echo $ip | cut -d'.' -f1-3)
    #INSTALAR EL SERVICIO DHCP
    sudo apt install -y isc-dhcp-server
    echo "INSTALANDO SERVICIO DHCP..."

    #CONFIGURAR interfaz a la que queremos se aplique la configuracion
    #Reemplazamos la línea de INTERFACESv4 con el nombre del adaptador de red interna
    sudo sed -i "s/^INTERFACESv4=.*/INTERFACESv4=\"$ADAPTADOR2\"/" /etc/default/isc-dhcp-server
    echo "*** Actualizando archivo /etc/default/isc-dhcp-server ***"

    #CONFIGURAR ARCHIVO /etc/dhcp/dhcpd.conf
    ARCHIVO_DHCPD="/etc/dhcp/dhcpd.conf"
sudo bash -c "cat > $ARCHIVO_DHCPD" <<EOL
#Archivo de configuración del servidor DHCP
default-lease-time 600;
max-lease-time 7200;
ddns-update-style none;

#CONFIGURACION DHCP RED INTERNA
subnet $PRIMEROS_TRES_OCTETOS.0 netmask 255.255.255.0 {
range $RANGO_IP_INICIO $RANGO_IP_FIN;
default-lease-time 3600;
max-lease-time 86400;
option routers $PRIMEROS_TRES_OCTETOS.1;
option domain-name-servers 8.8.8.8;
}
EOL
    echo "*** Configurando archivo dhcpd.conf ***"

    #REINICIAR EL SERVICIO DHCP Y CHECAR SU STATUS
    sudo service isc-dhcp-server restart
    sudo service isc-dhcp-server status

    echo "CONFIGURACION FINALIZADA EXITOSAMENTE :)"
}