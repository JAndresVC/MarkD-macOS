# Validación de MarkD Beta 13

Versión 0.2.0, build 13. QA funcional del 2026-11-14 en macOS 27.2.1 (26B131), Xcode 27.2 (27B52), SDK 27.2, arm64.

## Beta 13 y actualización del código público (2026-11-14)

Esta copia incorpora los mismos archivos de código, recursos, proyecto, scripts y pruebas de la entrega local Beta 13. El procedimiento manual adapta sus enlaces a este resumen público. La documentación pública conserva su alcance y fechas. Las pruebas funcionales y del instalador descritas aquí proceden de la entrega local; la transferencia del mismo código no representa un nuevo recorrido UI ni otra beta.

El control conservó `autosavingDelay = 0` y SwiftUI realizó sus autoguardados habituales. La variante corta configuró un segundo después de crear el controlador SwiftUI. Un observador iniciado antes de pegar comprobó bytes cada 20 ms. Tiempos desde iniciar el pegado hasta observar los bytes exactos, con tres muestras por variante.

| Variante | Muestras, segundos | Mediana |
| --- | --- | --- |
| Control | 15,136 / 15,035 / 15,037 | 15,037 s |
| Un segundo | 1,118 / 1,049 / 1,058 | 1,058 s |

Con cierre SIGKILL programado a los 8,071 s, el control perdió la última línea; la variante corta recuperó el contenido exacto. La primera sonda consultaba el controlador desde `App.init` y falló al arrancar antes de la preparación de SwiftUI. Se retiró esa consulta temprana. La app de entrega configura el intervalo desde `applicationDidFinishLaunching`.

El Release final pasó arranque, restauración, Undo/Redo y cambios de modo. Una edición Unicode llegó al disco en 1,136 s. Otro cierre a los 8,058 s conservó un archivo existente y el autosave de un documento nuevo sin ruta; ambas ventanas se restauraron y el primer guardado del nuevo fue exacto. Los cierres se limitaron a una copia QA con identidad independiente y ejecutable idéntico al Release al comparar copias sin firma.

Libro sintético de 4.830.318 bytes: edición/autoguardado en 4,266 s, Vista previa, búsqueda al capítulo 1399 y Undo/guardar exactos. No es un perfil de edición sostenida, memoria o energía. El tiempo superior al intervalo configurado confirma que no hay un plazo garantizado de escritura.

Once suites, cero fallos; Release/Analyze, metadatos y firma local aprobados. El DMG local pasó integridad, layout/fondo, solo lectura y comparación exacta del payload con Release; desmontado. Son comprobaciones de una entrega local; el repositorio publica código fuente.

La ejecución en macOS 26.4 queda aplazada por falta de un entorno de prueba. Se mantiene el mínimo técnico declarado y se documenta esa cobertura sin validar. La estabilización local se evalúa en macOS 27.2.1. VoiceOver hablado, matriz visual restante, validación de Beta 13 instalada y uso diario continúan pendientes. El riesgo residual de perder cambios antes de persistir no se considera aceptado ni resuelto.

## Controles de la copia pública actualizada (2026-11-14)

Los archivos técnicos coinciden byte por byte con la entrega validada de Beta 13. El árbol conserva 90 archivos y no incorpora informes privados, rutas personales, compilaciones, instaladores ni historia del repositorio privado. No se repitieron build o suites para transferir el mismo código.

Gitleaks archivos/historial y TruffleHog filesystem/historial terminaron 0, sin hallazgos. Verificación externa de credenciales desactivada. Semgrep local terminó 0, con 77 archivos, cero hallazgos/errores y cobertura genérica Swift/Bash; el icono preexistente de más de 1 MB se omitió por tamaño. Se conservan los hooks normales de commit/push para los commits de esta actualización.

## Antecedentes de Beta 12


Versión 0.2.0, build 12. La QA funcional de esta versión corresponde al 2026-11-10; la preparación de la copia pública comenzó el 2026-11-12.

## Verificaciones de esta copia (2026-11-12)

Release y Analyze de esta copia terminaron con salida 0 en macOS 27.2.1, Xcode 27.2 (27B52), destino arm64. Las once suites automáticas, los metadatos del bundle y la firma estricta local también pasaron. Estos resultados corresponden a la copia preparada el 2026-11-12; no incluyen un nuevo recorrido UI.

