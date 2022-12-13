// Licensed under the MIT license.

// This template is used to create Private DNS Zones.
targetScope = 'resourceGroup'

// Parameters
param vnetId string
param tags object

// Variables
var vnetName = length(split(vnetId, '/')) >= 9 ? last(split(vnetId, '/')) : 'incorrectSegmentLength'
var privateDnsZoneNames = [
  'privatelink.api.azureml.ms'
  'privatelink.notebooks.azure.net'
  'privatelink.adf.azure.com'
  'privatelink.azurecr.io'
  'privatelink.azuresynapse.net'
  'privatelink.blob.${environment().suffixes.storage}'
  'privatelink.cognitiveservices.azure.com'
  'privatelink.datafactory.azure.net'
  'privatelink.dev.azuresynapse.net'
  'privatelink.dfs.${environment().suffixes.storage}'
  'privatelink.file.${environment().suffixes.storage}'
  'privatelink.purview.azure.com'
  'privatelink.purviewstudio.azure.com'
  'privatelink.queue.${environment().suffixes.storage}'
  'privatelink.servicebus.windows.net'
  'privatelink.search.windows.net'
  'privatelink.sql.azuresynapse.net'
  'privatelink.table.${environment().suffixes.storage}'
  'privatelink.vaultcore.azure.net'
]

// Resources
resource privateDnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' = [for item in privateDnsZoneNames: {
  name: item
  location: 'global'
  tags: tags
  properties: {}
}]

resource virtualNetworkLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for item in privateDnsZoneNames: {
  name: '${item}/${vnetName}'
  location: 'global'
  dependsOn: [
    privateDnsZones
  ]
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}]

// Outputs
output privateDnsZoneIdMachineLearningApi string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.api.azureml.ms'
output privateDnsZoneIdMachineLearningNotebooks string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.notebooks.azure.net'
output privateDnsZoneIdDataFactory string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.datafactory.azure.net'
output privateDnsZoneIdDataFactoryPortal string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.adf.azure.com'
output privateDnsZoneIdPurview string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.purview.azure.com'
output privateDnsZoneIdPurviewPortal string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.purviewstudio.azure.com'
output privateDnsZoneIdDfs string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.dfs.${environment().suffixes.storage}'
output privateDnsZoneIdBlob string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.blob.${environment().suffixes.storage}'
output privateDnsZoneIdFile string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.file.${environment().suffixes.storage}'
output privateDnsZoneIdQueue string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.queue.${environment().suffixes.storage}'
output privateDnsZoneIdTable string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.table.${environment().suffixes.storage}'
output privateDnsZoneIdNamespace string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.servicebus.windows.net'
output privateDnsZoneIdKeyVault string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net'
output privateDnsZoneIdSynapse string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.azuresynapse.net'
output privateDnsZoneIdSynapseDev string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.dev.azuresynapse.net'
output privateDnsZoneIdSynapseSql string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.sql.azuresynapse.net'
output privateDnsZoneIdCognitiveService string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.cognitiveservices.azure.com'
output privateDnsZoneIdContainerRegistry string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.azurecr.io'
output privateDnsZoneIdSearch string = '${resourceGroup().id}/providers/Microsoft.Network/privateDnsZones/privatelink.search.windows.net'
