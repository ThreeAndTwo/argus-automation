#!/bin/bash

check_tx() {
    local tx_hash=$1
    local tx_name=$2
    if [ "$tx_hash" != "null" ] && cast receipt $tx_hash; then
        echo "✅ $tx_name succeeded"
    else
        echo "❌ $tx_name failed"
        [ "$tx_hash" != "null" ] && cast run $tx_hash
    fi
}

exec_batch_via_argus() {
    local transactions=("$@")
    
    local tx_array=""
    local first=true
    
    for tx in "${transactions[@]}"; do
        IFS=',' read -r to data value <<< "$tx"
        
        if [[ ! "$data" =~ ^0x ]]; then
            data="0x$data"
        fi
        
        if [ -z "$value" ] || [ "$value" = "0" ]; then
            value="0"
        fi
        
        if [ "$first" = true ]; then
            first=false
        else
            tx_array+=","
        fi
        
        tx_array+="(0,$to,$value,$data,0x,0x)"
    done

    local encoded_data=$(cast calldata \
        "execTransactions((uint256,address,uint256,bytes,bytes,bytes)[])" \
        "[$tx_array]")
    
    echo "Debug - Encoded data: $encoded_data"

    local tx_hash=$(curl -s 'http://127.0.0.1:8545/' \
        -H 'Content-Type: application/json' \
        -d "{
        \"jsonrpc\": \"2.0\",
        \"method\": \"eth_sendTransaction\",
        \"params\": [{
            \"from\": \"$BOT_ADDRESS\",
            \"to\": \"$ARGUS\",
            \"data\": \"$encoded_data\"
        }],
        \"id\": 1
    }" | jq -r '.result')

    check_tx "$tx_hash" "Batch Transaction"
}
