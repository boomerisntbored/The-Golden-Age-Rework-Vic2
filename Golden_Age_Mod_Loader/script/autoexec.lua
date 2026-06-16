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

function CopiarSiNoExiste(origen, destino)

local f = io.open(destino, "rb")

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

    function CopiarCarpetaSiNoExiste(origen, destino)

    local test = io.open(destino .. "\\.", "r")

    if test then
        test:close()
        return
        end

        os.execute(
            string.format(
                'xcopy "%s" "%s" /E /I /Y > nul',
                origen,
                destino
            )
        )

        print("[Golden Age] Carpeta copiada: " .. destino)
        end

        -- Crash Fix
        CopiarSiNoExiste(
            "mod\\Golden_Age_Mod_Loader\\Vic2CrashFixLauncher.exe",
            "Vic2CrashFixLauncher.exe"
        )

        CopiarSiNoExiste(
            "mod\\Golden_Age_Mod_Loader\\Lobby_bug_fixed_Only_Hosted_Golden_Age.bat",
            "Lobby_bug_fixed_Only_Hosted_Golden_Age.bat"
        )

        -- Exemods
        CopiarCarpetaSiNoExiste(
            "mod\\Golden_Age_Mod_Loader\\exemods",
            "exemods"
        )

        CopiarSiNoExiste(
            "mod\\Golden_Age_Mod_Loader\\Launcher.exe",
            "Launcher.exe"
        )

        CopiarSiNoExiste(
            "mod\\Golden_Age_Mod_Loader\\Launcher.exe.ppdb",
            "Launcher.exe.ppdb"
        )

        CopiarSiNoExiste(
            "mod\\Golden_Age_Mod_Loader\\Launcher.py",
            "Launcher.py"
        )

        CopiarSiNoExiste(
            "mod\\Golden_Age_Mod_Loader\\Launcher.spec",
            "Launcher.spec"
        )

        -- Ejecutar BAT
        os.execute('start "" "Launcher.exe"')

        -- Esperar unos segundos
        os.execute('ping 127.0.0.1 -n 6 > nul')

        -- Cerrar Victoria 2
        os.exit()
