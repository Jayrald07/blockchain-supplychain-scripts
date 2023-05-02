ORG_NAME=$1
CHANNEL_ID=$2
ORDERER_ADMIN_PORT=$3
SERVER_IP=$4

export ORDERER_CA=$PWD/organizations/ordererOrganizations/orderer.$(echo $ORG_NAME).com/tlsca/tlsca.orderer.$(echo $ORG_NAME).com-cert.pem
export ORDERER_ADMIN_TLS_SIGN_CERT=$PWD/organizations/ordererOrganizations/orderer.$(echo $ORG_NAME).com/orderers/orderer.$(echo $ORG_NAME).com/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=$PWD/organizations/ordererOrganizations/orderer.$(echo $ORG_NAME).com/orderers/orderer.$(echo $ORG_NAME).com/tls/server.key

osnadmin channel join --channelID $CHANNEL_ID --config-block $PWD/organizations/channel-artifacts/mychannel.block -o $SERVER_IP:$ORDERER_ADMIN_PORT --ca-file ${ORDERER_CA} --client-cert ${ORDERER_ADMIN_TLS_SIGN_CERT} --client-key ${ORDERER_ADMIN_TLS_PRIVATE_KEY}