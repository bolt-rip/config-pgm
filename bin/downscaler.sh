#!/bin/ash

if [ -z "$SLEEP_MIN" ]; then
    SLEEP_MIN=10
fi

counter=0
sleep_10_seconds=$(( $SLEEP_MIN*6 ))

echo "[INFO] Waiting for the server to start..."

/usr/bin/mc-monitor status --host localhost -retry-limit 999 > /dev/null 2>&1

echo "[INFO] Waiting for 0 player on the server under ${SLEEP_MIN} minute(s)."

while [ $counter -le ${sleep_10_seconds} ]
do
    sleep 10s
    players_number=$(/usr/bin/mc-monitor status --host localhost | grep -Poi 'online=\K\d+')
    echo "[INFO] There is/are ${players_number} player(s) on the server and the counter is at $(( $counter/6 )) minute(s)."
    if [ "$players_number" -eq 0 ] && [ "$(kubectl get pod "$POD_NAME" -n minecraft -o=jsonpath='{.metadata.labels.occupied}')" = "false" ]; then
        counter=$(( $counter + 1 ))
    else
        counter=0
    fi
done

echo "[WARN] There is 0 player on the server for ${SLEEP_MIN} minute(s), shutting down the server!"

if [ "$POD_CONTROLER" = "cloneset" ]; then
    number_of_replicas=$(kubectl get clonesets "$RELEASE_NAME" -n minecraft -o=jsonpath='{.status.replicas}')
    new_number_of_replicas="$(($number_of_replicas-1))"
    kubectl patch -n minecraft clonesets "$RELEASE_NAME" \
        -p='{"spec":{"scaleStrategy":{"podsToDelete":["'$POD_NAME'"]},"replicas":'$new_number_of_replicas'}}' --type=merge
fi

if [ "$POD_CONTROLER" = "helmrelease" ]; then
    kubectl delete helmrelease "$RELEASE_NAME"
fi