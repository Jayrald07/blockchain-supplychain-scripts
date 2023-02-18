#!/bin/bash

ORG_NAME=$1
OTHER_ORG_NAME=$2
PEER_PORT=$3
CHANNEL_ID=$4

CONFIGTX=$(mktemp -d)

# This needs configtx.yaml which should be presented in FABRIC_CFG_PATH
export FABRIC_CFG_PATH=$CONFIGTX

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

        MSPDir: $PWD/../organizations/peerOrganizations/$ORG_NAME.com/msp

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

cp $PWD/../config/core.yaml $CONFIGTX/core.yaml

configtxgen -printOrg $(echo $ORG_NAME)MSP > $PWD/../organizations/peerOrganizations/$(echo $ORG_NAME).com/neworg.json

# export all needed environment variables, it is okay to use the founding organization's certificates
# export ORDERE_CA

export ORDERER_CA=$PWD/../orderer/tlsca.orderer.$OTHER_ORG_NAME.com-cert.pem

# export the CORE_PEER environment variable - must be the admin or org in the channel
export CORE_PEER_LOCALMSPID=$(echo $ORG_NAME)MSP
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/../organizations/peerOrganizations/$(echo $ORG_NAME).com/tlsca/tlsca.$(echo $ORG_NAME).com-cert.pem
export CORE_PEER_MSPCONFIGPATH=$PWD/../organizations/peerOrganizations/$(echo $ORG_NAME).com/users/Admin@$(echo $ORG_NAME).com/msp
export CORE_PEER_ADDRESS=localhost:$PEER_PORT
export CORE_PEER_TLS_ENABLED=true

# fetch the channel config 
# peer channel fetch config $PWD/../channel-artifacts/config_block.pb -o localhost:$ORDERER_GENERAL_PORT --ordererTLSHostnameOverride orderer.$OTHER_ORG_NAME.com -c $CHANNEL_ID --tls --cafile ${ORDERER_CA}

# convert pb to json and extract the needed data only
configtxlator proto_decode --input $PWD/../channel-artifacts/config_block.pb --type common.Block --output $PWD/../channel-artifacts/config_block.json

jq ".data.data[0].payload.data.config" $PWD/../channel-artifacts/config_block.json > $PWD/../channel-artifacts/config.json

# append the config.json to .json and output as modified_config.json
jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {'$(echo $ORG_NAME)MSP':.[1]}}}}}' $PWD/../channel-artifacts/config.json $PWD/../organizations/peerOrganizations/$ORG_NAME.com/neworg.json > $PWD/../channel-artifacts/modified_config.json

# convert back the config.json to .pb
configtxlator proto_encode --input $PWD/../channel-artifacts/config.json --type common.Config --output $PWD/../channel-artifacts/config.pb

# conver the modified_config.json to .pb 
configtxlator proto_encode --input $PWD/../channel-artifacts/modified_config.json --type common.Config --output $PWD/../channel-artifacts/modified_config.pb

# calculate the delta of the two .pb generated previously and output the updated configuration 
configtxlator compute_update --channel_id $CHANNEL_ID --original $PWD/../channel-artifacts/config.pb --updated $PWD/../channel-artifacts/modified_config.pb --output $PWD/../channel-artifacts/_update.pb

# convert the _update.json to .json
configtxlator proto_decode --input $PWD/../channel-artifacts/_update.pb --type common.ConfigUpdate --output $PWD/../channel-artifacts/_update.json

# wrap it in envelope which should have the header to know it is for update

echo '{"payload":{"header":{"channel_header":{"channel_id":"'$(echo $CHANNEL_ID)'", "type":2}},"data":{"config_update":'$(cat $PWD/../channel-artifacts/_update.json)'}}}' | jq . > $PWD/../channel-artifacts/_update_in_envelope.json

# now, convert the  update to .pb envelope
configtxlator proto_encode --input $PWD/../channel-artifacts/_update_in_envelope.json --type common.Envelope --output $PWD/../channel-artifacts/_update_in_envelope.pb


# # At this point, we will be sending a notification to joined organizations to sign each envelope.
# # sign the pb envelope using org1
# peer channel signconfigtx -f $PWD/../channel-artifacts/_update_in_envelope.pb

# # switch to another org and update the channel, no need to manually sign the updated pb since it will attach to the update itself
# peer channel update -f $PWD/../channel-artifacts/_update_in_envelope.pb -c $CHANNEL_ID -o localhost:$ORDERER_GENERAL_PORT --ordererTLSHostnameOverride orderer.$OTHER_ORG_NAME.com --tls --cafile $ORDERER_CA

# # export the environment variables for new org

# # export the new channel config to mychannel.block
# peer channel fetch 0 $PWD/../channel-artifacts/mychannel.block -o localhost:$ORDERER_GENERAL_PORT --ordererTLSHostnameOverride orderer.$OTHER_ORG_NAME.com -c $CHANNEL_ID --tls --cafile $ORDERER_CA

# # join the current org
# peer channel join -b $PWD/../channel-artifacts/mychannel.block


# # export these environment variables in peer to be leader of gossip protocol
# CORE_PEER_GOSSIP_USELEADERELECTION=false
# CORE_PEER_GOSSIP_ORGLEADER=true