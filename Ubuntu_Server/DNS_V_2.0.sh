#!/bin/bash
echo "*********_CONFIGURAR DNS EN UBUNTU SERVER_************"

#Importar las funciones desde sus archivos
source ./F_Perdir_IP.sh
source ./F_Validar_IP.sh
source ./F_Ped_Val_Dominio_DNS.sh
source ./F_IP_Estatica.sh
source ./F_Config_DNS.sh

#Pedir y validar la IP
pedir_IP

#Pedir y validar el dominio
pedir_dominio

#Configurar la IP estática
configurar_ip_estatica "$ip"

#Configurar DNS (Instalar bind9 y configurar los archivos de zona)
configuracion_DNS "$ip" "$dominio"
