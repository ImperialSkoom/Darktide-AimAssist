# Aim Assist

Aim Assist is a Warhammer 40,000: Darktide mod for the Darktide Mod Framework. It provides configurable aim assistance for ranged weapons and includes:

* ADS-only or always-while-ranged activation modes
* Adjustable assist cone and target range
* Adaptive handling profiles for spread, projectile, charged, precision, and recoil-heavy weapons
* Optional camera snap with soft, strong, instant, and disabled modes
* Head or torso aim-point selection
* Target filters for high-value enemies or all enemies
* Built-in priority presets for threats, bosses, specialists, or targets closest to the crosshair
* Custom per-breed priority settings for every targetable hostile enemy type in the current game data
* Target retention with higher-priority and better-aligned target overrides
* Passive Daemonhost and line-of-sight protection

Regular enemies are included in the custom priority list but disabled by default. To target them, set `Target Filter` to `All enemies` and enable `Regular Enemies` under `Custom Target Priorities`.

Target discovery uses the game's enemy-side broadphase query, falling back to the side system's enemy-unit registry if the spatial query is empty or unavailable. Aim-point range, cone, and line-of-sight checks are performed by the mod. All returned candidates are considered before priority ranking, so nearby ignored enemies cannot fill a 32-result shortlist and hide a higher-priority enemy.

For diagnostics, run `/aimassist_status`, close chat, and aim near an enabled enemy with a ranged weapon for five seconds. The result is shown in chat and saved to the console log. The source identifies the spatial query or enemy registry. Candidate counts precede range, cone, and visibility filtering; registry candidates can include distant enemies.

## Install

1. Extract `AimAssist` into your Darktide `mods` directory.
2. Add `AimAssist` to `mod_load_order.txt`.
3. Launch with DMF enabled.

## Files

```text
AimAssist/
  .gitignore
  AimAssist.mod
  README.md
  scripts/
    mods/
      AimAssist/
        AimAssist.lua
        AimAssist_data.lua
        AimAssist_localization.lua
```
