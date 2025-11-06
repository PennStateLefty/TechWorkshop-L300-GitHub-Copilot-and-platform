# ZavaStorefront Infrastructure Deployment

This directory contains the Infrastructure-as-Code (IaC) for deploying the ZavaStorefront application to Microsoft Azure using Bicep templates.

## Architecture Overview

The infrastructure deploys the following Azure resources:

- **Resource Group**: Container for all resources
- **Azure Container Registry (ACR)**: Hosts the container image
- **Managed Identity**: Enables secure authentication
- **Application Insights**: Provides monitoring and telemetry
- **Log Analytics Workspace**: Backend for Application Insights
- **Container App Environment**: Runtime environment for containers
- **Container App**: Runs the ZavaStorefront application

## Prerequisites

Before deploying, ensure you have:

1. **Azure CLI** installed ([Installation Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
2. **Docker** installed ([Installation Guide](https://docs.docker.com/get-docker/))
3. An active **Azure subscription**
4. Appropriate permissions to create resources in Azure

## Deployment Steps

### 1. Login to Azure

```bash
az login
```

### 2. Set Your Subscription

```bash
# List available subscriptions
az account list --output table

# Set the subscription you want to use
az account set --subscription "<your-subscription-id>"
```

### 3. Create Resource Group

```bash
az group create \
  --name rg-zavastorefront-prod \
  --location centralus
```

### 4. Build and Push Container Image

First, build the Docker image:

```bash
# From the root of the repository
docker build -t zavastorefront:latest .
```

Deploy the infrastructure first to get the ACR details:

```bash
# Deploy infrastructure without container app (we'll add it later)
# First, deploy just the ACR and supporting resources
az deployment group create \
  --resource-group rg-zavastorefront-prod \
  --template-file infra/main.bicep \
  --parameters containerImage='mcr.microsoft.com/dotnet/samples:aspnetapp' \
  --query 'properties.outputs'
```

Note the ACR login server from the output (e.g., `zavastorefront<uniqueid>.azurecr.io`).

Login to ACR and push the image:

```bash
# Get ACR credentials
ACR_NAME=$(az deployment group show \
  --resource-group rg-zavastorefront-prod \
  --name main \
  --query 'properties.outputs.acrName.value' \
  --output tsv)

# Login to ACR
az acr login --name $ACR_NAME

# Tag the image
docker tag zavastorefront:latest $ACR_NAME.azurecr.io/zavastorefront:latest

# Push to ACR
docker push $ACR_NAME.azurecr.io/zavastorefront:latest
```

### 5. Deploy Full Infrastructure

Now deploy the complete infrastructure with your container image:

```bash
# Get the full container image path
CONTAINER_IMAGE="$ACR_NAME.azurecr.io/zavastorefront:latest"

# Deploy the infrastructure
az deployment group create \
  --resource-group rg-zavastorefront-prod \
  --template-file infra/main.bicep \
  --parameters containerImage=$CONTAINER_IMAGE
```

### 6. Get the Application URL

```bash
az deployment group show \
  --resource-group rg-zavastorefront-prod \
  --name main \
  --query 'properties.outputs.containerAppUrl.value' \
  --output tsv
```

Visit the URL (with https://) to access your application!

## Alternative: One-Step Deployment Script

For convenience, you can use the following script to automate the entire process:

```bash
#!/bin/bash

# Configuration
RESOURCE_GROUP="rg-zavastorefront-prod"
LOCATION="centralus"
IMAGE_TAG="latest"

# Create resource group
echo "Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# Initial deployment to create ACR
echo "Deploying ACR and infrastructure..."
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file infra/main.bicep \
  --parameters containerImage='mcr.microsoft.com/dotnet/samples:aspnetapp'

# Get ACR name
ACR_NAME=$(az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name main \
  --query 'properties.outputs.acrName.value' \
  --output tsv)

echo "ACR Name: $ACR_NAME"

# Build and push image
echo "Building Docker image..."
docker build -t zavastorefront:$IMAGE_TAG .

echo "Logging into ACR..."
az acr login --name $ACR_NAME

echo "Tagging image..."
docker tag zavastorefront:$IMAGE_TAG $ACR_NAME.azurecr.io/zavastorefront:$IMAGE_TAG

echo "Pushing image to ACR..."
docker push $ACR_NAME.azurecr.io/zavastorefront:$IMAGE_TAG

# Deploy with actual container image
echo "Deploying Container App with actual image..."
CONTAINER_IMAGE="$ACR_NAME.azurecr.io/zavastorefront:$IMAGE_TAG"
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file infra/main.bicep \
  --parameters containerImage=$CONTAINER_IMAGE

# Get application URL
APP_URL=$(az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name main \
  --query 'properties.outputs.containerAppUrl.value' \
  --output tsv)

echo ""
echo "Deployment complete!"
echo "Application URL: https://$APP_URL"
```

Save this as `deploy.sh`, make it executable (`chmod +x deploy.sh`), and run it.

## Infrastructure Details

### Resource Naming Convention

Resources are named using the pattern: `<resource-type-prefix>-<base-name>-<unique-suffix>`

- Resource Group: `rg-zavastorefront-prod`
- Container Registry: `zavastorefront<uniquesuffix>` (no hyphens due to ACR naming rules)
- Managed Identity: `id-zavastorefront-<uniquesuffix>`
- Application Insights: `ai-zavastorefront-<uniquesuffix>`
- Container App Environment: `cae-zavastorefront-<uniquesuffix>`
- Container App: `ca-zavastorefront-<uniquesuffix>`

### Security Features

1. **Managed Identity**: The Container App uses a user-assigned managed identity to authenticate with ACR
2. **Role-Based Access Control**: The managed identity has `acrPull` role on the container registry
3. **Admin Authentication**: Initially enabled for ease of development; can be disabled once managed identity is confirmed working
4. **HTTPS**: Container Apps automatically provision SSL certificates and enforce HTTPS

### Scaling Configuration

The Container App is configured with:
- **Minimum replicas**: 1
- **Maximum replicas**: 3
- **CPU**: 0.5 cores per instance
- **Memory**: 1 GB per instance

### Monitoring

Application Insights is integrated with the Container App environment, providing:
- Request telemetry
- Performance metrics
- Exception tracking
- Custom events and traces

## Updating the Application

To deploy a new version of the application:

```bash
# Build new image
docker build -t zavastorefront:v2 .

# Tag and push
docker tag zavastorefront:v2 $ACR_NAME.azurecr.io/zavastorefront:v2
docker push $ACR_NAME.azurecr.io/zavastorefront:v2

# Update the container app
az containerapp update \
  --name ca-zavastorefront-<uniquesuffix> \
  --resource-group rg-zavastorefront-prod \
  --image $ACR_NAME.azurecr.io/zavastorefront:v2
```

## Cleanup

To delete all resources:

```bash
az group delete --name rg-zavastorefront-prod --yes --no-wait
```

## Troubleshooting

### Check Container App Logs

```bash
az containerapp logs show \
  --name ca-zavastorefront-<uniquesuffix> \
  --resource-group rg-zavastorefront-prod \
  --follow
```

### Check Container App Status

```bash
az containerapp show \
  --name ca-zavastorefront-<uniquesuffix> \
  --resource-group rg-zavastorefront-prod \
  --query 'properties.{Status:provisioningState,Health:runningStatus}' \
  --output table
```

### Verify ACR Authentication

```bash
# Test ACR pull with managed identity
az containerapp revision list \
  --name ca-zavastorefront-<uniquesuffix> \
  --resource-group rg-zavastorefront-prod \
  --output table
```

## Additional Resources

- [Azure Container Apps Documentation](https://docs.microsoft.com/en-us/azure/container-apps/)
- [Azure Container Registry Documentation](https://docs.microsoft.com/en-us/azure/container-registry/)
- [Bicep Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Application Insights Documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)
