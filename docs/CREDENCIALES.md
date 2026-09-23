# Credenciales: dónde vive cada cosa

Este archivo es un índice. Nunca lleva valores.

## Login de la app

Usuario y contraseña de la pantalla de entrada.
Vive en: `tareas.html`, constantes `LOGIN_USUARIO` y `LOGIN_CLAVE`, en texto plano. **Es
público**: el repositorio y el sitio de GitHub Pages los muestran. Fue una decisión del
dueño; ver `docs/CONTEXTO.md`.
Rotación: se cambian las dos constantes y se publica. Cada dispositivo sigue con la sesión
abierta hasta que toque "Cerrar sesión".
Si se pierde: no pasa nada, se lee en el código. No protege datos: las tareas no están en
el servidor.

## Cuenta de GitHub `JuanCruz-Coding`

Es dueña del repositorio `tareas` y publica el sitio en GitHub Pages.
Vive en: el gestor de contraseñas del dueño. El `gh` de la PC tiene su token en el llavero
de Windows.
Rotación: desde la configuración de la cuenta en github.com.
Si se pierde: el sitio deja de actualizarse. Si además cambia el nombre de usuario, cambia
la dirección de la app, y las tareas guardadas en cada dispositivo quedan en la dirección
vieja. Antes de cualquier cambio de cuenta, exportar las tareas desde Ajustes en cada
dispositivo.

## Datos de las tareas

No son un secreto, pero son lo único que no tiene copia en ningún lado.
Viven en: el `localStorage` del navegador de cada dispositivo, clave `tareasApp.v1`.
Respaldo: manual, con "Exportar" en Ajustes.
Si se pierde (borrar datos del navegador, cambiar de teléfono): se pierde todo lo que no se
haya exportado.
