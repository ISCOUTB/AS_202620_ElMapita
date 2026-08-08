# Aspectos del sistema

| ID    | Aspecto    | Requisito    | C4    | ADR    | Código    | Pruebas    | Evidencia    |
|---|---|---|---|---|---|---|---|
| A-01  | Visualización del mapa 3D y ubicación del usuario    | RF-01    | Pendiente    | Pendiente    | Pendiente    | Pendiente    | Pendiente    |

---

## Descripción del aspecto A-01

**Nombre:** Visualización interactiva del campus en 3D con geolocalización en tiempo real.

**Usuario:** Estudiante de nuevo ingreso, visitante o personal de la UTB que necesite desplazarse dentro de las instalaciones sin conocer la distribución exacta de los edificios y pisos.

**Problema que resuelve:** 
Actualmente, las personas que llegan por primera vez a la Universidad Tecnológica de Bolívar (UTB) enfrentan dificultades para ubicar salones, laboratorios, baños o cafeterías, especialmente en edificios de múltiples pisos. Los mapas estáticos en papel o las señales físicas no son suficientes para guiar de manera eficiente a los usuarios, lo que genera pérdida de tiempo y frustración. Además, no existe una herramienta digital que muestre la posición del usuario en tiempo real dentro de un modelo tridimensional del campus.

**Resultado esperado:** 
La aplicación móvil (desarrollada en Flutter) debe cargar y renderizar un modelo 3D del edificio o zona seleccionada, mostrando claramente la distribución de los pisos (con escaleras y ascensores representados gráficamente). El sistema debe obtener la ubicación actual del usuario a través del GPS del dispositivo (o permitir la selección manual del punto de partida en interiores) y reflejar su posición mediante un puntero o marcador sobre el mapa. Esta visualización debe ser fluida (tiempo de carga < 3 segundos) y permitir interacciones táctiles como rotación, zoom y cambio de piso, almacenando los assets 3D en Supabase Storage y sirviéndolos a través del backend en NestJS.