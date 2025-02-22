#!/bin/bash

#FUNCIONES PARA PEDIR Y VALIDAR EL DOMINIO DNS
pedir_dominio()
{
    local dominio=""

    while true; do
        read -p "Ingrese el dominio: " dominio
        validacion_dominio "$dominio"
        if [ $? -eq 0 ]; then
            break
        fi
    done
}

validacion_dominio()
{
    local dominio="$1" 

    #Convertir a minúsculas
    dominio=$(echo "$dominio" | tr '[:upper:]' '[:lower:]')

    #Expresión regular para validar el formato del dominio
    local regex='^(www\.)?[a-z0-9-]{1,30}\.[a-z]{2,6}$'

    #Verificamos si el dominio tiene el formato correcto, si no, mensaje de error
    if [[ ! $dominio =~ $regex ]]; then
        echo "El dominio $dominio no tiene el formato válido."
        return 1
    fi

    #Verificar que no empiece o termine con un guion segun las reglas de DNS
    if [[ "$dominio" =~ ^- || "$dominio" =~ -$ ]]; then
        echo "El dominio no puede empezar ni terminar con un guion."
        return 1
    fi

    echo "Okay, el dominio es válido..."
    return 0
}