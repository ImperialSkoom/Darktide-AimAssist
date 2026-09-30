local Breed = require("scripts/utilities/breed")
local Breeds = require("scripts/settings/breed/breeds")

local localization = {
	mod_name = {
		en = "Aim Assist",
	},
	mod_description = {
		en = "Enables aim assistance when using ranged weapons.",
	},
	enabled = {
		en = "Enabled",
	},
	enabled_description = {
		en = "Enable the standalone auto-aim assist.",
	},
	activation_mode = {
		en = "Activation Mode",
	},
	activation_mode_description = {
		en = "Choose when the auto-aim assist is active.",
	},
	activation_mode_ads_only = {
		en = "ADS only",
	},
	activation_mode_ranged = {
		en = "While ranged is wielded",
	},
	activation_mode_disabled = {
		en = "Disabled",
	},
	assist_cone = {
		en = "Assist Cone",
	},
	assist_cone_description = {
		en = "Sets the maximum angle from the crosshair where a visible enemy can be selected.",
	},
	assist_cone_narrow = {
		en = "Narrow (4 degrees)",
	},
	assist_cone_wide = {
		en = "Wide (10 degrees)",
	},
	assist_cone_very_wide = {
		en = "Very wide (18 degrees)",
	},
	target_range = {
		en = "Target Range",
	},
	target_range_description = {
		en = "Sets the maximum distance where Aim Assist searches for targets.",
	},
	target_range_short = {
		en = "Short (30 m)",
	},
	target_range_medium = {
		en = "Medium (45 m)",
	},
	target_range_long = {
		en = "Long (70 m)",
	},
	adaptive_weapon_handling = {
		en = "Adaptive Weapon Handling",
	},
	adaptive_weapon_handling_description = {
		en = "Automatically tunes target search, camera snap, and retention for spread, projectile, charged, precision, and recoil-heavy ranged weapons.",
	},
	target_filter = {
		en = "Target Filter",
	},
	target_filter_description = {
		en = "Choose the broad enemy pool. Custom category and breed priorities are applied afterward.",
	},
	target_filter_high_value = {
		en = "Elites, specials, bosses",
	},
	target_filter_all = {
		en = "All enemies",
	},
	priority_list = {
		en = "Target Preference",
	},
	priority_list_description = {
		en = "Choose how valid targets are ranked before aim angle and distance break ties.",
	},
	priority_list_custom = {
		en = "Custom enemy priorities",
	},
	priority_list_threats = {
		en = "Threats first",
	},
	priority_list_bosses = {
		en = "Bosses first",
	},
	priority_list_specials = {
		en = "Specials first",
	},
	priority_list_closest = {
		en = "Closest to aim",
	},
	threat_override = {
		en = "Threat Override",
	},
	threat_override_description = {
		en = "Lets a higher-priority or clearly better-aligned target replace the briefly retained target.",
	},
	aim_weighting_settings = {
		en = "Custom Target Priorities",
	},
	aim_weighting_settings_description = {
		en = "Choose which enemy families can be targeted and assign each breed a strict priority tier.",
	},
	include_bosses = {
		en = "Bosses and Monsters",
	},
	include_bosses_description = {
		en = "Allow awakened bosses and monsters when using custom enemy priorities.",
	},
	include_specialists = {
		en = "Specialists",
	},
	include_specialists_description = {
		en = "Allow specialists such as snipers, trappers, flamers, mutants, and hounds when using custom enemy priorities.",
	},
	include_elites = {
		en = "Elites",
	},
	include_elites_description = {
		en = "Allow armored and squad-leader threats when using custom enemy priorities.",
	},
	include_regulars = {
		en = "Regular Enemies",
	},
	include_regulars_description = {
		en = "Allow basic enemies when using custom enemy priorities. Off by default; Target Filter must also be set to All enemies.",
	},
	aim_weight_snap_first = {
		en = "Highest priority",
	},
	aim_weight_strong = {
		en = "High priority",
	},
	aim_weight_normal = {
		en = "Normal priority",
	},
	aim_weight_light = {
		en = "Low priority",
	},
	aim_weight_last_resort = {
		en = "Fallback only",
	},
	aim_weight_ignore = {
		en = "Ignore",
	},
	camera_snap = {
		en = "Camera Snap",
	},
	camera_snap_description = {
		en = "Pulls the camera toward the selected assist target while Aim Assist is active.",
	},
	camera_snap_soft = {
		en = "Soft",
	},
	camera_snap_strong = {
		en = "Strong",
	},
	camera_snap_instant = {
		en = "Instant",
	},
	camera_snap_off = {
		en = "Off",
	},
	aim_point = {
		en = "Aim Point",
	},
	aim_point_description = {
		en = "Choose the enemy aim node the assisted shot should use.",
	},
	aim_point_head = {
		en = "Head",
	},
	aim_point_torso = {
		en = "Torso",
	},
}

local function is_targetable_enemy_breed(breed_data)
	return Breed.is_minion(breed_data)
		and breed_data.faction_name ~= "imperium"
		and breed_data.is_untargetable ~= true
end

local function add_breed_localization(breed_name, breed_data)
	local display_name = breed_data.is_boss
		and type(breed_data.boss_display_name) == "string"
		and breed_data.boss_display_name
		or breed_data.display_name
	local text = display_name and Localize(display_name) or breed_name

	if type(text) ~= "string" or string.find(text, "unlocalized", 1, true) then
		text = breed_name
	end

	if breed_name ~= "chaos_mutator_daemonhost" and string.find(breed_name, "mutator") then
		text = text .. " (mutator)"
	end

	localization[breed_name] = {
		en = text,
	}
end

for breed_name, breed_data in pairs(Breeds) do
	if is_targetable_enemy_breed(breed_data) then
		add_breed_localization(breed_name, breed_data)
	end
end

return localization
