# Zava Storefront - Infrastructure Quick Reference

## 📋 What Was Created

A complete, production-ready Infrastructure-as-Code (IaC) solution using **Bicep** and **Azure Developer CLI**.

### Files Created

```
infra/
├── main.bicep                          ✓ Main orchestration template
├── main.bicepparam                     ✓ Default parameters  
├── main.json                           ✓ Compiled ARM template
├── deploy.sh                           ✓ Interactive deployment script
├── README.md                           ✓ Comprehensive deployment guide
└── modules/
    ├── app-insights.bicep              ✓ Application monitoring
    ├── app-service.bicep               ✓ Web application hosting
    ├── app-service-plan.bicep          ✓ Compute resources
    ├── container-registry.bicep        ✓ Docker image storage
    ├── log-analytics-workspace.bicep   ✓ Log aggregation
    ├── managed-identity.bicep          ✓ Secure auth
    └── role-assignment.bicep           ✓ RBAC permissions

azure.yaml                              ✓ Azure Developer CLI config
INFRASTRUCTURE.md                       ✓ Full deployment details
```

## 🚀 Quick Start

### 1. Minimal Deployment (5 minutes)

```bash
# Edit the parameters
nano infra/main.bicepparam

# Update these critical values:
# - containerRegistryName (must be globally unique, alphanumeric only)
# - dockerImageUri (your container image location)

# Deploy
az deployment group create \
  --resource-group zava-rg \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
```

### 2. Interactive Deployment

```bash
# Make script executable
chmod +x infra/deploy.sh

# Run interactive deployment
./infra/deploy.sh
```

### 3. Azure Developer CLI (Recommended)

```bash
# One-command setup and deployment
azd up

# Or separate commands
azd provision    # Just deploy infrastructure
azd deploy       # Just deploy application
```

## 📊 Architecture

| Component | Purpose | SKU |
|-----------|---------|-----|
| **App Service** | Hosts containerized .NET app | B1 (free) |
| **App Service Plan** | Compute resources (Linux) | B1 |
| **Container Registry** | Docker image storage | Basic |
| **Application Insights** | App monitoring & diagnostics | Standard |
| **Log Analytics** | Centralized logging | Standard |
| **Managed Identity** | Secure authentication | N/A |

## 🔑 Key Features

✅ **Security**
- Managed Identity (no credentials in code)
- RBAC with least-privilege (AcrPull role)
- HTTPS/TLS 1.2+ enforced
- Anonymous container pull disabled

✅ **Monitoring**
- Application Insights instrumentation
- Log Analytics integration
- 30-day log retention
- Performance & dependency tracking

✅ **DevOps Ready**
- GitHub CI/CD integration support
- Azure Developer CLI compatible
- Modular Bicep structure
- Environment-based naming

## ⚙️ Configuration

### Main Parameters (`infra/main.bicepparam`)

```bicep
param location = 'eastus'
param containerRegistryName = 'YOUR_UNIQUE_NAME'
param dockerImageUri = 'YOUR_REGISTRY.azurecr.io/zavastorefront:latest'
param appServiceSku = 'B1'  # B1=free, S1=paid, S2+ for production
param gitHubRepoUrl = ''    # Optional: GitHub repo URL
```

### Environment Variables (Auto-configured)

App Service automatically receives:
- `APPLICATIONINSIGHTS_CONNECTION_STRING`
- `DOCKER_REGISTRY_SERVER_URL`
- `DOCKER_ENABLE_CI`

## 📦 Deployment Outputs

After deployment, you'll receive:
```
appInsightsConnectionString  → For app instrumentation
containerRegistryLoginServer → For docker push/pull
appServiceUrl               → Your application URL
managedIdentityPrincipalId  → For additional RBAC
logAnalyticsWorkspaceId     → For custom queries
```

## 🔄 Post-Deployment Steps

```bash
# 1. Build Docker image
docker build -t zavastorefront:latest -f Dockerfile .

# 2. Tag for registry
docker tag zavastorefront:latest REGISTRY.azurecr.io/zavastorefront:latest

# 3. Login and push
az acr login --name REGISTRY
docker push REGISTRY.azurecr.io/zavastorefront:latest

# 4. Monitor logs
az webapp log tail --name zava-dev-app --resource-group zava-rg

# 5. Access application
# Visit: https://zava-dev-app.azurewebsites.net (your URL from outputs)
```

## 📈 Scaling

**For Development**: B1 (current) - Free tier  
**For Production**: S1 or S2 - Better performance & uptime SLA  
**For High Traffic**: P1V2+ with multiple instances  

```bash
# Scale up the plan
az appservice plan update --name zava-dev-plan \
  --resource-group zava-rg --sku S1
```

## 🐛 Troubleshooting

### Template won't deploy
```bash
# Validate template
az bicep build --file infra/main.bicep

# Preview changes
az deployment group what-if \
  --resource-group zava-rg \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
```

### Container won't start
```bash
# Check logs
az webapp log tail --name zava-dev-app --resource-group zava-rg

# Verify managed identity has ACR access
az role assignment list --assignee PRINCIPAL_ID --resource-group zava-rg
```

### Image not found in registry
```bash
# List images in registry
az acr repository list --name REGISTRY_NAME

# List tags for image
az acr repository show-tags --name REGISTRY_NAME --repository zavastorefront
```

## 🔗 Important Links

- [Azure Bicep Docs](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [App Service Docs](https://learn.microsoft.com/azure/app-service/)
- [Container Registry](https://learn.microsoft.com/azure/container-registry/)
- [Managed Identities](https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/)
- [azd Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)

## 💾 File Reference

| File | Purpose | When to Edit |
|------|---------|-------------|
| `main.bicep` | Orchestration logic | Never - modify modules instead |
| `main.bicepparam` | Deployment parameters | **Before each deployment** |
| `modules/*.bicep` | Resource definitions | When changing infrastructure |
| `azure.yaml` | azd configuration | When using Azure Developer CLI |
| `deploy.sh` | Helper script | Optional - provides guided deployment |

## 🎯 Next Steps

1. ✅ Review the infrastructure components
2. ✅ Update `main.bicepparam` with your values
3. ✅ Run `azd up` or `./infra/deploy.sh`
4. ✅ Build and push Docker image
5. ✅ Monitor in Application Insights
6. ✅ Set up GitHub Actions for CI/CD

## 📝 Notes

- **Registry Name**: Must be globally unique and contain only lowercase alphanumeric characters
- **Docker Image**: Must follow format `registry.azurecr.io/imagename:tag`
- **App Service URL**: Will be `https://zava-dev-app.azurewebsites.net` (or your custom name)
- **Cost**: B1 (free), Basic ACR (~$10/month), Log Analytics (~$2/GB)

---

**For detailed information**, see:
- `INFRASTRUCTURE.md` - Complete deployment guide
- `infra/README.md` - Infrastructure-specific documentation
- `infra/modules/` - Individual module documentation
