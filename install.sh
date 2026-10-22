#!/bin/sh
# Instala (o desinstala) el parche de notificaciones de Slack y el hook de apt
# que lo re-aplica automáticamente después de cada actualización del paquete.
#   curl -fsSL https://raw.githubusercontent.com/SmowlJose/slack-notification-fix/main/install.sh | sudo sh
#   curl -fsSL .../install.sh | sudo sh -s uninstall
#   sudo ./install.sh [install|uninstall]   # desde una copia clonada del repo
set -eu

BIN=/usr/local/sbin/slack-notification-fix
HOOK=/etc/apt/apt.conf.d/99slack-notification-fix
RAW_URL=https://raw.githubusercontent.com/SmowlJose/slack-notification-fix/main/slack-notification-fix

if [ "$(id -u)" -ne 0 ]; then
    echo "Ejecuta este script con sudo." >&2
    exit 1
fi

# Deja en $1 el parcheador: el del repo clonado si se ejecuta como ./install.sh,
# o descargado de GitHub si llega por una tubería (curl ... | sudo sh).
fetch_patcher() {
    case "$0" in
    *install.sh)
        cp "$(dirname "$0")/slack-notification-fix" "$1"
        ;;
    *)
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL "$RAW_URL" -o "$1"
        elif command -v wget >/dev/null 2>&1; then
            wget -qO "$1" "$RAW_URL"
        else
            echo "Hace falta curl o wget para descargar el parche." >&2
            exit 1
        fi
        ;;
    esac
    if ! head -n 1 "$1" | grep -q '^#!/usr/bin/python3'; then
        echo "El parcheador descargado no es válido; no se instala nada." >&2
        exit 1
    fi
}

case "${1:-install}" in
install)
    if [ ! -x /usr/bin/python3 ]; then
        echo "Hace falta python3 (sudo apt install python3)." >&2
        exit 1
    fi
    TMP=$(mktemp)
    trap 'rm -f "$TMP"' EXIT
    fetch_patcher "$TMP"
    install -m 0755 "$TMP" "$BIN"
    cat > "$HOOK" <<HOOK_EOF
// Re-aplica el parche de notificaciones de Slack tras cada ejecución de dpkg
// (apt upgrade, unattended-upgrades, Software...). Nunca hace fallar a apt.
DPkg::Post-Invoke { "if [ -x $BIN ]; then $BIN apply --quiet || true; fi"; };
HOOK_EOF
    "$BIN" apply
    ;;
uninstall)
    [ -x "$BIN" ] && "$BIN" restore || true
    rm -f "$HOOK" "$BIN"
    rm -rf /var/lib/slack-notification-fix
    echo "Desinstalado. Reinicia Slack."
    ;;
*)
    echo "Uso: install.sh [install|uninstall]" >&2
    exit 1
    ;;
esac
