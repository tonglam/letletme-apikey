export default {
  async scheduled(event, env, ctx) {
    const apps = env.APPS ? env.APPS.split(",") : []; // Load apps from env
    const webhookUrl = env.WEBHOOK_URL;
    const apiToken = env.API_TOKEN;

    for (const app of apps) {
      try {
        const newKey = generateApiKey();

        await Promise.all([
          env.API_KEYS.put(app, newKey),
          env.API_KEYS.put(`${app}_last_rotated`, new Date().toISOString()),
        ]);

        await sendWebhookWithRetry(webhookUrl, app, newKey, apiToken);
        console.log(`[${app}] API key rotated successfully.`);
      } catch (err) {
        console.error(`[${app}] API key rotation failed: ${err.message}`);
      }
    }
  },

  // Add fetch handler for API access
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname.split("/").filter(Boolean);

    // Simple API to check last rotation time
    if (path[0] === "status" && path[1]) {
      const app = path[1];
      const lastRotated = await env.API_KEYS.get(`${app}_last_rotated`);

      if (!lastRotated) {
        return new Response("App not found", { status: 404 });
      }

      return new Response(
        JSON.stringify({
          app,
          lastRotated,
          message: "API key rotation status",
        }),
        {
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    return new Response("Not found", { status: 404 });
  },
};

function generateApiKey() {
  return crypto
    .getRandomValues(new Uint8Array(32))
    .reduce((str, byte) => str + byte.toString(16).padStart(2, "0"), "");
}

async function sendWebhookWithRetry(url, app, key, apiToken, maxRetries = 3) {
  if (!url) return; // Skip if webhook URL is not provided

  const payload = JSON.stringify({
    appId: app,
    newApiKey: key,
    timestamp: new Date().toISOString(),
  });

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Api-Token": apiToken,
        },
        body: payload,
      });

      if (response.ok) return;
      throw new Error(`HTTP ${response.status}`);
    } catch (err) {
      if (attempt === maxRetries) throw err;
      await new Promise((r) => setTimeout(r, 1000 * 2 ** (attempt - 1)));
    }
  }
}
