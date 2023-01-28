// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// The module contains a template to create a role assignment of the Machine Learning MSI to a Container Registry.
targetScope = 'resourceGroup'

// Parameters
param applicationInsightsId string
param userAssignedIdentityId string
@allowed([
  'Contributor'
])
param role string

// Variables
var applicationInsightsName = length(split(applicationInsightsId, '/')) == 9 ? last(split(applicationInsightsId, '/')) : 'incorrectSegmentLength'
var userAssignedIdentitySubscriptionId = length(split(userAssignedIdentityId, '/')) == 9 ? split(userAssignedIdentityId, '/')[2] : subscription().subscriptionId
var userAssignedIdentityResourceGroupName = length(split(userAssignedIdentityId, '/')) == 9 ? split(userAssignedIdentityId, '/')[4] : resourceGroup().name
var userAssignedIdentityName = length(split(userAssignedIdentityId, '/')) == 9 ? last(split(userAssignedIdentityId, '/')) : 'incorrectSegmentLength'
var roles = {
  Contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

// Resources
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: userAssignedIdentityName
  scope: resourceGroup(userAssignedIdentitySubscriptionId, userAssignedIdentityResourceGroupName)
}

resource userAssignedIdentityRoleAssignmentApplicationInsights 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(uniqueString(applicationInsights.id, userAssignedIdentity.id, roles[role]))
  scope: applicationInsights
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roles[role])
    principalId: userAssignedIdentity.properties.principalId
  }
}

// Outputs
