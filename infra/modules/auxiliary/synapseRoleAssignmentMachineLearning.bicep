// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// The module contains a template to create a role assignment of the Synase MSI to a storage file system.
targetScope = 'resourceGroup'

// Parameters
param machineLearningId string
param synapseId string
@allowed([
  'Contributor'
])
param role string

// Variables
var machineLearningName = length(split(machineLearningId, '/')) == 9 ? last(split(machineLearningId, '/')) : 'incorrectSegmentLength'
var synapseSubscriptionId = length(split(synapseId, '/')) == 9 ? split(synapseId, '/')[2] : subscription().subscriptionId
var synapseResourceGroupName = length(split(synapseId, '/')) == 9 ? split(synapseId, '/')[4] : resourceGroup().name
var synapseName = length(split(synapseId, '/')) == 9 ? last(split(synapseId, '/')) : 'incorrectSegmentLength'
var roles = {
  Contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

// Resources
resource machineLearning 'Microsoft.MachineLearningServices/workspaces@2022-10-01' existing = {
  name: machineLearningName
}

resource synapse 'Microsoft.Synapse/workspaces@2021-06-01' existing = {
  name: synapseName
  scope: resourceGroup(synapseSubscriptionId, synapseResourceGroupName)
}

resource synapseRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(uniqueString(machineLearning.id, synapse.id, roles[role]))
  scope: machineLearning
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roles[role])
    principalId: synapse.identity.principalId
  }
}

// Outputs
