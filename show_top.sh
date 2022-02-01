#!/bin/bash    
clear

BASE_PATH=$(pwd)
PATH_TO_TESTED="${BASE_PATH}/output.json"

OUTPUT_PEER_COUNT=60

# printing out best peers
echo "Show best ${OUTPUT_PEER_COUNT} Peers from ${PATH_TO_TESTED}:"

for ((i = 0 ; i <= $OUTPUT_PEER_COUNT ; i++)); do
    cat ${PATH_TO_TESTED}| jq -cr .[$i]
done

