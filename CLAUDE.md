# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

GitOps configuration for a home server running Docker Compose on an Intel N150 mini PC (Ubuntu Server 24.04 LTS). The single source of truth is `docker-compose.yml` — editing it and running `docker compose up -d` is how all changes are applied.

## Key commands

```bash
# Apply changes — core services only (no HDD required)
docker compose up -d

# Apply changes — media services (requires /mnt/hdd_esterno mounted)
docker compose --profile media up -d

# Restart a specific service
docker compose up -d <service_name>

# Start Minecraft (disabled by default via Docker profile)
docker compose --profile games up -d minecraft

# Update all images (Watchtower also does this automatically at 4 AM)
docker compose pull && docker compose up -d --remove-orphans && docker image prune -f
docker compose --profile media pull && docker compose --profile media up -d --remove-orphans

# Check logs
docker compose logs -f <service_name>

# Manage media services manually (via systemd)
systemctl start homeserver-media.service   # avvia container media
systemctl stop  homeserver-media.service   # ferma container media
systemctl status homeserver-media.service
```

## Architecture

### Storage split
- `CONFIG_PATH=./appdata` — configs, databases, app state → SSD (fast)
- `MEDIA_PATH=/mnt/hdd_esterno` — media library, photo archive, downloads → 12TB HDD

### Boot resilience (HDD esterno spento)
I servizi sono divisi in due profili Docker Compose:
- **core** (nessun profilo): si avvia sempre al boot — tailscale, portainer, homepage, beszel, immich DB/Redis/ML, stirling-pdf, it-tools, watchtower
- **media** (`profiles: ["media"]`): si avvia solo quando `/mnt/hdd_esterno` è montato — plex, jellyfin, qbittorrent, radarr, sonarr, filebrowser, immich-server

Al boot, `homeserver.service` avvia solo i core. `homeserver-media.service` parte automaticamente quando il mount unit `mnt-hdd_esterno.mount` si attiva (HDD connesso), ricreando sempre i container (`--force-recreate`) così il bind mount su `${MEDIA_PATH}` è sempre fresco. Se l'HDD viene rimosso, i container media si fermano automaticamente (BindsTo).

Tutti i servizi del profilo `media` hanno `restart: "no"`: Docker non li riavvia mai da solo al riavvio del demone/reboot. Solo `homeserver-media.service` può avviarli, e solo quando il mount è realmente attivo. Questo evita che un container riparta agganciato a una cartella vuota se l'HDD non si è rimontato (es. dopo un blackout, se il dock USB non si riaccende da solo).

`telegram-data-hub.service` parte sempre al boot, indipendentemente dall'HDD.

Installazione una-tantum: `sudo bash scripts/install-systemd.sh`

### Hardlink chain (critical)
Radarr, Sonarr, and qBittorrent all mount `${MEDIA_PATH}:/data` at the **same path**. This is intentional: it enables hardlinks when Radarr/Sonarr move completed downloads, so no data is duplicated on disk. Never break this mapping symmetry.

### Networks
- `immich` (bridge): isolates Immich stack internally (server, ML, Redis, Postgres)
- `default`: everything else
- `network_mode: host`: Plex (needs mDNS/DLNA) and Beszel (monitoring)

### Hardware transcoding
Plex, Jellyfin, and Immich all expose `/dev/dri:/dev/dri` for Intel QuickSync/OpenVINO acceleration on the N150 GPU.

## Services at a glance

### Core (sempre attivi, nessun HDD)
| Service | Port | Purpose |
|---|---|---|
| Homepage | 3000 | Dashboard (config in `appdata/homepage/`) |
| Portainer | 9000 | Docker management UI |
| Beszel | 8090 | System monitoring (host network) |
| Stirling PDF | 8081 | PDF tools |
| IT-Tools | 8082 | Developer utilities |
| Tailscale | — | VPN mesh + subnet router (192.168.3.0/24) |
| Watchtower | — | Auto-updates images at 4 AM daily |
| Immich Postgres | — | Database Immich (su SSD) |
| Immich Redis | — | Cache Immich |
| Immich ML | — | Machine learning Immich |

### Media (profile: `media` — richiedono `/mnt/hdd_esterno`)
| Service | Port | Purpose |
|---|---|---|
| FileBrowser | 8050 | Web file manager |
| qBittorrent | 8080 | Torrent client |
| Plex | 32400 | Media server (host network) |
| Jellyfin | 8096 | Open-source media server |
| Radarr | 7878 | Movie automation |
| Sonarr | 8989 | TV automation |
| Immich Server | 2284 | Self-hosted photo backup |

## Git strategy

`.env` is **never committed** — it holds secrets (Tailscale key, DB password, Plex claim token). Use the template in `README.md` to recreate it.

`appdata/` is excluded by default, then **selectively re-included** for config file types (`*.yaml`, `*.json`, `*.xml`, `*.conf`, `*.key`, etc.). Database files (`*.db`, `*.db-*`), logs, and caches are always excluded. When adding a new service, its config files will be tracked automatically if they match those extensions — no `.gitignore` changes needed.

## Homepage dashboard

Configuration lives entirely in `appdata/homepage/`. Changes to `services.yaml`, `widgets.yaml`, etc. take effect immediately without restarting the container.
