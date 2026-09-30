return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`AimAssist` encountered an error loading the Darktide Mod Framework.")

		new_mod("AimAssist", {
			mod_script = "AimAssist/scripts/mods/AimAssist/AimAssist",
			mod_data = "AimAssist/scripts/mods/AimAssist/AimAssist_data",
			mod_localization = "AimAssist/scripts/mods/AimAssist/AimAssist_localization",
		})
	end,
	packages = {},
}
