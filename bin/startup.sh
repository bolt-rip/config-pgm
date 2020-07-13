#!/bin/ash

if [[ -n "$MAX_PLAYERS" ]]; then
		echo "changing max players"
		sed -i '/max-players/d' /minecraft/server.properties
		echo "max-players=${MAX_PLAYERS}" >> /minecraft/server.properties
fi

if [[ -n "$OPERATORS" ]]; then
    echo "adding new operators"
    IFS=':' read -r -a array <<< "$OPERATORS"
    for element in "${array[@]}"
    do
        UUID_URL=https://api.ashcon.app/mojang/v1/uuid/$element
        UUID=$(wget -qO- --no-check-certificate $UUID_URL)
        jq '. |= . + [{"uuid": "'$UUID'", "name": "'$element'", "level": 4, "bypassesPlayerLimit": true}]' \
            /minecraft/ops.json > /minecraft/ops.json.new
        mv /minecraft/ops.json.new /minecraft/ops.json
    done
fi

if [[ "$SERVER_CATEGORY" -eq "privateserver" ]]; then
    echo "private server detected... removing Ingame plugin"
    rm /minecraft/plugins/Ingame.jar
fi

