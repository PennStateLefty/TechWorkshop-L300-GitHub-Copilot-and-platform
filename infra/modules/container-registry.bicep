@description('The location for the container registry')
param location string

@description('The name of the container registry')
param registryName string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: registryName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
    publicNetworkAccess: 'Enabled'
  }
}

output acrName string = containerRegistry.name
output loginServer string = containerRegistry.properties.loginServer
