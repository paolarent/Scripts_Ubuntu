#!/bin/bash

pedir_IP(){
    local ip=""

    while true; do
        read -p "Ingrese la IP: " ip
        #Llamamos a la función de validación
        validacion_ip_correcta "$ip"
        #Si la IP es válida (return 0), salimos del bucle
        if [ $? -eq 0 ]; then
            break
        fi
    done
}