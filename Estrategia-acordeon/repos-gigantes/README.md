# Repositorios gigantes: skills, plugins y estrategias de ahorro de tokens

> Investigación elaborada con la misma estrategia «acordeón» que el [roadmap general](../roadmap.md)
> (apertura → clasificación → profundización por categoría → fusión), aplicada a un caso concreto:
> **trabajar con agentes de código sobre repositorios de millones de líneas**, que es lo que
> tienen los clientes. Fecha: 2026-09-24. Versiones, precios, nombres de ajustes y estrellas
> cambian cada pocas semanas: verifica la fuente antes de aplicar una cifra.

← [Volver a Estrategia acordeón](../README.md)

**Leyenda de evidencia** (la misma del roadmap):

| Etiqueta | Significado |
|---|---|
| **[H]** | Hecho documentado (documentación oficial o paper con datos) |
| **[C]** | Afirmación de la comunidad o del propio proveedor (autoevaluación) |
| **[O]** | Opinión o inferencia propia |
| **[PV]** | Pendiente de verificar |

## Los documentos de este bloque

| Documento | Qué contiene |
|---|---|
| Este README | Resumen, método, taxonomía, matriz de priorización, adopción por fases, contradicciones y fuentes |
| [catalogo.md](catalogo.md) | Las fichas de cada skill, plugin, servidor MCP y ajuste nativo, por categoría |
| [privacidad-y-licencias.md](privacidad-y-licencias.md) | Por dónde sale el código de cada herramienta y qué licencia tiene: el filtro que hay que pasar **antes** de usarla con un cliente |
| [plantillas/](plantillas/README.md) | Configuración propia lista para copiar a un repositorio de cliente: settings, subagente explorador, hook de filtrado, skill de navegación y plantillas de CLAUDE.md y mapa |

---

## 1. Resumen ejecutivo

**El problema cambia de naturaleza con el tamaño.** En un repositorio pequeño el gasto lo
dominan el historial y los resultados de herramientas (ver roadmap § 2). En uno de millones
de líneas se suman tres fugas propias:

- **Instrucciones que no tocan.** Un CLAUDE.md raíz que cubre todos los subsistemas se paga en
  cada turno aunque la tarea sea de uno solo [H].
- **Búsqueda a ciegas.** Localizar un símbolo cuesta decenas de `grep` y lecturas, y cada
  resultado se reenvía en todos los turnos siguientes [H].
- **Ruido que no es código del equipo.** Vendorizado, generado, build y lockfiles aparecen en
  búsquedas y lecturas si nadie los excluye [H].

**La tesis.** En un repositorio gigante no se ahorra comprimiendo el repositorio, sino
**acotando** qué entra: se arranca en el subsistema, se aíslan las exploraciones en subagentes y
se navega con índices en vez de leer ficheros. Meter el repositorio entero, aunque sea
comprimido, es un antipatrón a esta escala [O].

**Qué dice la evidencia independiente, y no la de los proveedores:**

1. **Lo nativo es lo más sólido.** CLAUDE.md por capas, `claudeMdExcludes`, reglas `Read` en
   `permissions.deny`, subagente Explore, worktrees dispersos y límites de salida están
   documentados por Anthropic para este caso exacto [H]. Cuestan cero y no sacan código de la
   máquina.
2. **Los «−90 %» de las herramientas de filtrado no aparecen en la factura.** Dos estudios
   independientes con A/B pareado sobre RTK encontraron **+7,6 % de coste** (esfuerzo bajo,
   p=0,004) o ±0 % en Claude Code, y un +17 % con otro modelo, a calidad igual [H]. El
   contador de la propia herramienta decía 99,8 % de ahorro en esa misma ejecución.
3. **LSP no es un ahorrador de tokens, es una herramienta de precisión.** El único estudio
   controlado mide **más** tokens al localizar con modelos fuertes (+6 % Opus, +118 % Sonnet) y
   mejor precisión al buscar todas las referencias (1,00 frente a 0,76) [H, muestra pequeña,
   repos pequeños].
