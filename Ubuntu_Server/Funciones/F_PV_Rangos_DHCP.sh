#!/bin/bash

pedir_rangos(){
    local ip_servidor="$1"
    local RANGO_IP_INICIO=""
    local RANGO_IP_FIN=""
    #Solicitar las IPs de inicio y fin del rango
    while true; do
        read -p "Ingrese la IP de inicio del rango DHCP: " RANGO_IP_INICIO
        read -p "Ingrese la IP de fin del rango DHCP: " RANGO_IP_FIN
        
        #Llamamos a la función de validación de rangos
        validacion_rangos_ip "$RANGO_IP_INICIO" "$RANGO_IP_FIN" "$ip"
        
        #Si todo sale bien, salimos del bucle
        if [ $? -eq 0 ]; then
            break
        fi
    done

    echo "$RANGO_IP_INICIO $RANGO_IP_FIN"
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

    return 0  #Retorno exitoso
}