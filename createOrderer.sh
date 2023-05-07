#!/bin/bash

# NOTE!!!!!!!!!!!!!!!!!!!
# Make sure the permission for all folders in this current working directory is set to 777
ORG_NAME=$1
GENERAL=$2
ADMIN=$3
OPERATIONS=$4
CA_ORDERER_USERNAME=$5
CA_ORDERER_PASSWORD=$6
CA_ORDERER_PORT=$7
SERVER_IP=$8

mkdir -p $PWD/organizations/ordererOrganizations/orderer.$(echo $ORG_NAME).com


# Directory where MSP or Key Materials will be stored
export FABRIC_CA_CLIENT_HOME=$PWD/organizations/ordererOrganizations/orderer.$(echo $ORG_NAME).com

# Create Orgs and Orderer Identities
# At first, only admin are needed to be enrolled
fabric-ca-client enroll -u https://$CA_ORDERER_USERNAME:$CA_ORDERER_PASSWORD@$SERVER_IP:$CA_ORDERER_PORT --caname ca-orderer-$ORG_NAME --tls.certfiles $PWD/organizations/fabric-ca/orderer$ORG_NAME.com/tls-cert.pem

echo "
version: \"3.7\"

volumes:
  orderer.$(echo $ORG_NAME).com:

networks:
  production:
    name: blockchain_network
    driver: host

services:
  orderer.$ORG_NAME.com:
    container_name: orderer.$ORG_NAME.com
    image: hyperledger/fabric-orderer:2.4.7
    restart: always
    labels:
      service: hyperledger-fabric
    environment:
      - FABRIC_LOGGING_SPEC=INFO
      - ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
      - ORDERER_GENERAL_LISTENPORT=$GENERAL
      - ORDERER_GENERAL_LOCALMSPID=Orderer$(echo $ORG_NAME)MSP
      - ORDERER_GENERAL_LOCALMSPDIR=/var/hyperledger/orderer/msp
      # enabled TLS
      - ORDERER_GENERAL_TLS_ENABLED=true
      - ORDERER_GENERAL_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key
      - ORDERER_GENERAL_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt
      - ORDERER_GENERAL_TLS_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
      - ORDERER_GENERAL_CLUSTER_CLIENTCERTIFICATE=/var/hyperledger/orderer/tls/server.crt
      - ORDERER_GENERAL_CLUSTER_CLIENTPRIVATEKEY=/var/hyperledger/orderer/tls/server.key
      - ORDERER_GENERAL_CLUSTER_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
      - ORDERER_GENERAL_BOOTSTRAPMETHOD=none
      - ORDERER_CHANNELPARTICIPATION_ENABLED=true
      - ORDERER_ADMIN_TLS_ENABLED=true
      - ORDERER_ADMIN_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt
      - ORDERER_ADMIN_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key
      - ORDERER_ADMIN_TLS_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
      - ORDERER_ADMIN_TLS_CLIENTROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
      - ORDERER_ADMIN_LISTENADDRESS=0.0.0.0:$ADMIN
      - ORDERER_OPERATIONS_LISTENADDRESS=0.0.0.0:$OPERATIONS
      - ORDERER_METRICS_PROVIDER=prometheus
    working_dir: /root
    command: orderer
    volumes:
      - /var/lib/docker/volumes/$NODE_ID/_data/organizations/ordererOrganizations/orderer.$ORG_NAME.com/orderers/orderer.$ORG_NAME.com/msp:/var/hyperledger/orderer/msp
      - /var/lib/docker/volumes/$NODE_ID/_data/organizations/ordererOrganizations/orderer.$ORG_NAME.com/orderers/orderer.$ORG_NAME.com/tls/:/var/hyperledger/orderer/tls
      - orderer.$ORG_NAME.com:/var/hyperledger/production/orderer
    ports:
      - $GENERAL:$GENERAL
      - $ADMIN:$ADMIN
      - $OPERATIONS:$OPERATIONS
    networks:
      - production

" > $PWD/organizations/compose/orderer-node.yaml

FORMATTED_IP="$(echo $SERVER_IP | sed 's/\./-/g')"

