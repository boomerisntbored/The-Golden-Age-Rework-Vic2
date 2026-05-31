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
	local ls_i_array = {}
	local ls_num = 11

	for i=1, ls_num do
		ls_i_array[i] = i
	end

	for i = #ls_i_array, 1, -1 do
		local j = math.random(i)
		ls_i_array[i], ls_i_array[j] = ls_i_array[j], ls_i_array[i]
	end

	local ls_dir = "mod\\Golden Age\\gfx\\loadingscreens\\"
	local ls_start = "load_"
	local ls_end = ".dds"

	for i=1, #ls_i_array do
		local ls_mid = string.format("%02d", i)
		local ls_old = ls_dir .. ls_start .. ls_mid .. ls_end
		local ls_temp = ls_dir .. ls_mid .. ls_end
		os.rename(ls_old, ls_temp)
	end

	for i, index in pairs(ls_i_array) do
		local ls_old_mid = string.format("%02d", i)
		local ls_new_mid = string.format("%02d", index)
		local ls_old = ls_dir .. ls_old_mid .. ls_end
		local ls_new = ls_dir .. ls_start .. ls_new_mid .. ls_end
		os.rename(ls_old, ls_new)
	end

end

RandomizeLoadingScreens()
