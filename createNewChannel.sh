#!/bin/bash

# ./scripts/createNewChannel.sh channel2 DistributorEmpino empino.distributor.com 28051

CHANNEL_ID=$1
OTHER_ORG_MSP=$2
ORG_NAME=$3
PEER_PORT=$4
ORDERER_ADMIN_PORT=$5
ORDERER_GENERAL_PORT=$6

# Define here the dynamic configtx.yaml generation

CONFIGTX=$(mktemp -d)

echo "# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

---
################################################################################
#
#   Section: Organizations
#
#   - This section defines the different organizational identities which will
#   be referenced later in the configuration.
#
################################################################################
Organizations:
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
      - orderer.$ORG_NAME.com:$ORDERER_GENERAL_PORT

  - &$(echo $ORG_NAME)MSP
    # DefaultOrg defines the organization which is used in the sampleconfig
    # of the fabric.git development environment
    Name: $(echo $ORG_NAME)MSP

    # ID to load the MSP definition as
    ID: $(echo $ORG_NAME)MSP

    MSPDir: $PWD/../organizations/peerOrganizations/$ORG_NAME.com/msp

    # Policies defines the set of policies at this level of the config tree
    # For organization policies, their canonical path is usually
    #   /Channel/<Application|Orderer>/<OrgName>/<PolicyName>
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
        Rule: \"OR('$(echo $ORG_NAME)MSP.peer')\"

################################################################################
#
#   SECTION: Capabilities
#
#   - This section defines the capabilities of fabric network. This is a new
#   concept as of v1.1.0 and should not be utilized in mixed networks with
#   v1.0.x peers and orderers.  Capabilities define features which must be
#   present in a fabric binary for that binary to safely participate in the
#   fabric network.  For instance, if a new MSP type is added, newer binaries
#   might recognize and validate the signatures from this type, while older
#   binaries without this support would be unable to validate those
#   transactions.  This could lead to different versions of the fabric binaries
#   having different world states.  Instead, defining a capability for a channel
#   informs those binaries without this capability that they must cease
#   processing transactions until they have been upgraded.  For v1.0.x if any
#   capabilities are defined (including a map with all capabilities turned off)
#   then the v1.0.x peer will deliberately crash.
#
################################################################################
Capabilities:
  # Channel capabilities apply to both the orderers and the peers and must be
  # supported by both.
  # Set the value of the capability to true to require it.
  Channel: &ChannelCapabilities
    # V2_0 capability ensures that orderers and peers behave according
    # to v2.0 channel capabilities. Orderers and peers from
    # prior releases would behave in an incompatible way, and are therefore
    # not able to participate in channels at v2.0 capability.
    # Prior to enabling V2.0 channel capabilities, ensure that all
    # orderers and peers on a channel are at v2.0.0 or later.
    V2_0: true

  # Orderer capabilities apply only to the orderers, and may be safely
  # used with prior release peers.
  # Set the value of the capability to true to require it.
  Orderer: &OrdererCapabilities
    # V2_0 orderer capability ensures that orderers behave according
    # to v2.0 orderer capabilities. Orderers from
    # prior releases would behave in an incompatible way, and are therefore
    # not able to participate in channels at v2.0 orderer capability.
    # Prior to enabling V2.0 orderer capabilities, ensure that all
    # orderers on channel are at v2.0.0 or later.
    V2_0: true

  # Application capabilities apply only to the peer network, and may be safely
  # used with prior release orderers.
  # Set the value of the capability to true to require it.
  Application: &ApplicationCapabilities
    # V2_0 application capability ensures that peers behave according
    # to v2.0 application capabilities. Peers from
    # prior releases would behave in an incompatible way, and are therefore
    # not able to participate in channels at v2.0 application capability.
    # Prior to enabling V2.0 application capabilities, ensure that all
    # peers on channel are at v2.0.0 or later.
    V2_0: true

################################################################################
#
#   SECTION: Application
#
#   - This section defines the values to encode into a config transaction or
#   genesis block for application related parameters
#
################################################################################
Application: &ApplicationDefaults
  # Organizations is the list of orgs which are defined as participants on
  # the application side of the network
  Organizations:

  # Policies defines the set of policies at this level of the config tree
  # For Application policies, their canonical path is
  #   /Channel/Application/<PolicyName>
  Policies:
    Readers:
      Type: ImplicitMeta
      Rule: \"ANY Readers\"
    Writers:
      Type: ImplicitMeta
      Rule: \"ANY Writers\"
    Admins:
      Type: ImplicitMeta
      Rule: \"MAJORITY Admins\"
    LifecycleEndorsement:
      Type: ImplicitMeta
      Rule: \"MAJORITY Endorsement\"
    Endorsement:
      Type: ImplicitMeta
      Rule: \"MAJORITY Endorsement\"

  Capabilities:
    <<: *ApplicationCapabilities
