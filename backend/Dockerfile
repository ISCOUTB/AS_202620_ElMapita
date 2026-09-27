# El Mapita UTB — Backend API (NestJS)
# Pieza "API" del modelo de seis piezas (S08): proceso de larga duración,
# no función — el framework completo (DI, Swagger, pipes) se bootstrapea
# una vez por proceso. Mismo Node que ci.yml (NODE_VERSION: "20").

FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM deps AS build
COPY . .
RUN npm run build \
  && npm prune --omit=dev

FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup -S nodejs && adduser -S nestjs -G nodejs
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./package.json
USER nestjs
EXPOSE 3000
CMD ["node", "dist/main"]
