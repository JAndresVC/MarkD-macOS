# MarkD: guía del proyecto

Estado técnico de MarkD 0.2.0 Beta 14 (build 14), entrega local del 2026-11-25. Véanse [los resultados de validación](docs/VALIDATION.md).

## Objetivo y alcance

Lector y editor Markdown nativo para macOS, con lectura cómoda, edición predecible, navegación por teclado y varias ventanas. La beta no declara estabilidad 1.0 ni distribución pública de instaladores.

## Arquitectura

- Proyecto y esquema: `MarkD.xcodeproj`, MarkD. Mínimo declarado macOS 26.4; su ejecución está sin validar y aplazada por falta de entorno. La estabilización local se evalúa en macOS 27.2.1. Beta 13 se verificó con Xcode 27.2 y SDK macOS 27.2.
- SwiftUI y AppKit, sin dependencias externas de ejecución, WebView ni servicios de red. Las herramientas aisladas de empaquetado son dependencias de desarrollo.
- `MarkDAppDelegate.applicationDidFinishLaunching` configura `NSDocumentController.shared.autosavingDelay = 1`. SwiftUI debe crear antes su controlador; consultar el singleton desde `App.init` hizo fallar el arranque de una sonda experimental. Conservar este punto del ciclo de vida. Es una espera mínima, sin garantía de escritura inmediata.
- `FileDocument` y `DocumentGroup` gestionan lectura, guardado, autosave, conflictos y ventanas. La migración a otra API de documentos permanece aplazada.
- UTF-8 estricto, conservando BOM, Unicode y saltos de línea. Bytes inválidos producen error; no hay reparación ni conversión automática de otras codificaciones.
- Parser/esquema ignoran solamente el BOM inicial en su copia de análisis. El editor y los bytes guardados lo conservan.
- Un `NSTextView` permanece vivo entre Editar, Vista previa y RAW. Conservar selección, foco, posición y Undo. RAW permite seleccionar, copiar y buscar, sin edición.
- `NavigationSplitView` muestra esquema de encabezados y contenido. Navegación del editor por offsets UTF-16, incluidos LF/CRLF/CR y Unicode compuesto.
- Vista previa usa `LazyVStack` y prepara parser/esquema fuera del hilo de UI. Las tareas canceladas no publican snapshots antiguos; el parser comprueba cancelación entre líneas.
- Desde Beta 10, las filas de listas también se construyen bajo demanda. Buscar materializa primero el bloque y después la fila distante mediante una petición protegida por la fuente, consulta y resultado actuales. Conservar las dos etapas para encontrar filas aún no construidas.
- `MarkdownSource` distingue bytes UTF-8 exactos. Cachés acotadas por instancia; cambiar resultado activo, foco o tema no debe repetir el parser.
- Buscar en Vista previa usa la geometría de `Text.LayoutKey` para revelar la coincidencia precisa. Conservar selección, enlaces y accesibilidad; no sustituirla por centrado del bloque.
- La búsqueda Unicode cubre el carácter visible completo y evita duplicados dentro de caracteres compuestos.
- Una solicitud de navegación durante carga espera a los bloques. La navegación del esquema consulta Reducir movimiento; el recorrido al encabezado final con la preferencia activa pasó en Beta 10.
- Buscar en Editar/RAW se dirige al editor de la ventana activa incluso sin foco inicial y no actúa sobre documentos con una hoja modal.
- Temas y apariencia de ventana se propagan a todas las escenas. Desde Beta 11, Editar/RAW conservan el fondo nativo de selección y texto semántico legible con y sin foco. La selección de Vista previa mantiene los colores del tema. No aplicar la configuración de toolbar de documentos a Ajustes.
- Selector de modos: pestañas nativas en macOS 27 con compilador compatible; alternativa segmentada anterior. Conservar las guardas de compilador/disponibilidad.
- Por debajo de 780 puntos, usar el menú compacto rotulado. La ventana de documento tiene mínimo de 560 × 360 puntos; conservar la restricción de tamaño y comprobarla antes de modificarla.
- Bienvenida: nuevo documento, abrir, guía localizada y recientes nativos. Desde Beta 12, el botón Abrir invoca `NSDocumentController.shared.openDocument(nil)`, igual que Archivo > Abrir. AppKit conserva el acceso necesario durante la vida del documento. Cancelar mantiene la bienvenida; abrir un documento la oculta. No duplicar documentos ya abiertos.

