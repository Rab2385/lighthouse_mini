// Lighthouse service worker: makes the installed web app open without a
// connection (issue #12). Replaces Flutter's own, deprecated service worker.
//
// Network first: online you always get the newest files, and every file the
// app loads is kept in the cache. Offline, the cached copy is served.

const CACHE = 'lighthouse-v1';

self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      // Drop caches from older versions of this worker.
      for (const name of await caches.keys()) {
        if (name !== CACHE) await caches.delete(name);
      }
      await self.clients.claim();
    })(),
  );
});

// Files the page loaded before this worker took control (the very first
// visit) are sent over by index.html, so the first visit is enough.
self.addEventListener('message', (event) => {
  if (event.data?.type !== 'cache' || !Array.isArray(event.data.urls)) return;
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE);
      await Promise.allSettled(
        event.data.urls
          .filter((url) => new URL(url).origin === self.location.origin)
          .map(async (url) => {
            if (!(await cache.match(url))) await cache.add(url);
          }),
      );
    })(),
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (
    request.method !== 'GET' ||
    new URL(request.url).origin !== self.location.origin
  ) {
    return;
  }

  event.respondWith(
    (async () => {
      const cache = await caches.open(CACHE);
      try {
        const response = await fetch(request);
        if (response.ok) await cache.put(request, response.clone());
        return response;
      } catch (error) {
        const cached = await cache.match(request, { ignoreSearch: true });
        if (cached) return cached;
        if (request.mode === 'navigate') {
          const page = (await cache.match('./')) ?? (await cache.match('index.html'));
          if (page) return page;
        }
        throw error;
      }
    })(),
  );
});
