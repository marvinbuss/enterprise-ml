// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create Application Insights.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param eventGridSystemTopicName string
param eventGridTopicName string
param machineLearningId string

// Variables

// Resources
resource eventGridSystemTopic 'Microsoft.EventGrid/systemTopics@2022-06-15' = {
  name: eventGridSystemTopicName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    source: machineLearningId
    topicType: 'Microsoft.MachineLearningServices.Workspaces'
  }
}

resource eventGridTopic 'Microsoft.EventGrid/topics@2022-06-15' = {
  name: eventGridTopicName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dataResidencyBoundary: 'WithinGeopair'
    disableLocalAuth: false
    inboundIpRules: []
    inputSchema: 'EventGridSchema'
    inputSchemaMapping: {
      inputSchemaMappingType: 'Json'
    }
    publicNetworkAccess: 'Enabled'
  }
}

// Outputs
