# Asset Pack Release (LectorEtiquetas)

Estructura esperada por la app:
- `database/openfoodfacts_compact.sqlite`
- `ManagedAssetPackManifest.json`

## 1) Empaquetar (.aar)
```bash
cd "/Users/yorjandis/Desktop/ProyectoNeville_IOS/Neville_iOS/Shared/Models/LectorEtiquetas/ManagedAssets/AssetPackRelease"
xcrun ba-package package ManagedAssetPackManifest.json --output-path openfoodfacts-compact-db.aar
```

## 2) Subir a App Store Connect (Apple-Hosted)
```bash
xcrun altool --upload-asset-pack \
  "/Users/yorjandis/Desktop/ProyectoNeville_IOS/Neville_iOS/Shared/Models/LectorEtiquetas/ManagedAssets/AssetPackRelease/openfoodfacts-compact-db.aar" \
  --apple-id <APPLE_ID_NUMERICO_DE_TU_APP> \
  --api-key YZ83CX57YZ \
  --api-issuer 754e0e8c-46d2-4679-9597-bd85a59e0ce9 \
  --wait --output-format json
```

## 3) Verificar estado
```bash
xcrun altool --list-asset-packs \
  --apple-id <APPLE_ID_NUMERICO_DE_TU_APP> \
  --api-key YZ83CX57YZ \
  --api-issuer 754e0e8c-46d2-4679-9597-bd85a59e0ce9 \
  --output-format json

xcrun altool --list-asset-pack-versions \
  --apple-id <APPLE_ID_NUMERICO_DE_TU_APP> \
  --asset-pack-identifier openfoodfacts-compact-db \
  --api-key YZ83CX57YZ \
  --api-issuer 754e0e8c-46d2-4679-9597-bd85a59e0ce9 \
  --output-format json
```

## 4) Key .p8
`altool` busca `AuthKey_YZ83CX57YZ.p8` en:
- `./private_keys`
- `~/private_keys`
- `~/.private_keys`
- `~/.appstoreconnect/private_keys`
- o en `API_PRIVATE_KEYS_DIR`
