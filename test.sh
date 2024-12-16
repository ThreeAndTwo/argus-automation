#!/bin/bash

if [ ! -f ".env" ]; then
    echo "Error: .env file not found"
    exit 1
fi

set -a
source .env
set +a

source ./argus_module.sh

TOKEN_ADDRESS="0xA1290d69c65A6Fe4DF752f95823fae25cB99e5A7"
AMOUNT=1000000000000000000


# 业务代码
TRANSFER_DATA=$(cast calldata "transfer(address,uint256)" "$BOT_ADDRESS" "$AMOUNT")
echo "Generated transfer calldata: $TRANSFER_DATA"

printf "TOKEN_ADDRESS: $TOKEN_ADDRESS\n"

# 组装批量交易
TRANSACTIONS=(
    "$TOKEN_ADDRESS,$TRANSFER_DATA,0"
    "$TOKEN_ADDRESS,$TRANSFER_DATA,0"
)

# call argus
exec_batch_via_argus "${TRANSACTIONS[@]}"