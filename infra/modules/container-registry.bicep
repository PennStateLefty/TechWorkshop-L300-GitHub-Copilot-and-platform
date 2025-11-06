@description('The location for the container registry')
param location string

@description('The name of the container registry')
param registryName string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: registryName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    // Admin authentication is initially enabled for ease of setup.
    // For production, consider disabling this and relying solely on managed identity authentication.
    adminUserEnabled: true
    publicNetworkAccess: 'Enabled'
  }
}

output acrName string = containerRegistry.name
output loginServer string = containerRegistry.properties.loginServer
