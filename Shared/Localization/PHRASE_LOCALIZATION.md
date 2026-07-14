# Traducción de frases y contextos

Los ficheros españoles siguen siendo la definición canónica: crean la frase, el autor, las
relaciones y los contextos. Los ficheros ubicados en `en.lproj` y `zh-Hans.lproj` solo crean
filas en `PhraseTranslation` y `ContextTranslation`; nunca sobrescriben favoritos, notas del
usuario ni relaciones.

Cada bloque traducido conserva el `id` de la frase española. Para traducir contextos se añade
`contexto_ids`, en el mismo orden que `contexto`:

```text
id=nev_001
autor=nev
nota=Nota editorial traducida
fuente=Fuente traducida
contexto=Imagination,Awareness
contexto_ids=context:imaginaci%C3%B3n,context:conciencia
texto=Translated quote
relacionadas=nev_002
```

El texto chino debe escribirse en chino simplificado natural (`zh-Hans`), conservando la
intención y el tono del original. Los identificadores no se traducen. Se admiten paquetes
parciales: si falta una frase o un contexto, la app muestra el español como respaldo.
