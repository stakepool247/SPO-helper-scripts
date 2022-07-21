#!/bin/bash

TOPOLOGY_FILE=/home/cardano/cnode/config/mainnet-topology.json
clear


entries=$(jq -cr .Producers[].addr $TOPOLOGY_FILE | wc -l)
echo "current topology file has $entries  entries"

echo "Creating Backup"
cp $TOPOLOGY_FILE $TOPOLOGY_FILE.$(date +'%Y-%m-%d-%H-%S')

echo "Gathering failed subscriptions in last 2 hours"
mapfile -t load_failed < <( journalctl -u cardano-node.service  -o cat  --since "2 hours ago" | jq  '. | select(.data.event=="Failed to start all required subscriptions") | .data.domain' -cr | sort | uniq | grep -v "null" | tr -d '"')

echo "Found ${#load_failed[@]} relays to which we can't connect" 


echo "Checking how many are in the current topology file"
counter=0
declare -a node_list

for node in "${load_failed[@]}"
do
	found_node=$(jq -r '.Producers[].addr | contains("'"$node"'")' $TOPOLOGY_FILE | grep "true")
	
	if [ "true" = "$found_node" ]
	then
	#	echo "Found $node in topology"
		 ((counter+=1))
		node_list+=("$node")
	fi


done
echo "Found $counter relays in topology file" 


for node in "${node_list[@]}"
do
		printf "Removing entry: $node \n "
		jq 'del(.Producers[] | select(.addr == "'"$node"'"))' $TOPOLOGY_FILE | sponge $TOPOLOGY_FILE
done

entries=$(jq -cr .Producers[].addr $TOPOLOGY_FILE | wc -l)
echo "Updated topology file has $entries  entries"