## Archivos principales

| Archivo | Responsabilidad |
| --- | --- |
| `MarkD/MarkDApp.swift` | Escenas, comandos y Ajustes |
| `MarkD/ContentView.swift` | Modos, split view y toolbar |
| `MarkD/EditorView.swift` | Editor nativo, foco, Buscar, Undo y estilos |
| `MarkD/MarkDocument.swift` | Lectura/escritura UTF-8 y tipos de documento |
| `MarkD/MarkdownParser.swift` | Bloques, encabezados y parsing inline |
| `MarkD/MarkdownPreviewView.swift` | Vista previa, carga y navegación |
| `MarkD/DerivedValueCache.swift` | Fuente exacta, worker cancelable y cachés |
| `MarkD/PreviewSearch.swift` | Coincidencias, navegación y resaltado |
| `MarkD/PreviewSearchText.swift` | Geometría y desplazamiento nativos |
| `MarkD/SidebarView.swift` | Esquema de encabezados |
| `MarkD/AppTheme.swift` | Paletas y colores semánticos |
| `MarkD/ThemePresentation.swift` | Tema y apariencia de ventana |
| `MarkD/Localization.swift` | Textos y guía en cuatro idiomas |
| `MarkD/WelcomeView.swift` | Bienvenida y acciones de documentos |
| `MarkD/AppIdentity.swift` | Nombre y versión visible |
| `script/` | Compilación, pruebas y empaquetado |
| `script/dmg/` | Layout, fondo reproducible y requisitos del instalador |
| `script/test_dmg_layout.py` | Integración sobre el DMG montado |
| `Tests/` | Regresiones funcionales y sondas UI |

## Compilar y probar

Desde la raíz:

```bash
./Abrir\ MarkD.command
./script/test_all.sh
```

El iniciador no cierra una app ya abierta. `script/build_and_run.sh` es la entrada de recompilación: solicita cierre normal y espera la resolución de documentos sin guardar; no fuerza el cierre.

El runner ejecuta once suites, conserva logs y códigos reales, continúa después de fallos y termina con salida no cero si alguna suite falla. La ruta opcional a un bundle añade metadatos. Benchmarks y pruebas UI se ejecutan por separado.

```bash
./script/benchmark_large_document.sh
./script/benchmark_preview_search.sh
./script/test_bundle_metadata.sh /ruta/a/MarkD.app
```

Los scripts seleccionan Xcode en Aplicaciones y admiten `DEVELOPER_DIR`. Las pruebas UI necesitan permisos de Accesibilidad y una app de QA aislada; no usar documentos privados ni terminar procesos de uso personal. La [regresión de apertura y guardado](Tests/DocumentOpeningRegression.md) requiere comprobar bytes, alertas y estado Edited; escribir bytes en disco no basta para aprobar un guardado que muestra error.

## Paquetes locales

Con `uv` disponible, preparar las herramientas desde la raíz:

```bash
uv venv .build/dmg-tools
uv pip install --python .build/dmg-tools/bin/python --require-hashes -r script/dmg/requirements.txt
./script/package_dmg.sh
```

El resultado es `dist/MarkD-0.2.0-Beta-13-Installer.dmg`. El script compila Release, exige SDK 27 o posterior, verifica metadatos/icono/firma e integridad y no sobrescribe DMG existentes. Acepta otra ruta de salida libre como primer argumento. `dmgbuild` 1.6.7, `ds-store` 1.3.3 y `mac-alias` 2.2.3 tienen versiones/hashes fijados en `script/dmg/requirements.txt`; solo se usan para desarrollo.

