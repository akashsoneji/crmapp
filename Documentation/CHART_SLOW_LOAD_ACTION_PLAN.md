# Chart Slow-Load — Root Cause & Action Plan (Mobile ↔ Backend)

**Audience:** Backend / Web team  
**App:** Flutter (Android & iOS), `flutter_inappwebview` 6.x  
**Affected flow:** First time the user opens the **Chart** tab (and the very first cold launch).

---

## TL;DR

The mobile chart is a WebView loading a Vue/TradingView SPA at  
`{chartBaseUrl}/mobile-chart?symbol={SYMBOL}&theme={THEME}` (e.g. `https://demo3.tenaxcode.com/mobile-chart`).

That page **dynamically loads ~5 MB of vendor JS + CSS from your server** the first time a user opens it. The first-time download is the bottleneck (3–5 s on a typical 4G connection). Mobile teams can hide the wait with a background pre-warm, but the only durable fix is to **reduce the size of the bundle and the number of round-trips the first load needs**.

---

## 1. What the mobile app does today

- On first chart open, `InAppWebView` requests `GET /mobile-chart?symbol=…&theme=…`.
- That HTML is a 946-byte shell. The heavy work happens in the assets the HTML pulls in.
- The trading library (`charting_library.standalone.js`) **dynamically loads more bundles at runtime** — these are not visible in the HTML and were the original cause of confusion in profiling.

### 1.1 Files pulled during first load (measured against `demo3.tenaxcode.com`)

| URL | Size | Notes |
|---|---:|---|
| `/dist-demo3/assets/index-62167785.js` | 1,386,571 B | App entry, vendors, Vue runtime |
| `/dist-demo3/assets/index-dafb0e19.css` | 860,154 B | All styles inlined into one file |
| `/dist-demo3/charting_library/charting_library.standalone.js` | 55,730 B | Loads more bundles at runtime |
| `/dist-demo3/charting_library/bundles/library.668013b6b41ce2feaa5c.js` | **2,481,955 B** | TradingView charting library (the big one) |
| `/dist-demo3/charting_library/bundles/runtime.ddf792da21403fea7e07.js` | 25,974 B | Webpack runtime |
| `/dist-demo3/charting_library/bundles/8971.352a74bc5eebf8040884.js` | 74,712 B | Internal TradingView chunk |
| `/dist-demo3/tenax-datafeed.js` | 44,167 B | UDF datafeed glue |
| `https://cdnjs.cloudflare.com/.../font-awesome/6.0.0/css/all.min.css` | 18,062 B | External CDN |
| **Total** | **~4.9 MB** | Compressed transfer is smaller but parse cost is full size |

### 1.2 Cache headers are correct ✅

All app-owned assets are already served with:

```
Cache-Control: max-age=315360000
Cache-Control: public, immutable
Expires: Thu, 31 Dec 2037 23:55:55 GMT
ETag: "6a3a2543-15284b"
```

Good — this is what allows the mobile team to pre-warm the WebView disk cache. **Please keep these headers on every hashed asset forever. If you ever change them, pre-warm will silently stop working.**

The only header that should **never** be served as `immutable` is `mobile-chart` (the HTML shell itself) and any non-hashed files.

---

## 2. Where the time goes (cold first launch)

| Step | Time | Notes |
|---|---:|---|
| Flutter engine + Firebase + GetX services init | 1.5–2.5 s | App-side, not on your plate |
| Splash → auth check → token validation → accounts fetch | 1–3 s | App-side |
| DNS + TCP + TLS handshake to `demo3.tenaxcode.com` | 0.3–0.8 s | Mobile now preconnects in parallel |
| **Download of ~5 MB JS+CSS** | **3–5 s on 4G** | **This is the floor** |
| WebView parse + JS execute (TradingView lib is heavy) | 1–2 s | Browser-side, depends on device |
| **Total cold first load (current)** | **~7–10 s** | |
| **Total cold first load (after mobile-side pre-warm)** | **~5–6 s** | Network overlaps with auth |
| Second launch onward (cache hit) | ~1–2 s | |

