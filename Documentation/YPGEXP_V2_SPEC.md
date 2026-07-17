# YPGEXP-2: especificación criptográfica iOS / Android

Estado: contrato único previo a producción. No existe compatibilidad con `MYAPPEXPORT-1` ni con PBKDF2.

## 1. Objetivo y modelo de amenaza

`YPGEXP-2` protege confidencialidad e integridad de una exportación que se transporta entre iOS y Android mediante una contraseña compartida. Está diseñado frente a lectura, modificación, truncado, sustitución de cabecera y ataques offline de diccionario con hardware especializado.

No protege una contraseña débil, un dispositivo comprometido mientras los datos están descifrados, capturas de teclado/pantalla ni la longitud aproximada del contenido. Al ser un formato basado en contraseña y no en claves públicas de destinatarios, un KEM como ML-KEM no aportaría protección útil al flujo actual.

## 2. Primitivas y parámetros obligatorios

| Elemento | Valor exacto |
|---|---|
| Magia | ASCII `YPGEXP-2` |
| Formato | `com.ypg.neville.ndjson.export` |
| Versión | `2` |
| Normalización de contraseña | NFC y después UTF-8, sin terminador NUL |
| KDF | Argon2id v1.3 (`version = 19`) |
| Memoria Argon2id | `65536 KiB` |
| Pasadas Argon2id | `3` |
| Paralelismo Argon2id | `1` |
| Salt | 16 bytes CSPRNG independientes por fichero |
| Clave derivada | 32 bytes |
| AEAD | AES-256-GCM |
| Nonce | 12 bytes CSPRNG independientes por fichero |
| Tag | 16 bytes / 128 bits |

El paralelismo es deliberadamente `1`: es el contrato exacto de `crypto_pwhash(..., ARGON2ID13)` de libsodium usado en iOS. No debe sustituirse por el valor 4 de otros perfiles de Argon2.

Política de creación: la contraseña NFC debe contener al menos 15 puntos de código Unicode y como máximo 1024 bytes UTF-8. La importación no aplica el mínimo, pero sí el máximo, para que el error de contraseña no se convierta en un canal de formato.

## 3. Disposición binaria

Todos los saltos de línea estructurales son un solo byte `0A`; no se admite CRLF.

```text
offset  contenido
0       "YPGEXP-2" (8 bytes ASCII)
8       0A
9       cabecera JSON UTF-8 compacta, sin 0A literal
...     0A
...     ciphertext AES-GCM
EOF-16  tag GCM de 16 bytes
```

La cabecera contiene exactamente estos valores criptográficos (el orden JSON no forma parte de la semántica):

```json
{
  "cipher": "AES-256-GCM",
  "format": "com.ypg.neville.ndjson.export",
  "formatVersion": 2,
  "kdf": "ARGON2ID",
  "kdfIterations": 3,
  "kdfMemoryKiB": 65536,
  "kdfParallelism": 1,
  "kdfVersion": 19,
  "keyLengthBits": 256,
  "nonce": "base64-estándar-con-padding",
  "passwordNormalization": "NFC",
  "salt": "base64-estándar-con-padding",
  "tagLengthBits": 128
}
```

El AAD de AES-GCM son **todos los bytes desde el inicio del fichero hasta el segundo `0A`, incluido**:

```text
AAD = ASCII("YPGEXP-2") || 0A || headerJsonBytes || 0A
```

Android debe conservar los bytes originales de la cabecera al descifrar. No debe parsear y volver a serializar JSON para reconstruir el AAD.

## 4. Plaintext autenticado

```text
uint32_be manifestLength
manifestLength bytes de manifest.json UTF-8
resto: data.ndjson UTF-8
```

`manifestLength` es unsigned de 32 bits y big-endian. El manifiesto completo y NDJSON están cifrados. `manifest.encryption` repite todos los campos criptográficos salvo `format` y `formatVersion`; sus valores, incluido salt y nonce, deben coincidir con la cabecera o el fichero se rechaza.

## 5. Límites defensivos previos al KDF

El lector debe validar antes de ejecutar Argon2id:

- fichero: máximo `536875136` bytes;
- cabecera: de 1 a 4096 bytes;
- magia y versión exactas;
- todos los parámetros KDF/AEAD iguales a los valores de esta especificación;
- salt de 16 bytes, nonce de 12 bytes y payload mayor de 16 bytes;
- JSON numérico real: no aceptar booleanos como `1` o `0`.

Después de autenticar y descifrar:

