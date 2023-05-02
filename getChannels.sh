#!/bin/bash

ORG_NAME=$1
PEER_PORT=$2
SERVER_IP=$3

export FABRIC_CFG_PATH=$PWD/organizations/config
export CORE_PEER_LOCALMSPID=$(echo $ORG_NAME)MSP
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/organizations/peerOrganizations/$ORG_NAME.com/tlsca/tlsca.$ORG_NAME.com-cert.pem
export CORE_PEER_MSPCONFIGPATH=$PWD/organizations/peerOrganizations/$ORG_NAME.com/users/Admin@$ORG_NAME.com/msp
export CORE_PEER_ADDRESS=$SERVER_IP:$PEER_PORT
export CORE_PEER_TLS_ENABLED=true

echo $(peer channel list)