#!/bin/bash

#######################################################################
# Script para exportar una imagen Docker desde un servidor remoto,
# comprimirla, transferirla al equipo local y cargarla en Docker.
#
# Sintaxis:
#     ./dTransferImage.sh usuario@servidor nombreImagen
#
# Parámetros:
#     usuario@servidor   Host remoto al que conectarse por SSH.
#     nombreImagen       Nombre completo de la imagen Docker (incluyendo tag).
#
# Autoría: Marc Bria
# Licencia: GPL
# Última modificación: 10/02/2025
#######################################################################

# Verify that exactly 2 parameters are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 user@server dockerImage"
    exit 1
fi

remoteHost="$1"
imageName="$2"
fileName=$(echo "$imageName" | tr ':.' '_')

# Set up SSH control master to avoid multiple logins
sshControlPath="/tmp/ssh_control_%r@%h:%p"
ssh -o ControlMaster=auto -o ControlPath="$sshControlPath" -o ControlPersist=10m -f -N "$remoteHost"

# Function to execute remote commands using the existing SSH connection
ssh_remote() {
    ssh -o ControlPath="$sshControlPath" "$remoteHost" "$@"
}

# Function to copy files using the existing SSH connection
scp_remote() {
    scp -o ControlPath="$sshControlPath" "$@"
}

echo "> Saving the image on the remote server..."

ssh_remote "
    docker save -o /tmp/$fileName.tar $imageName &
    save_pid=\$!
    while kill -0 \$save_pid 2>/dev/null; do
        if ls -lh /tmp/$fileName.tar 2>/dev/null; then
            :  # If exists, don't do nothing (just show the size).
        else
            echo -n '='  # If is not still created, show the '=' symbol.
        fi
        sleep 2;
    done
    echo
"

echo "> Compressing the image on the remote server..."
ssh_remote "gzip -vv /tmp/$fileName.tar"

echo "> Transferring the compressed image to the local server..."
scp_remote "$remoteHost:/tmp/$fileName.tar.gz" .

echo "> Loading the image into Docker on the local server..."
docker load < "$fileName.tar.gz"

echo "> Deleting the temporary file on the remote server..."
ssh_remote "rm -f /tmp/$fileName.tar.gz"

# Close the SSH control master connection
ssh -o ControlPath="$sshControlPath" -O exit "$remoteHost"

echo "> Process completed successfully."
