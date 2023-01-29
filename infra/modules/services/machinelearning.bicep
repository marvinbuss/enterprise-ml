// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a Machine Learning workspace.
targetScope = 'resourceGroup'

// Parameters
param location string
param environmentName string
param tags object
param subnetId string
param machineLearningName string
param applicationInsightsId string
param containerRegistryId string
param keyVaultId string
param storageAccountId string
param datalakeFileSystemIds array = []
param aksId string = ''
param synapseId string = ''
param synapseBigDataPoolId string = ''
param databricksWorkspaceId string = ''
param databricksWorkspaceUrl string = ''
@secure()
param databricksAccessToken string = ''
param machineLearningComputeInstance001AdministratorObjectId string = ''
@secure()
param machineLearningComputeInstance001AdministratorPublicSshKey string = ''
param machineLearningComputeInstance002AdministratorObjectId string = ''
@secure()
param machineLearningComputeInstance002AdministratorPublicSshKey string = ''
param privateDnsZoneIdMachineLearningApi string = ''
param privateDnsZoneIdMachineLearningNotebooks string = ''
param userAssignedIdentityId string

// Variables
var machineLearningPrivateEndpointName = '${machineLearning.name}-pe'
var containerBuildComputeName = 'cpucluster001'
var noPublicIpRegions = [
  'australiaeast'
  'eastasia'
  'japaneast'
  'japanwest'
  'francecentral'
  'northeurope'
  'westeurope'
  'centralus'
  'eastus'
  'eastus2'
  'northcentralus'
  'southcentralus'
  'westcentralus'
  'westus'
  'westus2'
]

var storageAccountName = length(split(storageAccountId, '/')) == 9 ? split(storageAccountId, '/')[8] : 'incorrectSegmentLength'

// Existng resources
resource storage001 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

// Resources
resource machineLearning 'Microsoft.MachineLearningServices/workspaces@2022-10-01' = {
  name: machineLearningName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    allowPublicAccessWhenBehindVnet: true
    description: machineLearningName
    #disable-next-line BCP035
    encryption: {
      status: 'Disabled'
    }
    friendlyName: machineLearningName
    hbiWorkspace: true
    imageBuildCompute: containerBuildComputeName
    primaryUserAssignedIdentity: userAssignedIdentityId
    publicNetworkAccess: 'Enabled'
    // serviceManagedResourcesSettings: {
    //   cosmosDb: {
    //     collectionsThroughput: 400
    //   }
    // }
    v1LegacyMode: false
    applicationInsights: applicationInsightsId
    containerRegistry: containerRegistryId
    keyVault: keyVaultId
    storageAccount: storage001.id
  }
}

resource machineLearningKubernetes001 'Microsoft.MachineLearningServices/workspaces/computes@2022-10-01' = if (!empty(aksId)) {
  parent: machineLearning
  name: 'kubernetes001'
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    computeType: 'AKS'
    resourceId: aksId
  }
}

resource machineLearningDatabricks001 'Microsoft.MachineLearningServices/workspaces/computes@2022-10-01' = if (!empty(databricksWorkspaceId) && !empty(databricksWorkspaceUrl) && !empty(databricksAccessToken)) {
  parent: machineLearning
  name: 'databricks001'
  location: location
  tags: tags
  properties: {
    computeType: 'Databricks'
    computeLocation: location
    description: 'Databricks workspace connection'
    disableLocalAuth: true
    properties: {
      databricksAccessToken: databricksAccessToken
      workspaceUrl: databricksWorkspaceUrl
    }
    resourceId: databricksWorkspaceId
  }
}

resource machineLearningSynapse001 'Microsoft.MachineLearningServices/workspaces/linkedServices@2020-09-01-preview' = if (!empty(synapseId)) {
  parent: machineLearning
  name: 'synapse001'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    linkedServiceResourceId: synapseId
    linkType: 'Synapse'
  }
}

resource machineLearningSynapse001BigDataPool001 'Microsoft.MachineLearningServices/workspaces/computes@2022-10-01' = if (!empty(synapseId) && !empty(synapseBigDataPoolId)) {
  parent: machineLearning
  name: 'bigdatapool001'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn: [
    machineLearningSynapse001
  ]
  properties: {
    computeType: 'SynapseSpark'
    computeLocation: location
    description: 'Synapse workspace - Spark Pool'
    disableLocalAuth: true
    resourceId: synapseBigDataPoolId
  }
}

