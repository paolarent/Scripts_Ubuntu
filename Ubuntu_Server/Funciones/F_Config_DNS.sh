#!/bin/bash

#CONFIGURACION DNS
configuracion_DNS() {
    #INSTALAR BIND9 con sus herramientas y archivos
    sudo apt update    #actualizar paquetes
    sudo apt-get install -y bind9 bind9utils bind9-doc
    echo "Instalando BIND9..."

    #CONFIGURACION DE BIND9
    ARCHIVO_NCO="/etc/bind/named.conf.options"
sudo bash -c "cat > $ARCHIVO_NCO" <<EOL
options {
    directory "/var/cache/bind";

    forwarders {
        8.8.8.8;
    };

    dnssec-validation auto;

    listen-on-v6 { any; };
};
EOL
    echo "Configurando BIND9..."

    #CONFIGURACIÓN DE LA ZONA DIRECTA
    ARCHIVO_ZONA="/etc/bind/db.$dominio"
sudo bash -c "cat > $ARCHIVO_ZONA" <<EOL
;
; Archivo de zona directa para el dominio
;
\$TTL 604800
@     IN  SOA     $dominio. root.$dominio. (
                        2     ; Serial
                    604800     ; Refresh
                    86400     ; Retry
                2419200     ; Expire
                    604800 )   ; Negative Cache TTL
;
@     IN  NS      $dominio.
@     IN  A       $ip
www   IN  CNAME   $dominio.
EOL
    echo "Configurando la zona directa..."

    #CONFIGURACION LOCAL (named.conf.local)
    ARCHIVO_CONF_LOCAL="/etc/bind/named.conf.local"
    PRIMEROS_3_OCTETOS=$(echo $ip | cut -d'.' -f1-3 | awk -F. '{print $3"."$2"."$1}')
sudo bash -c "cat > $ARCHIVO_CONF_LOCAL" <<EOL
zone "$dominio" {
    type master;
    file "$ARCHIVO_ZONA";
};

zone "$PRIMEROS_3_OCTETOS.in-addr.arpa" {
    type master;
    file "/etc/bind/db.$PRIMEROS_3_OCTETOS";
};
EOL
    echo "Configurando la zona local..."

    ARCHIVO_3OCT_IP_INVERSA="/etc/bind/db.$PRIMEROS_3_OCTETOS"
    ultoct=$(echo $ip | awk -F. '{print $4}')
sudo bash -c "cat > $ARCHIVO_3OCT_IP_INVERSA" <<EOL
;
;   BIND REVERSE DATA FILE FOR LOCAL LOOPBACK INTERFACE
;
\$TTL   604800
@       IN          SOA         $dominio. root.$dominio. (
                                    1    ; Serial
                                604800    ; Refresh
                                86400    ; Retry
                            2419200    ; Expire
                                604800 )  ; Negative Cache TTL
;
@       IN          NS          $dominio.
$ultoct IN          PTR         $dominio.
EOL
    echo "Configurando la zona inversa..."

    #Agregar configuraciones a /etc/resolv.conf de manera segura
    sudo sed -i "/^search /c\search $dominio" /etc/resolv.conf 
    sudo sed -i "/^nameserver /c\nameserver $ip" /etc/resolv.conf 
    echo "domain $dominio" | sudo tee -a /etc/resolv.conf > /dev/null
    echo "options edns0 trust-ad" | sudo tee -a /etc/resolv.conf > /dev/null
    echo "Actualizando archivo resolv.conf"

    #REINICIAR BIND9 para aplicar cambios
    sudo service bind9 restart
    echo "REINICIANDO SERVICIO BIND9"
    #COMPROBAR STATUS de bind9
    sudo service bind9 status

    echo "CONFIGURACIÓN COMPLETADA. :)"

}