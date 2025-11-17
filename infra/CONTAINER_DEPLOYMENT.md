# Container-Based Deployment Architecture

## Overview

The infrastructure has been updated to use a **container-based deployment model** instead of GitHub source control integration. This is the recommended approach for containerized applications.

## Architecture Changes

### Removed Components
- ❌ GitHub source control deployment via Azure App Service
- ❌ GitHub repository parameters (`gitHubRepoUrl`, `gitHubBranch`)

### Added Components
- ✅ **ACR Webhook** - Automatically triggers App Service updates when images are pushed to Azure Container Registry
- ✅ Managed Identity with AcrPull permissions for secure image pulls
- ✅ Container-centric deployment pipeline

## Deployment Flow

```
Your Development Machine
        ↓
  Build Docker Image (--platform linux/amd64 for App Service)
        ↓
  Push to Azure Container Registry
        ↓
  ACR Webhook triggered
        ↓
  App Service pulls new image
        ↓
  Application restarts with new version
```

## Key Files Modified

### 1. **infra/modules/app-service.bicep**
- Removed GitHub source control deployment resource
- Removed `gitHubRepoUrl` and `gitHubBranch` parameters
- Kept container-specific configuration

### 2. **infra/modules/acr-webhook.bicep** (NEW)
- Deploys ACR webhook for automatic deployments
- Listens for 'push' events on container images
- Configured to POST to App Service webhook endpoint

### 3. **infra/main.bicep**
- Removed GitHub parameters from orchestration
- Added ACR webhook module deployment
- Simplified parameter passing to App Service

### 4. **infra/main.bicepparam**
- Removed `gitHubRepoUrl` and `gitHubBranch` parameters
- Updated default Docker image URI format
- Cleaner configuration for container-based deployments

### 5. **infra/deploy.sh**
- Removed GitHub repository configuration prompts
- Simplified infrastructure deployment parameters
- Updated documentation to focus on container builds

## Deployment Process

### Step 1: Deploy Infrastructure
```bash
cd infra
./deploy.sh
```

You'll be prompted for:
- Resource group name
- Azure region
- Container registry name (must be globally unique)
- Docker image URI
- App Service SKU

### Step 2: Build and Push Container Image

From the project root:

**For x86/x64 (Azure App Service):**
```bash
docker build --platform linux/amd64 -t zavastorefront:latest -f Dockerfile .
docker tag zavastorefront:latest <REGISTRY>.azurecr.io/zavastorefront:latest
az acr login --name <REGISTRY>
docker push <REGISTRY>.azurecr.io/zavastorefront:latest
```

**For ARM64 (Apple Silicon development):**
```bash
docker build --platform linux/arm64 -t zavastorefront:latest -f Dockerfile .
docker tag zavastorefront:latest <REGISTRY>.azurecr.io/zavastorefront:latest
az acr login --name <REGISTRY>
docker push <REGISTRY>.azurecr.io/zavastorefront:latest
```

### Step 3: App Service Auto-Deployment
Once you push to ACR, the webhook automatically:
1. Notifies App Service of the new image
2. Pulls the image from ACR
3. Restarts the application with the new version

## Benefits of This Approach

1. **Clean Separation of Concerns**
   - GitHub stores code
   - ACR stores container images
   - App Service consumes images

2. **Faster Deployments**
   - No need for App Service to clone repo and build
   - Direct container image deployment

3. **Better for CI/CD**
   - GitHub Actions can build images in parallel
   - Push to ACR triggers automatic deployment
   - No source control overhead in App Service

4. **Scalability**
   - Same image can be deployed to multiple services
   - Container builds can be cached and reused
   - Easier to manage versioning

5. **Security**
   - App Service only has image pull rights via Managed Identity
   - No need to expose source code to App Service
   - Reduced attack surface

## Monitoring Deployments

### View App Service logs:
```bash
az webapp log tail --name app-zavadev --resource-group <RG_NAME>
```

### View ACR webhook events:
```bash
az acr webhook list-events --registry <REGISTRY_NAME> --webhook-name app-zavadev-webhook
```

### Check App Service for new image:
```bash
az webapp config container show --name <APP_SERVICE_NAME> --resource-group <RG_NAME>
```

## Troubleshooting

### App Service not updating after push?
1. Check ACR webhook is enabled: `az acr webhook show --registry <REGISTRY> --name <WEBHOOK_NAME>`
2. Verify image was pushed: `az acr repository show --registry <REGISTRY> --name zavastorefront`
3. Check App Service logs for pull errors
4. Ensure App Service has AcrPull permission (should be automatic)

### Image pull errors?
1. Verify image exists in ACR: `az acr repository list --registry <REGISTRY>`
2. Check Managed Identity has AcrPull role: `az role assignment list --assignee <IDENTITY_ID>`
3. Verify DOCKER_REGISTRY_SERVER_URL is set correctly in App Service settings

## Next Steps

1. Deploy infrastructure using `./deploy.sh`
2. Build and test Docker image locally
3. Push image to ACR
4. Verify App Service deploys automatically
5. Set up GitHub Actions for automated builds (optional)

For GitHub Actions example, see the repository workflows directory.