Las herramientas de empaquetado se prepararon en un entorno aislado con `uv --offline` y `--require-hashes`: Python 3.14, `dmgbuild` 1.6.7, `ds-store` 1.3.3 y `mac-alias` 2.2.3. No se incorporan a la app. La imagen de comprobación, creada fuera del árbol público, pasó empaquetado e integridad, montaje de solo lectura, layout, metadatos, firma y comparación exacta con el Release de esta copia. Se desmontó al terminar. Es evidencia local de la preparación; no se incluye como descarga pública ni sustituye el DMG de la entrega de Beta 12.

Gitleaks sobre archivos e historial completo y TruffleHog sobre filesystem e historial terminaron con salida 0, sin hallazgos. La verificación externa de credenciales estuvo desactivada. Semgrep local terminó con salida 0, sin hallazgos ni errores: 77 archivos, incluidos los dos Python del instalador. Swift/Bash tienen cobertura genérica; no es análisis semántico específico de esos lenguajes. El icono PNG preexistente de 1024 px se omitió por tamaño (>1 MB); no cambió en esta preparación.

La revisión de privacidad no encontró rutas personales, informes privados ni metadatos locales de Xcode en los 90 archivos publicables. Código, recursos, configuración y pruebas coinciden con Beta 12; el procedimiento de regresión solo cambia su enlace al resumen público. Los hooks normales de Git se conservan y el estado local se verificó antes de la publicación inicial. Los resultados funcionales de las secciones siguientes mantienen sus fechas históricas.

