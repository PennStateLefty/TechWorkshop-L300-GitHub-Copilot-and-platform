# Quick Start: Deploying ZavaStorefront to Azure

This guide provides a quick overview of deploying the ZavaStorefront application to Microsoft Azure.

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed
- [Docker](https://docs.docker.com/get-docker/) installed
- An active Azure subscription

## Quick Deployment

1. **Clone the repository** (if you haven't already)

2. **Login to Azure**
   ```bash
   az login
   ```

3. **Run the automated deployment script**
   ```bash
   cd infra
   ./deploy.sh
   ```

The script will:
- Create an Azure Resource Group in Central US
- Deploy Azure Container Registry
- Build and push your Docker image
- Deploy Container Apps with managed identity
- Set up Application Insights for monitoring
- Configure all necessary security permissions

## What Gets Deployed

- **Resource Group**: `rg-zavastorefront-prod`
- **Azure Container Registry**: Hosts your container image
- **Managed Identity**: Provides secure authentication
- **Application Insights**: Monitoring and telemetry
- **Container App Environment**: Runtime for containers
- **Container App**: Your running application

## After Deployment

The script will output your application URL. Visit it with HTTPS to see your deployed application!

Example output:
```
Application URL: https://ca-zavastorefront-abc123.centralus.azurecontainerapps.io
```

## Detailed Documentation

For more detailed instructions, customization options, and troubleshooting, see:
- [Infrastructure Documentation](infra/README.md)

## Updating Your Application

To deploy a new version:

1. Make your code changes
2. Build and push a new image:
   ```bash
   docker build -t zavastorefront:v2 .
   az acr login --name <your-acr-name>
   docker tag zavastorefront:v2 <your-acr-name>.azurecr.io/zavastorefront:v2
   docker push <your-acr-name>.azurecr.io/zavastorefront:v2
   ```
3. Update the Container App:
   ```bash
   az containerapp update \
     --name ca-zavastorefront-<suffix> \
     --resource-group rg-zavastorefront-prod \
     --image <your-acr-name>.azurecr.io/zavastorefront:v2
   ```

## Clean Up

To delete all resources:
```bash
az group delete --name rg-zavastorefront-prod --yes --no-wait
```

## Support

For issues or questions, please refer to the [detailed documentation](infra/README.md) or open an issue in the repository.
