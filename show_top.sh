#!/bin/bash    
clear

BASE_PATH=$(pwd)
PATH_TO_TESTED="${BASE_PATH}/output.json"

OUTPUT_PEER_COUNT=20    #  default peer output count 

output_address="addr"   # default output address name [p2p: address, non-p2p: addr]
output_valency=true     # should valency be added at each line, required for non-p2p configuration
output_p2p=false        # non-p2p output by default

#########################
# The command line help #
#########################
display_help() {
    echo "Usage: $0 [option...]" >&2
    echo
    echo "   -p     Output P2P version compatible host output [default: non p2p output]"
    echo "   -c,    Set how may hosts should be printed out [default ${OUTPUT_PEER_COUNT}]"
    echo "   -h,    Prints this help "
    echo
    exit 1
}

################################
# Check if parameters options  #
# are given on the commandline #
################################
while getopts 'phc:' opt; do
  case "$opt" in
      p)  
         output_address="address" 
         output_valency=false
         output_p2p=true 
         echo "Printing output in p2p mode"   
          ;;

      c)
            arg="$OPTARG"
            OUTPUT_PEER_COUNT=$OPTARG
           ;;

      ?|h)
        display_help  # Call your function
          exit 0
          ;;
    esac
done

# printing out best peers
echo "Show best ${OUTPUT_PEER_COUNT} Peers from ${PATH_TO_TESTED}:"

json_output='{}' # creating epmty json object

for ((i = 0 ; i <= $(($OUTPUT_PEER_COUNT-1)) ; i++)); do
    output=$(cat ${PATH_TO_TESTED}| jq -cr .[$i])
    address=$(jq -r '.address' <<< "$output");
    port=$(jq -r '.port' <<< "$output");
    rtt=$(jq -r '.rtt' <<< "$output");

    if [ "$address" == "null" ]; then 
        continue # skip
    fi


    if "$output_p2p"
    then
        json_output=$(jq ".accessPoints += [{\"address\": \"${address}\", \"port\": \"${port}\", \"rtt\": \"${rtt}\"}]" <<< "$json_output")
    else
        json_output=$(jq ".producers += [{\"addr\": \"${address}\", \"port\": \"${port}\", \"rtt\": \"${rtt}\", \"valency\": 1}]" <<< "$json_output")
    fi

done

echo "output:"
echo ${json_output} | jq
