#!/bin/bash

ORG_NAME=$1
OTHER_ORG_NAME=$2
PEER_PORT=$3
CHANNEL_ID=$4
ORG_TYPE=$5
ORDERER_GENERAL_PORT=$6 # PORT of new peer
SERVER_IP=$7
CONFIGTX=$(mktemp -d)

# This needs configtx.yaml which should be presented in FABRIC_CFG_PATH
export FABRIC_CFG_PATH=$CONFIGTX

createPeerConfigTx() {
echo "################################################################################
#
#   Section: Organizations
#
#   - This section defines the different organizational identities which will
#   be referenced later in the configuration.
#
################################################################################
Organizations:
    - &$(echo $ORG_NAME)MSP
        # DefaultOrg defines the organization which is used in the sampleconfig
        # of the fabric.git development environment
        Name: $(echo $ORG_NAME)MSP

        # ID to load the MSP definition as
        ID: $(echo $ORG_NAME)MSP

        MSPDir: $PWD/organizations/peerOrganizations/$ORG_NAME.com/msp

        Policies:
            Readers:
                Type: Signature
                Rule: \"OR('$(echo $ORG_NAME)MSP.admin', '$(echo $ORG_NAME)MSP.peer', '$(echo $ORG_NAME)MSP.client')\"
            Writers:
                Type: Signature
                Rule: \"OR('$(echo $ORG_NAME)MSP.admin', '$(echo $ORG_NAME)MSP.client')\"
            Admins:
                Type: Signature
                Rule: \"OR('$(echo $ORG_NAME)MSP.admin')\"
            Endorsement:
                Type: Signature
                Rule: \"OR('$(echo $ORG_NAME)MSP.peer')\"" > $CONFIGTX/configtx.yaml

configtxgen -printOrg $(echo $ORG_NAME)MSP > $PWD/organizations/peerOrganizations/$(echo $ORG_NAME).com/neworg.json

export CORE_PEER_LOCALMSPID=$(echo $ORG_NAME)MSP
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/organizations/peerOrganizations/$(echo $ORG_NAME).com/tlsca/tlsca.$(echo $ORG_NAME).com-cert.pem
export CORE_PEER_MSPCONFIGPATH=$PWD/organizations/peerOrganizations/$(echo $ORG_NAME).com/users/Admin@$(echo $ORG_NAME).com/msp
export CORE_PEER_ADDRESS=$SERVER_IP:$PEER_PORT
export CORE_PEER_TLS_ENABLED=true

export ORDERER_CA=$PWD/organizations/orderer/tlsca.orderer.$OTHER_ORG_NAME.com-cert.pem

}

createOrdererConfigTx() {
echo "Organizations:
  # SampleOrg defines an MSP using the sampleconfig.  It should never be used
  # in production but may be used as a template for other definitions
  - &Orderer$(echo $ORG_NAME)Org
    # DefaultOrg defines the organization which is used in the sampleconfig
    # of the fabric.git development environment
    Name: Orderer$(echo $ORG_NAME)Org

    # ID to load the MSP definition as
    ID: Orderer$(echo $ORG_NAME)MSP

    # MSPDir is the filesystem path which contains the MSP configuration
    MSPDir: $PWD/organizations/ordererOrganizations/orderer.$(echo $ORG_NAME).com/msp

    # Policies defines the set of policies at this level of the config tree
    # For organization policies, their canonical path is usually
    #   /Channel/<Application|Orderer>/<OrgName>/<PolicyName>
    Policies:
      Readers:
        Type: Signature
        Rule: \"OR('Orderer$(echo $ORG_NAME)MSP.member')\"
      Writers:
        Type: Signature
        Rule: \"OR('Orderer$(echo $ORG_NAME)MSP.member')\"
      Admins:
        Type: Signature
        Rule: \"OR('Orderer$(echo $ORG_NAME)MSP.admin')\"

    OrdererEndpoints:
      - $SERVER_IP:$ORDERER_GENERAL_PORT" > $CONFIGTX/configtx.yaml

configtxgen -printOrg Orderer$(echo $ORG_NAME)Org > $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/neworg.json

export CORE_PEER_LOCALMSPID=Orderer$(echo $ORG_NAME)MSP
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/organizations/ordererOrganizations/orderer.$(echo $ORG_NAME).com/orderers/orderer.$(echo $ORG_NAME).com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/organizations/ordererOrganizations/orderer.$(echo $ORG_NAME).com/users/Admin@orderer.$(echo $ORG_NAME).com/msp
export CORE_PEER_ADDRESS=$SERVER_IP:$ORDERER_GENERAL_PORT
export CORE_PEER_TLS_ENABLED=true

export ORDERER_CA=$PWD/organizations/orderer/tlsca.orderer.$OTHER_ORG_NAME.com-cert.pem

}

