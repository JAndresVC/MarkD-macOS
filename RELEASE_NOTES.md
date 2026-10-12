# MarkD 0.2.0 Beta 9 — build 9

Entrega local del 2026-10-04. Corrige el bloqueo de Vista previa con documentos grandes mediante bloques bajo demanda y análisis del texto/esquema en segundo plano. Conserva editor, Undo y guardado nativos.

- Cancelación de análisis obsoletos y fuente UTF-8 exacta.
- Búsqueda distante y navegación del esquema solicitada durante carga.
- Navegación del esquema respetando la preferencia de Reducir movimiento.
- Nueva regresión de Vista previa y benchmark de documentos grandes.
- Once suites más metadatos: 12/12, salida 0; Debug/Analyze, Release, UI aislada y DMG aprobados.

Sonda de 4,14 MB: 28,09 s antes frente a aproximadamente 1,39 s hasta contenido disponible después. El indicador inicial apareció en 67 ms; no confundirlo con el documento listo ni interpretarlo como garantía para cualquier archivo.

Firma local para pruebas; sin Developer ID/notarización ni distribución pública de instaladores. Recuperación anterior al autosave, archivos reales, accesibilidad activa y compatibilidad/matriz siguen pendientes. Detalles: [Validación](docs/VALIDATION.md).

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

Las entregas anteriores son antecedentes, no una nueva verificación de la versión actual.
