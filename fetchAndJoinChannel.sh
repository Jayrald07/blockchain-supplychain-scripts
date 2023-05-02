#!/bin/bash

ORG_NAME=$1
PEER_PORT=$2
ORDERER_GENERAL_PORT=$3
CHANNEL_ID=$4
OTHER_ORG_NAME=$5
SERVER_IP=$6
OTHER_SERVER_IP=$7

export FABRIC_CFG_PATH=$PWD/organizations/config

export ORDERER_CA=$PWD/organizations/orderer/tlsca.orderer.$OTHER_ORG_NAME.com-cert.pem
# export ORDERER_CA=$PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/tlsca/tlsca.orderer.$ORG_NAME.com-cert.pem

# export the CORE_PEER environment variable - must be the admin or org in the channel
export CORE_PEER_LOCALMSPID=$(echo $ORG_NAME)MSP
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/organizations/peerOrganizations/$(echo $ORG_NAME).com/tlsca/tlsca.$(echo $ORG_NAME).com-cert.pem
export CORE_PEER_MSPCONFIGPATH=$PWD/organizations/peerOrganizations/$(echo $ORG_NAME).com/users/Admin@$(echo $ORG_NAME).com/msp
export CORE_PEER_ADDRESS=$SERVER_IP:$PEER_PORT
export CORE_PEER_TLS_ENABLED=true

# peer channel getinfo -c $CHANNEL_ID

sleep 5s

# peer channel fetch 0 $PWD/organizations/channel-artifacts/mychannel.block -o $OTHER_SERVER_IP:$ORDERER_GENERAL_PORT --ordererTLSHostnameOverride orderer.$OTHER_ORG_NAME.com -c $CHANNEL_ID --tls --cafile $ORDERER_CA
peer channel fetch 0 $PWD/organizations/channel-artifacts/mychannel.block -o $OTHER_SERVER_IP:$ORDERER_GENERAL_PORT -c $CHANNEL_ID --tls --cafile $ORDERER_CA

sleep 2s

# # join the current org
peer channel join -b $PWD/organizations/channel-artifacts/mychannel.block