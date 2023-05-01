// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create Application Insights.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param machineLearningRegistryName string

// Variables

// Resources
resource machineLearningRegistry 'Microsoft.MachineLearningServices/registries@2022-10-01-preview' = {
  name: machineLearningRegistryName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    description: 'Machine Learning Registry'
    properties: {}
    publicNetworkAccess: 'Enabled'
    regionDetails: [
      {
        acrDetails: [
          {
            systemCreatedAcrAccount: {
              acrAccountSku: 'Premium'
            }
          }
        ]
        location: location
        storageAccountDetails: [
          {
            systemCreatedStorageAccount: {
              storageAccountType: 'Standard_RAGRS'
            }
          }
        ]
      }
    ]
    tags: tags
  }
}

// Outputs
output machineLearningRegistryId string = machineLearningRegistry.id
