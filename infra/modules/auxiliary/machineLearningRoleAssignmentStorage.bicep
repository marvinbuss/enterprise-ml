// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// The module contains a template to create a role assignment of the Machine Learning MSI to a Storage file system.
targetScope = 'resourceGroup'

// Parameters
param storageAccountFileSystemId string
param machineLearningId string
@allowed([
  'StorageBlobDataReader'
  'StorageBlobDataContributor'
  'StorageBlobDataOwner'
])
param role string

// Variables
var storageAccountFileSystemName = length(split(storageAccountFileSystemId, '/')) == 13 ? last(split(storageAccountFileSystemId, '/')) : 'incorrectSegmentLength'
var storageAccountName = length(split(storageAccountFileSystemId, '/')) == 13 ? split(storageAccountFileSystemId, '/')[8] : 'incorrectSegmentLength'
var machineLearningSubscriptionId = length(split(machineLearningId, '/')) == 9 ? split(machineLearningId, '/')[2] : subscription().subscriptionId
var machineLearningResourceGroupName = length(split(machineLearningId, '/')) == 9 ? split(machineLearningId, '/')[4] : resourceGroup().name
var machineLearningName = length(split(machineLearningId, '/')) == 9 ? last(split(machineLearningId, '/')) : 'incorrectSegmentLength'
var roles = {
  StorageBlobDataReader: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
  StorageBlobDataContributor: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
  StorageBlobDataOwner: 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
}

// Resources
resource storageAccountFileSystem 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' existing = {
  name: '${storageAccountName}/default/${storageAccountFileSystemName}'
}

resource machineLearning 'Microsoft.MachineLearningServices/workspaces@2022-10-01' existing = {
  name: machineLearningName
  scope: resourceGroup(machineLearningSubscriptionId, machineLearningResourceGroupName)
}

resource synapseRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(uniqueString(storageAccountFileSystem.id, machineLearning.id, roles[role]))
  scope: storageAccountFileSystem
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roles[role])
    principalId: machineLearning.identity.principalId
  }
}

// Outputs
