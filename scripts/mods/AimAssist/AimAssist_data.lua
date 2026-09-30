local mod = get_mod("AimAssist")

local Breed = require("scripts/utilities/breed")
local Breeds = require("scripts/settings/breed/breeds")

local HIGH_PRIORITY_THREAT_BREEDS = {
	chaos_armored_hound = true,
	chaos_hound = true,
	chaos_hound_mutator = true,
	cultist_mutant = true,
	cultist_mutant_mutator = true,
	renegade_netgunner = true,
	renegade_radio_operator = true,
	renegade_sniper = true,
}
local AREA_THREAT_BREEDS = {
	chaos_poxwalker_bomber = true,
	cultist_flamer = true,
	cultist_grenadier = true,
	renegade_flamer = true,
	renegade_flamer_mutator = true,
	renegade_grenadier = true,
}
local SHOOTER_THREAT_BREEDS = {
	chaos_ogryn_gunner = true,
	cultist_gunner = true,
	renegade_gunner = true,
	renegade_plasma_gunner = true,
}

local function is_targetable_enemy_breed(breed_data)
	return Breed.is_minion(breed_data)
		and breed_data.faction_name ~= "imperium"
		and breed_data.is_untargetable ~= true
end

local function default_breed_priority(breed_name, breed_data)
	local tags = breed_data.tags or {}

	if tags.disabler or HIGH_PRIORITY_THREAT_BREEDS[breed_name] then
		return 5
	elseif AREA_THREAT_BREEDS[breed_name] or SHOOTER_THREAT_BREEDS[breed_name] then
		return 4
	elseif breed_data.is_boss then
		return 4
	elseif tags.special then
		return 4
	elseif tags.elite or tags.ogryn then
		return 3
	end

	return 1
end

local function create_breed_priority_dropdown(breed_name, default_value)
	return {
		setting_id = breed_name,
		type = "dropdown",
		default_value = default_value,
		options = {
			{ text = "aim_weight_snap_first", value = 5 },
			{ text = "aim_weight_strong", value = 4 },
			{ text = "aim_weight_normal", value = 3 },
			{ text = "aim_weight_light", value = 2 },
			{ text = "aim_weight_last_resort", value = 1 },
			{ text = "aim_weight_ignore", value = 0 },
		},
	}
end

local elite_priorities = {}
local special_priorities = {}
local boss_priorities = {}
local other_priorities = {}

for breed_name, breed_data in pairs(Breeds) do
	if is_targetable_enemy_breed(breed_data) then
		local priority_dropdown = create_breed_priority_dropdown(breed_name, default_breed_priority(breed_name, breed_data))
		local tags = breed_data.tags or {}

		if breed_data.is_boss then
			boss_priorities[#boss_priorities + 1] = priority_dropdown
		elseif tags.elite then
			elite_priorities[#elite_priorities + 1] = priority_dropdown
		elseif tags.special then
			special_priorities[#special_priorities + 1] = priority_dropdown
		else
			other_priorities[#other_priorities + 1] = priority_dropdown
		end
	end
end

local function localized_sort(a, b)
	return mod:localize(a.setting_id) < mod:localize(b.setting_id)
end

table.sort(elite_priorities, localized_sort)
table.sort(special_priorities, localized_sort)
table.sort(boss_priorities, localized_sort)
table.sort(other_priorities, localized_sort)

local boss_weight_widget = {
	setting_id = "include_bosses",
	type = "checkbox",
	default_value = true,
	sub_widgets = boss_priorities,
}
local specialist_weight_widget = {
	setting_id = "include_specialists",
	type = "checkbox",
	default_value = true,
	sub_widgets = special_priorities,
}
local elite_weight_widget = {
	setting_id = "include_elites",
	type = "checkbox",
	default_value = true,
	sub_widgets = elite_priorities,
}
local regular_weight_widget = {
	setting_id = "include_regulars",
	type = "checkbox",
	default_value = false,
	sub_widgets = other_priorities,
}

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "enabled",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "activation_mode",
				type = "dropdown",
				default_value = "ranged",
				options = {
					{ text = "activation_mode_ads_only", value = "ads_only" },
					{ text = "activation_mode_ranged", value = "ranged" },
					{ text = "activation_mode_disabled", value = "disabled" },
				},
			},
			{
				setting_id = "assist_cone",
				type = "dropdown",
				default_value = "wide",
				options = {
					{ text = "assist_cone_narrow", value = "narrow" },
					{ text = "assist_cone_wide", value = "wide" },
					{ text = "assist_cone_very_wide", value = "very_wide" },
				},
			},
			{
				setting_id = "target_range",
				type = "dropdown",
				default_value = "medium",
				options = {
					{ text = "target_range_short", value = "short" },
					{ text = "target_range_medium", value = "medium" },
					{ text = "target_range_long", value = "long" },
				},
			},
			{
				setting_id = "adaptive_weapon_handling",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "target_filter",
				type = "dropdown",
				default_value = "high_value",
				options = {
					{ text = "target_filter_high_value", value = "high_value" },
					{ text = "target_filter_all", value = "all" },
				},
			},
			{
				setting_id = "priority_list",
				type = "dropdown",
				default_value = "custom",
				options = {
					{ text = "priority_list_custom", value = "custom" },
					{ text = "priority_list_threats", value = "threats" },
					{ text = "priority_list_bosses", value = "bosses" },
					{ text = "priority_list_specials", value = "specials" },
					{ text = "priority_list_closest", value = "closest" },
				},
			},
			{
				setting_id = "threat_override",
				type = "checkbox",
				default_value = true,
			},
			{
				setting_id = "aim_weighting_settings",
				type = "group",
				sub_widgets = {
					boss_weight_widget,
					specialist_weight_widget,
					elite_weight_widget,
					regular_weight_widget,
				},
			},
			{
				setting_id = "camera_snap",
				type = "dropdown",
				default_value = "soft",
				options = {
					{ text = "camera_snap_soft", value = "soft" },
					{ text = "camera_snap_strong", value = "strong" },
					{ text = "camera_snap_instant", value = "instant" },
					{ text = "camera_snap_off", value = "off" },
				},
			},
			{
				setting_id = "aim_point",
				type = "dropdown",
				default_value = "head",
				options = {
					{ text = "aim_point_head", value = "head" },
					{ text = "aim_point_torso", value = "torso" },
				},
			},
		},
	},
}
