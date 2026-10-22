#!/bin/sh
# Instala (o desinstala) el parche de notificaciones de Slack y el hook de apt
# que lo re-aplica automáticamente después de cada actualización del paquete.
#   sudo ./install.sh            # instalar y aplicar
#   sudo ./install.sh uninstall  # restaurar Slack original y quitar todo
set -eu

BIN=/usr/local/sbin/slack-notification-fix
HOOK=/etc/apt/apt.conf.d/99slack-notification-fix
SRC_DIR=$(cd "$(dirname "$0")" && pwd)

if [ "$(id -u)" -ne 0 ]; then
    echo "Ejecuta este script con sudo." >&2
    exit 1
fi

case "${1:-install}" in
install)
    install -m 0755 "$SRC_DIR/slack-notification-fix" "$BIN"
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
    echo "Uso: sudo $0 [install|uninstall]" >&2
    exit 1
    ;;
esac
