<a id="glosario"></a>
# Glosario — El Mapita UTB

## 1. Dominio y negocio

| Término | Definición |
|---|---|
| **Admin Staff** | Rol de usuario con permisos administrativos limitados a la gestión operativa del sistema (por ejemplo, catálogo de POIs). |
| **Admin UTB** | Rol de usuario con permisos administrativos completos sobre el sistema, incluida la gestión de roles de otros usuarios. |
| **Aviso Legal** | Pantalla mostrada tras el splash que informa que el uso de la aplicación está reservado a la comunidad de la Universidad Tecnológica de Bolívar. |
| **Campus UTB** | Terreno, edificios e instalaciones físicas de la Universidad Tecnológica de Bolívar en Cartagena, Colombia. |
| **Categoría de Lugar** | Clasificación temática de un sitio del campus (salón, laboratorio, baño, cafetería, biblioteca, entre otras) usada para filtrar la lista de lugares en la pantalla principal. |
| **Docente** | Rol de usuario asignado al personal académico de la UTB. |
| **Edificio (Building)** | Estructura física del campus que contiene uno o más pisos, identificada con nombre, código y coordenadas geoespaciales. |
| **Estudiante** | Rol de usuario asignado a la comunidad estudiantil de la UTB. |
| **Piso (Floor)** | Nivel o planta horizontal dentro de un edificio que contiene salones, áreas comunes y puntos de interés específicos. |
| **POI (Punto de Interés / Point of Interest)** | Ubicación o elemento relevante dentro del campus o edificio (por ejemplo, aula, laboratorio, baño, cafetería, biblioteca, ascensor, escalera). |
| **Visitante** | Rol de usuario asignado a una persona externa a la comunidad UTB que consulta la aplicación. |
| **Wayfinding** | Conjunto de elementos del entorno y de la interfaz que ayudan a una persona a orientarse y desplazarse hacia un destino dentro de un espacio físico. |

## 2. Entidades y tipos del modelo

| Término | Definición |
|---|---|
| **Building** | Entidad de dominio que representa un edificio: nombre, código, geometría (`GeoPolygon`), lista de pisos y versión del modelo 3D asociado. |
| **CampusPlace** | Entidad del frontend que representa un lugar del campus con nombre, categoría (`PlaceCategory`) y ubicación descriptiva. |
| **Coordinates** | Par de valores `latitude`/`longitude` que representa una posición geográfica. |
| **Entity** | Contrato base compartido (`shared/kernel`) para toda entidad de dominio: expone `id`, `createdAt` y `updatedAt`. |
| **Floor** | Entidad de dominio que representa un piso: edificio al que pertenece, número, nombre, URL y versión del modelo 3D, altura en metros y lista de POIs. |
| **GeoPoint** | Tipo de valor GeoJSON que representa un punto (`coordinates: [number, number]`), usado para ubicar un POI. |
| **GeoPolygon** | Tipo de valor GeoJSON que representa un polígono (`coordinates: number[][][]`), usado para la huella de un edificio. |
| **LocationSource** | Tipo enumerado del origen de una estimación de ubicación: `gps`, `wifi`, `ble` o `manual`. |
| **ModelVersion** | Tipo de valor con versionado semántico (por ejemplo `1.0.0`) que identifica una versión de modelo 3D para invalidación de caché. |
| **PlaceCategory** | Enumeración de 20 categorías de lugares del campus (salones, laboratorios, baños, servicios escolares, canchas, auditorios, biblioteca, cafetería, estacionamientos, oficinas administrativas, bienestar universitario, servicio médico, centro de idiomas, salas de cómputo, sala de profesores, papelería, áreas verdes, control escolar, vigilancia, cajero automático). |
| **Poi** | Entidad de dominio que representa un punto de interés: piso al que pertenece, tipo (`PoiType`), nombre, geometría (`GeoPoint`) y metadatos. |
| **PoiMetadatos** | Tipo de valor con atributos opcionales de un POI: capacidad, horario, accesibilidad y descripción. |
| **PoiType** | Tipo enumerado de la clase de un POI: `salon`, `laboratorio`, `bano`, `cafeteria`, `biblioteca`, `escalera`, `ascensor` u `otro`. |
| **PrecisionLevel** | Tipo enumerado del nivel de precisión de una ubicación: `high`, `medium`, `low` o `manual`. |
| **User** | Entidad de dominio que representa un usuario autenticado: correo, rol (`UserRole`), nombre y estado activo. |
| **UserLocation** | Tipo de valor que representa la posición estimada del usuario: coordenadas, precisión en metros, estimación de piso, origen (`LocationSource`), marca de tiempo e indicador de incertidumbre mostrada. |
| **UserRole** | Tipo enumerado del rol de un usuario: `estudiante`, `visitante`, `docente`, `admin_staff` o `admin_utb`. |
| **ValueObject** | Contrato base compartido (`shared/kernel`) para todo objeto de valor: se compara por sus atributos (`props`) en vez de por identidad. |

