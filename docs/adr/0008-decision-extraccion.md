---
number: 0008
date: 2026-10-19
title: "Decisión de extracción de módulos del monolito"
status: Accepted
deciders: ["Diego Rosales Garza", "Rodrigo Vazquez Rico", "Angel Fabian Gutierrez Gomez"]
technical-story: "Evaluar si un módulo de El Mapita UTB debe extraerse a un servicio independiente después del reto aplicado sobre el MVP."
---

# ADR-0008: Mantener el monolito modular y no extraer módulos todavía

## Contexto

El sistema está organizado como un monolito modular con módulos de mapas, ubicación, autenticación y POIs. El backend se despliega como una sola API NestJS y el frontend Flutter consume ese backend y Supabase. S11 exige evaluar explícitamente si alguno de esos módulos debe convertirse en un servicio independiente.

Los fallos observados hasta ahora —indisponibilidad de Supabase, modelos inexistentes, deriva de contrato, cold start de Render y conectividad degradada— no requieren separar módulos para ser mitigados. La extracción añadiría comunicación de red, autenticación entre servicios, despliegues independientes, observabilidad distribuida y nuevos puntos de fallo.

## Alternativas consideradas

### A. Extraer un módulo a un servicio independiente

Se evaluó extraer `mapas`, `ubicacion`, `auth` o `pois` como servicios separados. Esto permitiría escalar o desplegar cada capacidad de forma independiente, pero introduciría llamadas de red, contratos entre servicios, gestión de fallos distribuidos y mayor carga operativa para un equipo de tres personas.

### B. No extraer y mantener el monolito modular

Los módulos permanecen separados por límites de código, casos de uso, puertos y adaptadores, pero comparten un despliegue. Esta opción conserva la simplicidad actual y deja preparada una futura extracción si aparecen señales medibles que la justifiquen.

## Criterios de decisión

La extracción se consideraría justificada si se cumple al menos una de estas condiciones:

1. Un módulo necesita escalar de manera independiente y esa diferencia se demuestra con métricas sostenidas.
2. Un módulo requiere un ciclo de despliegue o disponibilidad distinto al resto del sistema.
3. Los límites del módulo son estables y su contrato puede versionarse sin compartir el modelo interno.
4. El costo operativo adicional puede ser asumido por el equipo y el beneficio supera la complejidad introducida.

## Decisión

Se elige la alternativa **B: no extraer por ahora**. Se mantiene el monolito modular para el alcance actual del MVP. Los módulos seguirán aislados internamente mediante capas, interfaces de repositorio, casos de uso y contratos HTTP.

La decisión se revisará mediante un ADR nuevo si alguno de los criterios anteriores aparece con evidencia de producción o si una nueva funcionalidad exige escalado, disponibilidad o ciclo de despliegue independiente.

## Idempotencia y sagas

No se implementa una saga porque el sistema actual no coordina transacciones distribuidas entre varios servicios. Las consultas de mapas, POIs y ubicación son lecturas idempotentes. Las operaciones de escritura que se incorporen deben usar identificadores únicos, validación de estado y respuestas consistentes para evitar duplicados cuando una petición se reintente.

## Consecuencias

### Positivas

- Se conserva un despliegue y una operación simples.
- Se reducen los fallos de red y autenticación entre servicios.
- El equipo puede concentrarse en completar el MVP y resolver EC-01, EC-02 y EC-04.
- Los límites modulares mantienen abierta una extracción futura.

### Negativas

- No existe escalado independiente por módulo.
- Un despliegue del backend afecta a todos los módulos.
- Una falla del proceso puede afectar varias capacidades simultáneamente.

## Referencias

- [ADR-0001: Estilo arquitectónico](0001-estilo-arquitectonico-propuesto.md)
- [arc42 sección 11: Riesgos y deuda técnica](../arc42/arc42-template-EN.md#section-technical-risks)
- [C4 Nivel 2: Contenedores](../c4/C4_L2_Container.md)
