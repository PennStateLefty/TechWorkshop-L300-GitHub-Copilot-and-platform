# Infrastructure Deployment Summary

## What Was Created

A complete, production-ready Infrastructure-as-Code solution for the Zava Storefront application using Azure Bicep and the Azure Developer CLI (azd).

## Directory Structure

```
infra/
├── main.bicep                          # Main orchestration template
├── main.bicepparam                     # Parameters with sensible defaults
├── modules/
│   ├── app-insights.bicep              # Application Insights monitoring
│   ├── app-service.bicep               # Web app hosting container
│   ├── app-service-plan.bicep          # Compute resources
│   ├── container-registry.bicep        # Image storage
│   ├── log-analytics-workspace.bicep   # Centralized logging
│   ├── managed-identity.bicep          # Secure authentication
│   └── role-assignment.bicep           # RBAC permissions
├── README.md                           # Comprehensive deployment guide
└── (this file)

azure.yaml                              # Azure Developer CLI configuration
```

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Azure Resource Group                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              App Service (B1 SKU - Free Tier)            │   │
│  │  ├─ Docker Container (zavastorefront:latest)            │   │
│  │  ├─ Managed Identity (user-assigned)                    │   │
│  │  └─ HTTPS enforced (TLS 1.2+)                           │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                    │
│                    Pulls Docker Images                            │
│                              │                                    │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │         Azure Container Registry (Basic SKU)             │   │
│  │  ├─ zavastorefront:latest                               │   │
│  │  ├─ Anonymous pull: Disabled                            │   │
│  │  └─ Admin user: Disabled                                │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                    │
│                    Sends Logs & Metrics                           │
│                              │                                    │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │           Application Insights (Monitoring)              │   │
│  │           ↓                                              │   │
│  │       Log Analytics Workspace (30-day retention)        │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Key Features

### ✅ Security
- **Managed Identity**: No hardcoded credentials - App Service uses system-assigned identity
- **RBAC**: AcrPull role grants least-privilege ACR access
- **TLS 1.2+**: HTTPS enforced on all connections
- **Registry Security**: Anonymous pull disabled, admin user disabled
- **Network**: Optional GitHub integration for CI/CD

### ✅ Observability
- **Application Insights**: Automatic instrumentation of .NET application
- **Log Analytics**: Centralized log collection and analysis
- **30-Day Retention**: Configurable log retention for audit trails
- **Built-in Monitoring**: Health checks and performance metrics

### ✅ Best Practices
- **Modular Design**: Each resource in its own reusable Bicep module
- **Parameterized**: All values configurable without editing templates
- **Named Outputs**: Clear output values for post-deployment configuration
- **Comments**: Comprehensive documentation in each module
- **Latest API Versions**: Using 2023-12-01 or later API versions

### ✅ Cost Optimization
- **B1 (Free) App Service SKU**: Perfect for demo deployments
- **Basic Container Registry SKU**: Cost-effective for individual images
- **Standard Log Analytics SKU**: Good balance of features and cost
- **Configurable**: Easy to scale up for production

### ✅ Deployment Options
- **Azure Developer CLI (azd)**: One-command deployment and management
- **Bicep CLI**: Direct `az deployment` commands
- **Azure Portal**: Manual deployment via ARM templates
- **GitHub Actions**: Ready for CI/CD integration

## Quick Start Guide

### 1. Prerequisites
```bash
# Install Azure CLI
# Install Azure Developer CLI (azd)
# Install Docker (for local testing)

# Login to Azure
az login
```

### 2. Configure Parameters
Edit `infra/main.bicepparam`:
- Set your preferred region (default: eastus)
- Update container registry name (must be globally unique)
- Set your Docker image URI
- (Optional) Add GitHub repository URL

### 3. Deploy
```bash
# Option A: Using Azure Developer CLI (Recommended)
azd up

# Option B: Using Bicep CLI
az deployment group create \
  --resource-group zava-rg \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
```

### 4. Post-Deployment
```bash
# Build and push your Docker image
docker build -t zavastorefront:latest -f Dockerfile .
az acr login --name <your-registry>
docker tag zavastorefront:latest <registry>.azurecr.io/zavastorefront:latest
docker push <registry>.azurecr.io/zavastorefront:latest

# Access your application
# URL will be output after deployment (e.g., https://zava-dev-app.azurewebsites.net)
```

## Environment Variables

The App Service is pre-configured with:
- `APPLICATIONINSIGHTS_CONNECTION_STRING`: Automatically set from App Insights
- `DOCKER_REGISTRY_SERVER_URL`: ACR login server URL
- `DOCKER_ENABLE_CI`: Enables continuous deployment

## Outputs After Deployment

The deployment will output:
- `appInsightsConnectionString`: Connection string for app code
- `containerRegistryLoginServer`: ACR login URL for pushing images
- `appServiceUrl`: HTTPS URL of your deployed application
- `managedIdentityPrincipalId`: For additional RBAC assignments
- `logAnalyticsWorkspaceId`: For custom queries and dashboards

## GitHub CI/CD Setup

To enable automatic deployments from GitHub:

1. Update `main.bicepparam`:
   ```bicep
   param gitHubRepoUrl = 'https://github.com/your-org/repo'
   ```

2. In your GitHub Actions workflow:
   ```yaml
   - name: Push to ACR
     run: |
       az acr login --name zavastorefront
       docker push zavastorefront.azurecr.io/zavastorefront:latest
   ```

## Modules Overview

| Module | Purpose | Key Params |
|--------|---------|-----------|
| `managed-identity.bicep` | Secure authentication | location, resourceName |
| `container-registry.bicep` | Image storage | registryName, skuName |
| `log-analytics-workspace.bicep` | Log collection | workspaceName, retentionInDays |
| `app-insights.bicep` | Application monitoring | appInsightsName, workspaceResourceId |
| `app-service-plan.bicep` | Compute resources | planName, osType, skuName |
| `app-service.bicep` | Web app hosting | appServiceName, dockerImageUri |
| `role-assignment.bicep` | RBAC permissions | principalId, roleDefinitionId |

## Scaling Considerations

**For Development/Demo**: B1 SKU (current)
**For Production**: S1 or higher SKU
**For High Traffic**: P1V2 or higher with multiple instances

Updating SKU:
```bash
az appservice plan update --name zava-dev-plan --resource-group zava-rg --sku S1
```

## Monitoring & Troubleshooting

```bash
# View real-time logs
az webapp log tail --name zava-dev-app --resource-group zava-rg

# Check Application Insights
az monitor app-insights events show --app zava-dev-appinsights --resource-group zava-rg

# Verify managed identity permissions
az role assignment list --assignee <principal-id> --resource-group zava-rg
```

## Support & References

- **Bicep Documentation**: https://learn.microsoft.com/azure/azure-resource-manager/bicep/
- **App Service Docs**: https://learn.microsoft.com/azure/app-service/
- **Container Registry**: https://learn.microsoft.com/azure/container-registry/
- **Azure Developer CLI**: https://learn.microsoft.com/azure/developer/azure-developer-cli/
- **Managed Identities**: https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/

## What's Next?

1. **Test Locally**: Build and test the Docker image locally
2. **Push Image**: Push the image to your ACR
3. **Deploy**: Run `azd up` to deploy the infrastructure
4. **Configure**: Set any additional environment variables as needed
5. **Monitor**: View logs and metrics in Application Insights
6. **Setup CI/CD**: Configure GitHub Actions for automated deployments

---

**Created**: November 2025  
**Template**: Bicep Infrastructure-as-Code  
**Azure Developer CLI**: Ready for azd workflows
