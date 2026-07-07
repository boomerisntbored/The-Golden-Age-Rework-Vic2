@echo off
setlocal enabledelayedexpansion

echo ====================================================
echo    Modo Diagnostico: Optimizador para Victoria 2
echo ====================================================

:: 1. VERIFICAR O DESCARGAR TEXCONV AUTOMÁTICAMENTE
if not exist "texconv.exe" (
    echo [i] texconv.exe no encontrado. Descargando de Microsoft GitHub...
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/microsoft/DirectXTex/releases/latest/download/texconv.exe' -OutFile 'texconv.exe'"
    
    if not exist "texconv.exe" (
        echo [X] Error critico: No se pudo descargar texconv.exe automaticamente.
        pause
        exit /b
    )
    echo [^!] Descarga exitosa. texconv.exe esta listo.
)

:: 2. CREAR CARPETA DE SALIDA
if not exist "optimizadas" mkdir optimizadas

echo ----------------------------------------------------
echo [i] Procesando... Si hay un error, lo veras en pantalla:
echo ----------------------------------------------------

set "count_dds=0"
set "count_tga=0"

:: 3. OPTIMIZAR ARCHIVOS DDS (Sin ocultar errores)
for %%i in (*.dds) do (
    echo [>] Procesando DDS: "%%i"
    :: Quitamos el >nul para ver el reporte de error real si falla
    texconv.exe -f BC3_UNORM -m 1 -y -o optimizadas "%%i"
    if errorlevel 1 (
        echo [X] Error al procesar: "%%i"
    ) else (
        set /a count_dds+=1
    )
    echo ----------------------------------------------------
)

:: 4. OPTIMIZAR ARCHIVOS TGA (Sin ocultar errores)
for %%i in (*.tga) do (
    echo [>] Procesando TGA: "%%i"
    texconv.exe -f TGA -y -o optimizadas "%%i"
    if errorlevel 1 (
        echo [X] Error al procesar: "%%i"
    ) else (
        set /a count_tga+=1
    )
    echo ----------------------------------------------------
)

set /a total=!count_dds! + !count_tga!

echo ----------------------------------------------------
echo [^!] Proceso terminado.
echo [-] DDS listos: !count_dds! | TGA listos: !count_tga!
echo ----------------------------------------------------
pause