#!/bin/bash
echo "*********_CONFIGURAR DNS EN UBUNTU SERVER_************"

#Importar las funciones desde sus archivos
source ./Funciones/F_Pedir_IP.sh
source ./Funciones/F_Validar_IP.sh
source ./Funciones/F_Ped_Val_Dominio_DNS.sh
source ./Funciones/F_IP_Estatica.sh
source ./Funciones/F_Config_DNS.sh

#Pedir y validar la IP
pedir_IP

#Pedir y validar el dominio
pedir_dominio

#Configurar la IP estática
configurar_ip_estatica "$ip"

#Configurar DNS (Instalar bind9 y configurar los archivos de zona)
configuracion_DNS "$ip" "$dominio"
