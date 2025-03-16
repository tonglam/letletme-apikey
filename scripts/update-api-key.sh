#!/bin/sh

# Configuration
APP_NAME="your-app-name"
API_URL="your-api-url"
KEYS_DIR="your-keys-dir"
CF_ACCOUNT_ID="your-account-id"
CF_NAMESPACE_ID="your-namespace-id"
CF_API_TOKEN="your-api-token"

# Ensure keys directory exists
mkdir -p "$KEYS_DIR"

# Function to get current API key from file
get_current_key() {
    if [ -f "$KEYS_DIR/$APP_NAME.key" ]; then
        cat "$KEYS_DIR/$APP_NAME.key"
        return 0
    else
        echo ""
        return 1
    fi
}

# Function to test API key
test_api_key() {
    local key=$1
    if [ -z "$key" ]; then
        return 1
    fi
    
    echo "Testing API key..."
    local status_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "X-API-Key: $key" \
        "$API_URL")
    
    if [ "$status_code" = "200" ]; then
        return 0
    else
        echo "API test failed with status: $status_code"
        return 1
    fi
}

# Function to fetch new key from Cloudflare KV
fetch_new_key() {
    # First try GET to see if key exists
    local response=$(curl -s \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json" \
        "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/storage/kv/namespaces/$CF_NAMESPACE_ID/values/${APP_NAME}_key")
    
    # Check if response is valid JSON
    if ! echo "$response" | jq -e . >/dev/null 2>&1; then
        # If not JSON, it's probably the actual key
        if [ ! -z "$response" ]; then
            echo "$response"
            return 0
        fi
        echo "Error: Empty response from Cloudflare" >&2
        return 1
    fi

    # If JSON, check for errors
    local success=$(echo "$response" | jq -r '.success')
    if [ "$success" = "false" ]; then
        local error_msg=$(echo "$response" | jq -r '.errors[0].message')
        echo "Error from Cloudflare KV: $error_msg" >&2
        return 1
    fi

    # If JSON but success=true, extract the value
    local result=$(echo "$response" | jq -r '.result // .')
    if [ ! -z "$result" ]; then
        echo "$result"
        return 0
    fi

    echo "Error: No key found in KV" >&2
    return 1
}

# Function to update key file
update_key_file() {
    local new_key=$1
    if [ -z "$new_key" ] || case "$new_key" in *Error*|*error*) true;; *) false;; esac; then
        echo "Error: Invalid key content" >&2
        return 1
    fi
    
    echo "$new_key" > "$KEYS_DIR/$APP_NAME.key"
    chmod 600 "$KEYS_DIR/$APP_NAME.key"  # Secure file permissions
    return 0
}

# Main script

# Test current API key
current_key=$(get_current_key)
if [ ! -z "$current_key" ]; then
    if test_api_key "$current_key"; then
        echo "Current API key is working fine"
        exit 0
    fi
    echo "Current key failed, will fetch new key"
else
    echo "No current key found"
fi

# Fetch new key from KV
echo "Fetching new API key from Cloudflare KV..."
new_key=$(fetch_new_key)

# Check if fetch was successful
if [ $? -ne 0 ] || [ -z "$new_key" ] || case "$new_key" in *Error*) true;; *) false;; esac; then
    echo "Failed to fetch valid key from Cloudflare KV"
    exit 1
fi

# Update key file
if ! update_key_file "$new_key"; then
    echo "Failed to update key file"
    exit 1
fi

echo "API key updated successfully"

# Verify new key works
if test_api_key "$new_key"; then
    echo "New API key verified successfully"
    exit 0
else
    echo "Error: New API key verification failed"
    exit 1
fi 