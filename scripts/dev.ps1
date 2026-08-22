<# 
.SYNOPSIS
    Script para levantar backend y frontend simultáneamente en Windows PowerShell

.DESCRIPTION
    Inicia el backend NestJS y el frontend Flutter en modo desarrollo
#>

param(
    [switch]$SkipBackend,
    [switch]$SkipFrontend
)

$ErrorActionPreference = "Stop"

$PROJECT_ROOT = Split-Path -Parent $MyInvocation.MyCommand.Definition | Split-Path -Parent
$BACKEND_DIR = Join-Path $PROJECT_ROOT "backend"
$FRONTEND_DIR = Join-Path $PROJECT_ROOT "frontend"

Write-Host "🚀 Iniciando El Mapita UTB - Entorno de desarrollo" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# Verificar directorios
if (-not (Test-Path $BACKEND_DIR)) {
    Write-Error "❌ Directorio backend no encontrado: $BACKEND_DIR"
    exit 1
}

if (-not (Test-Path $FRONTEND_DIR)) {
    Write-Error "❌ Directorio frontend no encontrado: $FRONTEND_DIR"
    exit 1
}

# Verificar .env en backend
if (-not (Test-Path (Join-Path $BACKEND_DIR ".env"))) {
    Write-Warning "⚠️  Archivo .env no encontrado en backend. Copiando desde .env.example"
    Copy-Item (Join-Path $BACKEND_DIR ".env.example") (Join-Path $BACKEND_DIR ".env") -Force
    Write-Warning "   Edita $BACKEND_DIR\.env con tus credenciales de Supabase"
}

$backendProcess = $null
$frontendProcess = $null

# Función de limpieza
function Cleanup {
    Write-Host "`n🛑 Deteniendo servicios..." -ForegroundColor Yellow
    if ($backendProcess) { Stop-Process -Id $backendProcess.Id -Force -ErrorAction SilentlyContinue }
    if ($frontendProcess) { Stop-Process -Id $frontendProcess.Id -Force -ErrorAction SilentlyContinue }
    exit 0
}

# Registrar handler para Ctrl+C
[System.Console]::CancelKeyPress += { Cleanup }

if (-not $SkipBackend) {
    Write-Host "📦 Iniciando backend (NestJS) en puerto 3000..." -ForegroundColor Cyan
    $backendProcess = Start-Process -FilePath "npm" -ArgumentList "run", "start:dev" -WorkingDirectory $BACKEND_DIR -PassThru
    
    Write-Host "⏳ Esperando a que el backend esté listo..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    
    # Verificar health check
    for ($i = 1; $i -le 10; $i++) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -Method GET -TimeoutSec 5 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Host "✅ Backend listo en http://localhost:3000" -ForegroundColor Green
                Write-Host "📚 Swagger docs: http://localhost:3000/docs" -ForegroundColor Green
                break
            }
        } catch {
            if ($i -eq 10) {
                Write-Error "❌ Backend no respondió después de 10 intentos"
                Cleanup
            }
            Start-Sleep -Seconds 2
        }
    }
}

if (-not $SkipFrontend) {
    Write-Host "📱 Iniciando frontend (Flutter)..." -ForegroundColor Cyan
    
    Write-Host "🔍 Buscando dispositivos..." -ForegroundColor Yellow
    flutter devices
    
    Write-Host "✅ Frontend listo. Ejecuta 'flutter run' en otra terminal o usa tu IDE." -ForegroundColor Green
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "🎉 ¡Entorno de desarrollo listo!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend:  http://localhost:3000 (API)" -ForegroundColor Green
Write-Host "Docs:     http://localhost:3000/docs (Swagger)" -ForegroundColor Green
Write-Host "Frontend: Ejecuta 'flutter run' en $FRONTEND_DIR" -ForegroundColor Green
Write-Host ""
Write-Host "Presiona Ctrl+C para detener los servicios" -ForegroundColor Yellow

# Mantener script corriendo si backend está activo
if ($backendProcess) {
    try {
        $backendProcess.WaitForExit()
    } catch {
        Cleanup
    }
}