#!/bin/ash

sed -i "s/%SERVER-NAME%/$SERVER_NAME/g" plugins/PGM/config.yml

if [ "$CHART_NAME" == "ranked" ]; then
    # temporary hack due to configmap being read only, need to be fixed
    cp plugins/Bolty/config-readonly.yml plugins/Bolty/config.yml
    sed -i "s/%SERVER-NAME%/$SERVER_NAME/g" plugins/Bolty/config.yml
    echo "[INFO] Ranked server detected... updating PGM config."
    sed -i 's/%START-TIME%/"30s"/g' plugins/PGM/config.yml
    sed -i "s/%MATCH-LIMIT%/6/g" plugins/PGM/config.yml
    sed -i "s/%STATS-RETURN%/-1/g" plugins/PGM/config.yml
fi

if [ -n "$MAX_PLAYERS" ]; then
        echo "[INFO] Changing the maximum of players."
        sed -i '/max-players/d' /minecraft/server.properties
        echo "max-players=${MAX_PLAYERS}" >> /minecraft/server.properties
fi

if [ -n "$OPERATORS" ]; then
    echo "[INFO] Adding new operators."
    IFS=":"
    for operator in $OPERATORS
    do
        unset IFS
        UUID_URL="https://api.ashcon.app/mojang/v1/uuid/$operator"
        UUID=$(wget -qO- --no-check-certificate $UUID_URL)
        jq '. |= . + [{"uuid": "'$UUID'", "name": "'$operator'", "level": 4, "bypassesPlayerLimit": true}]' \
            /minecraft/ops.json > /minecraft/ops.json.new
        mv /minecraft/ops.json.new /minecraft/ops.json
    done
fi

if [ "$CHART_NAME" != "ranked" ]; then
    echo "[INFO] Not a ranked server detected... removing Ingame, Events, AutoKiller, Bolty, Matrix and Idly plugins and updating PGM config."
    rm -f /minecraft/plugins/ingame.jar /minecraft/plugins/Events.jar \
        /minecraft/plugins/AutoKiller-*.jar /minecraft/plugins/Bolty-*.jar \
        /minecraft/plugins/Matrix-*.jar \
        /minecraft/plugins/Idly.jar
    sed -i "s/%START-TIME%/-1/g" plugins/PGM/config.yml
    sed -i "s/%MATCH-LIMIT%/-1/g" plugins/PGM/config.yml
    sed -i 's/%STATS-RETURN%/"3s"/g' plugins/PGM/config.yml
fi

if [ "$CHART_NAME" = "privateserver" ]; then
    echo "[INFO] Private server detected... activating the whitelist."
    sed -i '/white-list/d' /minecraft/server.properties
    echo "white-list=true" >> /minecraft/server.properties
fi

if [ "$NODE_NAME" != "ns522982" ]; then
    echo "[INFO] Not on OCC node (node name: ns522982)... removing LPX and Matrix plugins."
    rm -f /minecraft/plugins/LPX-*.jar /minecraft/plugins/Matrix-*.jar
fi

# disable PGM tablist if ingame exists
TAB_ENABLED=true
INGAME=/minecraft/plugins/ingame.jar
if [[ -f "$INGAME" ]]; then
    TAB_ENABLED=false
fi

sed -i "s/%TAB-ENABLED%/$TAB_ENABLED/g" plugins/PGM/config.yml
