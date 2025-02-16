#!/bin/bash
echo "[-------------------_CONFIGURAR SERVIDOR DHCP EN UBUNTU SERVER_-------------------]"

IP=""
RANGO_IP_INICIO=""
RANGO_IP_FIN=""

#Función para validar la IP
validacion_ip_correcta()
{
    local IP="$1" #primer argumento para la funcion
    local regex_ipv4='^([0-9]{1,3}\.){3}[0-9]{1,3}$' #expresion para cuidar el formato de IPV4, 4 octetos, separados por ., de 1-3 digitos

    if [[ ! $IP =~ $regex_ipv4 ]]; then      #Comparacion de la ip ingresada con el formato
    echo "La IP ingresada no tiene el formato válido."    #Si es diferente, mensaje de error.
    return 1    #indicar fallo
    fi

    #Verificar cada octeto de la IP (valores entre 0 y 255)
    IFS='.' read -r -a octetos <<< "$IP"    #La IP se divide en un array llamado octetos usando el punto como separador.
    for octeto in "${octetos[@]}"; do       #Iteramos sobre cada octeto de la IP.
        if ! [[ "$octeto" =~ ^[0-9]+$ ]] || [ "$octeto" -lt 0 ] || [ "$octeto" -gt 255 ]; then
            echo "Error. La IP no es válida, los octetos deben estar entre 0 y 255."
            return 1
        fi
    done

    #Validar que no sean direcciones de red o broadcast
    IFS='.' read -r -a IP_array <<< "$IP"

    #Dirección de red si el último octeto es 0
    if [ "${IP_array[3]}" -eq 0 ]; then
        echo "Error. La IP $IP es una dirección de red y no es válida."
        return 1
    fi

    #Dirección de broadcast si el último octeto es 255
    if [ "${IP_array[3]}" -eq 255 ]; then
        echo "ERROR. La IP ingresada es una dirección de broadcast y no es válida."
        return 1
    fi

    return 0
}

validacion_rangos_ip() {
    local IP_INICIO="$1"
    local IP_FIN="$2"
    local IP_SERVIDOR="$3"
    
    #Validar formato IP de inicio
    validacion_ip_correcta "$IP_INICIO"
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    #Validar formato IP de fin
    validacion_ip_correcta "$IP_FIN"
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    #Convertir IPs a números para compararlas
    ip_to_num() {
        local ip="$1"
        local num=0
        IFS='.' read -r -a octetos <<< "$ip"
        for octeto in "${octetos[@]}"; do
            num=$((num * 256 + octeto))
        done
        echo "$num"
    }

    local NUM_IP_INICIO=$(ip_to_num "$IP_INICIO")
    local NUM_IP_FIN=$(ip_to_num "$IP_FIN")

    # Validar que la IP de inicio sea menor que la IP de fin
    if [ "$NUM_IP_INICIO" -ge "$NUM_IP_FIN" ]; then
        echo "La IP de inicio debe ser menor que la IP de fin."
        return 1
    fi
    
    #Obtener los primeros tres octetos de la IP del servidor
    IFS='.' read -r -a IP_SERVIDOR_ARRAY <<< "$IP_SERVIDOR"
    IFS='.' read -r -a IP_INICIO_ARRAY <<< "$IP_INICIO"
    IFS='.' read -r -a IP_FIN_ARRAY <<< "$IP_FIN"

    #Verificar que las IPs de inicio y fin estén dentro del mismo segmento de red
    if [[ "${IP_INICIO_ARRAY[0]}" != "${IP_SERVIDOR_ARRAY[0]}" || "${IP_INICIO_ARRAY[1]}" != "${IP_SERVIDOR_ARRAY[1]}" || "${IP_INICIO_ARRAY[2]}" != "${IP_SERVIDOR_ARRAY[2]}" ]]; then
        echo "Las IPs de inicio y fin no están en el mismo segmento de red que la IP del servidor."
        return 1
    fi
}    

obtener_subred_y_mascara() {
    local IP_INICIO="$1"
    local RESULT
    RESULT=$(ipcalc -n -m "$IP_INICIO/24")
    local SUBRED=$(echo "$RESULT" | awk '/Network/ {print $2}')
    local MASCARA=$(echo "$RESULT" | awk '/Netmask/ {print $2}')
    echo "$SUBRED $MASCARA"
}

#-----------------------------------------------------------------------------------------------------------------------
#Pedir la IP del servidor hasta que sea válida
while true; do
    read -p "Ingrese la IP del servidor DHCP: " IP
    validacion_ip_correcta "$IP"
    if [ $? -eq 0 ]; then
        break
    fi
done

#Solicitar las IPs de inicio y fin del rango
while true; do
    read -p "Ingrese la IP de inicio del rango DHCP: " RANGO_IP_INICIO
    read -p "Ingrese la IP de fin del rango DHCP: " RANGO_IP_FIN
    
    #Llamamos a la función de validación de rangos
    validacion_rangos_ip "$RANGO_IP_INICIO" "$RANGO_IP_FIN" "$IP"
    
    #Si todo sale bien, salimos del bucle
    if [ $? -eq 0 ]; then
        break
    fi
done

#Obtener los primeros tres octetos de la IP
read SUBRED MASCARA <<< "$(obtener_subred_y_mascara "$RANGO_IP_INICIO")"

#Configurar la IP estática
ARCHIVO_NETPLAN="/etc/netplan/50-cloud-init.yaml"
ADAPTADOR2="enp0s8"  #Adaptador de red 2 (RED INTERNA)
sudo bash -c "cat > $ARCHIVO_NETPLAN" <<EOL
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true
    $ADAPTADOR2:
      dhcp4: no
      addresses:
        - $IP/24
      nameservers:
        addresses:
          - 8.8.8.8
          - 1.1.1.1
EOL

echo "Configurando IP estática..."

sudo netplan apply  #Confirmar cambios y aplicarlos
echo "Aplicando cambios..."

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
subnet $SUBRED netmask $MASCARA {
range $RANGO_IP_INICIO $RANGO_IP_FIN;
default-lease-time 3600;
max-lease-time 86400;
option routers ${SUBRED%.*}.1;
option domain-name-servers 8.8.8.8;
}

EOL
echo "*** Configurando archivo dhcpd.conf ***"

#REINICIAR EL SERVICIO DHCP Y CHECAR SU STATUS
sudo service isc-dhcp-server restart
sudo service isc-dhcp-server status

echo "CONFIGURACION FINALIZADA EXITOSAMENTE :)"
#CHECAR LOS LEASES (las ip que ya asigno)
#cat /var/lib/dhcp/dhcpd.leases