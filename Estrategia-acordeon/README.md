# Estrategia acordeón

Investigaciones hechas con la estrategia «acordeón»: se **abre** con una búsqueda amplia, se
**clasifica** lo encontrado por el punto donde actúa, se **profundiza** categoría a categoría
verificando cada fuente, y se **fusiona** en una sola recomendación con las contradicciones
resueltas. Cada afirmación lleva su etiqueta de evidencia: [H] hecho documentado, [C] afirmación
de comunidad o proveedor, [O] opinión, [PV] pendiente de verificar.

← [Volver al índice](../README.md)

| Documento | Pregunta que responde | Fecha |
|---|---|---|
| [roadmap.md](roadmap.md) | ¿Cómo se optimizan los tokens en generación de código y en soluciones agénticas, en general? 38 estrategias en 8 categorías, matriz de priorización, fases y checklist | 2026-09-24 |
| [repos-gigantes/](repos-gigantes/README.md) | ¿Qué skills, plugins y estrategias sirven para trabajar con repositorios de **millones de líneas** como los de los clientes? | 2026-09-24 |

## Repositorios gigantes, en una pantalla

| Documento | Para qué abrirlo |
|---|---|
| [repos-gigantes/README.md](repos-gigantes/README.md) | Resumen, matriz de priorización, adopción por fases en un cliente, contradicciones (vendor frente a evidencia independiente) y fuentes |
| [repos-gigantes/catalogo.md](repos-gigantes/catalogo.md) | Fichas de ~45 recursos en 12 categorías: configuración nativa, subagentes, LSP, grafos, índices semánticos, codemods, mapas, docs de dependencias, filtrado, memoria, medición y colecciones |
| [repos-gigantes/privacidad-y-licencias.md](repos-gigantes/privacidad-y-licencias.md) | Semáforo: qué herramientas sacan código de la máquina y qué licencias bloquean el uso con clientes |
| [repos-gigantes/plantillas/](repos-gigantes/plantillas/README.md) | Configuración lista para copiar: `settings.json`, hook de filtrado de tests, subagente `explorador`, skill `explorar-repo-gigante`, `CLAUDE.md` y `MAPA.md` |

**Si solo lees una cosa:** lo que más ahorra en un repositorio gigante es la configuración
nativa de Claude Code: arrancar en el subsistema, CLAUDE.md por capas, `permissions.deny`,
explorar con un subagente y los límites de salida. Es gratis, local y está documentada. Las
cifras de «−90 %» de las herramientas externas son, casi siempre, del propio proveedor. Donde
hay medidas independientes en factura, el ahorro es mucho menor o nulo.
