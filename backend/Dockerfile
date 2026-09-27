# El Mapita UTB — Backend API (NestJS)
# Pieza "API" del modelo de seis piezas (S08): proceso de larga duración,
# no función — el framework completo (DI, Swagger, pipes) se bootstrapea
# una vez por proceso.
#
# Node 22, no 20: @supabase/supabase-js (y sus sub-paquetes) requieren
# Node >=22 en tiempo de ejecución de verdad, no solo por el warning
# EBADENGINE de npm — sin WebSocket nativo (Node 20 no lo trae), el cliente
# lanza "Node.js detected but native WebSocket not found" en cada consulta.
# Esto era la causa real de que /health nunca respondiera sano en Render
# (ver docs/adr/0004, hallazgo del deploy real — no era Alpine/musl ni la
# llave de servicio, aunque ambos se corrigieron en el camino).
#
# Base slim (Debian/glibc), no alpine: Alpine usa musl libc, que tiene un
# bug conocido de resolución DNS que cuelga peticiones salientes en ciertas
# redes de nube.

FROM node:22-slim AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM deps AS build
COPY . .
RUN npm run build \
  && npm prune --omit=dev

FROM node:22-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production
RUN groupadd -r nodejs && useradd -r -g nodejs nestjs
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./package.json
USER nestjs
EXPOSE 3000
CMD ["node", "dist/main"]
