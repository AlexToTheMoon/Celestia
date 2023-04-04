## Sovereign Rollup deploying for Celestia "Blockspace" testnet chain VIA Rollkit.

### Please notice:

In this guide we take to account that all default ports for Cosmos based chains are not busy at your machine.  
Rollup port : `26656, 26657, 6060, 1317, 9090, 9091  `
Celestia light node ports : `2121, 26658, 26659  `

For any feedback or comments, please contact Discord - AlexeyM#5409

##
<p align="center">
Instructions
</p>

#### Install Dependencies 
```
sudo apt update
sudo apt upgrade -y 
sudo apt install make clang pkg-config libssl-dev build-essential git jq llvm libudev-dev -y
```

#### Install Go 
```
wget https://go.dev/dl/go1.19.linux-amd64.tar.gz \
sudo tar -xvf go1.19.linux-amd64.tar.gz && sudo mv go /usr/local \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile \
source ~/.bash_profile; go version
```

#### Setup Celestia Light node
```
cd $HOME
git clone https://github.com/celestiaorg/celestia-node.git
cd celestia-node
git checkout v0.8.1
make cel-key
make build
chmod +x ./build/celestia
sudo mv ./build/celestia /usr/local/bin
celestia version
```

#### Init Light node 
```
celestia light init --p2p.network blockspacerace-0
```
Note : During initialization process the new Celestia key will be generated.  
U can write down mnemonic phase and use generated key, or U can add or recover your key via cel-key binary.
Instructions can be found here : https://docs.celestia.org/nodes/light-node/#keys-and-wallets

#### Fund the Celesia light node wallet

During initialization process the new celestia key was generated and key was shown  
Use it to fund your wallet for example at Dicscord faucet  
https://discord.com/channels/638338779505229824/1077531922022015026 

#### Sort config file and run Light node  

U can download ready to go config from this repo by command below:    
```
wget -qO $HOME/.celestia-light-blockspacerace-0/config.toml https://github.com/AlexToTheMoon/Celestia/raw/main/light-node-conf.toml 
```   
<SUB>For this guide used Pops team RPC but U can use any U like</SUB>   
<SUB>It can be easly changed inside `$HOME/.celestia-light-blockspacerace-0/config.toml` config file</SUB>  

Create service file  
```
sudo tee <<EOF >/dev/null /etc/systemd/system/celestia-light.service
[Unit]
Description=celestia-light-node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which celestia) light start --node.config $HOME/.celestia-light-blockspacerace-0/config.toml \
--node.store $HOME/.celestia-light-blockspacerace-0 --p2p.network blockspacerace-0
Restart=on-failure
RestartSec=10
LimitNOFILE=4096
[Install]
WantedBy=multi-user.target
EOF
```

Run service and check logs 

```
sudo systemctl daemon-reload
sudo systemctl enable celestia-light.service
sudo systemctl restart celestia-light.service
sudo journalctl -u celestia-light.service -fn 50 -o cat
```

If U see that every new head height is increasing all working well :      
<SUB>`INFO    header/store    store/store.go:353      new head        {"height": 513, "hash": "28C5E6...}`</SUB>  
<SUB>`INFO    header/store    store/store.go:353      new head        {"height": 1025, "hash": "57240...}`</SUB>    

Make sure port 26659 is listening, command to check :
```
sudo lsof -i -P -n | grep LISTEN | grep 26659
```  
<SUB>`# TCP *:26659 (LISTEN)`</SUB>  
 
#### Install Ignite
```
sudo curl https://get.ignite.com/cli! | bash
ignite version
```
#### Add variables 
We need to add few variables for Rollup launch, my case : `CHAIN_ID="ams", VAL_NAME="AM Solutions", KEY_NAME="alex"`  
Add your values below:  
`CHAIN_ID="Your chain name" `   
`VAL_NAME="Your Validator name" `   
`KEY_NAME="Your key name"`  

And import them to bash profile:  
```
echo 'export CHAIN_ID='\"${CHAIN_ID}\" >> $HOME/.bash_profile
echo 'export VAL_NAME='\"${VAL_NAME}\" >> $HOME/.bash_profile
echo 'export KEY_NAME='\"${KEY_NAME}\" >> $HOME/.bash_profile
source $HOME/.bash_profile
```
Check those :     
```
echo $CHAIN_ID $VAL_NAME $KEY_NAME
```

