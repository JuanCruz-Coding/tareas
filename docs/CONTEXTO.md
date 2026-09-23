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
emulado; en un iPhone de verdad todavía no. **La migración a Supabase está escrita y probada
contra un Supabase simulado, pero todavía no contra la base real**: falta la clave publishable
del proyecto (ver Pendientes). Mientras `SUPABASE_CLAVE` esté vacía, la app funciona como antes,
solo en el navegador.

## Decisiones tomadas

~~**Los datos viven solo en el navegador de cada dispositivo** (2026-09-23). Todo va en
`localStorage` bajo la clave `tareasApp.v1`, en JSON. No hay servidor ni sincronización.~~
Se revirtió el mismo 2026-09-23: el dueño quiso que Claude pudiera cargar tareas y leer sus
pendientes, y eso pide una base. Ver la decisión siguiente.

**Los datos viven en Supabase** (2026-09-23), proyecto `app-tareas` (ref
`sximhlooztbbsliqaznw`) en la organización "Juanchi's Org", plan Free. Tablas `tareas` y
`config`, creadas con `schema.sql`. `localStorage` quedó como caché: lo último cargado, para
abrir al toque y sin conexión. La interfaz y la lógica no cambiaron; todo lo que habla con la
base está en el objeto `db` y en la sección "SINCRONIZACIÓN" de `tareas.html`. Detalles que
importan:

- **`guardar()` manda solo lo que cambió.** No se reescribieron las decenas de llamadas a
  `guardar()`: ahora comparan cada tarea contra un *espejo* (lo último que se sabe que está en
  la base, guardado en `tareasApp.espejo`) y suben las diferencias. Así ningún camino —deshacer,
  el repaso, la recurrencia— puede olvidarse de guardar. La vista se redibuja antes de que
  Supabase responda; si falla, el cambio queda pendiente y se reintenta.
- **La app y la base nombran distinto algunas cosas**, y lo traducen `filaDe()` y `tareaDe()`:
  las listas `bandeja` y `algundia` son `inbox` y `algun_dia` en la base; el "ya avisé" de la
  app es una clave con fecha, hora y aviso (así vuelve a avisar si se mueve la tarea) y en la
  base es el booleano `notificada`.
- **Tiempo real con eco filtrado.** Cada cambio propio vuelve por el canal de tiempo real; se
  lo reconoce (`db.enviadas` y el espejo) y no se reprocesa. Lo que carga Claude o se edita en
  otro dispositivo aparece solo.
- **Migración única por navegador.** Si la base está vacía y nunca se usó (sin
  `config.inicializado`), el primer navegador que entra sube sus tareas, con los ids viejos
  cambiados a UUID también dentro de "tres para hoy". Si la base ya tiene datos, mandan esos, y
  las tareas locales de ese navegador **no se mezclan**: quedan guardadas en
  `tareasApp.respaldo`, sin pantalla para recuperarlas todavía.
- **"Borrar todo" no vuelve a sembrar los ejemplos**, porque `inicializado` queda en true.

~~**El login es de mentira, y se sabe** (2026-09-23). Usuario y contraseña fijos en el código
público, elegido por el dueño con las alternativas a la vista.~~ Se reemplazó el mismo
2026-09-23: con las tareas en una base, un login de mentira dejaba a cualquiera leer y borrar
todo, porque el sitio es público y la clave queda en el HTML.

**El login es real: Supabase Auth con mail y contraseña** (2026-09-23). El pedido original
era abrir la base al rol `anon`, sin login. Se le explicó al dueño que con el sitio público
eso dejaba sus tareas legibles y borrables por cualquiera, y eligió el login real. Cada fila
tiene `user_id` y las reglas (RLS) solo dejan entrar a su dueño; sin sesión no se ve nada,
aunque la clave publishable esté en el HTML. El usuario se crea a mano en el panel, y las altas
desde afuera tienen que estar apagadas. La sesión queda guardada en cada dispositivo;
"Cerrar sesión" además borra la copia local.

**Claude entra por SQL, no por la app.** Lo que carga llega sin sesión, así que un trigger
(`privado.completar_dueno`) completa `user_id` con el primer usuario creado, que es el único.
`schema.sql` termina con el `insert` y el `select` de ejemplo. Las tareas que carga llevan
`origen = 'claude'`.

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

