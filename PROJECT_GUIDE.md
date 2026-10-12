# MarkD — guía del proyecto

Estado técnico: MarkD 0.2.0 Beta 9 (build 9), entrega del 2026-10-04. Esta guía conserva la arquitectura y los límites comprobados; los resultados se resumen en [docs/VALIDATION.md](docs/VALIDATION.md).

## Objetivo y alcance

Lector y editor Markdown nativo para macOS, con lectura cómoda, edición predecible, navegación por teclado y varias ventanas. La beta no declara estabilidad 1.0 ni distribución pública de instaladores.

## Arquitectura

- Proyecto y esquema: `MarkD.xcodeproj`, MarkD. Mínimo declarado macOS 26.4; la ejecución allí sigue pendiente. Beta actual compilada con Xcode 27/SDK macOS 27.
- SwiftUI y AppKit, sin dependencias externas, WebView ni servicios de red.
- `FileDocument` y `DocumentGroup` gestionan lectura, guardado, autosave, conflictos y ventanas. La migración a otra API de documentos permanece aplazada.
- UTF-8 estricto, conservando BOM, Unicode y saltos de línea. Bytes inválidos producen error; no hay reparación ni conversión automática de otras codificaciones.
- Parser/esquema ignoran solamente el BOM inicial en su copia de análisis. El editor y los bytes guardados lo conservan.
- Un `NSTextView` permanece vivo entre Editar, Vista previa y RAW. Conservar selección, foco, posición y Undo. RAW permite seleccionar, copiar y buscar, sin edición.
- `NavigationSplitView` muestra esquema de encabezados y contenido. Navegación del editor por offsets UTF-16, incluidos LF/CRLF/CR y Unicode compuesto.
- Vista previa usa `LazyVStack` y prepara parser/esquema fuera del hilo de UI. Las tareas canceladas no publican snapshots antiguos; el parser comprueba cancelación entre líneas.
- `MarkdownSource` distingue bytes UTF-8 exactos. Cachés acotadas por instancia; cambiar resultado activo, foco o tema no debe repetir el parser.
- Buscar en Vista previa materializa bloques distantes antes de obtener la geometría de `Text.LayoutKey`. Conservar selección, enlaces y accesibilidad; no sustituir la coincidencia precisa por centrado del bloque.
- La búsqueda Unicode cubre el carácter visible completo y evita duplicados dentro de caracteres compuestos.
- Una solicitud de navegación durante carga espera a los bloques. La navegación del esquema consulta Reducir movimiento; la prueba con la preferencia global activa sigue pendiente.
- Buscar en Editar/RAW se dirige al editor de la ventana activa incluso sin foco inicial y no actúa sobre documentos con una hoja modal.
- Temas y apariencia de ventana se propagan a todas las escenas. No aplicar la configuración de toolbar de documentos a Ajustes.
- Selector de modos: pestañas nativas en macOS 27 con compilador compatible; alternativa segmentada anterior. Conservar las guardas de compilador/disponibilidad.
- Por debajo de 780 puntos, usar el menú compacto rotulado. La ventana de documento tiene mínimo de 560 × 360 puntos; conservar la restricción de tamaño y comprobarla antes de modificarla.
- Bienvenida: nuevo documento, abrir, guía localizada y recientes nativos. No duplicar documentos ya abiertos.

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
| `Tests/` | Regresiones funcionales y sondas UI |

## Compilar y probar

Desde la raíz:

```bash
./Abrir\ MarkD.command
./script/test_all.sh
```

El iniciador no cierra una app ya abierta. `script/build_and_run.sh` es la entrada de recompilación: solicita cierre normal y espera la resolución de documentos sin guardar; no fuerza el cierre.

El runner conserva logs y códigos reales por suite, continúa después de fallos y termina con salida no cero si alguna suite falla. La ruta opcional a un bundle añade metadatos. Benchmarks y pruebas UI se ejecutan por separado.

```bash
./script/benchmark_large_document.sh
./script/benchmark_preview_search.sh
./script/test_bundle_metadata.sh /ruta/a/MarkD.app
```

Los scripts seleccionan Xcode en Aplicaciones y admiten `DEVELOPER_DIR`. Las pruebas UI necesitan permisos de Accesibilidad y una app de QA aislada; no usar documentos privados ni terminar procesos de uso personal.

## Paquetes locales

`script/package_dmg.sh` compila Release, exige SDK 27 o posterior, verifica metadatos/icono/firma e integridad y no sobrescribe DMG existentes. Acepta otra ruta de salida libre como primer argumento.

Cada entrega que modifique la app o corrija errores debe incrementar beta/build y entregar un DMG local validado, conservando los anteriores. Una edición documental no requiere otra beta. Este flujo no autoriza instalación automática, cambios adicionales de firma/entitlements ni publicación de instaladores.

## Límites abiertos

- **Pérdida de edición anterior al guardado/autosave:** comprobada al terminar el proceso antes de persistir los bytes. Guardar con ⌘S y comprobar que termine para un cambio importante. No prometer recuperación de cada pulsación.
- Escrituras externas directas pueden mantener la vista antigua hasta resolver el conflicto nativo. Las pruebas de escritura coordinada no prueban sincronización en vivo con todos los editores.
- Falta completar matriz visual de seis temas, tres modos, tamaños y cuatro idiomas.
- Archivos reales de uso, bloques únicos/listas enormes, edición sostenida y memoria/Leaks necesitan más cobertura.
- VoiceOver hablado, Reducir movimiento activo, macOS 26.4 e instalación/actualización real siguen pendientes.
- Tablas, imágenes, tareas, notas al pie, filtrado del esquema y tema automático son propuestas; no figuran como implementados.
- iPhone/iPad y distribución pública de binarios quedan fuera del alcance de estabilización actual.

## Roadmap por criterios

| Etapa | Criterio |
| --- | --- |
| Beta 9 — entregada | Renderizado bajo demanda y análisis asíncrono; regresiones, QA sintética y DMG local aprobados |
| Beta 10 — propuesta | Archivos reales, accesibilidad activa, matriz visual, compatibilidad e instalación; ampliar perfil de memoria si hace falta |
| RC1 | Congelar funciones y usar durante 7–14 días; sin bugs críticos ni pérdida de contenido cuyo guardado/autosave había terminado |
| 1.0 local | Cumplir los criterios y aceptar la candidata; no implica por sí mismo un instalador público notarizado |

Antes de RC1 debe evaluarse una mitigación o aceptar expresamente el límite anterior al autosave. El roadmap no garantiza número de betas/fechas ni autoriza nuevas funcionalidades.

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

## Preparación de publicación — 2026-10-12

Se aprobó la documentación de esta copia y la creación de un historial Git local separado, con MIT, Andrés Vargas y correo privado de GitHub. El historial del repositorio de trabajo anterior se conserva por separado; no se importa a esta copia. El código, pruebas, scripts y recursos de Beta 9 permanecen idénticos.

Esta preparación no publica código ni instaladores y no configura un remoto. Antes de publicar, verificar el estado final con Gitleaks, TruffleHog y las reglas locales de Semgrep, incluidos los commits nuevos; conservar los hooks existentes. La cobertura genérica de Semgrep no sustituye una revisión específica de Swift.

El siguiente paso de publicación requiere decidir destino/nombre y autorizar su creación o cambio de visibilidad. Beta 10 continúa como propuesta para completar pruebas reales, accesibilidad, compatibilidad e instalación; el límite anterior al autosave sigue abierto. No corresponde otro DMG por esta preparación documental.
