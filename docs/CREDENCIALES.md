# Credenciales: dónde vive cada cosa

Este archivo es un índice. Nunca lleva valores.

## ~~Login de la app (usuario y contraseña fijos)~~

Se reemplazó el 2026-09-23 por Supabase Auth; ver "Usuario de la app". Las constantes
`LOGIN_USUARIO` y `LOGIN_CLAVE` ya no existen en el código.

## Usuario de la app (Supabase Auth)

Mail y contraseña con los que se entra a la app. Es el único usuario del proyecto.
Vive en: el gestor de contraseñas del dueño. El usuario se crea en el panel de Supabase,
proyecto `app-tareas` → Authentication → Users.
Rotación: desde ese mismo panel ("Send password recovery" o cambiarla a mano). Los
dispositivos con sesión abierta siguen entrando hasta que se cierre o venza.
Si se pierde: se resetea desde el panel; los datos no se pierden. **Si se borra el usuario, se
borran todas sus tareas** (`on delete cascade`).

## URL y clave publishable de Supabase

Con esto la app se conecta al proyecto `app-tareas`.
Vive en: `tareas.html`, constantes `SUPABASE_URL` y `SUPABASE_CLAVE`, **a la vista y a
propósito**: la clave publishable (antes "anon") está hecha para ir en el navegador. Sin
sesión no lee ni escribe nada, porque las reglas (RLS) de `schema.sql` solo le abren las
tareas a su dueño. Se sacan del panel: Settings → API Keys.
Rotación: se genera una nueva en el panel, se cambia la constante y se publica.
Si se pierde: se vuelve a copiar del panel. No protege nada por sí sola.

## Clave secreta de Supabase (secret / service_role)

Saltea todas las reglas de seguridad: con ella se lee y se borra todo.
Vive en: el panel de Supabase, y en ningún otro lado. **Nunca va en `tareas.html`, en el
repositorio ni en el chat.** La app no la usa.
Si se filtra: rotarla en el panel ya mismo.

## Contraseña de la base de datos (Postgres)

Acceso directo a Postgres del proyecto `app-tareas`. La app no la usa.
Vive en: el gestor de contraseñas del dueño.
Ojo: el 2026-09-23 se pegó en el chat con Claude. Conviene cambiarla en Settings → Database.
Si se pierde: se resetea desde el panel; no rompe nada, porque la app no la usa.

## Acceso de Claude al proyecto (MCP de Supabase)

Hoy Claude entra con el conector de Supabase de claude.ai, que ya tiene acceso a "Juanchi's
Org" (verificado el 2026-09-23). Además está el servidor MCP del proyecto en `.mcp.json`, que
solo tiene el ref y ningún secreto; para usarlo hay que autenticarlo con `claude /mcp`, y la
autorización queda en la configuración local de Claude Code, fuera del repositorio.
Si se pierde: se vuelve a autenticar con `claude /mcp`. Mientras tanto Claude no puede cargar
ni leer tareas; la app sigue igual.

## Cuenta de GitHub `JuanCruz-Coding`

Es dueña del repositorio `tareas` y publica el sitio en GitHub Pages.
Vive en: el gestor de contraseñas del dueño. El `gh` de la PC tiene su token en el llavero
de Windows.
Rotación: desde la configuración de la cuenta en github.com.
Si se pierde: el sitio deja de actualizarse. Los datos no dependen de esta cuenta, porque
están en Supabase.

## Datos de las tareas

Viven en: la base del proyecto `app-tareas`, tablas `tareas` y `config`. Cada dispositivo tiene
una copia en caché en `localStorage` (`tareasApp.v1`).
Respaldo: el plan Free de Supabase no ofrece backups para restaurar desde el panel. El único
respaldo es "Exportar" en Ajustes, a mano.
Si se pierde el proyecto: si se pausó (el plan Free pausa los proyectos que pasan una semana
sin actividad; con uso diario no pasa), se reactiva desde el panel. Si se borró, solo queda lo
último exportado y la caché de cada dispositivo.
