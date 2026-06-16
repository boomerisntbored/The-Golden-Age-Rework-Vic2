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

function RandomizeLoadingScreens()
    local ls_dir = "mod\\Golden Age\\gfx\\loadingscreens\\"
    
    -- 1. Generar una lista de todos los archivos .dds reales de la carpeta de forma invisible
    -- Usamos /B para solo nombres y > para guardarlo en un archivo de texto temporal
    local list_file = ls_dir .. "file_list.tmp"
    os.execute('dir "' .. ls_dir .. '*.dds" /B > "' .. list_file .. '"')

    -- 2. Leer ese archivo de texto y meter los nombres reales en una tabla
    local raw_files = {}
    local f = io.open(list_file, "r")
    if f then
        for line in f:lines() do
            if line ~= "" then
                table.insert(raw_files, line)
            end
        end
        f:close()
        os.remove(list_file) -- Borramos el archivo temporal de texto
    end

    local total_files = #raw_files
    if total_files == 0 then return end -- Si no hay archivos, frena para evitar errores

    -- 3. PASO CLAVE: Renombrar TODO el desorden actual a "pantalla_1.dds", "pantalla_2.dds", etc.
    -- Esto limpia de raíz los nombres raros de tu captura (load_22, load_3, etc.)
    for i = 1, total_files do
        local old_path = ls_dir .. raw_files[i]
        local temp_path = string.format("%spantalla_%d.dds", ls_dir, i)
        os.rename(old_path, temp_path)
    end

    -- 4. Crear la lista de índices aleatorios (Fisher-Yates Shuffle)
    local ls_i_array = {}
    for i = 1, total_files do
        ls_i_array[i] = i
    end

    math.randomseed(os.time())
    for i = total_files, 1, -1 do
        local j = math.random(i)
        ls_i_array[i], ls_i_array[j] = ls_i_array[j], ls_i_array[i]
    end

    -- 5. Pasar de "pantalla_X" al nombre definitivo "load_XX" usando el orden aleatorio
    for i = 1, total_files do
        local temp_path = string.format("%spantalla_%d.dds", ls_dir, i)
        
        -- El destino final usará el formato limpio: load_01.dds, load_02.dds, etc.
        local dest_mid = string.format("%02d", ls_i_array[i])
        local final_path = string.format("%sload_%s.dds", ls_dir, dest_mid)
        
        os.rename(temp_path, final_path)
    end
end

RandomizeLoadingScreens()