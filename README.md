# letletme-apikey

A Cloudflare Worker service that automatically generates and rotates API keys for multiple applications.

## Features

- 🔄 Automatic daily API key rotation
- 🔐 Secure key generation using crypto.getRandomValues
- 📦 Key storage in Cloudflare KV
- ⏰ Configurable cron schedule
- 🔧 Manual trigger endpoint for testing
- 🔄 Automatic key update script for app servers

## Setup

### Prerequisites

- [Node.js](https://nodejs.org/) (v16 or later)
- [pnpm](https://pnpm.io/) package manager
- [Cloudflare account](https://dash.cloudflare.com/sign-up) with Workers access

### Installation

1. Clone the repository:

```bash
git clone https://github.com/yourusername/letletme-apikey.git
cd letletme-apikey
```

2. Install dependencies:

```bash
pnpm install
```

### Configuration

1. Create a KV namespace for storing API keys:

```bash
pnpm wrangler kv:namespace create API_KEYS
```

2. Update `wrangler.toml` with your KV namespace ID:

```toml
[[kv_namespaces]]
binding = "API_KEYS"
id = "your-namespace-id"
preview_id = "your-namespace-id"
```

3. Configure your apps in `wrangler.toml`:

```toml
[vars]
APPS = "app1,app2"  # Comma-separated list of apps
```

4. Configure the cron schedule (default is daily at midnight UTC):

```toml
[triggers]
crons = ["0 0 * * *"]  # Cron syntax
```

## Deployment

Deploy to Cloudflare Workers:

```bash
pnpm run deploy
```

## Usage

### Automatic Rotation

Keys are automatically rotated according to the cron schedule. For each app, the worker:

- Generates a new 64-character hexadecimal API key
- Stores the key at `{app_name}_key` in KV storage
- Stores the rotation timestamp at `{app_name}_last_rotated`

### Manual Trigger

You can trigger key rotation manually by making a request to the `/trigger` endpoint:

```bash
curl https://your-worker.workers.dev/trigger
```

### Accessing Keys

Use Cloudflare's API or Workers KV to access the keys:

```bash
# Get current API key
pnpm wrangler kv:key get --binding=API_KEYS "app_name_key"

# Get last rotation time
pnpm wrangler kv:key get --binding=API_KEYS "app_name_last_rotated"
```

## Client Setup

### Update Script Configuration

The `scripts/update-api-key.sh` script automatically fetches and updates API keys on client servers.

1. Edit the script to configure your environment:

```bash
# Configuration
APP_NAME="your-app-name"
API_URL="your-api-url"
KEYS_DIR="/path/to/keys/directory"
CF_ACCOUNT_ID="your-cloudflare-account-id"
CF_NAMESPACE_ID="your-kv-namespace-id"
```

2. Set up your Cloudflare API token as an environment variable:

```bash
export CF_API_TOKEN="your-cloudflare-api-token"
```

3. Add to crontab to run periodically (example: every 10 minutes):

```bash
*/10 * * * * /path/to/update-api-key.sh
```

### How the Update Script Works

The script:

1. Tests if the current key can access your API
2. Fetches a new key from KV if needed
3. Updates the key file with secure permissions (600)
4. Verifies the new key works with your API

## Development

Run the worker locally for testing:

```bash
pnpm run dev
```

Test key rotation locally:

```bash
curl http://127.0.0.1:8787/trigger
```

## Security Best Practices

- API keys are generated using cryptographically secure random values
- Keys are stored in Cloudflare KV with restricted access
- Key files on client servers use restricted permissions (600)
- API tokens should be stored securely as environment variables
- Regularly audit access to your Cloudflare account and KV namespaces

## Key Format

- 64-character hexadecimal string
- Generated from 32 random bytes
- Example format: `f1ee11a2220bd9072690fb45d20c82ab74064784239fec365ecd0d90d1e70d55`

## License

MIT
