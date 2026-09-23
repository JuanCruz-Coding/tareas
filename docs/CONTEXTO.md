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

**En iPhone no hay notificaciones del sistema.** iOS no deja que una página común las mande:
solo lo permite a una web app con service worker, y esta app no tiene. En el iPhone el aviso
sale solo dentro de la app abierta. En la PC funcionan, pero solo con la pestaña abierta.

**Los datos dependen de la dirección.** `localStorage` es por origen
(`juancruz-coding.github.io`). Si cambia el usuario de GitHub, o la app se abre desde otra
dirección (el archivo local, otro hosting), arranca vacía. Los datos no se pierden, pero
quedan en la dirección vieja. Antes de mudarla hay que exportar.

**La primera carga necesita internet**, porque las librerías vienen de un CDN.

**La recurrencia mensual se corre en los meses cortos.** Una tarea del 31 pasa al 28 en
febrero y de ahí en adelante sigue en el 28, porque no se guarda el día original.
