#!/bin/bash

# 加载环境变量
source .env

# 读取 argus 的 roleManager
AUTHORIZER_RESULT=$(curl -s 'http://127.0.0.1:8545/' \
    -H 'Content-Type: application/json' \
    -d "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"eth_call\",
    \"params\": [{
        \"to\": \"$ARGUS\",
        \"data\": \"0xd09edf31\"
    }, \"latest\"],
    \"id\": 1
}" | jq -r '.result')

AUTHORIZER_ADDRESS="0x${AUTHORIZER_RESULT:26}"
echo "Authorizer Address: $AUTHORIZER_ADDRESS"

echo "Calling addAuthorizer on Authorizer contract..."
ADD_AUTHORIZER_DATA=$(cast calldata "addAuthorizer(bool,bytes32,address)" \
    "false" \
    "$ROLE_HASH" \
    "$ACL_ADDRESS")

curl 'http://127.0.0.1:8545/' \
    -H 'Content-Type: application/json' \
    -d "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"eth_sendTransaction\",
    \"params\": [{
        \"from\": \"$SAFE\",
        \"to\": \"$AUTHORIZER_ADDRESS\",
        \"data\": \"$ADD_AUTHORIZER_DATA\"
    }],
    \"id\": 1
}"
printf "\n"
