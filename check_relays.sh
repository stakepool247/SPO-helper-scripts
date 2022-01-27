#!/bin/bash    
clear
PATH_TO_TOPOLOGY=/home/cardano/cnode/config/top/topology.json
PATH_TO_TESTED=/home/cardano/cnode/config/top/output.json

wget -q -O ${PATH_TO_TOPOLOGY} https://explorer.mainnet.cardano.org/relays/topology.json

COUNT=$(cat $PATH_TO_TOPOLOGY | jq -r '.Producers | .[] | .addr' | wc -l)
let NWMAGIC=764824073
let COUNT-=1

echo "Total Peers in the file: ${COUNT}"

until [  $COUNT -lt 0 ]; do
        printf "Peer $COUNT: "

        peerIP=$(cat $PATH_TO_TOPOLOGY | jq -r ".Producers | .[$COUNT] | .addr")
        peerPORT=$(cat $PATH_TO_TOPOLOGY | jq -r ".Producers | .[$COUNT] | .port")

        checkPEER=$(cncli ping --host "${peerIP}" --port "${peerPORT}" --network-magic "${NWMAGIC}")
        #echo "OUTPUT ${checkPEER}"

        if [[ $(jq -r .status <<< "${checkPEER}") = "ok" ]]; then
                [[ ${CNCLI_CONNECT_ONLY} = true ]] && peerRTT=$(jq -r .connectDurationMs <<< "${checkPEER}") || peerRTT=$(jq -r .durationMs <<< "${checkPEER}")
        else # cncli ping failed
                peerRTT=99999
        fi

        echo "Peer $COUNT: peerIP: ${peerIP} peerPort: ${peerPORT} peerRTT: ${peerRTT}"
        let COUNT-=1
        
        cat <<EOF >> ${PATH_TO_TESTED}
        {"address" : "${peerIP}", "port": ${peerPORT}, "rtt": ${peerRTT}}       
EOF
done

# sort peers by RTT
cat ${PATH_TO_TESTED | jq -s -c 'sort_by(.rtt) | .[]' | sponge ${PATH_TO_TESTED} 
