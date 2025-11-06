@description('The location for the Container App Environment')
param location string

@description('The name of the Container App Environment')
param environmentName string

@description('Application Insights connection string')
@secure()
param appInsightsConnectionString string

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: environmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'azure-monitor'
    }
    daprAIConnectionString: appInsightsConnectionString
  }
}

output environmentId string = containerAppEnvironment.id
output environmentName string = containerAppEnvironment.name
