#!/bin/bash    
clear

BASE_PATH=$(pwd)
PATH_TO_TOPOLOGY="${BASE_PATH}/topology.json"
PATH_TO_TESTED="${BASE_PATH}/output.json"
CNCLI_CLI="/Users/lauris/.local/bin/cncli"
OUTPUT_PEER_COUNT=20

if [ -f "$PATH_TO_TESTED" ]; then
    echo "$PATH_TO_TESTED exists, removing it."
    rm $PATH_TO_TESTED
fi

# loading the peer list from cardano.org
wget -q -O ${PATH_TO_TOPOLOGY} https://explorer.mainnet.cardano.org/relays/topology.json

# check how many records are there
COUNT=$(cat $PATH_TO_TOPOLOGY | jq -r '.Producers | .[] | .addr' | wc -l)

# for testing purposes limit entries
COUNT=5

let NWMAGIC=764824073
let COUNT-=1

echo "Total Peers in the file: ${COUNT}"

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
        
        # check if last line 
        if [ $COUNT -lt 0 ]; 
                then end_of_record=" " 
        fi

        cat <<EOF >> ${PATH_TO_TESTED}
        {"address" : "${nodeIP}", "port": ${nodePORT}, "rtt": ${nodeRTT}${end_of_record}}
EOF
done

# sort peers by RTT
cat ${PATH_TO_TESTED} | jq -s -c 'sort_by(.rtt) | .[]' | sponge ${PATH_TO_TESTED} 

clear
# printing out 20 best peers
echo "Sorted best ${OUTPUT_PEER_COUNT} Peers based on RTT:"
head -n ${OUTPUT_PEER_COUNT} ${PATH_TO_TESTED} | jq