El layout nativo muestra MarkD y Aplicaciones sobre fondo claro. Su configuración y fondo viven en `script/dmg/`; no cambia preferencias globales de Finder. Después de montar la imagen en solo lectura, comprobarla con:

```bash
.build/dmg-tools/bin/python script/test_dmg_layout.py '/Volumes/Instalar MarkD'
```

`MARKD_APP_PATH` permite reempaquetar un bundle ya validado sin recompilar; conserva los controles y exige una ruta de salida libre. Comparar la app montada con el original y desmontar al terminar. El test de layout no instala ni ejecuta MarkD.

Cada entrega que modifique la app o corrija errores debe incrementar beta/build y entregar un DMG local validado, conservando los anteriores. Una edición documental o exportación del mismo código no requiere otra beta. Este flujo no autoriza instalación automática, cambios adicionales de firma/entitlements ni publicación de instaladores.

## Límites abiertos

- **Pérdida de edición anterior al guardado/autosave:** comprobada al terminar el proceso antes de persistir los bytes. Guardar con ⌘S y comprobar que termine para un cambio importante. No prometer recuperación de cada pulsación.
- Escrituras externas directas pueden mantener la vista antigua hasta resolver el conflicto nativo. Las pruebas de escritura coordinada no prueban sincronización en vivo con todos los editores.
- Beta 14 comprobó el contraste del selector compacto en los seis temas a 560 × 360 puntos de contenido en copia aislada y su funcionamiento a 560 puntos de ancho en la app instalada. La altura mínima en la instalación y el cruce de la corrección con los cuatro idiomas siguen pendientes.
- Se reprodujo la desaparición de las entradas de Recientes al actualizar entre dos compilaciones con firma local. Los archivos permanecieron intactos. Queda aislar el papel de la firma.
- Párrafos/código individuales enormes, edición sostenida y memoria/Leaks necesitan más cobertura. Las filas de listas grandes tienen la corrección bajo demanda de Beta 10.
- QA-12 está corregido para el recorrido de apertura de bienvenida reproducido. Faltan más documentos/volúmenes y comprobar la actualización instalada y el uso diario.
- VoiceOver hablado permanece aplazado. La ejecución en macOS 26.4 queda sin validar por falta de entorno y no bloquea por sí sola la estabilización local en macOS 27.2.1. La prueba parcial con Reducir movimiento activo no aprueba toda la accesibilidad.
- Tablas, imágenes, tareas, notas al pie, filtrado del esquema y tema automático son propuestas; no figuran como implementados.
- iPhone/iPad y distribución pública de binarios quedan fuera del alcance de estabilización actual.

## Roadmap por criterios

| Etapa | Criterio |
| --- | --- |
| Beta 9 entregada | Bloques bajo demanda y análisis asíncrono; regresiones y QA sintética |
| Beta 10 entregada | Filas de listas bajo demanda, búsqueda distante y recorridos seleccionados de interfaz/accesibilidad |
| Beta 11 entregada | Contraste de selección con y sin foco en Editar/RAW |
| Beta 12 entregada | Apertura nativa desde bienvenida, guardados/Undo, Recientes/reinicio y versiones exactas en el caso controlado |
| Beta 13 entregada | Autoguardado periódico de un segundo, comparación y recuperación, Undo/Redo, varias ventanas, archivo grande y DMG local |
| Beta 14 entregada | Contraste del selector compacto, seis temas, comprobación instalada y DMG local |
| Cierre de estabilización | Investigar continuidad de Recientes, validar uso diario, otros documentos y volúmenes, y evaluar recuperación anterior al autosave. macOS 26.4 y VoiceOver hablado siguen aplazados. |
| RC1 | Congelar funciones y usar durante 7 a 14 días; sin bugs críticos ni pérdida de contenido cuyo guardado/autosave había terminado |
| 1.0 local | Cumplir los criterios y aceptar la candidata; no implica por sí mismo un instalador público notarizado |

