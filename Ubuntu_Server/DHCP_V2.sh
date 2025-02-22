#!/bin/bash
echo "[-------------------_CONFIGURAR SERVIDOR DHCP EN UBUNTU SERVER_-------------------]"

#Importar las funciones desde sus archivos
source ./Funciones/F_Pedir_IP.sh
source ./Funciones/F_Validar_IP.sh
source ./Funciones/F_PV_Rangos_DHCP.sh
source ./Funciones/F_IP_Estatica.sh
source ./Funciones/F_Config_DHCP.sh

#Pedir y validar la IP
ip=$(pedir_IP)

#Pedir y validar el rango DHCP (inicio y fin)
read RANGO_IP_INICIO RANGO_IP_FIN < <(pedir_rangos "$ip")

#Configurar la IP estática
configurar_ip_estatica "$ip"

#INSTALAR y CONFIGURAR EL SERVICIO DHCP
configurar_DHCP "$ip" "$RANGO_IP_INICIO" "$RANGO_IP_FIN"