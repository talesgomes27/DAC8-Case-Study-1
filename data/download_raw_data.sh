#!/usr/bin/env bash
# Download e extracao automatizada dos dados brutos do Cyclistic (Divvy)
set -e

DEST_DIR="data/raw"
mkdir -p "$DEST_DIR"

MONTHS=(
  "202007" "202008" "202009" "202010" "202011" "202012"
  "202101" "202102" "202103" "202104" "202105" "202106"
)

BASE_URL="https://divvy-tripdata.s3.amazonaws.com"

echo "Iniciando download dos 12 meses do Cyclistic Bike-Share..."
echo "Destino: $DEST_DIR"

for m in "${MONTHS[@]}"; do
  ZIP_NAME="${m}-divvy-tripdata.zip"
  URL="${BASE_URL}/${ZIP_NAME}"
  
  echo "[>] Baixando $ZIP_NAME..."
  curl -s -f -o "${DEST_DIR}/${ZIP_NAME}" "$URL"
  
  echo "    Descompactando $ZIP_NAME..."
  unzip -q -o "${DEST_DIR}/${ZIP_NAME}" -d "$DEST_DIR"
  rm "${DEST_DIR}/${ZIP_NAME}"
  echo "    [OK] $m finalizado."
done

# Remove eventuais pastas de lixo do macOS
rm -rf "${DEST_DIR}/__MACOSX"

echo "Download e descompactacao concluidos com sucesso em $DEST_DIR!"
