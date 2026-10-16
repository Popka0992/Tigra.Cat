local loadingTick = os.clock()

local playersService = cloneref(game:GetService("Players"))
local workspaceService = cloneref(game:GetService("Workspace"))
local runService = cloneref(game:GetService("RunService"))

local function httpGet(url)
	local response = request({
		Url = url,
		Method = "GET"
	})
	return response and response.Body or ""
end

local ESP_RAW_URL = "https://raw.githubusercontent.com/Popka0992/Tigra.Cat/refs/heads/main/esp.lua"
local WORLD_RAW_URL = "https://raw.githubusercontent.com/Popka0992/Tigra.Cat/refs/heads/main/WorldVisuals.lua"
local WORLD_ESP_RAW_URL = "https://raw.githubusercontent.com/Popka0992/Tigra.Cat/refs/heads/main/WorldESP.lua"
local COMBAT_RAW_URL = "https://raw.githubusercontent.com/Popka0992/Tigra.Cat/refs/heads/main/Combat.lua"
local MISC_RAW_URL = "https://raw.githubusercontent.com/Popka0992/Tigra.Cat/refs/heads/main/Misc.lua"
local UI_RAW_URL = "https://raw.githubusercontent.com/Popka0992/Tigra.Cat/refs/heads/main/ui.lua"

local function loadModule(url)
	local body = httpGet(url)
	if body == "" then
		return {}
	end
	local chunk = loadstring(body)
	if not chunk then
		return {}
	end
	local result = chunk()
	if typeof(result) == "table" and type(result.Load) == "function" then
		local loaded = result:Load()
		return loaded or result
	end
	return result
end

local function resolveConfig(mod)
	if typeof(mod) ~= "table" then
		return {}
	end
	if type(mod.GetConfig) == "function" then
		return mod:GetConfig()
	end
	return mod.Config or mod.Table or mod
end

local ESP = loadModule(ESP_RAW_URL)
local ESPConfig = resolveConfig(ESP)

local WorldVisuals = loadModule(WORLD_RAW_URL)
local WorldConfig = resolveConfig(WorldVisuals)

local WorldESP = loadModule(WORLD_ESP_RAW_URL)
local WorldESPConfig = resolveConfig(WorldESP)

local Combat = loadModule(COMBAT_RAW_URL)
local CombatConfig = resolveConfig(Combat)

local Misc = loadModule(MISC_RAW_URL)
local MiscConfig = resolveConfig(Misc)

local Library = loadstring(httpGet(UI_RAW_URL))()

local Window = Library:Window({
	Logo = "rbxassetid://124454910007637",
	Build = "developer"
})

local KeybindList = Library:KeybindList()
local Watermark = Library:Watermark("Tigra.Cat", "rbxassetid://124454910007637")

local function isKeyAssigned(keyObj)
	if not keyObj then
		return false
	end
	local val = keyObj.Value or keyObj.Key or keyObj.CurrentKey
	if typeof(val) == "table" then
		val = val.Key or val.Value or val[1]
	end
	if val == "None" or val == "Unknown" or val == Enum.KeyCode.Unknown or val == nil then
		return false
	end
	return true
end

