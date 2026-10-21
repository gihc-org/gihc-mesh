FROM docker.io/library/node:25-alpine AS builder
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY eleventy.config.js ./
COPY src ./src
RUN npm run build

FROM docker.io/nginxinc/nginx-unprivileged:1.31-alpine

LABEL org.opencontainers.image.title="GIHC Mini-Mesh website"
LABEL org.opencontainers.image.description="Project website for the GIHC mini-mesh"
LABEL org.opencontainers.image.source="https://github.com/gihc-org/gihc-mesh"

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/_site/ /usr/share/nginx/html/

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O - http://127.0.0.1:8080/healthz >/dev/null || exit 1
