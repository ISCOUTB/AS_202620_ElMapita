---
number: 0006
date: 2026-10-04
title: "Reemplazo de ADR-0003: Contrato OpenAPI versionado con cierre de RSK-04 y bug de inyección de dependencias"
status: Accepted
supersedes: "ADR-0003"
deciders: ["Diego Rosales Garza", "Rodrigo Vazquez Rico", "Angel Fabian Gutierrez Gomez"]
technical-story: "ADR-0003 fue editado después de ser aceptado (commit 9ee88c5) para registrar el cierre de RSK-04 y un hallazgo nuevo. Se restaura su texto original y este ADR recoge formalmente esos cambios."
---

# ADR-0006: Reemplazo de ADR-0003

## Contexto

El ADR-0003 (aceptado el 2026-09-20, commit `afae3be`) decía en su punto 4 que **no** se corregía el desajuste de rutas (RSK-04) y que los pasos de deriva y runtime eran no bloqueantes. El commit `9ee88c5` reescribió ese ADR para reflejar que RSK-04 se cerró. Eso contradice la regla de no reescritura: la decisión original quedó borrada.

## Decisión

La estrategia de contrato (OpenAPI 3.1 versionado, tres capas de verificación en CI: lint, deriva, runtime) **se mantiene tal cual en [ADR-0003](0003-contrato-openapi-versionado.md)**. Este ADR registra lo que cambió desde entonces y sustituye los puntos afectados:

1. **Vínculo con EC-01.** `GET /api/v1/map/buildings/{buildingId}` y `GET /api/v1/map/floors/{floorId}/model` son las llamadas de `LoadBuildingUseCase` en la carga inicial (arc42 §6.1). Mientras RSK-04 estuvo abierto respondían `404`, así que EC-01 era incumplible; cerrarlo es condición necesaria (no suficiente) para medir EC-01 y EC-02.
2. **Cierre de RSK-04 (reemplaza el punto 4 de ADR-0003).** Se quitó el prefijo `api/` redundante de los 4 controladores (`@Controller('v1/map')`, `v1/pois`, `v1/auth`, `v1/location`) y se excluyó `health` (y luego `metrics`) del prefijo global. `npm run openapi:drift` reporta 0 rutas en deriva y los pasos de deriva/runtime del job `contract` ya son bloqueantes. Evidencia histórica de la detección en rojo: run 35549974182.
3. **Hallazgo adicional: DI rota en 14 casos de uso.** Los casos de uso de `mapas`, `pois`, `auth` y `ubicacion` tipaban dependencias por interfaz sin `@Inject('Token')`; al borrarse las interfaces en compilación, Nest inyectaba `undefined` y cada endpoint real respondía `500`. Se corrigió con `@Inject('Token')` + `@Injectable()` en los 14 sitios, y la prueba de contrato runtime ahora valida el **cuerpo** de las respuestas 2xx, no solo el código de estado.
4. **Consecuencias actualizadas.** Los compromisos "RSK-04 permanece sin corregir" y "detección temprana de deriva (dos desajustes)" del ADR-0003 quedan reemplazados por: RSK-04 cerrado; el bug de DI llevaba oculto desde agosto y ya está cubierto por la validación de cuerpo en CI.

El ADR-0003 se restauró a su versión aceptada (`afae3be`) y solo cambia su `status` a `Superseded by ADR-0006`.