################################################################################
#
#   SECTION: Orderer
#
#   - This section defines the values to encode into a config transaction or
#   genesis block for orderer related parameters
#
################################################################################
Orderer: &OrdererDefaults # Orderer Type: The orderer implementation to start
  OrdererType: etcdraft
  # Addresses used to be the list of orderer addresses that clients and peers
  # could connect to.  However, this does not allow clients to associate orderer
  # addresses \and orderer organizations which can be useful for things such
  # as TLS validation.  The preferred way to specify orderer addresses is now
  # to include the OrdererEndpoints item in your org definition
  Addresses:
    - orderer.$ORG_NAME.com:$ORDERER_GENERAL_PORT
    # - localhost:$ORDERER_GENERAL_PORT

  EtcdRaft:
    Consenters:
      - Host: orderer.$ORG_NAME.com
        Port: $ORDERER_GENERAL_PORT
        ClientTLSCert: $PWD/../organizations/ordererOrganizations/orderer.$(echo $ORG_NAME).com/orderers/orderer.$(echo $ORG_NAME).com/tls/server.crt
        ServerTLSCert: $PWD/../organizations/ordererOrganizations/orderer.$(echo $ORG_NAME).com/orderers/orderer.$(echo $ORG_NAME).com/tls/server.crt

  # Batch Timeout: The amount of time to wait before creating a batch
  BatchTimeout: 2s

  # Batch Size: Controls the number of messages batched into a block
  BatchSize:
    # Max Message Count: The maximum number of messages to permit in a batch
    MaxMessageCount: 10

    # Absolute Max Bytes: The absolute maximum number of bytes allowed for
    # the serialized messages in a batch.
    AbsoluteMaxBytes: 99 MB

    # Preferred Max Bytes: The preferred maximum number of bytes allowed for
    # the serialized messages in a batch. A message larger than the preferred
    # max bytes will result in a batch larger than preferred max bytes.
    PreferredMaxBytes: 512 KB

  # Organizations is the list of orgs which are defined as participants on
  # the orderer side of the network
  Organizations:

  # Policies defines the set of policies at this level of the config tree
  # For Orderer policies, their canonical path is
  #   /Channel/Orderer/<PolicyName>
  Policies:
    Readers:
      Type: ImplicitMeta
      Rule: \"ANY Readers\"
    Writers:
      Type: ImplicitMeta
      Rule: \"ANY Writers\"
    Admins:
      Type: ImplicitMeta
      Rule: \"MAJORITY Admins\"
    # BlockValidation specifies what signatures must be included in the block
    # from the orderer for the peer to validate it.
    BlockValidation:
      Type: ImplicitMeta
      Rule: \"ANY Writers\"

################################################################################
#
#   CHANNEL
#
#   This section defines the values to encode into a config transaction or
#   genesis block for channel related parameters.
#
################################################################################
Channel: &ChannelDefaults
  # Policies defines the set of policies at this level of the config tree
  # For Channel policies, their canonical path is
  #   /Channel/<PolicyName>
  Policies:
    # Who may invoke the 'Deliver' API
    Readers:
      Type: ImplicitMeta
      Rule: \"ANY Readers\"
    # Who may invoke the 'Broadcast' API
    Writers:
      Type: ImplicitMeta
      Rule: \"ANY Writers\"
    # By default, who may modify elements at this config level
    Admins:
      Type: ImplicitMeta
      Rule: \"MAJORITY Admins\"

  # Capabilities describes the channel level capabilities, see the
  # dedicated Capabilities section elsewhere in this file for a full
  # description
  Capabilities:
    <<: *ChannelCapabilities

################################################################################
#
#   Profile
#
#   - Different configuration profiles may be encoded here to be specified
#   as parameters to the configtxgen tool
#
################################################################################
Profiles:
  ConnectionGenesis:
    <<: *ChannelDefaults
    Orderer:
      <<: *OrdererDefaults
      Organizations:
        - *Orderer$(echo $ORG_NAME)Org
      Capabilities: *OrdererCapabilities
    Application:
      <<: *ApplicationDefaults
      Organizations:
        - *$(echo $ORG_NAME)MSP
      Capabilities: *ApplicationCapabilities

" > $CONFIGTX/configtx.yaml

cp $PWD/../config/core.yaml $CONFIGTX/core.yaml

export FABRIC_CFG_PATH=$CONFIGTX

# Create genesis block
# It needs FABRIC_CFG_PATH which points to /config folder. It will find for configtx,yaml
configtxgen -profile ConnectionGenesis -outputBlock $PWD/../channel-artifacts/mychannel.block -channelID $CHANNEL_ID

# Join orderer on the channel
# Make sure you have the copy of orderer MSP
export ORDERER_CA=$PWD/../organizations/ordererOrganizations/orderer.$(echo $ORG_NAME).com/tlsca/tlsca.orderer.$(echo $ORG_NAME).com-cert.pem
export ORDERER_ADMIN_TLS_SIGN_CERT=$PWD/../organizations/ordererOrganizations/orderer.$(echo $ORG_NAME).com/orderers/orderer.$(echo $ORG_NAME).com/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=$PWD/../organizations/ordererOrganizations/orderer.$(echo $ORG_NAME).com/orderers/orderer.$(echo $ORG_NAME).com/tls/server.key

osnadmin channel join --channelID $CHANNEL_ID --config-block $PWD/../channel-artifacts/mychannel.block -o localhost:$ORDERER_ADMIN_PORT --ca-file ${ORDERER_CA} --client-cert ${ORDERER_ADMIN_TLS_SIGN_CERT} --client-key ${ORDERER_ADMIN_TLS_PRIVATE_KEY}

# Join peer to channel (every peer)
export CORE_PEER_LOCALMSPID=$(echo $ORG_NAME)MSP
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/../organizations/peerOrganizations/$ORG_NAME.com/tlsca/tlsca.$ORG_NAME.com-cert.pem
export CORE_PEER_MSPCONFIGPATH=$PWD/../organizations/peerOrganizations/$ORG_NAME.com/users/Admin@$ORG_NAME.com/msp
export CORE_PEER_ADDRESS=localhost:$PEER_PORT
export CORE_PEER_TLS_ENABLED=true

peer channel join -b $PWD/../channel-artifacts/mychannel.block

sleep 2s

docker exec cli.$ORG_NAME.com sh /opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/setAnchorPeer.sh $ORG_NAME $PEER_PORT $CHANNEL_ID $ORDERER_GENERAL_PORT

rm -rf $CONFIGTX/