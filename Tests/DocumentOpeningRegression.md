# Regresión de apertura y guardado desde bienvenida

Recorrido de integración sobre un Release firmado con App Sandbox y acceso a archivos elegidos por el usuario. Se ejecuta por separado de `script/test_all.sh`; las suites de `FileDocument` no comprueban los permisos del panel ni la preservación de versiones de un documento abierto.

1. Preparar dos archivos Markdown sintéticos iguales, fuera del contenedor de la app, en una carpeta nueva. Conservar sus bytes esperados, incluyendo BOM/CRLF/Unicode si los contienen. Usar rutas nuevas al comparar builds para evitar que una autorización anterior o un documento ya abierto oculte el fallo.
2. Desde la bienvenida, pulsar Abrir y cancelar. Debe permanecer la bienvenida sin crear un documento.
3. Desde la bienvenida, abrir el primer archivo. Añadir una línea con acentos y emoji y guardar. Comprobar los bytes del archivo **y** que no aparezca alerta ni permanezca Edited. Un archivo escrito con un aviso de error no aprueba la prueba.
4. Pasar por Vista previa y RAW, volver a Editar, deshacer y guardar. El archivo debe volver a los bytes originales sin alerta ni estado editado residual. Repetir tres ciclos.
5. Cerrar solo ese documento ya guardado; reabrirlo desde Recientes y repetir edición/guardar/Undo/guardar. Reiniciar la app sin documentos pendientes, reabrir desde Recientes y repetir.
6. Abrir el segundo archivo mediante Archivo → Abrir y comparar la misma secuencia. En el caso corregido, ambas entradas deben conservar el guardado y las versiones nativas.
7. Consultar de forma no destructiva `NSFileVersion.otherVersionsOfItem(at:)` para ese fixture. Comparar los bytes/hashes de las versiones con los estados originales/editados. No se exige una versión por pulsación o por guardado: macOS puede agruparlas.

Si aparece un error, conservar el texto mediante Guardar como en una copia separada antes de cerrar. Capturar el aviso, estado Edited, bytes y errores nativos; no cambiar permisos ni desactivar el sandbox para que pase.

Evidencia del 2026-11-10: Beta 11 instalada falló al guardar desde bienvenida, con preservación de versiones denegada; el control Abrir nativo pasó. La corrección Beta 12 pasó diez guardados, Recientes/reinicio y versiones con contenido exacto. Ver [validación pública](../docs/VALIDATION.md) para alcance y límites.
