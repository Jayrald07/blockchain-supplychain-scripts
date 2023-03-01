#######################################################
# THIS IS FOR CHAINCODE LIFECYCLE

ORG_NAME=$1
PEER_PORT=$2
CHANNEL_ID=$3
CHAINCODE_NAME=$4
SEQUENCE=$5
VERSION=$6
ORDERER_GENERAL_PORT=$7

export ORDERER_CA=$PWD/../organizations/ordererOrganizations/orderer.empinoretailer.com/tlsca/tlsca.orderer.$ORG_NAME.com-cert.pem
export FABRIC_CFG_PATH=$PWD/../config
export CORE_PEER_LOCALMSPID=$(echo $ORG_NAME)MSP
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/../organizations/peerOrganizations/$(echo $ORG_NAME).com/tlsca/tlsca.$(echo $ORG_NAME).com-cert.pem
export CORE_PEER_MSPCONFIGPATH=$PWD/../organizations/peerOrganizations/$(echo $ORG_NAME).com/users/Admin@$(echo $ORG_NAME).com/msp
export CORE_PEER_ADDRESS=localhost:$PEER_PORT
export CORE_PEER_TLS_ENABLED=true

# Package The Chaincode
peer lifecycle chaincode package $PWD/../mychannel.tar.gz --path $PWD/../../chaincode/chaincode --lang node --label mychannel_v$VERSION

# Install The Chaincode
peer lifecycle chaincode install $PWD/../mychannel.tar.gz

# # s of 11/19/2022
# mychannel_v1.7:cf65a4c0e94a3003a364e6ea721b57ce3c0a89a9754e030d2abb0e808b26aed1

# # Query Installed Chaincode
# peer lifecycle chaincode queryinstalled

# Approve Chaincode for ORGs
peer lifecycle chaincode approveformyorg -o localhost:$ORDERER_GENERAL_PORT --ordererTLSHostnameOverride orderer.$ORG_NAME.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_ID --name $CHAINCODE_NAME --version $VERSION --package-id $(peer lifecycle chaincode calculatepackageid $PWD/../mychannel.tar.gz) --sequence $SEQUENCE --init-required --signature-policy "AND('$(echo $ORG_NAME)MSP.member','empinodistributorMSP.member')" --collections-config $PWD/../collections_config.json

# Check Commit Readiness
peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_ID --name $CHAINCODE_NAME --version $VERSION --sequence $SEQUENCE --output json --init-required --signature-policy "AND('$(echo $ORG_NAME)MSP.member','empinodistributorMSP.member')"  --collections-config $PWD/../collections_config.json

# Commit Installed Chaincode Definition
peer lifecycle chaincode commit -o localhost:$ORDERER_GENERAL_PORT --ordererTLSHostnameOverride orderer.$ORG_NAME.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_ID --name $CHAINCODE_NAME --peerAddresses localhost:$PEER_PORT --tlsRootCertFiles "$PWD/../organizations/peerOrganizations/$ORG_NAME.com/peers/$ORG_NAME.com/tls/ca.crt" --version $VERSION --sequence $SEQUENCE --signature-policy "AND('$(echo $ORG_NAME)MSP.member','empinodistributorMSP.member')" --init-required --collections-config $PWD/../collections_config.json

# Invoke InitLedger
# Lagyan ng --isInit kapag kakacommit pa lang sa mga peers
peer chaincode invoke -o localhost:$ORDERER_GENERAL_PORT --ordererTLSHostnameOverride orderer.$ORG_NAME.com --tls --cafile $ORDERER_CA -C $CHANNEL_ID -n $CHAINCODE_NAME --peerAddresses localhost:$PEER_PORT --tlsRootCertFiles "$PWD/../organizations/peerOrganizations/$ORG_NAME.com/peers/$ORG_NAME.com/tls/ca.crt" -c '{"function":"InitLedger","Args":[]}' --isInit

# peer chaincode invoke -o localhost:$ORDERER_GENERAL_PORT --ordererTLSHostnameOverride orderer.$ORG_NAME.com --tls --cafile $ORDERER_CA -C $CHANNEL_ID -n $CHAINCODE_NAME --peerAddresses localhost:$PEER_PORT --tlsRootCertFiles "$PWD/../organizations/peerOrganizations/$ORG_NAME.com/peers/$ORG_NAME.com/tls/ca.crt" -c '{"Args":["CreateAsset","124","blue","10","jayrald"]}'

# peer chaincode invoke -o localhost:$ORDERER_GENERAL_PORT --ordererTLSHostnameOverride orderer.$ORG_NAME.com --tls --cafile $ORDERER_CA -C $CHANNEL_ID -n $CHAINCODE_NAME --peerAddresses localhost:$PEER_PORT --tlsRootCertFiles "$PWD/../organizations/peerOrganizations/$ORG_NAME.com/peers/$ORG_NAME.com/tls/ca.crt" -c '{"Args":["ReadAsset","123"]}'

# peer chaincode invoke -o localhost:$ORDERER_GENERAL_PORT --ordererTLSHostnameOverride orderer.$ORG_NAME.com --tls --cafile $ORDERER_CA -C $CHANNEL_ID -n $CHAINCODE_NAME --peerAddresses localhost:$PEER_PORT --tlsRootCertFiles "$PWD/../organizations/peerOrganizations/$ORG_NAME.com/peers/$ORG_NAME.com/tls/ca.crt" -c '{"Args":["TransferAsset","123","jayrald"]}'

# sleep 3s

# peer chaincode invoke -o localhost:$ORDERER_GENERAL_PORT --ordererTLSHostnameOverride orderer.$ORG_NAME.com --tls --cafile $ORDERER_CA -C $CHANNEL_ID -n $CHAINCODE_NAME --peerAddresses localhost:$PEER_PORT --tlsRootCertFiles "$PWD/../organizations/peerOrganizations/$ORG_NAME.com/peers/$ORG_NAME.com/tls/ca.crt" -c '{"Args":["ReadAsset","123"]}'

# sleep 3s

# export ASSET_PROPERTIES=$(echo -n "{\"assetID\":\"1234\"}" | base64 | tr -d \\n)

# peer chaincode invoke -o localhost:$ORDERER_GENERAL_PORT --ordererTLSHostnameOverride orderer.$ORG_NAME.com --tls --cafile $ORDERER_CA -C $CHANNEL_ID -n $CHAINCODE_NAME --peerAddresses localhost:$PEER_PORT --tlsRootCertFiles "$PWD/../organizations/peerOrganizations/$ORG_NAME.com/peers/$ORG_NAME.com/tls/ca.crt" -c '{"Args":["ReadAssetPrivateDetails","1234"]}' --transient "{\"asset_properties\":\"$ASSET_PROPERTIES\"}"
