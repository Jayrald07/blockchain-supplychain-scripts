ORG_NAME=$1
CHANNEL_ID=$2
ORDERER_ADMIN_PORT=$3
ORDERER_GENERAL_PORT=$4
OTHER_ORG_NAME=$5
OTHER_ORDERER_GENERAL_PORT=$6

CONFIGTX=$(mktemp -d)

# This needs configtx.yaml which should be presented in FABRIC_CFG_PATH
export FABRIC_CFG_PATH=$CONFIGTX

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
    MSPDir: $PWD/../organizations/ordererOrganizations/orderer.$(echo $ORG_NAME).com/msp

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
      - orderer.$ORG_NAME.com:$ORDERER_GENERAL_PORT" > $CONFIGTX/configtx.yaml

cp $PWD/../config/core.yaml $CONFIGTX/core.yaml

configtxgen -printOrg Orderer$(echo $ORG_NAME)Org > $PWD/../organizations/ordererOrganizations/orderer.$ORG_NAME.com/neworg.json

export ORDERER_CA=$PWD/../orderer/tlsca.orderer.$OTHER_ORG_NAME.com-cert.pem

export FABRIC_CFG_PATH=$CONFIGTX

configtxlator proto_decode --input $PWD/../channel-artifacts/config_block.pb --type common.Block --output $PWD/../channel-artifacts/config_block.json

jq ".data.data[0].payload.data.config" $PWD/../channel-artifacts/config_block.json > $PWD/../channel-artifacts/config.json

jq -s '.[0] * {"channel_group":{"groups":{"Orderer":{"groups": {"Orderer'$(echo $ORG_NAME)'Org":.[1]}}}}}' $PWD/../channel-artifacts/config.json $PWD/../organizations/ordererOrganizations/orderer.$ORG_NAME.com/neworg.json > $PWD/../organizations/ordererOrganizations/orderer.$ORG_NAME.com/config1.json

CERT=`base64 $PWD/../organizations/ordererOrganizations/orderer.$ORG_NAME.com/orderers/orderer.$ORG_NAME.com/tls/server.crt | sed ':a;N;$!ba;s/\n//g'`

cat $PWD/../organizations/ordererOrganizations/orderer.$ORG_NAME.com/config1.json | jq '.channel_group.groups.Orderer.values.ConsensusType.value.metadata.consenters += [{"client_tls_cert":"'$CERT'", "host":"orderer.'$ORG_NAME'.com", "port": '$ORDERER_GENERAL_PORT',"server_tls_cert":"'$CERT'"}]' > $PWD/../channel-artifacts/modified_config.json

configtxlator proto_encode --input $PWD/../channel-artifacts/config.json --type common.Config --output $PWD/../channel-artifacts/config.pb

configtxlator proto_encode --input $PWD/../channel-artifacts/modified_config.json --type common.Config --output $PWD/../channel-artifacts/modified_config.pb

configtxlator compute_update --channel_id $CHANNEL_ID --original $PWD/../channel-artifacts/config.pb --updated $PWD/../channel-artifacts/modified_config.pb --output $PWD/../channel-artifacts/_update.pb

configtxlator proto_decode --input $PWD/../channel-artifacts/_update.pb --type common.ConfigUpdate --output $PWD/../channel-artifacts/_update.json

echo '{"payload":{"header":{"channel_header":{"channel_id":"'$(echo $CHANNEL_ID)'", "type":2}},"data":{"config_update":'$(cat $PWD/../channel-artifacts/_update.json)'}}}' | jq . > $PWD/../channel-artifacts/_update_in_envelope.json

configtxlator proto_encode --input $PWD/../channel-artifacts/_update_in_envelope.json --type common.Envelope --output $PWD/../channel-artifacts/_update_in_envelope.pb

rm -rf $CONFIGTX

# export ORDERER_CA=$PWD/../organizations/ordererOrganizations/orderer.$(echo $ORG_NAME).com/tlsca/tlsca.orderer.$(echo $ORG_NAME).com-cert.pem
# export ORDERER_ADMIN_TLS_SIGN_CERT=$PWD/../organizations/ordererOrganizations/orderer.$(echo $ORG_NAME).com/orderers/orderer.$(echo $ORG_NAME).com/tls/server.crt
# export ORDERER_ADMIN_TLS_PRIVATE_KEY=$PWD/../organizations/ordererOrganizations/orderer.$(echo $ORG_NAME).com/orderers/orderer.$(echo $ORG_NAME).com/tls/server.key

# osnadmin channel join --channelID $CHANNEL_ID --config-block $PWD/../channel-artifacts/mychannel.block -o localhost:$ORDERER_ADMIN_PORT --ca-file ${ORDERER_CA} --client-cert ${ORDERER_ADMIN_TLS_SIGN_CERT} --client-key ${ORDERER_ADMIN_TLS_PRIVATE_KEY}