4. **Los grafos de código tienen la mejor cifra publicada:** ~10× menos tokens y 2,1× menos
   llamadas con el 90 % de la calidad de un agente que explora ficheros (31 repos) [H]. El
   «120×» del README del proyecto es autoevaluación [C].
5. **Ningún índice (grafo o vectorial) tiene evaluación de calidad por encima de 1M de
   líneas.** El kernel de Linux se ha indexado, pero no se han evaluado sus respuestas [H].
   Hay que medir en el repositorio del cliente antes de venderlo.

**Cinco decisiones que salen de aquí:**

1. **Medir antes de instalar nada**: `/context`, `/usage`, el plugin `session-report`, OTel u
   `ccusage --offline`.
2. **Configuración nativa primero**: es gratuita, está documentada y es local.
3. **Exploración en subagente** con modelo pequeño y contrato de salida corto.
4. **Un índice local** (grafo primero, semántico después) solo tras un piloto medido en el
   repositorio real.
5. **Codemods deterministas** (ast-grep, OpenRewrite) para cambios masivos, en vez de editar
   fichero a fichero.

**Qué no hacer:**

- Empaquetar el repositorio entero (Repomix, gitingest) y pegarlo en el contexto.
- Dar por buenas las cifras del contador de una herramienta: solo vale la factura pareada.
- Usar DeepWiki, Augment, Context7 privado o `claude-mem` en su modo por defecto con código
  bajo NDA: sacan código de la máquina ([privacidad-y-licencias.md](privacidad-y-licencias.md)).
- Usar GitNexus en trabajo para clientes sin licencia comercial: es PolyForm Noncommercial.
- Crear un `.claudeignore`: no existe. El mecanismo real es `permissions.deny` [H].

---

## 2. Método: cómo se aplicó el acordeón

| Fase | Qué se hizo | Resultado |
|---|---|---|
| **1. Apertura** | Búsqueda amplia: documentación oficial de Claude Code para monorepos y el blog de Anthropic del 2026-05-14, listas curadas de plugins y skills, y servidores MCP de búsqueda, grafos, empaquetado, filtrado y memoria | ~60 candidatos |
| **2. Clasificación** | Cada candidato se asigna a la categoría del punto donde actúa (qué se carga, cómo se explora, cómo se busca, qué sale de las herramientas, qué se recuerda, cómo se mide) | 12 categorías (§ 3) |
| **3. Profundización** | Cinco investigaciones en paralelo, una por grupo de categorías. De cada recurso se comprobó: enlace (HTTP), licencia, actividad, cifra de ahorro **con su procedencia**, escala probada, cuándo no usarlo y si el código sale de la máquina | ~45 fichas; 12 descartes justificados |
| **4. Fusión** | Se cruzan las cifras de proveedor con las independientes, se resuelven las contradicciones (§ 6) y se priorizan por impacto, esfuerzo, evidencia y privacidad | Matriz (§ 4), fases (§ 5) y plantillas |

**Criterio añadido respecto al roadmap: la privacidad.** Para una consultora, una herramienta
que manda código del cliente a un tercero no es un ahorro, es un riesgo contractual y de RGPD.
Por eso cada ficha lleva la columna «¿sale código?», y la matriz penaliza lo que no tiene modo
local.

---

## 3. Taxonomía

