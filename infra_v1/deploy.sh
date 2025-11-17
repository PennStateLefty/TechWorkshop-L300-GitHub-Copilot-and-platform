#!/bin/bash

# ZavaStorefront Azure Deployment Script
# This script automates the deployment of the ZavaStorefront application to Azure

set -e  # Exit on error

# Configuration
RESOURCE_GROUP="rg-zavastorefront-prod"
LOCATION="centralus"
IMAGE_TAG="latest"

echo "========================================="
echo "ZavaStorefront Azure Deployment"
echo "========================================="
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI is not installed. Please install it first."
    echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install it first."
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if user is logged in to Azure
echo "Checking Azure login status..."
if ! az account show &> /dev/null; then
    echo "Please login to Azure..."
    az login
fi

# Display current subscription
SUBSCRIPTION=$(az account show --query name -o tsv)
echo "Current subscription: $SUBSCRIPTION"
read -p "Continue with this subscription? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled. Use 'az account set --subscription <id>' to change subscription."
    exit 1
fi

# Create resource group
echo ""
echo "Step 1: Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION --output table

# Initial deployment to create ACR
echo ""
echo "Step 2: Deploying ACR and infrastructure..."
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file infra/main.bicep \
  --parameters containerImage='mcr.microsoft.com/dotnet/samples:aspnetapp' \
  --output table

# Get ACR name
ACR_NAME=$(az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name main \
  --query 'properties.outputs.acrName.value' \
  --output tsv)

echo ""
echo "ACR Name: $ACR_NAME"

# Build Docker image
echo ""
echo "Step 3: Building Docker image..."
docker build -t zavastorefront:$IMAGE_TAG .

# Login to ACR
echo ""
echo "Step 4: Logging into Azure Container Registry..."
az acr login --name $ACR_NAME

# Tag image
echo ""
echo "Step 5: Tagging image..."
docker tag zavastorefront:$IMAGE_TAG $ACR_NAME.azurecr.io/zavastorefront:$IMAGE_TAG

# Push image to ACR
echo ""
echo "Step 6: Pushing image to ACR..."
docker push $ACR_NAME.azurecr.io/zavastorefront:$IMAGE_TAG

# Deploy with actual container image
echo ""
echo "Step 7: Deploying Container App with actual image..."
CONTAINER_IMAGE="$ACR_NAME.azurecr.io/zavastorefront:$IMAGE_TAG"
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file infra/main.bicep \
  --parameters containerImage=$CONTAINER_IMAGE \
  --output table

# Get application URL
APP_URL=$(az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name main \
  --query 'properties.outputs.containerAppUrl.value' \
  --output tsv)

# Display deployment information
echo ""
echo "========================================="
echo "Deployment Complete!"
echo "========================================="
echo ""
echo "Application URL: https://$APP_URL"
echo "Resource Group: $RESOURCE_GROUP"
echo "Container Registry: $ACR_NAME.azurecr.io"
echo ""
echo "To view logs:"
echo "  az containerapp logs show --name ca-zavastorefront-* --resource-group $RESOURCE_GROUP --follow"
echo ""
echo "To delete all resources:"
echo "  az group delete --name $RESOURCE_GROUP --yes --no-wait"
echo ""
