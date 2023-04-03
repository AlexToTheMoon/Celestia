#!/bin/bash

source $HOME/.bash_profile
TOKEN_AMOUNT="50000000000000000000000stake"
STAKING_AMOUNT="300000000stake"
RPC="https://rpc-blockspacerace.pops.one"

NAMESPACE_ID=$(echo $RANDOM | md5sum | head -c 16; echo;)
echo $NAMESPACE_ID
DA_BLOCK_HEIGHT=$(curl ${RPC}/block | jq -r '.result.block.header.height')
echo $DA_BLOCK_HEIGHT


$RBIN keys add $KEY_NAME --keyring-backend test
$RBIN add-genesis-account $KEY_NAME $TOKEN_AMOUNT --keyring-backend test
$RBIN gentx $KEY_NAME $STAKING_AMOUNT --chain-id $CHAIN_ID --keyring-backend test
$RBIN collect-gentxs
$RBIN tendermint unsafe-reset-all

sudo tee <<EOF >/dev/null /etc/systemd/system/celestia-amsd.service
[Unit]
Description=celestia-rollup
After=network-online.target

[Service]
User=$USER
ExecStart=$(which amsd) start --rollkit.aggregator true --rollkit.da_layer celestia --rollkit.da_config='{"base_url":"http://localhost:26659","timeout":60000000000,"fee":6000,"gas_limit":6000000}' --rollkit.namespace_id $NAMESPACE_ID --rollkit.da_start_height $DA_BLOCK_HEIGHT
Restart=on-failure
RestartSec=10
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable celestia-amsd.service
sudo systemctl restart celestia-amsd.service
