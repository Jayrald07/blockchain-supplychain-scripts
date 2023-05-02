ORG_NAME=$1
PEER_PORT=$2
CHANNEL_ID=$3
ORDERER_GENERAL_PORT=$4
SERVER_IP=$5

export FABRIC_CFG_PATH=$PWD/organizations/config

export ORDERER_CA=$PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/tlsca/tlsca.orderer.$ORG_NAME.com-cert.pem

# export the CORE_PEER environment variable - must be the admin or org in the channel
export CORE_PEER_LOCALMSPID=$(echo $ORG_NAME)MSP
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/organizations/peerOrganizations/$(echo $ORG_NAME).com/tlsca/tlsca.$(echo $ORG_NAME).com-cert.pem
export CORE_PEER_MSPCONFIGPATH=$PWD/organizations/peerOrganizations/$(echo $ORG_NAME).com/users/Admin@$(echo $ORG_NAME).com/msp
export CORE_PEER_ADDRESS=localhost:$PEER_PORT
export CORE_PEER_TLS_ENABLED=true

# fetch the channel config 
peer channel fetch config $PWD/organizations/channel-artifacts/config_block.pb -o $SERVER_IP:$ORDERER_GENERAL_PORT --ordererTLSHostnameOverride orderer.$ORG_NAME.com -c $CHANNEL_ID --tls --cafile ${ORDERER_CA}
