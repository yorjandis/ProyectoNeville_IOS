# BackgroundDownloadExtension

Pasos para terminar la integración en Xcode:

1. Crear target de tipo `Background Download Extension` con opción `Apple-Hosted, Managed`.
2. Asignar este `Info.plist`: `Neville_iOS/BackgroundDownloadExtension/Info.plist`.
3. Asignar este entitlements: `Neville_iOS/BackgroundDownloadExtension/BackgroundDownloadExtension.entitlements`.
4. Añadir `BackgroundDownloadHandler.swift` al target de extensión.
5. En el target de extensión, añadir el flag de compilación `BACKGROUND_DOWNLOAD_EXTENSION` para `Swift Active Compilation Conditions`.
6. En app y extensión, verificar App Group: `group.com.ypg.nev.group`.
7. Subir el asset pack Apple-hosted que contiene `database/openfoodfacts_compact.sqlite` y usa el manifiesto `ManagedAssetPackManifest.json`.
