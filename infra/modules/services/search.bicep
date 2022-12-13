// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create Azure Search.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param subnetId string
param searchName string
@allowed([
  'basic'
  'standard'
  'standard2'
  'standard2'
  'storage_optimized_l1'
  'storage_optimized_l2'
])
param searchSkuName string = 'standard'
@allowed([
  'default'
  'highDensity'
])
param searchHostingMode string = 'default'
@allowed([
  1
  2
  3
  4
  6
  12
])
param searchPartitionCount int = 1
@minValue(1)
@maxValue(12)
param searchReplicaCount int = 1
param privateDnsZoneIdSearch string = ''

// Variables
var searchPrivateEndpointName = '${search.name}-pe'

// Resources
resource search 'Microsoft.Search/searchServices@2021-04-01-preview' = {
  name: searchName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: searchSkuName
  }
  properties: {
    authOptions: {
      aadOrApiKey: {
        aadAuthFailureMode: 'http403'
      }
      apiKeyOnly: false
    }
    disableLocalAuth: true
    // disabledDataExfiltrationOptions: [
    //   'All'
    // ]
    hostingMode: searchHostingMode
    networkRuleSet: {
      ipRules: []
    }
    partitionCount: searchPartitionCount
    publicNetworkAccess: 'enabled'
    replicaCount: searchReplicaCount
    semanticSearch: 'free'
  }
}

resource searchPrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-07-01' = {
  name: searchPrivateEndpointName
  location: location
  tags: tags
  properties: {
    applicationSecurityGroups: []
    customDnsConfigs: []
    customNetworkInterfaceName: '${searchPrivateEndpointName}-nic'
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: searchPrivateEndpointName
        properties: {
          groupIds: [
            'searchService'
          ]
          privateLinkServiceId: search.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource searchPrivateEndpointARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-07-01' = if (!empty(privateDnsZoneIdSearch)) {
  parent: searchPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${searchPrivateEndpoint.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdSearch
        }
      }
    ]
  }
}

// Outputs
