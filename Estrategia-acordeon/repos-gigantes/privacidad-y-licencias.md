# Privacidad y licencias: el filtro previo

Antes de instalar una herramienta en el repositorio de un cliente hay que responder dos
preguntas, y ninguna es técnica:

1. **¿Sale código del cliente de la máquina?** Esto incluye mandarlo a una API de embeddings, a
   una nube de indexado, a un observador que resume sesiones o a un servicio que responde
   preguntas. Si sale, hace falta que el cliente lo acepte, normalmente con un acuerdo de
   encargo de tratamiento (DPA). Además, el código puede contener datos personales, secretos o
   propiedad intelectual sujetos a NDA.
2. **¿La licencia permite usarla en trabajo para clientes?** «No comercial», ELv2 o AGPL cambian
   la respuesta.

Todo lo que sigue es **valoración propia a 2026-09-24** sobre la documentación de cada proyecto.
No es asesoramiento legal: los casos marcados con ⚖️ los tiene que revisar legal.

← [Volver al bloque](README.md)

## Semáforo por herramienta

✅ local por defecto · ⚠️ tiene modo local, pero no es el de defecto, o hay algo que vigilar · ⛔ saca
código a un tercero

| Herramienta | ¿Sale código? | Cómo dejarla en local | Licencia | Veredicto con cliente bajo NDA/RGPD |
|---|---|---|---|---|
| Configuración nativa (CLAUDE.md, deny, excludes, subagentes, hooks) | ✅ No, más allá de la llamada normal al modelo | — | — | Usar |
| Plugins LSP oficiales | ✅ No | — | Apache-2.0 | Usar |
| ast-grep (skill, CLI) | ✅ No | — | MIT | Usar |
| codebase-memory-mcp | ✅ No, sin red | — | MIT | Usar tras el piloto |
| CodeGraphContext | ✅ No, con backend embebido | No usar Neo4j remoto | MIT | Usar |
| code-review-graph | ⚠️ Embeddings cloud opcionales | No activarlos | MIT | Usar en local |
| CocoIndex Code | ✅ Modelo de embeddings local por defecto | No configurar modelos cloud en LiteLLM | Apache-2.0 | Usar |
| Semble | ✅ No | — | MIT | Usar |
| Claude Context | ⛔ **Por defecto sí**: OpenAI + Zilliz Cloud | Ollama + Milvus autoalojado | MIT | Solo en modo local |
| Serena | ✅ No (panel en localhost) | — | ⚖️ GPL-3.0+ (app) | Usar sin modificar ni redistribuir |
| Sourcegraph MCP | ⛔ Con Sourcegraph Cloud · ✅ autoalojado | Instancia del cliente | Comercial | Solo sobre la instancia del cliente |
| Augment Context Engine | ⛔ Sí, su nube; sin on-prem | No hay | Comercial | Solo con DPA firmado |
| Greptile | ⛔ SaaS · ✅ autoalojado | Despliegue propio | Comercial | Solo autoalojado |
| GitNexus | ✅ No | — | ⚖️ **PolyForm Noncommercial** | **No sin licencia comercial** |
| OpenRewrite / Moderne | ✅ MCP local · ⛔ Moderne Platform | MCP local | Apache-2.0 · ⚖️ Moderne CLI comercial en repos privados | Usar con licencia |
| Repomix (CLI, MCP, plugin) | ✅ No · ⛔ la web repomix.com | Solo CLI/MCP | MIT | Usar el CLI; nunca la web |
| code2prompt, yek | ✅ No | — | MIT | Usar (revisar el instalador remoto de yek) |
| deepwiki-open | ✅ Con Ollama | Ollama + hospedaje propio | MIT | Usar en local |
| DeepWiki | ⛔ Sí, privados en la nube de Cognition | No hay | — | Solo dependencias públicas |
| Google Code Wiki | ⛔ Sí | Extensión on-prem en lista de espera | — | Solo repos públicos |
| Context7 | ⛔ Consultas a su servicio; privados, subidos | No hay | MIT (cliente) · backend privado | Solo docs públicas; vigilar que no viaje código en la consulta |
| Context (neuledge) | ✅ No | — | Apache-2.0 | Usar |
| GitMCP | ⚠️ Contenido público | Autoalojar | Apache-2.0 | Autoalojado para uso interno |
| context-mode | ✅ SQLite local; ⚠️ copia en claro de las salidas 24 h | Purgar al acabar | ⚖️ **Elastic License 2.0** | Revisar licencia; A/B antes |
| RTK | ✅ Telemetría opcional y anónima | Dejarla desactivada | Apache-2.0 | Permitido, pero bajo valor |
| claude-mem | ⛔ **Por defecto sí**: observador hospedado; sincronización cloud opcional | `--provider` propio o `CLAUDE_MEM_ONLINE_OPTIN=false` + `<private>` | Apache-2.0 (open-core) | No, salvo configuración cerrada y auditada |
| Basic Memory | ⚠️ Sincronización cloud opcional | No activarla | ⚖️ AGPL-3.0 | Revisar licencia |
| ccusage | ✅ Con `--offline` | `--offline` | MIT | Usar |
| OpenTelemetry de Claude Code | ✅ Solo a tu colector | Colector propio; `OTEL_LOG_*` desactivados | — | Usar |
| Superpowers, `feature-dev`, `code-review` | ✅ No | — | MIT / Apache-2.0 | Usar; medir el coste total |

## Reglas que se derivan

1. **Lista blanca por cliente, no por herramienta.** Se acuerda en la Fase 0 qué herramientas
   pueden ver su código y se deja escrita en el repositorio del proyecto.
2. **Lo local por defecto.** Si una herramienta tiene modo local y modo cloud, se configura el
   local de forma explícita y se comprueba (por ejemplo, sin red) antes de apuntarla al código
   del cliente.
3. **`permissions.deny` no es una frontera de secretos.** Es best-effort en Grep y Glob, y no
   cubre `grep -r` ni `find` en Bash ni los subprocesos [H]. Los secretos se sacan del árbol o
   se aíslan con sandbox.
4. **Telemetría sin contenido.** OTel sí, pero sin `OTEL_LOG_USER_PROMPTS`,
   `OTEL_LOG_TOOL_CONTENT` ni `OTEL_LOG_RAW_API_BODIES` salvo evaluación de privacidad.
5. **Los plugins del marketplace no están auditados** por Anthropic cuando son de terceros:
   revisar qué servidores MCP declaran antes de instalarlos.
6. **Datos personales en ejemplos.** Las skills, los ejemplos de herramientas y los mapas que se
   escriben para un cliente no llevan datos reales; se usan marcadores.
