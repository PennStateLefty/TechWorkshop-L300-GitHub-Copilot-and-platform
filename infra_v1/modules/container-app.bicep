@description('The location for the Container App')
param location string

@description('The name of the Container App')
param containerAppName string

@description('The ID of the Container App Environment')
param containerAppEnvironmentId string

@description('The container image to deploy')
param containerImage string

@description('The ID of the managed identity')
param managedIdentityId string

@description('The name of the Azure Container Registry')
param acrName string

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnvironmentId
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        transport: 'http'
        allowInsecure: false
      }
      registries: [
        {
          server: '${acrName}.azurecr.io'
          identity: managedIdentityId
        }
      ]
    }
    template: {
      containers: [
        {
          name: containerAppName
          image: containerImage
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Production'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
output containerAppId string = containerApp.id
