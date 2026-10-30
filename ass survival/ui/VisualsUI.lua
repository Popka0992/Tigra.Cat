return function(ctx)
	local VisualsPage = ctx.VisualsPage
	local espConfig = ctx.espConfig
	local EspInstance = ctx.EspInstance
	local worldConfig = ctx.worldConfig
	local WorldVisuals = ctx.WorldVisuals
	local validPickups = ctx.validPickups
	local isPickupAllowed = ctx.isPickupAllowed
	local Library = ctx.Library

	local SubPages = {
		["ESP"] = VisualsPage:SubPage({
			Name = "Player ESP",
		}),
		["Bots"] = VisualsPage:SubPage({
			Name = "Bot ESP",
		}),
		["WorldESP"] = VisualsPage:SubPage({
			Name = "World ESP",
		}),
		["WorldVisuals"] = VisualsPage:SubPage({
			Name = "Environment",
		}),
	}

	-- PLAYER ESP
	do
		local SectionGeneral = SubPages["ESP"]:Section({
			Name = "General - Bounds",
			Side = "Left",
		})

		local SectionOverlays = SubPages["ESP"]:Section({
			Name = "Overlays - Colors",
			Side = "Right",
		})

		SectionGeneral:Toggle({
			Name = "Enabled ESP",
			Default = espConfig.Enabled,
			Flag = "Esp_Enabled",
			Callback = function(value)
				espConfig.Enabled = value
			end,
		})

		SectionGeneral:Toggle({
			Name = "Players",
			Default = espConfig.Players,
			Flag = "Esp_Players",
			Callback = function(value)
				espConfig.Players = value
			end,
		})

		SectionGeneral:Slider({
			Name = "Framerate Limit",
			Min = 0,
			Max = 144,
			Default = espConfig.LimitFPS,
			Flag = "Esp_LimitFPS",
			Callback = function(value)
				espConfig.LimitFPS = value
			end,
		})

		local boundsToggle = SectionGeneral:Toggle({
			Name = "Bounds",
			Default = espConfig.Boxes.Enabled,
			Flag = "Esp_Boxes_Enabled",
			Callback = function(value)
				espConfig.Boxes.Enabled = value
			end,
		})

		boundsToggle:Colorpicker({
			Name = "Top Color",
			Default = espConfig.Boxes.GradTop,
			Flag = "Esp_Box_GradTop",
			Callback = function(value)
				espConfig.Boxes.GradTop = value
			end,
		})

		boundsToggle:Colorpicker({
			Name = "Bottom Color",
			Default = espConfig.Boxes.GradBot,
			Flag = "Esp_Box_GradBot",
			Callback = function(value)
				espConfig.Boxes.GradBot = value
			end,
		})

		SectionGeneral:Toggle({
			Name = "Dynamic Bounds",
			Default = espConfig.Bounding.Enabled,
			Flag = "Esp_Bounding_Enabled",
			Callback = function(value)
				espConfig.Bounding.Enabled = value
			end,
		})

		SectionGeneral:Toggle({
			Name = "Include Accessories",
			Default = espConfig.Bounding.Accessories,
			Flag = "Esp_Bounding_Accessories",
			Callback = function(value)
				espConfig.Bounding.Accessories = value
			end,
		})

		SectionGeneral:Slider({
			Name = "Padding X",
			Min = 0,
			Max = 30,
			Suffix = "px",
			Default = espConfig.Bounding.BoxX,
			Flag = "Esp_Bounding_BoxX",
			Callback = function(value)
				espConfig.Bounding.BoxX = value
			end,
		})

		SectionGeneral:Slider({
			Name = "Padding Y",
			Min = 0,
			Max = 30,
			Suffix = "px",
			Default = espConfig.Bounding.BoxY,
			Flag = "Esp_Bounding_BoxY",
			Callback = function(value)
				espConfig.Bounding.BoxY = value
			end,
		})

		local glowToggle = SectionGeneral:Toggle({
			Name = "Glow",
			Default = espConfig.Glow.Enabled,
			Flag = "Esp_Glow_Enabled",
			Callback = function(value)
				espConfig.Glow.Enabled = value
			end,
		})

		glowToggle:Colorpicker({
			Name = "Glow Top",
			Default = espConfig.Glow.Top,
			Flag = "Esp_Glow_Top",
			Callback = function(value)
				espConfig.Glow.Top = value
			end,
		})

		glowToggle:Colorpicker({
			Name = "Glow Bottom",
			Default = espConfig.Glow.Bot,
			Flag = "Esp_Glow_Bot",
			Callback = function(value)
				espConfig.Glow.Bot = value
			end,
		})

		SectionGeneral:Slider({
			Name = "Glow Alpha",
			Min = 0,
			Max = 100,
			Suffix = "%",
			Default = espConfig.Glow.Trans,
			Flag = "Esp_Glow_Trans",
			Callback = function(value)
				espConfig.Glow.Trans = value
			end,
		})

		local fillToggle = SectionGeneral:Toggle({
			Name = "Fill",
			Default = espConfig.Fill.Enabled,
			Flag = "Esp_Fill_Enabled",
			Callback = function(value)
				espConfig.Fill.Enabled = value
			end,
		})

		fillToggle:Colorpicker({
			Name = "Fill Top",
			Default = espConfig.Fill.Top,
			Flag = "Esp_Fill_Top",
			Callback = function(value)
				espConfig.Fill.Top = value
			end,
		})

		fillToggle:Colorpicker({
			Name = "Fill Bottom",
			Default = espConfig.Fill.Bot,
			Flag = "Esp_Fill_Bot",
			Callback = function(value)
				espConfig.Fill.Bot = value
			end,
		})

		SectionGeneral:Slider({
			Name = "Fill Alpha",
			Min = 0,
			Max = 100,
			Suffix = "%",
			Default = espConfig.Fill.Trans,
			Flag = "Esp_Fill_Trans",
			Callback = function(value)
				espConfig.Fill.Trans = value
			end,
		})

		local healthToggle = SectionOverlays:Toggle({
			Name = "Health Bar",
			Default = espConfig.Bars.Health.Enabled,
			Flag = "Esp_HealthBar_Enabled",
			Callback = function(value)
				espConfig.Bars.Health.Enabled = value
			end,
		})

		healthToggle:Colorpicker({
			Name = "Health Bar",
			Default = espConfig.Bars.Health.Color,
			Flag = "Esp_HealthBar_Color",
			Callback = function(value)
				espConfig.Bars.Health.Color = value
			end,
		})

		local nameToggle = SectionOverlays:Toggle({
			Name = "Name",
			Default = espConfig.Texts.Name.Enabled,
			Flag = "Esp_Name_Enabled",
			Callback = function(value)
				espConfig.Texts.Name.Enabled = value
			end,
		})

		nameToggle:Colorpicker({
			Name = "Name",
			Default = espConfig.Texts.Name.Color,
			Flag = "Esp_Name_Color",
			Callback = function(value)
				espConfig.Texts.Name.Color = value
			end,
		})

		local distToggle = SectionOverlays:Toggle({
			Name = "Distance",
			Default = espConfig.Texts.Distance.Enabled,
			Flag = "Esp_Dist_Enabled",
			Callback = function(value)
				espConfig.Texts.Distance.Enabled = value
			end,
		})

		distToggle:Colorpicker({
			Name = "Distance",
			Default = espConfig.Texts.Distance.Color,
			Flag = "Esp_Dist_Color",
			Callback = function(value)
				espConfig.Texts.Distance.Color = value
			end,
		})

		local weaponToggle = SectionOverlays:Toggle({
			Name = "Weapon",
			Default = espConfig.Texts.Weapon.Enabled,
			Flag = "Esp_Weapon_Enabled",
			Callback = function(value)
				espConfig.Texts.Weapon.Enabled = value
			end,
		})

		weaponToggle:Colorpicker({
			Name = "Weapon",
			Default = espConfig.Texts.Weapon.Color,
			Flag = "Esp_Weapon_Color",
			Callback = function(value)
				espConfig.Texts.Weapon.Color = value
			end,
		})

		SectionOverlays:Toggle({
			Name = "Weapon Icon",
			Default = espConfig.WeaponIcon.Enabled,
			Flag = "Esp_WeaponIcon_Enabled",
			Callback = function(value)
				espConfig.WeaponIcon.Enabled = value
			end,
		})

		SectionOverlays:Slider({
			Name = "Icon Scale",
			Min = 12,
			Max = 48,
			Suffix = "px",
			Default = espConfig.WeaponIcon.Size,
			Flag = "Esp_WeaponIcon_Size",
			Callback = function(value)
				espConfig.WeaponIcon.Size = value
			end,
		})

		local flagsToggle = SectionOverlays:Toggle({
			Name = "Flags",
			Default = espConfig.Texts.State.Enabled,
			Flag = "Esp_State_Enabled",
			Callback = function(value)
				espConfig.Texts.State.Enabled = value
			end,
		})

		flagsToggle:Colorpicker({
			Name = "Flags",
			Default = espConfig.Texts.State.Color,
			Flag = "Esp_State_Color",
			Callback = function(value)
				espConfig.Texts.State.Color = value
			end,
		})

		SectionOverlays:Button({
			Name = "Unload ESP",
			Callback = function()
				EspInstance:Unload()
				Library:Notification("Visuals safely unloaded.", 3, Library.Theme.Accent)
			end,
		})
	end

	-- BOT ESP
	do
		local botBoxes = espConfig.Bots.Boxes
		local botBoundingBox = botBoxes["Bounding Box"]
		local botGlow = botBoxes["Box Glow"]
		local botFill = botBoxes.Filled
		local botBars = espConfig.Bots.Bars
		local botTexts = espConfig.Bots.Texts

		local SectionGeneral = SubPages["Bots"]:Section({
			Name = "General - Bounds",
			Side = "Left",
		})

		local SectionOverlays = SubPages["Bots"]:Section({
			Name = "Overlays - Colors",
			Side = "Right",
		})

		SectionGeneral:Toggle({
			Name = "Enabled Bots",
			Default = espConfig.Bots.Enabled,
			Flag = "Esp_Bot_Enabled",
			Callback = function(value)
				espConfig.Bots.Enabled = value
			end,
		})

		SectionGeneral:Toggle({
			Name = "Custom Colors",
			Default = espConfig.Bots.CustomColors,
			Flag = "Esp_Bot_CustomColors",
			Callback = function(value)
				espConfig.Bots.CustomColors = value
			end,
		})

		local boundsToggle = SectionGeneral:Toggle({
			Name = "Bounds",
			Default = botBoundingBox.Enabled,
			Flag = "Esp_Bot_Boxes_Enabled",
			Callback = function(value)
				botBoundingBox.Enabled = value
			end,
		})

		boundsToggle:Colorpicker({
			Name = "Top Color",
			Default = botBoundingBox.GradTop,
			Flag = "Esp_Bot_Box_GradTop",
			Callback = function(value)
				botBoundingBox.GradTop = value
			end,
		})

		boundsToggle:Colorpicker({
			Name = "Bottom Color",
			Default = botBoundingBox.GradBot,
			Flag = "Esp_Bot_Box_GradBot",
			Callback = function(value)
				botBoundingBox.GradBot = value
			end,
		})

		SectionGeneral:Toggle({
			Name = "Dynamic Bounds",
			Default = espConfig.Bots.Bounding.Enabled,
			Flag = "Esp_Bot_Bounding_Enabled",
			Callback = function(value)
				espConfig.Bots.Bounding.Enabled = value
			end,
		})

		SectionGeneral:Toggle({
			Name = "Include Accessories",
			Default = espConfig.Bots.Bounding.Accessories,
			Flag = "Esp_Bot_Bounding_Accessories",
			Callback = function(value)
				espConfig.Bots.Bounding.Accessories = value
			end,
		})

		SectionGeneral:Slider({
			Name = "Padding X",
			Min = 0,
			Max = 30,
			Suffix = "px",
			Default = espConfig.Bots.Bounding.BoxX,
			Flag = "Esp_Bot_Bounding_BoxX",
			Callback = function(value)
				espConfig.Bots.Bounding.BoxX = value
			end,
		})

		SectionGeneral:Slider({
			Name = "Padding Y",
			Min = 0,
			Max = 30,
			Suffix = "px",
			Default = espConfig.Bots.Bounding.BoxY,
			Flag = "Esp_Bot_Bounding_BoxY",
			Callback = function(value)
				espConfig.Bots.Bounding.BoxY = value
			end,
		})

		local glowToggle = SectionGeneral:Toggle({
			Name = "Glow",
			Default = botGlow.Enabled,
			Flag = "Esp_Bot_Glow_Enabled",
			Callback = function(value)
				botGlow.Enabled = value
			end,
		})

		glowToggle:Colorpicker({
			Name = "Glow Top",
			Default = botGlow.Top,
			Flag = "Esp_Bot_Glow_Top",
			Callback = function(value)
				botGlow.Top = value
			end,
		})

		glowToggle:Colorpicker({
			Name = "Glow Bottom",
			Default = botGlow.Bot,
			Flag = "Esp_Bot_Glow_Bot",
			Callback = function(value)
				botGlow.Bot = value
			end,
		})

		SectionGeneral:Slider({
			Name = "Glow Alpha",
			Min = 0,
			Max = 100,
			Suffix = "%",
			Default = botGlow.Trans,
			Flag = "Esp_Bot_Glow_Trans",
			Callback = function(value)
				botGlow.Trans = value
			end,
		})

		local fillToggle = SectionGeneral:Toggle({
			Name = "Fill",
			Default = botFill.Enabled,
			Flag = "Esp_Bot_Fill_Enabled",
			Callback = function(value)
				botFill.Enabled = value
			end,
		})

		fillToggle:Colorpicker({
			Name = "Fill Top",
			Default = botFill.Top,
			Flag = "Esp_Bot_Fill_Top",
			Callback = function(value)
				botFill.Top = value
			end,
		})

		fillToggle:Colorpicker({
			Name = "Fill Bottom",
			Default = botFill.Bot,
			Flag = "Esp_Bot_Fill_Bot",
			Callback = function(value)
				botFill.Bot = value
			end,
		})

		SectionGeneral:Slider({
			Name = "Fill Alpha",
			Min = 0,
			Max = 100,
			Suffix = "%",
			Default = botFill.Trans,
			Flag = "Esp_Bot_Fill_Trans",
			Callback = function(value)
				botFill.Trans = value
			end,
		})

		local healthToggle = SectionOverlays:Toggle({
			Name = "Health Bar",
			Default = botBars.Health.Enabled,
			Flag = "Esp_Bot_HealthBar_Enabled",
			Callback = function(value)
				botBars.Health.Enabled = value
			end,
		})

		healthToggle:Colorpicker({
			Name = "Health Bar",
			Default = botBars.Health.Color,
			Flag = "Esp_Bot_HealthBar_Color",
			Callback = function(value)
				botBars.Health.Color = value
			end,
		})

		local nameToggle = SectionOverlays:Toggle({
			Name = "Name",
			Default = botTexts.Name.Enabled,
			Flag = "Esp_Bot_Name_Enabled",
			Callback = function(value)
				botTexts.Name.Enabled = value
			end,
		})

		nameToggle:Colorpicker({
			Name = "Name",
			Default = botTexts.Name.Color,
			Flag = "Esp_Bot_Name_Color",
			Callback = function(value)
				botTexts.Name.Color = value
			end,
		})

		local distToggle = SectionOverlays:Toggle({
			Name = "Distance",
			Default = botTexts.Distance.Enabled,
			Flag = "Esp_Bot_Dist_Enabled",
			Callback = function(value)
				botTexts.Distance.Enabled = value
			end,
		})

		distToggle:Colorpicker({
			Name = "Distance",
			Default = botTexts.Distance.Color,
			Flag = "Esp_Bot_Dist_Color",
			Callback = function(value)
				botTexts.Distance.Color = value
			end,
		})

		local weaponToggle = SectionOverlays:Toggle({
			Name = "Weapon",
			Default = botTexts.Weapon.Enabled,
			Flag = "Esp_Bot_Weapon_Enabled",
			Callback = function(value)
				botTexts.Weapon.Enabled = value
			end,
		})

		weaponToggle:Colorpicker({
			Name = "Weapon",
			Default = botTexts.Weapon.Color,
			Flag = "Esp_Bot_Weapon_Color",
			Callback = function(value)
				botTexts.Weapon.Color = value
			end,
		})

		SectionOverlays:Toggle({
			Name = "Weapon Icon",
			Default = botTexts.WeaponIcon.Enabled,
			Flag = "Esp_Bot_WeaponIcon_Enabled",
			Callback = function(value)
				botTexts.WeaponIcon.Enabled = value
			end,
		})

		SectionOverlays:Slider({
			Name = "Icon Scale",
			Min = 12,
			Max = 48,
			Suffix = "px",
			Default = botTexts.WeaponIcon.Size,
			Flag = "Esp_Bot_WeaponIcon_Size",
			Callback = function(value)
				botTexts.WeaponIcon.Size = value
			end,
		})

		local flagsToggle = SectionOverlays:Toggle({
			Name = "Flags",
			Default = botTexts.State.Enabled,
			Flag = "Esp_Bot_State_Enabled",
			Callback = function(value)
				botTexts.State.Enabled = value
			end,
		})

		flagsToggle:Colorpicker({
			Name = "Flags",
			Default = botTexts.State.Color,
			Flag = "Esp_Bot_State_Color",
			Callback = function(value)
				botTexts.State.Color = value
			end,
		})
	end

	-- WORLD ESP (Ores / Pickups / Animals)
	do
		local oreConfig = espConfig.Ores
		local pickupConfig = espConfig.Pickups
		local animalConfig = espConfig.Animals

		local SectionOres = SubPages["WorldESP"]:Section({
			Name = "Ores",
			Side = "Left",
		})

		local SectionLife = SubPages["WorldESP"]:Section({
			Name = "Pickups - Animals",
			Side = "Right",
		})

		SectionOres:Toggle({
			Name = "Enabled Ores ESP",
			Default = oreConfig.Enabled,
			Flag = "Esp_Ore_Enabled",
			Callback = function(value)
				oreConfig.Enabled = value
			end,
		})

		SectionOres:Toggle({
			Name = "Show Distance",
			Default = oreConfig.ShowDistance,
			Flag = "Esp_Ore_ShowDistance",
			Callback = function(value)
				oreConfig.ShowDistance = value
			end,
		})

		SectionOres:Slider({
			Name = "Max Distance",
			Min = 100,
			Max = 5000,
			Suffix = "st",
			Default = oreConfig.MaxDistance,
			Flag = "Esp_Ore_MaxDistance",
			Callback = function(value)
				oreConfig.MaxDistance = value
			end,
		})

		local stoneToggle = SectionOres:Toggle({
			Name = "Stone Nodes",
			Default = oreConfig.Stone.Enabled,
			Flag = "Esp_Ore_Stone_Enabled",
			Callback = function(value)
				oreConfig.Stone.Enabled = value
			end,
		})

		stoneToggle:Colorpicker({
			Name = "Stone Nodes",
			Default = oreConfig.Stone.Color,
			Flag = "Esp_Ore_Stone_Color",
			Callback = function(value)
				if typeof(value) == "Color3" then
					oreConfig.Stone.Color = value
				end
			end,
		})

		local sulfurToggle = SectionOres:Toggle({
			Name = "Sulfur Nodes",
			Default = oreConfig.Sulfur.Enabled,
			Flag = "Esp_Ore_Sulfur_Enabled",
			Callback = function(value)
				oreConfig.Sulfur.Enabled = value
			end,
		})

		sulfurToggle:Colorpicker({
			Name = "Sulfur Nodes",
			Default = oreConfig.Sulfur.Color,
			Flag = "Esp_Ore_Sulfur_Color",
			Callback = function(value)
				if typeof(value) == "Color3" then
					oreConfig.Sulfur.Color = value
				end
			end,
		})

		local metalToggle = SectionOres:Toggle({
			Name = "Metal Nodes",
			Default = oreConfig.Metal.Enabled,
			Flag = "Esp_Ore_Metal_Enabled",
			Callback = function(value)
				oreConfig.Metal.Enabled = value
			end,
		})

		metalToggle:Colorpicker({
			Name = "Metal Nodes",
			Default = oreConfig.Metal.Color,
			Flag = "Esp_Ore_Metal_Color",
			Callback = function(value)
				if typeof(value) == "Color3" then
					oreConfig.Metal.Color = value
				end
			end,
		})

		local pickupToggle = SectionLife:Toggle({
			Name = "Enabled Pickups ESP",
			Default = pickupConfig.Enabled,
			Flag = "Esp_Pickup_Enabled",
			Callback = function(value)
				pickupConfig.Enabled = value
			end,
		})

		pickupToggle:Colorpicker({
			Name = "Pickups Color",
			Default = pickupConfig.Color,
			Flag = "Esp_Pickup_Color",
			Callback = function(value)
				pickupConfig.Color = value
			end,
		})

		SectionLife:Toggle({
			Name = "Show Pickups Distance",
			Default = pickupConfig.ShowDistance,
			Flag = "Esp_Pickup_ShowDistance",
			Callback = function(value)
				pickupConfig.ShowDistance = value
			end,
		})

		SectionLife:Slider({
			Name = "Pickups Max Distance",
			Min = 50,
			Max = 2000,
			Suffix = "st",
			Default = pickupConfig.MaxDistance,
			Flag = "Esp_Pickup_MaxDistance",
			Callback = function(value)
				pickupConfig.MaxDistance = value
			end,
		})

		SectionLife:Dropdown({
			Name = "Pickups Whitelist",
			Multi = true,
			Items = validPickups,
			Default = {},
			Flag = "Esp_Pickup_Whitelist",
			Callback = function(value)
				espConfig.Pickups.Whitelist = value

				for _, pickup in pairs(workspace:GetDescendants()) do
					if pickup:GetAttribute("EspPickupLabel") then
						pickup.Visible = isPickupAllowed(pickup)
					end
				end
			end,
		})

		local animalToggle = SectionLife:Toggle({
			Name = "Enabled Animals ESP",
			Default = animalConfig.Enabled,
			Flag = "Esp_Animal_Enabled",
			Callback = function(value)
				animalConfig.Enabled = value
			end,
		})

		animalToggle:Colorpicker({
			Name = "Animals Color",
			Default = animalConfig.Color,
			Flag = "Esp_Animal_Color",
			Callback = function(value)
				animalConfig.Color = value
			end,
		})

		SectionLife:Toggle({
			Name = "Show Animals Distance",
			Default = animalConfig.ShowDistance,
			Flag = "Esp_Animal_ShowDistance",
			Callback = function(value)
				animalConfig.ShowDistance = value
			end,
		})

		SectionLife:Slider({
			Name = "Animals Max Distance",
			Min = 100,
			Max = 5000,
			Suffix = "st",
			Default = animalConfig.MaxDistance,
			Flag = "Esp_Animal_MaxDistance",
			Callback = function(value)
				animalConfig.MaxDistance = value
			end,
		})
	end

	-- ENVIRONMENT (World)
	do
		local SectionLeft = SubPages["WorldVisuals"]:Section({
			Name = "Lighting",
			Side = "Left",
		})

		local SectionRight = SubPages["WorldVisuals"]:Section({
			Name = "Environment",
			Side = "Right",
		})

		SectionLeft:Toggle({
			Name = "Enabled",
			Default = worldConfig.Enabled,
			Flag = "World_Enabled",
			Callback = function(value)
				worldConfig.Enabled = value
				WorldVisuals:Update()
			end,
		})

		local ambientToggle = SectionLeft:Toggle({
			Name = "Ambient",
			Default = worldConfig.Ambient,
			Flag = "World_Ambient",
			Callback = function(value)
				worldConfig.Ambient = value
				WorldVisuals:Update()
			end,
		})

		ambientToggle:Colorpicker({
			Name = "Ambient Color",
			Default = worldConfig.AmbientColor,
			Flag = "World_AmbientColor",
			Callback = function(value)
				worldConfig.AmbientColor = value

				if worldConfig.Ambient then
					WorldVisuals:Update()
				end
			end,
		})

		local outdoorAmbientToggle = SectionLeft:Toggle({
			Name = "Outdoor Ambient",
			Default = worldConfig.OutdoorAmbient,
			Flag = "World_OutdoorAmbient",
			Callback = function(value)
				worldConfig.OutdoorAmbient = value
				WorldVisuals:Update()
			end,
		})

		outdoorAmbientToggle:Colorpicker({
			Name = "Outdoor Ambient Color",
			Default = worldConfig.OutdoorAmbientColor,
			Flag = "World_OutdoorAmbientColor",
			Callback = function(value)
				worldConfig.OutdoorAmbientColor = value

				if worldConfig.OutdoorAmbient then
					WorldVisuals:Update()
				end
			end,
		})

		SectionLeft:Toggle({
			Name = "Sky Changer",
			Default = worldConfig.SkyChanger,
			Flag = "World_SkyChanger",
			Callback = function(value)
				worldConfig.SkyChanger = value
				WorldVisuals:Update()
			end,
		})

		SectionLeft:Dropdown({
			Name = "Selected Sky",
			Items = WorldVisuals:GetSkyboxList(),
			Default = worldConfig.SelectedSky,
			Flag = "World_SelectedSky",
			Callback = function(value)
				worldConfig.SelectedSky = value

				if worldConfig.SkyChanger then
					WorldVisuals:Update()
				end
			end,
		})

		SectionLeft:Toggle({
			Name = "Time Changer",
			Default = worldConfig.TimeChanger,
			Flag = "World_TimeChanger",
			Callback = function(value)
				worldConfig.TimeChanger = value
				WorldVisuals:Update()
			end,
		})

		SectionLeft:Slider({
			Name = "Clock Time",
			Min = 0,
			Max = 24,
			Suffix = "h",
			Default = worldConfig.ClockTime,
			Flag = "World_ClockTime",
			Callback = function(value)
				worldConfig.ClockTime = value

				if worldConfig.TimeChanger then
					WorldVisuals:Update()
				end
			end,
		})

		SectionLeft:Toggle({
			Name = "Brightness",
			Default = worldConfig.Brightness,
			Flag = "World_Brightness",
			Callback = function(value)
				worldConfig.Brightness = value
				WorldVisuals:Update()
			end,
		})

		SectionLeft:Slider({
			Name = "Brightness Value",
			Min = 0,
			Max = 10,
			Default = worldConfig.BrightnessValue,
			Flag = "World_BrightnessValue",
			Callback = function(value)
				worldConfig.BrightnessValue = value

				if worldConfig.Brightness then
					WorldVisuals:Update()
				end
			end,
		})

		SectionLeft:Toggle({
			Name = "Exposure",
			Default = worldConfig.Exposure,
			Flag = "World_Exposure",
			Callback = function(value)
				worldConfig.Exposure = value
				WorldVisuals:Update()
			end,
		})

		SectionLeft:Slider({
			Name = "Exposure Value",
			Min = -5,
			Max = 5,
			Default = worldConfig.ExposureValue,
			Flag = "World_ExposureValue",
			Callback = function(value)
				worldConfig.ExposureValue = value

				if worldConfig.Exposure then
					WorldVisuals:Update()
				end
			end,
		})

		local fogToggle = SectionRight:Toggle({
			Name = "Fog",
			Default = worldConfig.Fog,
			Flag = "World_Fog",
			Callback = function(value)
				worldConfig.Fog = value
				WorldVisuals:Update()
			end,
		})

		fogToggle:Colorpicker({
			Name = "Fog Color",
			Default = worldConfig.FogColor,
			Flag = "World_FogColor",
			Callback = function(value)
				worldConfig.FogColor = value

				if worldConfig.Fog then
					WorldVisuals:Update()
				end
			end,
		})

		SectionRight:Slider({
			Name = "Fog Start",
			Min = 0,
			Max = 5000,
			Suffix = "st",
			Default = worldConfig.FogStart,
			Flag = "World_FogStart",
			Callback = function(value)
				worldConfig.FogStart = value

				if worldConfig.Fog then
					WorldVisuals:Update()
				end
			end,
		})

		SectionRight:Slider({
			Name = "Fog End",
			Min = 0,
			Max = 5000,
			Suffix = "st",
			Default = worldConfig.FogEnd,
			Flag = "World_FogEnd",
			Callback = function(value)
				worldConfig.FogEnd = value

				if worldConfig.Fog then
					WorldVisuals:Update()
				end
			end,
		})

		local colorCorrectionToggle = SectionRight:Toggle({
			Name = "Color Correction",
			Default = worldConfig.ColorCorrection,
			Flag = "World_ColorCorrection",
			Callback = function(value)
				worldConfig.ColorCorrection = value
				WorldVisuals:Update()
			end,
		})

		colorCorrectionToggle:Colorpicker({
			Name = "Tint",
			Default = worldConfig.Tint,
			Flag = "World_Tint",
			Callback = function(value)
				worldConfig.Tint = value

				if worldConfig.ColorCorrection then
					WorldVisuals:Update()
				end
			end,
		})

		SectionRight:Slider({
			Name = "Saturation",
			Min = -2,
			Max = 2,
			Default = worldConfig.Saturation,
			Flag = "World_Saturation",
			Callback = function(value)
				worldConfig.Saturation = value

				if worldConfig.ColorCorrection then
					WorldVisuals:Update()
				end
			end,
		})

		SectionRight:Slider({
			Name = "Contrast",
			Min = -2,
			Max = 2,
			Default = worldConfig.Contrast,
			Flag = "World_Contrast",
			Callback = function(value)
				worldConfig.Contrast = value

				if worldConfig.ColorCorrection then
					WorldVisuals:Update()
				end
			end,
		})

		local atmosphereToggle = SectionRight:Toggle({
			Name = "Atmosphere",
			Default = worldConfig.Atmosphere,
			Flag = "World_Atmosphere",
			Callback = function(value)
				worldConfig.Atmosphere = value
				WorldVisuals:Update()
			end,
		})

		atmosphereToggle:Colorpicker({
			Name = "Atmosphere Color",
			Default = worldConfig.AtmosphereColor,
			Flag = "World_AtmosphereColor",
			Callback = function(value)
				worldConfig.AtmosphereColor = value

				if worldConfig.Atmosphere then
					WorldVisuals:Update()
				end
			end,
		})

		SectionRight:Slider({
			Name = "Atmosphere Decay",
			Min = 0,
			Max = 1,
			Decimals = 2,
			Default = worldConfig.AtmosphereDecay,
			Flag = "World_AtmosphereDecay",
			Callback = function(value)
				worldConfig.AtmosphereDecay = value

				if worldConfig.Atmosphere then
					WorldVisuals:Update()
				end
			end,
		})

		SectionRight:Slider({
			Name = "Atmosphere Density",
			Min = 0,
			Max = 1,
			Decimals = 2,
			Default = worldConfig.AtmosphereDensity,
			Flag = "World_AtmosphereDensity",
			Callback = function(value)
				worldConfig.AtmosphereDensity = value

				if worldConfig.Atmosphere then
					WorldVisuals:Update()
				end
			end,
		})

		SectionRight:Slider({
			Name = "Atmosphere Offset",
			Min = 0,
			Max = 1,
			Decimals = 2,
			Default = worldConfig.AtmosphereOffset,
			Flag = "World_AtmosphereOffset",
			Callback = function(value)
				worldConfig.AtmosphereOffset = value

				if worldConfig.Atmosphere then
					WorldVisuals:Update()
				end
			end,
		})

		SectionRight:Slider({
			Name = "Atmosphere Haze",
			Min = 0,
			Max = 10,
			Default = worldConfig.AtmosphereHaze,
			Flag = "World_AtmosphereHaze",
			Callback = function(value)
				worldConfig.AtmosphereHaze = value

				if worldConfig.Atmosphere then
					WorldVisuals:Update()
				end
			end,
		})

		SectionRight:Slider({
			Name = "Atmosphere Glare",
			Min = 0,
			Max = 10,
			Default = worldConfig.AtmosphereGlare,
			Flag = "World_AtmosphereGlare",
			Callback = function(value)
				worldConfig.AtmosphereGlare = value

				if worldConfig.Atmosphere then
					WorldVisuals:Update()
				end
			end,
		})
	end
end
