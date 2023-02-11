#!/bin/bash

ORG_MSP=$1
ORG_NAME=$2
PEER_PORT=$3
CHANNEL_ID=$4
ORDERER_GENERAL_PORT=$5
ORDERER_CA=/etc/hyperledger/orderer/tlsca.orderer.$ORG_MSP.com-cert.pem

export CORE_PEER_LOCALMSPID=$(echo $ORG_MSP)MSP
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/$ORG_NAME/tlsca/tlsca.$ORG_NAME-cert.pem
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/$ORG_NAME/users/Admin@$ORG_NAME/msp
export CORE_PEER_ADDRESS=localhost:$PEER_PORT
export CORE_PEER_TLS_ENABLED=true

# Create anchor peers
peer channel fetch config config_block.pb -o localhost:$ORDERER_GENERAL_PORT --ordererTLSHostnameOverride orderer.supplychain.com -c $CHANNEL_ID --tls --cafile ${ORDERER_CA}

configtxlator proto_decode --input config_block.pb --type common.Block --output config_block.json

jq .data.data[0].payload.data.config config_block.json > MSPconfig.json

jq '.channel_group.groups.Application.groups.'$(echo $ORG_MSP)'MSP.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "peer0.'$ORG_NAME'","port": '$PEER_PORT'}]},"version": "0"}}' MSPconfig.json > MSPconfigmodified_config.json

configtxlator proto_encode --input MSPconfig.json --type common.Config --output original_config.pb

configtxlator proto_encode --input MSPconfigmodified_config.json --type common.Config --output modified_config.pb

configtxlator compute_update --channel_id $CHANNEL_ID --original original_config.pb --updated modified_config.pb --output config_update.pb

configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json

echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_ID'","type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json 

configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output MSPanchors.tx

peer channel update -o localhost:$ORDERER_GENERAL_PORT --ordererTLSHostnameOverride orderer.supplychain.com -c $CHANNEL_ID -f MSPanchors.tx --tls --cafile ${ORDERER_CA}


rm *.tx *.json *.pb