## 3. Arquitectura y patrones

| Término | Definición |
|---|---|
| **Adaptador** | Implementación concreta de un puerto que conecta la lógica de dominio con una tecnología externa (por ejemplo, el cliente de Supabase). |
| **Adaptador de Render (MapRenderer)** | Puerto previsto para desacoplar la lógica de la aplicación del motor de renderizado 3D concreto; su implementación está pendiente. |
| **Application (capa)** | Capa que orquesta casos de uso, coordinando entidades de dominio y puertos sin conocer detalles de infraestructura. |
| **Arquitectura en Capas** | Estilo arquitectónico que organiza el código en niveles horizontales (presentación, lógica de negocio, datos) con dependencias en una sola dirección. |
| **Arquitectura Hexagonal (Ports & Adapters)** | Estilo arquitectónico que aísla el dominio de la aplicación mediante puertos (interfaces) y adaptadores (implementaciones concretas), permitiendo sustituir tecnologías externas sin tocar la lógica de negocio. |
| **BLoC (Business Logic Component)** | Patrón de diseño de arquitectura de software para Flutter que separa la interfaz de usuario de la lógica de negocio mediante flujos de eventos (Events) y estados (States). |
| **Cubit** | Variante simplificada de BLoC que expone métodos directos en lugar de eventos para emitir nuevos estados. |
| **Domain (capa)** | Capa que contiene las entidades, tipos de valor y reglas de negocio de un módulo, sin dependencias hacia infraestructura ni frameworks. |
| **Entity (patrón)** | Objeto de dominio con identidad propia (`id`) que persiste a través de cambios en sus atributos. |
| **Feature Module** | Unidad de organización del código que agrupa todo lo necesario para una funcionalidad (dominio, aplicación, infraestructura, presentación) bajo un mismo directorio. |
| **Infrastructure (capa)** | Capa que implementa los puertos definidos en el dominio usando tecnologías concretas (Supabase, sensores del dispositivo, almacenamiento local). |
| **Interfaces / Presentation (capa)** | Capa de entrada/salida del módulo: controladores REST en el backend, páginas y widgets en el frontend. |
| **Inyección de Dependencias** | Técnica mediante la cual un componente recibe sus dependencias (por ejemplo, un repositorio) en lugar de construirlas él mismo, facilitando pruebas y bajo acoplamiento. |
| **Monolito Modular** | Estilo arquitectónico en el que toda la aplicación se empaqueta y despliega como una única unidad ejecutable, pero su código interno está rigurosamente dividido en módulos independientes con fronteras explícitas y kernel compartido. |
| **Puerto** | Interfaz definida en la capa de dominio o aplicación que describe una capacidad externa (persistencia, almacenamiento, ubicación) sin comprometerse con una implementación concreta. |
| **Repositorio (Repository)** | Patrón que abstrae el acceso a datos de una entidad detrás de una interfaz (`findById`, `findAll`, `save`, `delete`), ocultando la tecnología de persistencia real. |
| **Result** | Tipo de valor que representa el resultado de una operación como éxito (`Success`) o fallo (`Failure`), evitando el uso de excepciones para control de flujo. |
| **Shared Kernel** | Conjunto de tipos y contratos base (`Entity`, `ValueObject`, `Repository`, `UseCase`) compartidos por todos los módulos del sistema. |
| **UseCase** | Contrato que encapsula una acción de negocio con una entrada y una salida definidas, ejecutada por la capa de aplicación. |

