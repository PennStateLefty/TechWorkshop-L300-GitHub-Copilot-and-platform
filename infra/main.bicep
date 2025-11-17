// Main Bicep template for Zava Storefront deployment to Azure
// Orchestrates all infrastructure components for a containerized .NET application
// on App Service with monitoring and managed identity authentication

targetScope = 'resourceGroup'

// ============================================================================
// Parameters
// ============================================================================

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment name (used for resource naming)')
@minLength(2)
@maxLength(8)
param environmentName string = 'dev'

@description('Name of the container registry (must be globally unique, alphanumeric only)')
@minLength(5)
@maxLength(50)
param containerRegistryName string = 'zavacr${uniqueString(resourceGroup().id)}'

@description('Docker image URI for the App Service (format: registryname.azurecr.io/imagename:tag)')
param dockerImageUri string

@description('App Service SKU')
@allowed([
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
])
param appServiceSku string = 'B1'

@description('Log Analytics retention in days')
@minValue(7)
@maxValue(730)
param logRetentionInDays int = 30

@description('Resource tags')
param tags object = {
  environment: environmentName
  project: 'ZavaStorefront'
  createdBy: 'bicep'
}

// ============================================================================
// Variables
// ============================================================================

var resourceNamePrefix = 'zava${environmentName}'
// Resource names follow Microsoft naming conventions:
// - App Service: 1-60 chars, alphanumeric and hyphens
// - App Service Plan: 1-40 chars, alphanumeric and hyphens  
// - Log Analytics Workspace: 4-63 chars, alphanumeric and hyphens
// - Application Insights: 1-255 chars (concise recommended)
// - Managed Identity: 3-128 chars, alphanumeric, hyphens, underscores
var appInsightsName = 'appi-${resourceNamePrefix}'
var workspaceName = 'law-${resourceNamePrefix}'
var appServicePlanName = 'plan-${resourceNamePrefix}'
var appServiceName = 'app-${resourceNamePrefix}'
var managedIdentityName = 'id-${resourceNamePrefix}'

// ACR Pull role definition ID
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

// ============================================================================
// Resources
// ============================================================================

// Log Analytics Workspace for monitoring
module logAnalyticsWorkspace 'modules/log-analytics-workspace.bicep' = {
  name: 'logAnalyticsDeployment'
  params: {
    location: location
    workspaceName: workspaceName
    skuName: 'PerGB2018'
    retentionInDays: logRetentionInDays
    tags: tags
  }
}

// Application Insights for observability
module appInsights 'modules/app-insights.bicep' = {
  name: 'appInsightsDeployment'
  params: {
    location: location
    appInsightsName: appInsightsName
    applicationType: 'web'
    workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
    tags: tags
  }
}

// Container Registry for storing Docker images
module containerRegistry 'modules/container-registry.bicep' = {
  name: 'containerRegistryDeployment'
  params: {
    location: location
    registryName: containerRegistryName
    skuName: 'Basic'
    adminUserEnabled: false
    publicNetworkAccessEnabled: true
    tags: tags
  }
}

// Managed Identity for App Service authentication
module managedIdentity 'modules/managed-identity.bicep' = {
  name: 'managedIdentityDeployment'
  params: {
    location: location
    resourceName: managedIdentityName
    tags: tags
  }
}

// Role Assignment: Grant App Service managed identity AcrPull permission
module acrPullRoleAssignment 'modules/role-assignment.bicep' = {
  name: 'acrPullRoleAssignment'
  params: {
    principalId: managedIdentity.outputs.principalId
    roleDefinitionId: acrPullRoleId
    principalType: 'ServicePrincipal'
    scope: containerRegistry.outputs.resourceId
  }
}

// App Service Plan (Linux) for hosting the containerized app
module appServicePlan 'modules/app-service-plan.bicep' = {
  name: 'appServicePlanDeployment'
  params: {
    location: location
    planName: appServicePlanName
    osType: 'Linux'
    skuName: appServiceSku
    tags: tags
  }
}

// App Service hosting the containerized .NET application
module appService 'modules/app-service.bicep' = {
  name: 'appServiceDeployment'
  params: {
    location: location
    appServiceName: appServiceName
    appServicePlanId: appServicePlan.outputs.resourceId
    dockerImageUri: dockerImageUri
    dockerRegistryUrl: 'https://${containerRegistry.outputs.loginServer}'
    appInsightsConnectionString: appInsights.outputs.connectionString
    managedIdentityResourceId: managedIdentity.outputs.resourceId
    tags: tags
  }
  dependsOn: [
    acrPullRoleAssignment
  ]
}

// ============================================================================
// Outputs
// ============================================================================

@description('The Application Insights instrumentation key')
output appInsightsKey string = appInsights.outputs.instrumentationKey

@description('The Application Insights connection string')
output appInsightsConnectionString string = appInsights.outputs.connectionString

@description('The container registry login server')
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer

@description('The App Service URL')
output appServiceUrl string = appService.outputs.fqdn

@description('The App Service hostname')
output appServiceHostname string = appService.outputs.defaultHostName

@description('The managed identity resource ID')
output managedIdentityResourceId string = managedIdentity.outputs.resourceId

@description('The managed identity principal ID')
output managedIdentityPrincipalId string = managedIdentity.outputs.principalId

@description('The Log Analytics Workspace ID')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.outputs.workspaceId

@description('The deployment region')
output deploymentRegion string = location

@description('The environment name')
output environmentName string = environmentName