| # | Categoría | Actúa sobre… | Ejemplos |
|---|---|---|---|
| **A** | Acotar lo que se carga | qué instrucciones, skills y ficheros son visibles en la sesión | CLAUDE.md por capas, `claudeMdExcludes`, `Read` deny, arrancar en subdirectorio, `sparsePaths` |
| **B** | Exploración aislada | dónde se consumen los tokens de exploración | Subagente Explore, subagente propio con modelo pequeño, `feature-dev` |
| **C** | Navegación precisa (LSP/SCIP) | cómo se resuelve «definición» y «referencias» | Plugins LSP oficiales, Serena, Sourcegraph MCP |
| **D** | Grafo de conocimiento del código | preguntas estructurales (quién llama, impacto) | codebase-memory-mcp, CodeGraphContext, code-review-graph |
| **E** | Índice semántico | búsqueda por significado («dónde validamos el IVA») | Claude Context, CocoIndex Code, Semble |
| **F** | Búsqueda estructural y codemods | patrones sintácticos y cambios masivos | ripgrep con disciplina, ast-grep, OpenRewrite |
| **G** | Mapas, empaquetado y wikis | una vista resumida del repositorio | Mapa de carpetas en markdown, Aider repo map, Repomix sobre un subárbol, deepwiki-open |
| **H** | Documentación de dependencias | no leer código vendorizado para aprender una API | Context7, Context (local), GitMCP |
| **I** | Filtrado de salida | lo que devuelven Bash, MCP y las lecturas | Límites nativos, hook de filtrado, context-mode, RTK |
| **J** | Memoria entre sesiones | qué estado sobrevive a `/clear` y a la compactación | Memoria nativa, fichero de plan, claude-mem |
| **K** | Medición | ver qué consume y validar el ahorro | `/context`, `/usage`, `session-report`, OTel, ccusage |
| **L** | Colecciones | de dónde se instala | Marketplace oficial, anthropics/skills, Superpowers |

Relación con el roadmap: A y G concretan S11, S12 y S20; B concreta S6 y S34; C concreta S21;
D y E concretan S14 y S22; F concreta S27 y S32 para cambios masivos; I concreta S27; J concreta
S19; K concreta S38.

---

## 4. Matriz de priorización

Puntuación = impacto / esfuerzo (A=3, M=2, B=1). A igualdad, desempata la evidencia. La columna
**Privacidad** marca con ✅ lo que es local, con ⚠️ lo que tiene modo local pero no por defecto y
con ⛔ lo que exige sacar código a un tercero.

