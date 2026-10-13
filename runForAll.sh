#!/bin/bash

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <JOURNALS_FILE_PATH> <ACTION_FILE_PATH>"
    exit 1
fi

# Asignar los parámetros a variables
JOURNAL_FILE=$1   # Path al archivo que contiene la lista de journals
ACTION_FILE=$2    # Path al archivo que contiene la acción a ejecutar

# Validar si el archivo de JOURNAL existe y es legible
if [ ! -f "$JOURNAL_FILE" ]; then
    echo "Error: El archivo de JOURNAL '$JOURNAL_FILE' no existe o no es legible."
    exit 1
fi

# Validar si el archivo de ACTION existe y es legible
if [ ! -f "$ACTION_FILE" ]; then
    echo "Error: El archivo de ACTION '$ACTION_FILE' no existe o no es legible."
    exit 1
fi

# Obtener el nombre del archivo sin la ruta ni la extensión, para propósitos de logging
FILENAME=$(basename "$JOURNAL_FILE" | sed 's/\.[^.]*$//')

# Mostrar los detalles del archivo de acción y journal
echo "Archivo de journal: $JOURNAL_FILE"
echo "Archivo de acción: $ACTION_FILE"
echo "El archivo de log se nombrará basado en: $FILENAME"

echo "------------------------------------------------------------"
echo "El contenido del archivo de acción es:"
cat "$ACTION_FILE"
echo "------------------------------------------------------------"

# Solicitar confirmación antes de continuar
read -p "¿Estás seguro de que quieres ejecutar esta acción? (y/n) " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    echo "Acción cancelada por el usuario."
    exit 0
fi

# Obtener la fecha y hora actual en formato YYYYMMDD-HHMM
TIMESTAMP=$(date +"%Y%m%d-%H%M")

# Crear el directorio de logs si no existe
mkdir -p ./logs

# Archivo de log basado en el timestamp y el nombre del archivo journal
LOG_FILE="./logs/${TIMESTAMP}-${FILENAME}.log"

# Procesar cada journal listado en el archivo de journals
while IFS= read -r JOURNAL; do
    echo "Ejecutando en: $JOURNAL"

    # Exportar la variable JOURNAL para usarla en el script de acción
    export JOURNAL

    # Ejecutar el archivo de acción en un subshell
    OUTPUT=$(bash "$ACTION_FILE")

    # Mostrar el resultado en la terminal
    echo "$OUTPUT"

    # Añadir la salida al archivo de log
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $OUTPUT" >> "$LOG_FILE"

done < "$JOURNAL_FILE"

echo "Logs guardados en: $LOG_FILE"
