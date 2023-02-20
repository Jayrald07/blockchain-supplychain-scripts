#!/bin/bash

ORG_NAME=$1
PEER_PORT=$2
CHANNEL_ID=$3
ORDERER_GENERAL_PORT=$4
OTHER_ORG_NAME=$5

export FABRIC_CFG_PATH=$PWD/../config

# export ORDERER_CA=$PWD/../organizations/ordererOrganizations/orderer.$ORG_NAME.com/tlsca/tlsca.orderer.$ORG_NAME.com-cert.pem
export ORDERER_CA=$PWD/../orderer/tlsca.orderer.$OTHER_ORG_NAME.com-cert.pem


# export CORE_PEER_LOCALMSPID=$(echo $ORG_NAME)MSP
# export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/../organizations/peerOrganizations/$ORG_NAME.com/tlsca/tlsca.$ORG_NAME.com-cert.pem
# export CORE_PEER_MSPCONFIGPATH=$PWD/../organizations/peerOrganizations/$ORG_NAME.com/users/Admin@$ORG_NAME.com/msp
# export CORE_PEER_ADDRESS=localhost:$PEER_PORT
# export CORE_PEER_TLS_ENABLED=true

export CORE_PEER_LOCALMSPID=Orderer$(echo $ORG_NAME)MSP
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/../organizations/ordererOrganizations/orderer.$(echo $ORG_NAME).com/orderers/orderer.$(echo $ORG_NAME).com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/../organizations/ordererOrganizations/orderer.$(echo $ORG_NAME).com/users/Admin@orderer.$(echo $ORG_NAME).com/msp
export CORE_PEER_ADDRESS=localhost:$ORDERER_GENERAL_PORT
export CORE_PEER_TLS_ENABLED=true

peer channel signconfigtx -f $PWD/../channel-artifacts/_update_in_envelope.pb

# peer channel update -f $PWD/../channel-artifacts/_update_in_envelope.pb -c $CHANNEL_ID -o localhost:$ORDERER_GENERAL_PORT --ordererTLSHostnameOverride orderer.$OTHER_ORG_NAME.com --tls --cafile $ORDERER_CA