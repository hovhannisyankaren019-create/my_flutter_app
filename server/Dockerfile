FROM node:20-alpine
WORKDIR /app
COPY package.json ./
COPY index.mjs ./
COPY knowledge.txt ./
COPY knowledge-learned.txt ./
COPY teachers.txt ./
ENV NODE_ENV=production
EXPOSE 8787
CMD ["node", "index.mjs"]
