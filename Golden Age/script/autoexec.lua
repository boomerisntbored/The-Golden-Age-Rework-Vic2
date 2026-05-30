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

-- loading screen randomizer function
function RandomizeLoadingScreens()
	local ls_dir = "mod\\Golden Age\\gfx\\loadingscreens\\"
	local ls_start = "load_"
	local ls_end = ".dds"

	-- 1. DETECTAR EL NÚMERO TOTAL DE IMÁGENES DINÁMICAMENTE
	local ls_num = 0
	while true do
		local siguiente_numero = string.format("%02d", ls_num + 1)
		local ruta_archivo = ls_dir .. ls_start .. siguiente_numero .. ls_end

		-- Intentamos abrir el archivo para ver si existe
		local f = io.open(ruta_archivo, "r")
		if f then
			f:close()
			ls_num = ls_num + 1
		else
			break -- Si no existe, encontramos el límite
		end
	end

	-- Si no se encontraron imágenes, salimos de la función para evitar errores
	if ls_num == 0 then return end

	-- 2. CREAR Y BARAJAR EL ARRAY DE ÍNDICES
	local ls_i_array = {}
	for i=1, ls_num do
		ls_i_array[i] = i
	end

	for i = #ls_i_array, 1, -1 do
		local j = math.random(i)
		ls_i_array[i], ls_i_array[j] = ls_i_array[j], ls_i_array[i]
	end

	-- 3. PASO SEGURIDAD: Renombrar temporalmente para no pisar archivos
	for i=1, ls_num do
		local ls_mid = string.format("%02d", i)
		local ls_old = ls_dir .. ls_start .. ls_mid .. ls_end
		local ls_temp = ls_dir .. "temp_" .. ls_mid .. ls_end
		os.rename(ls_old, ls_temp)
	end

	-- 4. PASO FINAL: Aplicar el orden aleatorio desde los temporales
	for i, index in pairs(ls_i_array) do
		local ls_old_mid = string.format("%02d", i)
		local ls_new_mid = string.format("%02d", index)
		local ls_old = ls_dir .. "temp_" .. ls_old_mid .. ls_end
		local ls_new = ls_dir .. ls_start .. ls_new_mid .. ls_end
		os.rename(ls_old, ls_new)
	end
end

-- Inicializar la semilla del sistema para que el azar cambie en cada inicio
math.randomseed(os.time())

-- Ejecutar la función
RandomizeLoadingScreens()
