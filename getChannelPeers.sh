#!/bin/bash

CHANNEL_ID=$1
ORDERER_PEER_PORT=$2
ORG_NAME=$3
PEER_PORT=$4

export FABRIC_CFG_PATH=$PWD/../organizations/config

export CORE_PEER_LOCALMSPID=$(echo $ORG_NAME)MSP
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/../organizations/peerOrganizations/$ORG_NAME.com/tlsca/tlsca.$ORG_NAME.com-cert.pem
export CORE_PEER_MSPCONFIGPATH=$PWD/../organizations/peerOrganizations/$ORG_NAME.com/users/Admin@$ORG_NAME.com/msp
export CORE_PEER_ADDRESS=localhost:$PEER_PORT
export CORE_PEER_TLS_ENABLED=true


export ORDERER_CA=$PWD/../organizations/ordererOrganizations/orderer.$ORG_NAME.com/tlsca/tlsca.orderer.$ORG_NAME.com-cert.pem

peer channel getinfo -o localhost:$ORDERER_PEER_PORT --tls --cafile $ORDERER_CA -c $CHANNEL_ID
