// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// The module contains a template to create a role assignment of the Synase MSI to a storage file system.
targetScope = 'resourceGroup'

// Parameters
param storageAccountFileSystemId string
param synapseId string
@allowed([
  'StorageBlobDataReader'
  'StorageBlobDataContributor'
  'StorageBlobDataOwner'
])
param role string

// Variables
var storageAccountFileSystemName = length(split(storageAccountFileSystemId, '/')) == 13 ? last(split(storageAccountFileSystemId, '/')) : 'incorrectSegmentLength'
var storageAccountName = length(split(storageAccountFileSystemId, '/')) == 13 ? split(storageAccountFileSystemId, '/')[8] : 'incorrectSegmentLength'
var synapseSubscriptionId = length(split(synapseId, '/')) == 9 ? split(synapseId, '/')[2] : subscription().subscriptionId
var synapseResourceGroupName = length(split(synapseId, '/')) == 9 ? split(synapseId, '/')[4] : resourceGroup().name
var synapseName = length(split(synapseId, '/')) == 9 ? last(split(synapseId, '/')) : 'incorrectSegmentLength'
var roles = {
  StorageBlobDataReader: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
  StorageBlobDataContributor: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
  StorageBlobDataOwner: 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
}

// Resources
resource storageAccountFileSystem 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' existing = {
  name: '${storageAccountName}/default/${storageAccountFileSystemName}'
}

resource synapse 'Microsoft.Synapse/workspaces@2021-06-01' existing = {
  name: synapseName
  scope: resourceGroup(synapseSubscriptionId, synapseResourceGroupName)
}

resource synapseRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(uniqueString(storageAccountFileSystem.id, synapse.id, roles[role]))
  scope: storageAccountFileSystem
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roles[role])
    principalId: synapse.identity.principalId
  }
}

// Outputs