do
	local Pages = {
		["Combat"] = Window:Page({Icon = "rbxassetid://91005239799306"}),
		["Visuals"] = Window:Page({Icon = "rbxassetid://131183993099134"}),
		["Misc"] = Window:Page({Icon = "rbxassetid://77101019021078"})
	}

	Library:CreateSettingsPage(Window, KeybindList, Watermark)

	do
		local SubPages = {
			["Silent Aim"] = Pages["Combat"]:SubPage({Name = "Silent Aim"}),
			["Weapon"] = Pages["Combat"]:SubPage({Name = "Weapon"})
		}

		do
			local SectionLeft = SubPages["Silent Aim"]:Section({Name = "General"})
			local SectionRight = SubPages["Silent Aim"]:Section({Name = "Targeting & FOV"})

			local SilentToggle = SectionLeft:Toggle({
				Name = "Enabled",
				Flag = "Silent_Enabled",
				Default = false,
				Callback = function(val)
					CombatConfig.Enabled = val
				end
			})

			local SilentKeybind
			SilentKeybind = SilentToggle:Keybind({
				Name = "Silent Aim",
				Flag = "Silent_Keybind",
				Default = "None",
				Mode = "Toggle",
				Callback = function(val)
					if not isKeyAssigned(SilentKeybind) then
						return
					end
					local state = if typeof(val) == "boolean" then val else not CombatConfig.Enabled
					if SilentToggle.Set then
						SilentToggle:Set(state)
					elseif SilentToggle.SetValue then
						SilentToggle:SetValue(state)
					end
					CombatConfig.Enabled = state
				end
			})

			SectionLeft:Dropdown({
				Name = "Hit Part",
				Flag = "Silent_HitPart",
				Multi = false,
				Items = {"Head", "HumanoidRootPart", "Torso", "Random"},
				Default = "Head",
				Callback = function(val)
					CombatConfig.HitPart = val
				end
			})

			SectionLeft:Slider({
				Name = "Hit Chance",
				Flag = "Silent_HitChance",
				Default = 100,
				Compact = false,
				Min = 0,
				Max = 100,
				Decimals = 1,
				Suffix = "%",
				Callback = function(val)
					CombatConfig.HitChance = val
				end
			})

			SectionLeft:Toggle({
				Name = "Prediction",
				Flag = "Silent_Prediction",
				Default = true,
				Callback = function(val)
					CombatConfig.Prediction = val
				end
			})

			SectionLeft:Toggle({
				Name = "Force Hit (Instant)",
				Flag = "Silent_ForceHit",
				Default = false,
				Callback = function(val)
					CombatConfig.InstantHit = val
				end
			})

			local HitscanToggle = SectionLeft:Toggle({
				Name = "Hitscan / Wallbang",
				Flag = "Silent_Hitscan",
				Default = false,
				Callback = function(val)
					CombatConfig.Hitscan = val
				end
			})

			HitscanToggle:Colorpicker({
				Flag = "Silent_HitscanColor",
				Default = Color3.fromRGB(255, 196, 0),
				Alpha = 0,
				Callback = function(val)
					CombatConfig.HitscanVisualColor = val
				end
			})

			SectionLeft:Slider({
				Name = "Hitscan Distance",
				Flag = "Silent_HitscanDistance",
				Default = 7,
				Compact = false,
				Min = 1,
				Max = 15,
				Decimals = 1,
				Suffix = " st",
				Callback = function(val)
					CombatConfig.HitscanDistance = val
				end
			})

			local ManipulatorToggle = SectionLeft:Toggle({
				Name = "Manipulator (Silent Peek)",
				Flag = "Silent_Manipulator",
				Default = false,
				Callback = function(val)
					CombatConfig.Manipulator = val
				end
			})

			ManipulatorToggle:Colorpicker({
				Flag = "Silent_ManipulatorColor",
				Default = Color3.fromRGB(0, 255, 170),
				Alpha = 0,
				Callback = function(val)
					CombatConfig.ManipulatorVisualColor = val
				end
			})

			SectionLeft:Slider({
				Name = "Manipulator Distance",
				Flag = "Silent_ManipulatorDistance",
				Default = 5,
				Compact = false,
				Min = 1,
				Max = 10,
				Decimals = 1,
				Suffix = " st",
				Callback = function(val)
					CombatConfig.ManipulatorDistance = val
				end
			})

			local SilentFovToggle = SectionRight:Toggle({
				Name = "Draw Field of View",
				Flag = "Silent_DrawFOV",
				Default = false,
				Callback = function(val)
					CombatConfig.ShowFOV = val
				end
			})

			SilentFovToggle:Colorpicker({
				Flag = "Silent_FOVColor",
				Default = Color3.fromRGB(170, 85, 255),
				Alpha = 0,
				Callback = function(val)
					CombatConfig.FOVColor = val
				end
			})

			SectionRight:Toggle({
				Name = "FOV Outline",
				Flag = "Silent_FOVOutline",
				Default = true,
				Callback = function(val)
					CombatConfig.FOVOutline = val
				end
			})

			SectionRight:Slider({
				Name = "FOV Radius",
				Flag = "Silent_Radius",
				Default = 120,
				Compact = false,
				Min = 10,
				Max = 600,
				Decimals = 1,
				Suffix = " px",
				Callback = function(val)
					CombatConfig.FOV = val
				end
			})

			SectionRight:Toggle({
				Name = "Target Players",
				Flag = "Silent_TargetPlayers",
				Default = true,
				Callback = function(val)
					CombatConfig.TargetPlayers = val
				end
			})

			SectionRight:Toggle({
				Name = "Target Bots",
				Flag = "Silent_TargetBots",
				Default = true,
				Callback = function(val)
					CombatConfig.TargetBots = val
				end
			})

			SectionRight:Toggle({
				Name = "Team Check",
				Flag = "Silent_TeamCheck",
				Default = false,
				Callback = function(val)
					CombatConfig.TeamCheck = val
				end
			})

			SectionRight:Toggle({
				Name = "Dead Check",
				Flag = "Silent_DeadCheck",
				Default = true,
				Callback = function(val)
					CombatConfig.DeadCheck = val
				end
			})

			SectionRight:Toggle({
				Name = "Distance Check",
				Flag = "Silent_DistCheck",
				Default = false,
				Callback = function(val)
					CombatConfig.DistCheck = val
				end
			})

			SectionRight:Slider({
				Name = "Max Distance",
				Flag = "Silent_MaxDist",
				Default = 1000,
				Compact = true,
				Min = 50,
				Max = 3000,
				Decimals = 1,
				Suffix = " st",
				Callback = function(val)
					CombatConfig.MaxDistance = val
				end
			})
		end

		do
			local SectionRecoil = SubPages["Weapon"]:Section({Name = "Recoil & Handling"})
			local SectionMods = SubPages["Weapon"]:Section({Name = "Modifications"})

			SectionRecoil:Slider({
				Name = "Recoil Percentage",
				Flag = "Wep_Recoil",
				Default = 100,
				Compact = false,
				Min = 0,
				Max = 100,
				Decimals = 1,
				Suffix = "%",
				Callback = function(val)
					CombatConfig.Recoil = val
				end
			})

			SectionRecoil:Slider({
				Name = "Spread Percentage",
				Flag = "Wep_Spread",
				Default = 100,
				Compact = false,
				Min = 0,
				Max = 100,
				Decimals = 1,
				Suffix = "%",
				Callback = function(val)
					CombatConfig.Spread = val
				end
			})

			SectionRecoil:Slider({
				Name = "Firerate Multiplier",
				Flag = "Wep_Firerate",
				Default = 1,
				Compact = false,
				Min = 1,
				Max = 5,
				Decimals = 1,
				Suffix = "x",
				Callback = function(val)
					CombatConfig.Firerate = val
				end
			})

			SectionMods:Toggle({
				Name = "No Pullout Delay",
				Flag = "Wep_InstantEquip",
				Default = false,
				Callback = function(val)
					CombatConfig.InstantEquip = val
				end
			})

			SectionMods:Toggle({
				Name = "Fast Bow",
				Flag = "Wep_FastBow",
				Default = false,
				Callback = function(val)
					CombatConfig.FastBow = val
				end
			})

			SectionMods:Toggle({
				Name = "Instant Eoka",
				Flag = "Wep_InstantEoka",
				Default = false,
				Callback = function(val)
					CombatConfig.InstantEoka = val
				end
			})

			SectionMods:Toggle({
				Name = "Shoot While Sprinting",
				Flag = "Wep_ShootSprinting",
				Default = false,
				Callback = function(val)
					CombatConfig.ShootSprinting = val
				end
			})

			SectionMods:Toggle({
				Name = "Reload While Sprinting",
				Flag = "Wep_ReloadSprinting",
				Default = false,
				Callback = function(val)
					CombatConfig.ReloadSprinting = val
				end
			})

			SectionMods:Toggle({
				Name = "Instant Reload",
				Flag = "Wep_InstantReload",
				Default = false,
				Callback = function(val)
					CombatConfig.InstantReload = val
				end
			})

			SectionMods:Toggle({
				Name = "Auto Reload",
				Flag = "Wep_AutoReload",
				Default = false,
				Callback = function(val)
					CombatConfig.AutoReload = val
				end
			})
		end
	end

	do
		local SubPages = {
			["Players"] = Pages["Visuals"]:SubPage({Name = "Players"}),
			["Entities"] = Pages["Visuals"]:SubPage({Name = "Entities"}),
			["Environment"] = Pages["Visuals"]:SubPage({Name = "Environment"})
		}

		do
			local SectionLeft = SubPages["Players"]:Section({Name = "Overlay & Boxes"})
			local SectionRight = SubPages["Players"]:Section({Name = "Rendering & Info"})

			local EspToggle = SectionLeft:Toggle({
				Name = "Master Enabled",
				Flag = "ESP_Master_Enabled",
				Default = ESPConfig.Enabled or false,
				Callback = function(val)
					ESPConfig.Enabled = val
				end
			})

			local EspKeybind
			EspKeybind = EspToggle:Keybind({
				Name = "Player ESP",
				Flag = "ESP_Master_Keybind",
				Default = "None",
				Mode = "Toggle",
				Callback = function(val)
					if not isKeyAssigned(EspKeybind) then
						return
					end
					local state = if typeof(val) == "boolean" then val else not ESPConfig.Enabled
					if EspToggle.Set then
						EspToggle:Set(state)
					elseif EspToggle.SetValue then
						EspToggle:SetValue(state)
					end
					ESPConfig.Enabled = state
				end
			})

			SectionLeft:Toggle({
				Name = "Show Bots",
				Flag = "ESP_ShowBots",
				Default = ESPConfig.Bots and ESPConfig.Bots.Enabled or false,
				Callback = function(val)
					if ESPConfig.Bots then
						ESPConfig.Bots.Enabled = val
					end
				end
			})

			local BoxToggle = SectionLeft:Toggle({
				Name = "Bounding Box",
				Flag = "ESP_Box",
				Default = ESPConfig.Boxes and ESPConfig.Boxes.Enabled or false,
				Callback = function(val)
					if ESPConfig.Boxes then
						ESPConfig.Boxes.Enabled = val
					end
				end
			})

			BoxToggle:Colorpicker({
				Flag = "ESP_BoxColor",
				Default = (ESPConfig.Boxes and ESPConfig.Boxes.Gradients and ESPConfig.Boxes.Gradients.Top) or Color3.fromRGB(255, 255, 255),
				Alpha = 0,
				Callback = function(val)
					if ESPConfig.Boxes and ESPConfig.Boxes.Gradients then
						ESPConfig.Boxes.Gradients.Top = val
						ESPConfig.Boxes.Gradients.Bot = val
					end
				end
			})

			SectionLeft:Toggle({
				Name = "Dynamic Bounding Box",
				Flag = "ESP_DynamicBox",
				Default = (ESPConfig.Boxes and ESPConfig.Boxes["Bounding Box"] and ESPConfig.Boxes["Bounding Box"].Enabled) or false,
				Callback = function(val)
					if ESPConfig.Boxes and ESPConfig.Boxes["Bounding Box"] then
						ESPConfig.Boxes["Bounding Box"].Enabled = val
					end
				end
			})

			SectionLeft:Toggle({
				Name = "Include Accessories",
				Flag = "ESP_IncludeAccs",
				Default = (ESPConfig.Boxes and ESPConfig.Boxes["Bounding Box"] and ESPConfig.Boxes["Bounding Box"].IncludeAccessories) or false,
				Callback = function(val)
					if ESPConfig.Boxes and ESPConfig.Boxes["Bounding Box"] then
						ESPConfig.Boxes["Bounding Box"].IncludeAccessories = val
					end
				end
			})

			local BoxGlowToggle = SectionLeft:Toggle({
				Name = "Box Glow",
				Flag = "ESP_BoxGlow",
				Default = (ESPConfig.Boxes and ESPConfig.Boxes["Box Glow"] and ESPConfig.Boxes["Box Glow"].Enabled) or false,
				Callback = function(val)
					if ESPConfig.Boxes and ESPConfig.Boxes["Box Glow"] then
						ESPConfig.Boxes["Box Glow"].Enabled = val
					end
				end
			})

			BoxGlowToggle:Colorpicker({
				Flag = "ESP_BoxGlowColor",
				Default = (ESPConfig.Boxes and ESPConfig.Boxes["Box Glow"] and ESPConfig.Boxes["Box Glow"].Top) or Color3.fromRGB(255, 255, 255),
				Alpha = (ESPConfig.Boxes and ESPConfig.Boxes["Box Glow"] and ESPConfig.Boxes["Box Glow"].Transparency and ESPConfig.Boxes["Box Glow"].Transparency[1]) or 0.85,
				Callback = function(val)
					if ESPConfig.Boxes and ESPConfig.Boxes["Box Glow"] then
						ESPConfig.Boxes["Box Glow"].Top = val
						ESPConfig.Boxes["Box Glow"].Bot = val
					end
				end
			})

			local BoxFillToggle = SectionLeft:Toggle({
				Name = "Box Fill",
				Flag = "ESP_BoxFill",
				Default = (ESPConfig.Boxes and ESPConfig.Boxes.Filled and ESPConfig.Boxes.Filled.Enabled) or false,
				Callback = function(val)
					if ESPConfig.Boxes and ESPConfig.Boxes.Filled then
						ESPConfig.Boxes.Filled.Enabled = val
					end
				end
			})

			BoxFillToggle:Colorpicker({
				Flag = "ESP_BoxFillColor",
				Default = (ESPConfig.Boxes and ESPConfig.Boxes.Filled and ESPConfig.Boxes.Filled.Top) or Color3.fromRGB(255, 255, 255),
				Alpha = (ESPConfig.Boxes and ESPConfig.Boxes.Filled and ESPConfig.Boxes.Filled.Transparency and ESPConfig.Boxes.Filled.Transparency[1]) or 0.85,
				Callback = function(val)
					if ESPConfig.Boxes and ESPConfig.Boxes.Filled then
						ESPConfig.Boxes.Filled.Top = val
						ESPConfig.Boxes.Filled.Bot = val
					end
				end
			})

			local HealthToggle = SectionRight:Toggle({
				Name = "Healthbar",
				Flag = "ESP_Health",
				Default = (ESPConfig.Bars and ESPConfig.Bars["Health Bar"] and ESPConfig.Bars["Health Bar"].Enabled) or false,
				Callback = function(val)
					if ESPConfig.Bars and ESPConfig.Bars["Health Bar"] then
						ESPConfig.Bars["Health Bar"].Enabled = val
					end
				end
			})

			HealthToggle:Colorpicker({
				Flag = "ESP_HealthColor",
				Default = (ESPConfig.Bars and ESPConfig.Bars["Health Bar"] and ESPConfig.Bars["Health Bar"].Color) or Color3.fromRGB(255, 255, 255),
				Alpha = 0,
				Callback = function(val)
					if ESPConfig.Bars and ESPConfig.Bars["Health Bar"] then
						ESPConfig.Bars["Health Bar"].Color = val
					end
				end
			})

			local NameToggle = SectionRight:Toggle({
				Name = "Show Name",
				Flag = "ESP_Name",
				Default = (ESPConfig.Texts and ESPConfig.Texts.Name and ESPConfig.Texts.Name.Enabled) or false,
				Callback = function(val)
					if ESPConfig.Texts and ESPConfig.Texts.Name then
						ESPConfig.Texts.Name.Enabled = val
					end
				end
			})

			NameToggle:Colorpicker({
				Flag = "ESP_NameColor",
				Default = (ESPConfig.Texts and ESPConfig.Texts.Name and ESPConfig.Texts.Name.Color) or Color3.fromRGB(255, 255, 255),
				Alpha = 0,
				Callback = function(val)
					if ESPConfig.Texts and ESPConfig.Texts.Name then
						ESPConfig.Texts.Name.Color = val
					end
				end
			})

			local DistToggle = SectionRight:Toggle({
				Name = "Show Distance",
				Flag = "ESP_Distance",
				Default = (ESPConfig.Texts and ESPConfig.Texts.Distance and ESPConfig.Texts.Distance.Enabled) or false,
				Callback = function(val)
					if ESPConfig.Texts and ESPConfig.Texts.Distance then
						ESPConfig.Texts.Distance.Enabled = val
					end
				end
			})

			DistToggle:Colorpicker({
				Flag = "ESP_DistColor",
				Default = (ESPConfig.Texts and ESPConfig.Texts.Distance and ESPConfig.Texts.Distance.Color) or Color3.fromRGB(200, 200, 200),
				Alpha = 0,
				Callback = function(val)
					if ESPConfig.Texts and ESPConfig.Texts.Distance then
						ESPConfig.Texts.Distance.Color = val
					end
				end
			})

			local WeaponToggle = SectionRight:Toggle({
				Name = "Show Weapon",
				Flag = "ESP_Weapon",
				Default = (ESPConfig.Texts and ESPConfig.Texts.Weapon and ESPConfig.Texts.Weapon.Enabled) or false,
				Callback = function(val)
					if ESPConfig.Texts and ESPConfig.Texts.Weapon then
						ESPConfig.Texts.Weapon.Enabled = val
					end
				end
			})

			WeaponToggle:Colorpicker({
				Flag = "ESP_WeaponColor",
				Default = (ESPConfig.Texts and ESPConfig.Texts.Weapon and ESPConfig.Texts.Weapon.Color) or Color3.fromRGB(255, 255, 255),
				Alpha = 0,
				Callback = function(val)
					if ESPConfig.Texts and ESPConfig.Texts.Weapon then
						ESPConfig.Texts.Weapon.Color = val
					end
				end
			})

			local StateToggle = SectionRight:Toggle({
				Name = "State Flags",
				Flag = "ESP_Flags",
				Default = (ESPConfig.Texts and ESPConfig.Texts.State and ESPConfig.Texts.State.Enabled) or false,
				Callback = function(val)
					if ESPConfig.Texts and ESPConfig.Texts.State then
						ESPConfig.Texts.State.Enabled = val
					end
				end
			})

			StateToggle:Colorpicker({
				Flag = "ESP_StateColor",
				Default = (ESPConfig.Texts and ESPConfig.Texts.State and ESPConfig.Texts.State.Color) or Color3.fromRGB(255, 255, 255),
				Alpha = 0,
				Callback = function(val)
					if ESPConfig.Texts and ESPConfig.Texts.State then
						ESPConfig.Texts.State.Color = val
					end
				end
			})
		end

		do
			local SectionLeft = SubPages["Entities"]:Section({Name = "Configuration"})
			local SectionRight = SubPages["Entities"]:Section({Name = "Entity Filters"})

			local WorldEspToggle = SectionLeft:Toggle({
				Name = "Master Enabled",
				Flag = "WorldESP_Master_Enabled",
				Default = false,
				Callback = function(val)
					WorldESPConfig.Enabled = val
				end
			})

			local WorldEspKeybind
			WorldEspKeybind = WorldEspToggle:Keybind({
				Name = "Entity ESP",
				Flag = "WorldESP_Master_Keybind",
				Default = "None",
				Mode = "Toggle",
				Callback = function(val)
					if not isKeyAssigned(WorldEspKeybind) then
						return
					end
					local state = if typeof(val) == "boolean" then val else not WorldESPConfig.Enabled
					if WorldEspToggle.Set then
						WorldEspToggle:Set(state)
					elseif WorldEspToggle.SetValue then
						WorldEspToggle:SetValue(state)
					end
					WorldESPConfig.Enabled = state
				end
			})

			SectionLeft:Toggle({
				Name = "Bounding Box",
				Flag = "WorldESP_Boxes",
				Default = false,
				Callback = function(val)
					WorldESPConfig.Boxes = val
				end
			})

			SectionLeft:Toggle({
				Name = "Show Name",
				Flag = "WorldESP_Names",
				Default = true,
				Callback = function(val)
					WorldESPConfig.Names = val
				end
			})

			SectionLeft:Toggle({
				Name = "Show Distance",
				Flag = "WorldESP_Distance",
				Default = true,
				Callback = function(val)
					WorldESPConfig.Distance = val
				end
			})

			SectionLeft:Slider({
				Name = "Render Distance",
				Flag = "WorldESP_MaxDist",
				Default = 1000,
				Compact = true,
				Min = 50,
				Max = 7500,
				Decimals = 1,
				Suffix = " st",
				Callback = function(val)
					WorldESPConfig.MaxDistance = val
				end
			})

			local function bindEntityFilter(name, flag, defaultColor)
				if not WorldESPConfig.Targets or not WorldESPConfig.Targets[name] then
					return
				end
				local filterToggle = SectionRight:Toggle({
					Name = name,
					Flag = flag,
					Default = false,
					Callback = function(val)
						WorldESPConfig.Targets[name].Enabled = val
					end
				})

				filterToggle:Colorpicker({
					Flag = flag .. "Color",
					Default = defaultColor,
					Alpha = 0,
					Callback = function(val)
						WorldESPConfig.Targets[name].Color = val
					end
				})
			end

			bindEntityFilter("ClothPlant", "WorldESP_Hemp", Color3.fromRGB(184, 184, 184))
			bindEntityFilter("Backpack", "WorldESP_BodyBag", Color3.fromRGB(255, 101, 40))
			bindEntityFilter("Brimstone Ore", "WorldESP_Brimstone", Color3.fromRGB(116, 103, 45))
			bindEntityFilter("Iron Ore", "WorldESP_Iron", Color3.fromRGB(168, 105, 21))
			bindEntityFilter("Stone Ore", "WorldESP_Stone", Color3.fromRGB(104, 104, 104))
		end

		do
			local SectionLeft = SubPages["Environment"]:Section({Name = "Lighting & Atmosphere"})
			local SectionRight = SubPages["Environment"]:Section({Name = "Skybox & Post-FX"})

			local function triggerWorldUpdate()
				if WorldVisuals and type(WorldVisuals.Update) == "function" then
					WorldVisuals:Update()
				end
			end

			SectionLeft:Toggle({
				Name = "Master Enabled",
				Flag = "World_Master_Enabled",
				Default = false,
				Callback = function(val)
					WorldConfig.Enabled = val
					triggerWorldUpdate()
				end
			})

			SectionLeft:Toggle({
				Name = "Time Changer",
				Flag = "World_TimeChangerToggle",
				Default = false,
				Callback = function(val)
					WorldConfig.TimeChanger = val
					triggerWorldUpdate()
				end
			})

			SectionLeft:Slider({
				Name = "Clock Time",
				Flag = "World_ClockTime",
				Default = tonumber(WorldConfig.ClockTime) or 14,
				Compact = false,
				Min = 0,
				Max = 24,
				Decimals = 1,
				Suffix = "h",
				Callback = function(val)
					WorldConfig.ClockTime = val
					triggerWorldUpdate()
				end
			})

			SectionLeft:Toggle({
				Name = "Brightness",
				Flag = "World_BrightnessToggle",
				Default = false,
				Callback = function(val)
					WorldConfig.Brightness = val
					triggerWorldUpdate()
				end
			})

			SectionLeft:Slider({
				Name = "Brightness Level",
				Flag = "World_BrightnessValue",
				Default = tonumber(WorldConfig.BrightnessValue) or 2,
				Compact = false,
				Min = 0,
				Max = 10,
				Decimals = 1,
				Suffix = "",
				Callback = function(val)
					WorldConfig.BrightnessValue = val
					triggerWorldUpdate()
				end
			})

			SectionLeft:Toggle({
				Name = "Exposure",
				Flag = "World_ExposureToggle",
				Default = false,
				Callback = function(val)
					WorldConfig.Exposure = val
					triggerWorldUpdate()
				end
			})

			SectionLeft:Slider({
				Name = "Exposure Level",
				Flag = "World_ExposureValue",
				Default = tonumber(WorldConfig.ExposureValue) or 0,
				Compact = false,
				Min = -3,
				Max = 3,
				Decimals = 1,
				Suffix = "",
				Callback = function(val)
					WorldConfig.ExposureValue = val
					triggerWorldUpdate()
				end
			})

			local AmbientToggle = SectionLeft:Toggle({
				Name = "Ambient",
				Flag = "World_AmbientToggle",
				Default = false,
				Callback = function(val)
					WorldConfig.Ambient = val
					triggerWorldUpdate()
				end
			})

			AmbientToggle:Colorpicker({
				Flag = "World_AmbientColor",
				Default = WorldConfig.AmbientColor or Color3.fromRGB(130, 130, 130),
				Alpha = 0,
				Callback = function(val)
					WorldConfig.AmbientColor = val
					triggerWorldUpdate()
				end
			})

			local OutdoorAmbientToggle = SectionLeft:Toggle({
				Name = "Outdoor Ambient",
				Flag = "World_OutdoorAmbientToggle",
				Default = false,
				Callback = function(val)
					WorldConfig.OutdoorAmbient = val
					triggerWorldUpdate()
				end
			})

			OutdoorAmbientToggle:Colorpicker({
				Flag = "World_OutdoorAmbientColor",
				Default = WorldConfig.OutdoorAmbientColor or Color3.fromRGB(130, 130, 130),
				Alpha = 0,
				Callback = function(val)
					WorldConfig.OutdoorAmbientColor = val
					triggerWorldUpdate()
				end
			})

			local AtmosphereToggle = SectionLeft:Toggle({
				Name = "Atmosphere",
				Flag = "World_AtmosphereToggle",
				Default = false,
				Callback = function(val)
					WorldConfig.Atmosphere = val
					triggerWorldUpdate()
				end
			})

			AtmosphereToggle:Colorpicker({
				Flag = "World_AtmosphereColor",
				Default = WorldConfig.AtmosphereColor or Color3.fromRGB(199, 199, 199),
				Alpha = 0,
				Callback = function(val)
					WorldConfig.AtmosphereColor = val
					triggerWorldUpdate()
				end
			})

			SectionLeft:Slider({
				Name = "Atmosphere Density",
				Flag = "World_AtmosphereDensity",
				Default = tonumber(WorldConfig.AtmosphereDensity) or 0.3,
				Compact = false,
				Min = 0,
				Max = 1,
				Decimals = 2,
				Suffix = "",
				Callback = function(val)
					WorldConfig.AtmosphereDensity = val
					triggerWorldUpdate()
				end
			})

			SectionLeft:Slider({
				Name = "Atmosphere Haze",
				Flag = "World_AtmosphereHaze",
				Default = tonumber(WorldConfig.AtmosphereHaze) or 0,
				Compact = false,
				Min = 0,
				Max = 10,
				Decimals = 1,
				Suffix = "",
				Callback = function(val)
					WorldConfig.AtmosphereHaze = val
					triggerWorldUpdate()
				end
			})

			SectionRight:Slider({
				Name = "Camera FOV",
				Flag = "World_CameraFOV",
				Default = 70,
				Compact = false,
				Min = 50,
				Max = 120,
				Decimals = 1,
				Suffix = "°",
				Callback = function(val)
					local camera = workspaceService.CurrentCamera
					if camera then
						camera.FieldOfView = val
					end
				end
			})

			SectionRight:Toggle({
				Name = "Sky Changer",
				Flag = "World_SkyChangerToggle",
				Default = false,
				Callback = function(val)
					WorldConfig.SkyChanger = val
					triggerWorldUpdate()
				end
			})

			SectionRight:Dropdown({
				Name = "Skybox",
				Flag = "World_SelectedSky",
				Multi = false,
				Items = {"default", "stormy", "blue space", "pink", "black storm", "realistic"},
				Default = WorldConfig.SelectedSky or "default",
				Callback = function(val)
					WorldConfig.SelectedSky = val
					triggerWorldUpdate()
				end
			})

			SectionRight:Toggle({
				Name = "No Clouds",
				Flag = "World_NoClouds",
				Default = false,
				Callback = function(val)
					WorldConfig.NoClouds = val
					triggerWorldUpdate()
				end
			})

			SectionRight:Toggle({
				Name = "No Sun Rays",
				Flag = "World_NoSunRays",
				Default = false,
				Callback = function(val)
					WorldConfig.NoSunRays = val
					triggerWorldUpdate()
				end
			})

			local FogToggle = SectionRight:Toggle({
				Name = "Fog Changer",
				Flag = "World_FogToggle",
				Default = false,
				Callback = function(val)
					WorldConfig.Fog = val
					triggerWorldUpdate()
				end
			})

			FogToggle:Colorpicker({
				Flag = "World_FogColor",
				Default = WorldConfig.FogColor or Color3.fromRGB(192, 192, 192),
				Alpha = 0,
				Callback = function(val)
					WorldConfig.FogColor = val
					triggerWorldUpdate()
				end
			})

			SectionRight:Slider({
				Name = "Fog Start",
				Flag = "World_FogStart",
				Default = tonumber(WorldConfig.FogStart) or 0,
				Compact = false,
				Min = 0,
				Max = 5000,
				Decimals = 1,
				Suffix = " st",
				Callback = function(val)
					WorldConfig.FogStart = val
					triggerWorldUpdate()
				end
			})

			SectionRight:Slider({
				Name = "Fog End",
				Flag = "World_FogEnd",
				Default = tonumber(WorldConfig.FogEnd) or 1000,
				Compact = false,
				Min = 0,
				Max = 10000,
				Decimals = 1,
				Suffix = " st",
				Callback = function(val)
					WorldConfig.FogEnd = val
					triggerWorldUpdate()
				end
			})

			local CcToggle = SectionRight:Toggle({
				Name = "Color Correction",
				Flag = "World_ColorCorrectionToggle",
				Default = false,
				Callback = function(val)
					WorldConfig.ColorCorrection = val
					triggerWorldUpdate()
				end
			})

			CcToggle:Colorpicker({
				Flag = "World_CCTint",
				Default = WorldConfig.Tint or Color3.fromRGB(255, 255, 255),
				Alpha = 0,
				Callback = function(val)
					WorldConfig.Tint = val
					triggerWorldUpdate()
				end
			})

			SectionRight:Slider({
				Name = "Saturation",
				Flag = "World_Saturation",
				Default = tonumber(WorldConfig.Saturation) or 0,
				Compact = false,
				Min = -2,
				Max = 2,
				Decimals = 1,
				Suffix = "",
				Callback = function(val)
					WorldConfig.Saturation = val
					triggerWorldUpdate()
				end
			})

			SectionRight:Slider({
				Name = "Contrast",
				Flag = "World_Contrast",
				Default = tonumber(WorldConfig.Contrast) or 0,
				Compact = false,
				Min = -2,
				Max = 2,
				Decimals = 1,
				Suffix = "",
				Callback = function(val)
					WorldConfig.Contrast = val
					triggerWorldUpdate()
				end
			})
		end
	end

	do
		local SubPages = {
			["Local Player"] = Pages["Misc"]:SubPage({Name = "Local Player"})
		}

		do
			local SectionMovement = SubPages["Local Player"]:Section({Name = "Movement"})
			local SectionExploits = SubPages["Local Player"]:Section({Name = "Character & Exploits"})

			local SpeedToggle = SectionMovement:Toggle({
				Name = "Speed Boost",
				Flag = "Move_SpeedToggle",
				Default = false,
				Callback = function(val)
					MiscConfig.SpeedEnabled = val
				end
			})

			local SpeedKeybind
			SpeedKeybind = SpeedToggle:Keybind({
				Name = "Speed Key",
				Flag = "Move_SpeedKey",
				Default = "None",
				Mode = "Hold",
				Callback = function(val)
					if not isKeyAssigned(SpeedKeybind) then
						return
					end
					local state = if typeof(val) == "boolean" then val else not MiscConfig.SpeedEnabled
					if SpeedToggle.Set then
						SpeedToggle:Set(state)
					elseif SpeedToggle.SetValue then
						SpeedToggle:SetValue(state)
					end
					MiscConfig.SpeedEnabled = state
				end
			})

			SectionMovement:Slider({
				Name = "Speed Value",
				Flag = "Move_SpeedValue",
				Default = 28,
				Compact = false,
				Min = 16,
				Max = 80,
				Decimals = 1,
				Suffix = " ws",
				Callback = function(val)
					MiscConfig.SpeedValue = val
				end
			})

			local FlyToggle = SectionMovement:Toggle({
				Name = "Fly",
				Flag = "Move_FlyToggle",
				Default = false,
				Callback = function(val)
					MiscConfig.FlyEnabled = val
				end
			})

			local FlyKeybind
			FlyKeybind = FlyToggle:Keybind({
				Name = "Fly Key",
				Flag = "Move_FlyKey",
				Default = "None",
				Mode = "Toggle",
				Callback = function(val)
					if not isKeyAssigned(FlyKeybind) then
						return
					end
					local state = if typeof(val) == "boolean" then val else not MiscConfig.FlyEnabled
					if FlyToggle.Set then
						FlyToggle:Set(state)
					elseif FlyToggle.SetValue then
						FlyToggle:SetValue(state)
					end
					MiscConfig.FlyEnabled = state
				end
			})

			SectionMovement:Dropdown({
				Name = "Fly Method",
				Flag = "Move_FlyMethod",
				Multi = false,
				Items = {"CFrame", "Velocity"},
				Default = "CFrame",
				Callback = function(val)
					MiscConfig.FlyMethod = val
				end
			})

			SectionMovement:Slider({
				Name = "Fly Speed",
				Flag = "Move_FlySpeed",
				Default = 40,
				Compact = false,
				Min = 10,
				Max = 150,
				Decimals = 1,
				Suffix = " studs",
				Callback = function(val)
					MiscConfig.FlySpeed = val
				end
			})

			SectionMovement:Toggle({
				Name = "Anti-Kick Timer",
				Flag = "Move_FlyTimerEnabled",
				Default = true,
				Callback = function(val)
					MiscConfig.FlyTimerEnabled = val
				end
			})

			SectionMovement:Slider({
				Name = "Timer Limit",
				Flag = "Move_FlyTimerDuration",
				Default = 3,
				Compact = false,
				Min = 1,
				Max = 6,
				Decimals = 1,
				Suffix = " s",
				Callback = function(val)
					MiscConfig.FlyTimerDuration = val
				end
			})

			SectionExploits:Toggle({
				Name = "Instant Loot",
				Flag = "Misc_InstantLoot",
				Default = false,
				Callback = function(val)
					MiscConfig.InstantLoot = val
				end
			})

			SectionExploits:Toggle({
				Name = "No Fall Damage",
				Flag = "Misc_NoFall",
				Default = false,
				Callback = function(val)
					MiscConfig.NoFall = val
				end
			})

			local ZoomToggle = SectionExploits:Toggle({
				Name = "Camera Zoom",
				Flag = "Misc_ZoomToggle",
				Default = false,
				Callback = function(val)
					MiscConfig.ZoomEnabled = val
				end
			})

			local ZoomKeybind
			ZoomKeybind = ZoomToggle:Keybind({
				Name = "Zoom Key",
				Flag = "Misc_ZoomKey",
				Default = "None",
				Mode = "Hold",
				Callback = function(val)
					if not isKeyAssigned(ZoomKeybind) then
						return
					end
					local state = if typeof(val) == "boolean" then val else not MiscConfig.ZoomEnabled
					if ZoomToggle.Set then
						ZoomToggle:Set(state)
					elseif ZoomToggle.SetValue then
						ZoomToggle:SetValue(state)
					end
					MiscConfig.ZoomEnabled = state
				end
			})

			SectionExploits:Slider({
				Name = "Zoom FOV",
				Flag = "Misc_ZoomFOV",
				Default = 25,
				Compact = false,
				Min = 5,
				Max = 60,
				Decimals = 1,
				Suffix = "°",
				Callback = function(val)
					MiscConfig.ZoomFOV = val
				end
			})

			local XRayToggle = SectionExploits:Toggle({
				Name = "X-Ray (Bases)",
				Flag = "Misc_XRayToggle",
				Default = false,
				Callback = function(val)
					if Misc and Misc.SetXRay then
						Misc:SetXRay(val)
					else
						MiscConfig.XRayEnabled = val
					end
				end
			})

			local XRayKeybind
			XRayKeybind = XRayToggle:Keybind({
				Name = "X-Ray Key",
				Flag = "Misc_XRayKey",
				Default = "None",
				Mode = "Toggle",
				Callback = function(val)
					if not isKeyAssigned(XRayKeybind) then
						return
					end
					local state = if typeof(val) == "boolean" then val else not MiscConfig.XRayEnabled
					if XRayToggle.Set then
						XRayToggle:Set(state)
					elseif XRayToggle.SetValue then
						XRayToggle:SetValue(state)
					end
					if Misc and Misc.SetXRay then
						Misc:SetXRay(state)
					else
						MiscConfig.XRayEnabled = state
					end
				end
			})

			SectionExploits:Slider({
				Name = "X-Ray Transparency",
				Flag = "Misc_XRayTransparency",
				Default = 100,
				Compact = false,
				Min = 1,
				Max = 100,
				Decimals = 1,
				Suffix = "%",
				Callback = function(val)
					if Misc and Misc.SetXRayTransparency then
						Misc:SetXRayTransparency(val / 100)
					else
						MiscConfig.XRayTransparency = val / 100
					end
				end
			})
		end
	end
end

Library:Notification("Loaded in " .. stringFormat("%.4f", os.clock() - loadingTick) .. " seconds", 5, Library.Theme.Accent)
