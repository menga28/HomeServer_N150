# 🏠 My Home Server (N150 / GitOps)

Questa repository ospita la configurazione **Infrastructure as Code (IaC)** del mio Home Server.
Tutto lo stack è gestito tramite **Docker Compose**, ottimizzato per l'architettura Intel N150 (Twin Lake) con transcodifica hardware abilitata.

## ⚙️ Hardware

*   **Mini PC:** Intel N150 (Twin Lake) - 4 Core / 4 Threads
*   **RAM:** 16GB
*   **OS Disk:** 512GB SSD NVMe (Sistema + AppData + Cache)
*   **Data Disk:** 12TB HDD Esterno (Media e Archivio)
*   **OS:** Ubuntu Server 24.04 LTS

## 📂 Struttura delle Cartelle

Il sistema separa nettamente le configurazioni (su SSD veloce) dai media (su HDD capiente).

```text
/home/user/home-server/   <-- Questa Repository (Git)
├── docker-compose.yml    <-- Configurazione Stack
├── .env                  <-- SEGRETI (Non su Git)
└── .gitignore            <-- Regole di esclusione

/mnt/hdd_esterno/         <-- HDD 12TB (Media)
├── Downloads/            <-- Scaricamenti (qBit)
├── Media/                <-- Libreria Plex
│   ├── Movies/
│   └── TV/
├── Immich/               <-- Foto Backup
└── backups/              <-- Backup vari
```

## 🚀 Installazione e Setup

### 1. Prerequisiti
Assicurarsi che Docker e Docker Compose siano installati e che l'HDD esterno sia montato (es. in `/mnt/hdd_esterno`).

### 2. Clona la Repository
```bash
git clone https://github.com/tuo-user/home-server.git
cd home-server
```

### 3. Configura le Variabili d'Ambiente (.env)
Crea un file `.env` nella root del progetto. **Questo file contiene password e non deve essere caricato su GitHub.**

```bash
nano .env
```

Incolla il seguente template e modifica i valori:

```ini
# --- SYSTEM ---
TZ=Europe/Rome
PUID=1000  # Comando 'id' per verificare
PGID=1000

# --- PATHS ---
# Configurazioni salvate localmente nella cartella del progetto (SSD)
CONFIG_PATH=./appdata
# Percorso assoluto del HDD esterno
MEDIA_PATH=/mnt/hdd_esterno

# --- SECRETS ---
TAILSCALE_AUTH_KEY=tskey-auth-xxxxxx
DB_PASSWORD=tua_password_sicura_immich
```

### 4. Avvia lo Stack
```bash
docker compose up -d
```

---

## services 🛠️ Servizi e Porte

| Servizio | URL Locale | Descrizione |
| :--- | :--- | :--- |
| **Homepage** | `http://IP:3000` | Dashboard Principale |
| **Portainer** | `http://IP:9000` | Gestione Docker GUI |
| **Plex** | `http://IP:32400` | Media Server (Transcodifica HW) |
| **Jellyfin** | `http://IP:8096` | Media Server (Open Source) |
| **Beszel** | `http://IP:8090` | Monitoraggio Risorse |
| **Immich** | `http://IP:2283` | Backup Foto (Simile a GPhotos) |
| **Stirling PDF**| `http://IP:8081` | Tool manipolazione PDF |
| **IT-Tools** | `http://IP:8082` | Strumenti dev/sysadmin |
| **Radarr** | `http://IP:7878` | Gestione Film |
| **Sonarr** | `http://IP:8989` | Gestione Serie TV |

---

## 🎮 Server Minecraft (Gestione Profili)

Il server Minecraft è configurato per **non avviarsi automaticamente** per risparmiare risorse (RAM). È gestito tramite un profilo Docker chiamato `games`.

**Per avviare Minecraft:**
```bash
docker compose --profile games up -d minecraft
```

**Per fermare Minecraft:**
```bash
docker stop minecraft
```

---

## 💡 Note Tecniche Importanti

### Transcodifica Hardware (Intel QuickSync)
I container Plex e Jellyfin hanno il device `/dev/dri` passato. Questo permette all'Intel N150 di decodificare flussi video 4K HEVC senza usare la CPU.

### Gestione Percorsi (Atomic Moves)
Radarr e Sonarr condividono lo stesso volume `/data` mappato su `${MEDIA_PATH}`.
*   Download: `/data/Downloads`
*   Media: `/data/Media`
Questa configurazione è essenziale per permettere gli **Hardlinks** (spostamento istantaneo dei file senza duplicazione dello spazio).

### Immich Machine Learning
Al primo avvio, Immich scaricherà diversi GB di modelli per il riconoscimento facciale. È normale vedere un alto utilizzo della CPU nei primi minuti/ore.

---

## 🔄 Manutenzione e Aggiornamenti

**Aggiornare tutto lo stack:**
```bash
# 1. Scarica le ultime modifiche dalla repo (se hai cambiato config)
git pull

# 2. Scarica le nuove immagini docker
docker compose pull

# 3. Ricrea i container aggiornati (rimuovendo i vecchi non usati)
docker compose up -d --remove-orphans
docker image prune -f
```
