# Stage 1 - Build the base
FROM node:18-alpine AS base
WORKDIR /app
COPY src ./src
COPY package*.json ./
COPY tsconfig*.json ./
COPY .env ./.env
RUN npm install

# Stage 2 - Build the app
FROM base AS build
WORKDIR /app
RUN npm run build

# Stage 3 - Generate Prisma client and run migrations
FROM build AS generate
WORKDIR /app
COPY --from=base /app/package*.json ./
COPY --from=base /app/src/prisma ./prisma
COPY --from=base /app/.env ./.env
RUN npm install
COPY --from=build /app/build ./
RUN npx prisma generate

# Stage 4 - Production
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
COPY --from=build /app/build ./
COPY --from=generate /app/prisma ./prisma
COPY src/prisma/schema.prisma ./prisma/schema.prisma

# PostgreSQL setup
RUN apk add --no-cache postgresql-client

# Set environment variables
ENV DB_URL=postgresql://dev:localpass@localhost:5400/dev
ENV DB_LOGS=1
ENV REDIS_URL=redis://default:2df28dafa5bb4dcba3acb31edc20feed@liberal-ghoul-49997.upstash.io:49997
ENV ACCESS_TOKEN_SECRET=access-token-secret
ENV REFRESH_TOKEN_SECRET=refresh-token-secret

# Run the app
CMD ["node", "src/app.js"]