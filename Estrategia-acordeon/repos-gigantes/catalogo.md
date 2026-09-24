# Catálogo: skills, plugins y ajustes para repositorios gigantes

Fichas de la fase de profundización, ordenadas por la categoría de la
[taxonomía](README.md#3-taxonomía). En cada ficha: qué hace, cómo se instala, **cuánto ahorra y
según quién**, cuándo no usarlo y si el código sale de la máquina. Enlaces comprobados el
2026-09-24: las páginas de npmjs.com devuelven 403 a clientes automáticos, así que esos paquetes
se verificaron en `registry.npmjs.org` (200). Las estrellas son aproximadas y solo sirven como
señal de popularidad.

Cuando un proyecto vive bajo una cuenta personal de GitHub, se enlaza su web o su paquete en el
registro (npm, PyPI, crates.io) si existe. Cada recurso se nombra por su proyecto.

← [Volver al bloque](README.md)

**Índice:**
[A. Acotar lo que se carga](#a) ·
[B. Exploración aislada](#b) ·
[C. Navegación precisa](#c) ·
[D. Grafos](#d) ·
[E. Índices semánticos](#e) ·
[F. Búsqueda estructural y codemods](#f) ·
[G. Mapas, empaquetado y wikis](#g) ·
[H. Docs de dependencias](#h) ·
[I. Filtrado de salida](#i) ·
[J. Memoria](#j) ·
[K. Medición](#k) ·
[L. Colecciones](#l) ·
[Descartes](#descartes)

---

<a id="a"></a>
## A. Acotar lo que se carga (configuración nativa)

Todo lo de esta categoría es de Claude Code, está documentado para monorepos y repositorios de
millones de líneas en https://code.claude.com/docs/en/large-codebases, cuesta cero y es local [H].
Las plantillas listas para copiar están en [plantillas/](plantillas/README.md).

| Ajuste | Qué resuelve | Dónde va | Nota clave |
|---|---|---|---|
| **Arrancar en el subsistema** | Carga su CLAUDE.md y los de sus ancestros, no los de los hermanos | — | Desde la raíz, los CLAUDE.md de cada subdirectorio se cargan al leer en él |
| **CLAUDE.md por capas** | Reglas globales en la raíz; convenciones de cada área en su carpeta | Versionado | Raíz con «punteros, no enciclopedias», menos de 200 líneas [H] |
| **Mapa de carpetas** (`MAPA.md`) | Una línea por carpeta de primer nivel para orientarse sin listar el árbol | Raíz, versionado | Recomendación del blog de Anthropic para repos con cientos de carpetas [H] |
| **`claudeMdExcludes`** | No cargar nunca los CLAUDE.md y reglas de paquetes ajenos | `settings.local.json` o proyecto | Globs sobre rutas absolutas: empezar por `**/`. Las listas se fusionan entre ámbitos |
| **`permissions.deny` con `Read(...)`** | Bloquear lecturas de vendor, generado, build | `.claude/settings.json` | Terminar en `/**/*` para que el directorio siga siendo listable. Best-effort en Grep/Glob; **no** cubre `grep -r` ni `find` en Bash [H] |
| **`.claude/rules/` con `paths:`** | Reglas centralizadas que solo se cargan al tocar ficheros que casan | Raíz | Alternativa a los CLAUDE.md por carpeta cuando se quiere todo en un sitio |
| **Skills por directorio** y campo `paths` | Procedimientos que solo se cargan en su área | `<área>/.claude/skills/` | Ver «Gobierno del listado» abajo |
| **`--add-dir` / `additionalDirectories`** | Acceso a un paquete hermano | Flag o settings | `additionalDirectories` da acceso a ficheros pero **no** carga ni CLAUDE.md ni skills; `--add-dir` carga skills, y CLAUDE.md solo con `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` |
| **`worktree.sparsePaths`** + `symlinkDirectories` | Worktrees (y subagentes en worktree) con solo los directorios necesarios | `.claude/settings.json` | Incluir `.claude` en la lista; enlazar `node_modules` en vez de duplicarlo |
| **Plugin interno + hook `SessionStart`** | Convenciones versionadas por un equipo de plataforma; el hook recomienda el plugin del área | Marketplace interno | El texto que imprime un `SessionStart` entra en el contexto [H] |

**Gobierno del listado de skills** (https://code.claude.com/docs/en/skills) [H]:

- El listado de skills tiene un presupuesto del **1 % de la ventana** del modelo. Cada skill
  admite como máximo 1.536 caracteres entre `description` y `when_to_use`.
- Si el listado no cabe, se quitan descripciones empezando por las skills menos invocadas: la
  skill sigue existiendo, pero deja de activarse sola.
- Palancas: `skillOverrides` (`name-only`, `off`, `user-invocable-only`), y
  `disable-model-invocation: true`, con la que la skill no ocupa contexto hasta que se invoca.
- Diagnóstico con `/doctor` y `/skill-doctor`.
- Regla práctica: la descripción empieza por las palabras que traería la petición, por ejemplo
  «writing or modifying tests in `packages/api/`».

**Equivalentes en otros agentes** [H]:

| Agente | Mecanismo | Trampa |
|---|---|---|
| Codex | `AGENTS.md` anidados, del git root al directorio actual; `project_doc_fallback_filenames` para leer también CLAUDE.md | `project_doc_max_bytes` = 32 KiB por defecto: los ficheros más profundos se **descartan en silencio** al llegar al límite |
| Cursor | Índice local («Instant Grep», sin subir código ni guardar embeddings), subagente Explore propio, `.cursorignore` | Los tools de terminal y MCP se saltan `.cursorignore`; `.cursorindexingignore` ya no aparece en la documentación |
| GitHub Copilot | `.github/instructions/*.instructions.md` con `applyTo`; `AGENTS.md` anidados | Las instrucciones por ruta solo funcionan en el agente cloud y en la revisión de GitHub.com |

---

<a id="b"></a>
## B. Exploración aislada

| Recurso | Tipo | Licencia | ¿Sale código? | Enlace |
|---|---|---|---|---|
| Subagente Explore (y Plan) | Nativo | — | No | https://code.claude.com/docs/en/sub-agents |
| Subagente propio con modelo pequeño | Nativo | — | No | [plantilla](plantillas/claude/agents/explorador.md) |
| `feature-dev` | Plugin oficial | Apache-2.0 | No | https://github.com/anthropics/claude-plugins-official |
| `code-review` | Plugin oficial | Apache-2.0 | No | https://github.com/anthropics/claude-plugins-official |

**Subagente Explore** [H]
- Solo lectura, con niveles quick, medium y very thorough. Mantiene los resultados de la
  exploración fuera del contexto principal: solo vuelve el resumen.
- No carga CLAUDE.md ni la instantánea de git status, así que no ve las convenciones del
  repositorio.
- **Cuándo sí:** mapear un subsistema, búsquedas amplias.
- **Cuándo no:** una consulta puntual en un fichero conocido, porque el arranque del subagente
  cuesta más de lo que ahorra.
- Patrón del blog de Anthropic: el subagente escribe lo que encuentra en un fichero y el agente
  principal edita.

**Subagente propio con `model: haiku`** [H/O]
- Igual que Explore, pero con **contrato de salida**: número de líneas, formato
  `ruta:línea — qué hace` y prohibición de pegar ficheros.
- El modelo pequeño abarata la lectura masiva; el riesgo es un resumen erróneo que contamine al
  principal.
- Para el subagente general-purpose se puede fijar el modelo con `CLAUDE_CODE_SUBAGENT_MODEL`.

**`feature-dev`** [H]
- Flujo de 7 fases. En la fase 2 lanza **2–3 agentes `code-explorer` en paralelo** (solo
  lectura) que trazan rutas de ejecución; después actúan `code-architect` y `code-reviewer`.
- Instalación: `/plugin install feature-dev@claude-plugins-official`.
- **Efecto:** limpia el contexto principal, pero **sube el total** de tokens [O]. Para
  funcionalidades nuevas en zonas desconocidas; no para cambios pequeños.

**`code-review`** [H]
- Cuatro agentes en paralelo: dos comprueban el cumplimiento de CLAUDE.md, uno busca bugs y otro
  revisa `git blame`.
- Puntúa cada hallazgo de 0 a 100 y descarta los que quedan por debajo de 80.
- Instalación: `/plugin install code-review@claude-plugins-official`.
- Mismo compromiso que `feature-dev`: más calidad, más total.

---

<a id="c"></a>
## C. Navegación precisa (LSP / SCIP)

| Recurso | Tipo | Licencia | ¿Sale código? | Enlace |
|---|---|---|---|---|
| Plugins LSP oficiales | Plugin | Apache-2.0 | No | https://code.claude.com/docs/en/discover-plugins |
| Serena | Servidor MCP | GPL-3.0+ (app) / MIT (SolidLSP) | No | https://github.com/oraios/serena |
| Sourcegraph MCP | MCP remoto (HTTP) | Comercial (Enterprise) | Sí con Sourcegraph Cloud · No si está autoalojado | https://sourcegraph.com/docs/api/mcp |
| SCIP | Formato de índice | Apache-2.0 | No | https://github.com/sourcegraph/scip |
| cclsp | Puente MCP ↔ LSP | MIT | No | https://www.npmjs.com/package/cclsp |

**Plugins LSP oficiales**
- Activan la herramienta LSP de Claude Code: diagnósticos automáticos tras cada edición,
  definición, referencias, hover, símbolos, implementaciones y jerarquía de llamadas.
- Instalación: `/plugin install <plugin>@claude-plugins-official`. El plugin **no** instala el
  binario, que tiene que estar en el `PATH`:

  | Plugin | Binario |
  |---|---|
  | `typescript-lsp` | `typescript-language-server` |
  | `pyright-lsp` | `pyright-langserver` |
  | `gopls-lsp` | `gopls` |
  | `jdtls-lsp` | `jdtls` |
  | `csharp-lsp` | `csharp-ls` |
  | `clangd-lsp` | `clangd` |
  | `rust-analyzer-lsp` | `rust-analyzer` |
  | `kotlin-lsp` | `kotlin-language-server` |
  | `php-lsp` | `intelephense` |
  | `swift-lsp` | `sourcekit-lsp` |
  | `lua-lsp` | `lua-language-server` |
  | `ruby-lsp` | gema `ruby-lsp` (Ruby ≥ 3.0) |

  `ruby-lsp` está en el marketplace aunque no aparece en la tabla de la documentación.
- **Ahorro:**
  - La documentación promete precisión y menos ciclos de compilar y lintar, sin cifra de
    tokens [H].
  - El paper arXiv 2608.13568 (3 repos pequeños, 2–3 ejecuciones) mide:
    - al **localizar**, **más** tokens con modelos fuertes: +6 % Opus, +118 % Sonnet, −26 % Haiku;
    - al buscar **todas las referencias**, más precisión (1,00 frente a 0,76) a +12–19 % de tokens;
    - en **renombrados**, grep solo pasa el 100 % de los tests y LSP solo con ubicaciones, el 67 %.

    Lo que predice el beneficio es lo ruidoso que sea `grep` [H, muestra pequeña].
- **Cuándo sí:** lenguajes tipados con el workspace bien configurado; diagnósticos tras editar;
  completitud de referencias cuando hay nombres repetidos.
- **Cuándo no:**
  - Monorepos donde el servidor no indexa bien: la documentación avisa de la memoria de
    `rust-analyzer` y `pyright` y de falsos «import no resuelto».
  - Sesiones cloud, que no arrancan servidores de lenguaje.
- **Windows:** comprobar el `PATH`; `jdtls` y `sourcekit-lsp` son los más costosos de montar [O].

**Serena**
- Recuperación y edición a nivel de símbolo sobre LSP (40+ lenguajes), o sobre un plugin de
  JetBrains de pago. Trae un panel local con una estimación de tokens.
- Unas 30k estrellas, v1.7.0 (2026-08-09).
- Instalación: `uv tool install -p 3.13 serena-agent` y después `serena setup claude-code`.
- **Ahorro:** sin benchmark publicado [C/PV]. El paper anterior no probó Serena.
- **Riesgos:**
  - Su propia documentación admite que Claude Code «sigue poco» sus herramientas y recomienda
    sustituir el system prompt y añadir hooks, lo que es frágil.
  - Sus herramientas ocupan contexto en cada turno y se solapan con los plugins LSP nativos.
  - La licencia GPL importa si el cliente quiere empaquetarlo o modificarlo.
- **Cuándo sí:** lenguajes que no cubren los plugins oficiales, o para ediciones atómicas por
  símbolo.

**Sourcegraph MCP**
- Búsqueda por palabra clave y en lenguaje natural, `read_file`, `go_to_definition`,
  `find_references`, búsqueda en commits y diffs, `code_finder` y `deepsearch`, **entre
  repositorios**.
- Solo en planes Enterprise.
- Instalación: `claude mcp add --transport http sourcegraph https://<instancia>/.api/mcp`.
- **Ahorro:**
  - Su benchmark (CodeScaleBench, del propio proveedor: 371 tareas, 40+ repos, Haiku 4.5) da una
    recompensa media de 0,536 sin MCP y 0,565 con él (+0,029).
  - En tareas multi-repo, la recuperación pasa de 0,007 a 0,471 [H, proveedor].
  - El «30 % de ahorro de tokens» de su web no tiene desglose [C].
- **Cuándo sí:** clientes con muchos repositorios y **Sourcegraph autoalojado**.
- **Cuándo no:** un único repositorio que ya está clonado en local.

**SCIP** — Índices precalculados de definiciones y referencias. No tiene integración directa
con agentes; solo tiene sentido a través de Sourcegraph o de un MCP propio que haya que mantener [O].

**cclsp** — Puente MCP ↔ LSP (definiciones, referencias, `rename_symbol`, diagnósticos). Es
**redundante en Claude Code**; úsalo solo en agentes sin LSP nativo [O].

---

<a id="d"></a>
## D. Grafos de conocimiento del código

| Recurso | Tipo | Licencia | ¿Sale código? | Enlace |
|---|---|---|---|---|
| codebase-memory-mcp | Servidor MCP (binario único) | MIT | No | https://github.com/DeusData/codebase-memory-mcp |
| CodeGraphContext | MCP + CLI | MIT | No (backends embebidos) | https://github.com/CodeGraphContext/CodeGraphContext |
| code-review-graph | MCP + CLI | MIT | No (embeddings cloud opcionales) | https://code-review-graph.com/ |
| GitNexus | MCP + skills + hooks | **PolyForm Noncommercial 1.0.0** | No | https://www.npmjs.com/package/gitnexus |

**codebase-memory-mcp** — la opción a pilotar primero.
- Parsea el repositorio con tree-sitter y construye un grafo persistente de funciones, llamadas,
  imports y herencia. Las versiones recientes añaden resolución de tipos vía LSP para ~11
  lenguajes.
- Unas 45k estrellas, v0.11.0 (2026-09-15). Se distribuye por npm, PyPI, Scoop, Winget y
  Chocolatey.
- **Ahorro:**
  - Paper arXiv 2603.27277 [H]: 31 repositorios (uno por lenguaje), 12 categorías de pregunta,
    Opus 4.6 en ambos brazos.
    - Calidad 0,83 frente a 0,92 de un agente que explora ficheros.
    - ~1.000 frente a ~10.000 tokens por pregunta.
    - 2,3 frente a 4,8 llamadas.
    - Iguala o gana en 19 de 31 lenguajes.
    - Límites: corrección sin ciego hecha por el propio autor; en C la calidad cae a 0,58 porque
      las macros no tienen AST.
  - El «120×» del README es autoevaluación [C].
- **Escala:**
  - El repositorio más grande evaluado en calidad es Django (~49k nodos).
  - El kernel de Linux (28M de líneas) se indexó en ~3 min, pero sus respuestas no se evaluaron [H].
  - Hay fallos abiertos: RAM sin límite en monorepos grandes de TypeScript y 8 fallos de Windows,
    uno de ellos un **fallo silencioso de indexado**. La v0.11 dice reducir la memoria pico un
    40–80 % [C].
- **Cuándo sí:** preguntas estructurales (quién llama a X, radio de impacto, arquitectura).
- **Cuándo no:** C con muchas macros, o cuando se necesita exactitud (la línea base tiene 9
  puntos más de calidad).
- **Riesgo:** índice caducado si falla el vigilante de ficheros. Fijar la v0.11 o posterior y
  validar en Windows antes de desplegar.

**CodeGraphContext**
- Grafo de 23 lenguajes con backend embebido (FalkorDB Lite, KuzuDB, LadybugDB) o Neo4j para
  grafos muy grandes. v0.5.1.
- Instalación: `pip install codegraphcontext` y después `cgc mcp setup` (asistente); `cgc watch`
  para actualizar en vivo.
- **Ahorro:** ~62 % menos tokens en las respuestas de sus herramientas gracias a su formato
  compacto [C].
- **Cuándo sí:** si se quieren consultas Cypher propias o el cliente ya tiene Neo4j.

**code-review-graph**
- Grafo tree-sitter en SQLite que calcula el conjunto mínimo de ficheros que hay que leer para
  una revisión o una tarea.
- Instalación: `pip install code-review-graph && code-review-graph install --platform claude-code`.
- **Ahorro:** «6,8× en revisiones, hasta 49× en tareas diarias» [C], pero comparado con meter el
  repositorio entero, no con un agente que usa `grep` [O].
- El mayor repositorio probado es FastAPI.
- Hay copias del repositorio bajo otras cuentas: usar la que enlazan su web o PyPI.

**GitNexus**
- Grafo con herramientas como `detect_changes` (riesgo antes del commit), `rename` coordinado y
  mapas Mermaid. Sus hooks añaden contexto del grafo a `grep` y `glob`.
- **Bloqueante:** su licencia no comercial impide usarlo en trabajo para clientes sin licencia
  comercial.
- Sin cifras de ahorro publicadas [PV].

---

<a id="e"></a>
## E. Índices semánticos (vectoriales)

| Recurso | Tipo | Licencia | ¿Sale código? | Enlace |
|---|---|---|---|---|
| Claude Context | Servidor MCP | MIT | **Sí por defecto** (OpenAI + Zilliz Cloud) · No con Ollama + Milvus propio | https://github.com/zilliztech/claude-context |
| CocoIndex Code | Skill + MCP + CLI | Apache-2.0 | No por defecto | https://cocoindex.io/cocoindex-code |
| Semble | CLI + MCP | MIT | No | https://github.com/minishlab/semble |
| Augment Context Engine MCP | SaaS + MCP | Comercial | **Sí** (nube de Augment, sin opción on-prem) | https://www.augmentcode.com/product/context-engine-mcp |
| Greptile | SaaS / autoalojable | Comercial | Sí en SaaS · No autoalojado | https://www.greptile.com/docs/mcp-v2/overview |

**Claude Context**
- Búsqueda híbrida (BM25 + vectores) sobre fragmentos cortados por AST, con reindexado
  incremental por árbol de Merkle. Unas 12,6k estrellas.
- **Ahorro:** evaluación del propio proveedor: 30 tareas de SWE-bench Verified con GPT-4o-mini.
  Los tokens bajan de 73,4k a 44,4k (**−39,4 %**) y las llamadas de 8,3 a 5,3, con la misma F1 de
  recuperación [C, autoevaluación].
- Coste de indexado: del orden de céntimos por cada 50k líneas con un modelo de embeddings
  pequeño [C]. No hay tiempo de indexado publicado por encima de 1M de líneas [PV].
- **Para clientes:** usar **solo** con Ollama y Milvus autoalojado.

**CocoIndex Code**
- Fragmentos semánticos por AST, con un motor incremental en Rust que solo recalcula los
  fragmentos cambiados. `ccc grep` busca por estructura sin índice.
- El modelo de embeddings por defecto es local. El almacén LMDB tiene 4 GiB por defecto,
  ampliable.
- Instalación: `npx skills add cocoindex-io/cocoindex-code`, o `pipx install 'cocoindex-code[full]'`
  seguido de `claude mcp add cocoindex-code -- ccc mcp`.
- **Ahorro:** «70 %» sin metodología publicada [C].
- Diseñado para «decenas de miles de ficheros». Sin prueba a 1M de líneas; soporte de Windows no
  documentado [PV].

**Semble**
- Embeddings pequeños y BM25 en CPU, sin API ni GPU. NDCG@10 de 0,854 en ~1.250 consultas sobre
  63 repositorios [H/C].
- El «99 % menos tokens que grep + read» se calcula restando tamaños de fichero, no con tareas
  reales [C].
- El índice vive solo durante la sesión, así que se reindexa cada vez: arriesgado a 1M+ líneas [O].

**Augment Context Engine MCP**
- Motor propietario de contexto expuesto a Claude Code, Cursor y Codex; disponible en general
  desde el 2026-02-06.
- **Ahorro:** su evaluación en 300 PR de Elasticsearch habla de calidad (+70–80 %), sin
  porcentaje de tokens [C/PV].
- Guarda código y embeddings en su nube. Solo si el cliente lo acepta por contrato (DPA).

**Greptile**
- Su MCP oficial trata de datos de revisión (comentarios de PR, reglas), no de recuperar
  contexto: **no es la herramienta para ahorrar tokens** en Claude Code.
- Útil si el cliente quiere revisión de PR con IA; admite despliegue autoalojado, incluso sin
  conexión a Internet.

**Grafo frente a vector** [O]:
- El grafo responde con exactitud a preguntas estructurales, indexa rápido, no necesita
  embeddings y es local por naturaleza; falla con macros, despacho dinámico y preguntas en
  lenguaje de negocio.
- El vector encuentra por significado y resiste a los nombres, pero cuesta embeddings, puede
  sacar código a una API y devuelve fragmentos plausibles pero equivocados.
- Por defecto, grafo y búsqueda léxica; el vector, donde las preguntas sean de negocio.
- Para comparar herramientas en el repositorio del cliente, CORE-Bench (arXiv 2606.11864) sirve
  de método.

---

<a id="f"></a>
## F. Búsqueda estructural y codemods

| Recurso | Tipo | Licencia | ¿Sale código? | Enlace |
|---|---|---|---|---|
| ripgrep con disciplina (herramienta Grep) | Estrategia | MIT / Unlicense | No | https://crates.io/crates/ripgrep |
| ast-grep agent skill | Skill / plugin | MIT | No | https://github.com/ast-grep/agent-skill |
| ast-grep-mcp | Servidor MCP (experimental) | MIT | No | https://github.com/ast-grep/ast-grep-mcp |
| OpenRewrite + Moderne (MCP y skills) | CLI + MCP + skills | Apache-2.0 (núcleo) · Moderne CLI comercial en repos privados | No con el MCP local · Sí con Moderne Platform | https://github.com/openrewrite/rewrite · https://docs.moderne.io/user-documentation/agent-tools/mcp/overview/ |

**ripgrep con disciplina** [H/O]
- Primero `files_with_matches` o `count`, y después contenido con `head_limit`.
- Filtros `type` y `glob`, y ficheros `.ignore`/`.rgignore` para vendor y generado.
- Buscar identificadores exactos, no palabras. Leer rangos de líneas, no ficheros enteros.
- En el paper de LSP, `grep` fue igual de barato o más al localizar, y más seguro al editar
  (repos pequeños).

**ast-grep agent skill** — la recomendación de esta categoría.
- Dos skills:
  - `ast-grep` enseña a escribir reglas de patrón sobre el AST y a probarlas con código de
    ejemplo antes de recorrer el repositorio;
  - `outline` da un mapa estructural antes de leer ficheros.
- Instalación: `/plugin marketplace add ast-grep/agent-skill` y `/plugin install ast-grep`.
  Requiere el CLI `ast-grep`, que tiene binarios para Windows.
- **Ahorro:** sin cifra publicada [O]. Una consulta estructural sustituye a muchos resultados
  ruidosos de `grep`, y un `ast-grep --rewrite` sustituye a N ediciones fichero a fichero.
- **Cuándo no:** cambios que necesitan tipos, porque ast-grep solo ve sintaxis.
- **Preferir la skill al MCP:** la skill no añade definiciones de herramientas en cada turno.

**OpenRewrite (+ Moderne)** — para clientes JVM.
- El agente invoca o escribe **recetas** deterministas con información de tipos (subidas de
  framework o de JDK) en lugar de editar miles de ficheros a mano.
- Es plausiblemente el mayor ahorro posible en migraciones [O, sin benchmark].
- Presupuestar la licencia de Moderne CLI si el código es privado.

---

<a id="g"></a>
## G. Mapas, empaquetado y wikis

> **Nota crítica.** En un repositorio de millones de líneas, empaquetarlo entero no tiene
> sentido: aunque vaya comprimido, excede cualquier ventana y se reenvía en cada turno.
> Empaquetar solo sirve para:
> - un **subárbol** acotado (por debajo de ~50–100k tokens) para una pregunta puntual;
> - dárselo a un subagente o a otro modelo;
> - entregar una instantánea a un auditor [O].

| Recurso | Tipo | Licencia | ¿Sale código? | Enlace |
|---|---|---|---|---|
| Mapa de carpetas + CLAUDE.md por capas | Estrategia | — | No | [plantilla](plantillas/MAPA.md.plantilla) |
| Aider repo map | Función de Aider | Apache-2.0 | No (solo al LLM) | https://aider.chat/docs/repomap.html |
| Repomix | CLI + MCP + plugins | MIT | No (CLI) · **Sí** (web repomix.com) | https://repomix.com/ |
| code2prompt | CLI / TUI + SDK + MCP | MIT | No | https://crates.io/crates/code2prompt |
| yek | CLI | MIT | No | https://github.com/bodo-run/yek |
| deepwiki-open | App autoalojada (Docker) | MIT | No con Ollama | https://github.com/AsyncFuncAI/deepwiki-open |
| DeepWiki + MCP | SaaS + MCP remoto | — | **Sí**; privados solo con cuenta de Devin | https://docs.devin.ai/work-with-devin/deepwiki-mcp |
| Google Code Wiki | SaaS (preview) | — | Sí; privados en lista de espera | https://codewiki.google |

**Mapa de carpetas** [H]
- La recomendación de Anthropic para repositorios con cientos de carpetas de primer nivel: un
  markdown ligero en la raíz con una línea por carpeta.
- Es texto estático: **no rompe la caché** entre turnos. Hay que regenerarlo en CI para que no
  caduque.
- Sirve igual para Codex y Cursor vía `AGENTS.md` o reglas.

**Aider repo map** [H]
- Tree-sitter y ranking sobre el grafo de dependencias, dentro de un presupuesto (`--map-tokens`,
  1k por defecto).
- A millones de líneas solo muestra la parte mejor clasificada: acotar Aider a un subárbol [O].
- `--map-refresh auto|always` rompe el prefijo cacheado; en sesiones largas, `manual` o `files` [O].

**Repomix**
- Empaqueta en XML o MD con tokens por fichero. `--include "pkg/foo/**"` acota a un subárbol,
  `--compress` deja solo firmas y tipos, y Secretlint excluye ficheros con pinta de credencial.
- Las herramientas MCP `grep_repomix_output` y `read_repomix_output` permiten **leer el paquete
  por partes** en vez de cargarlo: ese es el patrón útil.
- v1.18.1 (2026-09-21).
- Instalación: `/plugin marketplace add yamadashy/repomix` y `/plugin install repomix-mcp@repomix`.
- **Ahorro:** «~70 %» con `--compress` [C]. Su propia guía lo llama experimental y no da cifras.
- **Cuándo no:** en la raíz, o para corregir bugs, porque quita los cuerpos de función. **Nunca
  la web** con código de cliente.

**code2prompt / yek** — Alternativas locales para prompts con plantilla sobre un diff (code2prompt)
o para cortes rápidos con tope de tokens ordenados por historial de git (yek, cuyo «230× más
rápido» es de velocidad, no de tokens [C]). El instalador de yek en Windows es un script remoto
en tubería: que lo revise seguridad.

**deepwiki-open**
- Wiki con diagramas por RAG, con soporte para Ollama y hospedaje propio: la vía compatible con
  RGPD para una wiki al estilo DeepWiki [H capacidad / O cumplimiento].
- Los modelos locales pequeños dan wikis de menos calidad, y el índice caduca en un monorepo
  activo. Úsalo mejor para **generar el `MAPA.md` estático** que como herramienta viva [O].
- No confundir con el servicio hospedado que ahora enlaza su página.

**DeepWiki / Code Wiki** — Solo para entender **dependencias open source públicas**. Con código
privado exigen sacarlo a su nube: no se usa con clientes por defecto.

---

<a id="h"></a>
## H. Documentación de dependencias

Evitan que el agente lea `node_modules` o código vendorizado para aprender una API.

| Recurso | Tipo | Licencia | ¿Sale código? | Enlace |
|---|---|---|---|---|
| Context7 | MCP + CLI + skill | MIT (cliente); backend privado | Las consultas van a su servicio; repos privados, subidos | https://github.com/upstash/context7 |
| Context | MCP local | Apache-2.0 | No | https://github.com/neuledge/context |
| GitMCP | MCP remoto / autoalojable | Apache-2.0 | Solo contenido público; autoalojar para uso interno | https://gitmcp.io |

**Context7**
- Fragmentos de documentación por versión de librería (`resolve-library-id`, `query-docs`).
  Instalación: `npx ctx7 setup`.
- Plan gratuito limitado a 1.000 llamadas al mes desde enero de 2026 [C]; los repos privados solo
  en planes de pago.
- **Riesgo:** el agente puede meter fragmentos de código del cliente en la consulta.

**Context**
- Paquetes de documentación en SQLite FTS5 portables, que funcionan sin conexión y sin límites.
  `context add` crea paquetes desde un repo, una carpeta o un `llms.txt`, así que sirve para SDK
  internos del cliente.
- v1.0 (abril de 2026). Instalación: `npm i -g @neuledge/context && context serve`.
- **Es el mejor encaje para clientes con NDA** [O].

---

<a id="i"></a>
## I. Filtrado de salida de herramientas

| Recurso | Tipo | Licencia | ¿Sale código? | Enlace |
|---|---|---|---|---|
| Límites nativos de salida | Variables de entorno | — | No | https://code.claude.com/docs/en/env-vars |
| Hook `PreToolUse` de filtrado | Hook propio | — | No | [plantilla](plantillas/claude/hooks/filtrar-salida-tests.sh) |
| context-mode | Plugin (MCP + 6 hooks) | **Elastic License 2.0** | No (SQLite local); `ctx_fetch_and_index` descarga URLs | https://www.npmjs.com/package/context-mode |
| RTK | CLI + hook | Apache-2.0 | No | Ficha en [skills-y-herramientas](../../skills-y-herramientas/README.md) |

**Límites nativos** [H], comprobados en la documentación el 2026-09-24:

| Variable | Por defecto | Efecto |
|---|---|---|
| `BASH_MAX_OUTPUT_LENGTH` | 30.000 caracteres (máx. 150.000) | Si la salida de un comando que ha ido bien lo supera, se guarda en un fichero y Claude recibe la ruta y una vista previa. Un comando que falla trae ~10k caracteres (principio y final) |
| `MAX_MCP_OUTPUT_TOKENS` | 25.000 tokens (aviso a partir de 10.000) | Tope de lo que devuelve una herramienta MCP |
| `CLAUDE_CODE_FILE_READ_MAX_OUTPUT_TOKENS` | — | Tope de tokens de una lectura de fichero |

En repositorios gigantes, **bajarlos** es la palanca barata; nunca subirlos «para que quepa».

**Hook de filtrado de tests**
- La documentación de costes propone reescribir los comandos de test para que solo pasen los
  fallos («de decenas de miles de tokens a cientos») [H].
- **La trampa:** la tubería `cmd | grep | head` sustituye el exit code del test por el de `head`,
  y una suite que falla parece verde.
- La [plantilla](plantillas/claude/hooks/filtrar-salida-tests.sh) de este bloque lo evita: guarda
  la salida completa en un fichero, muestra solo fallos o el resumen, devuelve el exit code real
  y no concede permisos (`updatedInput` sin `permissionDecision` sigue el flujo normal de
  permisos [H]).

**context-mode**
- Ejecuta comandos y ficheros en un sandbox; solo el stdout llega al contexto, y las salidas
  grandes van a un índice FTS5 local que se consulta bajo demanda. Guarda estado entre
  compactaciones. Unas 24k estrellas.
- Instalación: `/plugin marketplace add mksglu/context-mode` y
  `/plugin install context-mode@context-mode`.
- **Ahorro:** «98 %» medido por su autor en **bytes** que entran al contexto, no en factura; con
  recuperación indexada baja al 82 % [C].
- **Riesgos:**
  - Sus hooks obligan a usar las herramientas `ctx_*`, lo que añade viajes MCP.
  - El modelo ve resúmenes y puede perder el detalle de un fallo.
  - Guarda en disco una copia en claro de la salida durante 24 h.
  - ELv2 no es una licencia OSI: que la revise legal.
- **Antes de adoptarlo:** A/B pareado en factura (ver RTK).

**RTK: evidencia nueva.** El catálogo ya lo tenía con la cifra de su repositorio (60–90 %). Dos
estudios independientes con factura pareada la contradicen (§ 6 del [README](README.md#6-contradicciones-resueltas)):

- **SkillsBench:** +7,6 % de coste con esfuerzo bajo (p=0,004) y +0,1 % con esfuerzo alto, a
  calidad igual.
- **Terminal-Bench:** ~3 % de ahorro con Claude y +17 % con otro modelo.

En Claude Code, su valor es bajo.

---

<a id="j"></a>
## J. Memoria entre sesiones

> **La memoria también cuesta.** Comprimir observaciones con un LLM son llamadas extra, e
> inyectar memoria al arrancar la sesión (y en cada subagente) añade tokens en cada una. Hay que
> medirla como cualquier otra pieza.

| Recurso | Tipo | Licencia | ¿Sale código? | Enlace |
|---|---|---|---|---|
| Memoria nativa (CLAUDE.md, reglas, auto memory, fichero de plan) | Nativo | — | No | https://code.claude.com/docs/en/memory |
| Serena memories | Parte de Serena | GPL-3.0+ | No | https://github.com/oraios/serena |
| claude-mem | Plugin (hooks + worker + MCP) | Apache-2.0 (desde v13.1.0; antes AGPL); open-core | **Sí por defecto** | https://docs.claude-mem.ai |
| Basic Memory | Servidor MCP | **AGPL-3.0** | No (sincronización cloud opcional) | https://github.com/basicmachines-co/basic-memory |

**Memoria nativa** [H] — la mejor relación coste/beneficio.
- **Auto memory:** `MEMORY.md` hace de índice, del que se cargan las primeras 200 líneas o
  25 KB, y los temas se leen bajo demanda. Se desactiva con `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`.
- **Los `@imports` no son perezosos:** cada fichero importado se paga al arrancar.
- **Qué sobrevive a la compactación:**
  - Se reinyectan el CLAUDE.md raíz, la auto memory, **el fichero de plan de plan mode**, hasta
    5 ficheros recientes (los de más de 5k tokens, solo como ruta) y la salida de los hooks
    `SessionStart` con matcher `compact`.
  - Se pierden los CLAUDE.md anidados y las reglas por ruta.
  - Por eso el estado de una tarea larga va al fichero de plan o a un fichero de notas, no a la
    conversación.

**claude-mem**
- Captura las observaciones de las herramientas, las comprime con un LLM y las inyecta en
  sesiones posteriores con divulgación progresiva en 3 pasos (índice → cronología → detalle).
- **Ahorro:** «~10×» [C, autoevaluación].
- **Coste añadido:** inyecta contexto en cada subagente, lo que escala con los equipos de agentes
  [C, informe de usuario].
- **Privacidad (bloqueante):**
  - El instalador pide iniciar sesión, y el observador por defecto corre en el servicio del
    proveedor: **las observaciones (código, salidas) salen de la máquina**.
  - Para usarlo en local: `--provider` con el plan de Anthropic propio, o
    `CLAUDE_MEM_ONLINE_OPTIN=false`, más etiquetas `<private>`.
- El proyecto promociona un token cripto de terceros, lo que es una señal reputacional [O].
- **Veredicto:** no para clientes con NDA o sujetos a RGPD salvo configuración cerrada y auditada.

**Serena memories / Basic Memory**
- Ficheros markdown que se leen bajo demanda. Sin ahorro medido [PV].
- Serena memories solo tiene sentido si ya se usa Serena. Basic Memory es AGPL y está más
  orientada a trabajo de conocimiento que a código.

---

<a id="k"></a>
## K. Medición

| Recurso | Tipo | Licencia | ¿Sale algo? | Enlace |
|---|---|---|---|---|
| `/context`, `/usage` (`/cost`, `/stats`), `/insights` | Nativo | — | No | https://code.claude.com/docs/en/commands |
| `session-report` | Plugin oficial | Apache-2.0 | No | https://github.com/anthropics/claude-plugins-official |
| OpenTelemetry | Nativo | — | Solo a tu colector | https://code.claude.com/docs/en/monitoring-usage |
| ccusage | CLI | MIT | No con `--offline` (si no, descarga la lista de precios) | https://ccusage.com |
| Claude-Code-Usage-Monitor | TUI | MIT | No (salvo `--api`) | https://pypi.org/project/claude-monitor/ |

- **`/context`** es lo primero antes y después de instalar **cualquier** pieza de este catálogo.
- **`/usage`** muestra la tasa de acierto de caché y la atribución por skill, subagente y
  servidor MCP (v2.1.251 o posterior).
- **`session-report`** genera un HTML de tokens, eficiencia de caché y prompts más caros a partir
  de las transcripciones locales. Instalación:
  `/plugin install session-report@claude-plugins-official`.
- **OpenTelemetry:** `CLAUDE_CODE_ENABLE_TELEMETRY=1`, con las métricas `claude_code.token.usage`
  y `claude_code.cost.usage` y el evento `skill_activated`.
  - Mantener desactivados `OTEL_LOG_USER_PROMPTS`, `OTEL_LOG_TOOL_CONTENT` y
    `OTEL_LOG_TOOL_DETAILS` con clientes.
  - Activar `OTEL_LOG_TOOL_DETAILS` solo si hace falta el nombre de la skill y tras evaluar la
    privacidad.
- **ccusage:** `npx ccusage@latest --offline` da informes diarios, por sesión y por bloque de
  5 h a partir de los logs locales; también lee los de Codex.
- **Claude-Code-Usage-Monitor:** sirve para el ritmo personal dentro de la ventana de 5 h. No es
  una herramienta de A/B.

---

<a id="l"></a>
## L. Colecciones

| Colección | Licencia | Qué sacar de ella para repos gigantes | Enlace |
|---|---|---|---|
| Marketplace oficial (`claude-plugins-official`) | Apache-2.0 (plugins de Anthropic); los de terceros, la suya | Plugins LSP, `feature-dev`, `code-review`, `session-report`, `claude-md-management` (audita y adelgaza CLAUDE.md), `hookify` (hooks desde reglas en markdown). También lista `serena`, `sourcegraph`, `context7` y `lumen` (embeddings locales con Ollama) | https://github.com/anthropics/claude-plugins-official |
| anthropics/skills | Mayoría Apache-2.0; docx/pdf/pptx/xlsx solo con código disponible | `skill-creator`, para escribir las skills «visión general del paquete» que recomienda la guía de costes | https://github.com/anthropics/skills |
| Superpowers | MIT | `subagent-driven-development`, `dispatching-parallel-agents`, `using-git-worktrees`, `writing-plans`, `executing-plans` | https://github.com/obra/superpowers |
| Awesome Claude Code | **CC BY-NC-ND 4.0**: enlazar, no copiar | Pistas por vetar: empaquetado por presupuesto sobre un grafo de dependencias, routers de modelo, líneas de estado de contexto | https://github.com/hesreallyhim/awesome-claude-code |

- **Marketplace oficial:** los plugins de terceros van fijados a un SHA, pero **Anthropic no los
  audita**, y los que usan MCP pueden sacar código.
- **Superpowers:**
  - Instalación: `/plugin install superpowers@claude-plugins-official`. Existe también para Codex
    y Cursor.
  - Un hook `SessionStart` inyecta ~800 tokens [O] al arrancar, al limpiar y al compactar.
  - Es una metodología con opiniones que puede chocar con el proceso del cliente, y sube el total
    de tokens.
  - En Windows su hook necesita Git Bash [PV].

---

<a id="descartes"></a>
## Descartes

| Recurso | Motivo |
|---|---|
| `.claudeignore` | No existe en Claude Code (issue oficial cerrada). Usar `permissions.deny` |
| claude-ignore (hook comunitario) | Madurez muy baja; `permissions.deny` cubre lo mismo de forma nativa |
| mcp-language-server | Beta sin commits desde junio de 2025; lo cubren los plugins LSP nativos |
| Comby | Última versión de 2022, sin integración con agentes ni Windows nativo |
| RepoMapper (MCP) | Un solo mantenedor, poca actividad, y a millones de líneas el ranking se diluye; mejor Aider sobre un subárbol |
| gitingest | Redundante con Repomix; su web procesa el código en sus servidores |
| Wrapper comunitario de Greptile | No oficial |
| token-optimizer-mcp | Solo cifras propias; se solapa con context-mode |
| Docfork | Archivado el 2026-06-13; servicio caído |
| Ref (ref.tools) | La web muestra ahora otro producto; no se pueden verificar sus afirmaciones |
| Deepcon | Cifras solo en comparativas cercanas al proveedor |
| Extensión comunitaria de Code Wiki (MCP) | Sin vetar; Code Wiki no tiene MCP oficial |