resource machineLearningCpuCluster001 'Microsoft.MachineLearningServices/workspaces/computes@2022-10-01' = {
  parent: machineLearning
  name: containerBuildComputeName
  dependsOn: [
    machineLearningPrivateEndpoint
    machineLearningPrivateEndpointARecord
  ]
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    computeType: 'AmlCompute'
    computeLocation: location
    description: 'Machine Learning cluster 001'
    disableLocalAuth: true
    properties: {
      enableNodePublicIp: contains(noPublicIpRegions, location) ? false : true
      isolatedNetwork: false
      osType: 'Linux'
      remoteLoginPortPublicAccess: 'Disabled'
      scaleSettings: {
        minNodeCount: 0
        maxNodeCount: 4
        nodeIdleTimeBeforeScaleDown: 'PT120S'
      }
      subnet: {
        id: subnetId
      }
      vmPriority: 'Dedicated'
      vmSize: 'Standard_DS3_v2'
    }
  }
}

resource machineLearningGpuCluster001 'Microsoft.MachineLearningServices/workspaces/computes@2022-10-01' = {
  parent: machineLearning
  name: 'gpucluster001'
  dependsOn: [
    machineLearningPrivateEndpoint
    machineLearningPrivateEndpointARecord
  ]
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    computeType: 'AmlCompute'
    computeLocation: location
    description: 'Machine Learning cluster 001'
    disableLocalAuth: true
    properties: {
      enableNodePublicIp: contains(noPublicIpRegions, location) ? false : true
      isolatedNetwork: false
      osType: 'Linux'
      remoteLoginPortPublicAccess: 'Disabled'
      scaleSettings: {
        minNodeCount: 0
        maxNodeCount: 4
        nodeIdleTimeBeforeScaleDown: 'PT120S'
      }
      subnet: {
        id: subnetId
      }
      vmPriority: 'Dedicated'
      vmSize: 'Standard_NC6'
    }
  }
}

resource machineLearningComputeInstance001 'Microsoft.MachineLearningServices/workspaces/computes@2022-10-01' = if (!empty(machineLearningComputeInstance001AdministratorObjectId)) {
  parent: machineLearning
  name: 'computeinstance001'
  dependsOn: [
    machineLearningPrivateEndpoint
    machineLearningPrivateEndpointARecord
  ]
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    computeType: 'ComputeInstance'
    computeLocation: location
    description: 'Machine Learning compute instance 001'
    disableLocalAuth: true
    properties: {
      applicationSharingPolicy: 'Personal'
      computeInstanceAuthorizationType: 'personal'
      enableNodePublicIp: contains(noPublicIpRegions, location) ? false : true
      #disable-next-line BCP037
      isolatedNetwork: false
      personalComputeInstanceSettings: {
        assignedUser: {
          objectId: machineLearningComputeInstance001AdministratorObjectId
          tenantId: subscription().tenantId
        }
      }
      // setupScripts: {
      //   scripts: {
      //     creationScript: {}
      //     startupScript: {}
      //   }
      // }
      sshSettings: {
        adminPublicKey: machineLearningComputeInstance001AdministratorPublicSshKey
        sshPublicAccess: empty(machineLearningComputeInstance001AdministratorPublicSshKey) ? 'Disabled' : 'Enabled'
      }
      subnet: {
        id: subnetId
      }
      vmSize: 'Standard_DS3_v2'
    }
  }
}

resource machineLearningComputeInstance003 'Microsoft.MachineLearningServices/workspaces/computes@2022-10-01' = if (!empty(machineLearningComputeInstance002AdministratorObjectId)) {
  parent: machineLearning
  name: 'computeinstance003'
  dependsOn: [
    machineLearningPrivateEndpoint
    machineLearningPrivateEndpointARecord
  ]
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    computeType: 'ComputeInstance'
    computeLocation: location
    description: 'Machine Learning compute instance 002'
    disableLocalAuth: true
    properties: {
      applicationSharingPolicy: 'Personal'
      computeInstanceAuthorizationType: 'personal'
      enableNodePublicIp: contains(noPublicIpRegions, location) ? false : true
      #disable-next-line BCP037
      isolatedNetwork: false
      personalComputeInstanceSettings: {
        assignedUser: {
          objectId: machineLearningComputeInstance002AdministratorObjectId
          tenantId: subscription().tenantId
        }
      }
      // setupScripts: {
      //   scripts: {
      //     creationScript: {}
      //     startupScript: {}
      //   }
      // }
      sshSettings: {
        adminPublicKey: machineLearningComputeInstance002AdministratorPublicSshKey
        sshPublicAccess: empty(machineLearningComputeInstance002AdministratorPublicSshKey) ? 'Disabled' : 'Enabled'
      }
      subnet: {
        id: subnetId
      }
      vmSize: 'Standard_DS3_v2'
    }
  }
}

