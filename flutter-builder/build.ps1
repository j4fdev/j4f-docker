# Script para compilar y etiquetar la imagen localmente
$IMAGE_NAME = "ghcr.io/j4fdev/flutter-builder:stable"

Write-Host "Construyendo imagen $IMAGE_NAME..." -ForegroundColor Cyan
docker build -t $IMAGE_NAME -f Dockerfile .

if ($LASTEXITCODE -eq 0) {
    Write-Host "Imagen construida exitosamente como $IMAGE_NAME" -ForegroundColor Green
    Write-Host "Probando versión de flutter..." -ForegroundColor Cyan
    docker run --rm $IMAGE_NAME flutter --version
} else {
    Write-Host "Error durante la construccion de la imagen." -ForegroundColor Red
}
