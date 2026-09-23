# Skills y herramientas para agentes de código

Tres recursos que actúan sobre el agente, no sobre el producto: uno le aporta conocimiento
reutilizable, otro le cambia el criterio, y el tercero le abarata lo que consume al usar la
línea de comandos.

← [Volver al índice](../README.md)

| Recurso | Tipo | Para qué sirve | Cuándo usarlo | Enlace |
| --- | --- | --- | --- | --- |
| Skills for Real Engineers | Colección de skills | Skills de ingeniería extraídas de un directorio `.agents` de uso real y publicadas como repositorio | Cuando quieres partir de skills ya rodadas en trabajo diario en vez de escribir las tuyas desde cero | [github.com/mattpocock/skills](https://github.com/mattpocock/skills) |
| Ponytail | Skill de comportamiento | Empuja al agente a razonar como el desarrollador senior más perezoso de la sala: la mejor línea de código es la que no se escribe | Cuando el agente tiende a sobre-construir, a añadir abstracciones por adelantado o a resolver con código lo que se resuelve borrando | [github.com/DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) |
| RTK | Herramienta de reducción de tokens | Proxy de línea de comandos que reduce el consumo de tokens de los comandos de desarrollo habituales. Binario único en Rust, sin dependencias. Su web declara una reducción del 60-90 % (según su repositorio, 2026-09-23) | Cuando el coste del contexto lo dominan salidas largas de comandos (builds, tests, logs) y no el razonamiento | [github.com/rtk-ai/rtk](https://github.com/rtk-ai/rtk) |

## Cómo se diferencian

**Skills for Real Engineers** es material: un conjunto de skills que se instalan y se invocan.
No impone un método de trabajo; aporta capacidades sueltas que el agente carga cuando tocan.

**Ponytail** no aporta capacidad, aporta sesgo. Es una sola skill cuyo efecto es de criterio:
reducir el volumen de código producido. Conviene medir su efecto antes de darla por buena en un
repositorio con convenciones propias, porque «no escribir código» compite con «seguir el patrón
de la casa».

**RTK** no toca el razonamiento del agente: se interpone entre el agente y la terminal. Es la
única de las tres que se justifica con una cifra, y esa cifra es la que declara el proyecto, no
una medida propia. Su impacto depende por completo de tu mezcla de comandos: si el agente ya
usa herramientas de búsqueda acotadas en vez de volcar ficheros enteros, el margen es menor.

## Enlaces

Los tres resolvían con HTTP 200 el 2026-09-23. Ninguna redirección relevante.
