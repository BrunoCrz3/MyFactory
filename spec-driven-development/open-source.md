# Métodos de SDD open source

Siete métodos publicados como repositorio, ordenados de más ligero a más pesado. El peso es una
**valoración propia a 2026-09-23**: mide cuánto proceso y cuántos artefactos impone el método
antes de que se escriba la primera línea de código, no su calidad.

← [Volver al bloque](README.md) · [Comerciales](comerciales.md) · [Comparativa](comparativa.md)

| Método | Flujo | Peso (valoración propia, 2026-09-23) | Brownfield | Enlace |
| --- | --- | --- | --- | --- |
| GSD (Get Shit Done) | Meta-prompting e ingeniería de contexto | Ligero | Parcial | [github.com/gsd-build/get-shit-done](https://github.com/gsd-build/get-shit-done) |
| OpenSpec | propose → apply → archive | Ligero | Sí, de diseño | [github.com/Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec) |
| Superpowers | Skills componibles que destilan la spec de la conversación | Ligero-medio | Parcial | [github.com/obra/superpowers](https://github.com/obra/superpowers) |
| Agent OS | Lee el código y escribe sus convenciones reales | Medio | Sí, es su punto fuerte | [github.com/buildermethods/agent-os](https://github.com/buildermethods/agent-os) |
| GitHub Spec Kit | constitution → specify → plan → tasks → implement | Medio | Parcial | [github.com/github/spec-kit](https://github.com/github/spec-kit) |
| BMAD-METHOD | Ciclo completo con personas de agente | Pesado | Parcial | [github.com/bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) |
| MUSUBI | Constitución de 9 artículos, EARS, C4 y ADR | Pesado | Sí, con modo propio | [github.com/nahisaho/MUSUBI](https://github.com/nahisaho/MUSUBI) |

## GitHub Spec Kit

CLI oficial de GitHub, escrita en Python. Estructura el trabajo en cinco pasos encadenados
—constitución, especificación, plan, tareas e implementación— y es compatible con más de 30
agentes de código. Es la referencia con la que se comparan los demás: si alguien dice «SDD» sin
más contexto, suele estar pensando en este flujo.

Su coste de entrada es la dependencia de Python y la disciplina de recorrer los cinco pasos
también cuando el cambio es pequeño.

## OpenSpec

Alternativa más ligera a Spec Kit, organizada por **cambio** y no por proyecto: cada cambio se
propone, se aplica y se archiva. Al girar sobre el cambio en vez de sobre la especificación
completa, encaja en repositorios existentes igual que en proyectos nuevos. No necesita Python.

Buena opción cuando el proceso de cinco pasos se percibe como exceso pero se quiere una puerta
explícita antes de tocar código.

## GSD (Get Shit Done)

Sistema ligero de meta-prompting, ingeniería de contexto y desarrollo dirigido por
especificación, pensado para funcionar con Claude Code, Codex, Cursor y muchos otros agentes. Su
objetivo declarado es combatir la degradación del contexto en sesiones largas —el *context
rot*—, más que imponer una cadena de artefactos.

Es el método que menos estructura añade: interesa cuando el problema real no es la falta de
especificación, sino que el agente pierde el hilo a mitad de tarea.

## Superpowers

Método de desarrollo para agentes de código construido a partir de skills componibles. Su rasgo
distintivo es de dónde sale la especificación: la extrae de la propia conversación antes de
permitir que se escriba código, en lugar de pedirte que la redactes por adelantado.

Encaja con quien trabaja hablando con el agente y quiere que ese diálogo cristalice en un
artefacto, no que se pierda.

## BMAD-METHOD

Marco de ciclo completo con varias personas de agente —analista, jefe de producto, arquitecto,
desarrollo y QA— que se pasan el trabajo entre sí. Cubre desde la idea hasta la verificación.

Es potente y tiene una curva de aprendizaje pronunciada: hay que entender el reparto de roles
antes de sacarle provecho. En equipos pequeños, el reparto puede costar más de lo que aporta.

## MUSUBI

El más riguroso de los siete. Se apoya en una constitución de nueve artículos y valida cada
funcionalidad contra ella. Escribe los requisitos en formato EARS, diseña con diagramas C4 y
registra las decisiones de arquitectura como ADR. Distingue explícitamente modo greenfield y
modo brownfield, en lugar de tratar el segundo como un caso degradado del primero.

Es la opción para quien viene de ingeniería de requisitos clásica y echa de menos trazabilidad
entre requisito, diseño y decisión.

## Agent OS

Ataca un problema distinto del resto: en vez de pedirte que declares cómo debe ser el código,
lee el que ya tienes, escribe las convenciones que realmente usa y le entrega al agente solo las
que vienen al caso. La especificación se descubre, no se redacta.

Es la opción más directa para un repositorio existente, sobre todo cuando el problema es que el
agente ignora los patrones de la casa.
