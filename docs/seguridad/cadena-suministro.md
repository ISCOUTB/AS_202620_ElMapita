# S11 — Cadena de suministro: análisis de dependencias

> Amenaza relacionada: T-13 en [`amenazas.md`](./amenazas.md). Fecha del análisis: 2026-11-01.

## 1. Herramienta usada y alcance

| Ecosistema | Herramienta | Comando | Evidencia |
|------------|-------------|---------|-----------|
| Backend (npm, `package-lock.json`) | `npm audit` (base de avisos GitHub Advisory) | `npm audit --omit=dev --json` y `npm audit --json` | [`s11-npm-audit-prod.json`](../evidencia/s11-npm-audit-prod.json), [`s11-npm-audit-full.json`](../evidencia/s11-npm-audit-full.json) |
| Frontend (pub, `pubspec.lock`) | `dart pub outdated` | `dart pub outdated --no-dev-dependencies` | [`s11-dart-pub-outdated.txt`](../evidencia/s11-dart-pub-outdated.txt) |

Limitación declarada: `dart pub outdated` informa versiones atrasadas y paquetes descontinuados, **no** vulnerabilidades. El frontend queda sin análisis de avisos de seguridad hasta incorporar OSV-Scanner (sección 5). Tampoco se escaneó la imagen Docker: Trivy no está instalado en esta máquina.

## 2. Resultado del backend

| Alcance | Crítica | Alta | Moderada | Baja | Total |
|---------|---------|------|----------|------|-------|
| Producción (`--omit=dev`) | 1 | 4 | 3 | 0 | 8 |
| Completo (incluye desarrollo) | 2 | 7 | 35 | 1 | 45 |

Lo que importa es el alcance de producción: 8 hallazgos. Los otros 37 están en dependencias de desarrollo (jest, eslint, ts-jest, `@nestjs/cli`) que no entran en la imagen final (`Dockerfile:25-26` ejecuta `npm prune --omit=dev`).

### 2.1 Hallazgos en producción, con evaluación de alcance real

| Paquete | Severidad | Origen | Problema | ¿Explotable aquí? | Acción |
|---------|-----------|--------|----------|-------------------|--------|
| `proxy-addr` 2.0.7 | Crítica | `express` (vía `@nestjs/platform-express`) | Suplantación de IP con subredes IPv4-mapeadas (GHSA-jqcg-44mw-7w3h) | **Hoy no**: `main.ts` no activa `trust proxy`. **Sí al añadir throttling por IP** (T-05/T-06) detrás de Render/Dokploy, donde hay que activarlo. | Actualizar a ≥ 2.0.8 antes de activar el throttler. |
| `multer` | Alta | `@nestjs/platform-express` | 6 avisos de DoS y bypass de límites | **No**: no hay `FileInterceptor` ni subida multipart en `backend/src`. | Actualizar igualmente; no hay mitigación de código necesaria. |
| `body-parser` | Alta | `express` | DoS con bytes tras un cuerpo comprimido (GHSA-27r3-jxmh-p828) | **Sí**: parsea todos los cuerpos JSON de `POST /auth/*`, `/pois`, `/location`. | Actualizar; sumar límite de tamaño de body (T-06). |
| `joi` 17.13.x | Alta | Directa (`config.module.ts`) | Prototype replacement y DoS por regex (3 avisos) | **Bajo**: Joi solo valida variables de entorno al arrancar, no entrada de usuarios. | Actualizar a ≥ 17.13.9. |
| `@nestjs/platform-express` | Alta | Directa | Agrega los avisos de `multer`/`body-parser` | Ver filas anteriores | Actualizar. |
| `js-yaml` | Moderada | `@nestjs/swagger` | CPU por claves de merge (GHSA-r3ph-w7gj-g6xm) | **Bajo**: solo se procesa YAML propio al generar Swagger. | Actualizar. |
| `@nestjs/swagger` | Moderada | Directa | Agrega `js-yaml` | Ver fila anterior | Actualizar. |
| `qs` | Moderada | `express` | 3 avisos de DoS en el parseo de query strings | **Sí**: parsea la query de todos los endpoints. | Actualizar a ≥ 6.16.1. |

### 2.2 Hallazgos solo de desarrollo que conviene conocer

