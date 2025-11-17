// This module deploys Application Insights
// Provides monitoring, diagnostics, and observability for the application
// Reference: https://learn.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview

@description('Azure region for the resource')
param location string

@description('Name of the Application Insights resource')
param appInsightsName string

@description('Application type')
@allowed([
  'web'
  'ios'
  'other'
  'store'
  'java'
  'phone'
])
param applicationType string = 'web'

@description('The resource ID of the Log Analytics Workspace')
param workspaceResourceId string

@description('Resource tags')
param tags object = {}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: applicationType
    WorkspaceResourceId: workspaceResourceId
    RetentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    IngestionMode: 'LogAnalytics'
  }
}

@description('Resource ID of Application Insights')
output resourceId string = appInsights.id

@description('Instrumentation key for the application')
output instrumentationKey string = appInsights.properties.InstrumentationKey

@description('Connection string for the application')
output connectionString string = appInsights.properties.ConnectionString

@description('Application Insights name')
output name string = appInsights.name
