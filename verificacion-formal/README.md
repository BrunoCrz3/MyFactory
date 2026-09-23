# Lenguajes de verificación formal y demostradores lógicos

Quince fichas que cubren diecinueve lenguajes y herramientas, ordenadas por **penetración de
mercado**: cuánto uso real tienen fuera de la academia, empezando por el que más. Ese orden y la
columna de tendencia son **valoración propia a 2026-09-23**, no una medida: no hay censo de
proyectos verificados y los usos conocidos son los que sus responsables han hecho públicos.

← [Volver al índice](../README.md) · [Cuándo usar cada uno](cuando-usar-cada-uno.md)

Leyenda de tendencia: ↑↑ crece rápido · ↑ crece · → estable · ↓ en declive.

| # | Lenguaje | Tipo | Dónde se usa | Tendencia (valoración propia, 2026-09-23) | Enlace |
| --- | --- | --- | --- | --- | --- |
| 1 | **TLA+** | Especificación y model checking | AWS, Microsoft, Oracle, Intel y bases de datos distribuidas | ↑ crecimiento moderado | [foundation.tlapl.us](https://foundation.tlapl.us) |
| 2 | **Lean 4** | Asistente de pruebas y lenguaje de programación | Matemáticas, AWS, DeepMind y startups de IA como Harmonic | ↑↑ el que más crece | [lean-lang.org](https://lean-lang.org) |
| 3 | **Rocq** (antes Coq) | Asistente de pruebas | CompCert, academia y criptografía | → estable; pierde peso relativo frente a Lean | [rocq-prover.org](https://rocq-prover.org) |
| 4 | **Isabelle/HOL** | Asistente de pruebas | seL4, el microkernel verificado, y academia | → estable | [isabelle.in.tum.de](https://isabelle.in.tum.de) |
| 5 | **Dafny** | Lenguaje verificable | AWS y benchmarks de IA | ↑ creciendo | [dafny.org](https://dafny.org) |
| 6 | **SPARK (Ada)** | Subconjunto verificable de Ada | Aeroespacial, defensa y ferroviario | → estable, nicho regulado | [adacore.com/languages/spark](https://www.adacore.com/languages/spark) |
| 7 | **B-Method / Event-B** | Especificación por refinamiento | Metro y ferrocarril | → / ↓ legado | [atelierb.eu](https://www.atelierb.eu) · event-b.org (**no resuelve**, ver nota) |
| 8 | **P** | Modelado de máquinas de estados | AWS (S3, DynamoDB y otros) | ↑ creciendo | [p-org.github.io/P](https://p-org.github.io/P/) |
| 9 | **Alloy** | Especificación ligera | Academia y diseño de modelos de datos | → estable | [alloytools.org](https://alloytools.org) |
| 10 | **F\*** | Lenguaje con tipos dependientes | Criptografía: HACL\*, presente en Firefox, Linux y Windows | → nicho | [fstar-lang.org](https://fstar-lang.org) |
| 11 | **Verus** | Verificación de código Rust | Sistemas en Rust y Microsoft Research | ↑↑ crece rápido desde una base pequeña | [github.com/verus-lang/verus](https://github.com/verus-lang/verus) |
| 12 | **Kani** | Model checker para Rust | AWS y la librería estándar de Rust | ↑ creciendo | [github.com/model-checking/kani](https://github.com/model-checking/kani) |
| 13 | **Quint** | Especificación TLA con sintaxis moderna | Blockchain y protocolos de consenso | ↑↑ crece rápido desde una base pequeña | [quint-lang.org](https://quint-lang.org) · [github.com/informalsystems/quint](https://github.com/informalsystems/quint) |
| 14 | **Agda / Idris 2** | Tipos dependientes | Investigación en teoría de tipos | → académico | [agda.readthedocs.io](https://agda.readthedocs.io) · [idris-lang.org](https://www.idris-lang.org) |
| 15 | **Z / VDM / PVS** | Especificación clásica | NASA (PVS) y sistemas industriales heredados | ↓ en declive | [overturetool.org](https://www.overturetool.org) (VDM) · [pvs.csl.sri.com](https://pvs.csl.sri.com) (PVS) |

## Las tres familias

La tabla mezcla herramientas que responden preguntas distintas. Agrupadas por lo que hacen:

- **Especificación y model checking** (TLA+, P, Quint, Alloy, B/Event-B, Z, VDM): describen
  *qué* debe cumplirse y exploran los estados posibles buscando un contraejemplo. No verifican
  el código que ejecutas: verifican el modelo de ese código.
- **Asistentes de pruebas** (Lean 4, Rocq, Isabelle/HOL, Agda, Idris 2, PVS): demuestran
  teoremas con ayuda de la máquina. Cuesta mucho más y lo que se obtiene también es mayor: una
  demostración, no la ausencia de contraejemplo dentro de un espacio acotado.
- **Verificación de código real** (Dafny, SPARK, F\*, Verus, Kani): el programa y su
  especificación son el mismo artefacto. Lo verificado es lo que se compila y ejecuta.

La [guía de uso](cuando-usar-cada-uno.md) recorre cada familia por la necesidad que resuelve.

## Los dos que usa storyMaker

- **TLA+** verifica el **harness**: la especificación vive en `formal/tla/` y se comprueba con
  TLC. El objeto es el bucle de orquestación —reintentos con tope, transiciones de estado,
  concurrencia en vuelo—, donde el fallo aparece en un entrelazado que ninguna prueba iba a
  reproducir.
- **Lean 4** verifica la **cronología de la historia**: en `formal/lean/` se demuestran los
  invariantes temporales de la novela. Aquí no hay espacio de estados que explorar, hay
  propiedades que deben sostenerse para cualquier historia; y ninguna versión se publica sin
  pasar el gate de validadores, Lean incluido.

Uno acota estados y el otro demuestra propiedades: son dos preguntas distintas, y por eso están
los dos.

## Nota sobre los enlaces (comprobados 2026-09-23)

| Enlace | Estado |
| --- | --- |
| `event-b.org` | **No resuelve.** El dominio tiene DNS, pero HTTPS no responde y HTTP devuelve 404. Queda anotado sin sustituto: la ficha se apoya en el enlace de Atelier B, que sí resuelve. |
| `quint-lang.org` | Resuelve, redirigiendo a `quint.sh`. |
| `github.com/informalsystems/quint` | Resuelve, redirigiendo a `github.com/quint-co/quint`: la organización se renombró. |
| `adacore.com/about-spark` | Redirigía a `adacore.com/languages/spark`; la tabla usa ya el destino. |
| `agda.readthedocs.io`, `idris-lang.org` | Resuelven con redirección trivial (versión de la documentación y `www` → dominio raíz). |

Los demás enlaces de esta página resolvían con HTTP 200. `event-b.org` es el único de los 35
enlaces del catálogo que no resuelve.
