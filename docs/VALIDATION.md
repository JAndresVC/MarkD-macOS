# Validación de MarkD Beta 9

Entrega del 2026-10-04: versión 0.2.0, build 9.

## Entorno y comprobaciones

macOS 27.2 (26B5091g), Xcode 27.0 (27A266a), SDK macOS 27.0, arm64. El mínimo de ejecución declarado es 26.4; no se ejecutó allí.

Once suites automáticas más metadatos: **12/12, salida 0**. Parser: 15 casos; búsqueda: 8; Vista previa: 3 grupos; I/O: 6 grupos. Debug/Analyze, Release y QA UI aislada aprobados.

Se verificaron análisis fuera del hilo principal, cancelación, invalidación por fuente UTF-8 exacta, navegación distante solicitada durante carga y reemplazo de un documento sin publicar resultados obsoletos. La regresión de navegación pendiente falló antes de corregirse (133) y pasó después (0).

## Rendimiento observado

Sonda optimizada en ventana nativa oculta de 800 × 600 puntos, una muestra por tamaño:

| Documento sintético | Layout inicial anterior | UI inicial después | Espera posterior hasta contenido |
| --- | --- | --- | --- |
| 275.890 bytes | 1.703 ms | 21 ms | 111 ms |
| 1.379.890 bytes | 8.699 ms | 26 ms | 447 ms |
| 4.140.390 bytes | 28.093 ms | 67 ms | 1.325 ms |

En la última muestra, aproximadamente 1,39 s hasta contenido disponible. Los 67 ms representan la interfaz de carga, no el documento listo. No son garantías del tiempo de apertura ni mediciones del renderizado de todos los bloques.

## Recorridos UI y paquete

Release aislado y libro sintético de 2.759.890 bytes: Vista previa, desplazamiento, búsqueda entre capítulos lejanos, 36.000 coincidencias con navegación circular, edición, Undo y guardado con bytes exactos.

Se comprobaron encabezados en el árbol de accesibilidad y Buscar nativo en RAW. No equivale a una sesión hablada de VoiceOver.

El DMG local pasó integridad, firma local, metadatos, montaje de solo lectura, comparación con Release y enlace a Aplicaciones. SHA-256 de Beta 9: `d15b102898995fe4f4f7f68d8a95e0b6994a452a4d7bd8c0bc2e67906dc220a2`. Firma para pruebas, sin Developer ID ni notarización.

## Límites abiertos

- Recuperación anterior al guardado/autosave: un cierre forzado a los 7,325 s de una edición restauró el original. La recuperación después de confirmar autosave sí pasó. No se cambió su programación nativa.
- Sincronización visual inmediata de escrituras externas directas.
- Archivos reales de uso, listas/bloques únicos enormes, edición sostenida y memoria/Leaks.
- VoiceOver hablado, Reducir movimiento activo, runtime macOS 26.4, matriz visual e instalación/actualización preservando documentos y ajustes.

Las capturas añadidas a la propuesta del README el 2026-10-12 proceden de Beta 9 y un documento sintético pequeño; no repiten toda la QA ni cierran estos pendientes.
