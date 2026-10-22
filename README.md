# slack-notification-fix

Parche para **Slack de escritorio en Linux**: hace que al pulsar una notificación te lleve al mensaje, canal o hilo de origen **aunque hayan pasado más de unos segundos** desde que llegó.

Se re-aplica solo después de cada `sudo apt upgrade`, así que solo hay que instalarlo una vez.

## Requisitos

- Ubuntu / Debian con Slack instalado desde el paquete **`.deb`** (`slack-desktop`, en `/usr/lib/slack`).
- `python3` (viene de serie en Ubuntu) y permisos de `sudo`.

> No sirve para las versiones Snap ni Flatpak de Slack.

## Instalación

```bash
git clone https://github.com/SmowlJose/slack-notification-fix.git
cd slack-notification-fix
sudo ./install.sh
```

Después, **cierra Slack del todo y vuelve a abrirlo** (menú *Archivo → Salir*, no solo cerrar la ventana).

Si todo ha ido bien verás:

```
slack-notification-fix: Slack 4.xx.xxx parcheado. Reinicia Slack para aplicar el cambio.
```

## Comprobar que funciona

1. En cualquier canal de Slack escribe `/remind me prueba in 1 minute`.
2. Cuando llegue la notificación, **espera un par de minutos** sin tocarla.
3. Púlsala desde la bandeja de notificaciones: debería abrir Slack en ese mensaje.

Para ver el estado del parche en cualquier momento:

```bash
slack-notification-fix check
```

| Resultado | Significado |
|---|---|
| `parcheado` | Todo correcto. |
| `SIN parchear` | Ejecuta `sudo slack-notification-fix apply` y reinicia Slack. |
| `patrón no encontrado` | Slack ha cambiado su código interno y el parche ya no encaja. Abre un issue. |

## ¿Y cuando se actualice Slack?

No tienes que hacer nada. El instalador añade un hook de apt que, al terminar cualquier actualización (`apt upgrade`, actualizaciones automáticas o la app *Software*), vuelve a parchear Slack si hace falta. Verás este mensaje en la salida de apt:

```
slack-notification-fix: Slack 4.xx.xxx parcheado. Reinicia Slack para aplicar el cambio.
```

Solo tienes que reiniciar Slack, como harías igualmente para usar la versión nueva. El hook nunca hace fallar a apt: si algo va mal, avisa y deja Slack tal cual.

## Desinstalar

```bash
cd slack-notification-fix
sudo ./install.sh uninstall
```

Restaura el Slack original y elimina el hook. Reinicia Slack después.

## Cómo funciona

En Linux, Slack crea cada notificación pero no guarda ninguna referencia a ella. A los pocos segundos el recolector de memoria de JavaScript la elimina y Electron deja de escuchar sus clics: GNOME sigue mostrando la notificación, pero al pulsarla ya no hay nada al otro lado. Por eso el tiempo "útil" varía, aunque suele rondar los 6 segundos.

El parche inserta una línea en `dist/main.bundle.cjs` (dentro de `/usr/lib/slack/resources/app.asar`) que mantiene cada notificación viva hasta que se pulsa, se responde o se cierra, con un máximo de 200. No modifica nada más.

Qué instala `install.sh`:

| Fichero | Para qué |
|---|---|
| `/usr/local/sbin/slack-notification-fix` | El parcheador (`check`, `apply`, `restore`). |
| `/etc/apt/apt.conf.d/99slack-notification-fix` | Hook que re-aplica el parche tras cada actualización. |
| `/var/lib/slack-notification-fix/` | Copia del `app.asar` original, para poder restaurarlo. |

Probado con Slack 4.50.143 y 4.52.182 en Ubuntu con GNOME.
