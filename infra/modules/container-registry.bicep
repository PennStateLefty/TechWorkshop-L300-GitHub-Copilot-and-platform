// This module deploys an Azure Container Registry (ACR)
// Stores container images for deployment to App Service
// Reference: https://learn.microsoft.com/en-us/azure/container-registry/

@description('Azure region for the resource')
param location string

@description('Name of the container registry (must be globally unique, alphanumeric only)')
param registryName string

@description('SKU of the container registry')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param skuName string = 'Basic'

@description('Whether to enable admin user (not recommended for production)')
param adminUserEnabled bool = false

@description('Whether to disable public network access')
param publicNetworkAccessEnabled bool = true

@description('Resource tags')
param tags object = {}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  // Name: 5-50 chars, lowercase alphanumeric only. Append unique suffix to ensure global uniqueness.
  // Container Registry names must be lowercase and cannot contain hyphens or underscores
  name: toLower('${take(registryName, 37)}${take(uniqueString(resourceGroup().id), 10)}')
  location: location
  sku: {
    name: skuName
  }
  tags: tags
  properties: {
    adminUserEnabled: adminUserEnabled
    publicNetworkAccess: publicNetworkAccessEnabled ? 'Enabled' : 'Disabled'
    // Prevent anonymous pull access for security
    anonymousPullEnabled: false
  }
}

@description('Login server URL of the container registry')
output loginServer string = containerRegistry.properties.loginServer

@description('Resource ID of the container registry')
output resourceId string = containerRegistry.id

@description('Registry name')
output name string = containerRegistry.name
