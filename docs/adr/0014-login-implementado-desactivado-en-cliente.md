---
number: 0014
date: 2026-11-22
title: "Cuentas de usuario: login implementado pero desactivado en la app móvil"
status: Accepted
deciders: ["Diego Rosales Garza", "Rodrigo Vazquez Rico", "Angel Fabian Gutierrez Gomez"]
technical-story: "El diseño inicial (arc42 §3, ADR-0011) asumía usuarios autenticados con roles. La versión final de la app abre directamente el mapa 3D del campus sin pedir cuenta, mientras el login sigue en el código. Sin este registro, la documentación y el sistema parecen contradecirse."
---

# ADR-0014: Login implementado pero desactivado en la app

## Contexto

La arquitectura inicial contemplaba cuentas (Supabase Auth), roles y rutas protegidas. La app final tiene un solo caso de uso: ver el mapa 3D, filtrar por categoría, elegir un destino y recibir la guía de llegada. Ese flujo no necesita identificar a nadie.

Estado verificado en el código (2026-11-22):

- **Cliente Flutter:** `LoginPage` y `RegisterPage` existen en `frontend/lib/features/auth/`, y `AuthBloc` está registrado en `core/di/injector.dart`. El router (`frontend/lib/app.dart`) solo define `/splash`, `/map`, `/lugares` y `/location`: **no hay ruta al login**, así que la app no lo muestra.
- **Backend NestJS:** el módulo `auth` y `AuthGuard` siguen activos. Protegen los endpoints de autenticación y la creación de POIs. Las lecturas del mapa (`GET /api/v1/map/...`) son públicas.
- **Datos del mapa:** el modelo `.glb` se descarga del bucket público `mapa-campus` de Supabase Storage y las capas de la tabla `mapa_capas` (lectura pública por RLS). Ninguna de las dos requiere sesión.

## Alternativas

| Opción | Consecuencia |
|---|---|
| A. Obligar a iniciar sesión | Fricción para un estudiante que solo quiere encontrar un salón; exige gestionar cuentas, correos y recuperación de acceso sin aportar al caso de uso. |
| B. Quitar el código de autenticación | Pierde lo ya construido y probado (`guarded-endpoints.spec.ts`) y cierra la puerta a funciones futuras con roles. |
| C. Mantener el login desactivado en el cliente (decisión) | Cero fricción hoy; el backend conserva la protección de las operaciones de escritura; la capacidad queda lista para reactivarse. |

La motivación exacta de dejar de usar cuentas la conoce el equipo y no quedó escrita en el repositorio. **Pendiente de confirmar por el equipo.**

## Decisión

El cliente móvil no expone login ni registro. El código de autenticación se conserva en el cliente y en el backend. Los endpoints de escritura (por ejemplo, crear POIs) siguen exigiendo `AuthGuard` y rol.

## Consecuencias

- **Sin datos personales de cuentas en la app:** se reduce lo expuesto en `docs/seguridad/privacidad.md` (los datos de cuentas ya no se generan desde el cliente).
- **Código sin uso en el cliente:** `LoginPage`, `RegisterPage` y `AuthBloc` son deuda declarada. Si no se reactivan, conviene retirarlos para no confundir.
- **Escritura de POIs:** sin login en la app, solo se puede hacer con un cliente autenticado contra la API (administración).
- **Si se reactiva:** basta añadir las rutas `/login` y `/register` al router y una redirección según el estado de `AuthBloc`. Las mitigaciones de roles del ADR-0011 pasan a aplicar al cliente.
- **Documentación:** arc42 §3 y los stakeholders que mencionan acceso por cuenta describen el diseño original; este ADR es la fuente del estado actual.
