-- Author: ImperialSkoom

local mod = get_mod("AimAssist")

local Action = require("scripts/utilities/action/action")
local Breed = require("scripts/utilities/breed")
local BuffSettings = require("scripts/settings/buff/buff_settings")
local Breeds = require("scripts/settings/breed/breeds")
local MinionPerception = require("scripts/utilities/minion_perception")
local WeaponTemplate = require("scripts/utilities/weapon/weapon_template")

local AUTO_AIM_KEYWORD = BuffSettings.keywords.enable_auto_aim
local TARGET_RESULTS = {}
local TARGET_NODES = {
	head = "enemy_aim_target_03",
	torso = "enemy_aim_target_02",
}
local CONE_ANGLES = {
	narrow = 4,
	wide = 10,
	very_wide = 18,
}
local RANGE_VALUES = {
	short = 30,
	medium = 45,
	long = 70,
}
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
local CAMERA_SNAP_SPEEDS = {
	off = 0,
	soft = 8,
	strong = 16,
	instant = -1,
}
local AIM_PROFILES = {
	default = {
		cone_scale = 1,
		range_scale = 1,
		snap_scale = 1,
		retention_scale = 1,
		angle_weight = 1.8,
		distance_weight = 0.2,
	},
	close_spread = {
		cone_scale = 1.25,
		range_scale = 0.65,
		snap_scale = 0.75,
		retention_scale = 0.8,
		angle_weight = 1.35,
		distance_weight = 0.55,
	},
	projectile = {
		cone_scale = 0.8,
		range_scale = 0.85,
		snap_scale = 0.65,
		retention_scale = 0.8,
		angle_weight = 2.1,
		distance_weight = 0.15,
	},
	area = {
		cone_scale = 1.1,
		range_scale = 0.75,
		snap_scale = 0.55,
		retention_scale = 0.7,
		angle_weight = 1.4,
		distance_weight = 0.45,
	},
	charged = {
		cone_scale = 0.85,
		range_scale = 1.15,
		snap_scale = 0.8,
		retention_scale = 1.25,
		angle_weight = 2.2,
		distance_weight = 0.15,
	},
	precision = {
		cone_scale = 0.7,
		range_scale = 1.25,
		snap_scale = 1.1,
		retention_scale = 1.15,
		angle_weight = 2.5,
		distance_weight = 0.1,
	},
	recoil_heavy = {
		cone_scale = 0.85,
		range_scale = 0.95,
		snap_scale = 1.15,
		retention_scale = 1.35,
		angle_weight = 1.7,
		distance_weight = 0.25,
	},
}
local CHARGED_RANGED_WEAPONS = {
	forcestaff_p1_m1 = true,
	forcestaff_p2_m1 = true,
	forcestaff_p3_m1 = true,
	forcestaff_p4_m1 = true,
	lasgun_p2_m1 = true,
	lasgun_p2_m2 = true,
	lasgun_p2_m3 = true,
	plasmagun_p1_m1 = true,
	plasmagun_p1_m2 = true,
	psyker_chain_lightning = true,
}
local PRECISION_RANGED_WEAPONS = {
	autogun_p3_m1 = true,
	autogun_p3_m2 = true,
	autogun_p3_m3 = true,
	lasgun_p1_m1 = true,
	lasgun_p1_m2 = true,
	lasgun_p1_m3 = true,
	laspistol_p1_m1 = true,
	stubrevolver_p1_m1 = true,
	stubrevolver_p1_m2 = true,
}
local CLOSE_SPREAD_WEAPONS = {
	ogryn_rippergun_p1_m1 = true,
	ogryn_rippergun_p1_m2 = true,
	ogryn_rippergun_p1_m3 = true,
	shotgun_p1_m1 = true,
	shotgun_p1_m2 = true,
	shotgun_p1_m3 = true,
	shotgun_p2_m1 = true,
	shotgun_p4_m1 = true,
	shotgun_p4_m2 = true,
	shotpistol_shield_p1_m1 = true,
}
local RECOIL_HEAVY_WEAPONS = {
	autogun_p1_m1 = true,
	autogun_p1_m2 = true,
	autogun_p1_m3 = true,
	autogun_p2_m1 = true,
	autogun_p2_m2 = true,
	autogun_p2_m3 = true,
	autopistol_p1_m1 = true,
	bolter_p1_m1 = true,
	boltpistol_p1_m1 = true,
	dual_stubpistols_p1_m1 = true,
	lasgun_p3_m1 = true,
	lasgun_p3_m2 = true,
	lasgun_p3_m3 = true,
	ogryn_heavystubber_p1_m1 = true,
	ogryn_heavystubber_p1_m2 = true,
	ogryn_heavystubber_p1_m3 = true,
	ogryn_heavystubber_p2_m1 = true,
	ogryn_heavystubber_p2_m2 = true,
	ogryn_heavystubber_p2_m3 = true,
}
local DEFAULT_BREED_PRIORITIES = {}
local BREED_PRIORITY_KEYS = {}
local TARGET_SWITCH_SCORE_MARGIN = 0.2

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

