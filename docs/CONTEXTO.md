# Tareas: contexto del proyecto

## Qué es

Una app de tareas personal, pensada para usarse todos los días en el iPhone y en la PC. La
regla que ordena todo es que sea simple al extremo: si se complica, se deja de usar. Por eso
tiene pocas pantallas (Hoy, Listas, Calendario), un repaso guiado de cuatro pasos y un botón +
para anotar rápido, que entiende atajos como "mañana 9:00 !alta @Santiago".

Es un solo archivo, `tareas.html`, con HTML, CSS y JavaScript sin build. Usa Bootstrap 5,
Bootstrap Icons y FullCalendar 6 por CDN. Está publicada en GitHub Pages:
https://juancruz-coding.github.io/tareas/

Estado al 2026-09-23: funciona completa. Se probó en Chrome de escritorio y con el celular
emulado; en un iPhone de verdad todavía no.

## Decisiones tomadas

**Los datos viven solo en el navegador de cada dispositivo** (2026-09-23). Todo va en
`localStorage` bajo la clave `tareasApp.v1`, en JSON. No hay servidor ni sincronización: para
pasar las tareas de la PC al iPhone se exporta un JSON en uno y se importa en el otro, desde
Ajustes. Se eligió así porque cualquier sincronización suma una cuenta, un backend o las dos
cosas, y la app tiene que ser simple.

**El login es de mentira, y se sabe** (2026-09-23). Usuario y contraseña están escritos en el
código (`LOGIN_USUARIO` y `LOGIN_CLAVE` en `tareas.html`), y el código es público. Cualquiera
los lee con "ver código fuente". Se le avisó al dueño antes de hacerlo, junto con dos
alternativas: un candado local cuya contraseña no fuera al código, o ningún login. Eligió el
login fijo. Solo frena a quien abre la URL sin saber mirar. Lo que sí protege de verdad es
que las tareas no están en el servidor: quien abre la URL ve una app vacía con los ejemplos.
La sesión queda recordada en cada dispositivo hasta tocar "Cerrar sesión" en Ajustes; pedirla
cada vez sería una fricción diaria que no protege nada.

**Las tareas de ejemplo quedaron públicas** (2026-09-23). Se cargan solas la primera vez y
están escritas en el código, así que se leen desde la URL. Se le ofreció al dueño cambiarlas
por ejemplos neutros y prefirió publicarlas como estaban.

**Una tarea creada con `@nombre` va directo a Delegadas**, no a la Bandeja. Si se delegó al
anotarla, pasarla por la Bandeja solo agrega un paso. Por lo mismo, **las tareas de la
Bandeja con fecha de hoy o vencida aparecen en Hoy**: si no, una tarea anotada con "hoy"
quedaría invisible hasta el repaso. Y una tarea anotada con hora avisa a esa hora por defecto.

**En la PC la app usa hasta 1200 px de ancho** (2026-09-23, a pedido del dueño: con 760 px se
desperdiciaba la pantalla). Desde 1100 px, Hoy se arma en dos columnas: las tareas a la
izquierda y "Tres para hoy" a la derecha, fijo al hacer scroll. Desde 992 px, el mes del
calendario muestra el título de cada tarea en vez de solo el punto; el corte está en el CSS y
en `pantallaAncha` del JavaScript, y **tienen que coincidir**. En el celular no cambió nada.

**Es una PWA** (2026-09-23): `manifest.webmanifest`, `sw.js` y los íconos de 192 y 512 px.
Sirve para instalarla en la PC y en Android, para abrir sin conexión, y porque es la única
forma de tener notificaciones en Android y en el iPhone, donde `new Notification()` no existe.
Por eso las notificaciones salen por `registration.showNotification()`, con
`new Notification()` como plan B para el archivo abierto en local, donde no hay service worker.
El service worker trae **primero de la red las páginas y primero de lo guardado el resto**: así
un cambio publicado llega solo, sin la trampa típica de la PWA que se queda con la versión
vieja. Las librerías del CDN llevan la versión en la URL, así que guardarlas no las
desactualiza. Tocar una notificación abre esa tarea: por mensaje si la app ya está abierta, o
con `#tarea=<id>` en la dirección si hay que abrirla.

**La barra de estado del iPhone es `default` y no `black-translucent`.** Con la translúcida,
iOS pinta el reloj en blanco, que sobre el fondo claro no se lee.

**Una tarea recurrente atrasada no genera la siguiente en el pasado.** Al completarla, la
próxima fecha se corre hasta quedar después de hoy.

## Estado actual

Anda todo lo pedido: Hoy (con las vencidas en rojo, las delegadas a controlar y "Tres para
hoy"), Listas, Calendario mensual y semanal, el repaso, la captura rápida, los recordatorios,
la recurrencia, exportar/importar, el modo oscuro y el login.

## Pendientes y bloqueos

Falta probarlo en un iPhone real, sobre todo el swipe para completar y "Agregar a pantalla de
inicio", que se probaron solo emulados.

## Trampas conocidas

~~**En iPhone no hay notificaciones del sistema.** iOS no deja que una página común las mande:
solo lo permite a una web app con service worker, y esta app no tiene.~~ Dejó de ser cierto el
2026-09-23, cuando la app pasó a ser PWA (ver abajo).

**Las notificaciones solo salen con la app abierta**, en todos lados. Para avisar con la app
cerrada hace falta Web Push, y eso requiere un servidor que las mande; esta app no tiene. En
el iPhone, además, solo funcionan si la app se abre desde la pantalla de inicio y no desde
Safari. Y el permiso tiene que pedirse con un toque: por eso el primer pedido automático
escucha `click` y no `pointerdown`, que en pantalla táctil no cuenta como gesto y el iPhone
rechaza sin mostrar nada.

**En el iPhone, Safari y la app de la pantalla de inicio no comparten datos.** iOS le da a la
app instalada su propio `localStorage`. Si se usó primero en Safari y después se agregó a la
pantalla de inicio, la app arranca con los ejemplos: hay que exportar desde Safari e importar
en la app.

**Si se cambia `sw.js` o su lista `PRECARGA`, hay que subir el número de `CACHE`**
(`tareas-v1` → `tareas-v2`). Si no, los dispositivos siguen con la versión vieja del service
worker. Los cambios a `tareas.html` **no** lo necesitan: las páginas van primero a la red, así
que llegan solas en cuanto hay conexión.

**En la PC de desarrollo, el Chrome headless no puede usar CacheStorage.** Falla hasta desde
una página común ("Unexpected internal error"), y al perfil de prueba le aparece una extensión
instalada por política, que parece del antivirus. Es algo de esa máquina y no de la app: la
misma prueba en Edge headless pasa entera. Para probar la PWA se usó Edge; el script quedó en
el scratchpad de la sesión del 2026-09-23 y no en el repo. El panel de navegador de Claude
tampoco sirve para esto: no registra service workers.

**Los datos dependen de la dirección.** `localStorage` es por origen
(`juancruz-coding.github.io`). Si cambia el usuario de GitHub, o la app se abre desde otra
dirección (el archivo local, otro hosting), arranca vacía. Los datos no se pierden, pero
quedan en la dirección vieja. Antes de mudarla hay que exportar.

**La primera carga necesita internet**, porque las librerías vienen de un CDN. Desde la segunda,
el service worker las tiene guardadas y la app abre sin conexión.

**La recurrencia mensual se corre en los meses cortos.** Una tarea del 31 pasa al 28 en
febrero y de ahí en adelante sigue en el 28, porque no se guarda el día original.