## 4. Documentación arquitectónica

| Término | Definición |
|---|---|
| **Árbol de Utilidad** | Técnica de arc42 que descompone los atributos de calidad de un sistema en escenarios concretos y medibles, priorizados por importancia y riesgo. |
| **ADR (Architecture Decision Record)** | Documento formal y conciso que captura una decisión de diseño arquitectónico relevante, su contexto, alternativas evaluadas y consecuencias. |
| **arc42** | Plantilla estándar para documentar arquitecturas de software en doce secciones, desde introducción y objetivos hasta glosario. |
| **Aspecto** | Característica funcional de extremo a extremo elegida para validar la arquitectura tempranamente mediante un corte vertical. |
| **C4 (modelo)** | Notación para diagramar arquitectura de software en niveles de abstracción crecientes: Contexto, Contenedores, Componentes y Código. |
| **C4 Nivel 1 (Contexto)** | Diagrama C4 que muestra el sistema como una caja negra y sus interacciones con usuarios y sistemas externos. |
| **C4 Nivel 2 (Contenedor)** | Diagrama C4 que descompone el sistema en sus contenedores desplegables (aplicaciones, bases de datos, servicios) y las relaciones entre ellos. |
| **Decisión (DEC)** | Elección arquitectónica registrada en la matriz de decisiones del arc42, con su estado (aceptada, rechazada) y justificación. |
| **Escenario de Calidad (EC)** | Enunciado verificable que describe un estímulo, el contexto y la respuesta esperada del sistema para un atributo de calidad concreto (rendimiento, disponibilidad, confiabilidad). |
| **Interfaz (IF)** | Punto de integración documentado entre dos contenedores o entre el sistema y un servicio externo, con su protocolo y propósito. |
| **Matriz de Trazabilidad** | Tabla que enlaza cada aspecto con su requisito, escenarios de calidad, vistas C4, ADR, código fuente, pruebas y evidencia. |
| **Requisito Funcional (RF)** | Capacidad concreta que el sistema debe ofrecer al usuario, derivada de un aspecto. |
| **Restricción (RES)** | Condición impuesta al proyecto (académica, física, tecnológica u operacional) que limita el espacio de soluciones arquitectónicas posibles. |
| **Riesgo (RSK)** | Situación identificada que podría comprometer la calidad o viabilidad del sistema, junto con su nivel de impacto y estrategia de mitigación. |
| **Trade-off** | Compromiso entre dos o más atributos de calidad o alternativas de diseño, donde mejorar uno implica ceder en otro. |

## 5. Identificadores del proyecto

| Término | Definición |
|---|---|
| **A-01** | Identificador del aspecto único del proyecto: "Visualización interactiva del campus en 3D con geolocalización en tiempo real". |
| **ADR-0001** | Registro de decisión arquitectónica que documenta la adopción de Monolito Modular para backend y frontend. |
| **ADR-0002** | Registro de decisión arquitectónica que documenta la estrategia frente a la restricción de rendimiento en dispositivos de gama de entrada (RES-04). |
| **DEC-01 … DEC-06** | Numeración de las seis decisiones arquitectónicas registradas en la matriz de decisiones del arc42, cada una vinculada a un ADR. |
| **EC-01 … EC-04** | Numeración de los cuatro escenarios de calidad del proyecto: carga inicial, fluidez de render, precisión de ubicación y disponibilidad sin conexión. |
| **IF-01 … IF-05** | Numeración de las cinco interfaces documentadas entre los contenedores del sistema y los servicios externos. |
| **RES-01 … RES-04** | Numeración de las cuatro restricciones del proyecto: académica, física/tecnológica, operacional y de rendimiento en gama de entrada. |
| **RF-01** | Identificador del requisito funcional derivado del aspecto A-01. |
| **RSK-01 … RSK-03** | Numeración de los tres riesgos arquitectónicos identificados: complejidad de modelos 3D, disparidad de hardware GPU y dependencia de Supabase. |

