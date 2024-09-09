#!/bin/bash

# SSH into the target machine(s) and update the configuration files to enable passive

IP_LIST=( "192.168.0.230" "192.168.1.9")                # RHEL
IP_LIST+=("192.168.1.1")                                # CentOS
IP_LIST+=("192.168.1.12" "192.168.1.14")                # Oracle Linux
IP_LIST+=("192.168.1.11" "192.168.0.115" "192.168.0.2") # Ubuntu
IP_LIST+=("192.168.0.251" "192.168.0.236")              # Debian
SSH_USER="root"
SSH_PASS="welcome"

declare -A FILE_MODIFICATIONS=(
    ["/usr/local/ncpa/etc/ncpa.cfg"]="s/^handlers = .*/handlers = nrdp/"
    ["/usr/local/ncpa/etc/ncpa.cfg.d/example.cfg_1"]="s/#\[passive checks\].*/[passive checks]/"
    ["/usr/local/ncpa/etc/ncpa.cfg.d/example.cfg_2"]="s/^#%HOSTNAME%\(.*\)/%HOSTNAME%\1/"
)

for IP in "${IP_LIST[@]}"
do
    echo "Connecting to $IP"
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "${SSH_USER}@${IP}" "exit"
    if [ $? -ne 0 ]; then
        echo "Failed to connect to $IP. Skipping..."
        continue
    fi
    
    for FILE in "${!FILE_MODIFICATIONS[@]}"
    do
        FILE_PATH="${FILE%_*}"
        sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "${SSH_USER}@${IP}" "sudo sed -i '${FILE_MODIFICATIONS[$FILE]}' $FILE_PATH"

        if [ $? -eq 0 ]; then
            echo "Successfully updated $FILE_PATH on $IP"
        else
            echo "Failed to update $FILE_PATH on $IP"
        fi
    done

    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "${SSH_USER}@${IP}" "sudo systemctl restart ncpa"
    
    if [ $? -eq 0 ]; then
        echo "Successfully restarted NCPA service on $IP"
    else
        echo "Failed to restart NCPA service on $IP"
    fi
    echo ""
done
