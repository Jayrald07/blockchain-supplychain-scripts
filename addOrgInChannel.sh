CONFIGTX=$(mktemp -d)

# This needs configtx.yaml which should be presented in FABRIC_CFG_PATH
export FABRIC_CFG_PATH=$CONFIGTX

configtxgen -printOrg SupplierMSP > organizations/peerOrganizations/empino.distributor.com/neworg.json

# export all needed environment variables, it is okay to use the founding organization's certificates
# export ORDERE_CA

export ORDERER_CA=$PWD/../../orderer/organizations/ordererOrganizations/orderer.supplychain.com/tlsca/tlsca.orderer.supplychain.com-cert.pem

# export the CORE_PEER environment variable - must be the admin or org in the channel
export CORE_PEER_LOCALMSPID="RetailerEmpinoMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$HOME/retailer/organizations/peerOrganizations/empino.retailer.com/tlsca/tlsca.empino.retailer.com-cert.pem
export CORE_PEER_MSPCONFIGPATH=$HOME/retailer/organizations/peerOrganizations/empino.retailer.com/users/Admin@empino.retailer.com/msp
export CORE_PEER_ADDRESS=localhost:29051
export CORE_PEER_TLS_ENABLED=true

# fetch the channel config 
peer channel fetch config channel-artifacts/config_block.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.supplychain.com -c channel1 --tls --cafile ${ORDERER_CA}

# convert pb to json and extract the needed data only
configtxlator proto_decode --input channel-artifacts/config_block.pb --type common.Block --output channel-artifacts/config_block.json

jq ".data.data[0].payload.data.config" channel-artifacts/config_block.json > channel-artifacts/config.json

# append the config.json to .json and output as modified_config.json
jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"RetailerEmpinorMSP":.[1]}}}}}' channel-artifacts/config.json ./organizations/peerOrganizations/empino.supplier.com/.json > channel-artifacts/modified_config.json

# convert back the config.json to .pb
configtxlator proto_encode --input channel-artifacts/config.json --type common.Config --output channel-artifacts/config.pb

# conver the modified_config.json to .pb 
configtxlator proto_encode --input channel-artifacts/modified_config.json --type common.Config --output channel-artifacts/modified_config.pb

# calculate the delta of the two .pb generated previously and output the updated configuration 
configtxlator compute_update --channel_id channel1 --original channel-artifacts/config.pb --updated channel-artifacts/modified_config.pb --output channel-artifacts/_update.pb

# convert the _update.json to .json
configtxlator proto_decode --input channel-artifacts/_update.pb --type common.ConfigUpdate --output channel-artifacts/_update.json

# wrap it in envelope which should have the header to know it is for update
echo '{"payload":{"header":{"channel_header":{"channel_id":"channel1", "type":2}},"data":{"config_update":'$(cat _update.json)'}}}' | jq . > channel-artifacts/_update_in_envelope.json

# now, convert the  update to .pb envelope
configtxlator proto_encode --input channel-artifacts/_update_in_envelope.json --type common.Envelope --output channel-artifacts/_update_in_envelope.pb


# At this point, we will be sending a notification to joined organizations to sign each envelope.
# sign the pb envelope using org1
peer channel signconfigtx -f channel-artifacts/_update_in_envelope.pb

# switch to another org and update the channel, no need to manually sign the updated pb since it will attach to the update itself
peer channel update -f channel-artifacts/_update_in_envelope.pb -c channel1 -o localhost:7050 --ordererTLSHostnameOverride orderer.supplychain.com --tls --cafile $ORDERER_CA

# export the environment variables for new org

# export the new channel config to mychannel.block
peer channel fetch 0 channel-artifacts/mychannel.block -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com -c channel1 --tls --cafile $ORDERER_CA

# join the current org
peer channel join -b channel-artifacts/mychannel.block


# export these environment variables in peer to be leader of gossip protocol
CORE_PEER_GOSSIP_USELEADERELECTION=false
CORE_PEER_GOSSIP_ORGLEADER=true