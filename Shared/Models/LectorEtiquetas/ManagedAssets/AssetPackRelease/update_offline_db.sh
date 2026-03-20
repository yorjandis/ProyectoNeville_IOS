#!/usr/bin/env bash


#
#
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DB_DIR="$SCRIPT_DIR/database"
DEST_DB_PATH="$DEST_DB_DIR/openfoodfacts_compact.sqlite"
MANIFEST_PATH="$SCRIPT_DIR/ManagedAssetPackManifest.json"
AAR_PATH="$SCRIPT_DIR/openfoodfacts-compact-db.aar"

# Defaults (override with env vars if needed)
APPLE_ID="${APPLE_ID:-6472626696}"
API_KEY_ID="${API_KEY_ID:-YZ83CX57YZ}"
API_ISSUER_ID="${API_ISSUER_ID:-754e0e8c-46d2-4679-9597-bd85a59e0ce9}"
ASSET_PACK_ID="${ASSET_PACK_ID:-openfoodfacts-compact-db}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-json}"

usage() {
    cat << USAGE
Uso:
  $(basename "$0") <ruta_sqlite_nueva> [--no-upload]

Ejemplo:
  $(basename "$0") "/Users/yorjandis/Documents/openfoodfacts/Version 6/productos.sqlite"

Variables opcionales:
  APPLE_ID        (default: $APPLE_ID)
  API_KEY_ID      (default: $API_KEY_ID)
  API_ISSUER_ID   (default: $API_ISSUER_ID)
  OUTPUT_FORMAT   (default: $OUTPUT_FORMAT)
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

if [[ $# -lt 1 ]]; then
    usage
    exit 1
fi

SOURCE_DB_PATH="$1"
NO_UPLOAD="false"
if [[ "${2:-}" == "--no-upload" ]]; then
    NO_UPLOAD="true"
fi

if [[ ! -f "$SOURCE_DB_PATH" ]]; then
    echo "[ERROR] No existe la SQLite origen: $SOURCE_DB_PATH" >&2
    exit 1
fi

if [[ ! -f "$MANIFEST_PATH" ]]; then
    echo "[ERROR] No existe el manifiesto: $MANIFEST_PATH" >&2
    exit 1
fi

mkdir -p "$DEST_DB_DIR"

echo "[1/6] Copiando SQLite..."
cp -f "$SOURCE_DB_PATH" "$DEST_DB_PATH"

echo "[2/6] Verificando integridad SQLite..."
INTEGRITY_RESULT="$(sqlite3 "$DEST_DB_PATH" "PRAGMA integrity_check;" | tr -d '\r')"
if [[ "$INTEGRITY_RESULT" != "ok" ]]; then
    echo "[ERROR] integrity_check no devolvió 'ok': $INTEGRITY_RESULT" >&2
    exit 1
fi

PRODUCT_COUNT="$(sqlite3 "$DEST_DB_PATH" "SELECT COUNT(*) FROM products;" | tr -d '\r')"
echo "[INFO] products.count = $PRODUCT_COUNT"

echo "[3/6] Empaquetando asset pack..."
rm -f "$AAR_PATH"
(
    cd "$SCRIPT_DIR"
    xcrun ba-package package "$(basename "$MANIFEST_PATH")" --output-path "$(basename "$AAR_PATH")"
)

if [[ ! -f "$AAR_PATH" ]]; then
    echo "[ERROR] No se generó el archivo AAR: $AAR_PATH" >&2
    exit 1
fi

AAR_SIZE="$(du -h "$AAR_PATH" | awk '{print $1}')"
echo "[INFO] AAR generado: $AAR_PATH ($AAR_SIZE)"

if [[ "$NO_UPLOAD" == "true" ]]; then
    echo "[4/6] Upload omitido por --no-upload"
    echo "[DONE] Empaquetado completado sin subir a App Store Connect."
    exit 0
fi

echo "[4/6] Subiendo a App Store Connect..."
xcrun altool --upload-asset-pack "$AAR_PATH" \
    --apple-id "$APPLE_ID" \
    --api-key "$API_KEY_ID" \
    --api-issuer "$API_ISSUER_ID" \
    --wait \
    --output-format "$OUTPUT_FORMAT"

echo "[5/6] Consultando asset packs..."
xcrun altool --list-asset-packs \
    --apple-id "$APPLE_ID" \
    --api-key "$API_KEY_ID" \
    --api-issuer "$API_ISSUER_ID" \
    --output-format "$OUTPUT_FORMAT"

echo "[6/6] Consultando versiones de $ASSET_PACK_ID..."
xcrun altool --list-asset-pack-versions \
    --apple-id "$APPLE_ID" \
    --asset-pack-identifier "$ASSET_PACK_ID" \
    --api-key "$API_KEY_ID" \
    --api-issuer "$API_ISSUER_ID" \
    --output-format "$OUTPUT_FORMAT"

echo "[DONE] BD offline actualizada y subida."
