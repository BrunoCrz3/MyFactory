# Spec Driven Development

El desarrollo dirigido por especificación (SDD) invierte el orden habitual con agentes: primero
se acuerda qué debe hacer el sistema, y el código se genera contra ese acuerdo. Lo que cambia
entre métodos no es la idea, sino **cuál es el artefacto central**, **cuántas puertas hay antes
del código** y **quién aprueba cada una**.

← [Volver al índice](../README.md)

## Los documentos de este bloque

| Documento | Qué contiene |
| --- | --- |
| [open-source.md](open-source.md) | 7 métodos publicados como repositorio, de los ligeros a los de ciclo completo |
| [comerciales.md](comerciales.md) | 6 productos, con sus afirmaciones marcadas como tales |
| [comparativa.md](comparativa.md) | Comparativa por flujo, peso, greenfield/brownfield y agentes soportados, con el flujo de storyMaker como referencia |

## Cómo elegir entre open source y comercial

La diferencia práctica no es el precio, son tres cosas:

**Dónde vive la especificación.** Los métodos open source dejan la spec en tu repositorio, en
Markdown, versionada con el código. Varios productos comerciales la alojan en su plataforma: eso
aporta validación y trazabilidad que un fichero no da, y a cambio la spec deja de vivir donde
vive el código.

**A qué te ata.** Un método open source es un conjunto de prompts y convenciones: cambiar de
agente cuesta poco. Entre los comerciales hay de todo, desde los que se declaran agnósticos del
agente hasta los que son un IDE.

**Cuánto proceso impone.** Un método ligero añade una puerta antes de escribir. Uno de ciclo
completo añade roles, plantillas y artefactos intermedios. En un proyecto pequeño, el proceso
pesado se abandona a la tercera funcionalidad; en uno grande, el ligero deja de sujetar. Elegir
mal en esta dimensión es lo que más caro sale.

## Sobre el greenfield y el brownfield

Casi todos los métodos nacieron para empezar de cero, y se nota: presuponen que la spec precede
al código. En un repositorio existente el problema es el inverso — el comportamiento ya está
escrito y nadie lo ha declarado — y solo algunos métodos lo abordan de frente, leyendo el código
para extraer de él las convenciones y la documentación que faltan. Está señalado recurso a
recurso en la [comparativa](comparativa.md).
