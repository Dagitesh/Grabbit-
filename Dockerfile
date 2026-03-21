# Monorepo: API lives in /backend. Railway often uses repo root as build context.
FROM node:20-bullseye-slim

WORKDIR /app

COPY backend/package.json backend/package-lock.json ./
RUN npm ci --omit=dev

COPY backend/ .

ENV NODE_ENV=production

EXPOSE 3000

CMD ["npm", "start"]