| Prio | Estrategia o recurso | Cat. | Impacto | Esfuerzo | Evidencia | Privacidad | Condición / advertencia |
|---|---|---|---|---|---|---|---|
| 1 | Medir la línea base (`/context`, `/usage`, `session-report`, OTel) | K | M (habilita) | B | [H] | ✅ | Sin ella no se valida nada de lo demás |
| 2 | Arrancar en el subsistema y CLAUDE.md por capas (<200 líneas) + mapa de carpetas | A | A | B | [H] | ✅ | El mapa se regenera en CI o caduca |
| 3 | `permissions.deny` con `Read(...)` para vendor, generado y build | A | A | B | [H] | ✅ | Es best-effort en Grep/Glob y no cubre `grep -r`: no es una frontera de seguridad |
| 4 | `claudeMdExcludes` para paquetes de otros equipos | A | M | B | [H] | ✅ | Lista estática, no un interruptor por tarea |
| 5 | Subagente Explore o subagente propio `model: haiku` con contrato de salida | B | A | B | [H] | ✅ | Explore no ve CLAUDE.md; el resumen puede perder detalle |
| 6 | Límites nativos de salida y hook de filtrado de tests que conserve el exit code | I | M | B | [H] | ✅ | Un `grep` sin `pipefail` convierte fallos en verde |
| 7 | Gobierno de skills: descripciones cortas y `disable-model-invocation` | A | M | B | [H] | ✅ | Con muchas skills se truncan descripciones y dejan de activarse |
| 8 | ripgrep con disciplina (conteo primero, globs, rangos) + skill de ast-grep | F | M | B | [H]/[O] | ✅ | ast-grep es solo sintaxis, sin tipos |
| 9 | Plugins LSP oficiales (lenguajes tipados) | C | M (precisión) | B | [H] | ✅ | **No prometer ahorro**; memoria alta en monorepos |
| 10 | Plan mode con fichero de plan en cambios entre paquetes | J | M | B | [H] | ✅ | El plan sobrevive a la compactación; los CLAUDE.md anidados no |
| 11 | Piloto de codebase-memory-mcp | D | A | M | [H] paper | ✅ | Fijar v0.11+; hay fallos abiertos en Windows; calidad −9 puntos |
| 12 | OpenRewrite (JVM) o `ast-grep --rewrite` para migraciones masivas | F | A | M | [O] | ✅ / ⚠️ | Moderne CLI exige licencia en repos privados |
| 13 | `sparsePaths` + `symlinkDirectories` en worktrees de subagentes | A | M | M | [H] | ✅ | Solo si se trabaja con worktrees |
| 14 | Plugin interno de convenciones + hook `SessionStart` que lo recomienda | A | M | M | [H] | ✅ | Requiere un equipo responsable (DRI) |
| 15 | Índice semántico local (CocoIndex Code, o Claude Context con Ollama + Milvus propio) | E | M | M | [C] | ⚠️ | Claude Context manda código a la nube por defecto |
| 16 | Sourcegraph MCP sobre la instancia autoalojada del cliente | C | A (multi-repo) | B si ya existe | [H] bench del proveedor | ✅ autoalojado / ⛔ cloud | Solo Enterprise; ganancia marginal en un solo repo |
| 17 | Repomix `--compress` sobre **un subárbol**, leído con `grep_repomix_output` | G | B–M | B | [C] | ✅ CLI / ⛔ web | Nunca en la raíz; quita los cuerpos de función |
| 18 | Docs de dependencias: Context (local) o Context7 | H | M | B | [C] | ✅ / ⛔ | Context7 manda las consultas a su servicio |
| 19 | context-mode | I | ? | M | [C] autoevaluado | ✅ | ELv2; ahorro en bytes, no en factura; hace falta un A/B |
| 20 | Superpowers, `feature-dev`, `code-review` (multiagente) | B/L | M (calidad) | B | [H]/[C] | ✅ | **Suben el total** de tokens; limpian el contexto principal |
| 21 | claude-mem | J | ? | M | [C] | ⛔ por defecto | Añade tokens a cada subagente; configurar en local o no usar |
| 22 | RTK | I | ≈0 o negativo | B | [H] independiente | ✅ | Ya está en el catálogo; ver § 6 |

**Descartados** (en [catalogo.md](catalogo.md) § Descartes): `.claudeignore`, mcp-language-server,
Comby, Docfork, Ref, gitingest (redundante), el wrapper comunitario de Greptile,
token-optimizer-mcp, claude-ignore, RepoMapper, la extensión comunitaria de Code Wiki y
Deepcon.

---

## 5. Adopción por fases en un repositorio de cliente

> Regla de oro, heredada del roadmap: **ninguna pieza sin línea base ni gate de calidad**. El
> gate es el mismo: la tasa de resolución no cae más de 1 punto y el coste por tarea resuelta
> baja un 10 % o más, con 3 o más ejecuciones por tarea por la varianza.

### Fase 0 — Primer día en el repositorio (medio día)

| Paso | Acción | Entregable |
|---|---|---|
| 0.1 | Elegir 10–20 tareas reales del cliente (bugs con test, cambios pequeños, preguntas de «dónde está X») | Suite mínima |
| 0.2 | Ejecutarlas sin configurar nada y guardar `/context` al inicio, `/usage` al final y el informe de `session-report` | Línea base |
| 0.3 | Revisar con el cliente la política de datos: qué herramientas pueden ver su código ([privacidad-y-licencias.md](privacidad-y-licencias.md)) | Lista blanca de herramientas |

### Fase 1 — Configuración nativa (1–3 días)

Copiar y adaptar [plantillas/](plantillas/README.md):

1. **Mapa de carpetas** en la raíz (`MAPA.md`: una línea por carpeta de primer nivel) y
   **CLAUDE.md raíz** con solo comandos, reglas globales y un puntero al mapa.
