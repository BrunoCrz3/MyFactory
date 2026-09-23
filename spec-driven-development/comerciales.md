# Productos comerciales de SDD

Seis productos. **Todo lo que aquí se atribuye a un producto —cobertura, alcance, capacidades—
procede de su propia comunicación pública y no está verificado de forma independiente.** Va
marcado como «según su web, 2026-09-23». Las columnas de valoración están marcadas igual.

← [Volver al bloque](README.md) · [Open source](open-source.md) · [Comparativa](comparativa.md)

| Producto | Artefacto central | Ata a | Orientación (valoración propia, 2026-09-23) | Enlace |
| --- | --- | --- | --- | --- |
| EasySpecs | Spec + Trust Spec sobre código existente | Nada: eliges el agente que genera el código (según su web, 2026-09-23) | Brownfield | [easyspecs.ai](https://easyspecs.ai) |
| Kiro | Requisitos, diseño y ficheros de dirección | Su IDE, basado en VS Code | Greenfield | [kiro.dev](https://kiro.dev) |
| Tessl | La spec como artefacto principal | Su plataforma | Greenfield | [tessl.io](https://tessl.io) |
| BrainGrid | Plan y descomposición en tareas | Nada: agnóstico del agente (según su web, 2026-09-23) | Ambos | [braingrid.ai](https://www.braingrid.ai) |
| CodeMySpec | Comprobación de que el código cumple la spec | Su plataforma | Ambos | [codemyspec.com](https://codemyspec.com) |
| Augment Code (Cosmos) | Contexto persistente de la arquitectura | Su plataforma | Brownfield a gran escala | [augmentcode.com](https://www.augmentcode.com) |

## EasySpecs

Plataforma de SDD construida para bases de código existentes. Su flujo empieza al revés que el
resto: primero genera documentación técnica y funcional del código real —declara alcanzar hasta
un 98 % de las líneas de código (según su web, 2026-09-23)— y solo sobre esa base escribe las
especificaciones.

Cada spec va emparejada con una **Trust Spec**: validadores, casos límite y pruebas de
reversión. El conjunto pasa por una cascada de comprobaciones deterministas y probabilísticas
(según su web, 2026-09-23). No está atado a ningún proveedor: la generación de código la hace el
agente que tú elijas.

Es el producto cuyo planteamiento se parece más a lo que en este catálogo se llama verificación:
la spec no es solo una descripción, viene con qué la refuta.

## Kiro

IDE dirigido por especificación, basado en VS Code, desarrollado por AWS. Produce documentos de
requisitos, documentos de diseño y ficheros de dirección (*steering files*) que guían al agente
a lo largo del proyecto.

La contrapartida es evidente: el método viene dentro de un IDE, así que adoptarlo es adoptar el
entorno. Si tu equipo ya trabaja en otro, la fricción no está en el flujo sino en la mudanza.

## Tessl

Plataforma para desarrollo nativo de IA en la que la especificación es el artefacto principal,
no un paso previo: el código se considera derivado de ella. Es la apuesta más radical del grupo
por el desplazamiento del centro de gravedad del repositorio.

## BrainGrid

Herramienta de planificación y descomposición de especificaciones, agnóstica del agente: prepara
el trabajo y luego se lo entrega al agente de código que ya uses. No genera el código.

Ese recorte de alcance es su virtud: se añade a un flujo existente sin desplazar nada, y su
único punto de contacto es el plan.

## CodeMySpec

Herramienta de SDD centrada en comprobar que el código efectivamente se corresponde con la spec.
Ocupa el extremo opuesto del ciclo al de la mayoría: no ayuda tanto a escribir la especificación
como a detectar cuándo el código se ha separado de ella.

## Augment Code (Cosmos)

Aborda el SDD desde el lado del contexto. Su motor persistente entiende la arquitectura a lo
largo de bases de código grandes y coordina varios agentes sobre ese entendimiento común.

La premisa es que en un repositorio grande el cuello de botella no es redactar la spec, sino que
el agente sepa dónde encaja lo que va a escribir.

## Enlaces

Los seis resolvían con HTTP 200 el 2026-09-23.
