# Cuándo usar cada uno

Guía breve por necesidad. Empieza por la pregunta que quieres responder, no por el lenguaje que
te suena. Los enlaces a cada herramienta están en la [tabla del bloque](README.md).

Todo lo que sigue es **valoración propia a 2026-09-23**.

← [Volver al bloque](README.md)

## La pregunta que decide

| Si lo que temes es… | La familia es… | Candidatos |
| --- | --- | --- |
| Un entrelazado imposible de reproducir: concurrencia, protocolos, reintentos, fallos parciales | Modelado de estados y model checking | TLA+, P, Quint, Alloy |
| Que una propiedad no se sostenga en ningún caso, no solo en los que has probado | Asistentes de pruebas | Lean 4, Rocq, Isabelle/HOL, Agda, Idris 2 |
| Que el código que se ejecuta no haga lo que su contrato dice | Verificación de código real | Dafny, SPARK, F\*, Verus, Kani |
| Que la especificación y la implementación se separen a lo largo de años y de refinamientos | Refinamiento y especificación clásica | B-Method / Event-B, Z, VDM, PVS |

## Modelado de estados: cuando el fallo está en el orden

Modelas el sistema como estados y transiciones, declaras qué debe cumplirse siempre, y la
herramienta explora entrelazados hasta dar con uno que lo rompa. Lo que obtienes no es una
demostración: es la ausencia de contraejemplo dentro del espacio que has acotado. Para
concurrencia y sistemas distribuidos suele bastar, porque ahí los fallos son de orden, no de
lógica.

**TLA+** es el estándar de hecho y el de más recorrido industrial. Su coste es la notación: el
modelo no se parece al código y hay que mantener los dos. **Quint** es la misma semántica con
una sintaxis moderna y herramientas de desarrollo actuales; sirve para quien rechaza TLA+ por la
notación y no por la idea. **P** parte de otro sitio: modela máquinas de estado que se comunican
por mensajes, un encaje muy natural para servicios distribuidos, y lo mismo sirve de modelo que
de programa. **Alloy** no es para protocolos sino para estructuras: relaciones, cardinalidades y
restricciones de un modelo de datos, con contraejemplos visuales que ayudan a verlo.

Una advertencia que se repite en todos: el modelo es tan bueno como su abstracción. Un modelo
que no refleja el sistema real verifica otro sistema, y da la misma sensación de seguridad.

## Asistentes de pruebas: cuando quieres una demostración

Aquí no se acota un espacio: se demuestra. La máquina comprueba cada paso, así que una prueba
aceptada no tiene agujeros, pero escribirla cuesta un orden de magnitud más que un modelo, y el
esfuerzo se mide en semanas, no en tardes.

**Lean 4** es el que más crece, tiene la comunidad más activa y sirve además como lenguaje de
programación, lo que reduce el salto entre demostrar y ejecutar. **Rocq** es el de mayor
historial industrial —CompCert, un compilador de C verificado— y sigue siendo sólido, aunque
pierda peso relativo. **Isabelle/HOL** es el que respalda el resultado más grande del campo,
seL4, y su automatización sigue siendo excelente para lógica de orden superior. **Agda** e
**Idris 2** son mayormente vehículos de investigación en teoría de tipos: elígelos si el objeto
de estudio es el sistema de tipos, no el sistema que estás construyendo.

## Código verificable: cuando el artefacto y la prueba son lo mismo

La especificación va escrita en el propio programa como precondiciones, postcondiciones e
invariantes, y el verificador comprueba que el código las cumple. Desaparece el hueco entre
modelo e implementación, que es la fuga principal de las dos familias anteriores. A cambio,
escribes en el lenguaje que la herramienta impone.

**Dafny** es el más accesible: se lee como C# o Python y es una buena primera puerta de entrada.
**SPARK** es un subconjunto verificable de Ada, con décadas de uso en aeroespacial, defensa y
ferroviario; es la opción cuando hay un regulador que exige evidencia. **F\*** usa tipos
dependientes y se ha empleado donde el fallo no es negociable: la criptografía de HACL\* llega a
Firefox, Linux y Windows. **Verus** y **Kani** llevan la verificación a Rust por dos vías
distintas: Verus demuestra propiedades sobre el código, Kani hace model checking acotado sobre
él. Kani exige mucho menos esfuerzo y da una garantía más débil; suele ser el primer paso
razonable en un proyecto en Rust.

## Refinamiento y especificación clásica: cuando el sistema vive décadas

**B-Method / Event-B** parte de una especificación abstracta y desciende por refinamientos
sucesivos hasta el código, demostrando en cada paso que el refinamiento conserva lo anterior. Es
el método detrás de sistemas de señalización de metro y ferrocarril. Pesa mucho y su ecosistema
es sobre todo de mantenimiento.

**Z**, **VDM** y **PVS** son la generación anterior de la especificación formal. PVS mantiene un
uso real en la NASA. Lo normal hoy es encontrarlos porque el sistema ya los usa, no porque se
elijan para algo nuevo: si empiezas de cero, mira primero las otras tres familias.

## Cómo empezar sin quedarte atascado

1. **Escribe la propiedad en español antes que en ningún lenguaje.** Si no puedes enunciar qué
   debe cumplirse siempre, ninguna herramienta te lo va a decir.
2. **Elige el nivel más barato que responda a tu pregunta.** Un model checker acotado que corre
   en minutos aporta más que una demostración que nunca terminas.
3. **Verifica lo que te daría miedo romper**, no el sistema entero. El objetivo no es una
   cobertura formal completa: es tener demostrado el puñado de invariantes cuyo incumplimiento
   no detectarías a tiempo.
4. **Cuenta con el mantenimiento.** Una especificación que no se actualiza con el código pasa de
   garantía a decorado en un par de versiones.

## Lo que usa storyMaker, y por qué esos dos

El proyecto usa **TLA+** y **Lean 4**, uno de cada una de las dos primeras familias, porque
responde a dos preguntas que no se parecen:

- **TLA+ para el harness.** El bucle de orquestación tiene concurrencia, reintentos con tope y
  máquinas de estado que deben terminar. Ahí el fallo es un entrelazado, y un entrelazado no se
  encuentra con pruebas: se encuentra explorando estados. La especificación está en
  `formal/tla/` y la comprueba TLC.
- **Lean 4 para la cronología.** Los invariantes temporales de la historia —que nada ocurra
  antes de lo que lo causa, que un retcon deje el orden consistente— deben sostenerse para
  *cualquier* novela que el sistema genere, no para las que se prueben. Eso es una demostración,
  no una exploración acotada. Vive en `formal/lean/`.

Ninguno de los dos verifica el texto que escribe el modelo: de eso se ocupan los validadores
programáticos y semánticos. Lo formal cubre el andamiaje y el orden, que es donde un fallo pasa
inadvertido hasta que ya está publicado.
