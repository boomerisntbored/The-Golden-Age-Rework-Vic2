@echo off

REM Ir a la raíz del juego (dos carpetas arriba)
cd

REM Si no existe el launcher en la raíz, copiarlo desde el mod
if not exist "Vic2CrashFixLauncher.exe" (
    copy /Y "mod\Golden Age\Vic2CrashFixLauncher.exe" "Vic2CrashFixLauncher.exe"
)

REM Ejecutar el launcher con el mod
start "" "Vic2CrashFixLauncher.exe" -mod=mod/Golden Age_temp.mod

exit