- `handlebars` 4.7.9, **crítica** (inyección de JavaScript con plantillas precompiladas). Viene de `ts-jest` y no llega a la imagen de producción. Riesgo: solo en CI/desarrollo, si se compilaran plantillas no confiables, lo que aquí no ocurre.
- `npm audit` propone como arreglo bajar `eslint` a 4.0.0 y `jest` a 29.7.0. Son **retrocesos mayores sin sentido** (artefacto del resolutor de npm). No se deben aplicar.

### 2.3 Remediación disponible

`npm audit fix --dry-run --omit=dev` indica que los 8 hallazgos de producción se corrigen **sin saltos mayores** con `npm audit fix` (actualiza `package-lock.json`). No se ejecutó: modificar el lockfile corresponde al paso 5, con las pruebas del backend como red de seguridad.

## 3. Resultado del frontend

`dart pub outdated --no-dev-dependencies`:
- 46 dependencias bloqueadas en versiones anteriores; 17 limitadas por restricciones de `pubspec.yaml`.
- Paquetes **descontinuados**: `flutter_secure_storage_macos` y `js`. El primero es el que guarda los tokens de sesión en macOS (AS-1); un paquete sin mantenimiento no recibirá parches.
- Sin avisos de vulnerabilidad: ver limitación de la sección 1.

## 4. Riesgos de cadena de suministro que no son dependencias

| Riesgo | Evidencia | Mitigación propuesta |
|--------|-----------|----------------------|
| Imagen base por tag flotante | `Dockerfile:18, 28` (`node:22-slim`) | Fijar por digest (`node:22-slim@sha256:…`) y revisarlo con Dependabot. |
| Herramientas de CI en `latest` | `ci.yml:100` (`@redocly/cli@latest`), `ci.yml:148` (`gitleaks:latest`) | Fijar versión exacta. |
| Actions de terceros por tag | `ci.yml` (`actions/checkout@v4`, `SonarSource/...@v5`, `lycheeverse/...@v2`) | Fijar por SHA de commit las de terceros. |
| Secretos | `gitleaks` ya corre en cada push (`ci.yml:135-148`) | Revisar cada entrada de `.gitleaksignore` y su justificación. |
| Script de instalación | `@scarf/scarf` ejecuta `postinstall` (aviso de npm) | Aprobar o bloquear explícitamente con `allowScripts`. |
| Sin SBOM | No existe | Generar CycloneDX en CI y adjuntarlo como artefacto. |

## 5. Plan de automatización (paso 5)

1. Job `deps-audit` en `ci.yml`: `npm audit --omit=dev --audit-level=high` bloqueante, con excepciones documentadas en este archivo.
2. OSV-Scanner sobre `backend/package-lock.json` y `frontend/pubspec.lock` (cubre el hueco del frontend).
3. Trivy sobre la imagen construida en el job `docker`.
4. `.github/dependabot.yml` para `npm`, `pub`, `docker` y `github-actions`.
5. SBOM CycloneDX como artefacto del pipeline.
6. Responsable: DevOps; revisión de excepciones: Backend.

## 6. Después de la remediación (2026-11-01)

Se ejecutó `npm audit fix --omit=dev` y se restauró `node_modules` con `npm ci`. Evidencia: [`s11-npm-audit-prod-despues.json`](../evidencia/s11-npm-audit-prod-despues.json).

| Alcance | Crítica | Alta | Moderada | Total |
|---------|---------|------|----------|-------|
| Producción antes | 1 | 4 | 3 | 8 |
| Producción después | 0 | 2 | 2 | 4 |

Cerrados: `proxy-addr` (ahora 2.0.8), `body-parser`, `qs` y `joi`. Quedan `multer` 2.4.0 (requiere ≥ 2.5.0), `@nestjs/platform-express`, `@nestjs/swagger` y `js-yaml`.

**Excepción documentada:** `multer` no es alcanzable porque el backend no tiene `FileInterceptor` ni subida multipart (búsqueda en `backend/src`). Se revisa cuando Dependabot proponga `multer` ≥ 2.5.0. El job `deps-audit` solo bloquea críticos hasta cerrar esta excepción.

**Advertencia de herramienta:** `npm audit fix --omit=dev` elimina las devDependencies de `node_modules`; hay que ejecutar `npm ci` después.
