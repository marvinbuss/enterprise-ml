// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// The module contains a template to create a role assignment of the Machine Learning MSI to a Container Registry.
targetScope = 'resourceGroup'

// Parameters
param containerRegistryId string
param machineLearningId string
@allowed([
  'AcrPull'
])
param role string

// Variables
var containerRegistryName = length(split(containerRegistryId, '/')) == 9 ? last(split(containerRegistryId, '/')) : 'incorrectSegmentLength'
var machineLearningSubscriptionId = length(split(machineLearningId, '/')) == 9 ? split(machineLearningId, '/')[2] : subscription().subscriptionId
var machineLearningResourceGroupName = length(split(machineLearningId, '/')) == 9 ? split(machineLearningId, '/')[4] : resourceGroup().name
var machineLearningName = length(split(machineLearningId, '/')) == 9 ? last(split(machineLearningId, '/')) : 'incorrectSegmentLength'
var roles = {
  AcrPull: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
}

// Resources
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: containerRegistryName
}

resource machineLearning 'Microsoft.MachineLearningServices/workspaces@2022-10-01' existing = {
  name: machineLearningName
  scope: resourceGroup(machineLearningSubscriptionId, machineLearningResourceGroupName)
}

resource synapseRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(uniqueString(containerRegistry.id, machineLearning.id, roles[role]))
  scope: containerRegistry
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roles[role])
    principalId: machineLearning.identity.principalId
  }
}

// Outputs
