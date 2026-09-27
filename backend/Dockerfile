# El Mapita UTB — Backend API (NestJS)
# Pieza "API" del modelo de seis piezas (S08): proceso de larga duración,
# no función — el framework completo (DI, Swagger, pipes) se bootstrapea
# una vez por proceso. Mismo Node que ci.yml (NODE_VERSION: "20").
#
# Base node:20-slim (Debian/glibc), no node:20-alpine: Alpine usa musl libc,
# que tiene un bug conocido de resolución DNS que cuelga peticiones salientes
# en ciertas redes de nube (ver docs/adr/0004, hallazgo del primer deploy real
# en Render — /health se colgaba llamando a Supabase pese a que la misma
# llamada, hecha desde fuera del contenedor, respondía en <200ms).

FROM node:20-slim AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM deps AS build
COPY . .
RUN npm run build \
  && npm prune --omit=dev

FROM node:20-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production
RUN groupadd -r nodejs && useradd -r -g nodejs nestjs
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./package.json
USER nestjs
EXPOSE 3000
CMD ["node", "dist/main"]
