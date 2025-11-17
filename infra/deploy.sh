#!/bin/bash
# Deployment script for Zava Storefront infrastructure
# This script provides an interactive way to deploy the infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI not found. Install from: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    print_success "Azure CLI installed"
    
    if ! command -v azd &> /dev/null; then
        print_error "Azure Developer CLI (azd) not found. Install from: https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd"
        exit 1
    fi
    print_success "Azure Developer CLI installed"
    
    if ! command -v docker &> /dev/null; then
        print_warning "Docker not found. You'll need Docker to build images locally. Install from: https://docs.docker.com/get-docker/"
    else
        print_success "Docker installed"
    fi
}

# Check Azure login
check_azure_login() {
    print_header "Checking Azure Login"
    
    if ! az account show &> /dev/null; then
        print_info "Not logged in to Azure. Logging in now..."
        az login
    else
        CURRENT_ACCOUNT=$(az account show --query "name" -o tsv)
        print_success "Logged in as: $CURRENT_ACCOUNT"
    fi
}

# Validate Bicep template
validate_template() {
    print_header "Validating Bicep Template"
    
    if az bicep build --file infra/main.bicep > /dev/null 2>&1; then
        print_success "Bicep template validation passed"
    else
        print_error "Bicep template validation failed"
        az bicep build --file infra/main.bicep
        exit 1
    fi
}

# Get or create resource group
setup_resource_group() {
    print_header "Setting Up Resource Group"
    
    read -p "Enter resource group name (default: zava-rg): " RG_NAME
    RG_NAME=${RG_NAME:-zava-rg}
    
    read -p "Enter Azure region (default: eastus): " REGION
    REGION=${REGION:-eastus}
    
    if az group exists --name "$RG_NAME" | grep -q false; then
        print_info "Creating resource group: $RG_NAME in $REGION"
        az group create --name "$RG_NAME" --location "$REGION"
        print_success "Resource group created"
    else
        print_success "Resource group exists: $RG_NAME"
    fi
}

# Configure parameters
configure_parameters() {
    print_header "Configuring Deployment Parameters"
    
    read -p "Enter globally unique container registry name (default: zavacr): " ACR_NAME
    ACR_NAME=${ACR_NAME:-zavacr}
    
    read -p "Enter Docker image URI (default: $ACR_NAME.azurecr.io/zavastorefront:latest): " DOCKER_IMAGE
    DOCKER_IMAGE=${DOCKER_IMAGE:-$ACR_NAME.azurecr.io/zavastorefront:latest}
    
    read -p "Enter App Service SKU [B1/B2/B3/S1/S2/S3] (default: B1): " SKU
    SKU=${SKU:-B1}
    
    # Create a temporary parameters file
    cat > /tmp/deploy-params.txt << EOF
containerRegistryName=$ACR_NAME
dockerImageUri=$DOCKER_IMAGE
appServiceSku=$SKU
location=$REGION
EOF
    
    print_success "Parameters configured"
}

# Deploy infrastructure
deploy_infrastructure() {
    print_header "Deploying Infrastructure"
    
    print_info "Starting deployment... This may take 5-10 minutes"
    
    az deployment group create \
        --resource-group "$RG_NAME" \
        --template-file infra/main.bicep \
        --parameters infra/main.bicepparam \
        --parameters containerRegistryName="$ACR_NAME" \
        --parameters dockerImageUri="$DOCKER_IMAGE" \
        --parameters appServiceSku="$SKU" \
        --parameters location="$REGION"
    
    if [ $? -eq 0 ]; then
        print_success "Infrastructure deployed successfully"
    else
        print_error "Deployment failed"
        exit 1
    fi
}

# Get deployment outputs
show_outputs() {
    print_header "Deployment Outputs"
    
    OUTPUTS=$(az deployment group show \
        --name main \
        --resource-group "$RG_NAME" \
        --query "properties.outputs" \
        --output json)
    
    echo "$OUTPUTS" | jq -r 'to_entries | .[] | "\(.key): \(.value.value)"'
    
    # Extract the actual ACR URI from outputs for use in image push
    ACR_LOGIN_SERVER=$(echo "$OUTPUTS" | jq -r '.containerRegistryLoginServer.value')
    if [ -z "$ACR_LOGIN_SERVER" ] || [ "$ACR_LOGIN_SERVER" == "null" ]; then
        print_warning "Could not extract ACR login server from outputs. Using input ACR name: $ACR_NAME.azurecr.io"
        ACR_LOGIN_SERVER="$ACR_NAME.azurecr.io"
    else
        print_success "Captured ACR URI from deployment: $ACR_LOGIN_SERVER"
    fi
    
    print_info "Save these values for later use"
}