2. **CLAUDE.md por subsistema**, lo mantiene el dueño de cada área.
3. **`permissions.deny`** con `Read(...)` para vendor, generado, build y artefactos. En Windows,
   rutas `//` absolutas en `settings.local.json` (la documentación avisa de que ahí no se usa la
   raíz del repositorio).
4. **`claudeMdExcludes`** para los paquetes en los que no se trabaja.
5. **Subagente `explorador`** (modelo pequeño, solo lectura, informe de 40 líneas como máximo).
6. **Hook de filtrado de tests** que conserve el exit code y deje la salida completa en un
   fichero.
7. **Skill `explorar-repo-gigante`** con la escalera de búsqueda (índice → LSP → rg → ast-grep →
   rangos de líneas).
8. Plugins LSP del lenguaje principal si es tipado, para diagnósticos y referencias.

**Gate de Fase 1:** repetir la suite y comparar coste por tarea resuelta, lecturas por tarea y
tokens base de sesión.

### Fase 2 — Índices, solo si la Fase 1 no basta (1–2 semanas)

1. Piloto de **codebase-memory-mcp** en el repositorio real: tiempo de indexado, RAM, calidad
   de las respuestas estructurales y caducidad tras un cambio de rama.
2. Si las preguntas son de negocio, no estructurales, un **índice semántico local** (CocoIndex
   Code, o Claude Context con Ollama y Milvus propios).
3. Si el cliente ya tiene **Sourcegraph autoalojado**, conectar su MCP antes que montar nada.
4. Para migraciones masivas: **ast-grep** o **OpenRewrite** con recetas, y el agente escribiendo
   o invocando la receta.

**Gate de Fase 2:** el índice tiene que ganar a la Fase 1 en coste por tarea resuelta **sin**
perder más de 1 punto de calidad. Si no gana, se desinstala: cada herramienta MCP también cuesta
tokens por turno.

### Fase 3 — Escala de equipo

1. Empaquetar skills, hooks y ajustes en un **plugin interno** versionado, con un DRI.
2. Hook `SessionStart` que recomiende el plugin del área según el directorio de arranque.
3. OTel hacia un colector propio con `skill_activated` para retirar las skills que no se usan.
4. Revisar la configuración cada 3–6 meses y tras cada modelo nuevo [H].

---

## 6. Contradicciones resueltas

| # | Tema | Contradicción | Resolución adoptada |
|---|---|---|---|
| 1 | RTK | «60–90 % de ahorro» (proyecto) frente a +7,6 % / ±0 % de coste (A/B de 425 ejecuciones) y +17 % con otro modelo (1.740 intentos) | Prevalece la factura pareada. Motivo: el hook solo ve ~1/5 de la salida (Read y Grep no pasan por Bash), la relectura cacheada cuesta 0,1× y los turnos extra se comen el ahorro |
| 2 | context-mode | «98 %» frente a ausencia de medida en factura | Es reducción de **bytes** medida por su autor. Tratar como [C] hasta un A/B propio; el caso de RTK muestra que bytes ≠ coste |
| 3 | LSP | «Ahorra tokens» (comunidad, blogs) frente a +6 % / +118 % al localizar (paper) | LSP para completitud de referencias y diagnósticos, no como ahorrador. Ayuda más cuanto más ruidoso es el `grep` (nombres repetidos) |
| 4 | codebase-memory-mcp | «120×» (README) frente a ~10× con 90 % de calidad (paper) | Se usa la cifra del paper; el paper tiene una corrección sin ciego y un repositorio por lenguaje |
| 5 | code-review-graph, Semble | «49–63×», «99 %» frente a línea base débil | Comparan con meter el repositorio entero o con el tamaño del fichero, no con un agente que usa `grep`. Descontar |
| 6 | Búsqueda agéntica frente a índice vectorial | Anthropic recomienda búsqueda agéntica para evitar índices caducados; los proveedores de índices, lo contrario | Por defecto, búsqueda agéntica + LSP. El índice se añade donde el piloto demuestre ganancia y haya reindexado incremental |
| 7 | Subagentes | Reducen el contexto principal frente a subir el total | Compensa cuando la exploración habría viajado en muchos turnos del principal. Medir el principal **y** el total |
| 8 | Memoria | «Ahorra 10×» frente a añadir tokens (compresión con LLM, inyección en cada subagente) | Memoria nativa (CLAUDE.md, reglas por ruta, auto memory, fichero de plan) primero; herramientas de memoria solo con A/B |
| 9 | `.claudeignore` | Blogs lo recomiendan frente a su inexistencia oficial | No existe (issue cerrada). Usar `permissions.deny` y no tratarlo como frontera de secretos |
| 10 | Empaquetado | «Todo el repo como contexto» frente a context rot y ventana | En millones de líneas, empaquetar solo un subárbol y leerlo por partes |
| 11 | Sourcegraph | «30 % de ahorro de tokens» (marketing) frente a +0,029 de recompensa media (su propio benchmark) | La ganancia se concentra en tareas **multi-repo** (recuperación de 0,007 a 0,471); en un solo repositorio es marginal |