**Supabase está listo pero falta el usuario** (2026-09-23). `schema.sql` se aplicó por el MCP
como migración `esquema_inicial`, y se verificó: RLS prendido en las dos tablas, `anon` sin
ningún permiso (la API responde 401 a leer y a escribir sin sesión), las cuatro triggers, las
dos tablas en Realtime, y cero avisos de seguridad del propio Supabase. La clave publishable ya
está en `SUPABASE_CLAVE`, y contra la base real la app carga y el login rechaza credenciales
inválidas.

Lo que **no** se pudo probar contra la base real es el camino con sesión (migración, tiempo
real, sincronización), porque el usuario de Auth no existe y lo tiene que crear el dueño: está
probado contra un Supabase simulado que aplica los mismos controles que `schema.sql`. Falta:

- ~~crear el usuario en Authentication → Users y apagar las altas nuevas~~: hecho por el dueño
  el 2026-09-23; verificado (un usuario confirmado, `disable_signup` en true en
  `/auth/v1/settings`);
- ~~publicar~~: publicado el 2026-09-23. En el sitio real: login a la vista, sin errores de
  consola, service worker `tareas-v2` con 13 archivos guardados y la app instalable;
- ~~después del primer login, verificar desde la base que se subieron las tareas~~: verificado
  el 2026-09-23, llegaron las 8, todas a nombre del usuario, con horas, recurrencias y
  delegados intactos, y las tres claves de `config`;
- **que Claude pueda escribir**: ver el párrafo siguiente. Hasta entonces, el tiempo real con
  una tarea cargada por Claude no se probó contra la base real (sí contra el simulado).

**El conector de Supabase que Claude tiene en claude.ai es de solo lectura para el SQL.** Llega
a `app-tareas` (aunque `list_organizations` no mostraba "Juanchi's Org", `get_project` con el ref
respondió), y con él se leen los pendientes, pero un `insert` falla con `cannot execute INSERT
in a read-only transaction`. El esquema se pudo aplicar porque `apply_migration` va por otro
camino. **No usar `apply_migration` para cargar tareas**: quedarían en el historial de
migraciones, y al reconstruir la base desde ahí (una rama, por ejemplo) el insert fallaría,
porque no habría usuario al que asignarle la tarea.

~~El servidor del proyecto que se agregó en `.mcp.json` sobra por ahora.~~ Se corrigió el mismo
día: **es el que permite escribir**, porque su URL no lleva `read_only`. Hay que autenticarlo
una vez con `claude /mcp` desde una terminal, en la carpeta del proyecto.

**Las tareas locales que no se suben al migrar no tienen pantalla para recuperarse.** Quedan
en `tareasApp.respaldo` de ese navegador. Si hace falta, se agrega un botón en Ajustes.

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

~~**Los datos dependen de la dirección.** `localStorage` es por origen: si cambia la dirección,
la app arranca vacía.~~ Con Supabase dejó de ser cierto: la dirección solo cambia la caché, y
los datos se vuelven a bajar al entrar.

**Si Realtime no avisa, no hay error.** Las tablas tienen que estar en la publicación
`supabase_realtime`; lo hace el final de `schema.sql`. Sin eso la app funciona igual pero no
se entera de lo que cambia afuera hasta recargar, y nada lo dice.

**Supabase devuelve como mucho 1000 filas por consulta.** `db.cargarTodo()` pide de a páginas;
si alguien lo simplifica a un solo `select`, a las 1000 tareas (completadas incluidas) empiezan
a faltar datos sin ningún aviso.

**Cerrar sesión sin conexión**: el cierre normal de Supabase falla sin red y deja la sesión
puesta, por eso `cerrarSesion()` cae a `signOut({ scope: 'local' })`.

**El panel de navegador de Claude muestra errores de consola del service worker** ("An unknown
error occurred when fetching the script"). Son del panel, que no registra service workers; en
Chrome y Edge de verdad no aparecen.

**La primera carga necesita internet**, porque las librerías vienen de un CDN. Desde la segunda,
el service worker las tiene guardadas y la app abre sin conexión.

**La recurrencia mensual se corre en los meses cortos.** Una tarea del 31 pasa al 28 en
febrero y de ahí en adelante sigue en el 28, porque no se guarda el día original.
