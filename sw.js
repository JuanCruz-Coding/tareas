/* Service worker de Tareas: hace que la app abra sin internet y que pueda mostrar notificaciones.

   Estrategia:
   - Las páginas (HTML) van primero a la red, así cada cambio publicado llega solo. Sin red,
     se usa la última copia guardada.
   - Todo lo demás (librerías del CDN, fuentes, íconos) sale primero de la copia guardada. Las
     librerías llevan la versión en la URL, así que una copia vieja nunca queda desactualizada.

   Si se cambia este archivo o la lista PRECARGA, hay que subir el número de CACHE: así el
   navegador instala la versión nueva y borra la vieja. */

const CACHE = 'tareas-v1';
const CDN = 'cdn.jsdelivr.net';

const PRECARGA = [
  './',
  './tareas.html',
  './manifest.webmanifest',
  './apple-touch-icon.png',
  './icono-192.png',
  './icono-512.png',
  'https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css',
  'https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css',
  'https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/fonts/bootstrap-icons.woff2',
  'https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js',
  'https://cdn.jsdelivr.net/npm/fullcalendar@6.1.15/index.global.min.js',
  'https://cdn.jsdelivr.net/npm/@fullcalendar/core@6.1.15/locales/es.global.min.js',
];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(PRECARGA)).then(() => self.skipWaiting()));
});

// Al activar una versión nueva se borran las copias de las anteriores
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(claves => Promise.all(claves.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

function guardar(req, resp) {
  // Las respuestas "opaque" son las del CDN pedidas sin CORS: no se pueden leer, pero sí guardar
  if (resp.ok || resp.type === 'opaque') {
    const copia = resp.clone();
    caches.open(CACHE).then(c => c.put(req, copia));
  }
  return resp;
}

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);

  // Páginas: primero la red
  if (req.mode === 'navigate') {
    e.respondWith(
      fetch(req)
        .then(resp => guardar(req, resp))
        .catch(() => caches.match(req, { ignoreSearch: true }).then(r => r || caches.match('./tareas.html')))
    );
    return;
  }

  // Solo se guarda lo propio y lo del CDN; cualquier otra cosa pasa de largo
  const esCDN = url.hostname === CDN;
  if (url.origin !== self.location.origin && !esCDN) return;

  // Lo demás: primero la copia guardada. En el CDN se ignora la query, porque la fuente de
  // íconos se pide con un hash (?dd67...) y la versión ya está en la ruta.
  e.respondWith(
    caches.match(req, { ignoreSearch: esCDN })
      .then(guardada => guardada || fetch(req).then(resp => guardar(req, resp)))
  );
});

// Tocar una notificación trae la app al frente y abre esa tarea
self.addEventListener('notificationclick', e => {
  e.notification.close();
  const id = e.notification.data && e.notification.data.id;
  e.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(ventanas => {
      const v = ventanas[0];
      if (v) {
        v.postMessage({ abrirTarea: id });
        return v.focus();
      }
      return self.clients.openWindow('./tareas.html' + (id ? '#tarea=' + id : ''));
    })
  );
});
