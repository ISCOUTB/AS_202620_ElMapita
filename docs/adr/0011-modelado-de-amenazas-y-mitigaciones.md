---
number: 0011
date: 2026-11-01
title: "Modelado de amenazas S11: mitigaciones priorizadas por riesgo"
status: Accepted
deciders: ["Diego Rosales Garza", "Rodrigo Vazquez Rico", "Angel Fabian Gutierrez Gomez"]
technical-story: "S11 pide aplicar un modelado de amenazas (STRIDE) al sistema real, traducirlo en mitigaciones verificables y evaluar cadena de suministro y privacidad."
---

# ADR-0011: Modelado de amenazas y mitigaciones priorizadas

## Contexto

El análisis (`docs/seguridad/`) encontró que la documentación afirmaba controles que el código no tenía: el C4 declara "RBAC JWT", pero ningún endpoint llevaba guard. Dos endpoints marcados como "solo admin" (`POST /v1/auth/users/:userId/role` y `POST /v1/pois`) aceptaban llamadas anónimas, y el rol se leía de `user_metadata`, que el propio usuario puede editar.

## Decisión

1. **Método:** STRIDE sobre el diagrama de flujo de datos de `docs/seguridad/dfd.md`. Riesgo = probabilidad × impacto (1-5). Prioridad: Crítica ≥ 20, Alta 12-19, Media 6-11, Baja ≤ 5.
2. **Autorización explícita por endpoint** con `AuthGuard` + `@Roles(...)` (`backend/src/modules/auth/interfaces/auth.guard.ts`). Se aplica primero a los dos endpoints privilegiados. El guard global "denegar por defecto" queda como siguiente paso, porque exige marcar como públicos los endpoints de lectura del mapa.
3. **El rol vive en `app_metadata`**, que solo escribe la service key. Se lee de ahí en el backend (`supabase-auth-client.ts`).
4. **La ubicación no sale del dispositivo** (DP-1 en `privacidad.md`). Enviarla exige un ADR nuevo.
5. **Cadena de suministro en CI:** job `deps-audit` bloqueante en severidad crítica de producción y Dependabot semanal para npm, pub, Docker y GitHub Actions.

## Alternativas consideradas

| Alternativa | Por qué no |
|-------------|-----------|
| Guard global deny-by-default ahora | Mayor radio de cambio (hay que anotar todos los endpoints públicos); se hace después de cubrir lo crítico |
| Dejar el rol en `user_metadata` y validar solo en el backend | El usuario lo reescribe con el SDK de Supabase; el guard no protegería nada |
| Bloquear CI con severidad alta | Hoy falla por `multer`, que no es explotable aquí (sin subida de archivos) |

## Consecuencias

- **Migración obligatoria de roles:** los usuarios que tenían rol en `user_metadata` vuelven a `estudiante` al leer de `app_metadata`. Hay que asignar de nuevo los administradores desde el panel de Supabase (Authentication → usuario → `app_metadata`: `{"role":"admin_utb"}`). Sin este paso, nadie puede llamar al endpoint de roles.
- La app Flutter sigue leyendo `role` de `userMetadata` (`supabase_auth_client.dart:40, 79, 135`). Es solo informativo en la interfaz, pero debe pasarse a `appMetadata` para coincidir.
- Los DTO siguen siendo `interface`: la validación de entrada (T-04) queda pendiente.

## Estado de las amenazas

| ID | Estado | Evidencia |
|----|--------|-----------|
| T-01, T-03 | Mitigadas | `auth.guard.spec.ts` (6 pruebas) y `guarded-endpoints.spec.ts` (9 pruebas HTTP: 401, 403, 2xx) |
| T-02 | Mitigada en backend, pendiente la migración de datos y el cliente Flutter | `supabase-auth-client.spec.ts` (lee y escribe en `app_metadata`, ignora `user_metadata`) |
| T-11 | Mitigada | `logger.module.spec.ts` comprueba que authorization, cookie, IP y set-cookie no salen en el log |
| T-13 | Parcial | `deps-audit` y Dependabot añadidos; falta fijar imagen por digest |
| Críticas de dependencias | Cerradas | `proxy-addr` 2.0.8; ver `docs/evidencia/s11-npm-audit-prod-despues.json` |
| T-04, T-05, T-06, T-07, T-08, T-09, T-10, T-12, T-15 | Pendientes | Plan en `amenazas.md` |

## Verificación

- Backend: 76 pruebas en verde (15 nuevas; cada control se rompió a propósito y la prueba correspondiente falló), `eslint` sin errores, `nest build`, `openapi:drift` sin deriva y 17 pruebas de contrato en verde.
- Dependencias de producción: de 8 hallazgos (1 crítico) a 4 (0 críticos). Quedan `multer`, `@nestjs/platform-express`, `js-yaml` y `@nestjs/swagger`. `multer` no es alcanzable: no hay subida de archivos.
