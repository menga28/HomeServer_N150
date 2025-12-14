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

### 1. Connessione Iniziale (Lato Windows)
Per gestire il server da remoto:
1.  Apri **PowerShell** o **Terminale**.
2.  Connettiti al tuo server (sostituisci l'IP):
    ```bash
    ssh nome_utente@192.168.X.XX
    ```
3.  Per copiare il testo dal terminale, è sufficiente selezionarlo; per incollare si usa il tasto destro o `Ctrl + V`.

### 2. Clona la Repository (Lato SSH)
Scarica la configurazione e crea i file essenziali.
```bash
git clone git@github.com:tuo-user/home-server.git
cd home-server
# Assicurati di essere il proprietario di tutta la cartella per i permessi Docker:
sudo chown -R $USER:$USER ~/home-server
```

### 3. Configura le Variabili d'Ambiente (.env)
Crea il file `.env` che contiene i segreti.
```bash
nano .env
```
Incolla il template e modifica i valori:

```ini
# --- SYSTEM ---
TZ=Europe/Rome
PUID=1000  # Comando 'id' per verificare
PGID=1000

# --- PATHS ---
CONFIG_PATH=./appdata
MEDIA_PATH=/mnt/hdd_esterno

# --- SECRETS ---
TAILSCALE_AUTH_KEY=tskey-auth-xxxxxx
DB_PASSWORD=tua_password_sicura_immich
```

### 4. Avvia lo Stack
```bash
docker compose up -d
```
*(Se un container dà errore di avvio, prova a rilanciare il comando. Docker è resiliente).*

---

## 🛠️ Manutenzione e Gestione (Lato SSH)

Questa sezione contiene i comandi che utilizzerai di più per la gestione quotidiana del server.

### 1. Modificare la Configurazione (docker-compose.yml)
Per aggiungere, rimuovere o modificare i container:
1.  Apri il file:
    ```bash
    nano ~/home-server/docker-compose.yml
    ```
2.  Dopo le modifiche, riavvia i container modificati (o tutto lo stack):
    ```bash
    # Riavvia tutto
    docker compose up -d 
    # Riavvia solo Immich (es.)
    docker compose up -d immich_server immich_web
    ```

### 2. Gestione della Dashboard (Homepage)
Tutta la configurazione di Homepage (icone, link, widget) avviene modificando file YAML nella cartella `appdata`.

1.  Accedi alla cartella di configurazione:
    ```bash
    cd ~/home-server/appdata/homepage
    ```
2.  Modifica i file principali (es. per aggiungere o modificare servizi):
    ```bash
    nano services.yaml
    nano widgets.yaml
    ```
    *(La dashboard si aggiornerà automaticamente dopo aver salvato il file).*

### 3. Gestione dei Permessi
Se un container (Plex, Radarr) dà errore **"Permission Denied"** nell'accedere all'HDD esterno, lancia questi due comandi:
```bash
# Rende l'utente 1000 (il tuo) proprietario di TUTTO l'HDD
sudo chown -R 1000:1000 /mnt/hdd_esterno

# Rende tutti i file completamente leggibili/scrivibili dal proprietario
sudo chmod -R 775 /mnt/hdd_esterno
```

### 4. Gestione Firewall (UFW)
Dopo aver lanciato nuovi servizi, potresti dover aprire la porta (se non usi `network_mode: host` come Plex).

```bash
# Apri una porta specifica (es. 2284 per Immich Web)
sudo ufw allow 2284
# Rimuovi una porta
sudo ufw delete allow 2284
```
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

## 🔄 Manutenzione e Aggiornamenti

**Aggiornare tutto lo stack (consigliato ogni 2-3 mesi):**
```bash
# 1. Scarica le ultime modifiche dalla repo (se hai cambiato config)
git pull

# 2. Scarica le nuove immagini docker (molto traffico!)
docker compose pull

# 3. Ricrea i container aggiornati (rimuovendo i vecchi non usati)
docker compose up -d --remove-orphans
docker image prune -f
```

---

## ⚠️ Immich Final Note

Il WebUI di Immich è accessibile su: `http://IP:2284`. Se hai problemi di connessione, prova sempre prima a riavviare i container Immich.

```bash
docker compose up -d immich_server immich_web
```
```