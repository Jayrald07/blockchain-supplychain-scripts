#!/bin/bash

ORG_NAME=$1
CA_SERVER_PORT=$2
CA_OPERATION_PORT=$3
CA_SERVER_ORDERER_PORT=$4
CA_ORDERER_OPERATION_PORT=$5
SERVER_IP=$6

mkdir -p $PWD/organizations/compose/ $PWD/organizations

echo "
version: '3.7'

networks:
  production:
    name: blockchain_network

services:

  ca_$ORG_NAME.com:
    image: hyperledger/fabric-ca:latest
    restart: always
    labels:
      service: hyperledger-fabric
    environment:
      - FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server
      - FABRIC_CA_SERVER_CA_NAME=ca-$ORG_NAME
      - FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_PORT=$CA_SERVER_PORT
      - FABRIC_CA_SERVER_OPERATIONS_LISTENADDRESS=0.0.0.0:$CA_OPERATION_PORT
      - FABRIC_CA_SERVER_CSR_HOSTS=$SERVER_IP
    ports:
      - $CA_SERVER_PORT:$CA_SERVER_PORT
      - $CA_OPERATION_PORT:$CA_OPERATION_PORT
    command: sh -c 'fabric-ca-server start -b admin:adminpw -d'
    volumes:
      - /var/lib/docker/volumes/$NODE_ID/_data/organizations/fabric-ca/$ORG_NAME.com:/etc/hyperledger/fabric-ca-server
    container_name: ca_$ORG_NAME
    networks:
      - production

  ca_orderer_$ORG_NAME.com:
    image: hyperledger/fabric-ca:latest
    restart: always
    labels:
      service: hyperledger-fabric
    environment:
      - FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server
      - FABRIC_CA_SERVER_CA_NAME=ca-orderer-$ORG_NAME
      - FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_PORT=$CA_SERVER_ORDERER_PORT
      - FABRIC_CA_SERVER_OPERATIONS_LISTENADDRESS=0.0.0.0:$CA_ORDERER_OPERATION_PORT
      - FABRIC_CA_SERVER_CSR_HOSTS=$SERVER_IP
    ports:
      - $CA_SERVER_ORDERER_PORT:$CA_SERVER_ORDERER_PORT
      - $CA_ORDERER_OPERATION_PORT:$CA_ORDERER_OPERATION_PORT
    command: sh -c 'fabric-ca-server start -b admin:adminpw -d'
    volumes:
      - /var/lib/docker/volumes/$NODE_ID/_data/organizations/fabric-ca/orderer$ORG_NAME.com:/etc/hyperledger/fabric-ca-server
    container_name: ca_orderer_$ORG_NAME
    networks:
      - production
" > $PWD/organizations/compose/ca.yaml

docker compose -f $PWD/organizations/compose/ca.yaml up -d