# Paquetes de contenido localizable

La identidad del contenido no depende del título ni del nombre del fichero. Cada entrada de
`ContentManifest.<idioma>.json` reutiliza el mismo `id` en todos los idiomas y solo cambia `title`,
`resourceName` y `locale`.

```json
{
  "id": "conference:conf_ejemplo",
  "kind": "conference",
  "resourceName": "conf_example",
  "title": "Example conference",
  "locale": "en"
}
```

Los idiomas pueden migrarse de forma parcial. Si una entrada todavía no existe en inglés o
chino simplificado, `ContentRepository` usa automáticamente el título y el TXT español. Esto
permite publicar traducciones por lotes sin duplicar favoritos, notas ni elementos recientes.

Los textos traducidos se colocan en el directorio localizado del idioma (`en.lproj` o
`zh-Hans.lproj`) y su índice se declara en `ContentManifest.en.json` o
`ContentManifest.zh-Hans.json`. Los identificadores heredados se generan una sola vez a partir del nombre
del recurso español y deben copiarse literalmente al manifiesto traducido.