So the question is not "why is the app slow?" — it's "**how do we make the 5 MB download + parse cheaper?**"

---

## 3. What the mobile team has already done

These are live in the codebase, so you can see them:

- **Background pre-warm** via `HeadlessInAppWebView` (`lib/services/chart_preload_service.dart`). The chart URL is loaded off-screen the moment the app's first frame paints, in parallel with auth/services.
- **DNS+TCP+TLS preconnect** in the same service (a HEAD request that warms the socket before the headless WebView even starts).
- **Cache-friendly settings** in `ChartInAppWebView`:
  - `cacheMode: LOAD_CACHE_ELSE_NETWORK`
  - `cacheEnabled: true`
  - `domStorageEnabled: true`
  - `hardwareAcceleration: true`
  - `useHybridComposition: true`
  - `offscreenPreRaster: true`
- **Single-instance warm webview kept alive** for the whole session so cache stays hot.
- **No-op for repeat symbols** in the chart (`updateSymbol` JS bridge) so changing symbols never re-downloads the bundle.

These changes are in `lib/services/chart_preload_service.dart`, `lib/widgets/chart_inapp_webview.dart`, and `lib/main.dart`.

---

## 4. What we need from the backend / web team

In priority order — items 1–3 are quick wins, item 4 is the long-term fix.

### 4.1 Reduce the bundle size (biggest win, ~40% saving likely possible)

- **Split `index-dafb0e19.css` (860 KB).** The CSS is unusually large for a Vue app. Audit for:
  - Unused component styles being shipped.
  - Tailwind/Bootstrap/UI-libs imported globally even when most components don't use them.
  - Inlined base64 images or fonts.
  - Uncompressed icon fonts (Font Awesome CSS is **18 KB** which is fine, but check the woff2/ttf it pulls).
- **Split the `index` JS bundle** (1.4 MB). Vite/webpack defaults can be tuned:
  - Code-split by route (lazy-load `/mobile-chart` and the trade screens, do not bundle the entire app into one chunk).
  - Move big libs to dynamic imports (e.g. `charting_library` should be dynamic-imported, not required in the main chunk — see 4.2).
  - Tree-shake unused lodash / moment / dayjs. Replace moment with dayjs (14 KB vs 70 KB) if still in use.
