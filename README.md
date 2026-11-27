# MarkD

Un espacio para tus palabras. MarkD es un lector y editor Markdown nativo para macOS, construido con SwiftUI y AppKit.

**Estado: 0.2.0, piloto de distribución.** Proyecto en desarrollo. Los DMG del piloto usan firma de desarrollo y carecen de notarización de Apple.

![Markdown con formato en Vista previa](docs/screenshots/preview.jpg)

## Qué puedes hacer

- Escribir en Editar, leer con formato en Vista previa y consultar la fuente en RAW, de solo lectura.
- Recorrer los encabezados desde el esquema lateral.
- Buscar con resaltado, contador y navegación entre coincidencias.
- Usar varias ventanas y el guardado, Undo y Redo nativos de macOS.
- Elegir entre seis temas: Light, Dark, Sepia, Solarized Light, Solarized Dark y Dracula.
- Usar la app en español, inglés, catalán o japonés, o seguir el idioma del sistema.
- Crear documentos, abrir archivos y consultar la guía Markdown desde la bienvenida.

![Edición del documento de ejemplo](docs/screenshots/editor.jpg)

Las capturas corresponden a Beta 9 y usan un documento sintético.

## Markdown y archivos

Abre archivos `.md`, `.markdown` y texto plano. Lee y guarda UTF-8 preservando el BOM, Unicode y saltos de línea; rechaza bytes inválidos sin repararlos silenciosamente. No convierte automáticamente otras codificaciones.

La Vista previa admite encabezados ATX y Setext, párrafos, citas, listas básicas, divisores, bloques de código y formato inline. Tablas, imágenes, listas de tareas y notas al pie todavía no están implementadas; no se declara compatibilidad completa con CommonMark o GFM.

El editor y la Vista previa usan componentes nativos, sin WebView ni servicios de red. Beta 10 añadió filas de listas bajo demanda; Beta 11 corrigió el contraste de selección sin foco en Editar/RAW. En Beta 12, Abrir desde la bienvenida usa el flujo nativo de documentos para conservar el acceso necesario al guardar y preservar versiones.

Beta 13 activa el autoguardado periódico nativo con mínimo de un segundo después del arranque. La comparación sintética observó una mediana de 15,037 s en el control y 1,058 s con la configuración corta. El tiempo depende del documento y del sistema, y pueden perderse ediciones aún no persistidas.

## Requisitos

- macOS 26.4 o posterior como mínimo declarado por el proyecto.
- Xcode 27 con SDK macOS 27 para compilar la beta actual.

La QA de Beta 14 se ejecutó en macOS 27.3 con Xcode 27.2 y SDK macOS 27.2 sobre Apple Silicon. **La ejecución en macOS 26.4 no está validada** y queda aplazada por falta de un entorno de prueba. El mínimo declarado se conserva; la estabilización local se evalúa en el entorno disponible.

## Compilar y abrir

Abre `MarkD.xcodeproj` en Xcode, selecciona el esquema MarkD y ejecuta sobre tu Mac.

También puedes hacer doble clic en `Abrir MarkD.command` o ejecutar desde la raíz:

```bash
./Abrir\ MarkD.command
```

La primera ejecución compila y abre la app. Si MarkD ya está abierta, el iniciador la lleva al frente para conservar los documentos abiertos.

Para recompilar desde la entrada de desarrollo:

```bash
./script/build_and_run.sh
```

Esta entrada solicita el cierre normal de MarkD antes de recompilar y cancela la operación si la app sigue esperando que guardes un documento.

## Atajos

| Acción | Atajo |
| --- | --- |
| Editar / Vista previa / RAW | ⌘1 / ⌘2 / ⌘3 |
| Buscar | ⌘F |
| Siguiente / anterior coincidencia | ⌘G / ⇧⌘G |
| Guardar | ⌘S |

## Límites de la beta

- **Una edición puede perderse si la app termina antes de completar un guardado o autosave.** Para persistir un cambio importante, usa ⌘S y comprueba que termine. La recuperación posterior al autosave pasó las pruebas; no se garantiza recuperar cada pulsación.
- Una escritura externa directa puede dejar visible el texto anterior hasta resolver el conflicto nativo al guardar.
- Párrafos y bloques de código individuales enormes aún pueden causar pausas. Hace falta ampliar la cobertura de edición sostenida y memoria/Leaks.
- La apertura y el guardado pasaron con documentos sintéticos en Beta 14 instalada. Queda ampliar la prueba a uso diario y otros volúmenes. Al actualizar entre compilaciones con firma local pueden desaparecer las entradas de Recientes. Abrir los archivos de nuevo repuebla la lista.
- Se comprobó el selector compacto de Beta 14 en los seis temas. VoiceOver hablado y el cruce completo de Beta 14 con los idiomas siguen pendientes. La navegación al encabezado final con Reducir movimiento activo se comprobó en Beta 10; esa prueba no cierra toda la validación de accesibilidad.

Resultados, fechas y límites: [Validación](docs/VALIDATION.md). Próximas etapas: [guía del proyecto](PROJECT_GUIDE.md).

## Pruebas

```bash
./script/test_all.sh
```

Ejecuta once suites y conserva resultados por suite. Para añadir la comprobación de metadatos de un bundle:

```bash
./script/test_all.sh /ruta/a/MarkD.app
```

Los benchmarks y recorridos UI se ejecutan por separado. La [regresión de apertura y guardado](Tests/DocumentOpeningRegression.md) describe los recorridos asistidos de guardado y recuperación y no forma parte del total automático.

## Empaquetado local

Para este paso necesitas `uv` disponible. Prepara las herramientas aisladas desde la raíz:

```bash
uv venv .build/dmg-tools
uv pip install --python .build/dmg-tools/bin/python --require-hashes -r script/dmg/requirements.txt
./script/package_dmg.sh
```

Genera `dist/MarkD-0.2.0-Beta-14-Installer.dmg`, con MarkD a la izquierda y Aplicaciones a la derecha. Valida la app y la imagen, y rechaza sobrescribir un archivo existente. Admite otra ruta de salida libre como primer argumento.

Las herramientas del instalador tienen versiones y hashes fijados; no se incorporan a la app. Los paquetes usan firma local para pruebas y no son una distribución pública notarizada. Compilaciones y DMG se excluyen de Git.

## Colaborar

Antes de cambiar el proyecto, lee [PROJECT_GUIDE.md](PROJECT_GUIDE.md) y las [instrucciones para agentes](AGENTS.md).

Al reportar un error, incluye la versión de MarkD y macOS, los pasos para reproducirlo y el resultado esperado. Usa un ejemplo mínimo sin documentos privados ni credenciales. Si aparece un error de guardado, conserva el texto mediante Guardar como en una copia separada antes de cerrar.

## Licencia y autor

Licencia [MIT](LICENSE). Autor: **Andrés Vargas**, [JAndresVC](https://github.com/JAndresVC).
