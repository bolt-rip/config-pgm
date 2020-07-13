#!/bin/ash

if [ -z -n "$SLEEP_MIN" ]; then
    SLEEP_MIN=10
fi

counter=0
sleep_10_seconds=$(( $SLEEP_MIN*6 ))

echo "[INFO] Waiting for the server to start..."

/usr/bin/mc-monitor status --host localhost -retry-limit 999 2>&1 >/dev/null

echo "[INFO] Waiting for 0 player on the server under ${SLEEP_MIN} minutes."

while [ $counter -le ${sleep_10_seconds} ]
do
    players_number=$(/usr/bin/mc-monitor status --host mc.hypixel.net | grep -Poi 'online=\K\d+')
    echo "[INFO] There is/are ${players_number} player(s) on the server and the counter is at $(( $counter/6 )) minute(s)."
    if [[ $players_number -eq 0 ]]; then
        counter=$(( $counter + 1 ))
        elif [[ $players_number = "offline" ]]; then
        counter=$(( $counter + 1 ))
    else
        counter=0
    fi
    sleep 10s
done

echo "[WARN] There is no one on the server for ${SLEEP_MIN}, shutting down the server!"

if [[ "$POD_CONTROLER" -eq "cloneset" ]]; then
    number_of_replicas=$(kubectl get clonesets "$RELEASE_NAME" -n minecraft -o=jsonpath='{.status.replicas}')
    new_number_of_replicas="$(($number_of_replicas-1))"
    kubectl patch -n minecraft clonesets "$RELEASE_NAME" \
        -p='{"spec":{"scaleStrategy":{"podsToDelete":[""$POD_NAME""]},"replicas":"$new_number_of_replicas"}}' --type=merge
fi

if [[ "$POD_CONTROLER" -eq "helmrelease" ]]; then
    kubectl delete helmrelease "$RELEASE_NAME"
fi