// resource machineLearningDefaultBlobStorage 'Microsoft.MachineLearningServices/workspaces/datastores@2022-10-01' = {
//   parent: machineLearning
//   name: 'workspaceblobstore'
//   properties: {
//     datastoreType: 'AzureBlob'
//     credentials: {
//       credentialsType: 'AccountKey'
//       secrets: {
//         secretsType: 'AccountKey'
//         key: storage001.listKeys().keys[0].value
//       }
//     }
//     accountName: storage001.name
//     containerName: 'default'
//     description: 'Default blob storage for AML.'
//     endpoint: environment().suffixes.storage
//     protocol: 'https'
//     serviceDataAccessAuthIdentity: 'WorkspaceSystemAssignedIdentity'
//   }
// }

// resource machineLearningDefaultFileStorage 'Microsoft.MachineLearningServices/workspaces/datastores@2022-10-01' = {
//   parent: machineLearning
//   name: 'workspacefilestore'
//   properties: {
//     datastoreType: 'AzureFile'
//     credentials: {
//       credentialsType: 'AccountKey'
//       secrets: {
//         secretsType: 'AccountKey'
//         key: storage001.listKeys().keys[0].value
//       }
//     }
//     accountName: storage001.name
//     fileShareName: 'azureml-filestore'
//     description: 'Default file storage for AML.'
//     endpoint: environment().suffixes.storage
//     protocol: 'https'
//     serviceDataAccessAuthIdentity: 'None'
//   }
// }

resource machineLearningDatalakes 'Microsoft.MachineLearningServices/workspaces/datastores@2022-10-01' = [for (datalakeFileSystemId, i) in datalakeFileSystemIds : if(length(split(datalakeFileSystemId, '/')) == 13) {
  parent: machineLearning
  name: '${length(datalakeFileSystemIds) <= 0 ? 'undefined${i}' : split(datalakeFileSystemId, '/')[8]}${length(datalakeFileSystemIds) <= 0 ? 'undefined${i}' : last(split(datalakeFileSystemId, '/'))}'
  properties: {
    datastoreType: 'AzureDataLakeGen2'
    tags: tags
    accountName: split(datalakeFileSystemId, '/')[8]
    filesystem: last(split(datalakeFileSystemId, '/'))
    endpoint: environment().suffixes.storage
    protocol: 'https'
    serviceDataAccessAuthIdentity: 'WorkspaceSystemAssignedIdentity'
    credentials: {
      credentialsType: 'None'
    }
  }
}]

resource machineLearningOnlineEndpoint 'Microsoft.MachineLearningServices/workspaces/onlineEndpoints@2022-10-01' = {
  parent: machineLearning
  name: 'online-endpoint-diabetes-${environmentName}'
  location: location
  tags: {
    AllowlistedObjectIds: machineLearningComputeInstance001AdministratorObjectId
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    authMode: 'AMLToken'  // 'AADToken'
    description: 'An online endpoint for scoring diabetes data.'
    publicNetworkAccess: 'Enabled'
  }
}

resource machineLearningPrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-07-01' = {
  name: machineLearningPrivateEndpointName
  location: location
  tags: tags
  properties: {
    applicationSecurityGroups: []
    customDnsConfigs: []
    customNetworkInterfaceName: '${machineLearningPrivateEndpointName}-nic'
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: machineLearningPrivateEndpointName
        properties: {
          groupIds: [
            'amlworkspace'
          ]
          privateLinkServiceId: machineLearning.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource machineLearningPrivateEndpointARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-07-01' = if (!empty(privateDnsZoneIdMachineLearningApi) && !empty(privateDnsZoneIdMachineLearningNotebooks)) {
  parent: machineLearningPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${machineLearningPrivateEndpoint.name}-api-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdMachineLearningApi
        }
      }
      {
        name: '${machineLearningPrivateEndpoint.name}-notebooks-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdMachineLearningNotebooks
        }
      }
    ]
  }
}

// Outputs
output machineLearningId string = machineLearning.id
