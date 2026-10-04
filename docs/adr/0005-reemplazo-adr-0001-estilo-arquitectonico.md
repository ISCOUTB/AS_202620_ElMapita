---
number: 0005
date: 2026-10-04
title: "Reemplazo de ADR-0001: Estilo Arquitectónico Monolito Modular (enlaces C4 actualizados)"
status: Accepted
supersedes: "ADR-0001"
deciders: ["Diego Rosales Garza", "Rodrigo Vazquez Rico", "Angel Fabian Gutierrez Gomez"]
technical-story: "ADR-0001 fue editado después de ser aceptado (commits 07b36f4 y 9ee88c5), violando la regla de no reescritura. Se restaura su texto original y este ADR registra formalmente el cambio."
---

# ADR-0005: Reemplazo de ADR-0001

## Contexto

El ADR-0001 (aceptado el 2026-08-22, commit `aa16382`) se modificó en una línea de la sección de referencias: el enlace único `../c4/C4_Contexto.png` pasó a apuntar a `C4_L1_Context` y `C4_L2_Container` (PNG y Mermaid) y a `docs/c4/contexto.md`, porque los diagramas C4 se renombraron y ampliaron en S06/S07.

Un ADR aceptado es inmutable: solo puede cambiar su campo `status`. Editar su contenido borra la huella de lo que el equipo decidió en su momento.

## Decisión

1. **Se mantienen sin cambio todas las decisiones DEC-01 a DEC-06 del ADR-0001** (Monolito Modular, desacoplo de Supabase, BLoC, caché de 2 niveles, fallback manual, OpenAPI tipado). Este ADR no introduce una decisión técnica nueva.
2. **El texto de ADR-0001 se restauró a su versión aceptada** (`git checkout aa16382 -- docs/adr/0001-...md`); su único cambio permitido es `status: "Superseded by ADR-0005"`.
3. **Las referencias vigentes del ADR-0001 son ahora las de este ADR:**
   - [C4 Nivel 1 - Contexto](../c4/C4_L1_Context.png) ([Mermaid](../c4/C4_L1_Context.md))
   - [C4 Nivel 2 - Contenedor](../c4/C4_L2_Container.png) ([Mermaid](../c4/C4_L2_Container.md))
   - [C4 Nivel 3 - Componentes Backend](../c4/C4_L3_Component_Backend.md)
   - Detalle: [`docs/c4/contexto.md`](../c4/contexto.md)
4. Para el contenido de las decisiones, leer [ADR-0001](0001-estilo-arquitectonico-propuesto.md) junto con este ADR.

## Consecuencias

- La trazabilidad de `docs/aspectos.md` (columna ADR) sigue apuntando a ADR-0001 para DEC-01..DEC-06; allí se añade la referencia a ADR-0005 como vigente.
- **Regla para el equipo:** desde S9, cualquier cambio de contenido a un ADR `Accepted` se hace con un ADR nuevo que declare `supersedes`.
