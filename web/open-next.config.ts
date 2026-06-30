// open-next.config.ts
//
// Minimal config -- Phase 1 doesn't use ISR/cached rendering, every page
// fetches fresh from Supabase on each request, so no KV/R2 cache binding
// is needed yet. Add caching config here if ISR is introduced later.

import { defineCloudflareConfig } from "@opennextjs/cloudflare";

export default defineCloudflareConfig();