Antes de RC1 debe evaluarse una mitigación o aceptar expresamente el límite anterior al autosave. Una nueva corrección de la app requiere Beta 15 y un DMG local validado. El roadmap no garantiza número de betas/fechas ni autoriza nuevas funcionalidades.

## Reglas de colaboración y relevo

1. Leer esta guía y `git status --short` antes de actuar; conservar cambios previos y no descartar trabajo ajeno.
2. Revisiones/diagnósticos permanecen en solo lectura salvo autorización para editar.
3. Comprender los callers y reproducir el fallo antes de corregirlo; reutilizar componentes existentes/nativos.
4. Mantener validación, seguridad de datos, accesibilidad y manejo de errores. No añadir dependencias o migraciones especulativas.
5. Conservar editor, Undo, fuente exacta y manejo nativo de documentos.
6. Tras cambios materiales, actualizar esta guía y ejecutar regresiones relevantes. Compilar no demuestra por sí solo que un bug esté resuelto.
7. Antes de cambiar icono/diseño aprobado, presentar una variante para revisión.
8. Conservar betas anteriores y verificar el paquete si cambia la app.
9. No incluir documentos personales, credenciales, compilaciones ni configuraciones locales en Git. No omitir controles de secretos ni publicar resultados incompletos como seguros.
10. Publicar/instalar y cambiar firma o historial requieren un encargo específico; una tarea de revisión no los autoriza.

Al detener una tarea, registrar objetivo, cambios, pruebas con códigos reales, límites y siguiente paso. Si el alcance es de solo lectura, entregar el relevo fuera de los archivos del proyecto. Conservar la distinción entre hechos comprobados, hipótesis y propuestas.

## Identidad y licencia

El bundle sigue siendo `com.Andres.MarkD`: cambiarlo afectaría ajustes y gestión de documentos. Autor: Andrés Vargas. Código bajo [MIT](LICENSE).

## Preparación de publicación (2026-11-12)

La preparación conservó el historial público separado, MIT, el crédito Andrés Vargas y correo privado de GitHub, sin incorporar el historial del repositorio de trabajo. El remoto se configuró únicamente después de aprobar la publicación. Esta preparación reunió el código de Beta 12 con documentación apta para publicar; no añade funciones a la app ni requiere Beta 13 por los cambios documentales.

Los controles locales de archivos e historial con Gitleaks y TruffleHog terminaron con salida 0 y sin hallazgos. Semgrep terminó con salida 0, sin hallazgos/errores, sobre 77 archivos; su cobertura de Swift/Bash es genérica. Release/Analyze, once suites, metadatos, firma local y empaquetado de comprobación de esta copia también pasaron. El identificador del estado local revisado se consulta con `git rev-parse HEAD`; el historial usa únicamente la identidad noreply aprobada. Resultados en [docs/VALIDATION.md](docs/VALIDATION.md), separados de la QA funcional del 2026-11-10.

Antes de publicar, verificar el estado final con Gitleaks, TruffleHog y las reglas locales de Semgrep, incluidos los commits nuevos; conservar los hooks existentes. La cobertura genérica de Semgrep no sustituye una revisión específica de Swift.

## Publicación del código

El código Beta 12 se publicó en [JAndresVC/MarkD-macOS](https://github.com/JAndresVC/MarkD-macOS), rama `main`, con licencia MIT. El primer envío fue el commit `fa13d9a`, revisado antes de publicar. El remoto `origin` de esta copia apunta a ese repositorio. La actualización de Beta 13 incorpora autoguardado periódico y su documentación de validación. La historia pública sigue siendo independiente y conserva MIT y los créditos aprobados.

La publicación del código como beta y la distribución de una app notarizada siguen siendo decisiones separadas.
