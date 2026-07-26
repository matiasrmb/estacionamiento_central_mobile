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
