FROM debian:bookworm-slim

LABEL org.opencontainers.image.title="J4F Flutter Builder" \
      org.opencontainers.image.description="Base Docker image with Flutter SDK pre-installed and web pre-cached for CI/CD builds" \
      org.opencontainers.image.source="https://github.com/j4fdev/j4f-docker" \
      org.opencontainers.image.vendor="J4F"

ENV DEBIAN_FRONTEND=noninteractive
ENV GIT_TERMINAL_PROMPT=0
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PATH}"

# 1. Instalar dependencias del sistema mínimas requeridas por Flutter
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      curl git unzip xz-utils zip libglu1-mesa ca-certificates openssh-client sudo bash && \
    rm -rf /var/lib/apt/lists/*

# 2. Argumento de versión de Flutter (por defecto stable)
ARG FLUTTER_VERSION=stable

# 3. Descargar Flutter SDK
RUN git clone https://github.com/flutter/flutter.git -b ${FLUTTER_VERSION} --depth 1 ${FLUTTER_HOME}

# 4. Configurar analytics off y precachear herramientas para Web
RUN git config --global --add safe.directory ${FLUTTER_HOME} && \
    flutter config --no-analytics && \
    flutter precache --web && \
    flutter doctor -v

# 5. Crear usuario 'builder' para builds reproducibles y no-root
RUN useradd -m -u 1000 -s /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    chown -R builder:builder ${FLUTTER_HOME}

USER builder
WORKDIR /home/builder

CMD ["flutter", "--version"]
