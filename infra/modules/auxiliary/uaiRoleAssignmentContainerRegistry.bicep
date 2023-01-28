// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// The module contains a template to create a role assignment of the Machine Learning MSI to a Container Registry.
targetScope = 'resourceGroup'

// Parameters
param containerRegistryId string
param userAssignedIdentityId string
@allowed([
  'AcrPull'
  'AcrPush'
  'Contributor'
])
param role string

// Variables
var containerRegistryName = length(split(containerRegistryId, '/')) == 9 ? last(split(containerRegistryId, '/')) : 'incorrectSegmentLength'
var userAssignedIdentitySubscriptionId = length(split(userAssignedIdentityId, '/')) == 9 ? split(userAssignedIdentityId, '/')[2] : subscription().subscriptionId
var userAssignedIdentityResourceGroupName = length(split(userAssignedIdentityId, '/')) == 9 ? split(userAssignedIdentityId, '/')[4] : resourceGroup().name
var userAssignedIdentityName = length(split(userAssignedIdentityId, '/')) == 9 ? last(split(userAssignedIdentityId, '/')) : 'incorrectSegmentLength'
var roles = {
  AcrPull: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
  AcrPush: '8311e382-0749-4cb8-b61a-304f252e45ec'
  Contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

// Resources
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: containerRegistryName
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: userAssignedIdentityName
  scope: resourceGroup(userAssignedIdentitySubscriptionId, userAssignedIdentityResourceGroupName)
}

resource userAssignedIdentityRoleAssignmentContainerRegistry 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(uniqueString(containerRegistry.id, userAssignedIdentity.id, roles[role]))
  scope: containerRegistry
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roles[role])
    principalId: userAssignedIdentity.properties.principalId
  }
}

// Outputs
