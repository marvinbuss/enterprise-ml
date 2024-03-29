// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a datalake.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param subnetId string
param storageName string
param privateDnsZoneIdDfs string = ''
param privateDnsZoneIdBlob string = ''
param fileSystemNames array
param purviewId string = ''
param dataLandingZoneSubscriptionIds array = []

// Variables
var storageNameCleaned = replace(storageName, '-', '')
var storagePrivateEndpointNameBlob = '${storage.name}-blob-pe'
var storagePrivateEndpointNameDfs = '${storage.name}-dfs-pe'
var synapseResourceAccessrules = [for subscriptionId in union(dataLandingZoneSubscriptionIds, array(subscription().subscriptionId)): {
  tenantId: subscription().tenantId
  resourceId: '/subscriptions/${subscriptionId}/resourceGroups/*/providers/Microsoft.Synapse/workspaces/*'
}]
var purviewResourceAccessRules = {
  tenantId: subscription().tenantId
  resourceId: purviewId
}
var machineLearningResourceAccessRules = [for subscriptionId in union(dataLandingZoneSubscriptionIds, array(subscription().subscriptionId)): {
  tenantId: subscription().tenantId
  resourceId: '/subscriptions/${subscriptionId}/resourceGroups/*/providers/Microsoft.MachineLearningServices/workspaces/*'
}]
var resourceAccessRules = empty(purviewId) ? union(synapseResourceAccessrules, machineLearningResourceAccessRules) : union(synapseResourceAccessrules, machineLearningResourceAccessRules, array(purviewResourceAccessRules))
var storageZrsRegions = [
  // Africa
  'southafricanorth'

  // Asia
  'australiaeast'
  'centralindia'
  'eastasia'
  'japaneast'
  'koreacentral'
  'southeastasia'

  // Canada
  'canadacentral'

  // Europe
  'francecentral'
  'germanywestcentral'
  'northeurope'
  'norwayeast'
  'swedencentral'
  'uksouth'
  'westeurope'

  // South America
  'brazilsouth'

  // US
  'centralus'
  'eastus'
  'eastus2'
  'southcentralus'
  'westus2'
  'westus3'
]

// Resources
resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageNameCleaned
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: contains(storageZrsRegions, location) ? 'Standard_ZRS' : 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    allowedCopyScope: 'AAD'
    allowSharedKeyAccess: false
    defaultToOAuthAuthentication: true
    dnsEndpointType: 'Standard'
    encryption: {
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: false
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
        queue: {
          enabled: true
          keyType: 'Service'
        }
        table: {
          enabled: true
          keyType: 'Service'
        }
      }
    }
    // immutableStorageWithVersioning:{
    //   enabled: false
    //   immutabilityPolicy: {
    //     state: 'Disabled'
    //     allowProtectedAppendWrites: true
    //     immutabilityPeriodSinceCreationInDays: 7
    //   }
    // }
    isHnsEnabled: true
    isLocalUserEnabled: false
    isNfsV3Enabled: false
    isSftpEnabled: false
    keyPolicy: {
      keyExpirationPeriodInDays: 7
    }
    largeFileSharesState: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'Metrics, AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
      resourceAccessRules: resourceAccessRules
    }
    // routingPreference: {  // Not supported for thsi account
    //   routingChoice: 'MicrosoftRouting'
    //   publishInternetEndpoints: false
    //   publishMicrosoftEndpoints: false
    // }
    supportsHttpsTrafficOnly: true
    // sasPolicy: {
    //   expirationAction: 'Log'
    //   sasExpirationPeriod: ''
    // }
  }
}

