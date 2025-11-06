# Deploy to Azure - Infrastructure as Code

## Objective
Create the necessary infrastructure-as-code to deploy the ZavaStorefront application to Microsoft Azure using containerization and Azure Container Apps.

## Requirements

### 1. Containerization
- Create a `Dockerfile` for the .NET 6 ASP.NET Core application
- Ensure the Dockerfile follows best practices for multi-stage builds to optimize image size
- The application source is in the `src/` directory

### 2. Azure Container Registry (ACR)
- Create an Azure Container Registry to host the container image
- Initially configure with basic (admin) authentication enabled
- Registry should be in the Central US region
- Name should follow Azure naming conventions (e.g., `zavastorefront<uniqueid>azurecr.io`)

### 3. Azure Container Apps
- Deploy the container image to Azure Container Apps
- Service should run in the Central US region
- Configure to pull images from the container registry

### 4. Azure Application Insights
- Set up Application Insights for observability and monitoring
- Integrate with the Container App for telemetry collection
- Located in Central US region

### 5. Managed Identity & Security
- Create a managed identity for the Container App
- Grant the managed identity `acrPull` role on the Container Registry
- This enables secure image pulls without basic authentication credentials
- Prepare for future transition from basic auth to managed identity authentication

### 6. Resource Organization
- Create an Azure Resource Group as the parent container
- All resources should be deployed within this resource group
- Resource Group should be in Central US region
- Suggested naming pattern: `rg-zavastorefront-prod` or similar

## Infrastructure Specification

### Resource Details
- **Region**: Central US
- **.NET Version**: 6.0 (ASP.NET Core)
- **Application Port**: Review `launchSettings.json` to determine correct port configuration
- **Container Image**: Should be based on official Microsoft .NET images

### Azure Services to Deploy
1. Resource Group (central US)
2. Azure Container Registry
3. Azure Container Apps
4. Azure Application Insights
5. Managed Identity

## Deliverables
- [ ] `Dockerfile` - Complete container definition
- [ ] Infrastructure as Code (Bicep or Terraform) for:
  - Resource Group
  - Container Registry with admin auth enabled
  - Managed Identity
  - Role assignment (acrPull on ACR)
  - Container App with Application Insights integration
  - Application Insights resource
- [ ] Documentation on how to deploy the infrastructure
- [ ] Instructions for building and pushing the container image to ACR

## Additional Notes
- The application uses MVC pattern with Views and Controllers
- Ensure proper environment variable configuration for the Container App
- Consider security best practices for storing credentials and connection strings
- Managed identity setup enables future secure authentication without storing credentials
