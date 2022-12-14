// Licensed under the MIT license.

// This template is used as a module from the main.bicep template. 
// The module contains a template to create the storage services.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
param purviewId string = ''
param privateDnsZoneIdDfs string = ''
param privateDnsZoneIdBlob string = ''

// Variables
var storage001Name = '${prefix}-lake001'

// Resources
module storage001 'services/storage.bicep' = {
  name: 'purview001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    storageName: storage001Name
    fileSystemNames: [
      'data'
    ]
    purviewId: purviewId
    dataLandingZoneSubscriptionIds: []
    privateDnsZoneIdDfs: privateDnsZoneIdDfs
    privateDnsZoneIdBlob: privateDnsZoneIdBlob
  }
}

// Outputs
output storage001Id string = storage001.outputs.storageId
output storage001FileSystemIds array = storage001.outputs.storageFileSystemIds
