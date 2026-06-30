-- AUTOEXEC.LUA
-- Victoria2 AutoExec
-- This file is run on app start after exports are done inside the engine (once per context created)

-- check for user mod files
package.path = package.path .. ";script\\?.lua;script\\country\\?.lua"

if CCurrentGameState.HasCommonExtension() then
	local modDir = tostring(CCurrentGameState.GetCommonModDirectory())
	package.path = package.path .. ";" .. modDir .. "\\?.lua"
end

package.path = package.path .. ";common\\?.lua"

--require('hoi') -- already imported by game, contains all exported classes
require('tweaks')
require('utils')
require('defines')
require('ai_country')


-- load country specific AI modules.
--require('ENG')

-- ==========================================
-- INSTALADOR AUTOMÁTICO DE ARCHIVOS
-- ==========================================

-- 1. FUNCIÓN DE COPIADO NATIVA (Sin os.execute ni ventanas negras)
function CopiarSiNoExiste(origen, destino)
local f_chk = io.open(destino, "r")
if f_chk then
    f_chk:close()
    return
    end

    local f_origen, err = io.open(origen, "rb")
    if not f_origen then
        print("[Golden Age] Error abriendo origen: " .. tostring(err))
        return
        end

        local f_destino = io.open(destino, "wb")
        if not f_destino then
            f_origen:close()
            return
            end

            local contenido = f_origen:read("*all")
            f_destino:write(contenido)

            f_origen:close()
            f_destino:close()

            print("[Golden Age] Copiado nativo en silencio: " .. destino)
            end

            -- Ejecutamos las copias con tus rutas
            CopiarSiNoExiste(
                "mod/Golden Age/Vic2CrashFixLauncher.exe",
                "Vic2CrashFixLauncher.exe"
            )

            CopiarSiNoExiste(
                "mod/Golden_Age_MANDATORY/Golden Age_temp.mod",
                "mod/Golden Age_temp.mod"
            )

            CopiarSiNoExiste(
                "mod/Golden_Age_MANDATORY/Lobby_bug_fixed_Only_Hosted_Golden_Age.bat",
                "Lobby_bug_fixed_Only_Hosted_Golden_Age.bat"
            )

            -- 2. EJECUTAR EL BAT EN SEGUNDO PLANO (Híbrido Windows / Proton)
            -- 'start /B' fuerza la ejecución en el mismo hilo oculto y '> nul 2>&1' traga cualquier salida gráfica.
            os.execute('start /B cmd.exe /c Lobby_bug_fixed_Only_Hosted_Golden_Age.bat > nul 2>&1')

            -- Cerramos el proceso del script actual de Lua limpiamente
            os.exit()
