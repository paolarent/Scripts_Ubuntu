#!/bin/bash

#FUNCION PARA VALIDAR IP
validacion_ip_correcta()
{
    local ip="$1" #primer argumento para la funcion
    local regex_ipv4='^([0-9]{1,3}\.){3}[0-9]{1,3}$' #expresion para cuidar el formato de IPV4, 4 octetos, separados por ., de 1-3 digitos

    if [[ ! $ip =~ $regex_ipv4 ]]; then      #Comparacion de la ip ingresada con el formato
    echo "La IP ingresada no tiene el formato válido."    #Si es diferente, mensaje de error.
    return 1    #indicar fallo
    fi

    #Verificar cada octeto de la IP (valores entre 0 y 255)
    IFS='.' read -r -a octetos <<< "$ip"    #La IP se divide en un array llamado octetos usando el punto como separador.
    for octeto in "${octetos[@]}"; do       #Iteramos sobre cada octeto de la IP.
        if ! [[ "$octeto" =~ ^[0-9]+$ ]] || [ "$octeto" -lt 0 ] || [ "$octeto" -gt 255 ]; then
            echo "Error. La IP no es válida, los octetos deben estar entre 0 y 255."
            return 1
        fi
    done

    #Validar que no sean direcciones de red o broadcast
    IFS='.' read -r -a ip_array <<< "$ip"

    #Dirección de red si el último octeto es 0
    if [ "${ip_array[3]}" -eq 0 ]; then
        echo "Error. La IP $ip es una dirección de red y no es válida."
        return 1
    fi

    #Dirección de broadcast si el último octeto es 255
    if [ "${ip_array[3]}" -eq 255 ]; then
        echo "ERROR. La IP ingresada es una dirección de broadcast y no es válida."
        return 1
    fi

    echo "Okay, la IP ingresada es válida..."
    return 0
}