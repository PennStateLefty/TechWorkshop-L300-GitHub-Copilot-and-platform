@description('The location for all resources')
param location string = 'centralus'

@description('The base name for all resources. A unique suffix will be appended.')
param baseName string = 'zavastorefront'

@description('The container image to deploy (e.g., zavastorefront<uniqueid>azurecr.io/zavastorefront:latest)')
param containerImage string

@description('A unique suffix to ensure globally unique resource names')
param uniqueSuffix string = uniqueString(resourceGroup().id)

// Azure Container Registry
module acr 'modules/container-registry.bicep' = {
  name: 'acrDeployment'
  params: {
    location: location
    registryName: '${baseName}${uniqueSuffix}'
  }
}

// Managed Identity
module identity 'modules/managed-identity.bicep' = {
  name: 'identityDeployment'
  params: {
    location: location
    identityName: 'id-${baseName}-${uniqueSuffix}'
  }
}

// Application Insights
module appInsights 'modules/app-insights.bicep' = {
  name: 'appInsightsDeployment'
  params: {
    location: location
    appInsightsName: 'ai-${baseName}-${uniqueSuffix}'
  }
}

// Role Assignment - Grant managed identity acrPull role on ACR
module roleAssignment 'modules/role-assignment.bicep' = {
  name: 'roleAssignmentDeployment'
  params: {
    principalId: identity.outputs.principalId
    acrName: acr.outputs.acrName
  }
}

// Azure Container App Environment
module containerAppEnv 'modules/container-app-environment.bicep' = {
  name: 'containerAppEnvDeployment'
  params: {
    location: location
    environmentName: 'cae-${baseName}-${uniqueSuffix}'
    appInsightsConnectionString: appInsights.outputs.connectionString
  }
}

// Azure Container App
module containerApp 'modules/container-app.bicep' = {
  name: 'containerAppDeployment'
  params: {
    location: location
    containerAppName: 'ca-${baseName}-${uniqueSuffix}'
    containerAppEnvironmentId: containerAppEnv.outputs.environmentId
    containerImage: containerImage
    managedIdentityId: identity.outputs.identityId
    acrName: acr.outputs.acrName
  }
  dependsOn: [
    roleAssignment
  ]
}

// Outputs
output acrLoginServer string = acr.outputs.loginServer
output acrName string = acr.outputs.acrName
output containerAppUrl string = containerApp.outputs.fqdn
output appInsightsConnectionString string = appInsights.outputs.connectionString
output managedIdentityPrincipalId string = identity.outputs.principalId
