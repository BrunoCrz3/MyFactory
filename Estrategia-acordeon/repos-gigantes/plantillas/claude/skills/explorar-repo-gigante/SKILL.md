---
name: explorar-repo-gigante
description: Buscar, localizar o entender código en un repositorio grande o monorepo sin gastar contexto. Úsala antes de leer ficheros para responder «dónde está X», «quién usa Y», «qué impacto tiene cambiar Z», antes de un cambio que cruza paquetes y antes de una refactorización o migración masiva.
---

# Explorar un repositorio gigante

En un repositorio de millones de líneas, lo caro no es escribir: es leer. Cada fichero que lees
se reenvía en todos los turnos siguientes. Esta skill fija el orden en que se busca y los topes
que no se cruzan.

## 1. Orientarse sin leer

- Lee `MAPA.md` (una línea por carpeta de primer nivel) y el `CLAUDE.md` del área. No listes el
  árbol desde la raíz ni abras ficheros para «hacerte una idea».
- Decide **qué subsistema** toca la tarea. Si no lo sabes, delega la exploración (paso 2) en vez
  de explorar tú.

## 2. Delegar la exploración amplia

Si la pregunta exige recorrer más de un par de ficheros, lanza el subagente `explorador` (o
Explore en «medium» o «very thorough») con una pregunta concreta y el área acotada. Tú solo
recibes su informe.

## 3. La escalera de búsqueda

Usa el primer peldaño que exista en este repositorio y baja solo si no basta:

| Peldaño | Herramienta | Para |
|---|---|---|
| 1 | Índice de código, si está instalado (grafo tipo codebase-memory, Sourcegraph) | Quién llama, dependencias, impacto |
| 2 | LSP (definición, referencias, diagnósticos) | Todas las referencias de un símbolo con nombre repetido; errores de tipo tras editar |
| 3 | `Grep`: primero `files_with_matches` o `count`, con `glob`/`type`; después contenido con `head_limit` | Identificadores exactos |
| 4 | `ast-grep` | Patrones estructurales («todas las llamadas a X sin await») |
| 5 | `Read` por rangos de líneas (≤ 200) | Solo lo que los peldaños anteriores han señalado |

## 4. Topes

- Ningún fichero de más de 300 líneas se lee entero.
- Ningún resultado de búsqueda de más de 50 ficheros se abre: se refina el patrón.
- No se leen vendorizado, generado, build ni lockfiles.
- Los tests se ejecutan acotados (un fichero o un paquete) y a través del filtro de salida.
- Nada de `cat` de logs: `grep` del error o `tail`.

## 5. Cambios grandes

- **Entre paquetes:** plan mode primero. El plan queda en un fichero y sobrevive a la
  compactación; la conversación no.
- **Masivos (N ficheros, mismo patrón):** una regla de `ast-grep --rewrite` o una receta de
  OpenRewrite, probada primero en un fichero, no N ediciones a mano.

## 6. Dejar rastro

Si descubres algo que habría ahorrado la búsqueda (una carpeta sin describir, un punto de
entrada), propón añadir una línea a `MAPA.md` o al `CLAUDE.md` del área.
