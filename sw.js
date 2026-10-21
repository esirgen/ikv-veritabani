// İnanır Kule Vinç - %100 Çevrimdışı (Offline-First) Service Worker v15
const CACHE_NAME = 'ikv-offline-v15';
const CORE_ASSETS = [
  './',
  './index.html',
  './manifest.json',
  './inanir_kule_vinc_icon.png',
  './inanir_kule_vinc_icon.svg'
];

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then(async (cache) => {
      for (const asset of CORE_ASSETS) {
        try {
          const res = await fetch(asset, { cache: 'reload' });
          if (res && res.ok) {
            await cache.put(asset, res.clone());
          }
        } catch (e) {}
      }
    })
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) {
            return caches.delete(key);
          }
        })
      )
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;

  const url = new URL(req.url);

  // Canlı bulut senkronizasyonu (Firebase / ntfy / bytebin) isteklerini önbellekleme
  if (
    url.hostname.includes('firebasedatabase.app') ||
    url.hostname.includes('ntfy.sh') ||
    url.hostname.includes('ntfy.envs.net') ||
    url.hostname.includes('bytebin.lucko.me')
  ) {
    return;
  }

  // Sayfa açılışı (navigation) veya index.html isteklerinde: Çevrimdışıysa anında önbellekten döndür
  if (req.mode === 'navigate' || url.pathname.endsWith('/') || url.pathname.endsWith('/index.html')) {
    event.respondWith(
      fetch(req)
        .then((networkRes) => {
          if (networkRes && networkRes.ok) {
            const copy = networkRes.clone();
            caches.open(CACHE_NAME).then((cache) => {
              cache.put(req, copy.clone());
              cache.put('./', copy.clone());
              cache.put('./index.html', copy);
            });
          }
          return networkRes;
        })
        .catch(async () => {
          const cache = await caches.open(CACHE_NAME);
          return (
            (await cache.match(req)) ||
            (await cache.match('./index.html')) ||
            (await cache.match('./'))
          );
        })
    );
    return;
  }

  // Diğer statik kaynaklar için Cache-First, yoksa Network
  event.respondWith(
    caches.match(req).then((cachedRes) => {
      if (cachedRes) return cachedRes;
      return fetch(req)
        .then((netRes) => {
          if (netRes && netRes.ok && (url.origin === self.location.origin || url.hostname.includes('cdn.tailwindcss.com') || url.hostname.includes('cdnjs.cloudflare.com'))) {
            const copy = netRes.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(req, copy));
          }
          return netRes;
        })
        .catch(() => cachedRes);
    })
  );
});
