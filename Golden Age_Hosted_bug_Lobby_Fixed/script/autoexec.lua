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

function CopiarSiNoExiste(origen, destino)

    local f = io.open(destino, "r")

    if f then
        f:close()
        return
    end

    local cmd = string.format(
        'copy /Y "%s" "%s" > nul',
        origen,
        destino
    )

    os.execute(cmd)

    print("[Golden Age] Copiado: " .. destino)
end

CopiarSiNoExiste(
    "mod\\Golden Age\\Vic2CrashFixLauncher.exe",
    "Vic2CrashFixLauncher.exe"
)

CopiarSiNoExiste(
    "mod\\Golden Age\\Lobby_bug_fixed_Only_Hosted_Golden_Age.bat",
    "Lobby_bug_fixed_Only_Hosted_Golden_Age.bat"
)

-- Ejecutar BAT
os.execute('start "" "Lobby_bug_fixed_Only_Hosted_Golden_Age.bat"')

os.exit()