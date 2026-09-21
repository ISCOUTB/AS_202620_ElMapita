# Contrato de API — El Mapita UTB

Este directorio contiene el contrato de integración versionado entre el frontend Flutter y el backend NestJS. La justificación de la estrategia (OpenAPI vs AsyncAPI) está en [ADR-0003](../adr/0003-contrato-openapi-versionado.md).

## Contenido

- **[`openapi.v1.yaml`](openapi.v1.yaml)** — contrato OpenAPI 3.1, fuente de verdad de las 16 operaciones REST expuestas por el backend (`Health`, `Autenticación`, `Mapas`, `POIs`, `Ubicación`). Los schemas se derivan de los tipos de dominio en `backend/src/modules/*/domain/index.ts`.

## Regla de versionado

| Tipo de cambio | Acción |
|---|---|
| **MAJOR** (incompatible: se quita/renombra un campo o ruta, cambia un tipo, se endurece una validación) | Nuevo archivo `openapi.v2.yaml` + nuevo prefijo de ruta `/api/v2`, con ventana de convivencia documentada en el ADR que lo origine. |
| **MINOR** (campo u operación nueva, opcional y aditiva) | Incrementar `info.version` a `1.x.0` en el mismo archivo. |
| **PATCH** (aclaración de descripción, ejemplo, `summary`) | Incrementar `info.version` a `1.0.x`. |

## Cómo se verifica en el pipeline

El job `contract` de `.github/workflows/ci.yml` corre tres capas, de menor a mayor costo:

1. **Lint** — `npx @redocly/cli lint docs/api/openapi.v1.yaml`. El contrato debe ser OpenAPI 3.1 válido. Bloqueante.
2. **Deriva** — `npm run openapi:drift` (desde `backend/`). Genera el documento real desde los decoradores de NestJS (mismo `setGlobalPrefix` que `src/main.ts`) y compara el conjunto de rutas contra el contrato.
3. **Runtime** — `npm run test:contracts` (desde `backend/`). Levanta la aplicación completa (mismo bootstrap que `main.ts`) con los repositorios/adaptadores hacia Supabase sustituidos por fakes en memoria, ejerce cada operación del contrato con `supertest` y valida las respuestas contra los schemas del contrato con Ajv.

Las capas 2 y 3 están en `continue-on-error: true` mientras **RSK-04** (arc42, sección 11) siga abierto — ver más abajo.

### Correrlas en local

```bash
cd backend
npm install

# capa 1
npx @redocly/cli@latest lint ../docs/api/openapi.v1.yaml

# capa 2
npm run openapi:generate   # escribe backend/.openapi-generated.json (gitignored)
npm run openapi:drift

# capa 3
npm run test:contracts
```

## Estado actual: RSK-04 (deriva conocida, sin corregir)

Al escribir el contrato se encontraron dos desajustes reales entre lo que el frontend consume y lo que el backend expone:

| Endpoint | Frontend consume | Backend expone |
|---|---|---|
| Health check | `GET /health` | `GET /api/health` |
| Cualquier ruta de módulo | `GET /api/v1/map/buildings` (ejemplo) | `GET /api/api/v1/map/buildings` |

El contrato (`openapi.v1.yaml`) declara las rutas **correctas** (las que el frontend espera). `npm run openapi:drift` y `npm run test:contracts` fallan hoy señalando exactamente esto — es el resultado esperado, no un bug de las pruebas. Detalle completo, causa raíz y criterio de cierre en [ADR-0003](../adr/0003-contrato-openapi-versionado.md) y en [`correcciones.md`](../../correcciones.md).

Cuando se corrija el prefijo duplicado, los pasos `openapi:drift` y `test:contracts` en `ci.yml` deben pasar de `continue-on-error: true` a bloqueantes.