# Create config.yaml under the msp folder of organizations
# It includes the NodeOUs configuration
echo "NodeOUs:
  Enable: true  
  ClientOUIdentifier:    
    Certificate: cacerts/$FORMATTED_IP-$CA_ORDERER_PORT-ca-orderer-$ORG_NAME.pem    
    OrganizationalUnitIdentifier: client  
  PeerOUIdentifier:
    Certificate: cacerts/$FORMATTED_IP-$CA_ORDERER_PORT-ca-orderer-$ORG_NAME.pem    
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/$FORMATTED_IP-$CA_ORDERER_PORT-ca-orderer-$ORG_NAME.pem   
    OrganizationalUnitIdentifier: admin  
  OrdererOUIdentifier:
    Certificate: cacerts/$FORMATTED_IP-$CA_ORDERER_PORT-ca-orderer-$ORG_NAME.pem    
    OrganizationalUnitIdentifier: orderer" > "$PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/msp/config.yaml"

mkdir -p $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/msp/tlscacerts

cp $PWD/organizations/fabric-ca/orderer$ORG_NAME.com/ca-cert.pem $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/msp/tlscacerts/ca.crt

mkdir -p $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/tlsca
mkdir -p $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/ca

cp $PWD/organizations/fabric-ca/orderer$ORG_NAME.com/ca-cert.pem $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/tlsca/tlsca.orderer.$ORG_NAME.com-cert.pem

cp $PWD/organizations/fabric-ca/orderer$ORG_NAME.com/ca-cert.pem $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/ca/ca.orderer.$ORG_NAME.com-cert.pem

fabric-ca-client register --caname ca-orderer-$ORG_NAME --id.name ordererv7 --id.secret ordererv4pw --id.type orderer --tls.certfiles $PWD/organizations/fabric-ca/orderer$ORG_NAME.com/ca-cert.pem

fabric-ca-client register --caname ca-orderer-$ORG_NAME --id.name ordererAdminv7 --id.secret ordererAdminv4pw --id.type admin --tls.certfiles $PWD/organizations/fabric-ca/orderer$ORG_NAME.com/ca-cert.pem

fabric-ca-client enroll -u https://ordererv7:ordererv4pw@$SERVER_IP:$CA_ORDERER_PORT --caname ca-orderer-$ORG_NAME -M $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/orderers/orderer.$ORG_NAME.com/msp --csr.hosts $SERVER_IP --csr.hosts localhost --tls.certfiles $PWD/organizations/fabric-ca/orderer$ORG_NAME.com/ca-cert.pem

cp $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/msp/config.yaml $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/orderers/orderer.$ORG_NAME.com/msp/config.yaml

fabric-ca-client enroll -u https://ordererv7:ordererv4pw@$SERVER_IP:$CA_ORDERER_PORT --caname ca-orderer-$ORG_NAME -M $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/orderers/orderer.$ORG_NAME.com/tls --enrollment.profile tls --csr.hosts $SERVER_IP --csr.hosts localhost --tls.certfiles $PWD/organizations/fabric-ca/orderer$ORG_NAME.com/ca-cert.pem

cp $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/orderers/orderer.$ORG_NAME.com/tls/tlscacerts/* $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/orderers/orderer.$ORG_NAME.com/tls/ca.crt

cp $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/orderers/orderer.$ORG_NAME.com/tls/signcerts/* $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/orderers/orderer.$ORG_NAME.com/tls/server.crt

cp $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/orderers/orderer.$ORG_NAME.com/tls/keystore/* $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/orderers/orderer.$ORG_NAME.com/tls/server.key

mkdir -p $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/orderers/orderer.$ORG_NAME.com/msp/tlscacerts

cp $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/orderers/orderer.$ORG_NAME.com/tls/tlscacerts/* $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/orderers/orderer.$ORG_NAME.com/msp/tlscacerts/tlsca.example.com-cert.pem

fabric-ca-client enroll -u https://ordererAdminv7:ordererAdminv4pw@$SERVER_IP:$CA_ORDERER_PORT --caname ca-orderer-$ORG_NAME -M $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/users/Admin@orderer.$ORG_NAME.com/msp --tls.certfiles $PWD/organizations/fabric-ca/orderer$ORG_NAME.com/ca-cert.pem

cp $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/msp/config.yaml $PWD/organizations/ordererOrganizations/orderer.$ORG_NAME.com/users/Admin@orderer.$ORG_NAME.com/msp/config.yaml

docker compose -f $PWD/organizations/compose/orderer-node.yaml up -d