for breed_name, breed_data in pairs(Breeds) do
	if is_targetable_enemy_breed(breed_data) then
		DEFAULT_BREED_PRIORITIES[breed_name] = default_breed_priority(breed_name, breed_data)
		BREED_PRIORITY_KEYS[#BREED_PRIORITY_KEYS + 1] = breed_name
	end
end

local active = true
local activation_mode = "ranged"
local cached_aiming = false
local last_aiming_t = 0
local target_node = TARGET_NODES.head
local cone_angle = CONE_ANGLES.wide
local target_range = RANGE_VALUES.medium
local target_filter = "high_value"
local priority_list = "custom"
local adaptive_weapon_handling = true
local threat_override = true
local camera_snap = "soft"
local include_elites = true
local include_specialists = true
local include_bosses = true
local include_regulars = false
local breed_priorities = {}
local AIM_GRACE_WINDOW = 0.35
local TARGET_RETENTION_WINDOW = 0.3
local hooked_require_tables = setmetatable({}, { __mode = "k" })
local retained_target_unit = nil
local retained_target_until = 0
local query_failure_reported = false
local diagnostic = {
	camera_calls = 0,
	search = "not called",
	source = "none",
	targets = 0,
	allowed = 0,
	in_cone = 0,
	visible = 0,
	snaps = 0,
}
local diagnostic_delay = nil

local function clear_retained_target()
	retained_target_unit = nil
	retained_target_until = 0
end

local function degrees_to_radians(degrees)
	return degrees * 0.0174532925
end

local function gameplay_time()
	return Managers and Managers.time and Managers.time:time("gameplay") or 0
end

local function refresh_settings()
	active = mod:get("enabled") ~= false
	activation_mode = mod:get("activation_mode") or "ranged"
	target_node = TARGET_NODES[mod:get("aim_point") or "head"] or TARGET_NODES.head
	cone_angle = CONE_ANGLES[mod:get("assist_cone") or "wide"] or CONE_ANGLES.wide
	target_range = RANGE_VALUES[mod:get("target_range") or "medium"] or RANGE_VALUES.medium
	target_filter = mod:get("target_filter") or "high_value"
	priority_list = mod:get("priority_list") or "custom"
	adaptive_weapon_handling = mod:get("adaptive_weapon_handling") ~= false
	camera_snap = mod:get("camera_snap") or "soft"

	threat_override = mod:get("threat_override") ~= false
	include_elites = mod:get("include_elites") ~= false
	include_specialists = mod:get("include_specialists") ~= false
	include_bosses = mod:get("include_bosses") ~= false
	include_regulars = mod:get("include_regulars") == true

	table.clear(breed_priorities)

	for i = 1, #BREED_PRIORITY_KEYS do
		local breed_name = BREED_PRIORITY_KEYS[i]
		local default_priority = DEFAULT_BREED_PRIORITIES[breed_name] or 0

		breed_priorities[breed_name] = tonumber(mod:get(breed_name)) or default_priority
	end

	clear_retained_target()
end

local function skip_repeated_require_hook(instance)
	if hooked_require_tables[instance] then
		return true
	end

	hooked_require_tables[instance] = true

	return false
end

local function local_player_unit()
	local player_manager = Managers and Managers.player
	local player = player_manager and player_manager:local_player_safe(1)

	return player and player.player_unit or nil
end

local function ui_using_input()
	local ui_manager = Managers and Managers.ui

	return ui_manager and ui_manager.using_input and ui_manager:using_input() or false
end

local function is_local_player_unit(unit)
	return unit and unit == local_player_unit()
end

local function unit_data_extension(unit)
	return unit and ScriptUnit.has_extension(unit, "unit_data_system") or nil
end

local function local_smart_targeting_extension()
	local unit = local_player_unit()

	return unit and ScriptUnit.has_extension(unit, "smart_targeting_system") or nil
end

local function current_weapon_template(unit_data)
	if not unit_data then
		return nil
	end

	local weapon_action_component = unit_data:read_component("weapon_action")

	return weapon_action_component and WeaponTemplate.current_weapon_template(weapon_action_component) or nil
end

local function current_action_settings_from(weapon_action_component, weapon_template)
	return weapon_action_component
		and weapon_template
		and Action.current_action_settings_from_component(weapon_action_component, weapon_template.actions)
		or nil
end

local function current_weapon_context(unit_data, optional_weapon_template, optional_weapon_action_component)
	local weapon_action_component = optional_weapon_action_component

	if not weapon_action_component and unit_data then
		weapon_action_component = unit_data:read_component("weapon_action")
	end

	local weapon_template = optional_weapon_template
		or weapon_action_component and WeaponTemplate.current_weapon_template(weapon_action_component)
		or nil

	if not weapon_template and unit_data then
		weapon_template = current_weapon_template(unit_data)
	end

	return weapon_template, current_action_settings_from(weapon_action_component, weapon_template), weapon_action_component
end

local function string_contains(value, text)
	return type(value) == "string" and string.find(value, text, 1, true) ~= nil
end

local function adaptive_aim_profile(weapon_template, action_settings, weapon_action_component)
	if not adaptive_weapon_handling then
		return AIM_PROFILES.default
	end

	local template_name = weapon_template and weapon_template.name
	local action_kind = action_settings and action_settings.kind
	local action_name = weapon_action_component and weapon_action_component.current_action_name

	if action_kind == "flamer_gas"
		or action_kind == "flamer_gas_burst"
		or action_kind == "chain_lightning"
		or string_contains(template_name, "flamer")
		or template_name == "psyker_chain_lightning"
	then
		return AIM_PROFILES.area
	end

	if action_kind == "shoot_pellets"
		or template_name and CLOSE_SPREAD_WEAPONS[template_name]
		or string_contains(template_name, "shotgun")
		or string_contains(template_name, "rippergun")
		or string_contains(template_name, "shotpistol")
	then
		return AIM_PROFILES.close_spread
	end

	if action_kind == "spawn_projectile"
		or action_kind == "shoot_projectile"
		or string_contains(template_name, "grenade")
		or string_contains(template_name, "gauntlet")
		or string_contains(template_name, "thumper")
	then
		return AIM_PROFILES.projectile
	end

	if template_name and CHARGED_RANGED_WEAPONS[template_name]
		or string_contains(action_kind, "charge")
		or string_contains(action_name, "charge")
		or string_contains(template_name, "plasmagun")
		or string_contains(template_name, "forcestaff")
	then
		return AIM_PROFILES.charged
	end

	if template_name and PRECISION_RANGED_WEAPONS[template_name]
		or string_contains(template_name, "longlas")
		or string_contains(template_name, "stubrevolver")
	then
		return AIM_PROFILES.precision
	end

	if template_name and RECOIL_HEAVY_WEAPONS[template_name]
		or string_contains(template_name, "autopistol")
		or string_contains(template_name, "bolt")
		or string_contains(template_name, "bolter")
		or string_contains(template_name, "dual_stubpistols")
		or string_contains(template_name, "heavy_stubber")
		or string_contains(template_name, "heavystubber")
		or string_contains(template_name, "stubgun")
		or string_contains(template_name, "autogun") and not string_contains(template_name, "autogun_p3")
	then
		return AIM_PROFILES.recoil_heavy
	end

	return AIM_PROFILES.default
end

local function template_has_keyword(template, wanted_keyword)
	local keywords = template and template.keywords

	if not keywords then
		return false
	end

	for i = 1, #keywords do
		if keywords[i] == wanted_keyword then
			return true
		end
	end

	return false
end

local function is_ranged_wielded(unit_data)
	if not unit_data then
		return false
	end

	local inventory_component = unit_data:read_component("inventory")

	if inventory_component then
		if inventory_component.wielded_slot == "slot_secondary" then
			return true
		elseif inventory_component.wielded_slot == "slot_primary" then
			return false
		end
	end

	return template_has_keyword(current_weapon_template(unit_data), "ranged")
end

local function is_reloading(unit_data)
	if not unit_data then
		return false
	end

	local weapon_action_component = unit_data:read_component("weapon_action")
	local weapon_template = weapon_action_component and WeaponTemplate.current_weapon_template(weapon_action_component)
	local action_settings = current_action_settings_from(weapon_action_component, weapon_template)
	local action_kind = action_settings and action_settings.kind

	return action_kind == "reload_state" or action_kind == "reload_shotgun"
end

local function is_alternate_fire_active(unit_data)
	if not unit_data then
		return false
	end

	local alternate_fire_component = unit_data:read_component("alternate_fire")

	if alternate_fire_component and alternate_fire_component.is_active ~= nil then
		if alternate_fire_component.is_active == true then
			cached_aiming = true
			last_aiming_t = gameplay_time()

			return true
		end

		cached_aiming = false
	end

	return cached_aiming or last_aiming_t > 0 and gameplay_time() - last_aiming_t <= AIM_GRACE_WINDOW
end

local function should_enable_auto_aim(unit)
	if not active or activation_mode == "disabled" or ui_using_input() then
		return false, not active and "mod disabled" or activation_mode == "disabled" and "activation disabled" or "UI using input"
	end

	if not is_local_player_unit(unit) then
		return false, "not local player"
	end

	local unit_data = unit_data_extension(unit)

	if not is_ranged_wielded(unit_data) then
		return false, "ranged weapon not wielded"
	end

	if is_reloading(unit_data) then
		return false, "reloading"
	end

	if activation_mode == "ranged" then
		return true
	end

	return is_alternate_fire_active(unit_data), "waiting for ADS"
end

local function target_node_position(unit)
	if not unit or not Unit.alive(unit) then
		return nil
	end

	local ok, has_node = pcall(Unit.has_node, unit, target_node)

	if not ok or not has_node then
		return POSITION_LOOKUP and POSITION_LOOKUP[unit] or nil
	end

	local position_ok, position = pcall(function()
		return Unit.world_position(unit, Unit.node(unit, target_node))
	end)

	return position_ok and position or POSITION_LOOKUP and POSITION_LOOKUP[unit] or nil
end

local function has_line_of_sight(smart_targeting_extension, ray_origin, target_position)
	local raycast_object = smart_targeting_extension and smart_targeting_extension._visibility_raycast_object

	if not raycast_object or not Raycast or not Raycast.cast then
		return false
	end

	local to_target = target_position - ray_origin
	local distance = Vector3.length(to_target)

	if distance <= 0 then
		return false
	end

	local hit = Raycast.cast(raycast_object, ray_origin, Vector3.normalize(to_target), distance)

	return not hit
end

local function breed_from_unit_data(unit_data_extension)
	if not unit_data_extension then
		return nil
	end

	if unit_data_extension.breed then
		return unit_data_extension:breed()
	end

	return unit_data_extension._breed
end

local function is_boss_breed(breed)
	local tags = breed and breed.tags

	return breed and (breed.is_boss or tags and (tags.monster or tags.captain or tags.cultist_captain))
end

local function is_witch_aggroed(unit)
	local game_session_manager = Managers and Managers.state and Managers.state.game_session
	local unit_spawner = Managers and Managers.state and Managers.state.unit_spawner
	local game_session = game_session_manager and game_session_manager:game_session()
	local game_object_id = nil

	if unit_spawner then
		local id_ok, id = pcall(unit_spawner.game_object_id, unit_spawner, unit)

		game_object_id = id_ok and id or nil
	end

	if not game_session or not game_object_id then
		return false
	end

	local ok, target_unit = pcall(MinionPerception.target_unit, game_session, game_object_id)

	return ok and target_unit ~= nil
end

local function is_passive_witch(unit, breed)
	return breed and breed.tags and breed.tags.witch and not is_witch_aggroed(unit)
end

local function breed_priority_key(unit, breed)
	if is_passive_witch(unit, breed) then
		return breed.name .. "_passive"
	end

	return breed and breed.name or nil
end

local function custom_breed_priority(unit, unit_data_extension)
	local breed = breed_from_unit_data(unit_data_extension)
	local breed_name = breed_priority_key(unit, breed)

	if not breed_name then
		return 0
	end

	return breed_priorities[breed_name] or DEFAULT_BREED_PRIORITIES[breed_name] or 0
end

local function custom_category_enabled(breed)
	local tags = breed and breed.tags

	if not breed then
		return false
	elseif is_boss_breed(breed) then
		return include_bosses
	elseif tags and tags.elite then
		return include_elites
	elseif tags and tags.special then
		return include_specialists
	end

	return include_regulars
end

local function target_priority_rank(unit, unit_data_extension)
	if priority_list == "custom" then
		return 5 - custom_breed_priority(unit, unit_data_extension)
	end

	if priority_list == "closest" then
		return 0
	end

	local breed = breed_from_unit_data(unit_data_extension)
	local tags = breed and breed.tags
	local breed_name = breed and breed.name
	local is_boss = is_boss_breed(breed)
	local is_immediate_threat = tags and tags.disabler or HIGH_PRIORITY_THREAT_BREEDS[breed_name] == true
	local is_area_threat = AREA_THREAT_BREEDS[breed_name] == true
	local is_shooter_threat = SHOOTER_THREAT_BREEDS[breed_name] == true

	if priority_list == "bosses" then
		if is_boss then
			return 0
		elseif is_immediate_threat then
			return 1
		elseif is_area_threat then
			return 2
		elseif tags and tags.special then
			return 3
		elseif tags and (tags.elite or tags.ogryn) then
			return 4
		end

		return 5
	end

	if priority_list == "specials" then
		if is_immediate_threat then
			return 0
		elseif is_area_threat then
			return 1
		elseif tags and tags.special then
			return 2
		elseif is_boss then
			return 3
		elseif tags and (tags.elite or tags.ogryn) then
			return 4
		end

		return 5
	end

	if is_immediate_threat then
		return 0
	elseif is_area_threat then
		return 1
	elseif is_boss then
		return 2
	elseif is_shooter_threat then
		return 3
	elseif tags and tags.special then
		return 4
	elseif tags and (tags.elite or tags.ogryn) then
		return 5
	end

	return 6
end

local function is_high_value_target(unit_data_extension)
	local breed = breed_from_unit_data(unit_data_extension)
	local tags = breed and breed.tags

	if breed and breed.is_boss then
		return true
	end

	if not tags then
		return false
	end

	return tags.special
		or tags.elite
		or tags.ogryn
		or tags.monster
		or tags.captain
		or tags.cultist_captain
end

local function custom_target_allowed(unit, unit_data_extension)
	local breed = breed_from_unit_data(unit_data_extension)

	if not custom_category_enabled(breed) then
		return false
	end

	return custom_breed_priority(unit, unit_data_extension) > 0
end

local function target_allowed(unit, unit_data_extension)
	local breed = breed_from_unit_data(unit_data_extension)

	if not breed or not is_targetable_enemy_breed(breed) then
		return false
	end

	if is_passive_witch(unit, breed) then
		return false
	end

	if target_filter ~= "all" and not is_high_value_target(unit_data_extension) then
		return false
	end

	if priority_list == "custom" then
		return custom_target_allowed(unit, unit_data_extension)
	end

	return true
end

local function retained_target_position(smart_targeting_extension, ray_origin, forward, max_angle, effective_target_range, aim_profile)
	if not retained_target_unit or gameplay_time() >= retained_target_until or not HEALTH_ALIVE[retained_target_unit] then
		clear_retained_target()

		return nil, nil
	end

	local unit_data = ScriptUnit.has_extension(retained_target_unit, "unit_data_system")

	if not unit_data or not target_allowed(retained_target_unit, unit_data) then
		clear_retained_target()

		return nil, nil
	end

	local target_position = target_node_position(retained_target_unit)

	if not target_position then
		clear_retained_target()

		return nil, nil
	end

	local to_target = target_position - ray_origin
	local distance = Vector3.length(to_target)
	local direction = distance > 0 and Vector3.normalize(to_target) or nil
	local dot = direction and Vector3.dot(forward, direction) or -1
	local retention_scale = aim_profile.retention_scale or 1

	if distance <= effective_target_range
		and dot >= math.cos(max_angle * math.max(1, 1.5 * retention_scale))
		and has_line_of_sight(smart_targeting_extension, ray_origin, target_position)
	then
		return retained_target_unit, target_position
	end

	clear_retained_target()

	return nil, nil
end

local function find_cone_target(smart_targeting_extension, raw_aim_rotation, optional_weapon_template, optional_weapon_action_component)
	local unit = smart_targeting_extension and smart_targeting_extension._unit
	local enabled, reason = should_enable_auto_aim(unit)

	diagnostic.targets = 0
	diagnostic.allowed = 0
	diagnostic.in_cone = 0
	diagnostic.visible = 0
	diagnostic.source = "none"
	diagnostic.search = reason or "searching"

	if not enabled then
		clear_retained_target()

		return nil
	end

	local first_person_component = smart_targeting_extension._first_person_component
	local ray_origin = first_person_component and first_person_component.position

	if not ray_origin or not raw_aim_rotation then
		diagnostic.search = "missing camera position or rotation"
		return nil
	end

	local extension_manager = Managers and Managers.state and Managers.state.extension
	local broadphase_system = extension_manager and extension_manager:has_system("broadphase_system") and extension_manager:system("broadphase_system")
	local side_system = extension_manager and extension_manager:has_system("side_system") and extension_manager:system("side_system")
	local broadphase = broadphase_system and broadphase_system.broadphase
	local side = side_system and side_system.side_by_unit[unit]
	local enemy_side_names = side and side:relation_side_names("enemy")

	if not side then
		diagnostic.search = "missing player side"
		return nil
	end

	table.clear(TARGET_RESULTS)

	local unit_data = unit_data_extension(unit)
	local weapon_template, action_settings, weapon_action_component = current_weapon_context(unit_data, optional_weapon_template, optional_weapon_action_component)
	local aim_profile = adaptive_aim_profile(weapon_template, action_settings, weapon_action_component)
	local effective_cone_angle = math.clamp(cone_angle * aim_profile.cone_scale, 1, 24)
	local effective_target_range = math.max(8, target_range * aim_profile.range_scale)
	local forward = Quaternion.forward(raw_aim_rotation)
	local max_angle = degrees_to_radians(effective_cone_angle)
	local retained_unit, retained_position = retained_target_position(smart_targeting_extension, ray_origin, forward, max_angle, effective_target_range, aim_profile)

	if retained_position and not threat_override then
		diagnostic.search = "retained target"
		return retained_position, aim_profile
	end

	-- Query by enemy side, then filter the selected aim point ourselves. The
	-- engine smart-targeting query can return no candidates despite visible enemies.
	local ok, num_targets = false, "spatial query unavailable"
	local target_results = TARGET_RESULTS

	if broadphase and enemy_side_names and Broadphase and Broadphase.query then
		ok, num_targets = pcall(Broadphase.query, broadphase, ray_origin, effective_target_range, TARGET_RESULTS, enemy_side_names)
	end

	diagnostic.source = "broadphase"

	-- Some sessions have an empty spatial query even with enemies present.
	-- The side registry is maintained independently and includes hostile units
	-- on clients as well as the server. Never mutate its shared array.
	if not ok or type(num_targets) ~= "number" or num_targets <= 0 then
		local enemy_units = side:relation_units("enemy")

		if enemy_units then
			target_results = enemy_units
			num_targets = #enemy_units
			ok = true
			diagnostic.source = "enemy registry"
		end
	end

	if not ok then
		diagnostic.search = "query failed: " .. tostring(num_targets)
		if not query_failure_reported then
			mod:error("Target search failed: %s", tostring(num_targets))
			query_failure_reported = true
		end

		return retained_position, aim_profile
	end

	if type(num_targets) ~= "number" or num_targets <= 0 then
		diagnostic.search = "query returned " .. tostring(num_targets)
		return retained_position, aim_profile
	end

	diagnostic.targets = num_targets
	diagnostic.search = "no eligible visible target"

	local best_position = retained_position
	local best_unit = retained_unit
	local best_score = math.huge
	local best_rank = math.huge
	local max_dot = math.cos(max_angle)

	if retained_unit and retained_position then
		local retained_unit_data = ScriptUnit.has_extension(retained_unit, "unit_data_system")
		local retained_to_target = retained_position - ray_origin
		local retained_distance = Vector3.length(retained_to_target)
		local retained_direction = retained_distance > 0 and Vector3.normalize(retained_to_target) or nil
		local retained_dot = retained_direction and Vector3.dot(forward, retained_direction) or -1

		if retained_dot >= max_dot and retained_unit_data then
			local retained_angle = math.acos(math.clamp(retained_dot, -1, 1))
			local retained_aim_score = (retained_angle / max_angle) * aim_profile.angle_weight
				+ (retained_distance / effective_target_range) * aim_profile.distance_weight

			best_rank = target_priority_rank(retained_unit, retained_unit_data)
			best_score = best_rank * 10 + retained_aim_score
		end
	end

	for i = 1, num_targets do
		local target_unit = target_results[i]

		if target_unit and target_unit ~= unit and HEALTH_ALIVE[target_unit] then
			local target_position = target_node_position(target_unit)
			local unit_data = ScriptUnit.has_extension(target_unit, "unit_data_system")

			if target_position and unit_data and target_allowed(target_unit, unit_data) then
				diagnostic.allowed = diagnostic.allowed + 1
				local to_target = target_position - ray_origin
				local distance = Vector3.length(to_target)
				local direction = distance > 0 and Vector3.normalize(to_target) or nil
				local dot = direction and Vector3.dot(forward, direction) or -1

				local in_range = distance >= 1 and distance <= effective_target_range

				if in_range and dot >= max_dot then
					diagnostic.in_cone = diagnostic.in_cone + 1
				end

				if in_range and dot >= max_dot and has_line_of_sight(smart_targeting_extension, ray_origin, target_position) then
					diagnostic.visible = diagnostic.visible + 1
					local angle = math.acos(math.clamp(dot, -1, 1))
					local aim_score = (angle / max_angle) * aim_profile.angle_weight
						+ (distance / effective_target_range) * aim_profile.distance_weight
					local rank = target_priority_rank(target_unit, unit_data)
					local score = rank * 10 + aim_score
					local holding_retained_target = best_unit == retained_unit and retained_unit ~= nil and retained_position ~= nil
					local should_replace = holding_retained_target
						and (rank < best_rank or rank == best_rank and score + TARGET_SWITCH_SCORE_MARGIN < best_score)
						or not holding_retained_target and score < best_score

					if should_replace then
						best_rank = rank
						best_score = score
						best_position = target_position
						best_unit = target_unit
					end
				end
			end
		end
	end

	if best_unit then
		diagnostic.search = "target selected"
		if best_unit ~= retained_target_unit then
			retained_target_until = gameplay_time() + TARGET_RETENTION_WINDOW * (aim_profile.retention_scale or 1)
		end

		retained_target_unit = best_unit
	end

	return best_position, aim_profile
end

mod:hook_require("scripts/extension_systems/buff/buff_extension_base", function(BuffExtensionBase)
	if skip_repeated_require_hook(BuffExtensionBase) then
		return
	end

	mod:hook(BuffExtensionBase, "has_keyword", function(func, self, keyword, ...)
		local has_keyword = func(self, keyword, ...)

		if has_keyword then
			return has_keyword
		end

		if keyword == AUTO_AIM_KEYWORD or keyword == "enable_auto_aim" then
			return (should_enable_auto_aim(self._unit))
		end

		return has_keyword
	end)
end)

mod:hook_require("scripts/extension_systems/smart_targeting/player_unit_smart_targeting_extension", function(PlayerUnitSmartTargetingExtension)
	if skip_repeated_require_hook(PlayerUnitSmartTargetingExtension) then
		return
	end

	mod:hook(PlayerUnitSmartTargetingExtension, "assisted_hitscan_trajectory", function(func, self, smart_targeting_template, weapon_template, raw_aim_rotation, optional_override_use_auto_aim, ...)
		local target_position = find_cone_target(self, raw_aim_rotation, weapon_template)

		if target_position then
			return Quaternion.look(target_position - self._first_person_component.position)
		end

		return func(self, smart_targeting_template, weapon_template, raw_aim_rotation, optional_override_use_auto_aim, ...)
	end)
end)

mod:hook_require("scripts/utilities/aim_assist", function(AimAssist)
	if skip_repeated_require_hook(AimAssist) then
		return
	end

	mod:hook(AimAssist, "apply_aim_assist", function(func, main_t, main_dt, input, targeting_data, aim_assist_ramp_component, weapon_action_component, look_yaw, look_pitch, position, combat_ability_action_component, grenade_ability_action_component, ...)
		diagnostic.camera_calls = diagnostic.camera_calls + 1
		local yaw, pitch = func(main_t, main_dt, input, targeting_data, aim_assist_ramp_component, weapon_action_component, look_yaw, look_pitch, position, combat_ability_action_component, grenade_ability_action_component, ...)
		local snap_speed = CAMERA_SNAP_SPEEDS[camera_snap] or 0

		if snap_speed == 0 then
			diagnostic.search = "camera snap off"
			return yaw, pitch
		end

		local smart_targeting_extension = local_smart_targeting_extension()
		local raw_aim_rotation = Quaternion.from_yaw_pitch_roll(yaw, pitch, 0)
		local target_position, aim_profile = find_cone_target(smart_targeting_extension, raw_aim_rotation, nil, weapon_action_component)

		if not target_position or not position then
			return yaw, pitch
		end

		local target_rotation = Quaternion.look(target_position - position, Vector3.up())
		local current_rotation = Quaternion.from_yaw_pitch_roll(yaw, pitch, 0)
		local snap_scale = aim_profile and aim_profile.snap_scale or 1
		local lerp_t = snap_speed < 0 and 1 or math.clamp(main_dt * snap_speed * snap_scale, 0, 1)
		local snapped_rotation = Quaternion.lerp(current_rotation, target_rotation, lerp_t)
		diagnostic.snaps = diagnostic.snaps + 1

		return Quaternion.yaw(snapped_rotation), Quaternion.pitch(snapped_rotation)
	end)
end)

mod:hook_require("scripts/utilities/alternate_fire", function(AlternateFire)
	if skip_repeated_require_hook(AlternateFire) then
		return
	end

	mod:hook_safe(AlternateFire, "start", function(_, _, _, _, _, _, _, _, _, _, _, _, _, player_unit)
		if is_local_player_unit(player_unit) then
			cached_aiming = true
			last_aiming_t = gameplay_time()
		end
	end)

	mod:hook_safe(AlternateFire, "stop", function(_, _, _, _, _, _, player_unit)
		if is_local_player_unit(player_unit) then
			cached_aiming = false
			last_aiming_t = gameplay_time()
		end
	end)
end)

mod:command("aimassist_status", "Report camera snap diagnostics after five seconds.", function()
	diagnostic.camera_calls = 0
	diagnostic.snaps = 0
	diagnostic.search = "not called"
	diagnostic.source = "none"
	diagnostic.targets = 0
	diagnostic.allowed = 0
	diagnostic.in_cone = 0
	diagnostic.visible = 0
	diagnostic_delay = 5
	mod:echo("Close chat and aim near an enabled enemy with a ranged weapon. Diagnostics in five seconds.")
end)

mod.update = function(dt)
	if not diagnostic_delay then
		return
	end

	diagnostic_delay = diagnostic_delay - dt

	if diagnostic_delay > 0 then
		return
	end

	diagnostic_delay = nil
	local enabled, reason = should_enable_auto_aim(local_player_unit())
	local message = string.format("Camera calls=%d, snaps=%d; activation=%s, camera=%s; search=%s; source=%s; candidates=%d, allowed=%d, in cone=%d, visible=%d",
		diagnostic.camera_calls, diagnostic.snaps, enabled and "ready" or reason, camera_snap,
		diagnostic.search, diagnostic.source, diagnostic.targets, diagnostic.allowed, diagnostic.in_cone, diagnostic.visible)
	mod:info("%s", message)
	mod:echo("%s", message)
end

mod.on_all_mods_loaded = refresh_settings
mod.on_enabled = function()
	active = true
	refresh_settings()
end
mod.on_disabled = function()
	active = false
	cached_aiming = false
	last_aiming_t = 0
	clear_retained_target()
end
mod.on_game_state_changed = function()
	diagnostic_delay = nil
	cached_aiming = false
	last_aiming_t = 0
	query_failure_reported = false
	clear_retained_target()
end
mod.on_setting_changed = function()
	refresh_settings()
end

refresh_settings()
