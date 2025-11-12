Plan: Deploy Multi-Region AI Gateway with Priority-Based Backend Pools
Create infrastructure with 3 regional AI Foundry accounts, API Management with backend pools using circuit breaker pattern (single 429 fully opens circuit for 10s), strict priority-based routing (1→2→3), and Azure Monitor usage tracking. One user-assigned managed identity for APIM with project-level RBAC, authentication handled in policies only. All loops use @batchSize(1) to avoid conflicts.

Steps:

Create main.bicep foundation — Define parameters from main.acc.parameters.bicepparam, deploy all resources to West Europe resource group except AI Foundry projects (region-specific), establish naming convention: cog-aifoundry-${environment}-${suffix}-${regionAbbr}, create shared user-assigned managed identity for APIM at start

Deploy monitoring infrastructure — Sequential deployment in West Europe: Log Analytics workspace using log-analytics.bicep → Custom table AIUsageLog_CL using custom-table.bicep → Data Collection Endpoint using data-collection-endpoint.bicep → Data Collection Rule using data-collection-rule.bicep with stream Custom-AIUsageLog_CL

Deploy multi-region AI Foundry — Loop with @batchSize(1) and [for (location, i) in openAILocations] to create 3 AI Foundry accounts in West Europe using ai-foundry.bicep, deploy projects in respective regions (location.name), ensure module outputs projectId for RBAC scoping, output account names, project resource IDs, and endpoints per region

Grant RBAC to managed identity — Loop with @batchSize(1) through 3 AI Foundry project IDs from step 3, assign Cognitive Services OpenAI User and Azure AI Developer roles at project scope to APIM managed identity, assign Monitoring Metrics Publisher role to DCE resource, ensure completion before model deployments

Deploy APIM service — Create modules/apim.bicep for StandardV2 SKU (no VNet), assign user-assigned managed identity from step 1, publisher info from parameters, stub APIs for /openai/deployments/* and /v1/* paths without policies, output APIM service name and gateway URL

Update model-deployments.bicep — Add regionAbbreviation parameter, remove API key named value creation entirely, create regional backends as simple HTTP backends with AI Foundry URLs (no backend authentication—rely on policy), name backends as aoai-{deploymentName with dots→-dot-}-${regionAbbr} and oaiv1-{deploymentName with dots→-dot-}-${regionAbbr}, use @batchSize(1) for model deployment loop internally, output structured array with deploymentName, priority, regionAbbreviation, aoaiBackendId, oaiv1BackendId

Deploy models per region — Loop with @batchSize(1) through openAILocations calling modified model-deployments.bicep, transform deployments[] inline: add model.format: 'OpenAI', restructure to model: {format, name, version} and sku: {name: skuName, capacity: skuCapacity}, pass through priority and deploymentName, depends on RBAC completion from step 4

Create modules/apim-backend-pools.bicep — New module to create APIM backend pools with @batchSize(1) per unique deploymentName with dots replaced by -dot- (e.g., pool-gpt-4o-mini-2024-dot-07-dot-18), add backends from all regions with strict priority ordering, configure circuit breaker: trip threshold = 1 consecutive 429, trip duration = 10s, fully close after duration, output list of pool names

Aggregate and deploy backend pools — In main.bicep, flatten all backend outputs from all regions, group by exact deploymentName match, create single pool per deployment with all regional backends (both AOAI and OAIv1 formats in same pool), sort by priority (1, 2, 3), call apim-backend-pools.bicep after all model deployments complete

Create modules/apim-config.bicep — New module to create APIM Named Values with @batchSize(1): dce-endpoint (from DCE output), dcr-immutable-id (from DCR output), stream-name (Custom-AIUsageLog_CL), deploy after backend pools and before policy attachment

Update policies for backend pools — Modify aoai-policy.xml to extract deployment name, replace dots with -dot-, use set-backend-service backend-id="pool-{deploymentName}", keep authentication-managed-identity resource="https://cognitiveservices.azure.com" in inbound policy, modify oaiv1-policy.xml similarly for model field, replace hardcoded DCE/DCR with {{dce-endpoint}}, {{dcr-immutable-id}}, {{stream-name}}

Add comprehensive outputs — Export APIM gateway URL, managed identity client ID and principal ID, all AI Foundry project IDs and endpoints by region, list of backend pool names, DCE ingestion endpoint, deployment counts per region, manual steps for policy attachment with updated policy files