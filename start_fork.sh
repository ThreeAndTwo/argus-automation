#!/bin/bash

# 加载环境变量
source .env

# 启动fork环境
echo "Starting Ethereum mainnet fork..."
anvil --fork-url $MAINNET_RPC \
      --fork-block-number $FORK_BLOCK_NUMBER \
      --block-time 12 \
      --steps-tracing