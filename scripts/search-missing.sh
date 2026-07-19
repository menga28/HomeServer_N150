#!/usr/bin/env bash
# Lancia la ricerca automatica dei contenuti mancanti su Sonarr e Radarr.
# La RSS Sync (già periodica in entrambi) copre solo le uscite nuove;
# questo script copre il backlog di episodi/film già segnati come "mancanti".
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SONARR_API_KEY="$(grep -oP '(?<=^SONARR_API_KEY=).*' "$REPO_DIR/.env")"
RADARR_API_KEY="$(grep -oP '(?<=^RADARR_API_KEY=).*' "$REPO_DIR/.env")"

curl -fsS -X POST "http://localhost:8989/api/v3/command" \
  -H "X-Api-Key: ${SONARR_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"name":"MissingEpisodeSearch"}' > /dev/null
echo "Sonarr: ricerca episodi mancanti avviata"

curl -fsS -X POST "http://localhost:7878/api/v3/command" \
  -H "X-Api-Key: ${RADARR_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"name":"MissingMoviesSearch"}' > /dev/null
echo "Radarr: ricerca film mancanti avviata"
