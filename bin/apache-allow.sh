#!/bin/bash

# Configuration files
ALLOWED_FILE="/etc/apache-allow/allowed_ips.conf"
DISALLOWED_FILE="/etc/apache-allow/disallowed_ips.conf"
NEW_FILE="/etc/apache-allow/new_ips.conf"

HA_TOKEN="your token"
HA_SITE="homeassistant.local";

ha_set() {


# Replace these variables with the desired IP and hostname
IP=$1
HOSTNAME=$2
if [ -z "$HOSTNAME" ]; then
  HOSTNAME=$IP
fi

STATE=$3
IP_SAVE=${IP//[.\:]/_}
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")
# Create the entity using the Home Assistant API
echo "$IP_SAVE";
echo "$TIMESTAMP";

curl -X POST -H "Authorization: Bearer $HA_TOKEN" -H "Content-Type: application/json" \
     -d '{
         "object_id": "apache-access-'$IP_SAVE'",
         "name": "'$HOSTNAME'",
         "state": "'$STATE'",
         "attributes": {
             "friendly_name": "'$HOSTNAME'",
             "ip_address": "'$IP'",
             "hostname": "'$HOSTNAME'",
             "timestamp": "'$TIMESTAMP'"
         },
         "icon": "mdi:web"
     }' \
      "$HA_SITE/api/states/sensor.apache_access_$IP_SAVE"


}

purge() {
    grep -Fvxf "$ALLOWED_FILE" "$NEW_FILE" >> "$DISALLOWED_FILE"
     : > "$NEW_FILE"  # Clear the new file after processing
}


init() {
    # Create the files if they don't exist
    touch "$ALLOWED_FILE"
    touch "$DISALLOWED_FILE"
    touch "$NEW_FILE"
    # Read and process allowed IPs
    while IFS= read -r line; do
        ip=$(echo "$line" | awk '{print $1}')
        hostname=$(echo "$line" | awk '{$1=""; print $0}' | xargs)
       if [ -z "$hostname" ]; then
         hostname="$ip"
       fi
        ha_set "$ip" "$hostname" "allow"
    done < "$ALLOWED_FILE"

    # Read and process disallowed IPs
    #while IFS= read -r line; do
    #    ip=$(echo "$line" | awk '{print $1}')
    #    hostname=$(echo "$line" | awk '{$1=""; print $0}' | xargs)
    #         if [ -z "$hostname" ]; then
    #     hostname="$ip"
    #   fi
    #   ha_set "$ip" "$hostname" "disallow"
    #done < "$DISALLOWED_FILE"

    # Read and process new IPs
    while IFS= read -r line; do
        ip=$(echo "$line" | awk '{print $1}')
        hostname=$(echo "$line" | awk '{$1=""; print $0}' | xargs)
       if [ -z "$hostname" ]; then
         hostname="$ip"
       fi
        ha_set "$ip" "$hostname" "new"
    done < "$NEW_FILE"
}


# Function to check if an IP is allowed, disallowed, or new
check_ip() {
    local ip="$1"
    local hostname=$(nslookup "$ip" | awk '/name =/ {print $4}')
    if [ -z "$hostname" ]; then
      hostname="$ip"
    fi    
    if grep -q "^$ip" "$ALLOWED_FILE"; then
        echo "allowed"
    elif grep -q "^$ip" "$DISALLOWED_FILE"; then
         ha_set "$ip" "$hostname" "disallow"
         echo "disallowed"
    else
       if grep -q "^$ip" "$NEW_FILE"; then
          echo "new"
       else 
        echo "$ip $hostname" | sudo tee -a "$NEW_FILE" >/dev/null  
       ha_set "$ip" "$hostname" "new"
          echo "new"
       fi
    fi
}

# Function to add IP to allowed list
allow_ip() {
    local ip="$1"
    local hostname=$(nslookup "$ip" | awk '/name =/ {print $4}')
    if [ -z "$hostname" ]; then
       hostname="$ip"
    fi
    if ! grep -q "^$ip" "$ALLOWED_FILE"; then
        echo "$ip $hostname" | sudo tee -a "$ALLOWED_FILE" > /dev/null
    fi
    sed -i "/^$ip/d" "$NEW_FILE"  # Remove from NEW_FILE
    sed -i "/^$ip/d" "$DISALLOWED_FILE"
    ha_set "$ip" "$hostname" "allow"
}

# Function to add IP to disallowed list
disallow_ip() {
    local ip="$1"
    local hostname=$(nslookup "$ip" | awk '/name =/ {print $4}')
    
    if ! grep -q "^$ip" "$DISALLOWED_FILE"; then
        echo "$ip $hostname" | sudo tee -a "$DISALLOWED_FILE" > /dev/null
    fi
    sed -i "/^$ip/d" "$ALLOWED_FILE"
    sed -i "/^$ip/d" "$NEW_FILE"  # Remove from NEW_FILE
    ha_set "$ip" "$hostname" "disallow"

}


# Function to add IP to disallowed list
disallow_honey_ip() {
    local ip="$1"
    local hostname=$(nslookup "$ip" | awk '/name =/ {print $4}')
    
    if grep -q "^$ip" "$ALLOWED_FILE"; then
        # IP is in the allowed list, so don't disallow it
        return 0
    fi

    if ! grep -q "^$ip" "$DISALLOWED_FILE"; then
        echo "$ip $hostname" | sudo tee -a "$DISALLOWED_FILE" > /dev/null
    fi
    sed -i "/^$ip/d" "$ALLOWED_FILE"
    sed -i "/^$ip/d" "$NEW_FILE"  # Remove from NEW_FILE
    ha_set "$ip" "$hostname" "disallow"

}

# Main script logic
case "$1" in
    "check")
        check_ip "$2"
        ;;
    "allow")
        allow_ip "$2"
        ;;
    "disallow")
        disallow_ip "$2"
        ;;
    "honey")
        disallow_honey_ip "$2"
        ;;
    "init")
        init
        ;;
    "purge")
        purge
        ;;

    *)
        echo "Usage: $0 [check|allow|disallow|honey] <ip>"
        echo "Usage: $0 [init|purge]"
        exit 1
        ;;
esac
