// Licensed under the MIT license.

// This template is used to create network resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param vnetAddressPrefix string = '10.0.0.0/24'
param servicesSubnetAddressPrefix string = '10.0.0.0/27'

// Variables
var servicesSubnetName = 'ServicesSubnet'
var routeTableName = '${prefix}-routetable'
var nsgName = '${prefix}-nsg'

// Resources
resource routeTable 'Microsoft.Network/routeTables@2020-11-01' = {
  name: routeTableName
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: false
    routes: []
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: []
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: '${prefix}-vnet'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    enableDdosProtection: false
    subnets: [
      {
        name: servicesSubnetName
        properties: {
          addressPrefix: servicesSubnetAddressPrefix
          addressPrefixes: []
          networkSecurityGroup: {
            id: nsg.id
          }
          routeTable: {
            id: routeTable.id
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          serviceEndpointPolicies: []
          serviceEndpoints: []
        }
      }
    ]
  }
}

// Outputs
output vnetId string = vnet.id
output servicesSubnetId string = vnet.properties.subnets[0].id
