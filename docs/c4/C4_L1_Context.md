# C4 Nivel 1 — Diagrama de Contexto del Sistema — El Mapita UTB

> Referencia: [C4 Model: Documentación Clara y Efectiva](https://dev.to/ajcastillo/c4-model-documentacion-clara-y-efectiva-para-arquitecturas-de-software-43od) — Nivel 1 responde *¿Dónde encaja este sistema dentro del ecosistema?* Dirigido a stakeholders no técnicos.  
> Fuente: `docs/arc42/arc42-template-EN.md` S3.1/S3.2 | Render: [`C4_L1_Context.png`](./C4_L1_Context.png)

## Diagrama (Mermaid)

```mermaid
flowchart TB
    classDef person fill:#08427B,stroke:#073B6F,color:#FFFFFF
    classDef system fill:#1168BD,stroke:#3C7FC0,color:#FFFFFF
    classDef ext fill:#999999,stroke:#8A8A8A,color:#FFFFFF

    A["Estudiante / Visitante<br><i>&lt;&lt;Person&gt;&gt;</i>"]:::person
    B["Docente / Admin<br><i>&lt;&lt;Person&gt;&gt;</i>"]:::person

    subgraph UTB ["UTB"]
        C["El Mapita UTB<br>Mapa 3D interactivo<br><i>&lt;&lt;System&gt;&gt;</i><br>Modelos .glb + geolocalizacion"]:::system
    end

    subgraph Externos ["Sistemas Externos"]
        D["Supabase<br>Auth, DB PostGIS, Storage, Realtime<br><i>&lt;&lt;External&gt;&gt;</i>"]:::ext
        E["Ubicacion SO<br>CoreLocation / FusedLocation<br><i>&lt;&lt;External&gt;&gt;</i>"]:::ext
    end

    A -- "Usa<br>HTTPS" --> C
    B -- "Usa / Administra<br>HTTPS/JWT" --> C
    C -- "Consulta datos<br>HTTPS/WSS/PostgREST" --> D
    C -- "Obtiene ubicacion<br>MethodChannels" --> E

    subgraph Leyenda ["Leyenda"]
        direction LR
        L1["Person<br>Usuario"]:::person
        L2["System<br>El Mapita"]:::system
        L3["External<br>Supabase/Ubicacion"]:::ext
    end
```

## Actores y Sistemas

| Elemento | Tipo |
|----------|------|
| Estudiante / Visitante | Person |
| Docente / Admin | Person |
| El Mapita UTB | System (UTB) |
| Supabase | System_Ext |
| Ubicacion SO | System_Ext |