---

## 7. Lagunas

1. **Nada evaluado en calidad por encima de 1M de líneas**, ni grafos ni vectores ni LSP [PV].
   Es la primera medida que conviene producir con un cliente.
2. **El paper de LSP usa repositorios pequeños** y una integración propia, no los plugins
   oficiales ni Serena [H]. No se sabe si el signo cambia a escala.
3. **context-mode, claude-mem, Serena y CocoIndex** no tienen medida independiente en factura [PV].
4. **Windows**: codebase-memory-mcp tiene fallos abiertos (entre ellos un fallo silencioso de
   indexado); los hooks de ejemplo son bash + `jq`; los binarios LSP tienen que estar en el PATH.
5. **Estrellas de GitHub**: algunas cifras son anómalamente altas para la edad del proyecto.
   Úsalas como señal de popularidad, no de calidad [O].

---

## 8. Fuentes

**Documentación oficial (Anthropic, OpenAI, Cursor, GitHub)**
- https://code.claude.com/docs/en/large-codebases
- https://claude.com/blog/how-claude-code-works-in-large-codebases-best-practices-and-where-to-start (2026-05-14)
- https://code.claude.com/docs/en/best-practices
- https://code.claude.com/docs/en/sub-agents
- https://code.claude.com/docs/en/skills
- https://code.claude.com/docs/en/context-window
- https://code.claude.com/docs/en/costs
- https://code.claude.com/docs/en/env-vars
- https://code.claude.com/docs/en/hooks
- https://code.claude.com/docs/en/memory
- https://code.claude.com/docs/en/discover-plugins
- https://code.claude.com/docs/en/monitoring-usage
- https://code.claude.com/docs/en/commands
- https://learn.chatgpt.com/docs/agent-configuration/agents-md
- https://cursor.com/docs/context/codebase-indexing
- https://cursor.com/docs/context/ignore-files
- https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions

**Papers y estudios con datos**
- https://arxiv.org/abs/2608.13568 (¿Ahorra tokens un language server? Estudio preliminar)
- https://arxiv.org/abs/2603.27277 (Codebase-Memory: grafos tree-sitter vía MCP)
- https://arxiv.org/abs/2606.11864 (CORE-Bench: recuperación de código por agentes)
- https://blog.jetbrains.com/ai/2026/07/rtk-claude-code-token-savings/ (A/B pareado de RTK en Claude Code)
- https://quesma.com/blog/does-rtk-make-ai-coding-cheaper/ (RTK en Terminal-Bench)
- https://github.com/sourcegraph/CodeScaleBench (benchmark del propio proveedor)

**Recursos**: los enlaces de cada herramienta están en su ficha de [catalogo.md](catalogo.md). Todos se
comprobaron con HTTP 200 el 2026-09-24, salvo las excepciones anotadas en la ficha.
