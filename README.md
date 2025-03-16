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

1. Install dependencies:

```bash
pnpm install
```

2. Configure your KV namespace:

```bash
pnpm wrangler kv:namespace create API_KEYS
```

3. Update `wrangler.toml` with your KV namespace ID:

```toml
[[kv_namespaces]]
binding = "API_KEYS"
id = "your-namespace-id"
```

4. Configure your apps in `wrangler.toml`:

```toml
[vars]
APPS = "app1,app2"  # Comma-separated list of apps
```

## Deployment

Deploy to Cloudflare Workers:

```bash
pnpm wrangler deploy
```

## Usage

### Automatic Rotation

Keys are automatically rotated daily at midnight (UTC). Each app gets:

- A new API key stored at `app_name`
- A rotation timestamp stored at `app_name_last_rotated`

### Manual Trigger

Trigger key rotation manually:

```bash
curl https://your-worker.workers.dev/trigger
```

### Accessing Keys

Use Cloudflare's API or Workers KV to access the keys:

```bash
# Get current API key
pnpm wrangler kv:key get --binding=API_KEYS --preview false "app_name"

# Get last rotation time
pnpm wrangler kv:key get --binding=API_KEYS --preview false "app_name_last_rotated"
```

### App Server Key Updates

The `scripts/update-api-key.sh` script automatically manages API keys on app servers:

1. Set up environment variable:

```bash
export CF_API_TOKEN="your-cloudflare-api-token"
```

2. Add to crontab (runs every 10 minutes):

```bash
*/10 * * * * /path/to/update-api-key.sh website
*/10 * * * * /path/to/update-api-key.sh wechat
```

The script:

- Checks if current key can access the API
- Fetches new key from KV if needed
- Updates key file in `/home/workspace/letletme-api/keys/`
- Verifies the new key works
- Uses secure file permissions (600)

## Key Format

- 64-character hexadecimal string
- Generated from 32 random bytes
- Example: `f1ee11a2220bd9072690fb45d20c82ab74064784239fec365ecd0d90d1e70d55`

## Development

1. Run locally:

```bash
pnpm wrangler dev
```

2. Test key rotation:

```bash
curl http://127.0.0.1:8787/trigger
```

## Security

- Keys are generated using cryptographically secure random values
- Keys are stored in Cloudflare KV with restricted access
- No external webhook dependencies
- Apps should use secure methods to fetch their keys
- Key files on app servers use restricted permissions (600)
- API tokens should be stored securely as environment variables

## License

MIT
