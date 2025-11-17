// This module deploys an App Service Plan
// Defines the compute resources and pricing for the App Service
// Reference: https://learn.microsoft.com/en-us/azure/app-service/overview-hosting-plans

@description('Azure region for the resource')
param location string

@description('Name of the App Service Plan')
param planName string

@description('Operating system for the plan')
@allowed([
  'Windows'
  'Linux'
])
param osType string = 'Linux'

@description('SKU for the plan')
@allowed([
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1V2'
  'P2V2'
  'P3V2'
  'P1V3'
  'P2V3'
  'P3V3'
])
param skuName string = 'B1'

@description('Resource tags')
param tags object = {}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: planName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: getTier(skuName)
  }
  kind: osType == 'Windows' ? 'windows' : 'linux'
  properties: {
    reserved: osType == 'Linux'
  }
}

@description('Resource ID of the App Service Plan')
output resourceId string = appServicePlan.id

@description('App Service Plan name')
output name string = appServicePlan.name

// Helper function to determine tier from SKU name
func getTier(skuName string) string => startsWith(skuName, 'B') ? 'Basic' : startsWith(skuName, 'S') ? 'Standard' : startsWith(skuName, 'P') ? 'Premium' : 'Free'