resource storageManagementPolicies 'Microsoft.Storage/storageAccounts/managementPolicies@2022-09-01' = {
  parent: storage
  name: 'default'
  properties: {
    policy: {
      rules: [
        {
          enabled: true
          name: 'default'
          type: 'Lifecycle'
          definition: {
            actions: {
              baseBlob: {
                // enableAutoTierToHotFromCool: true  // Not available for HNS storage yet
                tierToCool: {
                  // daysAfterLastAccessTimeGreaterThan: 90  // Not available for HNS storage yet
                  daysAfterModificationGreaterThan: 90
                }
                // tierToArchive: {  // Not available for HNS storage yet
                //   // daysAfterLastAccessTimeGreaterThan: 365  // Not available for HNS storage yet
                //   daysAfterModificationGreaterThan: 365
                // }
                // delete: {  // Uncomment, if you also want to delete assets after a certain timeframe
                //   // daysAfterLastAccessTimeGreaterThan: 730  // Not available for HNS storage yet
                //   daysAfterModificationGreaterThan: 730
                // }
              }
              snapshot: {
                tierToCool: {
                  daysAfterCreationGreaterThan: 90
                }
                // tierToArchive: {  // Not available for HNS storage yet
                //   daysAfterCreationGreaterThan: 365
                // }
                // delete: {  // Uncomment, if you also want to delete assets after a certain timeframe
                //   daysAfterCreationGreaterThan: 730
                // }
              }
              version: {
                tierToCool: {
                  daysAfterCreationGreaterThan: 90
                }
                // tierToArchive: {  // Not available for HNS storage yet
                //   daysAfterCreationGreaterThan: 365
                // }
                // delete: {  // Uncomment, if you also want to delete assets after a certain timeframe
                //   daysAfterCreationGreaterThan: 730
                // }
              }
            }
            filters: {
              blobTypes: [
                'blockBlob'
              ]
              prefixMatch: []
            }
          }
        }
      ]
    }
  }
}

resource storageBlobServices 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  parent: storage
  name: 'default'
  properties: {
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    cors: {
      corsRules: []
    }
    // automaticSnapshotPolicyEnabled: true  // Not available for HNS storage yet
    // changeFeed: {
    //   enabled: true
    //   retentionInDays: 7
    // }
    // defaultServiceVersion: ''
    // deleteRetentionPolicy: {
    //   enabled: true
    //   days: 7
    // }
    // isVersioningEnabled: true
    // lastAccessTimeTrackingPolicy: {
    //   name: 'AccessTimeTracking'
    //   enable: true
    //   blobType: [
    //     'blockBlob'
    //   ]
    //   trackingGranularityInDays: 1
    // }
    // restorePolicy: {
    //   enabled: true
    //   days: 7
    // }
  }
}

resource storageFileSystems 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = [for fileSystemName in fileSystemNames: {
  parent: storageBlobServices
  name: fileSystemName
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}]

resource storagePrivateEndpointBlob 'Microsoft.Network/privateEndpoints@2022-07-01' = {
  name: storagePrivateEndpointNameBlob
  location: location
  tags: tags
  properties: {
    applicationSecurityGroups: []
    customDnsConfigs: []
    customNetworkInterfaceName: '${storagePrivateEndpointNameBlob}-nic'
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: storagePrivateEndpointNameBlob
        properties: {
          groupIds: [
            'blob'
          ]
          privateLinkServiceId: storage.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource storagePrivateEndpointBlobARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-07-01' = if (!empty(privateDnsZoneIdBlob)) {
  parent: storagePrivateEndpointBlob
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${storagePrivateEndpointBlob.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdBlob
        }
      }
    ]
  }
}

resource storagePrivateEndpointDfs 'Microsoft.Network/privateEndpoints@2022-07-01' = {
  name: storagePrivateEndpointNameDfs
  location: location
  tags: tags
  properties: {
    applicationSecurityGroups: []
    customDnsConfigs: []
    customNetworkInterfaceName: '${storagePrivateEndpointNameDfs}-nic'
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: storagePrivateEndpointNameDfs
        properties: {
          groupIds: [
            'dfs'
          ]
          privateLinkServiceId: storage.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource storagePrivateEndpointDfsARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-07-01' = if (!empty(privateDnsZoneIdDfs)) {
  parent: storagePrivateEndpointDfs
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${storagePrivateEndpointDfs.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdDfs
        }
      }
    ]
  }
}

// Outputs
output storageId string = storage.id
output storageFileSystemIds array = [for fileSystemName in fileSystemNames: {
  storageFileSystemId: resourceId('Microsoft.Storage/storageAccounts/blobServices/containers', storageNameCleaned, 'default', fileSystemName)
}]
