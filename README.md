# Estacionamiento Central Mobile

Aplicación Flutter para la operación móvil de Estacionamiento Central.

## Impresión de comprobantes

El comprobante durable y canónico se crea en la API como trabajo `PC_PDF` y
lo procesa la PC con Print Agent. Esta es la ruta que debe consultarse para
auditoría, reimpresiones y entrega del comprobante.

La impresora integrada Sunmi sólo genera una copia local opcional. Su intento
no crea una cola durable, no se audita y una falla no revierte ni bloquea el
ingreso o la salida ya registrados. La aplicación nunca solicita
`imprimir_sunmi: true` a la API.

## Desarrollo

```sh
flutter analyze
flutter test
```

## Firma de releases Android

Los builds `--release` requieren una configuración de firma completa. Los builds
debug no requieren esta configuración.

### Desarrollo local

Crear `android/key.properties` (ya ignorado por Git) con estas claves. No subir
este archivo ni el keystore al repositorio.

```properties
storeFile=/ruta/al/keystore
storePassword=
keyAlias=
keyPassword=
```

Completar los valores sólo en la máquina local. `storeFile` debe apuntar a un
keystore existente y legible.

### CI

En CI, no crear `android/key.properties`. Configurar las cuatro variables de
entorno siguientes como secretos del proveedor:

| Variable | Equivale a |
| --- | --- |
| `ANDROID_SIGNING_STORE_FILE` | `storeFile` |
| `ANDROID_SIGNING_STORE_PASSWORD` | `storePassword` |
| `ANDROID_SIGNING_KEY_ALIAS` | `keyAlias` |
| `ANDROID_SIGNING_KEY_PASSWORD` | `keyPassword` |

Usar una fuente completa: el archivo local o las cuatro variables de CI. La
presencia de `android/key.properties` selecciona exclusivamente la fuente local:
debe ser legible y contener las cuatro claves completas. Las variables de CI se
usan sólo cuando ese archivo no existe. No mezclar valores entre ambas fuentes.

### Publicación

Google Play App Signing administra la clave de firma de la aplicación publicada.
Conservar de forma segura la clave de carga y sus credenciales, y no incluirlas
en código, Git, documentación ni logs.

Si falta la configuración al ejecutar un release, Gradle falla antes de compilar
con: `Release signing configuration is incomplete. Configure ignored
android/key.properties or CI signing environment variables.`

Si `android/key.properties` existe pero no se puede leer o interpretar, los
builds debug no se ven afectados; un release falla explícitamente sin usar las
variables de CI como alternativa. Lo mismo ocurre si el archivo existe pero está
incompleto.
