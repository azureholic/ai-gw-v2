#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy AI Gateway infrastructure to Azure

.DESCRIPTION
    This script creates the resource group (if it doesn't exist) and deploys the main.bicep template
    using the configuration from resourcegroup.config.json and main.acc.parameters.bicepparam

.PARAMETER Environment
    The environment to deploy (default: acc)

.PARAMETER SubscriptionId
    Azure subscription ID (optional - uses current subscription if not provided)

.PARAMETER WhatIf
    Run deployment in validation mode without making changes

.EXAMPLE
    .\deploy.ps1
    
.EXAMPLE
    .\deploy.ps1 -Environment acc -SubscriptionId "12345678-1234-1234-1234-123456789012"

.EXAMPLE
    .\deploy.ps1 -WhatIf
#>

param(
    [Parameter()]
    [string]$Environment = "acc",
    
    [Parameter()]
    [string]$SubscriptionId,
    
    [Parameter()]
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Script variables
$ScriptDir = $PSScriptRoot
$InfraDir = Join-Path $ScriptDir "infra"
$ResourceGroupConfigPath = Join-Path $InfraDir "resourcegroup.config.json"
$MainBicepPath = Join-Path $InfraDir "main.bicep"
$ParametersPath = Join-Path $InfraDir "main.$Environment.parameters.bicepparam"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "AI Gateway Infrastructure Deployment" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Validate files exist
Write-Host "Validating configuration files..." -ForegroundColor Yellow
if (-not (Test-Path $ResourceGroupConfigPath)) {
    Write-Error "Resource group config not found: $ResourceGroupConfigPath"
}
if (-not (Test-Path $MainBicepPath)) {
    Write-Error "Main Bicep template not found: $MainBicepPath"
}
if (-not (Test-Path $ParametersPath)) {
    Write-Error "Parameters file not found: $ParametersPath"
}
Write-Host "✓ All configuration files found" -ForegroundColor Green
Write-Host ""

# Read resource group configuration
Write-Host "Reading resource group configuration..." -ForegroundColor Yellow
$rgConfig = Get-Content $ResourceGroupConfigPath -Raw | ConvertFrom-Json
$resourceGroupName = $rgConfig.resourceGroupNames[0]
$tags = $rgConfig.tags

Write-Host "Resource Group: $resourceGroupName" -ForegroundColor White
Write-Host "Environment: $Environment" -ForegroundColor White
Write-Host ""

# Set subscription if provided
if ($SubscriptionId) {
    Write-Host "Setting Azure subscription..." -ForegroundColor Yellow
    az account set --subscription $SubscriptionId
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to set subscription"
    }
    Write-Host "✓ Subscription set" -ForegroundColor Green
    Write-Host ""
}

# Get current subscription info
Write-Host "Current Azure context:" -ForegroundColor Yellow
$subscription = az account show | ConvertFrom-Json
Write-Host "  Subscription: $($subscription.name)" -ForegroundColor White
Write-Host "  ID: $($subscription.id)" -ForegroundColor White
Write-Host "  Tenant: $($subscription.tenantId)" -ForegroundColor White
Write-Host ""

# Read parameters to get location
Write-Host "Reading deployment parameters..." -ForegroundColor Yellow
$paramContent = Get-Content $ParametersPath -Raw
if ($paramContent -match "param rgLocation = '([^']+)'") {
    $location = $Matches[1]
    Write-Host "Location: $location" -ForegroundColor White
} else {
    Write-Error "Could not extract location from parameters file"
}
Write-Host ""

# Create or update resource group
Write-Host "Ensuring resource group exists..." -ForegroundColor Yellow
$rgExists = az group exists --name $resourceGroupName | ConvertFrom-Json

if ($rgExists) {
    Write-Host "✓ Resource group already exists: $resourceGroupName" -ForegroundColor Green
} else {
    Write-Host "Creating resource group: $resourceGroupName in $location" -ForegroundColor White
    
    # Build tags parameter
    $tagParams = @()
    foreach ($key in $tags.PSObject.Properties.Name) {
        $tagParams += "$key=$($tags.$key)"
    }
    
    az group create `
        --name $resourceGroupName `
        --location $location `
        --tags $tagParams
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create resource group"
    }
    Write-Host "✓ Resource group created successfully" -ForegroundColor Green
}
Write-Host ""

# Deploy Bicep template
Write-Host "Starting deployment..." -ForegroundColor Yellow
Write-Host "Template: $MainBicepPath" -ForegroundColor White
Write-Host "Parameters: $ParametersPath" -ForegroundColor White
Write-Host ""

$deploymentName = "ai-gateway-$Environment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

if ($WhatIf) {
    Write-Host "Running in WHAT-IF mode (validation only)..." -ForegroundColor Magenta
    Write-Host ""
    
    az deployment group what-if `
        --name $deploymentName `
        --resource-group $resourceGroupName `
        --template-file $MainBicepPath `
        --parameters $ParametersPath `
        --verbose
} else {
    Write-Host "Deploying infrastructure..." -ForegroundColor Cyan
    Write-Host "Deployment name: $deploymentName" -ForegroundColor White
    Write-Host ""
    
    az deployment group create `
        --name $deploymentName `
        --resource-group $resourceGroupName `
        --template-file $MainBicepPath `
        --parameters $ParametersPath `
        --verbose
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "Deployment failed"
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host "Deployment completed successfully!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

# Get deployment outputs
if (-not $WhatIf) {
    Write-Host "Fetching deployment outputs..." -ForegroundColor Yellow
    $outputs = az deployment group show `
        --name $deploymentName `
        --resource-group $resourceGroupName `
        --query properties.outputs `
        --output json | ConvertFrom-Json
    
    if ($outputs) {
        Write-Host ""
        Write-Host "Deployment Outputs:" -ForegroundColor Cyan
        Write-Host "==================" -ForegroundColor Cyan
        
        if ($outputs.apimGatewayUrl) {
            Write-Host "APIM Gateway URL: $($outputs.apimGatewayUrl.value)" -ForegroundColor White
        }
        if ($outputs.apimName) {
            Write-Host "APIM Name: $($outputs.apimName.value)" -ForegroundColor White
        }
        if ($outputs.managedIdentityClientId) {
            Write-Host "Managed Identity Client ID: $($outputs.managedIdentityClientId.value)" -ForegroundColor White
        }
        if ($outputs.logAnalyticsWorkspaceId) {
            Write-Host "Log Analytics Workspace ID: $($outputs.logAnalyticsWorkspaceId.value)" -ForegroundColor White
        }
        
        Write-Host ""
    }
}

Write-Host "Done! 🚀" -ForegroundColor Green
