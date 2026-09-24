# Plantillas para un repositorio de cliente

Configuración propia (no de terceros) que aplica la Fase 1 del [plan de adopción](../README.md#5-adopción-por-fases-en-un-repositorio-de-cliente).
Está en `claude/`, sin punto, para que no configure Claude Code mientras se trabaja en MyFactory:
al copiarla al cliente, pasa a llamarse `.claude/`.

← [Volver al bloque](../README.md)

## Qué hay

| Fichero | Destino en el repo del cliente | Qué hace | Versionado |
|---|---|---|---|
| [claude/settings.json](claude/settings.json) | `.claude/settings.json` | `Read` deny de vendor, generado, build y lockfiles; límites de salida más bajos; worktrees dispersos; registra el hook | Sí |
| [claude/settings.local.json](claude/settings.local.json) | `.claude/settings.local.json` | `claudeMdExcludes` para paquetes ajenos (personal) | No: añadirlo al `.gitignore` |
| [claude/hooks/filtrar-salida-tests.sh](claude/hooks/filtrar-salida-tests.sh) | `.claude/hooks/` | Deja pasar solo los fallos de los tests, conserva el exit code y guarda la salida completa en un fichero | Sí |
| [claude/agents/explorador.md](claude/agents/explorador.md) | `.claude/agents/` | Subagente de solo lectura con `model: haiku` e informe de 40 líneas como máximo | Sí |
| [claude/skills/explorar-repo-gigante/SKILL.md](claude/skills/explorar-repo-gigante/SKILL.md) | `.claude/skills/explorar-repo-gigante/` | Orden de búsqueda (índice → LSP → Grep → ast-grep → rangos) y topes de lectura | Sí |
| [CLAUDE.md.plantilla](CLAUDE.md.plantilla) | `CLAUDE.md` (raíz) | Raíz corta: orientación, comandos, reglas globales, qué preservar al compactar | Sí |
| [MAPA.md.plantilla](MAPA.md.plantilla) | `MAPA.md` (raíz) | Una línea por carpeta de primer nivel, con dueño y punto de entrada | Sí, regenerado en CI |

## Cómo instalarlas

```bash
# Desde la raíz del repositorio del cliente
P=<ruta a MyFactory>/Estrategia-acordeon/repos-gigantes/plantillas
mkdir -p .claude
cp -r "$P/claude/." .claude/
cp "$P/CLAUDE.md.plantilla" CLAUDE.md      # si ya existe, fusionar a mano
cp "$P/MAPA.md.plantilla" MAPA.md
echo ".claude/settings.local.json" >> .gitignore
```

Si el cliente ya tiene `.claude/settings.json`, **no lo sobrescribas**: fusiona las claves
`permissions.deny`, `env`, `worktree` y `hooks`.

## Qué hay que ajustar siempre

1. **`permissions.deny`:** quitar lo que en ese repositorio sea código propio (en algunos
   proyectos `out/` o `build/` son fuente) y añadir sus carpetas generadas. Bloquear los
   lockfiles impide al agente leerlos en tareas de dependencias; si esas tareas son frecuentes,
   quitar esas tres reglas.
2. **`worktree.sparsePaths`:** sustituir los marcadores `RUTA/...` por los directorios del área
   de trabajo, o borrar el bloque `worktree` si no se usan worktrees. Deja siempre `.claude`.
3. **Hook:** ajustar la expresión `re` a los runners de test del cliente y `fallos` a su formato
   de error. Requiere `bash` y `jq`; sin `jq`, el hook no hace nada.
4. **`CLAUDE.md` y `MAPA.md`:** rellenar los marcadores `<...>`. Los ejemplos de carpetas del
   mapa son ficticios: bórralos. No pongas datos reales de personas (dueños por equipo, no por
   nombre).
5. **`claudeMdExcludes`:** los globs se comparan con rutas absolutas, así que tienen que empezar
   por `**/`.

## Windows

- **Hook:** el comando registrado invoca `bash` de forma explícita, así que hace falta Git Bash
  en el `PATH`, y también `jq` (por ejemplo, `winget install jqlang.jq`).
- **`settings.local.json`:** la documentación avisa de que en Windows puede no leerse desde la
  raíz del repositorio. Si se arranca desde subdirectorios, escribir las reglas `Read(...)` con
  rutas `//` absolutas.
- **Plugins LSP:** el binario del servidor tiene que estar en el `PATH`.

## Cómo comprobar que funcionan

| Pieza | Comprobación |
|---|---|
| CLAUDE.md por capas y excludes | `/context` → sección *Memory files*: solo la raíz y el área |
| `Read` deny | Pedir que lea un fichero de `dist/`: debe negarse |
| Hook | Pedir que ejecute un test que falla: tiene que aparecer `--- exit=<no 0>` y solo las líneas de fallo |
| Subagente | `/agents` lo lista; al pedir «usa explorador para…», el principal recibe solo el informe |
| Skill | `/skills` la lista; una pregunta tipo «¿dónde se calcula X?» debería activarla |
| Ahorro | Repetir la suite de la Fase 0 y comparar con `/usage` y `session-report` |

## Probado

El hook se ha probado el 2026-09-24 en Git Bash con jq 1.8.1:

- Los comandos compuestos (`;`, `$(...)`) y los que no son de test no se tocan.
- Una suite simulada que falla (exit 3, 300 líneas) devuelve solo las dos líneas de fallo y
  `exit=3`.
- Una que pasa devuelve las 5 últimas líneas y `exit=0`.
- Los demás campos de la entrada (`description`) se conservan.
