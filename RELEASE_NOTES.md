# MarkD 0.2.0 Beta 12 (build 12)

Entrega funcional del 2026-11-10, comprobada en macOS 27.2.1 con Xcode 27.2 y SDK macOS 27.2.

- Abrir desde la bienvenida usa el mismo flujo de `NSDocumentController` que Archivo > Abrir. Corrige el caso reproducido de pérdida de acceso al guardar y preservar versiones después de importar un archivo.
- El recorrido anterior podía escribir los bytes nuevos y, aun así, mostrar permiso denegado y dejar el documento Edited. La validación comprueba tanto contenido como finalización del guardado.
- Diez guardados exactos en el Release corregido, con Undo, cambios de modo, Recientes y reinicio; versiones nativas con los estados esperados. Cancelar Abrir conserva la bienvenida.
- Once suites automáticas, metadatos por separado, Release/Analyze, firma local y DMG aprobados en la entrega. La [regresión de apertura](Tests/DocumentOpeningRegression.md) se ejecuta por separado del runner.

La corrección cubre el caso aislado; siguen pendientes otros documentos/volúmenes y la actualización instalada con uso diario. No cambian FileDocument, autosave, permisos del disco ni entitlements. Detalles y límites: [Validación](docs/VALIDATION.md).

El paquete local se llama `MarkD-0.2.0-Beta-12-Installer.dmg` y conserva el diseño de MarkD junto a Aplicaciones sobre fondo claro. Usa firma local para pruebas, sin Developer ID, notarización ni distribución pública de instaladores.

## Beta 11 y presentación del instalador

Beta 11, entregada el 2026-10-30, corrigió el contraste del texto seleccionado al perder el foco en Editar/RAW. Mantiene el fondo de selección nativo y usa texto semántico del sistema; la selección de Vista previa conserva sus colores del tema. Se comprobó con seis temas y foco activo/inactivo.

El 2026-11-09 cambió la presentación del DMG a MarkD y Aplicaciones con una flecha central. Esa imagen conservó exactamente la app Beta 11 y su número de build. Las herramientas del instalador se aíslan en desarrollo, con versiones y hashes fijados.

## Beta 10

Entregada el 2026-10-13. Las filas de listas grandes se construyen bajo demanda; Buscar materializa una fila distante antes de revelar la coincidencia. Se comprobó búsqueda hasta el final de listas sintéticas con viñetas y numeradas.

La sonda de 1.000 filas pasó de una mediana de pausa UI de 1.172,54 ms a 40,29 ms, con tres muestras por variante. No representa el tiempo de apertura de cualquier libro. También se comprobó navegación al encabezado final con Reducir movimiento activo; la sesión hablada de VoiceOver sigue pendiente.

## Beta 9

Entregada el 2026-10-04. Corrigió el bloqueo de Vista previa con documentos grandes mediante bloques bajo demanda y análisis del texto/esquema en segundo plano. Conserva editor, Undo y guardado nativos.

- Cancelación de análisis obsoletos y fuente UTF-8 exacta.
- Búsqueda distante y navegación del esquema solicitada durante carga.
- Navegación del esquema respetando la preferencia de Reducir movimiento.
- Regresión de Vista previa y benchmark de documentos grandes.
- Once suites más metadatos: 12/12 comprobaciones, salida 0; Debug/Analyze, Release, UI aislada y DMG aprobados en esa entrega.

Sonda de 4,14 MB: 28,09 s antes frente a aproximadamente 1,39 s hasta contenido disponible después. El indicador inicial apareció en 67 ms; no confundirlo con el documento listo ni interpretarlo como garantía para cualquier archivo.

## Entregas anteriores

| Beta | Cambio principal |
| --- | --- |
| 8 | BOM UTF-8 exacto, primer encabezado/código y pruebas unificadas de seguridad documental |
| 7 | Unicode exacto, recarga del modelo al editor y limpieza de Undo obsoleto |
| 6 | Búsqueda Unicode/rendimiento, análisis reutilizado y contraste de bienvenida |
| 5 | Bienvenida, guía, creación/apertura y recientes |
| 4 | Buscar sin foco inicial, ventana activa y respeto de hojas modales |
| 3 | Selector nativo de macOS 27 con compatibilidad y menú compacto |
| 2 | Numeración extrema, foco RAW, scroll de resultados y navegación por saltos de línea |

La preparación del 2026-11-12 conserva el código y la identidad Beta 12; sus pruebas de compilación, suites y empaquetado se documentan por separado y no repiten estos recorridos UI. La recuperación anterior al autosave, VoiceOver hablado, runtime 26.4 y las validaciones restantes para RC1 continúan pendientes. Las entregas anteriores conservan sus fechas de verificación.
