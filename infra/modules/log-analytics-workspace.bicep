// This module deploys a Log Analytics Workspace
// Stores logs and metrics for Application Insights and monitoring
// Reference: https://learn.microsoft.com/en-us/azure/azure-monitor/logs/log-analytics-workspace-overview

@description('Azure region for the resource')
param location string

@description('Name of the Log Analytics Workspace')
param workspaceName string

@description('SKU of the workspace')
@allowed([
  'PerGB2018'
  'CapacityReservation'
])
param skuName string = 'PerGB2018'

@description('Data retention in days')
@minValue(7)
@maxValue(730)
param retentionInDays int = 30

@description('Resource tags')
param tags object = {}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: skuName
    }
    retentionInDays: retentionInDays
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
  }
}

@description('Resource ID of the Log Analytics Workspace')
output resourceId string = logAnalyticsWorkspace.id

@description('Workspace ID')
output workspaceId string = logAnalyticsWorkspace.properties.customerId

@description('Workspace name')
output name string = logAnalyticsWorkspace.name
