using './main.bicep'

// ============================================================================
// Parameters for Zava Storefront deployment
// ============================================================================

param location = 'centralus'
param environmentName = 'dev'

// Container registry name - must be globally unique, lowercase alphanumeric only (5-50 characters)
// Note: Registry name will have a unique suffix appended automatically
// Avoid using 'azure', 'microsoft', or other reserved terms
param containerRegistryName = 'zavacr'

// Docker image URI - UPDATE THIS with your container image
// Format: registryname.azurecr.io/imagename:tag
// Example: zavacr12345.azurecr.io/zavastorefront:latest
param dockerImageUri = 'zavacr.azurecr.io/zavastorefront:latest'

// App Service SKU - set to B1 for small demo deployment
param appServiceSku = 'B1'

// Log retention in days
param logRetentionInDays = 30

// Resource tags
param tags = {
  environment: 'dev'
  project: 'ZavaStorefront'
  createdBy: 'bicep'
  managedBy: 'azd'
}