- **Audit `library.js` (2.48 MB) overrides.** Most apps that use the standalone charting library ship a much smaller lib because they customize it:
  - If you don't use all 18+ chart types, you can strip unused ones in the library build.
  - If you don't use the drawings toolbar's full set, you can drop those bundles.
  - See [TradingView's "Saving the bundle size" docs](https://www.tradingview.com/charting-library-docs/latest/saving_bundle_size/) — typical reductions are 30–60%.

### 4.2 Lazy-load `charting_library` after the page shell is interactive

Right now `charting_library.standalone.js` is loaded as a regular `<script>` in `<body>`, and that script then dynamically loads the 2.48 MB `bundles/library.*.js`. The user pays for this on every cold visit.

Recommendation:

- Render a skeleton / "Loading chart…" UI from the SPA shell in <100 ms.
- Use `requestIdleCallback` (or a setTimeout) to import `charting_library` *after* the first paint so the user sees the app frame first.
- This will make first-paint feel instant even before the bundle is downloaded.

### 4.3 Serve over HTTP/2 + Brotli + consider a CDN

- All heavy assets are already `immutable`, so a CDN is a free win. Move the static `/dist-demo3/...` assets behind Cloudflare / CloudFront / Akamai. Origin is fine, but edge cache shaves 200–500 ms on first byte on 4G.
- Confirm Brotli (`Content-Encoding: br`) is on for all text assets. We saw `Content-Length` of compressed size (e.g. 1.39 MB for `index.js`), but verify the actual on-the-wire size — if Nginx is configured without `brotli on;` you'll ship gzip at best.
- The Font Awesome CSS is on `cdnjs.cloudflare.com` — good. But the woff/woff2 fonts it points to are also on cdnjs by default; confirm they have `Cache-Control: public, max-age=...` (they do, but worth re-checking after Font Awesome version bumps).

### 4.4 Ship the bundle inside the mobile app (extreme option)

The mobile team can ship a copy of `/dist-demo3/...` inside the APK (~5 MB increase) and intercept the WebView's network requests with `shouldInterceptRequest` to serve them from local assets. This makes cold first launch effectively instant (no network).

**Trade-offs** the backend must support:

- The hashed filenames (`index-62167785.js`, `library.668013b6b41ce2feaa5c.js`) change on every build (cache-busting). The mobile app release must use the **same hash** as the server. So we need a small CI step:
  - On web deploy, write the current `index-*.js`, `index-*.css`, `library-*.js`, etc. hashes to a `mobile-asset-manifest.json`.
  - The mobile team fetches that manifest as part of their release build, and the Flutter app checks it on startup: if `mobile-asset-manifest.json` on the server matches the bundled one, serve locally; otherwise fall back to network.
- Need to add `Content-Type` headers and the correct paths in the `shouldInterceptRequest` map.

This is the **only way to make cold first launch truly <2s on slow networks**. Worth doing if chart open is on a critical conversion path.

### 4.5 Add a `Server-Timing` header for profiling (small effort, huge value)

Add the `Server-Timing` header to `GET /mobile-chart` and the static assets. This lets the mobile team see TTFB, download time, etc. in WebView devtools / Chrome without guessing.

Example:

```
Server-Timing: cdn;dur=0.1, app;dur=0.05, total;dur=0.3
```

---

## 5. Suggested order of work

1. **(1 day)** Confirm Brotli is on; confirm a CDN is in front of `/dist-demo3/...`. Measure new first-load TTFB.
2. **(1–2 days)** Lazy-load `charting_library` after first paint (4.2). Big perceived-win with no bundle changes.
3. **(3–5 days)** Bundle audit: split CSS, code-split by route, strip unused TradingView pieces (4.1). Target: get total cold download under 2 MB.
4. **(Optional, ongoing)** Manifest-driven offline-bundle in the mobile app (4.4) for markets with poor connectivity.

---

## 6. Asks for the backend team

- [ ] **Confirm `Cache-Control: public, immutable, max-age=315360000` is permanent** on every hashed asset under `/dist-demo3/`. Mobile pre-warm depends on it.
- [ ] **Confirm Brotli is enabled** for all text assets in `/dist-demo3/`.
- [ ] **Reply with the current sizes** of `index-*.js` and `index-*.css` after their next refactor, and the size of `bundles/library-*.js` after you strip unused TradingView features.
- [ ] **Implement 4.2 (lazy-load charting library)** in the next sprint — this is the single biggest perceived-perf win on the mobile side and requires only frontend work on the SPA.
- [ ] **Generate a `mobile-asset-manifest.json`** on every web deploy (even if mobile doesn't act on it yet) — this unblocks offline-bundling later.
- [ ] (Optional) Add `Server-Timing` headers.

---

## 7. Reference: relevant mobile files

- `lib/services/chart_preload_service.dart` — pre-warm + preconnect
- `lib/widgets/chart_inapp_webview.dart` — on-screen WebView settings + symbol bridge
- `lib/screens/home/chart_screen.dart` — builds the chart URL (`{chartBaseUrl}/mobile-chart?symbol=…&theme=…`)
- `lib/clients/tenax/config.dart` (and other flavors) — `chartBaseUrl`
- `lib/main.dart` — `MyGetXApp.build` triggers `ChartPreloadService.prewarm()` on first frame