## 6. Tecnologías y herramientas

| Término | Definición |
|---|---|
| **BaaS (Backend as a Service)** | Modelo de computación en la nube donde los servicios de backend (autenticación, base de datos, almacenamiento de archivos) son provistos como servicios administrados (por ejemplo, Supabase). |
| **Bucket `modelos-3d`** | Contenedor de almacenamiento en Supabase Storage donde se publican los archivos de modelos 3D del campus. |
| **Dart** | Lenguaje de programación en el que está escrita la aplicación móvil con Flutter. |
| **Dio** | Cliente HTTP para Dart/Flutter usado por `DioClient` para las llamadas a la API REST del backend. |
| **ESLint** | Herramienta de análisis estático de código JavaScript/TypeScript usada en el backend para verificar calidad y estilo. |
| **Flutter** | Framework de Google para construir aplicaciones móviles multiplataforma con Dart, usado para el frontend de El Mapita. |
| **geolocator** | Paquete de Flutter usado para obtener coordenadas y estado de permisos de ubicación del dispositivo. |
| **GitHub Actions** | Plataforma de integración continua usada para ejecutar el pipeline de backend, frontend y verificación de documentación del proyecto. |
| **GoTrue** | Servicio de autenticación de Supabase, responsable de emitir y validar tokens de sesión. |
| **Hive** | Base de datos clave-valor ligera, embebida y de alto rendimiento escrita puramente en Dart, utilizada para persistencia local en dispositivos móviles. |
| **Jest** | Framework de pruebas para JavaScript/TypeScript usado en el backend para pruebas unitarias y end-to-end. |
| **lychee** | Herramienta de verificación de enlaces usada en el job de documentación del pipeline para detectar enlaces rotos. |
| **NestJS** | Framework progresivo de Node.js para la construcción de aplicaciones del lado del servidor escalables, estructurado con TypeScript e inyección de dependencias. |
| **PostGIS** | Extensión espacial para el sistema de base de datos relacional PostgreSQL que añade soporte para objetos geográficos, permitiendo ejecutar consultas espaciales en SQL. |
| **PostgreSQL** | Sistema de gestión de bases de datos relacionales de código abierto sobre el que se construye Supabase. |
| **PostgREST** | Servidor web independiente que transforma una base de datos PostgreSQL directamente en una API RESTful. |
| **Supabase** | Alternativa de código abierto a Firebase construida sobre PostgreSQL, que provee autenticación, base de datos, almacenamiento, funciones y capacidades en tiempo real. |
| **Supabase Realtime** | Servicio de Supabase que distribuye eventos de cambios en la base de datos a los clientes suscritos mediante WebSockets. |
| **TypeScript** | Superset tipado de JavaScript en el que está escrito el backend construido con NestJS. |

## 7. 3D y rendimiento

