FROM node:20-bullseye-slim

WORKDIR /app

# Install dependencies first for better layer caching
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Copy application code
COPY . .

ENV NODE_ENV=production

# Express listens on $PORT (Railway injects this)
EXPOSE 3000

CMD ["npm", "start"]

