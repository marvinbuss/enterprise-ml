// Licensed under the MIT license.

// This template is used to create a Purview account.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param subnetId string
param purviewName string
param privateDnsZoneIdPurview string
param privateDnsZoneIdPurviewPortal string
param privateDnsZoneIdStorageBlob string
param privateDnsZoneIdStorageQueue string
param privateDnsZoneIdEventhubNamespace string

// Variables
var purviewPrivateEndpointNamePortal = '${purview.name}-portal-pe'
var purviewPrivateEndpointNameAccount = '${purview.name}-account-pe'
var purviewPrivateEndpointNameBlob = '${purview.name}-pe-blob'  // Suffix '-blob' required for ingestion private endpoint so that these show up in the portal today
var purviewPrivateEndpointNameQueue = '${purview.name}-pe-queue'  // Suffix '-queue' required for ingestion private endpoint so that these show up in the portal today
var purviewPrivateEndpointNameNamespace = '${purview.name}-pe-namespace'  // Suffix '-namespace' required for ingestion private endpoint so that these show up in the portal today
var purviewRegions = [
  'australiaeast'
  'brazilsouth'
  'canadacentral'
  'centralindia'
  'eastus'
  'eastus2'
  'francecentral'
  'northeurope'
  'southcentralus'
  'southeastasia'
  'uksouth'
  'westcentralus'
  'westeurope'
  'westus2'
]

// Resources
resource purview 'Microsoft.Purview/accounts@2021-07-01' = {
  name: purviewName
  location: contains(purviewRegions, location) ? location : 'northeurope'
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    cloudConnectors: {}
    #disable-next-line BCP073
    friendlyName: purviewName
    managedResourceGroupName: purviewName
    publicNetworkAccess: 'Enabled'
  }
}

resource purviewPrivateEndpointPortal 'Microsoft.Network/privateEndpoints@2022-07-01' = {
  name: purviewPrivateEndpointNamePortal
  location: location
  tags: tags
  properties: {
    applicationSecurityGroups: []
    customDnsConfigs: []
    customNetworkInterfaceName: '${purviewPrivateEndpointNamePortal}-nic'
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: purviewPrivateEndpointNamePortal
        properties: {
          groupIds: [
            'portal'
          ]
          privateLinkServiceId: purview.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource purviewPrivateEndpointPortalARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-07-01' = if(!empty(privateDnsZoneIdPurviewPortal)) {
  parent: purviewPrivateEndpointPortal
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${purviewPrivateEndpointPortal.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdPurviewPortal
        }
      }
    ]
  }
}

resource purviewPrivateEndpointAccount 'Microsoft.Network/privateEndpoints@2022-07-01' = {
  name: purviewPrivateEndpointNameAccount
  location: location
  tags: tags
  properties: {
    applicationSecurityGroups: []
    customDnsConfigs: []
    customNetworkInterfaceName: '${purviewPrivateEndpointNameAccount}-nic'
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: purviewPrivateEndpointNameAccount
        properties: {
          groupIds: [
            'account'
          ]
          privateLinkServiceId: purview.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource purviewPrivateEndpointAccountARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-07-01' = if(!empty(privateDnsZoneIdPurview)) {
  parent: purviewPrivateEndpointAccount
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${purviewPrivateEndpointAccount.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdPurview
        }
      }
    ]
  }
}

resource purviewPrivateEndpointBlob 'Microsoft.Network/privateEndpoints@2022-07-01' = {
  name: purviewPrivateEndpointNameBlob
  location: location
  tags: tags
  properties: {
    applicationSecurityGroups: []
    customDnsConfigs: []
    customNetworkInterfaceName: '${purviewPrivateEndpointNameBlob}-nic'
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: purviewPrivateEndpointNameBlob
        properties: {
          groupIds: [
            'blob'
          ]
          privateLinkServiceId: purview.properties.managedResources.storageAccount
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource purviewPrivateEndpointBlobARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-07-01' = if(!empty(privateDnsZoneIdStorageBlob)) {
  parent: purviewPrivateEndpointBlob
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${purviewPrivateEndpointBlob.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdStorageBlob
        }
      }
    ]
  }
}

resource purviewPrivateEndpointQueue 'Microsoft.Network/privateEndpoints@2022-07-01' = {
  name: purviewPrivateEndpointNameQueue
  location: location
  tags: tags
  properties: {
    applicationSecurityGroups: []
    customDnsConfigs: []
    customNetworkInterfaceName: '${purviewPrivateEndpointNameQueue}-nic'
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: purviewPrivateEndpointNameQueue
        properties: {
          groupIds: [
            'queue'
          ]
          privateLinkServiceId: purview.properties.managedResources.storageAccount
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource purviewPrivateEndpointQueueARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-07-01' = if(!empty(privateDnsZoneIdStorageQueue)) {
  parent: purviewPrivateEndpointQueue
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${purviewPrivateEndpointQueue.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdStorageQueue
        }
      }
    ]
  }
}

resource purviewPrivateEndpointNamespace 'Microsoft.Network/privateEndpoints@2022-07-01' = {
  name: purviewPrivateEndpointNameNamespace
  location: location
  tags: tags
  properties: {
    applicationSecurityGroups: []
    customDnsConfigs: []
    customNetworkInterfaceName: '${purviewPrivateEndpointNameNamespace}-nic'
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: purviewPrivateEndpointNameNamespace
        properties: {
          groupIds: [
            'namespace'
          ]
          privateLinkServiceId: purview.properties.managedResources.eventHubNamespace
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource purviewPrivateEndpointNamespaceARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-07-01' = if(!empty(privateDnsZoneIdEventhubNamespace)) {
  parent: purviewPrivateEndpointNamespace
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${purviewPrivateEndpointNamespace.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdEventhubNamespace
        }
      }
    ]
  }
}

// Outputs
output purviewId string = purview.id
output purviewManagedStorageId string = purview.properties.managedResources.storageAccount
output purviewManagedEventHubId string = purview.properties.managedResources.eventHubNamespace
