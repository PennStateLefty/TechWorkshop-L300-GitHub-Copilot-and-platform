// This module deploys an App Service (Web App)
// Hosts the containerized .NET application
// Reference: https://learn.microsoft.com/en-us/azure/app-service/

@description('Azure region for the resource')
param location string

@description('Name of the App Service')
param appServiceName string

@description('Resource ID of the App Service Plan')
param appServicePlanId string

@description('Docker image URI (e.g., myregistry.azurecr.io/image:tag)')
param dockerImageUri string

@description('Docker registry URL')
param dockerRegistryUrl string

@description('Connection string from Application Insights')
param appInsightsConnectionString string

@description('The resource ID of the user-assigned managed identity')
param managedIdentityResourceId string

@description('Resource tags')
param tags object = {}

resource appService 'Microsoft.Web/sites@2023-12-01' = {
  name: appServiceName
  location: location
  tags: tags
  kind: 'app,linux,container'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityResourceId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${dockerImageUri}'
      alwaysOn: false
      http20Enabled: true
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      appCommandLine: ''
      numberOfWorkers: 1
      // Application settings
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: dockerRegistryUrl
        }
        {
          name: 'DOCKER_ENABLE_CI'
          value: 'true'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'recommended'
        }
      ]
    }
  }
}

@description('Resource ID of the App Service')
output resourceId string = appService.id

@description('Default hostname of the App Service')
output defaultHostName string = appService.properties.defaultHostName

@description('FQDN of the App Service')
output fqdn string = 'https://${appService.properties.defaultHostName}'

@description('App Service name')
output name string = appService.name