if [ "$ORG_TYPE" = "PEER" ]; then
    createPeerConfigTx
elif [ "$ORG_TYPE" = "ORDERER" ]; then
    createOrdererConfigTx
else
    echo "Invalid Org Type"
    exit 1
fi

cp $PWD/organizations/config/core.yaml $CONFIGTX/core.yaml

# convert pb to json and extract the needed data only
configtxlator proto_decode --input $PWD/organizations/channel-artifacts/config_block.pb --type common.Block --output $PWD/organizations/channel-artifacts/config_block.json

jq ".data.data[0].payload.data.config" $PWD/organizations/channel-artifacts/config_block.json > $PWD/organizations/channel-artifacts/config.json

addToJsonPeer() {
jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"'$ORG_NAME'MSP":.[1]}}}}}' $PWD/organizations/channel-artifacts/config.json $PWD/organizations/peerOrganizations/$ORG_NAME.com/neworg.json > $PWD/organizations/channel-artifacts/modified_config.json
}

addToJsonOrderer() {
jq -s '.[0] * {"channel_group":{"groups":{"Orderer":{"groups": {"Orderer'$(echo $ORG_NAME)'MSP":.[1]}}}}}' $PWD/organizations/channel-artifacts/config.json $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/neworg.json > $PWD/organizations/channel-artifacts/pre_modified_config.json

export CERT=`base64 $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/orderers/orderer.$ORG_NAME.com/tls/server.crt | sed ':a;N;$!ba;s/\n//g'`

cat $PWD/organizations/channel-artifacts/pre_modified_config.json | jq '.channel_group.groups.Orderer.values.ConsensusType.value.metadata.consenters += [{"client_tls_cert":"'$CERT'", "host":"'$SERVER_IP'", "port": '$ORDERER_GENERAL_PORT',"server_tls_cert":"'$CERT'"}]' > $PWD/organizations/channel-artifacts/pre_med_modified_config.json

cat $PWD/organizations/channel-artifacts/pre_med_modified_config.json | jq '.channel_group.values.OrdererAddresses.value.addresses += ["'$SERVER_IP':'$ORDERER_GENERAL_PORT'"]' > $PWD/organizations/channel-artifacts/modified_config.json

}

if [ "$ORG_TYPE" = "PEER" ]; then
    addToJsonPeer
elif [ "$ORG_TYPE" = "ORDERER" ]; then
    addToJsonOrderer
else
    echo "Invalid Org Type"
    exit 1
fi



# convert back the config.json to .pb
configtxlator proto_encode --input $PWD/organizations/channel-artifacts/config.json --type common.Config --output $PWD/organizations/channel-artifacts/config.pb

# conver the modified_config.json to .pb 
configtxlator proto_encode --input $PWD/organizations/channel-artifacts/modified_config.json --type common.Config --output $PWD/organizations/channel-artifacts/modified_config.pb

# calculate the delta of the two .pb generated previously and output the updated configuration 
configtxlator compute_update --channel_id $CHANNEL_ID --original $PWD/organizations/channel-artifacts/config.pb --updated $PWD/organizations/channel-artifacts/modified_config.pb --output $PWD/organizations/channel-artifacts/_update.pb

# convert the _update.json to .json
configtxlator proto_decode --input $PWD/organizations/channel-artifacts/_update.pb --type common.ConfigUpdate --output $PWD/organizations/channel-artifacts/_update.json

# wrap it in envelope which should have the header to know it is for update

echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_ID'", "type":2}},"data":{"config_update":'$(cat $PWD/organizations/channel-artifacts/_update.json)'}}}' | jq . > $PWD/organizations/channel-artifacts/_update_in_envelope.json

# now, convert the  update to .pb envelope
configtxlator proto_encode --input $PWD/organizations/channel-artifacts/_update_in_envelope.json --type common.Envelope --output $PWD/organizations/channel-artifacts/_update_in_envelope.pb


# # export these environment variables in peer to be leader of gossip protocol
# CORE_PEER_GOSSIP_USELEADERELECTION=false
# CORE_PEER_GOSSIP_ORGLEADER=true