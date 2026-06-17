FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY dist/ ./dist/
USER node
EXPOSE 3000
CMD ["node", "dist/server.js"]
