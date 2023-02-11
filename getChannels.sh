#!/bin/bash

MSP=$1
ORG_NAME=$2
PEER_PORT=$3

export FABRIC_CFG_PATH=$PWD/../config
export CORE_PEER_LOCALMSPID=$(echo $MSP)MSP
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/../organizations/peerOrganizations/$ORG_NAME/tlsca/tlsca.$ORG_NAME-cert.pem
export CORE_PEER_MSPCONFIGPATH=$PWD/../organizations/peerOrganizations/$ORG_NAME/users/Admin@$ORG_NAME/msp
export CORE_PEER_ADDRESS=localhost:$PEER_PORT
export CORE_PEER_TLS_ENABLED=true

echo $(peer channel list)