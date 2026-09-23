# Comparativa de métodos de SDD

Los trece métodos y productos del bloque, cruzados por las cuatro dimensiones que de verdad
deciden cuál encaja. Los enlaces a cada proyecto están en [open-source.md](open-source.md) y
[comerciales.md](comerciales.md); aquí solo se comparan.

Las clasificaciones de esta página son **valoración propia a 2026-09-23**, hechas a partir de lo
que cada proyecto describe de sí mismo. No son medidas ni el resultado de haberlos usado todos.

← [Volver al bloque](README.md)

## Tabla comparativa

| Método | Flujo | Peso | Greenfield / Brownfield | Agentes |
| --- | --- | --- | --- | --- |
| [GSD](open-source.md#gsd-get-shit-done) | Meta-prompting y control del contexto, sin cadena de artefactos | Ligero | Ambos, sin modo específico | Muchos: Claude Code, Codex, Cursor y otros |
| [OpenSpec](open-source.md#openspec) | propose → apply → archive, un ciclo por cambio | Ligero | Ambos por diseño | Agnóstico, sin Python |
| [Superpowers](open-source.md#superpowers) | Conversación → spec destilada → código, sobre skills componibles | Ligero-medio | Ambos, sin modo específico | Agentes con soporte de skills |
| [Agent OS](open-source.md#agent-os) | Leer código → escribir convenciones → inyectar las relevantes | Medio | Brownfield en primer lugar | Agnóstico |
| [Spec Kit](open-source.md#github-spec-kit) | constitution → specify → plan → tasks → implement | Medio | Greenfield en primer lugar | Más de 30 agentes |
| [BMAD-METHOD](open-source.md#bmad-method) | Ciclo completo repartido entre personas de agente | Pesado | Greenfield en primer lugar | Agnóstico |
| [MUSUBI](open-source.md#musubi) | Constitución de 9 artículos → EARS → C4 + ADR → validación | Pesado | Modo greenfield y modo brownfield separados | Agnóstico |
| [EasySpecs](comerciales.md#easyspecs) | Documentar el código real → spec + Trust Spec → cascada de validación | Medio-pesado | Brownfield | El que elijas (según su web, 2026-09-23) |
| [Kiro](comerciales.md#kiro) | Requisitos → diseño → ficheros de dirección, dentro del IDE | Medio | Greenfield | El suyo: ata al IDE |
| [Tessl](comerciales.md#tessl) | La spec como artefacto principal, el código como derivado | Medio | Greenfield | Su plataforma |
| [BrainGrid](comerciales.md#braingrid) | Planificar y descomponer, luego delegar | Ligero | Ambos | Agnóstico (según su web, 2026-09-23) |
| [CodeMySpec](comerciales.md#codemyspec) | Contrastar código contra spec | Ligero-medio | Ambos | Su plataforma |
| [Augment Code](comerciales.md#augment-code-cosmos) | Contexto persistente de arquitectura → coordinación de agentes | Medio | Brownfield a gran escala | Los suyos, coordinados |
| **storyMaker** (referencia) | docs → spec aprobada → plan aprobado → código con TDD → docs al cerrar | Medio | Greenfield, con las puertas escritas en el propio repo | El agente del repositorio |

## Qué distingue a unos de otros

**Por dónde entra el método.** Tres puntos de entrada distintos, y conviene no confundirlos:
por la especificación (Spec Kit, MUSUBI, Tessl), por el código que ya existe (Agent OS,
EasySpecs, Augment Code) o por el contexto de la sesión (GSD, Superpowers). Un método que entra
por la spec no resuelve un repositorio sin documentar, y uno que entra por el código no impide
que el siguiente cambio se haga a ciegas.

**Dónde está la puerta.** Casi todos ponen la puerta antes de escribir código. CodeMySpec la
pone después, comprobando que lo escrito corresponde a lo acordado. EasySpecs pone las dos: la
Trust Spec es una puerta de salida acordada por adelantado. Un proceso con puerta solo a la
entrada supone que el agente cumple el plan; uno con puerta solo a la salida supone que el plan
estaba bien.

**Qué cuesta abandonarlo.** Los métodos open source son ficheros en tu repositorio: dejarlos
cuesta borrarlos. Kiro es un IDE y Tessl, Augment Code y CodeMySpec son plataformas: ahí la spec
vive fuera del repositorio, con lo que eso implica el día que se cambia de herramienta.

**Peso frente a tamaño del cambio.** Ninguno de los pesados distingue bien entre una errata y
una funcionalidad nueva. Es el punto donde se abandonan: si arreglar un texto exige constitución,
diseño y ADR, se acaba saltando el proceso, y un proceso que se salta a veces no sujeta nunca.
Los métodos que declaran excepciones explícitas —o que giran sobre el cambio, como OpenSpec—
sobreviven mejor al uso diario.

## El flujo de storyMaker, como referencia

El proyecto storyMaker no adopta ninguno de los trece: lleva su propio flujo escrito en la guía
del repositorio. Sirve aquí de punto de comparación porque toma decisiones distintas en dos
sitios concretos.

```
docs/*.md  →  spec.md  →  plan.md  →  código
              [aprobada]  [aprobado]   [TDD]
```

1. **Contexto semilla.** El vocabulario y el conocimiento de dominio viven en el repositorio y
   son lectura obligatoria antes de tocar dominio. Toda spec deriva de ellos.
2. **Spec aprobada, con interrogatorio previo.** Antes de dar una spec por buena, una skill
   propia (`grill-me`) somete el planteamiento a un interrogatorio adversarial. La spec no se
   aprueba por estar escrita, sino por sobrevivir a las preguntas.
3. **Plan aprobado.** Sin spec aprobada no hay plan; sin plan aprobado no hay código. Cada
   artefacto declara su estado —borrador, en revisión, aprobada— y quién lo aprobó.
4. **Código con TDD.** La prueba primero, siempre.
5. **Cierre.** Al terminar se actualizan los documentos y queda una entrada en el registro de
   iteraciones: qué cambió, qué lo provocó y qué efecto tuvo.

**En qué se separa del resto.** Dos cosas. La primera: la aprobación es de una persona y es
explícita, no una marca de estado que el agente se pone a sí mismo — cada puerta tiene un nombre
y una fecha. La segunda: hay un paso de refutación antes de aprobar, algo que en los trece
métodos anteriores solo aparece —y del lado de la salida— en la Trust Spec de EasySpecs.

**Qué le falta frente a ellos.** No tiene modo brownfield, porque no lo necesita todavía; y las
puertas las sostiene la disciplina de quien las aplica, no una herramienta que las imponga. Es
justo lo que aportan Spec Kit o MUSUBI a cambio de su peso.
