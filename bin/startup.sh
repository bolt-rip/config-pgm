#!/bin/ash

if [ -n "$MAX_PLAYERS" ]; then
		echo "changing max players"
		sed -i '/max-players/d' /minecraft/server.properties
		echo "max-players=${MAX_PLAYERS}" >> /minecraft/server.properties
fi

if [ -n "$OPERATORS" ]; then
    echo "adding new operators"
    IFS=":"
    for operator in $OPERATORS
    do
        UUID_URL=https://api.ashcon.app/mojang/v1/uuid/$operator
        UUID=$(wget -qO- --no-check-certificate $UUID_URL)
        jq '. |= . + [{"uuid": "'$UUID'", "name": "'$operator'", "level": 4, "bypassesPlayerLimit": true}]' \
            /minecraft/ops.json > /minecraft/ops.json.new
        mv /minecraft/ops.json.new /minecraft/ops.json
    done
fi

if [ "$RELEASE_NAME" != "ranked" ]; then
    echo "not a ranked server detected... removing Ingame plugin"
    rm /minecraft/plugins/Ingame.jar
fi