- plaintext: máximo `536870912` bytes;
- manifiesto: de 1 a `1048576` bytes;
- `manifestLength` no puede rebasar el plaintext;
- manifiesto, resumen y líneas NDJSON se validan antes de importar datos.

Estos límites impiden que una cabecera manipulada solicite gigabytes de Argon2 o provoque asignaciones descontroladas. Cualquier fallo de GCM se comunica como un único error de autenticación, sin distinguir contraseña errónea de manipulación.

## 6. Implementación Kotlin de referencia

Para Argon2id puede usarse la API ligera de Bouncy Castle, sin registrar su provider. Dependencia de referencia:

```kotlin
implementation("org.bouncycastle:bcprov-jdk18on:1.84")
```

Derivación exacta:

```kotlin
import org.bouncycastle.crypto.generators.Argon2BytesGenerator
import org.bouncycastle.crypto.params.Argon2Parameters
import java.nio.charset.StandardCharsets
import java.text.Normalizer

fun deriveYpgexpKey(password: String, salt: ByteArray): ByteArray {
    require(salt.size == 16)
    val normalized = Normalizer.normalize(password, Normalizer.Form.NFC)
    val passwordBytes = normalized.toByteArray(StandardCharsets.UTF_8)
    require(passwordBytes.size <= 1024)

    val parameters = Argon2Parameters.Builder(Argon2Parameters.ARGON2_id)
        .withVersion(Argon2Parameters.ARGON2_VERSION_13)
        .withSalt(salt)
        .withMemoryAsKB(65_536)
        .withIterations(3)
        .withParallelism(1)
        .build()

    return ByteArray(32).also { output ->
        val generator = Argon2BytesGenerator()
        generator.init(parameters)
        generator.generateBytes(passwordBytes, output)
        passwordBytes.fill(0)
    }
}
```

Cifrado/descifrado AEAD:

```kotlin
import java.security.SecureRandom
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

private fun aesGcmEncrypt(
    plaintext: ByteArray,
    key: ByteArray,
    nonce: ByteArray,
    aad: ByteArray
): ByteArray {
    require(key.size == 32 && nonce.size == 12)
    val cipher = Cipher.getInstance("AES/GCM/NoPadding")
    cipher.init(
        Cipher.ENCRYPT_MODE,
        SecretKeySpec(key, "AES"),
        GCMParameterSpec(128, nonce)
    )
    cipher.updateAAD(aad)
    // Android/JCA devuelve ciphertext || tag(16), que coincide con YPGEXP-2.
    return cipher.doFinal(plaintext)
}

private fun aesGcmDecrypt(
    ciphertextAndTag: ByteArray,
    key: ByteArray,
    nonce: ByteArray,
    aad: ByteArray
): ByteArray {
    require(ciphertextAndTag.size > 16)
    val cipher = Cipher.getInstance("AES/GCM/NoPadding")
    cipher.init(
        Cipher.DECRYPT_MODE,
        SecretKeySpec(key, "AES"),
        GCMParameterSpec(128, nonce)
    )
    cipher.updateAAD(aad)
    return try {
        cipher.doFinal(ciphertextAndTag)
    } catch (_: AEADBadTagException) {
        throw SecurityException("Contraseña incorrecta o fichero manipulado")
    }
}
```

En creación, generar salt y nonce con `SecureRandom.nextBytes`; nunca reutilizar ni derivar el nonce de la contraseña, fecha o UUID. En un bloque `finally`, sobrescribir en lo posible `key`, `passwordBytes` y plaintext temporal.

Secuencia del lector Android:

1. comprobar tamaño máximo y localizar los dos primeros bytes `0A`;
2. comprobar magia y tamaño de cabecera;
3. parsear la cabecera UTF-8 y validar tipos, constantes, Base64 y longitudes;
4. asignar `aad = file.copyOfRange(0, payloadOffset)` sin reserializar JSON;
5. normalizar contraseña NFC, derivar 32 bytes con Argon2id y descifrar `file[payloadOffset..EOF]`;
6. limpiar la clave y validar el plaintext/manifiesto antes de persistir registros.

## 7. Vector interoperable

El vector completo está en `Documentation/TestVectors/ypgexp-v2-vector.json`. La clave Argon2id también fue contrastada con la implementación de referencia usando:

```text
argon2id v=19, m=65536 KiB, t=3, p=1, output=32
```

La prueba Android debe comprobar, en este orden: clave derivada, descifrado, plaintext exacto, rechazo con contraseña distinta, rechazo al alterar un bit de cabecera, ciphertext o tag y rechazo de parámetros fuera de perfil.
