# Presentaciones de funciones premium

Cada función tiene su propia carpeta con:

- un archivo Swift que contiene su título, descripción comercial y valor práctico localizables;
- una carpeta `Images` preparada para sus capturas de pantalla.

Todos los textos comerciales se resuelven desde la tabla `PremiumFeatures.strings`,
disponible en español (`es`), inglés (`en`) y chino simplificado (`zh-Hans`).

Cada fichero `…PremiumFeature.swift` declara un enum conforme a `PremiumFeatureScreenshotName`. Los valores del enum contienen los nombres exactos de las capturas, sin extensión, y la galería respeta estrictamente el orden de declaración de sus casos. Los nombres y sus sufijos son libres; para añadir, retirar o reordenar capturas solo hay que editar ese enum. Mientras no exista un recurso declarado, la galería muestra una composición visual coherente en lugar de un espacio vacío.

Para presentar una función bloqueada se usa:

```swift
PremiumFeaturePreviewView(feature: .agenda)
```

Para proteger una vista nueva sin repetir la lógica de suscripción:

```swift
PremiumFeatureGate(feature: .agenda) {
    AgendaMainView()
}
```
