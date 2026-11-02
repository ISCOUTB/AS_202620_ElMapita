# S11 — Privacidad y minimización de datos

> Amenazas relacionadas: T-11, T-16 en [`amenazas.md`](./amenazas.md). Fecha del análisis: 2026-11-01.
> Marco de referencia: Ley 1581 de 2012 de Colombia (protección de datos personales / habeas data). Este documento es una evaluación técnica del equipo, no asesoría jurídica.

## 1. Hallazgo principal: la ubicación no sale del dispositivo

Se revisó todo `frontend/lib` y `backend/src` buscando envío de coordenadas (`post`, `insert`, `upsert`, canales Realtime, rutas `/location`).

| Qué se comprobó | Resultado | Evidencia |
|-----------------|-----------|-----------|
| La app envía lat/long a la API o a Supabase | **No** | Ningún `post/insert/upsert/channel` recibe coordenadas en `frontend/lib` |
| La ubicación en tiempo real se procesa | **Solo en el dispositivo**: se convierte a coordenadas del modelo 3D y se inyecta en el visor | `campus_model_page.dart:177-203` (`watchPosition` → `_onPosition` → `runJavaScript`) |
| La ubicación se persiste | **No**: ni Hive, ni SharedPreferences, ni SecureStorage la guardan | `local_storage.dart` solo guarda rutas de modelos; `secure_storage.dart` solo tokens y `userId` |
| El backend recibe o guarda ubicación | **No**: el adaptador de plataforma es un stub que devuelve `0,0` | `location-adapter.ts:6-27` |
| `POST /v1/location/manual` | Existe, pero el caso de uso solo arma un objeto en memoria; no hay repositorio | `ubicacion.controller.ts:26-31` |

**Conclusión:** la ubicación en tiempo real es un dato que se trata de forma local y efímera. Es la mejor decisión de minimización posible y debe quedar como **decisión de diseño explícita** (ver sección 5, DP-1).

> Si alguien del equipo conoce un flujo que envíe la ubicación fuera (otra rama, otro build o una versión desplegada distinta), debe indicarlo con el archivo o la captura de red. Con esa evidencia, este documento y T-16 se actualizan: habría que añadir base de legitimación, consentimiento específico, redondeo de coordenadas y plazo de retención.

## 2. Inventario de datos personales

| Dato | Titular | Dónde se guarda | Quién lo trata | Finalidad | Evidencia |
|------|---------|-----------------|----------------|-----------|-----------|
| Correo electrónico | Usuario registrado | Supabase Auth | Supabase (encargado) | Identificación e inicio de sesión | `supabase-auth-client.ts:43-49` |
| Nombre | Usuario registrado | `user_metadata` en Supabase | Supabase | Mostrar el perfil | `use-cases.ts:59` |
| Contraseña | Usuario registrado | Supabase Auth (hash) | Supabase | Autenticación. El backend la reenvía y no la guarda | `supabase-auth-client.ts:22-25` |
| Rol | Usuario registrado | `user_metadata` (ver T-02) | Supabase | Control de acceso | `supabase-auth-client.ts:110` |
| Tokens de sesión | Usuario registrado | `SecureStorage` del dispositivo | Dispositivo | Mantener la sesión | `supabase_auth_client.dart:33-35` |
| Identificador de usuario | Usuario registrado | `SecureStorage` | Dispositivo | Sesión | `supabase_auth_client.dart:35` |
| Dirección IP y cabeceras de cada petición | Cualquier visitante | Logs de Render/Dokploy | Proveedor de despliegue | Operación y depuración | `logger.module.ts:6-19` (solo se redacta `authorization`) |
| Ubicación | Cualquier usuario del mapa | **No se guarda** (solo memoria del dispositivo) | Dispositivo | Mostrar la posición en el mapa | Sección 1 |

Sin datos sensibles en el sentido de la Ley 1581 (salud, biometría, orientación política, etc.). Los visitantes **no** necesitan cuenta: el mapa es público, de modo que su único rastro son los logs de la sección siguiente.

## 3. Hallazgos de privacidad

| ID | Hallazgo | Riesgo | Corrección |
|----|----------|--------|------------|
| PV-1 | `pino-http` registra IP y cabeceras (`cookie`, `user-agent`, `x-forwarded-for`) y `redact` solo cubre `authorization` | Se acumulan datos personales en logs sin necesidad ni plazo definido | Ampliar `redact`; evitar registrar IP completa; definir retención (T-11) |
| PV-2 | No hay política de retención ni de eliminación de cuenta | No se puede atender una solicitud de supresión | Documentar el procedimiento: borrar el usuario con la API admin de Supabase y verificar que no quedan filas con su `id` |
| PV-3 | No hay aviso de privacidad ni autorización de tratamiento en la app | Falta transparencia hacia el titular | Pantalla de registro con aviso corto: qué datos se piden, para qué, quién los trata y cómo pedir su supresión |
| PV-4 | Los datos de cuentas viven en Supabase; la región del proyecto no está documentada | Posible transferencia internacional sin registrar | Anotar región de Supabase y de Render en este documento |
| PV-5 | El registro pide `nombre` aunque la función de mapa no lo usa | Dato recogido sin necesidad | Hacer el campo opcional o eliminarlo si ninguna pantalla lo necesita |
| PV-6 | El rol y el nombre están en `user_metadata`, que el propio usuario puede editar (T-02) | Integridad de datos personales | Mover el rol a `app_metadata` |

## 4. Terceros que tratan datos

| Tercero | Qué recibe | Control disponible |
|---------|-----------|--------------------|
| Supabase | Correo, nombre, contraseña (hash), rol, metadatos de sesión | Contrato del proveedor; revisar región y retención de logs de Auth |
| Render / Dokploy | IP y cabeceras de las peticiones; logs de la aplicación | Reducir lo que se registra (PV-1) |
| SonarCloud / GitHub | Código fuente, sin datos de usuario | No aplica |
| Proveedor de IA de desarrollo | Fragmentos del código que se le comparten | Regla de no pegar `.env` ni datos reales (T-17) |

## 5. Decisiones de privacidad del diseño

| ID | Decisión | Justificación |
|----|----------|---------------|
| DP-1 | La ubicación del usuario se procesa solo en el dispositivo y no se envía ni persiste | Minimización por diseño: la función (mostrar la posición en el modelo 3D) no necesita servidor |
| DP-2 | Se mantiene el acceso público al mapa sin cuenta | Reduce la cantidad de datos personales recogidos |
| DP-3 | La app pide permiso de ubicación en el momento de uso, no al abrir | Consentimiento contextual del sistema operativo |
| DP-4 | Si se añade una función que envíe ubicación, requiere un ADR nuevo con consentimiento específico, redondeo de coordenadas y plazo de retención | Evita introducir el tratamiento sin evaluarlo, en línea con la condición de revisión del ADR-0007 |

## 6. Plan de acción

| Acción | Resuelve | Responsable | Prioridad |
|--------|----------|-------------|-----------|
| Ampliar `redact` y no registrar IP completa | PV-1, T-11 | Backend | Media |
| Aviso de privacidad en el registro | PV-3 | Frontend | Media |
| Procedimiento de supresión de cuenta documentado y probado | PV-2 | Backend | Media |
| Anotar regiones de Supabase y Render | PV-4 | DevOps | Baja |
| Hacer `nombre` opcional o quitarlo | PV-5 | Frontend / Backend | Baja |
| Mover el rol a `app_metadata` | PV-6, T-02 | Backend | Crítica |
| Prueba automatizada que falle si algún endpoint o servicio envía coordenadas | DP-1 | Frontend | Baja |
