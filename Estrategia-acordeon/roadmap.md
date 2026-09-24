# Roadmap de optimización de tokens en generación de código y soluciones agénticas

> Investigación elaborada con estrategia "acordeón" (apertura → clasificación → profundización por categoría → fusión).
> Fecha de elaboración: 2026-09-24. Los precios, parámetros y nombres de API cambian con frecuencia: verifica siempre la documentación vigente del proveedor antes de aplicar una cifra.

**Leyenda de evidencia** (se usa en todo el documento):

| Etiqueta | Significado |
|---|---|
| **[H]** | Hecho documentado (documentación oficial de proveedor o paper con datos) |
| **[C]** | Práctica común reportada por la comunidad o por un proveedor comercial interesado |
| **[O]** | Opinión, inferencia o hipótesis (propia o de la fuente) |
| **[PV]** | Pendiente de verificar (dato sin fuente primaria o no replicado) |

---

## Índice

1. [Resumen ejecutivo](#sec-1)
2. [Contexto: cómo se consumen los tokens y dónde se desperdician](#sec-2)
3. [Taxonomía de estrategias](#sec-3)
4. [Matriz de priorización](#sec-4)
5. [Detalle de estrategias por categoría](#sec-5)
   - [A. Reutilización y precio](#cat-a)
   - [B. Selección de modelo y cómputo](#cat-b)
   - [C. Construcción del contexto de entrada](#cat-c)
   - [D. Gestión del contexto en el tiempo](#cat-d)
   - [E. Herramientas e interfaz agente-entorno](#cat-e)
   - [F. Formato y control de la salida](#cat-f)
   - [G. Arquitectura y orquestación](#cat-g)
   - [H. Medición y gobernanza](#cat-h)
   - [Contradicciones y solapamientos resueltos](#sec-5-res)
6. [Roadmap de adopción por fases](#sec-6)
7. [Guía para generación de código](#sec-7)
8. [Guía para soluciones agénticas](#sec-8)
9. [Checklist de optimización de tokens](#sec-9)
10. [Lagunas y líneas abiertas](#sec-10)
11. [Fuentes](#sec-11)

---

<a id="sec-1"></a>
## 1. Resumen ejecutivo

**El problema.** En sistemas agénticos lo que más se paga no es lo que el modelo escribe, sino lo que lee una y otra vez.
- Cada turno reenvía el system prompt, las definiciones de herramientas, el historial y los resultados de herramientas acumulados [H].
- Un agente consume unas 4× más tokens que un chat, y un sistema multiagente unas 15× [H].
- En tareas de código agénticas el consumo es unas 1000× el de un chat de código. Domina la entrada y la misma tarea puede variar hasta 30× entre ejecuciones [H].
- Más tokens no equivalen a más calidad: el acierto suele tocar techo a coste intermedio [H], y el rendimiento se degrada al crecer el contexto (*lost in the middle*, *context rot*) [H].

**La tesis.** Optimizar tokens es, sobre todo, **ingeniería de contexto y de orquestación**. El objetivo no es minimizar tokens a toda costa, sino **maximizar calidad por token**. El único criterio válido de éxito es *coste por tarea resuelta con calidad igual o mejor*.

**Las 38 estrategias** se agrupan en 8 categorías según su punto de actuación:

| Categoría | Qué cubre |
|---|---|
| A | Precio y reutilización |
| B | Modelo y cómputo |
| C | Contexto de entrada |
| D | Contexto en el tiempo |
| E | Herramientas |
| F | Salida |
| G | Orquestación |
| H | Medición |

**Cinco palancas con mejor relación impacto/esfuerzo y evidencia sólida:**

1. **Caché de prefijos bien diseñada (A).** La parte cacheada se lee a 0,1× o menos del precio de entrada. En agentes de larga duración reduce el coste total un 41–80 % [H]. Exige un orden estable → dinámico y no cambiar herramientas, modelo ni *effort* a mitad de sesión.
2. **Limpiar o enmascarar resultados antiguos de herramientas (D).** −84 % de tokens en un benchmark de 100 turnos de Anthropic [H]. En agentes de código, el enmascarado simple rinde igual que el resumen con LLM y cuesta la mitad que no gestionar el contexto [H].
3. **Herramientas diferidas y salidas filtradas (E).**
   - Tool Search reduce ~85 % los tokens de definiciones y mejora la selección [H].
   - Filtrar la salida de tests y logs con hooks pasa de decenas de miles de tokens a cientos [H].
   - Un visor de 100 líneas rinde más que mostrar el archivo completo [H].
4. **Elegir modelo y *effort* por tarea (B).** Hay que asignar un modelo por rol de subagente y ajustar el razonamiento. Un modelo mejor con *effort* medio puede usar un 76 % menos de tokens de salida que otro inferior a su máximo [H, proveedor]. Cuidado: el routing ingenuo entre modelos puede salir más caro que no enrutar, porque rompe la caché [H].
5. **La arquitectura más simple que funcione (G).** Workflow determinista antes que agente, y agente único antes que multiagente para escribir código. El arnés de orquestación por sí solo puede recortar un 38 % de tokens por tarea sin perder calidad [H, preprint].

**Qué no hacer:**
- Comprimir código con compresores de prosa [O/H].
- Usar caché semántica para generación de código dependiente del repositorio [O].
- Asumir que *Predicted Outputs* ahorra tokens: reduce latencia, pero los tokens rechazados se facturan [H].
- Paralelizar escritura de código entre agentes sin contexto compartido [H].
- Inflar CLAUDE.md o AGENTS.md: puede encarecer más de un 20 % sin mejorar el éxito [H, preprint].

**Cómo adoptarlo:**
- **Fase 0:** medir primero. Instrumentar los campos `usage`, la tasa de acierto de caché y el coste por tarea resuelta, y montar una pequeña suite de evaluación.
- **Quick wins (0–4 semanas):** caché, higiene de sesión, *effort*, filtros y diffs.
- **Medio plazo (1–3 meses):** divulgación progresiva, diseño de herramientas, subagentes y workflows.
- **Avanzado (3+ meses):** routing aprendido, reducción de trayectoria y ejecución de código sobre herramientas.

Cada paso se valida con un *gate* de calidad: la tasa de resolución no puede caer más de 1 punto y el coste por tarea resuelta debe bajar al menos un 10 %.

---

<a id="sec-2"></a>
## 2. Contexto: cómo se consumen los tokens y dónde se desperdician

### 2.1 Anatomía del consumo

| Componente | Cómo se factura / consume | Nota clave |
|---|---|---|
| System prompt + archivos de instrucciones | Entrada, en **cada** petición | CLAUDE.md/AGENTS.md se cargan al inicio de cada sesión [H] |
| Definiciones de herramientas | Entrada, en cada petición; son el primer nivel del prefijo | 58 herramientas de 5 servidores MCP ≈ 55K tokens [H] |
| Historial de conversación | Entrada, reenviado entero en cada turno | Claude Code "sends your full conversation with every request" [H] |
| Resultados de herramientas | Entrada en el turno siguiente y en todos los posteriores | Cada llamada a herramienta genera otra petición con todo el historial [H] |
| Salida visible | Salida: 5× la entrada en Anthropic, 4–8× en OpenAI [H] | Recortar la salida a la mitad reduce la latencia casi a la mitad [H] |
| Razonamiento (thinking) | Salida, aunque no se vea; también ocupa ventana | Puede suponer decenas de miles de tokens por petición [H] |
| Tareas en segundo plano | Reenvían el contexto completo sin intervención del usuario | Loops, check-ins, mensajes entre sesiones [H] |

Con N turnos que añaden Δ tokens cada uno, la entrada total crece aproximadamente con N²·Δ/2 [O]. Por eso las técnicas que actúan sobre la **entrada acumulada** (categorías A, D y E) dominan el ahorro en agentes.

### 2.2 Por qué importa

- **Coste.** El gasto crece aunque el precio por token baje ("token maxing") [H].
- **Latencia.** Más turnos y más salida implican más tiempo.
- **Límites.** Ventana de contexto, TPM/RPM y ventanas de uso de suscripción [H].
- **Calidad.** La precisión cae cuando la información relevante está en medio del contexto, en algunos casos más de un 30 % [H]. Los 18 modelos evaluados por Chroma empeoran al crecer la entrada, incluso en tareas triviales [H].
- **Predictibilidad.** La varianza puede llegar a 30× entre ejecuciones. Los modelos predicen mal su propio consumo (r ≤ 0,39) y lo subestiman [H].

### 2.3 Dónde se desperdician tokens

**En generación de código (desarrollador + asistente):**
- Prompts vagos que provocan escaneos amplios del repositorio [H].
- Sesiones largas que nunca se limpian y arrastran contexto obsoleto [H].
- Archivos de instrucciones inflados que se pagan en cada turno [H].
- Leer archivos completos o logs y salidas de tests enteros [H].
- Reescribir archivos completos para cambios pequeños [H].
- Razonamiento máximo para tareas mecánicas [H].
- Retrabajo por arrancar en la dirección equivocada [H].

**En sistemas agénticos:**
- Información inútil, redundante o caducada en la trayectoria (AgentDiet) [H].
- Resultados antiguos de herramientas que se reenvían indefinidamente [H].
- Catálogos de herramientas inflados o solapados [H].
- Datos intermedios que pasan por el modelo sin necesidad [H].
- Invalidar la caché al cambiar el prefijo (timestamps al inicio, herramientas dinámicas) [H].
- Sobredimensionar el multiagente, con teammates ociosos que siguen vivos [H].
- Recursión de subagentes [C].
- Sobrerrazonamiento en preguntas triviales (ante "2+3", +1953 % de tokens en modelos tipo o1) [H].

### 2.4 Métricas de eficiencia

| Métrica | Fórmula / fuente |
|---|---|
| Tokens por tipo y petición | `input_tokens`, `cache_read_input_tokens`, `cache_creation_input_tokens`, `output_tokens` (Anthropic); `cached_tokens`, `reasoning_tokens` (OpenAI) [H] |
| Tasa de acierto de caché | `cache_read / (cache_read + cache_creation + input_tokens)` [H] |
| Tokens y coste por tarea | Suma por `task_id` |
| **Coste por tarea resuelta** | coste total / nº tareas resueltas (p. ej., Agentless: 0,34 $/issue en la v1; 0,70 $ en la versión actual) [H] |
| TTFT y latencia total | p50/p95 |
| Ratio entrada/salida | Entre 100:1 (Manus) y 150:1 (SWE-bench) según la fuente [H] |
| Precisión por 1K tokens / por coste | Útil para comparar formatos y modelos [C] |
| Varianza entre ejecuciones | Coeficiente de variación de tokens para la misma tarea (N ≥ 3–5) [H/C] |

---

<a id="sec-3"></a>
## 3. Taxonomía de estrategias

### 3.1 Criterio

Cada estrategia se clasifica por **la parte del ciclo de inferencia sobre la que actúa**. Así las categorías son mutuamente excluyentes por punto de actuación. Algunas estrategias tienen una categoría secundaria cuando su efecto se nota también en otra parte.

| # | Categoría | La estrategia actúa sobre… |
|---|---|---|
| **A** | Reutilización y precio | el **precio o la reutilización** de tokens, sin cambiar el contenido |
| **B** | Selección de modelo y cómputo | **qué modelo** procesa y **cuánto razona** |
| **C** | Construcción del contexto de entrada | **qué entra** en el contexto al inicio o en cada petición |
| **D** | Gestión del contexto en el tiempo | **cómo evoluciona** el contexto acumulado durante la sesión |
| **E** | Herramientas e interfaz agente-entorno | **definiciones, invocación y resultados** de herramientas |
| **F** | Formato y control de la salida | **qué y cuánto genera** el modelo |
| **G** | Arquitectura y orquestación | la **topología** (workflow / agente / multiagente) y el flujo de trabajo |
| **H** | Medición y gobernanza | la **observación y los límites** del consumo (transversal: habilita al resto) |

### 3.2 Tabla de clasificación (consolidada tras la Fase 3)

Leyenda: Ámbito **Cód** = generación de código · **Ag** = agéntico · **Ambos**. Impacto y complejidad: **A** alta · **M** media · **B** baja.

| ID | Estrategia | Cat. (2ª) | Ámbito | Impacto | Complej. | Justificación breve |
|---|---|---|---|---|---|---|
| S1 | Caché de prefijos del proveedor | A | Ambos | A | B | La parte cacheada se lee a 0,1× o menos; en OpenAI y Gemini es automática [H] |
| S2 | Prompt amigable con la caché (estable→dinámico) | A (C) | Ambos | A | B | −41 a −80 % de coste en agentes [H] |
| S3 | TTL de caché según el patrón de uso | A | Ambos | M | B | Evita reescrituras tras pausas [H] |
| S4 | Batch API asíncrona | A | Ambos | M | B | −50 %, solo para trabajo que no es en tiempo real [H] |
| S9 | Caché semántica de respuestas | A | Ag | B–M | M | Solo para consultas tipo FAQ; hay riesgo de fallo silencioso en código [H/O] |
| S5 | Routing / cascada de modelos | B | Ambos | A | A | −53 % en SWE-bench con un router entrenado; el routing ingenuo sale más caro [H] |
| S6 | Modelo por tipo de tarea o subagente | B (G) | Ambos | A | B | Es configuración, no código [H] |
| S7 | *Effort* / presupuesto de razonamiento | B | Ambos | A | B | El thinking se factura como salida [H] |
| S8 | Razonamiento conciso (Chain of Draft) | B (F) | Ambos | M | B | 7,6 % de los tokens de CoT en razonamiento; sin validar en código [H/PV] |
| S10 | Prompts específicos | C | Cód | A | B | Evita el escaneo amplio [H] |
| S11 | Archivo de instrucciones del proyecto corto | C | Cód | M | B | Se paga en cada turno; su valor está en disputa [H] |
| S12 | Divulgación progresiva (skills bajo demanda) | C | Ambos | M | M | Carga lo especializado solo si hace falta [H] |
| S13 | System prompt a la altitud correcta + ejemplos canónicos | C | Ag | M | M | Menos reglas y más heurísticas [H] |
| S14 | Recuperación just-in-time por identificadores | C (E) | Ambos | A | M | No precargar contenido [H] |
| S20 | Mapa de repositorio (tree-sitter + ranking) | C | Cód | A | M | Estructura del repo en ~1K tokens [H] |
| S22 | RAG con reranking y ordenación | C | Ambos | M | A | −67 % de fallos de recuperación con reranking [H] |
| S30 | Compresión de prompts | C | Ambos | M | A | 2–20× en prosa; en código solo con métodos estructurales [H] |
| S31 | Formatos de datos compactos (JSON minificado, TOON, CSV) | C (F) | Ag | M | B | −20 a −40 % en datos uniformes; empeora con datos anidados [H/C] |
| S15 | Compactación del historial | D | Ambos | A | B | Cada turno posterior se vuelve ~8× más ligero en el ejemplo documentado [H/O] |
| S16 | Limpiar o enmascarar resultados antiguos | D | Ag | A | B | −84 % de tokens (búsqueda web); ~−50 % de coste en SWE-agent [H] |
| S17 | Reiniciar el contexto entre tareas | D | Cód | A | B | Coste cero [H] |
| S18 | Reducción de trayectoria (AgentDiet) | D | Ag | A | A | −40 a −60 % de entrada y −21 a −36 % de coste [H] |
| S19 | Memoria externa / notas estructuradas | D (G) | Ag | M | M | Saca estado de la ventana [H] |
| S21 | Code intelligence / LSP | E (C) | Cód | M | B | Una llamada en lugar de grep + N lecturas [H] |
| S23 | Ejecución de código sobre herramientas (PTC, code-exec MCP) | E | Ag | A | A | −37 % medido; 98,7 % ilustrativo [H/O] |
| S24 | Tool Search / carga diferida | E | Ag | A | B | ~−85 % en definiciones; mejora la selección [H] |
| S25 | Conjunto mínimo de herramientas sin solapes | E | Ag | M | M | Menos definiciones y menos confusión [H] |
| S26 | Preferir CLI y desactivar MCP sin uso | E | Cód | M | B | Sin listado por herramienta [H] |
| S27 | Filtrar o truncar la salida de herramientas | E (D) | Ambos | A | B | De decenas de miles a cientos de tokens [H] |
| S28 | Interfaz agente-entorno acotada (estilo SWE-agent) | E | Ag | M | M | Visor de 100 líneas: 18 % de resolución frente a 12,7 % con archivo completo [H] |
| S29 | Descripciones y ejemplos de herramientas de calidad | E | Ag | M | B | Precisión de parámetros del 72 % al 90 % [H] |
| S32 | Edición diff / search-replace | F | Cód | A* | B | −30 % en archivos largos; *en archivos cortos puede costar más [H] |
| S33 | Predicted Outputs (OpenAI) | F | Cód | Nulo o negativo en tokens; A en latencia | M | Los tokens rechazados se facturan [H] |
| S-F1 | Control de longitud (max_tokens, stop, sin preámbulos) | F | Ambos | M | B | La salida es el token más caro [H] |
| S-F2 | Structured outputs / JSON Schema | F | Ag | B–M | B | Elimina los reintentos por error de parseo [H] |
| S-F3 | Pedir solo el código cambiado | F | Cód | M | B | No repetir contexto [O] |
| S34 | Delegar tareas verbosas a subagentes | G (D) | Ambos | A (orquestador) | M | Aísla el ruido, pero sube el total [H] |
| S35 | Dimensionar el esfuerzo multiagente | G | Ag | A | M | Multiagente ≈15×, equipos ≈7× [H] |
| S36 | Workflow determinista antes que agente | G | Ambos | A | M | Agentless: 0,34–0,70 $/issue [H] |
| S37 | Planificar, verificar y corregir pronto | G | Cód | M | B | Evita retrabajo [H] |
| S38 | Medición y gobernanza (S38a–f) | H | Ambos | M (indirecto) | B | Sin medir no se puede validar el ahorro [H] |

---

<a id="sec-4"></a>
## 4. Matriz de priorización

**Método:**
- Puntuación = impacto / esfuerzo, con A=3, M=2, B=1.
- A igualdad de puntuación, se ordena por solidez de la evidencia.
- La columna "Condición" indica cuándo la prioridad cambia.

| Prioridad | Estrategia | Impacto | Esfuerzo | Ratio | Evidencia | Condición / advertencia |
|---|---|---|---|---|---|---|
| 1 | S1 Caché de prefijos | A | B | 3,0 | [H] fuerte | Solo por encima del mínimo cacheable del modelo |
| 2 | S2 Prompt amigable con la caché | A | B | 3,0 | [H] fuerte | Imprescindible si se aplica S1 |
| 3 | S16 Limpiar/enmascarar resultados antiguos | A | B | 3,0 | [H] fuerte | Rompe la caché: usar un umbral mínimo de tokens liberados |
| 4 | S27 Filtrar salida de herramientas | A | B | 3,0 | [H] | Conservar el código de salida |
| 5 | S17 Reiniciar contexto entre tareas | A | B | 3,0 | [H] | Guardar el estado antes (S19) |
| 6 | S7 *Effort* / presupuesto de thinking | A | B | 3,0 | [H] | Fijarlo por sesión, no por turno |
| 7 | S6 Modelo por rol | A | B | 3,0 | [H] | Medir coste por tarea, no por token |
| 8 | S24 Tool Search / carga diferida | A | B | 3,0 | [H] | Útil con ≥10 herramientas o >10K tokens de definiciones |
| 9 | S10 Prompts específicos | A | B | 3,0 | [H] cualitativa | No sirve para exploración |
| 10 | S15 Compactación | A | B | 3,0 | [H] | Compactar con la caché caliente |
| 11 | S32 Edición diff | A* | B | 3,0 | [H] mixta | Solo en archivos largos con modelos grandes |
| 12 | S29 Descripciones y ejemplos de herramientas | M | B | 2,0 | [H] | — |
| 13 | S-F1 Control de longitud | M | B | 2,0 | [H] | Vigilar las truncaciones |
| 14 | S26 CLI frente a MCP | M | B | 2,0 | [H] | Ventaja menor si el MCP ya está diferido |
| 15 | S37 Planificar / verificar | M | B | 2,0 | [H] cualitativa | No en cambios triviales |
| 16 | S21 LSP / code intelligence | M | B | 2,0 | [H] cualitativa | Lenguajes tipados |
| 17 | S3 TTL de caché | M | B | 2,0 | [H] | Según las pausas entre peticiones |
| 18 | S4 Batch API | M | B | 2,0 | [H] | Solo para trabajo que no es en tiempo real |
| 19 | S11 Instrucciones de proyecto cortas | M | B | 2,0 | [H] en disputa | Evaluar antes y después |
| 20 | S38 Medición y gobernanza | M | B | 2,0 | [H] | **Requisito previo** del resto |
| 21 | S-F3 Solo código cambiado | M | B | 2,0 | [O] | Requiere un aplicador fiable |
| 22 | S31 Formatos compactos | M | B | 2,0 | [H/C] | Solo con arrays grandes y uniformes |
| 23 | S8 Razonamiento conciso | M | B | 2,0 | [H] fuera de código | Sustituido por S7 en modelos con thinking |
| 24 | S14 Recuperación just-in-time | A | M | 1,5 | [H] | +latencia |
| 25 | S20 Mapa de repositorio | A | M | 1,5 | [H] | Repos medianos o grandes |
| 26 | S36 Workflow antes que agente | A | M | 1,5 | [H] | Solo tareas descomponibles |
| 27 | S34 Delegar a subagentes | A | M | 1,5 | [H] | Sube el total del sistema |
| 28 | S35 Dimensionar el multiagente | A | M | 1,5 | [H] | Research sí; escritura de código no |
| 29 | S12 Divulgación progresiva | M | M | 1,0 | [H] | — |
| 30 | S13 Altitud del system prompt | M | M | 1,0 | [H] cualitativa | — |
| 31 | S19 Memoria externa | M | M | 1,0 | [H] rendimiento | Sin dato aislado de ahorro de tokens |
| 32 | S25 Herramientas mínimas | M | M | 1,0 | [H] cualitativa | Rediseñar invalida la caché |
| 33 | S28 Interfaz agente-entorno acotada | M | M | 1,0 | [H] 2024 | Revalidar con modelos actuales |
| 34 | S-F2 Structured outputs | B–M | B | 1,0–2,0 | [H] | Ahorro = tasa de fallo previa × coste de reintento |
| 35 | S5 Routing / cascada | A | A | 1,0 | [H] | Decidir por tarea, no por turno |
| 36 | S18 Reducción de trayectoria | A | A | 1,0 | [H] | Harness propio |
| 37 | S23 Ejecución de código sobre herramientas | A | A | 1,0 | [H]/[O] | Sandbox; flujos con ≥3 llamadas |
| 38 | S22 RAG con reranking | M | A | 0,67 | [H] | Corpus > ventana o cambiante |
| 39 | S30 Compresión de prompts | M | A | 0,67 | [H] prosa | En código solo métodos estructurales |
| 40 | S9 Caché semántica | B–M | M | 0,5–1,0 | [H] FAQ | No para código dependiente del repo |
| 41 | S33 Predicted Outputs | B (tokens) | M | 0,5 | [H] | Solo latencia; incompatible con tools |

---

<a id="sec-5"></a>
## 5. Detalle de estrategias por categoría

Formato común para cada estrategia: **Qué / Cómo** · **Aplicar** · **No aplicar** · **Ahorro** · **Riesgos** · **Ejemplo** · **Validar / Señales de alarma**. Las fuentes de cada afirmación están en la [sección 11](#sec-11).

<a id="cat-a"></a>
### A. Reutilización y precio

**Por qué importa.** En agentes, entre el 99 % y el 99,3 % de los tokens son de entrada (proporción de 100:1 a 150:1). Descontar hasta un 90 % sobre la parte repetida es la palanca económica más grande [H]. Manus considera la tasa de acierto de caché "la métrica más importante" de un agente en producción [H].

#### S1 — Caché de prefijos

- **Qué / Cómo.** El proveedor guarda el estado calculado de un prefijo idéntico.

| Aspecto | Anthropic | OpenAI | Gemini |
|---|---|---|---|
| Lectura | 0,1× base (0,05× Opus 5.5; 0,025× Fable/Mythos 5.1) | 0,1× ("hasta −90 %") | 10 % del precio de entrada |
| Escritura | 1,25× (TTL 5 min) / 2× (TTL 1 h) | 1,25× en GPT-5.6+ según la documentación actual [PV en modelos anteriores] | Explícita: almacenamiento por hora |
| Activación | Breakpoints `cache_control` (máx. 4) o caché automática | Automática desde 1.024 tokens | Implícita automática (2.5+) o explícita |
| Mínimo cacheable | 512–4.096 según modelo | 1.024 | 2.048–4.096 |
| Orden | tools → system → messages | prefijo exacto | prefijo exacto |

- **Aplicar.** Prefijos largos y estables reutilizados dentro del TTL: system prompt + herramientas de un agente, documentación del repo, bucles de herramientas.
- **No aplicar.** Prompts por debajo del mínimo (se ignoran sin error). Prefijos de un solo uso: en Anthropic, escribir sin leer después cuesta un +25 %.
- **Ahorro.** Hasta −90 % en la parte cacheada. −41 a −80 % del coste total y −13 a −31 % de TTFT en agentes de larga duración [H]. Punto de equilibrio: 1 escritura + 1 lectura cuesta 1,35× frente a 2× sin caché.
- **Riesgos.** Cachear todo el contexto sin control puede aumentar la latencia [H]. En peticiones paralelas simultáneas no hay aciertos hasta que empieza la primera respuesta [H].
- **Ejemplo.**
```json
{
  "model": "claude-opus-5-5",
  "tools": ["...definiciones estables, orden fijo..."],
  "system": [
    {"type": "text", "text": "<reglas del agente + convenciones del repo>",
     "cache_control": {"type": "ephemeral", "ttl": "1h"}},
    {"type": "text", "text": "<resumen de arquitectura por sesión>",
     "cache_control": {"type": "ephemeral"}}
  ],
  "messages": ["...historial append-only..."]
}
```
- **Validar.** Tasa de acierto de caché por turno, coste por tarea y TTFT p50/p95.
- **Señal de alarma.** Que el equipo no actualice un system prompt obsoleto "para no romper la caché".

#### S2 — Prompt amigable con la caché

- **Qué / Cómo.** Maximizar el prefijo común:
  - estable primero, dinámico al final;
  - historial solo por el final (append-only);
  - serialización determinista (claves JSON ordenadas);
  - no cambiar herramientas, modelo, *effort* ni thinking a mitad de sesión.

  En Anthropic, cambiar herramientas invalida todo; cambiar `tool_choice`, imágenes, thinking o *effort* invalida los mensajes [H].
- **Aplicar.** Siempre que se use S1.
- **No aplicar.** Cuando reordenar empeore la precisión de forma medible (efecto de recencia) [PV].
- **Ahorro.** Es la diferencia entre ~0 % de aciertos y el rango del 41–80 % [H].
- **Riesgos.** Obliga a no retirar herramientas dinámicamente (alternativa: enmascararlas). Choca con la categoría D.
- **Ejemplo.**
```text
[TOOLS: lista fija, orden alfabético, JSON con claves ordenadas]
[SYSTEM: rol, reglas, estilo]                         <- breakpoint 1h
[CONTEXTO REPO: árbol + instrucciones del proyecto]   <- breakpoint 5m
[HISTORIAL append-only; nunca editar turnos previos]
[ÚLTIMO USER: tarea + fecha/hora + git status]         <- lo dinámico, al final
Anti-patrón: "Fecha: 2026-09-24T10:31:07" en la primera línea del system prompt.
```
- **Validar.** Caídas bruscas de la tasa de acierto en un turno concreto. Diff del prefijo serializado entre turnos.

#### S3 — TTL según el patrón de uso

- **Qué / Cómo.** Elegir TTL de 5 min (1,25×) o 1 h (2×) en Anthropic, o la retención extendida de 24 h en OpenAI. Cada lectura renueva el TTL. El *keepalive* óptimo es el máximo que permite el TTL (~4 min), no 30 s. Deja de compensar tras ~46 min de pausa en Anthropic y ~36 min en OpenAI [H].
- **Aplicar.** TTL de 1 h con pausas humanas de 5–60 min, en batch y en subagentes de más de 5 min.
- **No aplicar.** Tráfico continuo (basta con 5 min). Pausas largas o imprevisibles.
- **Ahorro.** Mantener la caché caliente puede abaratar hasta 12,5× la petición siguiente [H].
- **Ejemplo.**
```python
def elegir_ttl(gap_p90_s):
    if gap_p90_s < 280:  return "5m"   # tráfico continuo
    if gap_p90_s < 3300: return "1h"   # pausas humanas
    return None                        # no cachear
```
- **Validar.** Distribución de tiempos entre peticiones y coste por sesión.

#### S4 — Batch API

- **Qué / Cómo.** −50 % en entrada y salida a cambio de latencia de hasta 24 h (Anthropic, OpenAI y Gemini) [H]. Se acumula con la caché, pero los aciertos en batch son *best-effort* (30–98 %). En batch se recomienda TTL de 1 h [H].
- **Aplicar.** Generación masiva de tests, migraciones fichero a fichero, docstrings, evaluaciones y LLM-as-judge, revisiones nocturnas.
- **No aplicar.** Bucles agénticos interactivos. Requisitos de latencia.
- **Riesgos.** Peticiones que expiran. Los resultados se retienen 29 días, lo que afecta a cumplimiento y RGPD [H].
- **Ejemplo.**
```python
reqs = [{"custom_id": f"test-{f}",
         "params": {"model": MODEL, "max_tokens": 4000,
                    "system": [{"type": "text", "text": GUIA_TESTS,
                                "cache_control": {"type": "ephemeral", "ttl": "1h"}}],
                    "messages": [{"role": "user", "content": leer(f)}]}}
        for f in modulos_sin_tests]
client.messages.batches.create(requests=reqs)
```
- **Validar.** Coste por unidad, porcentaje de peticiones expiradas y acierto de caché dentro del lote.

#### S9 — Caché semántica de respuestas

- **Qué / Cómo.** Guardar pares consulta/respuesta y devolver la respuesta si una consulta nueva es similar según embeddings (GPTCache). vCache sustituye el umbral fijo por uno aprendido por consulta con error acotado [H].
- **Aplicar.** FAQs sin estado (asistente de documentación interna).
- **No aplicar.** Generación de código dependiente del fichero, la rama o el commit: devolver código de otra rama es un fallo silencioso [O]. Pasos intermedios de agentes.
- **Ahorro.** Hasta −68,8 % de llamadas en consultas tipo FAQ [H]. Las cifras "10×" y "30–70 %" que circulan son de marketing o de blogs [PV].
- **Riesgos.** Respuestas obsoletas, ataques de colisión y fugas entre usuarios [H].
- **Ejemplo.** Particionar la clave por `hash(repo_commit, model, system_version)` y aplicar TTL.

<a id="cat-b"></a>
### B. Selección de modelo y cómputo

**Por qué importa.** El precio por token varía hasta dos órdenes de magnitud entre modelos [H]. El razonamiento se factura como salida [H]. Además, los modelos difieren en más de 1,5M de tokens de media en la misma tarea agéntica [H]: **el precio por token no es el coste por tarea**.

#### S5 — Routing / cascada

- **Qué / Cómo.** Hay dos variantes:
  - Un **router** decide antes de generar (RouteLLM: routers entrenados con preferencias).
  - Una **cascada** prueba primero el modelo barato y escala si no se supera un umbral o una verificación (FrugalGPT).

  En código agéntico, SWE-Router usa la trayectoria parcial del modelo barato para decidir si escala [H].
- **Aplicar.** Tráfico de dificultad heterogénea y gran volumen, cuando hay un verificador barato (tests, linter, compilación).
- **No aplicar.** Sesiones largas cacheadas con cambios de modelo frecuentes. Volumen bajo. Tareas homogéneamente difíciles.
- **Ahorro.**
  - RouteLLM: −85 % en MT Bench, −45 % en MMLU, −35 % en GSM8K con el 95 % de la calidad de GPT-4. El paper es más prudente y habla de ">2×"; el −85 % depende de la línea base elegida [H].
  - FrugalGPT: hasta −98 % en sus datasets, que no son de código [H/PV].
  - SWE-bench Verified (100 casos): el router entrenado costó 25,66 $ y resolvió 75; Opus solo, 54,73 $ y 74 (−53 %). **El router basado en reglas costó 172,56 $: 3× más que no enrutar**, por las reescrituras de caché [H]. La muestra es pequeña [O].
- **Riesgos.** Rompe la caché, envía casos difíciles al modelo débil y añade el coste del propio router.
- **Ejemplo (cascada con permanencia para no romper la caché).**
```python
def solve(task, session):
    if session.tier is None:  # decidir UNA vez por tarea
        session.tier = "large" if router.p_hard(task) > 0.6 else "small"
    out = llm(session.tier, task, cache_prefix=session.prefix)
    if session.tier == "small" and not run_tests(out):
        session.tier = "large"                     # escalar una sola vez, sin alternar
        out = llm("large", task + failing_tests(out))
    return out
```
- **Validar.** Coste por tarea resuelta, % de llamadas al modelo fuerte, tasa de acierto de caché antes y después.
- **Señales de alarma.** Escalados tardíos y aumento de `cache_creation`.

#### S6 — Modelo por tipo de tarea o subagente

- **Qué / Cómo.** Routing estático por rol:
  - planificador o arquitecto con modelo grande;
  - implementación con modelo medio;
  - búsqueda, lectura y resumen con modelo pequeño.

  En Claude Code se configura con `model:` en el frontmatter del subagente, `CLAUDE_CODE_SUBAGENT_MODEL` y el alias `opusplan` (Opus planifica, Sonnet ejecuta) [H].
- **Aplicar.** Arquitecturas orquestador-subagentes. Subtareas de mucho volumen de lectura y poca decisión.
- **No aplicar.** Subtareas cuyo error se propaga sin verificar (un resumen erróneo contamina al orquestador). Tareas cortas donde el coste de arrancar el subagente domina.
- **Ahorro.** No hay cifra pública del ahorro por usar Haiku en subagentes [PV]. Dato relacionado: "Upgrading to Claude Sonnet 4 is a larger performance gain than doubling the token budget on Sonnet 3.7" [H]. Elegir bien el modelo puede valer más que darle más tokens.
- **Ejemplo.**
```markdown
---
name: log-scout
description: Busca errores en logs y devuelve solo un resumen de <30 líneas
model: haiku
tools: Read, Grep, Bash
---
Devuelve únicamente: fichero:línea, mensaje, frecuencia. No propongas fixes.
```
- **Señal de alarma.** El orquestador relee lo que el subagente debía haber resumido.

#### S7 — *Effort* / presupuesto de razonamiento

- **Qué / Cómo.**
  - OpenAI: `reasoning.effort` (none/minimal/low/medium/high/…, según el modelo) y `max_output_tokens` como techo [H].
  - Claude: `/effort`, `--effort`, `effortLevel`.
  - `MAX_THINKING_TOKENS` solo aplica a modelos con presupuesto fijo; los de razonamiento adaptativo lo ignoran [H]. El nivel `max` es "prone to overthinking" [H].
- **Aplicar.** *Effort* bajo en tareas mecánicas (renombrados, boilerplate, subagentes de búsqueda). Alto en depuración compleja y en diseño.
- **No aplicar.** Bajarlo en diseño o en depuración no trivial. Cambiarlo a mitad de una conversación cacheada: invalida los mensajes [H].
- **Ahorro.** Opus 4.5 con *effort* medio igualó a Sonnet 4.5 en SWE-bench Verified usando un −76 % de tokens de salida. Con *effort* máximo lo superó por 4,3 puntos usando −48 % [H, cifra del proveedor].
- **Ejemplo.**
```bash
claude --effort medium            # fijado por sesión, no por turno (preserva la caché)
export MAX_THINKING_TOKENS=8000   # solo en modelos con presupuesto fijo
```
- **Señales de alarma.** Ciclos editar → fallar test → reeditar, y respuestas `incomplete`.

#### S8 — Razonamiento conciso

- **Qué / Cómo.**
  - *Chain of Draft*: pasos de ~5 palabras con ejemplos few-shot [H].
  - Sobrerrazonamiento: las mitigaciones eficaces (SimPO, RL) requieren entrenar el modelo [H].
- **Aplicar.** Razonamiento auxiliar en modelos sin thinking nativo (clasificar, decidir una ruta).
- **No aplicar.** En zero-shot (en Claude, solo +3,6 % sobre respuesta directa), en modelos de menos de 3B parámetros, o como sustituto del thinking nativo (para eso está S7).
- **Ahorro y coste.** 7,6 % de los tokens de CoT, pero la precisión en GSM8K baja ~4 puntos (95,4 % → 91,1 % en GPT-4o) [H].
- **Evidencia en código:**
  - El paper de CoD no evalúa código [H].
  - ASAP −23,5 % de tokens en LiveCodeBench [H].
  - En SWE-bench, elegir trayectorias con menos sobrerrazonamiento dio +30 % de rendimiento y −43 % de coste [H].
  - La aplicabilidad por prompt en agentes de código de producción sigue [PV].
- **Ejemplo.**
```text
Think step by step, but keep only a minimum draft for each thinking step,
with 5 words at most. Return the answer after a separator ####.
```

<a id="cat-c"></a>
### C. Construcción del contexto de entrada

**Por qué importa.** Todo lo que se carga al inicio se paga en cada turno (con caché, a tarifa reducida, pero se paga). Cada token extra consume el "presupuesto de atención" del modelo [H].

#### S10 — Prompts específicos

- **Qué / Cómo.** Indicar archivo, símbolo y resultado verificable. "Add input validation to the login function in auth.ts" frente a "improve this codebase" [H].
- **No aplicar.** En exploración o auditoría; ahí conviene plan mode o un subagente explorador (G).
- **Ahorro.** Cualitativo ("minimal file reads") [H]. Cada archivo que no se lee es un resultado de herramienta que no se reenvía en los turnos siguientes [O].
- **Ejemplo.**
```text
En src/auth/login.ts, función validateLogin(): rechaza emails sin "@" y contraseñas
< 12 caracteres con AuthError("INVALID_INPUT"). No toques otros archivos.
Verifica con: npm test -- tests/auth/login.test.ts
```
- **Validar.** Llamadas Read/Grep por tarea y turnos hasta tener los tests en verde.

#### S11 — Archivo de instrucciones del proyecto corto

- **Qué / Cómo.** Dejar solo lo esencial en el archivo que siempre se carga y mover el resto a mecanismos condicionales:

| Herramienta | Límite recomendado | Carga condicional |
|---|---|---|
| Claude Code | CLAUDE.md < 200 líneas | CLAUDE.md de subdirectorio, `.claude/rules/` con `paths:` (los imports `@path` se cargan siempre y no ahorran) |
| Cursor | < 500 líneas | Reglas "Apply Intelligently" o por glob |
| Copilot | — | `.github/instructions/*.instructions.md` con `applyTo` |
| AGENTS.md | — | Formato abierto con más de 20 herramientas; se aplica el archivo más cercano |

- **Evidencia en disputa.** Un estudio empírico (preprint) concluye que los archivos de contexto "does not generally improve task success rates, while increasing inference cost by over 20 %". Las instrucciones específicas sí se siguen; los resúmenes de repositorio no ayudan [H/PV].
- **Resolución.** Incluir solo comandos de build y test, convenciones no estándar y reglas del tipo "haz siempre X". Evaluar antes y después.
- **Ejemplo.**
```markdown
# CLAUDE.md (≈40 líneas)
- Build: pnpm build · Test: pnpm test -- <ruta>
- TS strict; no usar `any`; errores con Result<T,E> (src/lib/result.ts)
- Migraciones DB: ver skill `db-migrations`
# Compact instructions
Al compactar preserva: ficheros modificados, último test fallido literal, decisiones.
```
- **Señal de alarma.** El agente vuelve a violar convenciones que antes respetaba.

#### S12 — Divulgación progresiva (skills bajo demanda)

- **Qué / Cómo.** Tres niveles:
  1. Solo `name` + `description` al inicio.
  2. `SKILL.md` completo cuando la skill es relevante.
  3. Archivos enlazados solo si hacen falta [H].

  El mismo principio aplica a herramientas (ver S24).
- **No aplicar.** A conocimiento que se usa en casi todos los turnos.
- **Ahorro.** No hay cifra publicada para skills. En herramientas, ~−85 % del contexto inicial [H].
- **Riesgos.** Una descripción pobre hace que la skill no se active. Cargarla a mitad de sesión no invalida el prefijo; cambiar herramientas sí [H].
- **Validar.** Tokens base de la sesión y activación correcta de cada skill (falsos negativos y positivos).

#### S13 — System prompt a la altitud correcta + ejemplos canónicos

- **Qué / Cómo.** Heurísticas fuertes, ni lógica if/else rígida ni guía vaga. Pocos ejemplos, diversos y canónicos, en vez de listas de casos límite [H].
- **Riesgos.** El modelo imita los ejemplos [C]. Cambiar el system prompt invalida la caché.
- **Ejemplo.**
```text
<rol>Revisor de PRs de un backend Go.</rol>
<heurísticas>Prioriza corrección > seguridad > rendimiento > estilo.
Si no hay tests para una rama nueva, pídelos.</heurísticas>
<ejemplos><ej>diff: ... → "BLOCKER: error ignorado en L42"</ej>
<ej>diff: ... → "NIT: nombre poco descriptivo `x`"</ej></ejemplos>
```

#### S14 — Recuperación just-in-time por identificadores

- **Qué / Cómo.** Mantener referencias ligeras (rutas, queries, URLs) y cargar el contenido con herramientas cuando se necesita. Claude Code lo combina con un enfoque híbrido: instrucciones por adelantado y glob/grep en el momento [H].
- **No aplicar.** Corpus pequeño y estable (Anthropic sugiere incluir entera una base de < 200K tokens, cacheada). Casos donde la latencia es crítica: explorar en tiempo de ejecución es más lento [H].
- **Riesgos.** Más llamadas a herramientas y búsquedas en bucle.
- **Ejemplo.**
```text
"Esquema en db/schema.sql; queries en queries/metrics/*.sql; usa `rg -n <símbolo> src/`
antes de abrir archivos y lee solo los rangos de línea relevantes."
```

#### S20 — Mapa de repositorio

- **Qué / Cómo.** Aider analiza el código con tree-sitter, construye un grafo de dependencias y usa un algoritmo de ranking de grafos para quedarse con las firmas más referenciadas dentro de un presupuesto (`--map-tokens`, 1K por defecto y flexible) [H]. Que sea PageRank se documenta en la comunidad y en el código fuente [PV].
- **No aplicar.** Repos minúsculos, lenguajes sin gramática tree-sitter, o si el agente ya navega bien con LSP.
- **Riesgos.** Si el mapa cambia entre turnos, se pierde la caché [O].
- **Ejemplo.** `aider --map-tokens 2048 --map-refresh auto src/billing/invoice.py`

#### S22 — RAG con reranking y ordenación

- **Qué / Cómo.** Búsqueda híbrida (BM25 + densa), reranker, top-k pequeño y los fragmentos más relevantes en los extremos del bloque (curva en U de *lost in the middle*) [H]. Con Contextual Retrieval, los fallos de recuperación bajan un 35 % (embeddings contextuales), un 49 % (+BM25) y un 67 % (+reranking) [H].
- **No aplicar.** Corpus de menos de 200K tokens y estables (van enteros y cacheados). Navegación exacta de código: grep o LSP es más preciso [C].
- **Riesgos.** Inyectar los fragmentos al inicio rompe la caché; deben ir después del prefijo estable [H].
- **Ejemplo.**
```python
top = rerank(q, hybrid_search(q, bm25_k=100, dense_k=100))[:8]
ordered = [top[0]] + top[2:][::-1] + [top[1]]   # más relevantes en los extremos
prompt = STABLE_PREFIX + "<docs>" + fmt(ordered) + "</docs>\n" + q
```

#### S30 — Compresión de prompts

- **Qué / Cómo.** LLMLingua comprime hasta 20× en razonamiento y conversación; LLMLingua-2 entre 2× y 5×, siendo de 3 a 6 veces más rápido [H].
- **No aplicar** sobre código literal (identificadores, indentación, diffs). Para código hay métodos estructurales: LongCodeZip llega hasta 5,6× sin pérdida y obtiene 75,3 frente a 59,3 de LongLLMLingua en RepoQA [H].
- **Riesgos.** Prompt ilegible. Si la compresión no es determinista, destruye la caché.
- **Ejemplo.**
```python
docs_c = compressor.compress_prompt(prose_docs, rate=0.4, force_tokens=["\n", "`"])
prompt = STABLE_PREFIX + docs_c["compressed_prompt"] + CODE_SNIPPETS_RAW + task  # el código va sin comprimir
```

#### S31 — Formatos de datos compactos

- **Qué / Cómo.** TOON declara las claves una vez por array uniforme. Según su propio benchmark: −40 % de tokens frente a JSON con precisión similar [H, autorreportado].
- **Matiz del estudio independiente.**
  - El "prompt tax" (instrucciones para explicar el formato) se come el ahorro en contextos cortos.
  - JSON plano obtuvo la mejor precisión global.
  - La decodificación restringida gastó menos tokens de salida [H].
- **No aplicar.** Datos anidados o irregulares, payloads pequeños, o salidas que consume un parser.
- **Ejemplo.**
```text
metrics[2]{id,svc,p95}:
  1,api,210
  2,db,35
```

<a id="cat-d"></a>
### D. Gestión del contexto en el tiempo

**Por qué importa.** El reenvío acumulativo hace que la entrada crezca de forma cuadrática. Y cualquier reescritura del historial invalida la caché desde ese punto [H]. Estas técnicas cambian ahorro por turno en el futuro por un coste puntual de reconstrucción de caché.

#### S15 — Compactación del historial

- **Qué / Cómo.** Sustituir los turnos antiguos por un resumen estructurado:
  - Claude Code: `/compact <instrucciones>` o auto-compact.
  - API de Anthropic (beta): compactación bajo demanda o por umbral (`compact_20260112`, trigger 150K por defecto, `instructions` que sustituyen el prompt de resumen, coste en `usage.iterations`) [H].
  - OpenAI: `/responses/compact`, que produce un resumen cifrado y opaco [H].

  Tras compactar, Claude Code recarga CLAUDE.md, la memoria y hasta 5 ficheros recientes. Las reglas con `paths:` y los CLAUDE.md anidados se pierden en el resumen [H].
- **Aplicar.** Una sola tarea larga que necesita continuidad, en pausas naturales y **con la caché caliente**. Con la caché caliente, compactar cuesta una fracción; con la caché fría, reprocesa todo el contexto [H].
- **No aplicar.** Al cambiar de tarea: `/clear` no cuesta nada. Para abandonar un camino: `/rewind` vuelve a un prefijo ya cacheado.
- **Ahorro.** En el ejemplo documentado, una compactación de 180K tokens deja el siguiente mensaje en 23K (~8× menos por turno) [H/O]. No hay porcentaje global oficial [PV].
- **Ejemplo.**
```python
context_management = {"edits": [{"type": "compact_20260112",
  "trigger": {"type": "input_tokens", "value": 100000},
  "pause_after_compaction": True,
  "instructions": "Preserva firmas, nombres, errores abiertos y decisiones técnicas."}]}
```
- **Señales de alarma.** El agente vuelve a preguntar decisiones ya tomadas, relee ficheros o reintroduce bugs corregidos.

#### S16 — Limpiar o enmascarar resultados antiguos de herramientas

- **Qué / Cómo.** API de Anthropic: `clear_tool_uses_20250919` con estos parámetros [H]:
  - `trigger`: 100K por defecto;
  - `keep`: los últimos 3 usos;
  - `clear_at_least`: mínimo de tokens liberados para compensar la ruptura de caché;
  - `exclude_tools`;
  - `clear_tool_inputs`.

  Existe también `clear_thinking_20251015`. Genéricamente: *observation masking* en SWE-agent y OpenHands [H]. Anthropic la considera la forma de compactación "más segura y ligera" [H].
- **Aplicar.** Agentes con muchas llamadas a herramientas cuyos resultados caducan (búsquedas, grep, tests ya corregidos).
- **No aplicar.** Resultados irrepetibles (APIs con efectos secundarios). Sesiones por debajo del umbral.
- **Ahorro.**
  - −84 % de tokens y +29 % de rendimiento en búsqueda web de 100 turnos [H, evaluación interna].
  - En SWE-bench Verified, enmascarar **reduce el coste a la mitad** frente a no gestionar el contexto, e iguala o supera al resumen con LLM [H].
- **Ejemplo.**
```python
context_management = {"edits": [
  {"type": "clear_thinking_20251015", "keep": {"type": "thinking_turns", "value": 2}},
  {"type": "clear_tool_uses_20250919",
   "trigger": {"type": "input_tokens", "value": 50000},
   "keep": {"type": "tool_uses", "value": 5},
   "clear_at_least": {"type": "input_tokens", "value": 10000},
   "exclude_tools": ["memory"]}]}
```
- **Señales de alarma.** Aumentan los Read o grep idénticos, o el agente vuelve a lanzar tests cuyo resultado ya tenía.

#### S17 — Reiniciar el contexto entre tareas

- **Qué / Cómo.** `/clear` o una sesión nueva. Se recargan el system prompt y las instrucciones del proyecto, y la capa de sistema puede seguir saliendo de caché [H]. `/rename` antes de limpiar y `/resume` para volver [H].
- **No aplicar.** A mitad de tarea con estado que no se ha guardado fuera (primero S19 o S15).
- **Ahorro.** No hay porcentaje oficial. Anthropic atribuye el gasto alto inesperado sobre todo a "long sessions that were never cleared" [H].
- **Ejemplo.**
```text
/rename feat-auth-validacion
# actualizar NOTES.md con el estado
/clear
> Lee NOTES.md y aborda la tarea #2: paginación en /api/orders
```

#### S18 — Reducción de trayectoria en inferencia (AgentDiet)

- **Qué / Cómo.** Un modelo barato actúa como "reflector" y reescribe pasos anteriores quitando información inútil, redundante o caducada. Trabaja con una ventana deslizante (a=2, b=1) y solo actúa sobre pasos de más de 500 tokens [H].
- **Aplicar.** Harness propio de agente de código con trayectorias largas.
- **No aplicar.** Herramientas cerradas sin control del bucle, o trayectorias cortas.
- **Ahorro.** −39,9 a −59,7 % de tokens de entrada y **−21,1 a −35,9 % del coste total**, ya descontada la sobrecarga del reflector. La tasa de resolución varía entre −1 y +2 puntos (SWE-bench Verified y Multi-SWE-bench Flash) [H].
- **Riesgos.** Rompe la caché desde el paso reescrito. Un reflector que se equivoque puede borrar pruebas necesarias.
- **Ejemplo.**
```python
for s in agent_loop():
    tgt = s - 2
    if tgt >= 0 and tokens(traj[tgt]) > 500:
        traj[tgt] = reflector.reduce(traj[tgt], context=traj[tgt-1:s+1],
            rules="elimina inútil/redundante/caducado; conserva rutas, errores y diffs")
```

#### S19 — Memoria externa y notas estructuradas

- **Qué / Cómo.**
  - Memory tool de Anthropic (`memory_20250818`, lado cliente; hay que proteger contra *path traversal*).
  - Patrón NOTES.md.
  - Jerarquía de memoria virtual de MemGPT.
  - "Compresión restaurable" de Manus: conservar la URL o ruta y descartar el contenido [H].
- **Aplicar.** Trabajo que abarca varias sesiones, y como complemento de S15 y S17.
- **No aplicar.** Tareas atómicas de una sola sesión.
- **Ahorro.** El +39 % publicado es de **rendimiento**, combinando memoria y context editing. No hay dato aislado de ahorro de tokens [PV].
- **Ejemplo.**
```markdown
# NOTES.md
## Estado: 3/5 features verificadas E2E
## Decisiones: ORM=SQLAlchemy 2.x; sin mocks en tests de integración
## Abierto: test_orders_pagination falla (off-by-one)
## Siguiente: feature #4 export CSV
```
- **Señal de alarma.** El agente actúa según notas obsoletas.

<a id="cat-e"></a>
### E. Herramientas e interfaz agente-entorno

**Por qué importa.** Las herramientas consumen tokens por tres vías: definiciones (en cada petición), invocación (un ciclo de inferencia por llamada) y resultados (se reenvían en todos los turnos posteriores). Además, la selección de herramientas empeora a partir de 30–50 herramientas disponibles [H].

#### S21 — Code intelligence / LSP

- **Qué / Cómo.** Plugins LSP (pyright, typescript, gopls, rust-analyzer) con ir a definición, referencias y diagnósticos. Una llamada sustituye a un grep más varias lecturas, y los errores de tipo se detectan sin compilar [H].
- **No aplicar.** Lenguajes dinámicos sin buen servidor, monorepos mal configurados, o sesiones cloud (no arrancan LSP de plugins) [H].
- **Ahorro.** No hay cifra publicada [PV]. Estimación: 5K–40K tokens por consulta de navegación [O].
- **Ejemplo.** `/plugin install pyright-lsp@claude-plugins-official` y en el prompt: "usa findReferences, no grep".

#### S23 — Ejecución de código sobre herramientas

- **Qué / Cómo.** El modelo escribe código que invoca las herramientas y agrega los resultados. Solo el resultado final entra en el contexto.
  - *Programmatic Tool Calling* (API de Anthropic, en GA): `allowed_callers: ["code_execution_20260120"]` [H].
  - *Code execution with MCP* (patrón de arquitectura): servidores expuestos como árbol de ficheros, con divulgación progresiva [H].
- **Aplicar.** Flujos con 3 o más llamadas dependientes, agregación de datos grandes, llamadas en paralelo.
- **No aplicar.** Llamadas únicas, o flujos donde el modelo debe razonar sobre cada resultado intermedio. En τ²-bench, PTC no mejoró el resultado y costó un +8 % [C/PV].
- **Ahorro.**
  - PTC: de 43.588 a 27.297 tokens (**−37 %**); datos intermedios de 200KB reducidos a 1KB; mejora de precisión [H].
  - 150K → 2K (−98,7 %): **ejemplo ilustrativo**, no benchmark [O].
  - Terceros: −78,5 % [C].
- **Riesgos.**
  - Requiere sandbox, límites de recursos y monitorización.
  - +7 % de latencia en un test con un solo servidor [C].
  - PTC no es elegible para ZDR, no está en Bedrock ni en Vertex, y es incompatible con `strict: true` [H].
- **Ejemplo.**
```json
{"tools": [
  {"type": "code_execution_20260120", "name": "code_execution"},
  {"name": "get_ci_runs", "description": "Lista ejecuciones de CI de un repo",
   "input_schema": {"type": "object", "properties": {"repo": {"type": "string"}}, "required": ["repo"]},
   "allowed_callers": ["code_execution_20260120"]}
]}
```

#### S24 — Tool Search / carga diferida

- **Qué / Cómo.** `defer_loading: true` en las herramientas poco frecuentes, más una herramienta de búsqueda (regex o BM25) que devuelve referencias y las expande. El prefijo no cambia, así que la caché se conserva [H]. En Claude Code, las herramientas MCP se difieren por defecto (`ENABLE_TOOL_SEARCH=auto`) [H].
- **Aplicar.** 10 o más herramientas, definiciones de más de 10K tokens, o varios servidores MCP.
- **No aplicar.** Menos de 10 herramientas, o herramientas que se usan en todas las peticiones.
- **Ahorro.** De ~72K a ~8,7K tokens de definiciones (~−85/88 %). Precisión de selección: Opus 4 del 49 % al 74 %, Opus 4.5 del 79,5 % al 88,1 % [H].
- **Riesgos.** Si la descripción no contiene las palabras clave, la herramienta "no existe" para el modelo. Añade un turno de búsqueda.
- **Ejemplo.**
```json
{"tools": [
  {"type": "tool_search_tool_bm25_20251119", "name": "tool_search_tool_bm25"},
  {"name": "github_create_pr", "description": "...", "input_schema": {}},
  {"name": "slack_post_message", "description": "...", "input_schema": {}, "defer_loading": true}
]}
```

#### S25 — Conjunto mínimo de herramientas sin solapes

- **Qué / Cómo.** Criterio: si un humano no sabe decir qué herramienta usar, el agente tampoco [H]. Consolidar (por ejemplo `schedule_event` en lugar de list_users + list_events + create_event) y agrupar con prefijos por servicio (`jira_search`) [H].
- **Riesgos.** Las herramientas "gordas" tienen esquemas más complejos (mitigar con S29). Rediseñar herramientas invalida toda la caché.
- **Ejemplo.** `list_files, read_file, read_file_lines, cat_file, get_file_content` pasan a ser `fs_read(path, start?, end?)` + `fs_search(query, glob?, max_results=50)`.

#### S26 — Preferir CLI y desactivar MCP sin uso

- **Qué / Cómo.** `gh`, `aws`, `gcloud` o `sentry-cli` no añaden listado por herramienta. `/mcp` para desactivar servidores y `/context` para ver qué ocupa el contexto [H].
- **Matiz.** Con el MCP diferido por defecto, la ventaja se reduce a los nombres y las instrucciones del servidor. La cifra de ~26K tokens del MCP de GitHub solo aplica si Tool Search está desactivado [H].
- **Ejemplo (CLAUDE.md).** "Para GitHub usa `gh ... --json <campos mínimos>`".

#### S27 — Filtrar o truncar la salida de herramientas

- **Qué / Cómo.**
  - Hooks `PreToolUse` que reescriben el comando para mostrar solo los fallos [H].
  - `MAX_MCP_OUTPUT_TOKENS` (25K por defecto): las salidas mayores se guardan en archivo y solo se pasa la ruta [H].
  - Diseño de herramientas con paginación y `response_format` concise/detailed (72 frente a 206 tokens) [H].
- **No aplicar.** Depuración de fallos intermitentes o de rendimiento, donde importa el contexto alrededor del error.
- **Ahorro.** De decenas de miles de tokens a cientos por log [H].
- **Ejemplo (hook para filtrar la salida de tests).**
```bash
#!/bin/bash
input=$(cat); cmd=$(echo "$input" | jq -r '.tool_input.command')
if [[ "$cmd" =~ ^(npm test|pytest|go test) ]]; then
  filtered="$cmd 2>&1 | grep -A 5 -E '(FAIL|ERROR|error:)' | head -100; echo \"EXIT=\${PIPESTATUS[0]}\""
  echo "$input" | jq --arg c "$filtered" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"allow",updatedInput:(.tool_input+{command:$c})}}'
else echo "{}"; fi
```
  La línea `EXIT=${PIPESTATUS[0]}` es una mejora propia [O] para no enmascarar el código de salida real.
- **Señal de alarma.** El agente vuelve a ejecutar sin filtro o lee el archivo completo.

#### S28 — Interfaz agente-entorno acotada (estilo SWE-agent)

- **Qué / Cómo.** Ablación del paper de SWE-agent (SWE-bench Lite, GPT-4 Turbo) [H]:

| Elemento | Variante | Resolución |
|---|---|---|
| Visor de archivo | 100 líneas | **18,0 %** |
| | 30 líneas | 14,3 % |
| | Archivo completo | 12,7 % |
| Búsqueda | Resumida (máx. 50 resultados) | **18,0 %** |
| | Iterativa | 12,0 % |
| Edición | Con linter | **18,0 %** |
| | Sin linter | 15,0 % |
| Historial | Colapsar lo anterior a las últimas 5 observaciones | **18,0 %** |
| | Historial completo | 15,0 % |

- **Lectura.** Acotar la salida **mejora la calidad y reduce tokens a la vez**.
- **Riesgos.** Los valores óptimos se midieron en 2024 y hay que revalidarlos con modelos actuales [PV].
- **Ejemplo.**
```python
def open_file(path, line=1, window=100): ...   # + "(N more lines below)"
def search_dir(term, max_results=50): ...      # si >50: "refina la búsqueda"
def edit(path, start, end, text): lint(); rollback_if_syntax_error()
```

#### S29 — Descripciones y ejemplos de herramientas de calidad

- **Qué / Cómo.** Descripciones que distingan bien entre herramientas y `input_examples` para convenciones que el schema no expresa [H]. Iterar con evaluaciones y con un agente que pruebe las herramientas.
- **Ahorro.** Precisión en parámetros complejos del 72 % al 90 %. −40 % de tiempo de tarea tras reescribir las descripciones [H]. El ahorro de tokens es indirecto (menos reintentos).
- **Riesgos.** Los ejemplos añaden tokens (mitigar con S24). No usar datos reales en los ejemplos.

<a id="cat-f"></a>
### F. Formato y control de la salida

**Por qué importa.**
- Un token de salida cuesta 5× uno de entrada en Anthropic y 4–8× en OpenAI [H].
- La latencia es aproximadamente proporcional a la salida: −50 % de salida ≈ −50 % de latencia, mientras que −50 % de prompt solo reduce entre un 1 % y un 5 % [H].
- En agentes, la salida de hoy es la entrada de mañana [O].
- La tensión: ahorrar salida solo compensa si no provoca reintentos.

#### S32 — Edición diff / search-replace frente a archivo completo

- **Qué / Cómo.**
  - Aider: formatos `whole`, `diff` (SEARCH/REPLACE), `udiff`, `editor-*` [H].
  - Anthropic: `str_replace_based_edit_tool`; `old_str` debe coincidir exactamente y ser único [H].
  - OpenAI: `apply_patch` (formato V4A) [H].
  - Patrón *apply-model*: un modelo potente redacta y uno rápido fusiona. Cursor reporta ~1000 tok/s con *speculative edits* [H].
- **Aplicar.** Archivos largos (más de 300 tokens) con cambios localizados, y modelos grandes. Con más de 300 tokens, FuncDiff usó 546 tokens frente a 648 de FullCode; la política adaptativa AdaEdit logra más de un −30 % de coste y latencia [H].
- **No aplicar.**
  - Archivos cortos: el ancla que localiza el cambio pesa y el diff puede costar más que el archivo entero [H].
  - Modelos pequeños o ajustados: la generación directa gana [H].
  - Diffs con números de línea: 21 % frente a 69 % [H].
- **Riesgos.**
  - Fallos de aplicación que obligan a reintentar.
  - En Aider, quitar el parcheo flexible multiplicó por 9 los errores [H].
  - El formato también cambia la "pereza" del modelo: con GPT-4 Turbo, udiff pasó de 20 % a 61 % [H].
- **Ejemplo.**
```python
fmt = "whole" if tokens(file) < 300 or est_change_ratio > 0.5 else "search_replace"
```
- **Validar.** Tokens de salida por edición aceptada, % de ediciones que se aplican al primer intento, reintentos.

#### S33 — Predicted Outputs (OpenAI)

- **Qué / Cómo.** El cliente envía en `prediction` el texto esperado; el servidor valida esos tokens en paralelo. Solo en Chat Completions y en modelos GPT-4o y 4.1 (no GPT-5.x) [H].
- **Tokens.** **No ahorra**: los tokens rechazados se facturan como completion [H]. Si hay más rechazados que aceptados, la latencia incluso empeora [H].
- **Incompatibilidades.** `tools`, `n>1`, `logprobs`, penalties y `max_completion_tokens` [H], así que no sirve en bucles agénticos.
- **Latencia.** La cifra de "3–5× más rápido" viene de un tercero comercial [PV].
- **Validar.** Ratio aceptados/(aceptados + rechazados) y latencia p50/p95.

#### S-F1 — Control de longitud de salida

- **Qué / Cómo.** `max_tokens` / `max_completion_tokens`, `stop_sequences`, y la instrucción "Respond directly without preamble" [H]. Si una respuesta se corta en `max_tokens` con un `tool_use` incompleto, hay que reintentar con un límite mayor [H].
- **No aplicar.** Cuando la explicación es el entregable. Topes bajos en generación de código largo.
- **Ejemplo.**
```json
{"max_tokens": 2048, "stop_sequences": ["</patch>"],
 "system": "Devuelve solo <patch>...</patch>. Sin preámbulo, sin resumen, sin explicar lo que no se pregunte."}
```
- **Validar.** % de respuestas con `stop_reason == max_tokens` y tasa de éxito.

#### S-F2 — Structured outputs / JSON Schema

- **Qué / Cómo.** Decodificación restringida por gramática: `output_config.format` en Anthropic, `json_schema` con `strict: true` en OpenAI [H]. En Anthropic, la gramática se cachea 24 h y **cambiar el formato invalida la caché** [H].
- **No aplicar.** Código largo dentro de strings JSON: el escapado infla los tokens y empeora la edición [H/O]. Esquemas recursivos (no soportados en Anthropic).
- **Ahorro.** Igual a la tasa de fallo de parseo previa × el coste de cada reintento [O].

#### S-F3 — Pedir solo el código cambiado

- **Qué / Cómo.** "Devuelve únicamente las funciones modificadas, completas, precedidas por `# file: <ruta>`". Es la base del *lazy edit* que luego fusiona un modelo *apply* [C].
- **Riesgos.** Que los marcadores `// ... existing code ...` acaben en el archivo final si no hay aplicador. La "pereza" es un modo de fallo documentado [H].

<a id="cat-g"></a>
### G. Arquitectura y orquestación

**Por qué importa.** La topología decide cuántas llamadas se hacen y cuánto contexto lleva cada una: chat 1×, agente ≈4×, multiagente ≈15× [H]. El arnés de orquestación por sí solo redujo un 38 % los tokens por tarea (de 14,2K a 8,8K) y un 41 % el coste, con calidad en paridad (22 tareas, 6 modelos) [H, preprint con arnés propietario: pendiente de replicación].

#### S34 — Delegar tareas verbosas a subagentes

- **Qué / Cómo.** El subagente arranca con un contexto limpio, sin el historial del orquestador, y devuelve un resumen de 1–2K tokens aunque haya consumido decenas de miles [H]. Los *forks* sí heredan el contexto [H].
- **Aplicar.** Salida voluminosa, trabajo autocontenido, investigación en paralelo, restricción de herramientas [H].
- **No aplicar.** Tareas con mucho ida y vuelta, fases que comparten mucho contexto, cambios rápidos, escritura en paralelo con decisiones implícitas [H].
- **Paradoja.** Reduce el contexto del orquestador pero **aumenta el total del sistema**: el subagente paga su propio arranque y no comparte la caché del orquestador [H/O]. Solo compensa si la salida verbosa se habría reenviado en muchos turnos posteriores [O].
- **Ejemplo.**
```yaml
---
name: test-runner
description: Ejecuta la suite y devuelve SOLO fallos
tools: Bash, Read, Grep
model: haiku
---
Devuelve como máximo 15 líneas: test fallido, fichero:línea, mensaje (1 línea).
Nunca pegues la salida completa ni los tests en verde.
```
- **Validar.** Tokens del orquestador **y** total del sistema por tarea; re-delegaciones.

#### S35 — Dimensionar el esfuerzo multiagente

- **Qué / Cómo.** Reglas explícitas en el prompt del orquestador [H]:
  - consulta factual: 1 agente con 3–10 llamadas;
  - comparación: 2–4 subagentes con 10–15 llamadas cada uno;
  - investigación compleja: más de 10 subagentes.

  En BrowseComp, los tokens explican el 80 % de la varianza del rendimiento [H], aunque se midió en búsqueda web, no en código.
- **Aplicar.** Research o revisión paralelizables de alto valor, y depuración con hipótesis que compiten entre sí.
- **No aplicar.** Escritura de código con dependencias. En esto coinciden Anthropic y Cognition [H].
- **Coste.** Los agent teams consumen ≈7× cuando los teammates trabajan en plan mode, y escalan linealmente con el tamaño del equipo. "Three focused teammates often outperform five scattered ones" [H]. Los teammates ociosos siguen consumiendo hasta que se cierran [H].
- **Ejemplo (regla en el system prompt del orquestador).**
```text
Clasifica la tarea antes de delegar:
- FACTUAL -> resuélvela tú, <=10 tool calls, 0 subagentes.
- COMPARATIVA (N opciones) -> min(N,4) subagentes, <=15 calls c/u.
- AMPLIA -> máx. 5 subagentes con objetivo, formato de salida, herramientas y límite.
Cierra cada subagente al terminar. NO paralelices la escritura de código compartido.
```

#### S36 — Workflow determinista antes que agente

- **Qué / Cómo.** Rutas de código predefinidas (encadenamiento, routing, paralelización, evaluador-optimizador). Solo se usa un agente autónomo cuando la tarea no se puede descomponer [H]. Agentless: localización → reparación → validación, sin que el LLM decida los pasos siguientes [H].
- **Ahorro.** Agentless v1: 27,33 % a **0,34 $/issue**; versión actual: 32,00 % a **0,70 $/issue** (SWE-bench Lite) [H]. La varianza de coste es muy inferior a la de un agente (hasta 30×) [O].
- **No aplicar.** Problemas abiertos, repositorios desconocidos, tareas donde el feedback del entorno cambia el plan.
- **Ejemplo.**
```python
files   = llm("Lista ≤3 ficheros relevantes", ctx=issue + repo_tree)
spans   = llm("Funciones/líneas a editar", ctx=issue + skeletons(files))
patches = [llm("Genera diff", ctx=issue + code(spans)) for _ in range(k)]
ok      = [p for p in patches if run_tests(apply(p)).passed]      # sin LLM
return rank(ok)[0] if ok else escalate_to_agent(issue)            # agente solo como fallback
```

#### S37 — Planificar, verificar y corregir pronto

- **Qué / Cómo.** Plan mode (exploración solo lectura y propuesta aprobada), Esc para detener, `/rewind` a un checkpoint, objetivos verificables, tests incrementales [H]. Rebobinar descarta el contexto contaminado en lugar de corregir encima [O].
- **Ahorro.** No hay cifra oficial ("preventing expensive re-work") [H/PV].
- **Riesgos.** Planes superficiales aprobados sin revisar. En agent teams, el plan mode eleva el consumo a ≈7× [H].
- **Ejemplo.**
```text
[plan mode] Añade validación a login() en src/auth.ts.
Aceptación: tests/auth.test.ts::rejects_empty_password pasa; no tocar otros módulos.
Plan en ≤8 pasos. Tras aprobarlo: paso 1, ejecuta solo ese test, continúa.
Si un test falla 2 veces seguidas, detente y pregunta.
```

<a id="cat-h"></a>
### H. Medición y gobernanza

**Por qué importa.** No reduce tokens por sí misma, pero sin ella no se puede validar nada. Con una varianza de hasta 30× entre ejecuciones, una conclusión basada en una sola ejecución no es fiable [H/O].

#### S38a — Instrumentar los campos `usage`

- **Anthropic.** `input_tokens` son solo los tokens **posteriores** al último breakpoint. El total es `cache_read + cache_creation + input_tokens` [H].
- **OpenAI Chat.** `prompt_tokens` **incluye** los tokens cacheados (`prompt_tokens_details.cached_tokens`). Los `reasoning_tokens` van dentro de `completion_tokens` [H].
- **Agent SDK.** Deduplicar los mensajes con el mismo ID. El `output_tokens` por paso es un placeholder. `total_cost_usd` es una estimación, no la factura [H].
- **Ejemplo (wrapper multiproveedor; precios = placeholders que hay que cargar de la tabla oficial).**
```python
import time, json, uuid, logging
from dataclasses import dataclass, asdict

PRICES = {  # USD por millón de tokens: PLACEHOLDERS
    "claude-model-x": {"in": 0.0, "out": 0.0, "cache_read_mult": 0.10},
    "gpt-model-x":    {"in": 0.0, "out": 0.0, "cached_in": 0.0},
}
CACHE_WRITE_MULT = {"5m": 1.25, "1h": 2.0}  # Anthropic

@dataclass
class UsageRecord:
    request_id: str; task_id: str; agent: str; provider: str; model: str
    uncached_in: int; cache_read: int; cache_write: int; output: int
    reasoning: int; latency_ms: float; cost_usd: float; cache_hit_rate: float

def _anthropic(u, model, ttl):
    p = PRICES[model]
    cr, cw, ui = u.cache_read_input_tokens or 0, u.cache_creation_input_tokens or 0, u.input_tokens
    cost = (ui*p["in"] + cr*p["in"]*p["cache_read_mult"]
            + cw*p["in"]*CACHE_WRITE_MULT[ttl] + u.output_tokens*p["out"]) / 1e6
    return ui, cr, cw, u.output_tokens, 0, cost

def _openai_chat(u, model):
    p = PRICES[model]
    cached = getattr(u.prompt_tokens_details, "cached_tokens", 0) or 0
    reasoning = getattr(u.completion_tokens_details, "reasoning_tokens", 0) or 0
    ui = u.prompt_tokens - cached                # prompt_tokens INCLUYE los cacheados
    cost = (ui*p["in"] + cached*p["cached_in"] + u.completion_tokens*p["out"]) / 1e6
    return ui, cached, 0, u.completion_tokens, reasoning, cost

def tracked_call(call_fn, *, provider, model, task_id, agent, ttl="5m", **kw):
    t0 = time.perf_counter(); resp = call_fn(model=model, **kw)
    lat = (time.perf_counter() - t0) * 1000
    ui, cr, cw, out, rsn, cost = (_anthropic(resp.usage, model, ttl) if provider == "anthropic"
                                  else _openai_chat(resp.usage, model))
    total_in = ui + cr + cw
    rec = UsageRecord(getattr(resp, "id", str(uuid.uuid4())), task_id, agent, provider, model,
                      ui, cr, cw, out, rsn, lat, round(cost, 6), cr / total_in if total_in else 0.0)
    logging.getLogger("llm.usage").info(json.dumps(asdict(rec)))   # -> OTel / DB
    return resp, rec
```
- **Validar.** La suma registrada debe coincidir con la consola del proveedor (desviación inferior a ±2 %) [O].

#### S38b — Conteo de tokens previo al envío

- **Anthropic.** `POST /v1/messages/count_tokens`: gratuito, con rate limits propios, y es una estimación. No aplica lógica de caché y falla con server tools [H]. Los modelos Claude 4.7+ usan un tokenizador que genera **~30 % más tokens** para el mismo texto, así que hay que recontar al migrar [H].
- **OpenAI.** `tiktoken` en local (`o200k_base`); no cuenta la sobrecarga de formato de mensajes [H/C].
- **Uso.** Decidir si compactar (D), enrutar a un modelo barato (B) o rechazar la petición.

#### S38c — Observabilidad

- **Claude Code.**
  - `/usage`: coste estimado, desglose de caché y línea "Prompt cache (main)" con fallos y su causa probable. En planes de suscripción añade atribución por skill, subagente o servidor MCP [H].
  - `/context`: qué ocupa la ventana [H].
- **OpenTelemetry.** `CLAUDE_CODE_ENABLE_TELEMETRY=1` expone las métricas `claude_code.token.usage` y `claude_code.cost.usage`, con atributos `model`, `agent.name`, `skill.name` y `mcp_server.name` [H].
- **Gateways.** LiteLLM (tercero, sin auditoría de Anthropic), Langfuse y Helicone (terceros, no verificados en detalle) [C/PV].
- **Privacidad.** Mantener desactivados `OTEL_LOG_USER_PROMPTS` y `OTEL_LOG_RAW_API_BODIES` salvo que haya una evaluación de privacidad (RGPD) [O].
- **Referencia de coste.** ~13 $ por desarrollador y día activo, 150–250 $ al mes; el 90 % de usuarios está por debajo de 30 $/día (Claude Code, empresa) [H].

#### S38d — Presupuestos y guardarraíles

| Nivel | Mecanismo | Nota |
|---|---|---|
| Ejecución (Claude Code `-p`) | `--max-budget-usd`, `--max-turns` | El presupuesto incluye subagentes [H] |
| Agent SDK | `max_budget_usd`, `maxTurns` | [H] |
| Profundidad y concurrencia | `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` (3), `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` (20) | Valores por defecto entre paréntesis [H] |
| OpenAI Agents SDK | `max_turns` → `MaxTurnsExceeded` | [H] |
| Organización | Límites de gasto y rate limits por workspace; TPM/RPM por tamaño de equipo | [H] |
| Gateway | Presupuesto y TPM/RPM por clave | LiteLLM [H] |
| Propio | Abortar tras 3 tool calls idénticas (hash de nombre + args) | [O] |

Calibrar los topes con el p95 de la línea base: un tope demasiado bajo corta tareas legítimas y obliga a reintentar [O].

#### S38e — Control de tareas en segundo plano

- Cada disparo de `/loop`, tarea programada, check-in o mensaje entre sesiones reenvía el contexto completo [H]. Si el intervalo es mayor que el TTL, **cada disparo es un fallo de caché completo** [H].
- **Controles.** Filas *Loops* en `/usage`, `CLAUDE_CODE_GOAL_CHECKIN_MINUTES=0`, `crossSessionInbound=hold`, y `/clear` antes de programar un loop [H].
- **Estimación.** `Coste_loop ≈ disparos/día × (contexto_cacheado × 0,1 + contexto_nuevo × 1,0 [+ reescritura si expira el TTL])`.

#### S38f — Métricas de eficiencia y evaluaciones A/B de regresión

- **KPI principal.** Coste por tarea resuelta. Secundarios: p50/p95 de tokens, tasa de acierto de caché, coeficiente de variación de tokens, ratio entrada/salida.
- **Gate de calidad (ejemplo).**
```yaml
eval: regression-token-opt
tasks: suite_interna_50          # issues reales anonimizados
runs_per_task: 5                 # por la varianza
arms: [baseline, optimizacion_X]
report: [resolve_rate, cost_per_resolved, p50_tokens, p95_tokens, cache_hit_rate, cv_tokens]
gate: resolve_rate_delta >= -1pp AND cost_per_resolved_delta <= -10%
```
- La métrica "Cost-to-Normalized-Gain" no se ha encontrado establecida con ese nombre [PV]; se recomienda usar coste por tarea resuelta.

<a id="sec-5-res"></a>
### Contradicciones y solapamientos resueltos

| # | Tema | Contradicción | Resolución adoptada |
|---|---|---|---|
| 1 | Precio de lectura de caché | "0,1× universal" frente a 0,05×/0,025× en modelos recientes | Calcular el ahorro **por modelo** con la tabla vigente |
| 2 | Caché de OpenAI | "Gratis y automática" (anuncio original) frente a escritura a 1,25× en GPT-5.6+ (documentación actual) | Prevalece la documentación actual; los modelos anteriores quedan como [PV] |
| 3 | Mínimo cacheable | "1.024 tokens" frente a 512–4.096 según el modelo | Tabla por modelo |
| 4 | Agentless | 0,34 $/issue frente a 0,70 $/issue | Son versiones distintas del paper; se citan ambas con su versión |
| 5 | Tool Search | −85 % sobre 55K frente a 72K | El −85 % corresponde a la línea base de ~72K tokens |
| 6 | Code execution with MCP | −98,7 % frente a −37 % | El −98,7 % es ilustrativo; el −37 % (PTC) es la cifra medida |
| 7 | RouteLLM | −85 % frente a ">2×" | Depende de la línea base; se usa la formulación prudente del paper |
| 8 | Routing | "Ahorra" frente a "encarece" | Solo ahorra con un router entrenado y decidiendo por tarea (no por turno) para preservar la caché |
| 9 | Resumen frente a enmascarado (D) | Anthropic sugiere compactar; SWE-agent muestra que enmascarar iguala al resumen a menor coste | En agentes de código, primero S16 (enmascarar o limpiar); S15 solo cuando hace falta continuidad narrativa |
| 10 | Edición de contexto y caché | Blogs: "preserva la caché" frente a la documentación: "la invalida" | Prevalece la documentación oficial: la invalida; usar `clear_at_least` |
| 11 | Mantener o quitar errores | Manus: mantenerlos en contexto; AgentDiet: quitar lo inútil | Mantener el **último** error relevante y quitar trazas antiguas ya resueltas |
| 12 | Diff o archivo completo | Aider y 2604.27296 a favor del diff; 2609.05779 y Cursor a favor del archivo completo | Decide la tríada tamaño del modelo × localidad del cambio × longitud del archivo (política adaptativa de S32) |
| 13 | Instrucciones de proyecto | Los proveedores las recomiendan; un estudio encuentra +20 % de coste sin mejora | Mantenerlas cortas y específicas y evaluarlas; los resúmenes de arquitectura se mueven a skills |
| 14 | Multiagente | Anthropic (a favor) frente a Cognition (en contra) | Es una contradicción de alcance: multiagente para research y lectura en paralelo, agente único para escribir código |
| 15 | "Contexto < 200K: inclúyelo entero" frente a *context rot* | Consejos opuestos | Compatibles solo si el contenido es muy relevante y va cacheado; si no, recuperación just-in-time o RAG |
| 16 | Predicted Outputs | "Ahorra" frente a "factura los rechazados" | Es una optimización de latencia, no de coste |
| 17 | TOON | −40 % frente al "prompt tax" | Útil solo con arrays grandes y uniformes que se repiten; en payloads pequeños, JSON compacto |
| 18 | Solapamiento S12/S24 | Divulgación progresiva de skills y de herramientas | S12 para conocimiento (C) y S24 para definiciones de herramientas (E) |
| 19 | Solapamiento S27/S16 | Filtrar al entrar frente a limpiar después | Complementarios: S27 evita que entre ruido y S16 retira lo que caduca |

---

<a id="sec-6"></a>
## 6. Roadmap de adopción por fases

> Regla de oro: **no adoptar ninguna técnica sin línea base ni gate de calidad.** Cada fase termina con una evaluación A/B (S38f).

### Fase 0 — Línea base (semana 0–1)

| Paso | Acción concreta | Entregable |
|---|---|---|
| 0.1 | Instrumentar `usage` por petición con el wrapper de S38a o la telemetría OTel | Tabla de peticiones con `task_id` |
| 0.2 | Definir la suite de evaluación: 20–50 tareas reales anonimizadas, 3–5 ejecuciones por tarea | `suite_interna` |
| 0.3 | Medir la línea base: coste por tarea resuelta, p50/p95 de tokens, tasa de acierto de caché, coeficiente de variación | Informe base |
| 0.4 | Poner topes de seguridad (S38d) en CI y automatizaciones | `max_budget_usd`, `max_turns` |

**Métrica de salida:** línea base estable (CV < 50 % en la mayoría de tareas).

### Fase 1 — Quick wins (0–4 semanas)

| # | Estrategia | Pasos de implementación | Métrica que valida el ahorro | Señal de que perjudica la calidad |
|---|---|---|---|---|
| 1 | S1 + S2 + S3 Caché | (1) Mover al final todo lo dinámico (fecha, git status). (2) Fijar herramientas y su orden. (3) Poner breakpoints (1h en system, 5m en contexto) o caché automática. (4) No cambiar modelo, *effort* ni herramientas a mitad de sesión | Tasa de acierto > 70 % en sesiones largas; coste de entrada −40 % o más | Instrucciones obsoletas que no se actualizan |
| 2 | S17 + S15 Higiene de sesión | `/clear` entre tareas; `/compact` con instrucciones solo con la caché caliente; sección "Compact instructions" en CLAUDE.md | Tokens de entrada medios por turno | Preguntas repetidas sobre decisiones ya tomadas |
| 3 | S16 Limpiar resultados de herramientas | Activar `clear_tool_uses` con `clear_at_least` ≥ 10K o enmascarar observaciones antiguas | `cleared_input_tokens`; tokens por tarea | Relecturas idénticas |
| 4 | S27 Filtros de salida | Hook de tests y logs (sección [E](#cat-e)); ajustar `MAX_MCP_OUTPUT_TOKENS` | Tokens por resultado de herramienta | Re-ejecuciones sin filtro; tests en verde que en realidad fallaron |
| 5 | S7 + S6 Modelo y *effort* | *Effort* medio por defecto; `model: haiku` en subagentes de lectura; modelo grande solo para planificar | Tokens de salida y de razonamiento por tarea; coste por tarea resuelta | Más ciclos de fallo y reedición |
| 6 | S24 + S26 Herramientas | Diferir herramientas MCP; desactivar servidores sin uso; preferir CLI con `--json` | Tokens de definiciones (`/context`) | Búsquedas de herramienta vacías |
| 7 | S10 + S37 Hábitos de prompt | Plantilla archivo + función + test; plan mode en tareas complejas; Esc y `/rewind` pronto | Lecturas por tarea; turnos de corrección | Parches que rompen a quien los llama |
| 8 | S32 + S-F1 Salida | Edición search-replace en archivos largos; "sin preámbulo"; `max_tokens` razonable | Tokens de salida por edición aceptada | Fallos de aplicación; truncaciones |
| 9 | S11 Instrucciones cortas | Recortar CLAUDE.md/AGENTS.md a menos de 200 líneas con solo comandos y convenciones | Tokens base; tasa de éxito | Convenciones violadas |
| 10 | S4 Batch | Mover a batch las evaluaciones, la generación masiva de tests y los docstrings | Coste por unidad −50 % | Peticiones expiradas |

**Gate de Fase 1:** coste por tarea resuelta −25 % o más y tasa de resolución ≥ base − 1 punto [O: objetivo orientativo].

### Fase 2 — Medio plazo (1–3 meses)

| # | Estrategia | Pasos de implementación | Métrica | Señal de alarma |
|---|---|---|---|---|
| 1 | S12 + S13 | Mover flujos especializados a skills; reescribir el system prompt con heurísticas y 2–3 ejemplos canónicos | Tokens base de sesión; activación correcta de skills | Skills que no se activan |
| 2 | S14 + S20 + S21 | Recuperación just-in-time por rutas; repo map (aider o propio con tree-sitter); plugins LSP | Lecturas por tarea; tokens de resultados de herramientas | Símbolos inventados; decisiones sin haber leído el código |
| 3 | S25 + S28 + S29 | Auditar el catálogo de herramientas (consolidar y usar prefijos por servicio); visor de 100 líneas y búsqueda con máximo 50 resultados; `input_examples` | Reintentos por parámetros inválidos; pasos por tarea | Uso de Bash para cubrir herramientas eliminadas |
| 4 | S34 + S35 | Subagentes con contrato de salida (≤15 líneas); regla de dimensionamiento en el orquestador; cerrar teammates | Tokens del orquestador **y** total del sistema | Re-delegaciones; síntesis contradictorias |
| 5 | S36 | Identificar tareas repetitivas (bug con test que lo reproduce, migraciones) y convertirlas en pipeline con el agente como fallback | Coste por tarea resuelta; tasa de fallback | El fallback crece hasta anular el ahorro |
| 6 | S19 | NOTES.md o memory tool con límite de tamaño y caducidad | Tokens de arranque por sesión | Notas obsoletas |
| 7 | S38c–e | OTel con atributos de equipo y agente; alertas por anomalía; auditar loops | Cobertura de trazas; tiempo de detección | — |
| 8 | S-F2 + S31 | Structured outputs en salidas que consume código; TOON o CSV para listados grandes y uniformes | Reintentos por error de parseo; tokens por payload | Campos vacíos pero válidos; filas inventadas |

**Gate de Fase 2:** coste por tarea resuelta −40 % o más acumulado frente a la línea base, sin caída de calidad [O].

### Fase 3 — Avanzado (3+ meses)

| # | Estrategia | Pasos de implementación | Métrica | Señal de alarma |
|---|---|---|---|---|
| 1 | S5 Routing aprendido | Router entrenado (RouteLLM u otro) o cascada con verificador; decisión por tarea con permanencia | % de llamadas al modelo fuerte; coste por tarea resuelta; tasa de acierto de caché | `cache_creation` al alza |
| 2 | S18 Reducción de trayectoria | Reflector barato en un harness propio (patrón AgentDiet) | Tokens de entrada acumulados; coste total incluido el reflector | Re-ejecuciones de comandos cuyo resultado se borró |
| 3 | S23 Ejecución de código sobre herramientas | Sandbox seguro; PTC o code-mode para flujos con 3 o más llamadas | Tokens por tarea; *round trips*; latencia | Resúmenes a ciegas; más salida que entrada ahorrada |
| 4 | S22 + S30 | RAG con Contextual Retrieval y reranker; compresión solo de prosa o con métodos para código | Recall@k; tokens por consulta; precisión | Identificadores alterados |
| 5 | S9 (solo FAQ) | Caché semántica particionada por contexto con umbral adaptativo | Precisión de los aciertos | Respuestas de otra rama o versión |
| 6 | S38f continuo | Evaluaciones de regresión en CI con cada cambio de prompt, modelo o arnés | Gate automático | — |

---

<a id="sec-7"></a>
## 7. Guía para generación de código (desarrollador con asistente de IA)

**Antes de empezar**
1. Una sesión, una tarea. `/clear` al cambiar de tema (o `/rename` + `/clear` + `/resume` más tarde).
2. Mantén el archivo de instrucciones del proyecto por debajo de 200 líneas, con solo comandos de build y test y convenciones no obvias. Lo especializado, en skills o reglas por ruta.
3. Desactiva los servidores MCP que no vayas a usar y prefiere `gh` o `aws` con `--json` y los campos mínimos.
4. Instala el plugin LSP de tu lenguaje si es tipado.

**Al pedir**

5. Sé específico: archivo + función + comportamiento + comando de verificación.
```text
En src/orders/pagination.ts, getPage(): corrige el off-by-one del offset.
No modifiques otros archivos. Verifica con: npm test -- tests/orders/pagination.test.ts
```
6. En tareas complejas o ambiguas, usa plan mode y revisa el plan antes de aprobarlo.
7. Pide al asistente que lea rangos de líneas, no archivos completos, y que use `rg` o LSP antes de abrir archivos.

**Durante**

8. Corrige pronto: Esc al primer desvío y `/rewind` en lugar de "arreglar encima".
9. Tests incrementales: un archivo, un test, continuar.
10. Filtra la salida de tests y logs con hooks para ver solo los fallos.
11. Si la conversación se alarga en la **misma** tarea, compacta en una pausa natural, con la caché caliente e indicando qué preservar.

**Modelo y razonamiento**

12. Por defecto, un modelo de gama media con *effort* medio. Sube el modelo o el *effort* solo para diseño o depuración difícil. Fíjalo por sesión: cambiarlo a mitad rompe la caché.

**Salida**

13. Pide ediciones search-replace o diff en archivos largos y el archivo completo en archivos cortos.
14. "Sin preámbulo ni resumen": pide explicación solo cuando la necesites.

**Vigila**

15. `/usage` (acierto de caché, fallos y su causa) y `/context` (qué ocupa la ventana).
16. Señales de que te estás pasando de optimizar:
    - el asistente relee lo mismo;
    - repite errores ya resueltos;
    - ignora convenciones;
    - o necesitas más rondas de corrección que antes.

---

<a id="sec-8"></a>
## 8. Guía para soluciones agénticas (arquitecto / desarrollador de agentes)

**1. Elige la topología mínima (G)**
- ¿La tarea se puede descomponer en pasos conocidos? Entonces usa un **workflow** (S36), con el agente como fallback.
- Agente único para escribir código. Subagentes solo para leer, investigar o ejecutar cosas verbosas, siempre con contrato de salida (S34).
- Multiagente solo para research o revisión en paralelo de alto valor, con reglas explícitas de dimensionamiento y cierre (S35).

**2. Diseña el prefijo para la caché (A)**
- Orden fijo: `tools` (conjunto estable y ordenado) → `system` (estable) → contexto de sesión → historial solo por el final → lo dinámico al final.
- Serialización determinista. Nada de timestamps al inicio.
- Decide modelo, *effort* y formato de salida **por tarea**, no por turno.
- Elige el TTL según las pausas. Batch para todo lo que no sea en tiempo real.

**3. Diseña las herramientas (E)**
- Catálogo mínimo sin solapes, con prefijos por servicio y descripciones que distingan bien entre herramientas y `input_examples` (S25, S29).
- `defer_loading` a partir de 10 herramientas o 10K tokens de definiciones (S24).
- Salidas acotadas por diseño: paginación, `max_results`, `response_format=concise`, ventanas de 100 líneas, truncado con ruta a archivo (S27, S28).
- Flujos con 3 o más llamadas dependientes o agregaciones: ejecución de código sobre herramientas en sandbox (S23).

**4. Gestiona el contexto en el tiempo (D)**
- Enmascara o limpia los resultados antiguos con un umbral de tokens liberados que compense la ruptura de caché (S16).
- Compacta solo cuando haga falta continuidad, con instrucciones y la caché caliente (S15).
- Estado persistente en memoria externa acotada (S19), para que las compactaciones y los reinicios no pierdan decisiones.
- Con harness propio y trayectorias largas, evalúa la reducción de trayectoria (S18).

**5. Construye la entrada con criterio (C)**
- Recuperación just-in-time por identificadores (S14). RAG con reranking solo si el corpus supera la ventana (S22).
- Todo lo recuperado va **después** del prefijo estable.
- Formatos compactos para listados uniformes (S31). No comprimas código con compresores de prosa (S30).

**6. Selección de modelo (B)**
- Modelo por rol (S6): orquestador capaz, workers baratos.
- Routing aprendido solo con volumen y verificador, y con permanencia de modelo durante la tarea (S5).

**7. Gobernanza (H)**
- Instrumenta `usage` por `task_id` y `agent`; deduplica y no sumes los placeholders.
- Topes duros: presupuesto, turnos, profundidad (1–2) y concurrencia de subagentes; detector de bucles (tool calls idénticas).
- Audita las tareas en segundo plano.
- Gate de regresión A/B en CI para cada cambio de prompt, modelo o arnés.

**Patrón de referencia (pseudoarquitectura)**
```text
Petición
  └─ Clasificador de tarea (reglas/modelo pequeño) ── FAQ → caché semántica (opcional)
       ├─ Tarea descomponible → Workflow determinista ── falla → Agente (fallback)
       └─ Tarea abierta → Agente único (modelo medio, effort fijo)
             ├─ Prefijo cacheado: tools(fijas + tool_search) · system · contexto sesión
             ├─ Herramientas: salidas acotadas · PTC para agregaciones
             ├─ Subagentes de lectura (modelo pequeño, contrato ≤15 líneas)
             ├─ Context editing (limpieza de tool results) + memoria externa
             └─ Guardarraíles: budget · max_turns · depth · loop detector
  └─ Telemetría usage → coste por tarea resuelta → gate A/B
```

---

<a id="sec-9"></a>
## 9. Checklist de optimización de tokens

Cópiala en tu repositorio o en tu plantilla de PR de arquitectura.

**Medición (hacer primero)**
- [ ] Registro de `usage` por petición con `task_id` y `agent` (entrada, lectura y escritura de caché, salida, razonamiento)
- [ ] Coste por **tarea resuelta** medido en una suite de evaluación con 3 o más ejecuciones por tarea
- [ ] Tasa de acierto de caché visible (`/usage` o dashboard)
- [ ] Topes de presupuesto, turnos, profundidad y concurrencia en automatizaciones
- [ ] Tareas en segundo plano (loops, check-ins) auditadas

**Caché y precio (A)**
- [ ] Prefijo ordenado: herramientas fijas → system estable → contexto → historial solo por el final → lo dinámico al final
- [ ] Sin timestamps ni datos variables al inicio del prompt
- [ ] Modelo, *effort*, thinking, herramientas y formato de salida fijos durante la sesión
- [ ] TTL elegido según las pausas reales
- [ ] Trabajo que no es en tiempo real en Batch API

**Modelo y cómputo (B)**
- [ ] Modelo asignado por rol o subagente
- [ ] *Effort* por defecto medio o bajo; alto solo en diseño y depuración compleja
- [ ] Si hay routing: aprendido, por tarea y con medición del impacto en la caché

**Entrada (C)**
- [ ] Prompts con archivo, función, resultado y verificación
- [ ] Archivo de instrucciones del proyecto con menos de 200 líneas y solo esencial; lo especializado en skills o reglas por ruta
- [ ] Recuperación just-in-time (rutas, rangos de línea, LSP) en lugar de precarga
- [ ] RAG solo si el corpus supera la ventana, con reranking y los fragmentos después del prefijo
- [ ] Sin compresión de prosa aplicada a código
- [ ] Formatos compactos solo para listados grandes y uniformes

**Contexto en el tiempo (D)**
- [ ] `/clear` o sesión nueva entre tareas no relacionadas
- [ ] Limpieza o enmascarado de resultados antiguos con umbral de tokens liberados
- [ ] Compactación con instrucciones de qué preservar y con la caché caliente
- [ ] Estado en NOTES.md o memoria externa antes de reiniciar o compactar

**Herramientas (E)**
- [ ] Catálogo mínimo, sin solapes, con prefijos por servicio
- [ ] `defer_loading` / Tool Search con 10 o más herramientas
- [ ] Servidores MCP sin uso desactivados; CLI con `--json` y campos mínimos
- [ ] Salidas acotadas (filtros, paginación, `max_results`, `concise`) sin enmascarar códigos de salida
- [ ] Descripciones que distinguen bien entre herramientas y `input_examples` en parámetros complejos
- [ ] Ejecución de código sobre herramientas en flujos con 3 o más llamadas (si hay sandbox)

**Salida (F)**
- [ ] Edición search-replace o diff en archivos largos; archivo completo en archivos cortos o con modelos pequeños
- [ ] "Sin preámbulo ni resumen" en salidas que consume una máquina o un subagente
- [ ] `max_tokens` y `stop_sequences` razonables; truncaciones monitorizadas
- [ ] Structured outputs donde hubiera fallos de parseo (no para código largo)

**Orquestación (G)**
- [ ] Workflow determinista donde la tarea sea descomponible
- [ ] Subagentes con contrato de salida corto; total del sistema medido
- [ ] Multiagente dimensionado por complejidad, con teammates cerrados al terminar
- [ ] Plan mode y verificación temprana en tareas complejas

**Calidad (siempre)**
- [ ] Gate A/B: tasa de resolución ≥ base − 1 punto y coste por tarea resuelta −10 % o más
- [ ] Señales vigiladas: relecturas, re-ejecuciones, decisiones repetidas, truncaciones, fallos de aplicación de diffs y aumento de turnos

---

<a id="sec-10"></a>
## 10. Lagunas y líneas abiertas

1. **Evidencia en código de varias técnicas.** Chain of Draft, LLMLingua (20×) y el −84 % de context editing se midieron en razonamiento, conversación o búsqueda web, no en generación de código [PV].
2. **Ahorro cuantificado sin publicar.** Faltan cifras oficiales para LSP/code intelligence, skills, plan mode, memoria externa (el +39 % es de rendimiento) y subagentes con modelo pequeño [PV].
3. **Estudios con muestra pequeña o sin replicar.**
   - *Harness effect* (22 tareas, arnés propietario).
   - TwinRouterBench (100 casos, 75 frente a 74 resueltos).
   - Estudio de AGENTS.md (preprint).
   - Ablaciones de SWE-agent (GPT-4 Turbo, 2024).
4. **Cifras de proveedores comerciales.** Fast-apply (10.500 tok/s, 98 %), Predicted Outputs "3–5×", GPTCache "10×/100×" y benchmark propio de TOON [C/PV].
5. **PTC y facturación.** Hay que aclarar si el −37 % mide tokens facturados o tokens de contexto, dado que la documentación dice que los resultados programáticos "no cuentan" [PV].
6. **Subagentes y caché.** No está confirmado si los *forks* (que heredan contexto) reutilizan el prefijo cacheado del orquestador [PV].
7. **Volatilidad de las APIs.** Cabeceras beta, nombres de estrategias (`compact_*`, `clear_*`, `code_execution_*`), precios y valores por defecto cambian cada pocos meses. Además, el tokenizador de Claude 4.7+ produce ~30 % más tokens, lo que rompe la comparabilidad entre generaciones de modelos [H].
8. **Interacción caché × compactación × routing.** No hay un modelo de coste unificado que optimice las tres cosas a la vez. Es una línea abierta para simulación con trazas propias [O].
9. **Idioma.** No se ha analizado el efecto de trabajar en español frente a inglés sobre el número de tokens y la calidad. Hay un estudio preliminar que niega ventajas del chino [PV].
10. **Métrica "Cost-to-Normalized-Gain".** No está establecida con ese nombre; conviene estandarizar internamente el uso de coste por tarea resuelta [PV].

---

<a id="sec-11"></a>
## 11. Fuentes

**Documentación oficial: Anthropic / Claude**
- https://platform.claude.com/docs/en/build-with-claude/prompt-caching
- https://platform.claude.com/docs/en/build-with-claude/batch-processing
- https://platform.claude.com/docs/en/build-with-claude/context-editing
- https://platform.claude.com/docs/en/build-with-claude/compaction
- https://platform.claude.com/docs/en/build-with-claude/compaction-threshold
- https://platform.claude.com/docs/en/build-with-claude/token-counting
- https://platform.claude.com/docs/en/build-with-claude/structured-outputs
- https://platform.claude.com/docs/en/build-with-claude/handling-stop-reasons
- https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
- https://platform.claude.com/docs/en/about-claude/pricing
- https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-search-tool
- https://platform.claude.com/docs/en/agents-and-tools/tool-use/programmatic-tool-calling
- https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool
- https://platform.claude.com/docs/en/docs/agents-and-tools/tool-use/text-editor-tool
- https://code.claude.com/docs/en/costs
- https://code.claude.com/docs/en/prompt-caching
- https://code.claude.com/docs/en/context-window
- https://code.claude.com/docs/en/model-config
- https://code.claude.com/docs/en/memory
- https://code.claude.com/docs/en/mcp
- https://code.claude.com/docs/en/discover-plugins
- https://code.claude.com/docs/en/sub-agents
- https://code.claude.com/docs/en/agent-teams
- https://code.claude.com/docs/en/monitoring-usage
- https://code.claude.com/docs/en/cli-reference
- https://code.claude.com/docs/en/agent-sdk/cost-tracking
- https://code.claude.com/docs/en/agent-sdk/subagents

**Ingeniería: Anthropic**
- https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
- https://www.anthropic.com/engineering/multi-agent-research-system
- https://www.anthropic.com/engineering/building-effective-agents
- https://www.anthropic.com/engineering/advanced-tool-use
- https://www.anthropic.com/engineering/code-execution-with-mcp
- https://www.anthropic.com/engineering/writing-tools-for-agents
- https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
- https://www.anthropic.com/news/contextual-retrieval
- https://www.anthropic.com/news/claude-opus-4-5
- https://claude.com/blog/context-management (antes https://www.anthropic.com/news/context-management)

**Documentación oficial: OpenAI, Google, Microsoft**
- https://developers.openai.com/api/docs/guides/prompt-caching
- https://developers.openai.com/api/docs/guides/batch
- https://developers.openai.com/api/docs/guides/reasoning
- https://developers.openai.com/api/docs/guides/predicted-outputs
- https://developers.openai.com/api/docs/guides/latency-optimization
- https://developers.openai.com/api/docs/guides/structured-outputs
- https://developers.openai.com/api/docs/guides/tools-apply-patch
- https://developers.openai.com/api/docs/guides/compaction
- https://developers.openai.com/api/docs/pricing
- https://openai.com/index/api-prompt-caching/
- https://github.com/openai/tiktoken
- https://openai.github.io/openai-agents-python/running_agents/
- https://ai.google.dev/gemini-api/docs/caching
- https://ai.google.dev/gemini-api/docs/pricing
- https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/predicted-outputs

**Papers (arXiv y congresos)**
- https://arxiv.org/abs/2307.03172 (Lost in the Middle)
- https://arxiv.org/abs/2310.05736 (LLMLingua)
- https://arxiv.org/abs/2403.12968 (LLMLingua-2)
- https://arxiv.org/abs/2510.00446 (LongCodeZip)
- https://arxiv.org/pdf/2502.14925 (CodePromptZip)
- https://arxiv.org/abs/2310.08560 (MemGPT)
- https://arxiv.org/abs/2305.05176 (FrugalGPT)
- https://arxiv.org/abs/2406.18665 (RouteLLM)
- https://arxiv.org/abs/2607.00053 (SWE-Router)
- https://arxiv.org/html/2605.18859v1 (TwinRouterBench)
- https://arxiv.org/pdf/2602.09902 (cascadas con verificación)
- https://arxiv.org/abs/2412.21187 (Overthinking "2+3")
- https://arxiv.org/abs/2502.18600 (Chain of Draft)
- https://arxiv.org/abs/2502.08235 (overthinking en tareas agénticas)
- https://arxiv.org/abs/2509.25243 (MultiCoD)
- https://arxiv.org/html/2508.05988v1 (ASAP)
- https://arxiv.org/abs/2601.06007 (Don't Break the Cache)
- https://arxiv.org/abs/2607.19214 (Keepalive economics)
- https://arxiv.org/abs/2411.05276 (GPT Semantic Cache)
- https://arxiv.org/abs/2502.03771 (vCache)
- https://arxiv.org/html/2601.23088v1 (ataques a caché semántica)
- https://arxiv.org/html/2403.02694v2 (MeanCache / privacidad)
- https://arxiv.org/abs/2509.23586 (AgentDiet)
- https://arxiv.org/abs/2508.21433 (gestión de contexto en SWE-agent: masking frente a resumen)
- https://arxiv.org/abs/2405.15793 (SWE-agent)
- https://arxiv.org/abs/2407.01489 y https://arxiv.org/abs/2407.01489v1 (Agentless)
- https://arxiv.org/abs/2604.22750 (consumo de tokens en tareas de código agénticas)
- https://arxiv.org/abs/2607.06906 (The Harness Effect)
- https://arxiv.org/abs/2602.11988 (evaluación de archivos de contexto tipo AGENTS.md)
- https://arxiv.org/abs/2604.27296 (To Diff or Not to Diff)
- https://arxiv.org/abs/2609.05779 (Diffs vs Whole Files)
- https://arxiv.org/abs/2510.12487 (Diff-XYZ)
- https://arxiv.org/abs/2603.03306 (TOON vs JSON)
- https://arxiv.org/abs/2601.14470 (distribución de tokens en ChatDev)
- https://arxiv.org/pdf/2602.03695 (precisión por coste)
- https://arxiv.org/pdf/2507.21046 (coste por ganancia normalizada)
- https://arxiv.org/pdf/2604.14210 (idioma y coste en vibe coding)
- https://arxiv.org/html/2602.15945v1 (decisiones de diseño MCP; identificado, no revisado)

**Repositorios, frameworks y blogs de ingeniería**
- https://aider.chat/docs/repomap.html
- https://aider.chat/docs/more/edit-formats.html
- https://aider.chat/docs/unified-diffs.html
- https://www.trychroma.com/research/context-rot
- https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus
- https://cognition.com/blog/dont-build-multi-agents
- https://lmsys.org/blog/2024-07-01-routellm/
- https://github.com/zilliztech/GPTCache
- https://github.com/toon-format/toon
- https://agents.md/
- https://cursor.com/docs/context/rules
- https://cursor.com/blog/instant-apply
- https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions
- https://docs.litellm.ai/docs/proxy/users
- https://github.com/orgs/modelcontextprotocol/discussions/629

**Fuentes de terceros o comerciales (usadas solo como [C]/[PV])**
- https://aimultiple.com/code-execution-with-mcp
- https://www.getmaxim.ai/articles/code-execution-with-mcp-how-code-mode-cuts-agent-token-costs-by-90/
- https://www.morphllm.com/fast-apply-model
- https://www.morphllm.com/openai/predicted-outputs
- https://langfuse.com/docs
- https://docs.helicone.ai
- https://claudelab.net/en/articles/api-sdk/compaction-api-context-management (solo para contrastar una contradicción)
