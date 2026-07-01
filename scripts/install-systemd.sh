#!/usr/bin/env bash
# Installa i servizi systemd e la regola udev per HomeServer.
# Esegui una sola volta con: sudo bash scripts/install-systemd.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SYSTEM_DIR="$REPO_DIR/system"

echo "==> Installazione servizi systemd da $SYSTEM_DIR"

# 1. Copia i service files
cp "$SYSTEM_DIR/homeserver.service"       /etc/systemd/system/
cp "$SYSTEM_DIR/homeserver-media.service" /etc/systemd/system/
cp "$SYSTEM_DIR/telegram-data-hub.service" /etc/systemd/system/

# 2. Copia la regola udev
cp "$SYSTEM_DIR/99-hdd-media.rules" /etc/udev/rules.d/

# 3. Aggiorna fstab: aggiunge nofail,x-systemd.device-timeout=5 se non già presenti
FSTAB_LINE='UUID=38b3a4d6-1f5c-f143-87df-75641f92c147 /mnt/hdd_esterno ext4 defaults,nofail,x-systemd.device-timeout=5 0 2'
if grep -q 'x-systemd.device-timeout' /etc/fstab; then
  echo "==> fstab già aggiornato, salto"
else
  sed -i 's|UUID=38b3a4d6-1f5c-f143-87df-75641f92c147 /mnt/hdd_esterno ext4 defaults|UUID=38b3a4d6-1f5c-f143-87df-75641f92c147 /mnt/hdd_esterno ext4 defaults,nofail,x-systemd.device-timeout=5|' /etc/fstab
  echo "==> fstab aggiornato"
fi

# 4. Ricarica systemd e udev
systemctl daemon-reload
udevadm control --reload-rules

# 5. Abilita i servizi al boot (core e telegram-data-hub)
systemctl enable homeserver.service
systemctl enable telegram-data-hub.service
# homeserver-media si abilita con WantedBy=mnt-hdd_esterno.mount
systemctl enable homeserver-media.service

echo ""
echo "==> Fatto. Riepilogo:"
echo "    homeserver.service         → avvio automatico (boot)"
echo "    telegram-data-hub.service  → avvio automatico (boot)"
echo "    homeserver-media.service   → avvio automatico quando /mnt/hdd_esterno è montato"
echo ""
echo "    Per fermare/avviare manualmente i media container:"
echo "    systemctl start homeserver-media.service"
echo "    systemctl stop  homeserver-media.service"
