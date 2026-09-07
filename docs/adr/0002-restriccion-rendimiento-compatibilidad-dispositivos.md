---
number: 0002
date: 2026-09-07
title: "Restricción de Rendimiento: Soporte al Mayor Rango Posible de Dispositivos Móviles"
status: Accepted
deciders: ["Diego Rosales Garza", "Rodrigo Vazquez Rico", "Angel Fabian Gutierrez Gomez"]
technical-story: "El equipo propone como reto del corte que El Mapita UTB mantenga rendimiento aceptable en el mayor rango posible de dispositivos móviles de la comunidad UTB, incluyendo gama de entrada, sin excluir usuarios por hardware o versión de sistema operativo."
---

# ADR-0002: Restricción de Rendimiento — Soporte al Mayor Rango Posible de Dispositivos Móviles

## Contexto

El Mapita UTB se dirige a toda la comunidad UTB (estudiantes, visitantes, docentes, personal administrativo), un universo de dispositivos Android/iOS heterogéneo en antigüedad, RAM, GPU y versión de sistema operativo. La línea base del proyecto (ADR-0001, aspecto A-01) ya define escenarios de calidad de rendimiento — **EC-01** (carga inicial < 5 s p95) y **EC-02** (fluidez ≥ 30 FPS) — sobre un entorno de referencia de "gama media". El equipo propone como reto de este corte extender esa exigencia: el rendimiento aceptable debe sostenerse también en gama de entrada, para no excluir por hardware a una parte real de la comunidad universitaria.

**Restricciones clave:**
- El renderizado 3D (`.glb`/`.gltf`) es la operación más costosa de la app en CPU/GPU y memoria; es también el punto donde la disparidad de hardware pega más fuerte.
- El riesgo **RSK-02** (arc42 sección 11) ya anticipaba esta tensión: *"disparidad de hardware/GPU Android gama entrada → LOD y fallback a vista esquemática si cae por debajo de 20 FPS"*, pero nunca se había formalizado como restricción de arquitectura ni como decisión registrada.
- No se puede resolver subiendo el `minSdk` o exigiendo GPU dedicada — eso es exactamente lo que la restricción prohíbe.
- El equipo sigue siendo de 3 desarrolladores; la solución debe integrarse en la arquitectura Monolito Modular ya adoptada (ADR-0001), sin introducir nuevos contenedores.

## Alternativas Consideradas

| Alternativa | Descripción | Pros | Contras |
|-------------|-------------|------|---------|
| **1. Fijar gama media como piso soportado** | Declarar explícitamente gama de entrada como no soportada; documentar requisitos mínimos de hardware. | Simple, cero costo de implementación adicional, umbrales EC-01/EC-02 se cumplen sin esfuerzo extra. | Contradice el propósito institucional de la app (accesible a toda la comunidad UTB); excluye justamente al segmento con mayor necesidad de orientación (estudiantes de nuevo ingreso con equipos más modestos). |
| **2. Niveles de detalle (LOD) + degradación progresiva** ✅ **SELECCIONADA** | Servir mallas `.glb` con múltiples niveles de detalle según capacidad detectada del dispositivo; caer automáticamente a una vista esquemática 2D si el frame rate baja de un umbral (20 FPS, como ya anticipa RSK-02). | Mantiene el valor diferencial del mapa 3D en dispositivos capaces; garantiza usabilidad mínima (vista esquemática) en gama de entrada; reutiliza la caché de dos niveles (DEC-04) y el puerto `ModelRenderer`/`MapRenderer` ya previsto en la arquitectura del ADR-0001; no requiere nuevos contenedores en C4. | Más trabajo de diseño e implementación (generar/mantener varios niveles de detalle por modelo, lógica de detección de capacidad y de caída de calidad). |
| **3. Vista 2D/esquemática como modo primario, 3D opcional** | Invertir el orden: la app arranca en un plano 2D del campus y el modo 3D es una mejora opcional activable. | Compatibilidad máxima garantizada por diseño; menor riesgo de regresión de rendimiento. | Sacrifica el valor diferencial del aspecto A-01 ("mapa 3D interactivo con geolocalización"), que es el atractivo central del producto frente a un mapa estático. |