# Build and push Docker image
build_and_push_image() {
    print_header "Building and Pushing Docker Image"
    
    read -p "Do you want to build and push the Docker image now? (y/n): " BUILD_IMAGE
    if [[ "$BUILD_IMAGE" != "y" && "$BUILD_IMAGE" != "Y" ]]; then
        print_info "Skipping image build. You can build manually later."
        return
    fi
    
    read -p "Build for which platform? [1=linux/amd64 (x86/x64), 2=linux/arm64 (ARM), 3=both multiplatform]: " PLATFORM_CHOICE
    PLATFORM_CHOICE=${PLATFORM_CHOICE:-1}
    
    case $PLATFORM_CHOICE in
        1)
            PLATFORM="linux/amd64"
            print_info "Building for x86/x64 architecture..."
            ;;
        2)
            PLATFORM="linux/arm64"
            print_info "Building for ARM64 architecture..."
            ;;
        3)
            PLATFORM="linux/amd64,linux/arm64"
            print_info "Building for both x86/x64 and ARM64 architectures (multiplatform)..."
            ;;
        *)
            PLATFORM="linux/amd64"
            print_warning "Invalid choice, defaulting to linux/amd64"
            ;;
    esac
    
    # Check if docker buildx is available (required for multiplatform builds)
    if [[ "$PLATFORM_CHOICE" == "3" ]]; then
        if ! docker buildx version &> /dev/null; then
            print_error "Docker buildx not available. Required for multiplatform builds."
            print_info "Install Docker Desktop with buildx support or use option 1 or 2 for single platform builds."
            return 1
        fi
        
        # Create or use buildx builder
        if ! docker buildx inspect multiarch &> /dev/null; then
            print_info "Creating multiarch builder..."
            docker buildx create --name multiarch --use
        else
            docker buildx use multiarch
        fi
        
        print_info "Building multiplatform image for $PLATFORM..."
        docker buildx build \
            --platform "$PLATFORM" \
            --tag "$ACR_LOGIN_SERVER/zava/zavastorefront:latest" \
            --tag "$ACR_LOGIN_SERVER/zava/zavastorefront:multiarch" \
            --push \
            -f Dockerfile .
    else
        print_info "Building image for $PLATFORM..."
        docker build \
            --platform "$PLATFORM" \
            -t zavastorefront:latest \
            -f Dockerfile .
        
        if [ $? -eq 0 ]; then
            print_success "Image built successfully"
        else
            print_error "Image build failed"
            return 1
        fi
        
        print_info "Tagging image for registry..."
        docker tag zavastorefront:latest "$ACR_LOGIN_SERVER/zava/zavastorefront:latest"
        
        print_info "Logging in to registry using your Azure identity..."
        # Use identity-based authentication (no admin credentials required)
        # Your user principal with Owner rights can perform data plane operations
        if ! az acr login --name "$ACR_NAME" --expose-token | docker login "$ACR_LOGIN_SERVER" -u 00000000-0000-0000-0000-000000000000 --password-stdin; then
            print_error "Failed to login to registry"
            print_info "Note: Your Azure user principal with Owner rights should have AcrPush permissions"
            print_info "If this fails, you may need to assign the 'AcrPush' role to your user principal"
            return 1
        fi
        
        print_info "Pushing image to registry..."
        docker push "$ACR_LOGIN_SERVER/zava/zavastorefront:latest"
        
        if [ $? -eq 0 ]; then
            print_success "Image pushed successfully"
        else
            print_error "Image push failed"
            return 1
        fi
    fi
}

# Post-deployment instructions
post_deployment_instructions() {
    print_header "Next Steps"
    
    print_info "To build and push your Docker image:"
    echo
    
    print_info "Option 1: Build for x86/x64 (Linux) - suitable for Azure App Service:"
    echo "   docker build --platform linux/amd64 -t zavastorefront:latest -f Dockerfile ."
    echo "   docker tag zavastorefront:latest $ACR_LOGIN_SERVER/zava/zavastorefront:latest"
    echo "   az acr login --name $ACR_NAME --expose-token | docker login $ACR_LOGIN_SERVER -u 00000000-0000-0000-0000-000000000000 --password-stdin"
    echo "   docker push $ACR_LOGIN_SERVER/zava/zavastorefront:latest"
    echo
    
    print_info "Option 2: Build for ARM64 on Apple Silicon:"
    echo "   docker build --platform linux/arm64 -t zavastorefront:latest -f Dockerfile ."
    echo "   docker tag zavastorefront:latest $ACR_LOGIN_SERVER/zava/zavastorefront:latest"
    echo "   az acr login --name $ACR_NAME --expose-token | docker login $ACR_LOGIN_SERVER -u 00000000-0000-0000-0000-000000000000 --password-stdin"
    echo "   docker push $ACR_LOGIN_SERVER/zava/zavastorefront:latest"
    echo
    
    print_info "Option 3: Build multiplatform image (requires Docker buildx):"
    echo "   docker buildx build --platform linux/amd64,linux/arm64 \\"
    echo "     -t $ACR_LOGIN_SERVER/zava/zavastorefront:latest \\"
    echo "     --push -f Dockerfile ."
    echo
    
    print_info "Monitor your deployment:"
    echo "   az webapp log tail --name zava-dev-app --resource-group $RG_NAME"
    echo
    
    print_success "Deployment complete! Your application should be available shortly."
}

# Main script
main() {
    clear
    print_header "Zava Storefront Infrastructure Deployment"
    
    check_prerequisites
    check_azure_login
    validate_template
    setup_resource_group
    configure_parameters
    
    read -p "Ready to deploy? (y/n): " CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        print_warning "Deployment cancelled"
        exit 0
    fi
    
    deploy_infrastructure
    show_outputs
    build_and_push_image
    post_deployment_instructions
}

# Run main function
main
