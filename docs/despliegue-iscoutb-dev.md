# Runbook de despliegue en iscoutb.dev — El Mapita UTB

Este documento describe los pasos de configuración del backend en el servidor de la materia `iscoutb.dev`. Solo se despliega el backend NestJS; el frontend Flutter no se despliega aquí.

## Requisitos previos

- Repositorio público `ISCOUTB/AS_202620_ElMapita` en la rama `main`.
- Archivo `deploy/compose.lab.yaml` comprometido en el repositorio.
- Archivo `deploy/.env.example` comprometido en el repositorio (sin valores reales).
- Archivo `deploy/.env` en el computador local con valores de prueba (ignorado por git).

## Paso 1 — Verificar el IaC en el repositorio

Confirma que en la rama `main` existen:

- `deploy/compose.lab.yaml`
- `deploy/.env.example`
- `.gitignore` incluye `deploy/.env`

Haz commit y push si falta algo.

## Paso 2 — Configurar el servicio

1. Abre el proyecto **elmapita**, entorno **production**, servicio **sistema**.
2. Comprueba que el proveedor apunta al repositorio `ISCOUTB/AS_202620_ElMapita`, rama `main`, y Compose Path `./deploy/compose.lab.yaml`.
3. Asegúrate de que **Isolated Deployment** esté activado.

## Paso 3 — Configurar variables de entorno

Escribe una variable por línea con los valores reales. Nunca escribas estos valores en el repositorio.

Ejemplo (reemplaza por los valores reales de tu proyecto Supabase):

```
PORT=3000
NODE_ENV=production
SUPABASE_URL=https://TU-PROYECTO.supabase.co
SUPABASE_SERVICE_ROLE_KEY=TU-CLAVE-REAL-DE-SERVICE-ROLE
SUPABASE_ANON_KEY=TU-ANON-KEY-REAL
FRONTEND_URL=https://elmapita.iscoutb.dev
LOG_LEVEL=info
```

Guarda los cambios.

## Paso 4 — Agregar el dominio público

Agrega un dominio para el servicio `api`:

| Campo | Valor |
|---|---|
| Service Name | `api` |
| Host | `elmapita.iscoutb.dev` |
| Internal Path | vacío (o `/`) |
| Strip Path | no |
| Container Port | `3000` |
| HTTPS | activado |
| Certificate Provider | Let's Encrypt |

**Nota:** El Internal Path se deja vacío porque el backend NestJS ya sirve las rutas de negocio bajo `/api` y expone `/health` y `/metrics` en la raíz.

## Paso 5 — Desplegar

1. Ve a la pestaña **General** del servicio.
2. Pulsa **Deploy**.
3. Espera en **Deployments** hasta que el estado sea **Done**.

> Los cambios de dominio se aplican al volver a desplegar.

## Paso 6 — Verificar

Desde fuera de la universidad, abre:

```
https://elmapita.iscoutb.dev/health
```

También puedes consultar la métrica:

```
https://elmapita.iscoutb.dev/metrics
```

---

## Despliegue controlado por rama (opcional)

Si se prefiere que solo se publique lo que pasó pruebas:

1. Crea una rama `produccion` en el repositorio y protégenla en GitHub (solo pull requests con CI en verde).
2. Cambia la rama del servicio en el panel a `produccion`.
3. Los merges a `produccion` disparan el despliegue.
