#!/bin/bash

# 加载环境变量
source .env

echo "Impersonating Safe account..."
curl 'http://127.0.0.1:8545/' \
    -H 'Content-Type: application/json' \
    -d "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"anvil_impersonateAccount\",
    \"params\": [
        \"$SAFE\"
    ],
    \"id\": 1
}"
printf "\n"

echo "Setting ETH balance for Safe..."
curl 'http://127.0.0.1:8545/' \
    -H 'Content-Type: application/json' \
    -d "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"anvil_setBalance\",
    \"params\": [
        \"$SAFE\",
        \"0x21E19E0C9BAB2400000\"
    ],
    \"id\": 1
}"
printf "\n"

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

echo "Calling addAuthorizer on authorizer..."


# 读取 argus 的 roleManager
ROLE_MANAGER_RESULT=$(curl -s 'http://127.0.0.1:8545/' \
    -H 'Content-Type: application/json' \
    -d "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"eth_call\",
    \"params\": [{
        \"to\": \"$ARGUS\",
        \"data\": \"0x00435da5\"
    }, \"latest\"],
    \"id\": 1
}" | jq -r '.result')

ROLE_MANAGER_ADDRESS="0x${ROLE_MANAGER_RESULT:26}"
echo "Role Manager Address: $ROLE_MANAGER_ADDRESS"

echo "Calling addRole on roleManager..."


# 1. 调用 addRoles
echo "Calling addRoles on roleManager..."
ADD_ROLES_DATA=$(cast calldata "addRoles(bytes32[])" "[$ROLE_HASH]")

curl 'http://127.0.0.1:8545/' \
    -H 'Content-Type: application/json' \
    -d "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"eth_sendTransaction\",
    \"params\": [{
        \"from\": \"$SAFE\",
        \"to\": \"$ROLE_MANAGER_ADDRESS\",
        \"data\": \"$ADD_ROLES_DATA\"
    }],
    \"id\": 1
}"
printf "\n"

# 2. 调用 grantRoles
echo "Calling grantRoles on roleManager..."
GRANT_ROLES_DATA=$(cast calldata "grantRoles(bytes32[],address[])" "[$ROLE_HASH]" "[$BOT_ADDRESS]")

curl 'http://127.0.0.1:8545/' \
    -H 'Content-Type: application/json' \
    -d "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"eth_sendTransaction\",
    \"params\": [{
        \"from\": \"$SAFE\",
        \"to\": \"$ROLE_MANAGER_ADDRESS\",
        \"data\": \"$GRANT_ROLES_DATA\"
    }],
    \"id\": 1
}"
printf "\n"


# 3. 调用 argus 的 addDelegate
echo "Calling addDelegate on Argus..."
ADD_DELEGATE_DATA=$(cast calldata "addDelegate(address)" "$BOT_ADDRESS")

curl 'http://127.0.0.1:8545/' \
    -H 'Content-Type: application/json' \
    -d "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"eth_sendTransaction\",
    \"params\": [{
        \"from\": \"$SAFE\",
        \"to\": \"$ARGUS\",
        \"data\": \"$ADD_DELEGATE_DATA\"
    }],
    \"id\": 1
}"
printf "\n"
echo "All operations completed!"
