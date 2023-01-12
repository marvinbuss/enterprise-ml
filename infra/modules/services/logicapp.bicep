// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create Application Insights.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param logicAppName string
param eventGridTopicEndpoint string
param machineLearningId string

// Variables

// Resources
resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    accessControl: {}
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        EventInput: {
          splitOn: '@triggerBody()'
          type: 'ApiConnectionWebhook'
          inputs: {
            body: {
              properties: {
                destination: {
                  endpointType: 'webhook'
                  properties: {
                    endpointUrl: '@{listCallbackUrl()}'
                  }
                }
                filter: {
                  includedEventTypes: [
                    'Microsoft.MachineLearningServices.DatasetDriftDetected'
                  ]
                }
                topic: machineLearningId
              }
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureeventgrid_1\'][\'connectionId\']'
              }
            }
            path: '/subscriptions/{topicSubscriptionId}/providers/@{encodeURIComponent(\'Microsoft.MachineLearningServices.Workspaces\')}/resource/eventSubscriptions'
            queries: {
              'x-ms-api-version': '2017-09-15-preview'
            }
          }
        }
      }
      actions: {
        EventOutput: {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            body: [
              {
                data: '@triggerBody()'
                eventTime: '@triggerBody()?[\'eventTime\']'
                eventType: 'DataDrift'
                id: '@triggerBody()?[\'id\']'
                subject: '@triggerBody()?[\'subject\']'
              }
            ]
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azureeventgridpublish\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/eventGrid/api/events'
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          azureeventgrid_1: {
            connectionId: eventGridSystemTopicConnection.id
            connectionName: eventGridSystemTopicConnectionName
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/northeurope/managedApis/${eventGridSystemTopicConnectionName}'
          }
          azureeventgridpublish: {
            connectionId: eventGridTopicConnection.id
            connectionName: eventGridTopicConnectionName
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/northeurope/managedApis/${eventGridTopicConnectionName}'
          }
        }
      }
    }
  }
}

var eventGridSystemTopicConnectionName = 'azureeventgrid'
resource eventGridSystemTopicConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: eventGridSystemTopicConnectionName
  location: location
  tags: tags
  properties: {
    api: {
      brandColor: '0072c6'
      description: 'Azure Event Grid is an eventing backplane that enables event based programing with pub/sub semantics and reliable distribution & delivery for all services in Azure as well as third parties.'
      displayName: 'Azure Event Grid'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1538/1.0.1538.2619/${eventGridSystemTopicConnectionName}/icon.png'
      #disable-next-line use-resource-id-functions
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/northeurope/managedApis/${eventGridSystemTopicConnectionName}'
      name: eventGridSystemTopicConnectionName
      type: 'Microsoft.Web/locations/managedApis'
    }
    customParameterValues: {}
    displayName: 'mabuss@microsoft.com'
    nonSecretParameterValues: {
      #disable-next-line use-resource-id-functions
      'token:TenantId': subscription().tenantId
      'token:grantType': 'code'
    }
    parameterValues: {}
    statuses: [
      {
        status: 'Connected'
      }
    ]
    testLinks: []
  }
}

var eventGridTopicConnectionName = 'azureeventgridpublish'
resource eventGridTopicConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: eventGridTopicConnectionName
  location: location
  tags: tags
  properties: {
    api: {
      brandColor: '0072c6'
      description: 'Azure Event Grid Publish will publish data to any Azure Event Grid Custom Topic.'
      displayName: 'Azure Event Grid Publish'
      iconUri: 'https://connectoricons-prod.azureedge.net/releases/v1.0.1538/1.0.1538.2619/${eventGridTopicConnectionName}/icon.png'
      #disable-next-line use-resource-id-functions
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/northeurope/managedApis/${eventGridTopicConnectionName}'
      name: eventGridTopicConnectionName
      type: 'Microsoft.Web/locations/managedApis'
    }
    customParameterValues: {}
    displayName: 'entml-dev-egt001'
    nonSecretParameterValues: {
      endpoint: eventGridTopicEndpoint
    }
    parameterValues: {}
    statuses: [
      {
        status: 'Connected'
      }
    ]
    testLinks: []
  }
}

// Outputs
