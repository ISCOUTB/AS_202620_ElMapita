---
number: 0008
date: 2026-10-25
title: "PostgreSQL (Supabase) como fuente de verdad relacional de El Mapita UTB"
status: Accepted
deciders: ["Diego Rosales Garza", "Rodrigo Vazquez Rico", "Angel Fabian Gutierrez Gomez"]
technical-story: "Entrega de arquitecturas intensivas en datos: documentar la decisión de datos más costosa de revertir. La decisión se tomó al iniciar el proyecto sin ADR; este lo registra con sus consecuencias reales."
---

# ADR-0008: PostgreSQL (Supabase) como fuente de verdad relacional

## Contexto

El sistema guarda edificios, pisos y POIs con relaciones entre sí (`pisos.edificio_id`, `pois.piso_id`), geometrías (polígonos de edificio, puntos de POI), modelos 3D `.glb` versionados y usuarios con rol. Las lecturas dominan ampliamente; hay una sola escritura expuesta (crear POI). El despliegue es una instancia sin presupuesto (ADR-0004).

Se adoptó Supabase: PostgreSQL con PostGIS, Storage para los `.glb` y Auth para usuarios. Esta decisión es la **más costosa de revertir** del proyecto por cuatro razones, que son las que se evalúan abajo:

1. **Datos geoespaciales y relacionales** que habría que migrar y reconstruir.
2. **Acoplamiento a tres servicios del proveedor a la vez** (BD, Storage, Auth), no solo a la base de datos.
3. **Claves y rutas ya viven en clientes instalados**: la ruta `{edificioId}/{versión}.glb` y las URLs de la API están en apps móviles que no se actualizan al mismo tiempo que el servidor.
4. **El esquema no está versionado en el repositorio** (no hay `.sql` ni migraciones): hoy solo existe dentro del proyecto Supabase.

## Alternativas

| Alternativa | Consistencia | Geometría | Costo de migrar luego | Riesgo |
|---|---|---|---|---|
| A. PostgreSQL + PostGIS vía Supabase (**decisión**) | ACID, integridad referencial | Tipos y operadores espaciales nativos | Alto (ver arriba) | Acoplamiento al proveedor |
| B. Documentos NoSQL (MongoDB / Firestore) | Eventual o por documento | GeoJSON con índices propios, menos operadores | Medio: el esquema es flexible, pero se pierde integridad referencial | Edificio/piso/POI quedan con referencias sin garantía; más lógica en el backend |
| C. Clave-valor (DynamoDB / Redis) con la geometría como JSON | Por clave | Ninguna nativa | Medio | Sin consultas espaciales ni por relación; no encaja con el dominio |

## Decisión

**Se adopta A.** Razones, contra los escenarios de calidad y la lecture:

1. **Los datos son relacionales y de baja escala.** Pocas decenas de edificios, cientos de POIs: no hace falta escalar horizontalmente, y el modelo relacional da integridad referencial y ACID sin trabajo adicional.
2. **Geometría nativa.** PostGIS cubre las consultas por cercanía y contención que el dominio necesitará (hoy la geometría se almacena y se devuelve tal cual, sin consultas espaciales).
3. **Costo $0 y menos piezas** (ADR-0004): BD, Storage y Auth en un solo proveedor, sin operar servidores propios.
4. **El patrón de lectura masiva se resuelve con caché**, no con otra base (ver [diseno-cache.md](../datos/diseno-cache.md)): la alternativa B/C no aportaría nada que una caché de TTL no dé ya.

## Consecuencias

**Asumidas:**
- **Lock-in de tres servicios.** Salir de Supabase exige reemplazar Auth (`auth.users`, rol en `user_metadata`), Storage (URLs firmadas) y la BD a la vez.
- **El backend usa la *service-role key*** y por tanto omite RLS: la autorización vive solo en el backend.
- **Arrays desnormalizados** (`edificios.pisos`, `pisos.pois`) que ninguna escritura mantiene en sincronía con las claves foráneas. Fuente de verdad: las claves foráneas, no los arrays.
- **Sin transacciones multi-fila** en el backend: `GetBuilding` lee tres veces sin snapshot (ver [consistencia-operaciones.md](../datos/consistencia-operaciones.md)).

**Acciones derivadas:**
1. Exportar el esquema a `backend/supabase/schema.sql` (`supabase db dump --schema public`) y versionarlo. **Pendiente: lo ejecuta el responsable del proyecto Supabase, requiere sus credenciales.** Es la mitigación de menor costo del riesgo 4.
2. Mantener los modelos **inmutables por versión** (`uploadModel` ya usa `upsert: false`) para que las rutas ya presentes en clientes instalados sigan siendo válidas.
3. Mantener el acceso a datos detrás de los puertos de dominio (`BuildingRepository`, `FloorRepository`, `PoiRepository`, `Model3DStorage`): es lo único que hoy separa al negocio del proveedor y reduce el costo de una migración futura.

**Condición de revisión:** reabrir con un ADR nuevo si (a) hay más de una instancia o escrituras concurrentes frecuentes que exijan otra estrategia de caché o de consistencia, (b) el plan gratuito de Supabase deja de ser viable, o (c) aparece un requisito de datos no estructurados o de volumen que el modelo relacional no soporte.
