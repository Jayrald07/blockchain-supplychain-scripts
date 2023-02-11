#!/bin/bash
MSP=$1
GENERAL=$2
ADMIN=$3
OPERATIONS=$4
mkdir -p $PWD/../organizations/ordererOrganizations/orderer.$MSP.com

# Directory where MSP or Key Materials will be stored
export FABRIC_CA_CLIENT_HOME=$PWD/../organizations/ordererOrganizations/orderer.$MSP.com

# Create Orgs and Orderer Identities
# At first, only admin are needed to be enrolled
fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca-orderer --tls.certfiles $HOME/ca/organizations/fabric-ca/ordererOrg/tls-cert.pem

echo "
version: \"3.7\"

volumes:
  orderer.$MSP.com:

networks:
  production:
    name: blockchain_network

services:
  orderer.$MSP.com:
    container_name: orderer.$MSP.com
    image: hyperledger/fabric-orderer:2.4.7
    labels:
      service: hyperledger-fabric
    environment:
      - FABRIC_LOGGING_SPEC=INFO
      - ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
      - ORDERER_GENERAL_LISTENPORT=$GENERAL
      - ORDERER_GENERAL_LOCALMSPID=OrdererMSP
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
      - ORDERER_OPERATIONS_LISTENADDRESS=orderer.$MSP.com:$OPERATIONS
      - ORDERER_METRICS_PROVIDER=prometheus
    working_dir: /root
    command: orderer
    volumes:
      - ../organizations/ordererOrganizations/orderer.$MSP.com/orderers/orderer.$MSP.com/msp:/var/hyperledger/orderer/msp
      - ../organizations/ordererOrganizations/orderer.$MSP.com/orderers/orderer.$MSP.com/tls/:/var/hyperledger/orderer/tls
      - orderer.$MSP.com:/var/hyperledger/production/orderer
    ports:
      - $GENERAL:$GENERAL
      - $ADMIN:$ADMIN
      - $OPERATIONS:$OPERATIONS
    networks:
      - production

" > $PWD/../compose/orderer-node.yaml

# Create config.yaml under the msp folder of organizations
# It includes the NodeOUs configuration
echo "NodeOUs:
  Enable: true  
  ClientOUIdentifier:    
    Certificate: cacerts/localhost-9054-ca-orderer.pem    
    OrganizationalUnitIdentifier: client  
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem    
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem   
    OrganizationalUnitIdentifier: admin  
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem    
    OrganizationalUnitIdentifier: orderer" > "$PWD/../organizations/ordererOrganizations/orderer.$MSP.com/msp/config.yaml"

mkdir -p $PWD/../organizations/ordererOrganizations/orderer.$MSP.com/msp/tlscacerts

cp $HOME/ca/organizations/fabric-ca/ordererOrg/ca-cert.pem $PWD/../organizations/ordererOrganizations/orderer.$MSP.com/msp/tlscacerts/ca.crt

mkdir -p $PWD/../organizations/ordererOrganizations/orderer.$MSP.com/tlsca
mkdir -p $PWD/../organizations/ordererOrganizations/orderer.$MSP.com/ca

cp $HOME/ca/organizations/fabric-ca/ordererOrg/ca-cert.pem $PWD/../organizations/ordererOrganizations/orderer.$MSP.com/tlsca/tlsca.orderer.$MSP.com-cert.pem

cp $HOME/ca/organizations/fabric-ca/ordererOrg/ca-cert.pem $PWD/../organizations/ordererOrganizations/orderer.$MSP.com/ca/ca.orderer.$MSP.com-cert.pem

fabric-ca-client register --caname ca-orderer --id.name ordererv7 --id.secret ordererv4pw --id.type orderer --tls.certfiles $HOME/ca/organizations/fabric-ca/ordererOrg/ca-cert.pem

fabric-ca-client register --caname ca-orderer --id.name ordererAdminv7 --id.secret ordererAdminv4pw --id.type admin --tls.certfiles $HOME/ca/organizations/fabric-ca/ordererOrg/ca-cert.pem

fabric-ca-client enroll -u https://ordererv7:ordererv4pw@localhost:9054 --caname ca-orderer -M $PWD/../organizations/ordererOrganizations/orderer.$MSP.com/orderers/orderer.$MSP.com/msp --csr.hosts orderer.$MSP.com --csr.hosts localhost --tls.certfiles $HOME/ca/organizations/fabric-ca/ordererOrg/ca-cert.pem

cp $PWD/../organizations/ordererOrganizations/orderer.$MSP.com/msp/config.yaml $PWD/../organizations/ordererOrganizations/orderer.$MSP.com/orderers/orderer.$MSP.com/msp/config.yaml

fabric-ca-client enroll -u https://ordererv7:ordererv4pw@localhost:9054 --caname ca-orderer -M $PWD/../organizations/ordererOrganizations/orderer.$MSP.com/orderers/orderer.$MSP.com/tls --enrollment.profile tls --csr.hosts orderer.$MSP.com --csr.hosts localhost --tls.certfiles $HOME/ca/organizations/fabric-ca/ordererOrg/ca-cert.pem

cp $PWD/../organizations/ordererOrganizations/orderer.$MSP.com/orderers/orderer.$MSP.com/tls/tlscacerts/* $PWD/../organizations/ordererOrganizations/orderer.$MSP.com/orderers/orderer.$MSP.com/tls/ca.crt

cp $PWD/../organizations/ordererOrganizations/orderer.$MSP.com/orderers/orderer.$MSP.com/tls/signcerts/* $PWD/../organizations/ordererOrganizations/orderer.$MSP.com/orderers/orderer.$MSP.com/tls/server.crt

cp $PWD/../organizations/ordererOrganizations/orderer.$MSP.com/orderers/orderer.$MSP.com/tls/keystore/* $PWD/../organizations/ordererOrganizations/orderer.$MSP.com/orderers/orderer.$MSP.com/tls/server.key

mkdir -p $PWD/../organizations/ordererOrganizations/orderer.$MSP.com/orderers/orderer.$MSP.com/msp/tlscacerts

cp $PWD/../organizations/ordererOrganizations/orderer.$MSP.com/orderers/orderer.$MSP.com/tls/tlscacerts/* $PWD/../organizations/ordererOrganizations/orderer.$MSP.com/orderers/orderer.$MSP.com/msp/tlscacerts/tlsca.example.com-cert.pem

fabric-ca-client enroll -u https://ordererAdminv7:ordererAdminv4pw@localhost:9054 --caname ca-orderer -M $PWD/../organizations/ordererOrganizations/orderer.$MSP.com/users/Admin@orderer.$MSP.com/msp --tls.certfiles $HOME/ca/organizations/fabric-ca/ordererOrg/ca-cert.pem

cp $PWD/../organizations/ordererOrganizations/orderer.$MSP.com/msp/config.yaml $PWD/../organizations/ordererOrganizations/orderer.$MSP.com/users/Admin@orderer.$MSP.com/msp/config.yaml

docker compose -f $PWD/../compose/orderer-node.yaml up -d