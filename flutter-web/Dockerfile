# =========================================================================
# J4F Universal Flutter Web Dockerfile
# Compila cualquier aplicación Flutter Web de J4F (Monorepo o Repositorio Remoto)
# =========================================================================
FROM ghcr.io/j4fdev/flutter-builder:stable AS builder

# 1. Argumentos de configuración
ARG GIT_TOKEN
ARG APP_DIR=.
ARG REPO_URL=""
ARG REPO_BRANCH="main"
ARG CACHEBUST=1

# Flags para descarga condicional de SDKs internas de J4F
ARG WITH_AISDK=false
ARG WITH_AUTHSDK=false
ARG WITH_NETWORKSDK=false
ARG WITH_BILLING=false

WORKDIR /home/builder

# 2. Configurar autenticación Git si se proporciona GIT_TOKEN
RUN if [ -n "$GIT_TOKEN" ]; then \
      git config --global url."https://${GIT_TOKEN}@github.com/".insteadOf "https://github.com/"; \
    fi

# 3. Descarga condicional de SDKs compartidas
RUN mkdir -p /home/builder/libraries && \
    if [ "$WITH_AISDK" = "true" ]; then \
      echo "📦 Clonando j4f-aisdk..." && \
      git clone --depth 1 https://github.com/j4fdev/j4f-aisdk.git /home/builder/libraries/j4f-aisdk; \
    fi && \
    if [ "$WITH_AUTHSDK" = "true" ]; then \
      echo "📦 Clonando j4f-authsdk..." && \
      git clone --depth 1 https://github.com/j4fdev/j4f-authsdk.git /home/builder/libraries/j4f-authsdk; \
    fi && \
    if [ "$WITH_NETWORKSDK" = "true" ]; then \
      echo "📦 Clonando j4f-network-sdk..." && \
      git clone --depth 1 https://github.com/j4fdev/j4f-network-sdk.git /home/builder/libraries/j4f-network-sdk; \
    fi && \
    if [ "$WITH_BILLING" = "true" ]; then \
      echo "📦 Clonando j4f-billing..." && \
      git clone --depth 1 https://github.com/j4fdev/j4f-billing.git /home/builder/libraries/j4f-billing; \
    fi

# 4. Asegurar que los directorios pertenezcan al usuario builder (evita Permission denied en .dart_tool)
USER root
RUN mkdir -p /home/builder/app/${APP_DIR} && \
    chown -R builder:builder /home/builder/app /home/builder/libraries
USER builder

# 5. Obtención del código fuente:
# CASO A: Repositorio remoto vía Git (ej. GrowPOS donde el código está en DanielZR30/pos_disco_app)
RUN if [ -n "$REPO_URL" ]; then \
      echo "CacheBust: $CACHEBUST" && \
      echo "📥 Clonando código fuente desde $REPO_URL (rama: $REPO_BRANCH)..." && \
      git clone --branch $REPO_BRANCH --depth 1 https://${GIT_TOKEN}@${REPO_URL#https://} /home/builder/app && \
      cd /home/builder/app && git log -1; \
    fi

# CASO B: Contexto local (ej. FitPlan donde el código ya está en el workspace)
COPY --chown=builder:builder . /home/builder/src/
RUN if [ -z "$REPO_URL" ]; then \
      mkdir -p /home/builder/app && \
      cp -r /home/builder/src/* /home/builder/app/ 2>/dev/null || true; \
    fi

# 6. Compilar la aplicación Flutter Web en el subdirectorio indicado
WORKDIR /home/builder/app/${APP_DIR}

RUN flutter pub get && \
    flutter build web --release

# =========================================================================
# Stage 2: Runtime Nginx SPA con Inyección Dinámica de Variables de Entorno
# =========================================================================
FROM nginx:alpine

ARG APP_DIR=.

COPY --from=builder /home/builder/app/${APP_DIR}/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:80/index.html > /dev/null || exit 1

ENTRYPOINT ["/entrypoint.sh"]