La preparación se mantuvo local hasta aprobar el destino. El primer envío publicó el commit `fa13d9a` en [JAndresVC/MarkD-macOS](https://github.com/JAndresVC/MarkD-macOS), rama `main`, con 90 archivos. Se comprobó acceso público sin autenticación y coincidencia del commit remoto con el aprobado. La licencia MIT y el crédito Andrés Vargas se conservan. Esta actualización de estado no añade QA funcional ni distribuye instaladores.

## QA funcional de Beta 12 (2026-11-10)

Entorno: macOS 27.2.1 (26B131), Xcode 27.2 (27B52), SDK macOS 27.2 (26B118), arm64. El mínimo de ejecución declarado es 26.4; no se ejecutó allí.

`script/test_all.sh` pasó once suites con cero fallos. Los metadatos se ejecutaron después por separado, con salida 0. Parser: 15 casos; localización: 4; búsqueda: 8; scroll: 4; documentos de Vista previa: 4 grupos; seguridad del editor: 5; I/O: 6; navegación: 5; Buscar del editor: 5. Temas/apariencia/caché y encabezados accesibles también pasaron.

Release y Analyze terminaron con salida 0. Xcode avisó de destinos arm64/x86_64 coincidentes y seleccionó arm64. La firma local estricta pasó. Esta evidencia no representa una prueba en Intel ni en macOS 26.4.

### Apertura, guardado y versiones

En Beta 11 se reprodujo un fallo al abrir desde la bienvenida: Guardar escribió los bytes nuevos, pero mostró permiso denegado y mantuvo Edited. Abrir un archivo equivalente mediante Archivo > Abrir pasó en la misma carpeta. Guardar como rescató el contenido del caso fallido.

Beta 12 usa el flujo nativo de `NSDocumentController` para Abrir desde la bienvenida. En el Release corregido pasaron tres ciclos de edición/Guardar/Vista previa/RAW/Editar/Undo/Guardar, reapertura desde Recientes y reinicio de la app: diez guardados exactos, con estados de 179 y 204 bytes, sin alerta ni Edited residual. El archivo sintético conservó BOM, CRLF y Unicode. Cancelar Abrir volvió a la bienvenida.

La consulta de versiones nativas encontró cero en el caso fallido, tres en el control nativo y trece en Beta 12. Las versiones legibles de los controles coincidieron por hash con los estados esperados y no tenían conflictos. No se exige una versión por pulsación o guardado; macOS puede agruparlas.

El recorrido aisló y corrigió esta entrada de apertura. Faltan otros documentos y volúmenes; no demuestra que todo error de permisos tenga la misma causa. El [procedimiento de regresión](../Tests/DocumentOpeningRegression.md) es integración UI asistida y no forma parte del runner automático.

### Paquete local

La imagen `MarkD-0.2.0-Beta-12-Installer.dmg` pasó integridad, metadatos, firma local, montaje de solo lectura, layout/fondo y comparación del bundle montado con el Release probado. Se desmontó al terminar y se conservaron las imágenes anteriores.

El layout mantiene la presentación MarkD junto a Aplicaciones aprobada el 2026-11-09. La ronda de Beta 12 comprobó la configuración incrustada; no repitió la inspección visual de Finder de aquella fecha. Firma para pruebas, sin Developer ID ni notarización. No hubo instalación automática.

## Antecedentes de Beta 10 y Beta 11

Beta 10 (2026-10-13) añadió filas de listas bajo demanda. Pasaron búsqueda hasta el último resultado y vuelta en listas sintéticas de 2.000 filas, junto con la regresión de listas. La mediana de pausa UI de la sonda de 1.000 filas pasó de 1.172,54 ms a 40,29 ms, con tres muestras por variante; no mide apertura total de cualquier documento.

La navegación al encabezado final con Reducir movimiento activo pasó en Beta 10. Los controles/encabezados del árbol de accesibilidad tienen evidencia, pero la sesión hablada de VoiceOver sigue pendiente. Los ajustes temporales se restauraron tras la prueba; Beta 12 no volvió a activarlos.

Beta 11 (2026-10-30) comprobó el contraste de selección de Editar/RAW en seis temas, con y sin foco. La corrección usa fondo de selección nativo y texto semántico del sistema. Vista previa mantiene su selección del tema. Son resultados de aquella entrega, no una nueva matriz completa de esta copia.

## Rendimiento histórico de Beta 9 (2026-10-04)

Sonda optimizada en ventana nativa oculta de 800 × 600 puntos, una muestra por tamaño:

| Documento sintético | Layout inicial anterior | UI inicial después | Espera posterior hasta contenido |
| --- | --- | --- | --- |
| 275.890 bytes | 1.703 ms | 21 ms | 111 ms |
| 1.379.890 bytes | 8.699 ms | 26 ms | 447 ms |
| 4.140.390 bytes | 28.093 ms | 67 ms | 1.325 ms |

En la última muestra, aproximadamente 1,39 s hasta contenido disponible. Los 67 ms representan la interfaz de carga, no el documento listo. No son garantías del tiempo de apertura ni mediciones del renderizado de todos los bloques.

La entrega de Beta 9 pasó once suites más metadatos, Debug/Analyze y Release. Se verificaron análisis fuera del hilo principal, cancelación, invalidación por fuente UTF-8 exacta, navegación distante solicitada durante carga y reemplazo de un documento sin publicar resultados obsoletos. La regresión de navegación pendiente falló antes de corregirse (133) y pasó después (0).

El recorrido UI aislado usó un libro sintético de 2.759.890 bytes: Vista previa, desplazamiento, búsqueda entre capítulos lejanos, 36.000 coincidencias con navegación circular, edición, Undo y guardado con bytes exactos. Encabezados del árbol de accesibilidad y Buscar nativo en RAW pasaron; no equivalen a VoiceOver hablado.

El DMG local de Beta 9 también pasó integridad, firma, metadatos, montaje de solo lectura, comparación con Release y enlace a Aplicaciones. SHA-256 de aquella imagen: `d15b102898995fe4f4f7f68d8a95e0b6994a452a4d7bd8c0bc2e67906dc220a2`.

Las capturas del README proceden de Beta 9 y un documento sintético pequeño, preparadas el 2026-10-12. Se conservan con ese rótulo; no repiten la QA ni prueban la apariencia actual en toda la matriz.

## Límites registrados en Beta 12 antes de RC1

- Recuperación anterior al guardado/autosave: un cierre forzado a los 7,325 s de una edición restauró el original. La recuperación después de confirmar autosave sí pasó. No se cambió su programación nativa ni se garantiza recuperar cada pulsación.
- Sincronización visual inmediata de escrituras externas directas.
- Párrafos/código individuales enormes, edición sostenida y memoria/Leaks.
- VoiceOver hablado, altura mínima/matriz visual restante y actualización instalada preservando documentos y ajustes. La ejecución en macOS 26.4 está aplazada por falta de entorno.
- Seguimiento del guardado con otros documentos/volúmenes y uso diario. La corrección de Beta 12 cubre el caso controlado descrito arriba.

Los resultados no declaran RC1 ni 1.0 estable. Hace falta evaluar una mitigación o aceptar expresamente el límite anterior al autosave antes de aprobar la candidata.
