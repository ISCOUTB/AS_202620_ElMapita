#!/bin/bash
# dev.sh - Script para levantar backend y frontend simultáneamente

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"
FRONTEND_DIR="$PROJECT_ROOT/frontend"

echo -e "${BLUE}🚀 Iniciando El Mapita UTB - Entorno de desarrollo${NC}"
echo "=================================================="

# Verificar que existan los directorios
if [ ! -d "$BACKEND_DIR" ]; then
    echo -e "${RED}❌ Directorio backend no encontrado: $BACKEND_DIR${NC}"
    exit 1
fi

if [ ! -d "$FRONTEND_DIR" ]; then
    echo -e "${RED}❌ Directorio frontend no encontrado: $FRONTEND_DIR${NC}"
    exit 1
fi

# Verificar archivo .env en backend
if [ ! -f "$BACKEND_DIR/.env" ]; then
    echo -e "${YELLOW}⚠️  Archivo .env no encontrado en backend. Copiando desde .env.example${NC}"
    cp "$BACKEND_DIR/.env.example" "$BACKEND_DIR/.env"
    echo -e "${YELLOW}   Edita $BACKEND_DIR/.env con tus credenciales de Supabase${NC}"
fi

# Función para limpiar procesos al salir
cleanup() {
    echo -e "\n${YELLOW}🛑 Deteniendo servicios...${NC}"
    kill $(jobs -p) 2>/dev/null || true
    exit 0
}

trap cleanup SIGINT SIGTERM

# Iniciar backend
echo -e "${BLUE}📦 Iniciando backend (NestJS) en puerto 3000...${NC}"
cd "$BACKEND_DIR"
npm run start:dev &
BACKEND_PID=$!

# Esperar a que el backend esté listo
echo -e "${YELLOW}⏳ Esperando a que el backend esté listo...${NC}"
sleep 5

# Verificar health check
for i in {1..10}; do
    if curl -s http://localhost:3000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend listo en http://localhost:3000${NC}"
        echo -e "${GREEN}📚 Swagger docs: http://localhost:3000/docs${NC}"
        break
    fi
    if [ $i -eq 10 ]; then
        echo -e "${RED}❌ Backend no respondió después de 10 intentos${NC}"
        kill $BACKEND_PID 2>/dev/null || true
        exit 1
    fi
    sleep 2
done

# Iniciar frontend
echo -e "${BLUE}📱 Iniciando frontend (Flutter)...${NC}"
cd "$FRONTEND_DIR"

# Verificar si hay dispositivos conectados
echo -e "${YELLOW}🔍 Buscando dispositivos...${NC}"
flutter devices

echo -e "${GREEN}✅ Frontend iniciado. Selecciona un dispositivo para ejecutar.${NC}"
echo ""
echo -e "${BLUE}==================================================${NC}"
echo -e "${GREEN}🎉 ¡Entorno de desarrollo listo!${NC}"
echo -e "${BLUE}==================================================${NC}"
echo ""
echo -e "Backend:  ${GREEN}http://localhost:3000${NC} (API)"
echo -e "Docs:     ${GREEN}http://localhost:3000/docs${NC} (Swagger)"
echo -e "Frontend: Ejecutando en dispositivo/emulador seleccionado"
echo ""
echo -e "${YELLOW}Presiona Ctrl+C para detener ambos servicios${NC}"

# Esperar a que terminen los procesos en background
wait $BACKEND_PID