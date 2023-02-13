ORG_NAME=$1
PORT=$2
ORDERER_PORT=$3

export FABRIC_CFG_PATH=$PWD/../config

export ORDERER_CA=$PWD/../organizations/ordererOrganizations/orderer.$(echo $ORG_NAME)MSP.com/tlsca/tlsca.orderer.$(echo $ORG_NAME)MSP.com-cert.pem

# export the CORE_PEER environment variable - must be the admin or org in the channel
export CORE_PEER_LOCALMSPID=$(echo $ORG_NAME)MSP
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/../organizations/peerOrganizations/$ORG_NAME.com/tlsca/tlsca.$ORG_NAME.com-cert.pem
export CORE_PEER_MSPCONFIGPATH=$PWD/../organizations/peerOrganizations/$ORG_NAME.com/users/Admin@$ORG_NAME.com/msp
export CORE_PEER_ADDRESS=localhost:$PORT
export CORE_PEER_TLS_ENABLED=true


peer channel fetch config $PWD/../channel-artifacts/config_block.pb -o localhost:$ORDERER_PORT --ordererTLSHostnameOverride orderer.$(echo $ORG_NAME)MSP.com -c channel1 --tls --cafile ${ORDERER_CA}

# peer channel fetch 0 $PWD/../channel-artifacts/mychannel.block -o localhost:$ORDERER_PORT --ordererTLSHostnameOverride orderer.example.com -c channel1 --tls --cafile $ORDERER_CA



