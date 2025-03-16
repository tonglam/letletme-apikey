export default {
  async scheduled(event, env, ctx) {
    const apps = env.APPS ? env.APPS.split(",") : [];

    for (const app of apps) {
      try {
        const newKey = generateApiKey();
        await Promise.all([
          env.API_KEYS.put(`${app}_key`, newKey),
          env.API_KEYS.put(`${app}_last_rotated`, new Date().toISOString()),
        ]);
        console.log(`[${app}] API key rotated successfully.`);
      } catch (err) {
        console.error(`[${app}] API key rotation failed: ${err.message}`);
      }
    }
  },

  // Handle HTTP requests
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    if (url.pathname === "/trigger") {
      // Run the scheduled task manually
      await this.scheduled(null, env, ctx);
      return new Response("Keys rotated", { status: 200 });
    }
    return new Response("Not Found", { status: 404 });
  },
};

function generateApiKey() {
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return Array.from(array)
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}
