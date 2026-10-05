---
number: 0007
date: 2026-10-04
title: "No incorporar un componente de IA generativa en El Mapita UTB (S9)"
status: Accepted
deciders: ["Diego Rosales Garza", "Rodrigo Vazquez Rico", "Angel Fabian Gutierrez Gomez"]
technical-story: "S9 pide una decisión justificada sobre incluir o no un componente generativo en el sistema, evaluando costo y latencia frente a los escenarios de calidad EC-01..EC-04."
---

# ADR-0007: No incorporar un componente generativo dentro del sistema

## Contexto

Se evaluó un asistente generativo en la app (por ejemplo, preguntar en lenguaje natural cómo llegar a un laboratorio, o resumir POIs). El valor de A-01 es mostrar el campus en 3D y la posición del usuario; la búsqueda de POIs ya es una consulta estructurada (`/api/v1/pois`, por piso).

## Alternativas

| Alternativa | Latencia añadida | Costo | Riesgo |
|---|---|---|---|
| A. Sin componente generativo (decisión) | 0 | 0 | Ninguno nuevo |
| B. LLM en la nube vía API desde el backend | Segundos por respuesta (depende de modelo y longitud; **no medido en este proyecto**) | Por token; sin presupuesto asignado y con volumen de uso desconocido | Dependencia externa, secreto adicional, los datos del usuario salen del sistema |
| C. Modelo pequeño en el dispositivo | Alta carga de CPU/RAM en gama media | Sin costo de API, pero aumenta el tamaño de la app | Compite con el presupuesto de render |

## Decisión

**No se incorpora un componente generativo en S9** (alternativa A), por estas razones:

1. **Presupuesto de latencia:** EC-01 exige primera vista interactiva < 5 s p95 y EC-02 ≥ 30 FPS. Un LLM en el camino de carga lo comprometería; en el dispositivo (C) competiría con el render 3D por CPU/GPU.
2. **Disponibilidad offline (EC-04):** la vista debe ser utilizable sin red en < 5 s. Un componente generativo remoto no funciona offline y no podría ser parte del flujo crítico.
3. **Precisión de ubicación (EC-03):** la ubicación y el fallback manual son reglas deterministas y verificables; un modelo generativo añadiría no determinismo donde se exige un umbral exacto (≤ 15 m).
4. **Costo y operación:** el despliegue actual es de $0 (ADR-0004, plan free de Render). Una API de LLM introduce costo variable, un secreto más y riesgo de abuso sin control de cuotas diseñado.
5. **Privacidad:** enviar ubicación a un tercero requeriría consentimiento y un tratamiento de datos que el proyecto no ha diseñado.
6. **Alcance:** el problema (orientarse en el campus) se resuelve con búsqueda estructurada de POIs.

La IA sí se usa como **herramienta de desarrollo** (registrada en `docs/ia.md`), no como componente del producto.

## Consecuencias

- Sin nuevas dependencias de ejecución ni secretos.
- **Condición de revisión:** reabrir con un ADR nuevo si (a) hay presupuesto y cuotas definidos, (b) se mide la latencia real del proveedor y queda fuera de la ruta crítica de EC-01/EC-04, y (c) se define el tratamiento de datos del usuario.
