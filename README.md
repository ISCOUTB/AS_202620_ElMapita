# El Mapita UTB

Aplicación móvil interactiva con mapa 3D de la Universidad Tecnológica de Bolívar (UTB), diseñada para guiar a estudiantes, visitantes y personal dentro del campus. Permite ubicar salones, baños, laboratorios, cafeterías, bibliotecas, escaleras y ascensores, e incluye un puntero de ubicación en tiempo real dentro de las instalaciones.

---

##  Equipo de Desarrollo

- Diego Rosales Garza
- Rodrigo Vasquez Rico
- Angel Fabian Gutierrez Gomez

##  Stakeholders / Beneficiarios

- Estudiantes de nuevo ingreso.
- Visitantes y padres de familia.
- Personal administrativo y docente.
- Dirección de Tecnología de la UTB.

---

##  Stack Tecnológico

| Capa | Tecnología |
| :--- | :--- |
| **Frontend Móvil** | Flutter (Dart) |
| **Backend API** | NestJS (TypeScript) |
| **Base de Datos** | Supabase (PostgreSQL + PostGIS) |
| **Autenticación** | Supabase Auth |
| **Almacenamiento** | Supabase Storage |
| **Tiempo Real** | Supabase Realtime |



---

##  Estructura de Carpetas

```
AS_202620_ElMapita/
├── .github/
│   └── workflows/          # Pipelines de CI/CD (lint, tests, build)
├── backend/                 # API REST/GraphQL en NestJS
│   ├── src/
│   │   ├── modules/         # Módulos de dominio (mapas, ubicaciones, usuarios, etc.)
│   │   ├── common/          # Utilidades, filtros, pipes, guards compartidos
│   │   ├── config/          # Configuración de entorno y variables
│   │   └── database/        # Conexión a Supabase, migraciones y seeds
│   │       ├── migrations/
│   │       └── seeds/
│   ├── test/                 # Pruebas unitarias e de integración del backend
│   └── docs/                 # Documentación específica de la API (endpoints, contratos)
├── mobile/                   # Aplicación móvil en Flutter
│   ├── lib/
│   │   ├── core/              # Configuración base, temas, constantes
│   │   ├── features/          # Funcionalidades por módulo (mapa, navegación, perfil, etc.)
│   │   ├── shared/            # Widgets y componentes reutilizables
│   │   └── config/            # Configuración de entorno y variables de la app
│   ├── assets/
│   │   ├── images/            # Recursos gráficos
│   │   ├── models3d/          # Modelos 3D del campus
│   │   └── fonts/             # Tipografías del proyecto
│   └── test/                  # Pruebas unitarias y de widgets
└── docs/                      # Documentación general del proyecto
    ├── c4/                     # Diagramas de arquitectura C4 (Contexto, Contenedores, Componentes)
    ├── api/                    # Especificaciones y contratos de la API
    ├── database/               # Modelo de datos, diagramas ER, esquema PostGIS
    ├── design/                 # Mockups, wireframes y guías de UI/UX
    └── actas/                  # Actas de reuniones y decisiones de equipo
```

### Descripción general

- **`backend/`**: contiene la API construida con NestJS, responsable de exponer los datos del mapa, las ubicaciones y la lógica de negocio, conectándose a Supabase (PostgreSQL + PostGIS) para el almacenamiento geoespacial.
- **`mobile/`**: contiene la aplicación cliente construida en Flutter, consumida por estudiantes, visitantes y personal, que renderiza el mapa 3D interactivo y el puntero de ubicación en tiempo real.
- **`docs/`**: concentra toda la documentación transversal del proyecto, incluyendo los diagramas de arquitectura C4 (`docs/c4/`), el modelo de datos, la documentación de la API y los artefactos de diseño.
- **`.github/workflows/`**: contendrá los pipelines de integración continua (linting, pruebas automatizadas y builds) tanto para el backend como para el móvil.

---

