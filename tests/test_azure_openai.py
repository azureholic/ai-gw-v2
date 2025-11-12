"""
Test script for Azure OpenAI API via APIM Gateway
"""
import os
from openai import AzureOpenAI
from azure.identity import DefaultAzureCredential, get_bearer_token_provider

# Configuration
APIM_ENDPOINT = os.getenv("APIM_ENDPOINT", "https://apim-acc-genaishared-lxpp27stioik4.azure-api.net")
API_VERSION = "2024-02-15-preview"
DEPLOYMENT_NAME = "gpt-4o-mini-2024-07-18"  # Change to your deployment name

def test_chat_completion():
    """Test chat completion using Azure OpenAI API through APIM with managed identity"""
    
    # Use DefaultAzureCredential for authentication
    credential = DefaultAzureCredential()
    token_provider = get_bearer_token_provider(
        credential,
        "https://cognitiveservices.azure.com/.default"
    )
    
    # Initialize Azure OpenAI client with APIM endpoint
    client = AzureOpenAI(
        azure_endpoint=APIM_ENDPOINT,
        api_version=API_VERSION,
        azure_ad_token_provider=token_provider
    )
    
    try:
        # Make a chat completion request
        response = client.chat.completions.create(
            model=DEPLOYMENT_NAME,
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": "What is Azure API Management?"}
            ],
            max_tokens=150,
            temperature=0.7
        )
        
        # Print the response
        print("✓ Chat completion successful!")
        print(f"\nModel: {response.model}")
        print(f"\nResponse:\n{response.choices[0].message.content}")
        print(f"\nUsage:")
        print(f"  Prompt tokens: {response.usage.prompt_tokens}")
        print(f"  Completion tokens: {response.usage.completion_tokens}")
        print(f"  Total tokens: {response.usage.total_tokens}")
        
        return True
        
    except Exception as e:
        print(f"✗ Error during chat completion: {e}")
        return False

def test_streaming_completion():
    """Test streaming chat completion using Azure OpenAI API through APIM"""
    
    credential = DefaultAzureCredential()
    token_provider = get_bearer_token_provider(
        credential,
        "https://cognitiveservices.azure.com/.default"
    )
    
    client = AzureOpenAI(
        azure_endpoint=APIM_ENDPOINT,
        api_version=API_VERSION,
        azure_ad_token_provider=token_provider
    )
    
    try:
        print("\n✓ Starting streaming completion...")
        
        # Make a streaming chat completion request
        stream = client.chat.completions.create(
            model=DEPLOYMENT_NAME,
            messages=[
               {"role": "user", "content": "What is Azure API Management?"}
            ],
            max_tokens=100,
            stream=True
        )
        
        print("\nStreamed response:")
        usage_info = None
        for chunk in stream:
            if chunk.choices and len(chunk.choices) > 0 and chunk.choices[0].delta.content:
                print(chunk.choices[0].delta.content, end="", flush=True)
            # Capture usage from the final chunk
            if hasattr(chunk, 'usage') and chunk.usage:
                usage_info = chunk.usage
        
        print("\n")
        if usage_info:
            print(f"\nUsage:")
            print(f"  Prompt tokens: {usage_info.prompt_tokens}")
            print(f"  Completion tokens: {usage_info.completion_tokens}")
            print(f"  Total tokens: {usage_info.total_tokens}")
        
        print("\n✓ Streaming completion successful!")
        return True
        
    except Exception as e:
        print(f"\n✗ Error during streaming completion: {e}")
        return False

if __name__ == "__main__":
    print("=" * 60)
    print("Testing Azure OpenAI API via APIM Gateway")
    print("=" * 60)
    print(f"Endpoint: {APIM_ENDPOINT}")
    print(f"Deployment: {DEPLOYMENT_NAME}")
    print("=" * 60)
    
    # Run tests
    test_results = []
    
    print("\n[1/2] Testing chat completion...")
    test_results.append(test_chat_completion())
    
    print("\n[2/2] Testing streaming completion...")
    test_results.append(test_streaming_completion())
    
    # Summary
    print("\n" + "=" * 60)
    print(f"Results: {sum(test_results)}/{len(test_results)} tests passed")
    print("=" * 60)
    
    exit(0 if all(test_results) else 1)