**Análisis:** la alternativa 1 es la más barata pero incumple el propósito del reto por diseño. La alternativa 3 es la más segura técnicamente pero renuncia a la propuesta de valor ya validada en A-01. La alternativa 2 preserva ambos: rendimiento aceptable en todo el rango de dispositivos y el mapa 3D como experiencia principal donde el hardware lo permite.

## Decisión

**Adoptamos LOD + degradación progresiva** como estrategia para cumplir RES-04:

- El contenedor `App Móvil Flutter` (C4 Nivel 2, sin cambios en sus límites) incorporará, dentro de `features/mapas/infrastructure/renderer/` (puerto `MapRenderer` ya previsto en el ADR-0001), la selección de nivel de detalle por modelo y la lógica de caída a vista esquemática.
- `features/mapas/infrastructure/storage/model_cache.dart` deberá indexar variantes de un mismo modelo por nivel de detalle, no solo por versión.
- El umbral de degradación (< 20 FPS sostenidos → vista esquemática) es el mismo ya declarado en RSK-02; esta decisión lo convierte de riesgo mitigable a comportamiento de diseño obligatorio.
- Los umbrales de EC-01 y EC-02 (arc42 sección 10.2) no cambian; lo que cambia es el entorno de referencia sobre el que se exige cumplirlos, que ahora incluye gama de entrada (ver "Impacto de RES-04" en arc42 sección 2).

## Consecuencias

### Positivas (Beneficios Esperados)

| Área | Impacto |
|------|---------|
| **Inclusión** | Ningún usuario queda excluido de la orientación básica del campus por tener un dispositivo de gama baja. |
| **Reutilización arquitectónica** | Se apoya en decisiones ya tomadas (DEC-04 caché dos niveles, puerto `MapRenderer`) en lugar de introducir mecanismos nuevos. |
| **Límites C4 estables** | La estrategia vive dentro del contenedor existente; no se toca el Nivel 1 ni el Nivel 2 del modelo C4. |
| **Riesgo ya mitigado por diseño** | RSK-02 deja de ser solo un riesgo anotado y pasa a tener una decisión de arquitectura que lo gobierna. |

### Negativas / Compromisos Técnicos (Trade-offs)

| Compromiso | Mitigación |
|------------|------------|
| **Costo de producción de assets 3D** | Generar múltiples niveles de detalle por edificio/piso incrementa el trabajo de modelado y el tamaño total almacenado en Supabase Storage. Mitigación: priorizar LOD solo en los edificios de mayor tráfico en un primer momento. |
| **Complejidad de detección de capacidad** | Detectar de forma confiable la capacidad de un dispositivo Android/iOS es heurístico, no exacto. Mitigación: usar frame rate medido en tiempo real (ya alineado con la medición de EC-02) como señal principal, en vez de intentar clasificar el hardware por adelantado. |
| **Estado de implementación: pendiente** | Esta decisión define el diseño a seguir, pero **no se ha implementado código todavía** — el corte actual se concentró en estabilizar el esqueleto de la aplicación (ver `docs/aspectos.md`, columnas Pruebas/Evidencia). La implementación queda como deuda declarada y explicada en `correcciones.md`. |

## Referencias

- [ADR-0001: Estilo Arquitectónico Monolito Modular](0001-estilo-arquitectonico-propuesto.md)
- [arc42 Sección 2: Restricciones de arquitectura — RES-04](../arc42/arc42-template-EN.md#section-architecture-constraints)
- [arc42 Sección 10.2: Escenarios de calidad EC-01 y EC-02](../arc42/arc42-template-EN.md#ec-01)
- [arc42 Sección 11: Riesgos y deuda técnica — RSK-02](../arc42/arc42-template-EN.md#section-technical-risks)
- [C4 Nivel 2 — Contenedores](../c4/C4_L2_Container.png) ([Mermaid](../c4/C4_L2_Container.md))
- [Justificación de la deuda de implementación](../../correcciones.md)
