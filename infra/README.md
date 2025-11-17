# Zava Storefront Infrastructure

This directory contains the Infrastructure-as-Code (IaC) for deploying the Zava Storefront application to Azure using Bicep and the Azure Developer CLI (azd).

## Architecture Overview

The infrastructure deploys a containerized .NET application with the following components:

### Core Resources
- **App Service** (B1 SKU): Hosts the containerized web application
- **App Service Plan** (Linux): Provides compute resources for the App Service
- **Azure Container Registry**: Stores and manages container images
- **Managed Identity**: Provides secure authentication without hardcoded credentials
- **Application Insights**: Monitors application performance and logs
- **Log Analytics Workspace**: Centralized logging and analytics

### Security Features
- Managed Identity for App Service with role-based access control (RBAC)
- AcrPull role assignment for secure container image retrieval
- HTTPS enforced with TLS 1.2 minimum
- No admin user enabled on Container Registry
- Anonymous pull access disabled on Container Registry

### Monitoring & Observability
- Application Insights with connection to Log Analytics
- Automatic instrumentation for .NET application
- 30-day log retention (configurable)
- Health monitoring and alerting capability

## Prerequisites

1. **Azure CLI**: [Install Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
2. **Azure Developer CLI (azd)**: [Install azd](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd)
3. **Docker**: [Install Docker](https://docs.docker.com/get-docker/) (for building and testing images locally)
4. **Bicep CLI**: Usually included with Azure CLI, but can be installed separately if needed

## Quick Start

### 1. Prepare Your Environment

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription <your-subscription-id>

# Create a resource group (if not using azd to manage it)
az group create --name zava-rg --location eastus
```

### 2. Update Parameters

Edit `main.bicepparam` to configure:

```bicep
param location = 'eastus'                          # Change to your preferred region
param containerRegistryName = 'zavastorefront'     # Must be globally unique
param dockerImageUri = 'your-registry.azurecr.io/zavastorefront:latest'  # Your image URI
param appServiceSku = 'B1'                         # B1 for demo, S1+ for production
```

### 3. Deploy Using Azure Developer CLI (Recommended)

```bash
# Initialize the project (if not already done)
azd init

# Provision and deploy infrastructure
azd up

# Or just provision infrastructure
azd provision

# Deploy the application
azd deploy
```

### 4. Deploy Using Bicep CLI (Alternative)

```bash
# Validate the template
az bicep build --file infra/main.bicep

# Preview changes
az deployment group what-if \
  --resource-group zava-rg \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam

# Deploy the infrastructure
az deployment group create \
  --resource-group zava-rg \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
```

## File Structure

```
infra/
├── main.bicep                    # Main orchestration template
├── main.bicepparam               # Parameters file with defaults
├── modules/                      # Reusable Bicep modules
│   ├── managed-identity.bicep    # User-assigned managed identity
│   ├── container-registry.bicep  # Azure Container Registry
│   ├── log-analytics-workspace.bicep  # Log Analytics for monitoring
│   ├── app-insights.bicep        # Application Insights component
│   ├── app-service-plan.bicep    # App Service Plan
│   ├── app-service.bicep         # App Service web app
│   └── role-assignment.bicep     # RBAC role assignments
└── README.md                     # This file
```

## Module Descriptions

### managed-identity.bicep
Creates a user-assigned managed identity for the App Service to authenticate with Azure resources without storing credentials.

**Outputs:**
- `resourceId`: Full resource ID of the managed identity
- `principalId`: Object ID for RBAC assignments
- `clientId`: Client ID for application configuration

### container-registry.bicep
Deploys an Azure Container Registry (ACR) to store container images with security best practices applied.

**Features:**
- Basic SKU for demo (cost-effective)
- Anonymous pull disabled for security
- Admin user disabled (use managed identity instead)

**Outputs:**
- `loginServer`: URL for docker login and push operations
- `resourceId`: Full resource ID

### log-analytics-workspace.bicep
Creates a Log Analytics Workspace that serves as the backend for Application Insights monitoring.

**Outputs:**
- `resourceId`: Full resource ID
- `workspaceId`: Workspace ID for Application Insights integration

### app-insights.bicep
Deploys Application Insights connected to the Log Analytics Workspace for application monitoring.

**Features:**
- Integrated with Log Analytics
- 30-day data retention
- Automatic dependency tracking

**Outputs:**
- `instrumentationKey`: For SDK configuration
- `connectionString`: Modern connection string format

### app-service-plan.bicep
Creates an App Service Plan on Linux to host the containerized application.

**Features:**
- B1 SKU for small demo deployments
- Linux OS for cost efficiency with .NET 6
- Configurable to larger SKUs (S1, S2, S3, P1v2, etc.)

### app-service.bicep
Deploys the App Service web application with Docker container support.

**Features:**
- Linux container support
- System-assigned managed identity integration
- HTTPS enforced with TLS 1.2 minimum
- Application Insights instrumentation
- GitHub CI/CD integration capability
- Automatic Docker settings configuration

### role-assignment.bicep
Creates RBAC role assignments to grant the managed identity specific permissions.

**Features:**
- AcrPull role for container image access
- Scoped to resource group or specific resource
- Support for multiple principal types

## Deployment Scenarios

### Demo/Development Deployment
Uses the B1 (free tier) App Service SKU for minimal cost:

```bash
azd up --parameter appServiceSku=B1
```

### Production Deployment
Uses S1 SKU with higher performance:

```bash
azd up --parameter appServiceSku=S1
```

### Custom Region
Deploy to a different Azure region:

```bash
azd up --parameter location=westeurope
```

## GitHub Integration for CI/CD

To enable continuous deployment from GitHub:

1. Update `main.bicepparam` with your GitHub repository:
   ```bicep
   param gitHubRepoUrl = 'https://github.com/your-org/your-repo'
   param gitHubBranch = 'main'
   ```

2. Deploy or redeploy:
   ```bash
   azd up
   ```

3. Configure GitHub Actions to push your Docker image to the container registry

## Post-Deployment Configuration

### 1. Build and Push Container Image
```bash
# Build the Docker image
docker build -t zavastorefront:latest -f Dockerfile .

# Tag for registry
docker tag zavastorefront:latest <your-registry>.azurecr.io/zavastorefront:latest

# Login to registry
az acr login --name <your-registry>

# Push image
docker push <your-registry>.azurecr.io/zavastorefront:latest
```

### 2. Configure App Service to Use Image
The App Service will automatically pull the image you specified in `dockerImageUri` during deployment. To update:

```bash
az webapp config container set \
  --name zava-dev-app \
  --resource-group zava-rg \
  --docker-custom-image-name <your-registry>.azurecr.io/zavastorefront:latest \
  --docker-registry-server-url https://<your-registry>.azurecr.io \
  --docker-registry-server-username <username> \
  --docker-registry-server-password <password>
```

### 3. Verify Deployment
```bash
# Get the App Service URL
az webapp show --name zava-dev-app --resource-group zava-rg --query defaultHostName

# Check Application Insights
az monitor app-insights component show --app zava-dev-appinsights --resource-group zava-rg
```

## Monitoring & Troubleshooting

### View Application Logs
```bash
# Stream logs from App Service
az webapp log tail --name zava-dev-app --resource-group zava-rg
```

### Check Application Insights
```bash
# View top operations
az monitor app-insights events show --app zava-dev-appinsights --resource-group zava-rg
```

### Container Registry Operations
```bash
# List repositories
az acr repository list --name zavastorefront

# List tags in a repository
az acr repository show-tags --name zavastorefront --repository zavastorefront
```

## Scaling

### Vertical Scaling (Larger SKU)
```bash
az appservice plan update \
  --name zava-dev-plan \
  --resource-group zava-rg \
  --sku S1
```

### Horizontal Scaling (More Instances)
```bash
az appservice plan update \
  --name zava-dev-plan \
  --resource-group zava-rg \
  --number-of-workers 2
```

## Cost Optimization

The current configuration uses the B1 (free tier) App Service SKU, which is ideal for demos and development. For production:

1. **App Service Plan**: Consider S1 or higher for production workloads
2. **Container Registry**: Basic SKU is sufficient for most use cases
3. **Application Insights**: Standard ingestion with 30-day retention
4. **Log Analytics**: Standard SKU with 30-day retention

## Security Best Practices Implemented

✅ Managed Identity for authentication (no hardcoded credentials)  
✅ RBAC with least-privilege principle (AcrPull only)  
✅ HTTPS/TLS 1.2 enforced  
✅ Anonymous container pull disabled  
✅ Admin user disabled on Container Registry  
✅ Application Insights for security monitoring  
✅ Log retention for audit trails  

## Troubleshooting

### Docker Image Not Found
```bash
# Verify image exists in registry
az acr repository show --name <registry> --repository zavastorefront

# Check App Service Docker settings
az webapp config container show --name zava-dev-app --resource-group zava-rg
```

### Container Fails to Start
1. Check Application Insights for runtime errors
2. Verify port 8080 is exposed in Dockerfile
3. Ensure ASPNETCORE_URLS environment variable is set
4. Check App Service logs: `az webapp log tail --name zava-dev-app --resource-group zava-rg`

### Managed Identity Permissions Issue
```bash
# Verify role assignment
az role assignment list --assignee <principal-id> --resource-group zava-rg
```

## References

- [Azure Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure App Service Documentation](https://learn.microsoft.com/en-us/azure/app-service/)
- [Container Registry Best Practices](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-best-practices)
- [Managed Identity Documentation](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/)
- [Azure Developer CLI Documentation](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/)

## Support

For issues with:
- **Bicep syntax**: Check the [Bicep documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- **Azure resources**: Review [Azure documentation](https://learn.microsoft.com/en-us/azure/)
- **Azure CLI**: Run `az <command> --help`
- **Azure Developer CLI**: Run `azd help`

## Contributing

When updating the infrastructure:

1. Test changes locally with `az bicep build`
2. Use `az deployment group what-if` before deploying
3. Update this README if adding new resources or parameters
4. Follow Bicep best practices as documented in the main template