#### Create and configure your Rollup
```
cd $HOME
ignite scaffold chain ${CHAIN_ID} --address-prefix ${CHAIN_ID}
```
Install Rollkit

```
cd $HOME/${CHAIN_ID}
go mod edit -replace github.com/cosmos/cosmos-sdk=github.com/rollkit/cosmos-sdk@v0.46.7-rollkit-v0.7.2-no-fraud-proofs
go mod edit -replace github.com/tendermint/tendermint=github.com/celestiaorg/tendermint@v0.34.22-0.20221202214355-3605c597500d
go mod tidy
go mod download
```
Build up our rollup binary file, will be stored at `$HOME/go/bin`

```
cd $HOME/${CHAIN_ID}
ignite chain build
```
<SUB>Healthy output `🗃  Installed. Use with: <your_chain_name+d>`</SUB>


Create variable for binary file
```
echo 'export RBIN='\"${CHAIN_ID}d\" >> $HOME/.bash_profile
source $HOME/.bash_profile
```
Init our rollup working directory and configs
```
$RBIN init "$VAL_NAME" --chain-id $CHAIN_ID
```
<SUB>In this stage U can make any changes at your configs if U familiar to </SUB>  
<SUB>Config directory `$HOME/.${CHAIN_ID}/config`</SUB>

#### Run your Rollup

Download and launch script which will create service file and run node  
!! It will generate new wallet, seed phrase will be stored at `$HOME/key-seed.txt`
```
cd $HOME
wget -qO $HOME/rollup-launch.sh https://raw.githubusercontent.com/AlexToTheMoon/Celestia/main/rollup-launch.sh
chmod +x rollup-launch.sh
sudo ./rollup-launch.sh
```

Lets check logs 
```
sudo journalctl -u celestia-rollupd.service -fn 50 -o cat
```
We have to see blocks with rising height  
`daHeight` should reply current chain height  

<SUB>`INF successfully submitted Rollkit block to DA layer daHeight=161446 module=BlockManager rollkitHeight=1`</SUB>  
<SUB>`INF successfully submitted Rollkit block to DA layer daHeight=161471 module=BlockManager rollkitHeight=2`</SUB>  

Full screenshot of healthy logs : https://github.com/AlexToTheMoon/Celestia/blob/main/rollup-logs-png.png

<SUB>If U see loogs similar to line below, it means it not enough funds on the wallet we created during light node setup    
Because each block productions on rollup reduces  6000utia  
`ERR DA layer submission failed error="Codespace: 'sdk', Code: 5, Message: xxxxutia is smaller than 6000utia: insufficient funds`</SUB>


#### Let`s create our own query in our rollup chain!

Looks like it not necessary to stop rollup service
But it wont be worse for sure (at least it will save some funds :) )

Stop the servcie:
```
sudo systemctl stop celestia-rollupd.service
```
Create our new query module (press "y" when asking)
```
cd $CHAIN_ID
ignite scaffold query $CHAIN_ID --response TheFactIs
```
Add response text

Open file `~/$CHAIN_ID/x/$CHAIN_ID/keeper/query_$CHAIN_ID.go`  
Add respond text between curly brackets to line `return &types.QueryAmsResponse{}, nil`  
Sample : `return &types.QueryAmsResponse{TheFactIs: "Celestia will fly to the moon !!!"}, nil`  
Save file

Rebuild binary file
```
cd $HOME/$CHAIN_ID
ignite chain build
```
<SUB>Healthy output `🗃  Installed. Use with: <your_chain_name+d>`</SUB>  

#### Test our new query 

To test all request's U have to enable the API endpoint in app.toml  
U can do this manually your own  
Or just with one line command below:  
```
sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true|" $HOME/.$CHAIN_ID/config/app.toml
```

Let's launch rollupd service back working
```
sudo systemctl restart celestia-rollupd.service
```
Query through App
```
$RBIN query $CHAIN_ID $CHAIN_ID
```
Query through REST via CLI 
```
curl -s http://localhost:1317/$CHAIN_ID/$CHAIN_ID/$CHAIN_ID
```

Query through REST via web browser
Get Ur IP address 
```
hostname -i | awk '{print $2}'
```
Request in web browser, but instead of $CHAIN_ID variable should be your Chain name  
check `echo $CHAIN_ID`

http://YOUR-IP:1317/$CHAIN_ID/$CHAIN_ID/$CHAIN_ID 

All three methods should give same output
which is : **theFactIs: Celestia will fly to the moon !!!**


##
<p align="center">
 Good luck!
</p>
