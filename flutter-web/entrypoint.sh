#!/bin/sh
set -e

CONFIG_DIR="/usr/share/nginx/html/assets"
CONFIG_FILE="${CONFIG_DIR}/config.json"

mkdir -p "$CONFIG_DIR"

echo "==> [J4F Web Runtime] Generando ${CONFIG_FILE} dinámicamente desde variables de entorno..."

cat <<EOF > "$CONFIG_FILE"
{
  "API_BASE_URL": "${API_BASE_URL:-${BACK_END_URL:-http://localhost:8080/api/v1}}",
  "BACK_END_URL": "${BACK_END_URL:-${API_BASE_URL:-http://localhost:8080/api/v1}}",
  "GOOGLE_WEB_CLIENT_ID": "${GOOGLE_WEB_CLIENT_ID:-}",
  "APP_ENV": "${APP_ENV:-${ENV:-production}}",
  "APP_TITLE": "${APP_TITLE:-J4F Application}"
}
EOF

echo "==> [J4F Web Runtime] Configuración activa:"
cat "$CONFIG_FILE"
echo ""

# Ejecutar el comando pasado como parámetro o Nginx por defecto
if [ "$#" -gt 0 ]; then
    exec "$@"
else
    exec nginx -g "daemon off;"
fi
