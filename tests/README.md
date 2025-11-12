# Azure OpenAI API Testing

## Setup

1. Install dependencies:
```powershell
pip install -r requirements.txt
```

2. Authenticate with Azure:
```powershell
az login
```

3. Set the APIM endpoint (optional, defaults to current deployment):
```powershell
$env:APIM_ENDPOINT = "https://apim-acc-genaishared-mndjc5mvpg7nk.azure-api.net"
```

## Run Tests

### Azure OpenAI API (Native Azure format)
```powershell
python test_azure_openai.py
```

### OpenAI v1 API (OpenAI-compatible format)
```powershell
python test_openai_v1.py
```

## Configuration

### test_azure_openai.py
- **Authentication**: Azure DefaultAzureCredential (managed identity/Azure CLI)
- **Endpoint**: APIM gateway URL (Azure OpenAI native format)
- **API Version**: 2024-02-15-preview
- **Model**: gpt-4o-mini-2024-07-18-standard (full deployment name)

### test_openai_v1.py
- **Authentication**: Azure DefaultAzureCredential (managed identity/Azure CLI)
- **Endpoint**: APIM gateway URL + /v1 (OpenAI-compatible format)
- **Model**: gpt-4o-mini (simplified model name)

## Tests Included

1. **Chat Completion**: Single request/response
2. **Streaming Completion**: Streaming response chunks
