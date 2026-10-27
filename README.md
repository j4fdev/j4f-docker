# J4F Docker Tools & Base Images (`j4f-docker`)

Repositorio central de imágenes Docker base, plantillas de runtime y utilidades de contenedores para todos los proyectos del ecosistema **J4F** (`FitPlan`, `POS`, `landingj4f`, etc.).

---

## 🚀 ¿Qué problema resuelve?

Hasta ahora, cada proyecto de Flutter Web descargaba Debian/Ubuntu, instalaba paquetes con `apt`, clonaba el repositorio completo de Flutter SDK (1.2 GB) y corría `flutter precache` en cada compilación.

Esto provocaba:
- **Tiempos de build lentos** (10-20 minutos por cada despliegue).
- **Consumo excesivo de RAM y CPU** en el servidor de producción o máquinas de desarrollo.
- **Riesgos de Out-Of-Memory (OOM)** al compilar en servidores pequeños.
- **Duplicación de código** en múltiples `Dockerfile.flutter.*`.

Con **`j4f-docker`**:
1. La imagen base **`ghcr.io/j4fdev/flutter-builder:stable`** ya tiene el SDK de Flutter, Dart y precache web preinstalados.
2. Cualquier proyecto hace `FROM ghcr.io/j4fdev/flutter-builder:stable AS builder` y compila en 1-2 minutos.
3. Se publica en **GitHub Container Registry (GHCR)** con acceso automático mediante credenciales de GitHub.

---

## 📦 Imágenes Disponibles

### 1. `flutter-builder` (`ghcr.io/j4fdev/flutter-builder:stable`)
- **Base**: `debian:bookworm-slim`
- **Herramientas**: Flutter SDK (canal stable), Dart SDK, git, curl, unzip, zip, certificados SSL.
- **Precache**: Artefactos de Web precacheados (`flutter precache --web`).
- **Usuario**: `builder` (UID 1000, con soporte sudo sin contraseña).

---

## 🛠️ Cómo Usarla en tus Proyectos (FitPlan, POS, Landing, etc.)

Reemplaza tu antiguo `Dockerfile.flutter.*` de 70 líneas por este archivo optimizado:

```dockerfile
# =========================================================================
# Multi-Stage Flutter Web Build — Usando imagen base centralizada J4F
# =========================================================================
FROM ghcr.io/j4fdev/flutter-builder:stable AS builder

ARG GIT_TOKEN
ARG API_BASE_URL
ARG GOOGLE_WEB_CLIENT_ID

# Configuración de credenciales Git para dependencias privadas (j4f-authsdk, etc.)
RUN if [ -n "$GIT_TOKEN" ]; then \
      git config --global url."https://${GIT_TOKEN}@github.com/".insteadOf "https://github.com/"; \
    fi

WORKDIR /app

# 1. Copiar pubspec y librerías primero (para aprovechar caché de capas Docker)
COPY --chown=builder:builder pubspec.* ./
# Si el proyecto usa librerías locales:
# COPY --chown=builder:builder ../../libraries /libraries

RUN flutter pub get

# 2. Copiar el resto del código y compilar en modo release
COPY --chown=builder:builder . .

RUN flutter build web --release \
    --dart-define=API_BASE_URL=$API_BASE_URL \
    --dart-define=GOOGLE_WEB_CLIENT_ID=$GOOGLE_WEB_CLIENT_ID

# =========================================================================
# Stage 2: Servidor Nginx SPA Ultra Ligero (~25MB)
# =========================================================================
FROM nginx:alpine

# Copiar archivos compilados
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copiar configuración Nginx optimizada para SPA
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:80/index.html > /dev/null || exit 1

CMD ["nginx", "-g", "daemon off;"]
```

---

## 💻 Uso Local (Sin depender de conexión o si estás probando cambios)

Si estás trabajando en local o en tu servidor y quieres construir la imagen base manualmente:

### En Windows (PowerShell):
```powershell
cd libraries/j4f-docker/flutter-builder
.\build.ps1
```

### En Linux / VPS:
```bash
cd libraries/j4f-docker/flutter-builder
chmod +x build.sh
./build.sh
```

Una vez construida localmente con el tag `ghcr.io/j4fdev/flutter-builder:stable`, Docker la utilizará automáticamente sin necesidad de descargarla de internet.

---

## 🌐 Publicación Automática a GitHub Container Registry (GHCR)

El archivo `.github/workflows/publish-flutter-builder.yml` compila y publica automáticamente la imagen en GHCR cada vez que se actualiza la carpeta `flutter-builder` en la rama principal.

### Autenticación para descargar imágenes privadas en el servidor:
Si el paquete es privado en tu organización de GitHub, en el VPS o máquina de desarrollo solo debes iniciar sesión una vez:
```bash
echo $TU_GITHUB_PAT | docker login ghcr.io -u TU_USUARIO_GITHUB --password-stdin
```
*(Si configuras el paquete como **Público** en la pestaña Packages de GitHub, ni siquiera requiere login para hacer `docker pull`).*
