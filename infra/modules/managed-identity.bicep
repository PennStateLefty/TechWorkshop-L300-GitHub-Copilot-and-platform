// This module deploys a User-Assigned Managed Identity
// Used by App Service for authentication to Azure resources
// Reference: https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/

@description('Azure region for the resource')
param location string

@description('Name of the resource')
param resourceName string

@description('Resource tags')
param tags object = {}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: resourceName
  location: location
  tags: tags
}

@description('The resource ID of the managed identity')
output resourceId string = userAssignedIdentity.id

@description('The principal ID of the managed identity (for RBAC assignments)')
output principalId string = userAssignedIdentity.properties.principalId

@description('The client ID of the managed identity')
output clientId string = userAssignedIdentity.properties.clientId
