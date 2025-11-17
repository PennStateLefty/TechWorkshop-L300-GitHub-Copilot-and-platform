// This module deploys an ACR Webhook
// Automatically triggers App Service deployments when images are pushed to ACR
// Reference: https://learn.microsoft.com/en-us/azure/container-registry/container-registry-webhooks

@description('Name of the container registry')
param registryName string

@description('Name of the webhook')
param webhookName string

@description('Azure region for the webhook')
param location string

@description('The App Service webhook URL endpoint for deployments')
@secure()
param appServiceWebhookUri string

@description('List of actions that trigger the webhook')
param webhookActions array = [
  'push'
]

@description('Repository scope for the webhook (e.g., zava, zavastorefront:*, or empty string for all)')
param repositoryScope string = 'zava'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  name: registryName
}

resource acrWebhook 'Microsoft.ContainerRegistry/registries/webhooks@2023-11-01-preview' = {
  parent: containerRegistry
  name: webhookName
  location: location
  properties: {
    actions: webhookActions
    serviceUri: appServiceWebhookUri
    scope: repositoryScope
    status: 'enabled'
  }
}

@description('Webhook resource ID')
output resourceId string = acrWebhook.id

@description('Webhook name')
output name string = acrWebhook.name