| Término | Definición |
|---|---|
| **Degradación Progresiva** | Estrategia que reduce gradualmente el detalle visual de la escena 3D a medida que el rendimiento del dispositivo cae, en lugar de fallar de forma abrupta. |
| **Draco** | Biblioteca de compresión de código abierto desarrollada por Google para comprimir y descomprimir mallas geométricas 3D y nubes de puntos. |
| **FPS (Frames Per Second)** | Número de fotogramas que la aplicación logra renderizar por segundo; métrica central del escenario de calidad EC-02. |
| **Gama de Entrada** | Segmento de dispositivos móviles Android de menor capacidad de procesamiento y GPU, contemplado como entorno de referencia por la restricción RES-04. |
| **GLB / GLTF (Graphics Language Transmission Format)** | Formato estándar de archivo abierto para la transmisión y carga eficiente de escenas y modelos 3D. GLB es la versión binaria compacta de GLTF. |
| **LOD (Level of Detail)** | Técnica de optimización que ajusta la complejidad geométrica de un modelo 3D según la distancia de cámara o la capacidad del dispositivo. |
| **Malla (Mesh)** | Estructura geométrica compuesta por vértices, aristas y caras que define la forma de un objeto 3D. |
| **Percentil p95** | Valor por debajo del cual se encuentra el 95% de las mediciones de una métrica; unidad de medida usada en el umbral de carga del escenario EC-01. |
| **Presupuesto de Frame** | Tiempo máximo disponible para renderizar un fotograma sin caer por debajo de la tasa de cuadros objetivo (33,3 ms para 30 FPS). |
| **Vista Esquemática** | Modo de representación simplificado del edificio (sin geometría 3D detallada) al que el sistema degrada cuando la tasa de cuadros cae por debajo del umbral definido. |

## 8. Geolocalización

| Término | Definición |
|---|---|
| **Accuracy (Precisión)** | Margen de error, expresado en metros, de una estimación de ubicación reportada por el dispositivo. |
| **BLE (Bluetooth Low Energy)** | Tecnología de comunicación inalámbrica de bajo consumo usada como fuente alternativa de estimación de ubicación en interiores. |
| **Estimación de Piso** | Cálculo del nivel del edificio en el que se encuentra el usuario, derivado de la ubicación y contexto disponibles. |
| **Fallback Manual** | Mecanismo de degradación controlada que permite al usuario seleccionar manualmente su punto de partida (edificio, piso o salón) cuando la geolocalización automática no está disponible o es imprecisa. |
| **GPS (Global Positioning System)** | Sistema de posicionamiento satelital, fuente principal de ubicación en exteriores, con precisión degradada en interiores. |
| **Incertidumbre de Ubicación** | Representación probabilística del error en la estimación de la posición del usuario, ilustrada visualmente mediante un radio o círculo de precisión alrededor del marcador. |
| **Timeout de Adquisición** | Tiempo máximo de espera para obtener una estimación de ubicación antes de activar el fallback manual. |
| **Wi-Fi (posicionamiento por)** | Técnica de estimación de ubicación basada en la intensidad de señal de redes inalámbricas cercanas, usada como fuente alternativa en interiores. |

## 9. Proceso y evaluación

| Término | Definición |
|---|---|
| **Corte** | Hito de evaluación periódico del curso en el que se entrega y sustenta el avance del proyecto. |
| **Corte Vertical (Aspecto A-01)** | Implementación funcional de una característica de extremo a extremo (desde la base de datos hasta la interfaz gráfica táctil) para validar la arquitectura tempranamente. |
| **Deuda Declarada** | Categoría de respuesta a una observación de evaluación que reconoce que un criterio no se cumple hoy, explicando qué lo desbloquea y cuándo se resolverá. |
| **Evidencia** | Artefacto verificable (código, prueba, resultado de ejecución, captura) que demuestra el cumplimiento de un criterio o escenario. |
| **Línea Base (Baseline)** | Primera medición registrada de una métrica sobre una capacidad real del sistema, usada como punto de comparación contra un umbral. |
| **No Conformidad** | Desviación identificada entre el estado esperado y el estado real de un módulo o entregable, con evidencia trazable en el repositorio. |
| **Pipeline** | Secuencia automatizada de jobs de integración continua (backend, frontend, documentación, quality gate) que valida cada cambio del repositorio. |
| **Quality Gate** | Job del pipeline que agrega el resultado de los demás jobs y falla en cascada si alguno de ellos no pasa. |
| **Réplica** | Categoría de respuesta a una observación de evaluación que la rebate con evidencia ejecutable, por considerarla incorrecta. |
| **Tag `corte-1`** | Etiqueta de Git que marca el commit correspondiente al cierre del primer corte del proyecto. |
| **Umbral** | Valor límite definido en un escenario de calidad que separa un resultado aceptable de uno no aceptable. |
