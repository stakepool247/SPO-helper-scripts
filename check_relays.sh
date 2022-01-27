#!/bin/bash    
clear

BASE_PATH=$(pwd)
PATH_TO_TOPOLOGY="${BASE_PATH}/topology.json"
PATH_TO_TESTED="${BASE_PATH}/output.json"
CNCLI_CLI="$(which cncli)"
NWMAGIC=764824073
OUTPUT_PEER_COUNT=20
TEST_COUNT=0  # for testing purposes. Set to 0 to read all records

if [ -f "$PATH_TO_TESTED" ]; then
    echo "$PATH_TO_TESTED exists, removing it."
    rm $PATH_TO_TESTED
fi

# loading the peer list from cardano.org
wget -q -O ${PATH_TO_TOPOLOGY} https://explorer.mainnet.cardano.org/relays/topology.json

# check how many records are there
COUNT=$(cat $PATH_TO_TOPOLOGY | jq -r '.Producers | .[] | .addr' | wc -l)

# for testing purposes limit entries
if [ "$TEST_COUNT" -gt 0 ]; then 
        COUNT=$TEST_COUNT 
fi

let COUNT-=1


echo "Total Peers in the file: $(( $COUNT + 1 ))"

# checking the rtt
until [  $COUNT -lt 0 ]; do
        printf "Peer $COUNT: "

        nodeIP=$(cat $PATH_TO_TOPOLOGY | jq -r ".Producers | .[$COUNT] | .addr")
        nodePORT=$(cat $PATH_TO_TOPOLOGY | jq -r ".Producers | .[$COUNT] | .port")

        checkNODE=$(${CNCLI_CLI} ping --host "${nodeIP}" --port "${nodePORT}" --network-magic "${NWMAGIC}")
        #echo "OUTPUT ${checkNODE}"

        if [[ $(jq -r .status <<< "${checkNODE}") = "ok" ]]; then
                [[ ${CNCLI_CONNECT_ONLY} = true ]] && nodeRTT=$(jq -r .connectDurationMs <<< "${checkNODE}") || nodeRTT=$(jq -r .durationMs <<< "${checkNODE}")
        else 
                nodeRTT=999999
        fi

        echo "Peer $COUNT: nodeIP: ${nodeIP} nodePORT: ${nodePORT} nodeRTT: ${nodeRTT}"
        let COUNT-=1

        cat <<EOF >> ${PATH_TO_TESTED}
        {"address" : "${nodeIP}", "port": ${nodePORT}, "rtt": ${nodeRTT}}
EOF
done


# remove duplicates
cat ${PATH_TO_TESTED} | jq -s 'unique_by(.address)' | sponge ${PATH_TO_TESTED} 

# sort peers by RTT
cat ${PATH_TO_TESTED} |  jq  'sort_by(.rtt) '  | sponge ${PATH_TO_TESTED} 

# clear
# printing out best peers
echo "Best ${OUTPUT_PEER_COUNT} Peers:"
for ((i = 0 ; i <= $OUTPUT_PEER_COUNT ; i++)); do
  cat ${PATH_TO_TESTED}| jq -cr .[$i]
done


