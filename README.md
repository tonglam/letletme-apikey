# letletme-apikey

A Cloudflare Worker for automatic API key rotation.

## Features

- Automatically rotates API keys on a configurable schedule
- Stores API keys in Cloudflare KV
- Sends webhooks when keys are rotated
- Simple status API to check last rotation time

## Setup

1. Install Wrangler CLI:

```
npm install -g wrangler
```

2. Login to your Cloudflare account:

```
wrangler login
```

3. Create a KV namespace:

```
wrangler kv:namespace create API_KEYS
```

4. Update the `wrangler.toml` file with your KV namespace ID

5. Configure environment variables in the `wrangler.toml` file:
   - `APPS`: Comma-separated list of app IDs
   - `WEBHOOK_URL`: URL to notify when keys are rotated
   - `API_TOKEN`: Token for webhook authentication

## Deployment

Deploy to Cloudflare:

```
wrangler deploy
```

## Usage

The worker will automatically rotate API keys based on the configured cron schedule.

To check the status of an app's API key rotation:

```
curl https://your-worker.your-subdomain.workers.dev/status/your-app-id
```
