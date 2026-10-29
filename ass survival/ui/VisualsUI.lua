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
		["ESP"] = VisualsPage:SubPage({Name = "Player ESP"}),
		["BotESP"] = VisualsPage:SubPage({Name = "Bot ESP"}),
		["WorldESP"] = VisualsPage:SubPage({Name = "World ESP"}),
		["WorldVisuals"] = VisualsPage:SubPage({Name = "World"})
	}

	-- PLAYER ESP
	do
		local SectionLeft = SubPages["ESP"]:Section({Name = "General & Bounds"})
		local SectionRight = SubPages["ESP"]:Section({Name = "Overlays & Colors"})

		SectionLeft:Toggle({
			Name = "Enabled ESP",
			Flag = "Esp_Enabled",
			Default = espConfig.Enabled,
			Callback = function(value)
				espConfig.Enabled = value
			end
		})

		SectionLeft:Toggle({
			Name = "Players",
			Flag = "Esp_Players",
			Default = espConfig.Players,
			Callback = function(value)
				espConfig.Players = value
			end
		})

		SectionLeft:Slider({
			Name = "Framerate Limit",
			Flag = "Esp_LimitFPS",
			Default = espConfig.LimitFPS,
			Compact = true,
			Min = 0,
			Max = 144,
			Decimals = 1,
			Suffix = " FPS",
			Callback = function(value)
				espConfig.LimitFPS = value
			end
		})

		local boxToggle = SectionLeft:Toggle({
			Name = "Bounding Box",
			Flag = "Esp_Boxes_Enabled",
			Default = espConfig.Boxes.Enabled,
			Callback = function(value)
				espConfig.Boxes.Enabled = value
			end
		})

		boxToggle:Colorpicker({
			Flag = "Esp_Box_GradTop",
			Default = espConfig.Boxes.Gradients.Top,
			Alpha = 0,
			Callback = function(value)
				espConfig.Boxes.Gradients.Top = value
			end
		})

		boxToggle:Colorpicker({
			Flag = "Esp_Box_GradBot",
			Default = espConfig.Boxes.Gradients.Bot,
			Alpha = 0,
			Callback = function(value)
				espConfig.Boxes.Gradients.Bot = value
			end
		})

		SectionLeft:Toggle({
			Name = "Dynamic Bounds",
			Flag = "Esp_Bounding_Enabled",
			Default = espConfig.Boxes["Bounding Box"].Enabled,
			Callback = function(value)
				espConfig.Boxes["Bounding Box"].Enabled = value
			end
		})

		SectionLeft:Toggle({
			Name = "Include Accessories",
			Flag = "Esp_Bounding_Accessories",
			Default = espConfig.Boxes["Bounding Box"].IncludeAccessories,
			Callback = function(value)
				espConfig.Boxes["Bounding Box"].IncludeAccessories = value
			end
		})

		SectionLeft:Slider({
			Name = "Padding X",
			Flag = "Esp_Bounding_BoxX",
			Default = espConfig.Boxes["Bounding Box"].BoxX,
			Compact = true,
			Min = 0,
			Max = 30,
			Decimals = 1,
			Suffix = "px",
			Callback = function(value)
				espConfig.Boxes["Bounding Box"].BoxX = value
			end
		})

		SectionLeft:Slider({
			Name = "Padding Y",
			Flag = "Esp_Bounding_BoxY",
			Default = espConfig.Boxes["Bounding Box"].BoxY,
			Compact = true,
			Min = 0,
			Max = 30,
			Decimals = 1,
			Suffix = "px",
			Callback = function(value)
				espConfig.Boxes["Bounding Box"].BoxY = value
			end
		})

		local glowToggle = SectionLeft:Toggle({
			Name = "Box Glow",
			Flag = "Esp_Glow_Enabled",
			Default = espConfig.Boxes["Box Glow"].Enabled,
			Callback = function(value)
				espConfig.Boxes["Box Glow"].Enabled = value
			end
		})

		glowToggle:Colorpicker({
			Flag = "Esp_Glow_Top",
			Default = espConfig.Boxes["Box Glow"].Top,
			Alpha = 0,
			Callback = function(value)
				espConfig.Boxes["Box Glow"].Top = value
			end
		})

		glowToggle:Colorpicker({
			Flag = "Esp_Glow_Bot",
			Default = espConfig.Boxes["Box Glow"].Bot,
			Alpha = 0,
			Callback = function(value)
				espConfig.Boxes["Box Glow"].Bot = value
			end
		})

		SectionLeft:Slider({
			Name = "Glow Alpha",
			Flag = "Esp_Glow_Trans",
			Default = math.floor(((espConfig.Boxes["Box Glow"].Transparency and espConfig.Boxes["Box Glow"].Transparency[1]) or 0.85) * 100),
			Compact = true,
			Min = 0,
			Max = 100,
			Decimals = 1,
			Suffix = "%",
			Callback = function(value)
				if not espConfig.Boxes["Box Glow"].Transparency then
					espConfig.Boxes["Box Glow"].Transparency = { 0.85, 0.85 }
				end
				espConfig.Boxes["Box Glow"].Transparency[1] = value / 100
				espConfig.Boxes["Box Glow"].Transparency[2] = value / 100
			end
		})

		local fillToggle = SectionLeft:Toggle({
			Name = "Box Fill",
			Flag = "Esp_Fill_Enabled",
			Default = espConfig.Boxes.Filled.Enabled,
			Callback = function(value)
				espConfig.Boxes.Filled.Enabled = value
			end
		})

		fillToggle:Colorpicker({
			Flag = "Esp_Fill_Top",
			Default = espConfig.Boxes.Filled.Top,
			Alpha = 0,
			Callback = function(value)
				espConfig.Boxes.Filled.Top = value
			end
		})

		fillToggle:Colorpicker({
			Flag = "Esp_Fill_Bot",
			Default = espConfig.Boxes.Filled.Bot,
			Alpha = 0,
			Callback = function(value)
				espConfig.Boxes.Filled.Bot = value
			end
		})

		SectionLeft:Slider({
			Name = "Fill Alpha",
			Flag = "Esp_Fill_Trans",
			Default = math.floor(((espConfig.Boxes.Filled.Transparency and espConfig.Boxes.Filled.Transparency[1]) or 0.85) * 100),
			Compact = true,
			Min = 0,
			Max = 100,
			Decimals = 1,
			Suffix = "%",
			Callback = function(value)
				if not espConfig.Boxes.Filled.Transparency then
					espConfig.Boxes.Filled.Transparency = { 0.85, 0.85 }
				end
				espConfig.Boxes.Filled.Transparency[1] = value / 100
				espConfig.Boxes.Filled.Transparency[2] = value / 100
			end
		})

		local healthBarToggle = SectionRight:Toggle({
			Name = "Health Bar",
			Flag = "Esp_HealthBar_Enabled",
			Default = espConfig.Bars["Health Bar"].Enabled,
			Callback = function(value)
				espConfig.Bars["Health Bar"].Enabled = value
			end
		})

		healthBarToggle:Colorpicker({
			Flag = "Esp_HealthBar_Color",
			Default = espConfig.Bars["Health Bar"].Color,
			Alpha = 0,
			Callback = function(value)
				espConfig.Bars["Health Bar"].Color = value
			end
		})

		local nameToggle = SectionRight:Toggle({
			Name = "Name",
			Flag = "Esp_Name_Enabled",
			Default = espConfig.Texts.Name.Enabled,
			Callback = function(value)
				espConfig.Texts.Name.Enabled = value
			end
		})

		nameToggle:Colorpicker({
			Flag = "Esp_Name_Color",
			Default = espConfig.Texts.Name.Color,
			Alpha = 0,
			Callback = function(value)
				espConfig.Texts.Name.Color = value
			end
		})

		local distToggle = SectionRight:Toggle({
			Name = "Distance",
			Flag = "Esp_Dist_Enabled",
			Default = espConfig.Texts.Distance.Enabled,
			Callback = function(value)
				espConfig.Texts.Distance.Enabled = value
			end
		})

		distToggle:Colorpicker({
			Flag = "Esp_Dist_Color",
			Default = espConfig.Texts.Distance.Color,
			Alpha = 0,
			Callback = function(value)
				espConfig.Texts.Distance.Color = value
			end
		})

		local weaponToggle = SectionRight:Toggle({
			Name = "Weapon",
			Flag = "Esp_Weapon_Enabled",
			Default = espConfig.Texts.Weapon.Enabled,
			Callback = function(value)
				espConfig.Texts.Weapon.Enabled = value
			end
		})

		weaponToggle:Colorpicker({
			Flag = "Esp_Weapon_Color",
			Default = espConfig.Texts.Weapon.Color,
			Alpha = 0,
			Callback = function(value)
				espConfig.Texts.Weapon.Color = value
			end
		})

		SectionRight:Toggle({
			Name = "Weapon Icon",
			Flag = "Esp_WeaponIcon_Enabled",
			Default = espConfig.Texts.WeaponIcon.Enabled,
			Callback = function(value)
				espConfig.Texts.WeaponIcon.Enabled = value
			end
		})

		SectionRight:Slider({
			Name = "Icon Scale",
			Flag = "Esp_WeaponIcon_Size",
			Default = espConfig.Texts.WeaponIcon.Size,
			Compact = true,
			Min = 12,
			Max = 48,
			Decimals = 1,
			Suffix = "px",
			Callback = function(value)
				espConfig.Texts.WeaponIcon.Size = value
			end
		})

		local stateToggle = SectionRight:Toggle({
			Name = "Flags",
			Flag = "Esp_State_Enabled",
			Default = espConfig.Texts.State.Enabled,
			Callback = function(value)
				espConfig.Texts.State.Enabled = value
			end
		})

		stateToggle:Colorpicker({
			Flag = "Esp_State_Color",
			Default = espConfig.Texts.State.Color,
			Alpha = 0,
			Callback = function(value)
				espConfig.Texts.State.Color = value
			end
		})

		SectionRight:Button({
			Name = "Unload ESP",
			Callback = function()
				EspInstance:Unload()
				Library:Notification("Visuals safely unloaded.", 3, Library.Theme.Accent)
			end
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

		local SectionLeft = SubPages["BotESP"]:Section({Name = "General & Bounds"})
		local SectionRight = SubPages["BotESP"]:Section({Name = "Overlays & Colors"})

		SectionLeft:Toggle({
			Name = "Enabled Bots",
			Flag = "Esp_Bot_Enabled",
			Default = espConfig.Bots.Enabled,
			Callback = function(value)
				espConfig.Bots.Enabled = value
			end
		})

		SectionLeft:Toggle({
			Name = "Custom Bot Colors",
			Flag = "Esp_Bot_CustomColors",
			Default = espConfig.Bots.CustomColors,
			Callback = function(value)
				espConfig.Bots.CustomColors = value
			end
		})

		local botBoxToggle = SectionLeft:Toggle({
			Name = "Bounding Box",
			Flag = "Esp_Bot_Boxes_Enabled",
			Default = botBoxes.Enabled,
			Callback = function(value)
				botBoxes.Enabled = value
			end
		})

		botBoxToggle:Colorpicker({
			Flag = "Esp_Bot_Box_GradTop",
			Default = botBoxes.Gradients.Top,
			Alpha = 0,
			Callback = function(value)
				botBoxes.Gradients.Top = value
			end
		})

		botBoxToggle:Colorpicker({
			Flag = "Esp_Bot_Box_GradBot",
			Default = botBoxes.Gradients.Bot,
			Alpha = 0,
			Callback = function(value)
				botBoxes.Gradients.Bot = value
			end
		})

		SectionLeft:Toggle({
			Name = "Dynamic Bounds",
			Flag = "Esp_Bot_Bounding_Enabled",
			Default = botBoundingBox.Enabled,
			Callback = function(value)
				botBoundingBox.Enabled = value
			end
		})

		SectionLeft:Toggle({
			Name = "Include Accessories",
			Flag = "Esp_Bot_Bounding_Accessories",
			Default = botBoundingBox.IncludeAccessories,
			Callback = function(value)
				botBoundingBox.IncludeAccessories = value
			end
		})

		SectionLeft:Slider({
			Name = "Padding X",
			Flag = "Esp_Bot_Bounding_BoxX",
			Default = botBoundingBox.BoxX,
			Compact = true,
			Min = 0,
			Max = 30,
			Decimals = 1,
			Suffix = "px",
			Callback = function(value)
				botBoundingBox.BoxX = value
			end
		})

		SectionLeft:Slider({
			Name = "Padding Y",
			Flag = "Esp_Bot_Bounding_BoxY",
			Default = botBoundingBox.BoxY,
			Compact = true,
			Min = 0,
			Max = 30,
			Decimals = 1,
			Suffix = "px",
			Callback = function(value)
				botBoundingBox.BoxY = value
			end
		})

		local botGlowToggle = SectionLeft:Toggle({
			Name = "Box Glow",
			Flag = "Esp_Bot_Glow_Enabled",
			Default = botGlow.Enabled,
			Callback = function(value)
				botGlow.Enabled = value
			end
		})

		botGlowToggle:Colorpicker({
			Flag = "Esp_Bot_Glow_Top",
			Default = botGlow.Top,
			Alpha = 0,
			Callback = function(value)
				botGlow.Top = value
			end
		})

		botGlowToggle:Colorpicker({
			Flag = "Esp_Bot_Glow_Bot",
			Default = botGlow.Bot,
			Alpha = 0,
			Callback = function(value)
				botGlow.Bot = value
			end
		})

		SectionLeft:Slider({
			Name = "Glow Alpha",
			Flag = "Esp_Bot_Glow_Trans",
			Default = math.floor(((botGlow.Transparency and botGlow.Transparency[1]) or 0.85) * 100),
			Compact = true,
			Min = 0,
			Max = 100,
			Decimals = 1,
			Suffix = "%",
			Callback = function(value)
				if not botGlow.Transparency then
					botGlow.Transparency = { 0.85, 0.85 }
				end
				botGlow.Transparency[1] = value / 100
				botGlow.Transparency[2] = value / 100
			end
		})

		local botFillToggle = SectionLeft:Toggle({
			Name = "Box Fill",
			Flag = "Esp_Bot_Fill_Enabled",
			Default = botFill.Enabled,
			Callback = function(value)
				botFill.Enabled = value
			end
		})

		botFillToggle:Colorpicker({
			Flag = "Esp_Bot_Fill_Top",
			Default = botFill.Top,
			Alpha = 0,
			Callback = function(value)
				botFill.Top = value
			end
		})

		botFillToggle:Colorpicker({
			Flag = "Esp_Bot_Fill_Bot",
			Default = botFill.Bot,
			Alpha = 0,
			Callback = function(value)
				botFill.Bot = value
			end
		})

		SectionLeft:Slider({
			Name = "Fill Alpha",
			Flag = "Esp_Bot_Fill_Trans",
			Default = math.floor(((botFill.Transparency and botFill.Transparency[1]) or 0.85) * 100),
			Compact = true,
			Min = 0,
			Max = 100,
			Decimals = 1,
			Suffix = "%",
			Callback = function(value)
				if not botFill.Transparency then
					botFill.Transparency = { 0.85, 0.85 }
				end
				botFill.Transparency[1] = value / 100
				botFill.Transparency[2] = value / 100
			end
		})

		local botHealthBarToggle = SectionRight:Toggle({
			Name = "Health Bar",
			Flag = "Esp_Bot_HealthBar_Enabled",
			Default = botBars["Health Bar"].Enabled,
			Callback = function(value)
				botBars["Health Bar"].Enabled = value
			end
		})

		botHealthBarToggle:Colorpicker({
			Flag = "Esp_Bot_HealthBar_Color",
			Default = botBars["Health Bar"].Color,
			Alpha = 0,
			Callback = function(value)
				botBars["Health Bar"].Color = value
			end
		})

		local botNameToggle = SectionRight:Toggle({
			Name = "Name",
			Flag = "Esp_Bot_Name_Enabled",
			Default = botTexts.Name.Enabled,
			Callback = function(value)
				botTexts.Name.Enabled = value
			end
		})

		botNameToggle:Colorpicker({
			Flag = "Esp_Bot_Name_Color",
			Default = botTexts.Name.Color,
			Alpha = 0,
			Callback = function(value)
				botTexts.Name.Color = value
			end
		})

		local botDistToggle = SectionRight:Toggle({
			Name = "Distance",
			Flag = "Esp_Bot_Dist_Enabled",
			Default = botTexts.Distance.Enabled,
			Callback = function(value)
				botTexts.Distance.Enabled = value
			end
		})

		botDistToggle:Colorpicker({
			Flag = "Esp_Bot_Dist_Color",
			Default = botTexts.Distance.Color,
			Alpha = 0,
			Callback = function(value)
				botTexts.Distance.Color = value
			end
		})

		local botWeaponToggle = SectionRight:Toggle({
			Name = "Weapon",
			Flag = "Esp_Bot_Weapon_Enabled",
			Default = botTexts.Weapon.Enabled,
			Callback = function(value)
				botTexts.Weapon.Enabled = value
			end
		})

		botWeaponToggle:Colorpicker({
			Flag = "Esp_Bot_Weapon_Color",
			Default = botTexts.Weapon.Color,
			Alpha = 0,
			Callback = function(value)
				botTexts.Weapon.Color = value
			end
		})

		SectionRight:Toggle({
			Name = "Weapon Icon",
			Flag = "Esp_Bot_WeaponIcon_Enabled",
			Default = botTexts.WeaponIcon.Enabled,
			Callback = function(value)
				botTexts.WeaponIcon.Enabled = value
			end
		})

		SectionRight:Slider({
			Name = "Icon Scale",
			Flag = "Esp_Bot_WeaponIcon_Size",
			Default = botTexts.WeaponIcon.Size,
			Compact = true,
			Min = 12,
			Max = 48,
			Decimals = 1,
			Suffix = "px",
			Callback = function(value)
				botTexts.WeaponIcon.Size = value
			end
		})

		local botStateToggle = SectionRight:Toggle({
			Name = "Flags",
			Flag = "Esp_Bot_State_Enabled",
			Default = botTexts.State.Enabled,
			Callback = function(value)
				botTexts.State.Enabled = value
			end
		})

		botStateToggle:Colorpicker({
			Flag = "Esp_Bot_State_Color",
			Default = botTexts.State.Color,
			Alpha = 0,
			Callback = function(value)
				botTexts.State.Color = value
			end
		})
	end

	-- WORLD ESP
	do
		local oreConfig = espConfig.Ores
		local pickupConfig = espConfig.Pickups
		local animalConfig = espConfig.Animals

		local SectionLeft = SubPages["WorldESP"]:Section({Name = "Ore ESP", Side = "Left"})
		local SectionRight = SubPages["WorldESP"]:Section({Name = "Pickups & Animals", Side = "Right"})

		SectionLeft:Toggle({
			Name = "Enabled Ores ESP",
			Flag = "Esp_Ore_Enabled",
			Default = oreConfig.Enabled,
			Callback = function(value)
				oreConfig.Enabled = value
			end
		})

		SectionLeft:Toggle({
			Name = "Show Distance",
			Flag = "Esp_Ore_ShowDistance",
			Default = oreConfig.ShowDistance,
			Callback = function(value)
				oreConfig.ShowDistance = value
			end
		})

		SectionLeft:Slider({
			Name = "Max Distance",
			Flag = "Esp_Ore_MaxDistance",
			Default = oreConfig.MaxDistance,
			Compact = true,
			Min = 100,
			Max = 5000,
			Decimals = 1,
			Suffix = " st",
			Callback = function(value)
				oreConfig.MaxDistance = value
			end
		})

		local stoneToggle = SectionLeft:Toggle({
			Name = "Stone Nodes",
			Flag = "Esp_Ore_Stone_Enabled",
			Default = oreConfig.Stone.Enabled,
			Callback = function(value)
				oreConfig.Stone.Enabled = value
			end
		})

		stoneToggle:Colorpicker({
			Flag = "Esp_Ore_Stone_Color",
			Default = oreConfig.Stone.Color,
			Alpha = 0,
			Callback = function(value)
				if typeof(value) == "Color3" then
					oreConfig.Stone.Color = value
				end
			end
		})

		local sulfurToggle = SectionLeft:Toggle({
			Name = "Sulfur Nodes",
			Flag = "Esp_Ore_Sulfur_Enabled",
			Default = oreConfig.Sulfur.Enabled,
			Callback = function(value)
				oreConfig.Sulfur.Enabled = value
			end
		})

		sulfurToggle:Colorpicker({
			Flag = "Esp_Ore_Sulfur_Color",
			Default = oreConfig.Sulfur.Color,
			Alpha = 0,
			Callback = function(value)
				if typeof(value) == "Color3" then
					oreConfig.Sulfur.Color = value
				end
			end
		})

		local metalToggle = SectionLeft:Toggle({
			Name = "Metal Nodes",
			Flag = "Esp_Ore_Metal_Enabled",
			Default = oreConfig.Metal.Enabled,
			Callback = function(value)
				oreConfig.Metal.Enabled = value
			end
		})

		metalToggle:Colorpicker({
			Flag = "Esp_Ore_Metal_Color",
			Default = oreConfig.Metal.Color,
			Alpha = 0,
			Callback = function(value)
				if typeof(value) == "Color3" then
					oreConfig.Metal.Color = value
				end
			end
		})

		local pickupToggle = SectionRight:Toggle({
			Name = "Enabled Pickups ESP",
			Flag = "Esp_Pickup_Enabled",
			Default = pickupConfig.Enabled,
			Callback = function(value)
				pickupConfig.Enabled = value
			end
		})

		pickupToggle:Colorpicker({
			Flag = "Esp_Pickup_Color",
			Default = pickupConfig.Color,
			Alpha = 0,
			Callback = function(value)
				if typeof(value) == "Color3" then
					pickupConfig.Color = value
				end
			end
		})

		SectionRight:Toggle({
			Name = "Show Pickups Distance",
			Flag = "Esp_Pickup_ShowDistance",
			Default = pickupConfig.ShowDistance,
			Callback = function(value)
				pickupConfig.ShowDistance = value
			end
		})

		SectionRight:Slider({
			Name = "Pickups Max Distance",
			Flag = "Esp_Pickup_MaxDistance",
			Default = pickupConfig.MaxDistance,
			Compact = true,
			Min = 50,
			Max = 2000,
			Decimals = 1,
			Suffix = " st",
			Callback = function(value)
				pickupConfig.MaxDistance = value
			end
		})

		SectionRight:Dropdown({
			Name = "Pickups Whitelist",
			Flag = "Esp_Pickup_Whitelist",
			Multi = true,
			Items = validPickups,
			Default = {},
			Callback = function(value)
				espConfig.Pickups.Whitelist = value
				for _, data in pairs(EspInstance.PickupCache) do
					if typeof(data) == "table" and data.Label then
						if not isPickupAllowed(value, data.Name) then
							data.Label.Visible = false
						end
					end
				end
			end
		})

		local animalToggle = SectionRight:Toggle({
			Name = "Enabled Animals ESP",
			Flag = "Esp_Animal_Enabled",
			Default = animalConfig.Enabled,
			Callback = function(value)
				animalConfig.Enabled = value
			end
		})

		animalToggle:Colorpicker({
			Flag = "Esp_Animal_Color",
			Default = animalConfig.Color,
			Alpha = 0,
			Callback = function(value)
				if typeof(value) == "Color3" then
					animalConfig.Color = value
				end
			end
		})

		SectionRight:Toggle({
			Name = "Show Animals Distance",
			Flag = "Esp_Animal_ShowDistance",
			Default = animalConfig.ShowDistance,
			Callback = function(value)
				animalConfig.ShowDistance = value
			end
		})

		SectionRight:Slider({
			Name = "Animals Max Distance",
			Flag = "Esp_Animal_MaxDistance",
			Default = animalConfig.MaxDistance,
			Compact = true,
			Min = 100,
			Max = 5000,
			Decimals = 1,
			Suffix = " st",
			Callback = function(value)
				animalConfig.MaxDistance = value
			end
		})
	end

	-- WORLD
	do
		local SectionLeft = SubPages["WorldVisuals"]:Section({Name = "Lighting"})
		local SectionRight = SubPages["WorldVisuals"]:Section({Name = "Environment"})

		SectionLeft:Toggle({
			Name = "Enabled World",
			Flag = "World_Enabled",
			Default = worldConfig.Enabled,
			Callback = function(value)
				worldConfig.Enabled = value
				WorldVisuals:Update()
			end
		})

		local ambientToggle = SectionLeft:Toggle({
			Name = "Ambient",
			Flag = "World_Ambient",
			Default = worldConfig.Ambient,
			Callback = function(value)
				worldConfig.Ambient = value
				WorldVisuals:Update()
			end
		})

		ambientToggle:Colorpicker({
			Flag = "World_AmbientColor",
			Default = worldConfig.AmbientColor,
			Alpha = 0,
			Callback = function(value)
				worldConfig.AmbientColor = value
				if worldConfig.Ambient then
					WorldVisuals:Update()
				end
			end
		})

		local outdoorToggle = SectionLeft:Toggle({
			Name = "Outdoor Ambient",
			Flag = "World_OutdoorAmbient",
			Default = worldConfig.OutdoorAmbient,
			Callback = function(value)
				worldConfig.OutdoorAmbient = value
				WorldVisuals:Update()
			end
		})

		outdoorToggle:Colorpicker({
			Flag = "World_OutdoorAmbientColor",
			Default = worldConfig.OutdoorAmbientColor,
			Alpha = 0,
			Callback = function(value)
				worldConfig.OutdoorAmbientColor = value
				if worldConfig.OutdoorAmbient then
					WorldVisuals:Update()
				end
			end
		})

		local skyToggle = SectionLeft:Toggle({
			Name = "Custom Skybox",
			Flag = "World_SkyChanger",
			Default = worldConfig.SkyChanger,
			Callback = function(value)
				worldConfig.SkyChanger = value
				WorldVisuals:Update()
			end
		})

		SectionLeft:Dropdown({
			Name = "Skybox Preset",
			Flag = "World_SelectedSky",
			Multi = false,
			Items = WorldVisuals:GetSkyboxList(),
			Default = worldConfig.SelectedSky,
			Callback = function(value)
				worldConfig.SelectedSky = value
				if worldConfig.SkyChanger then
					WorldVisuals:Update()
				end
			end
		})

		SectionLeft:Toggle({
			Name = "Time Changer",
			Flag = "World_TimeChanger",
			Default = worldConfig.TimeChanger,
			Callback = function(value)
				worldConfig.TimeChanger = value
				WorldVisuals:Update()
			end
		})

		SectionLeft:Slider({
			Name = "Time",
			Flag = "World_ClockTime",
			Default = worldConfig.ClockTime,
			Compact = true,
			Min = 0,
			Max = 24,
			Decimals = 1,
			Suffix = " h",
			Callback = function(value)
				worldConfig.ClockTime = value
				if worldConfig.TimeChanger then
					WorldVisuals:Update()
				end
			end
		})

		SectionLeft:Toggle({
			Name = "Custom Brightness",
			Flag = "World_Brightness",
			Default = worldConfig.Brightness,
			Callback = function(value)
				worldConfig.Brightness = value
				WorldVisuals:Update()
			end
		})

		SectionLeft:Slider({
			Name = "Brightness",
			Flag = "World_BrightnessValue",
			Default = worldConfig.BrightnessValue,
			Compact = true,
			Min = 0,
			Max = 10,
			Decimals = 1,
			Suffix = "",
			Callback = function(value)
				worldConfig.BrightnessValue = value
				if worldConfig.Brightness then
					WorldVisuals:Update()
				end
			end
		})

		SectionLeft:Toggle({
			Name = "Custom Exposure",
			Flag = "World_Exposure",
			Default = worldConfig.Exposure,
			Callback = function(value)
				worldConfig.Exposure = value
				WorldVisuals:Update()
			end
		})

		SectionLeft:Slider({
			Name = "Exposure",
			Flag = "World_ExposureValue",
			Default = worldConfig.ExposureValue,
			Compact = true,
			Min = -5,
			Max = 5,
			Decimals = 1,
			Suffix = "",
			Callback = function(value)
				worldConfig.ExposureValue = value
				if worldConfig.Exposure then
					WorldVisuals:Update()
				end
			end
		})

		local fogToggle = SectionRight:Toggle({
			Name = "Custom Fog",
			Flag = "World_Fog",
			Default = worldConfig.Fog,
			Callback = function(value)
				worldConfig.Fog = value
				WorldVisuals:Update()
			end
		})

		fogToggle:Colorpicker({
			Flag = "World_FogColor",
			Default = worldConfig.FogColor,
			Alpha = 0,
			Callback = function(value)
				worldConfig.FogColor = value
				if worldConfig.Fog then
					WorldVisuals:Update()
				end
			end
		})

		SectionRight:Slider({
			Name = "Fog Start",
			Flag = "World_FogStart",
			Default = worldConfig.FogStart,
			Compact = true,
			Min = 0,
			Max = 5000,
			Decimals = 1,
			Suffix = " st",
			Callback = function(value)
				worldConfig.FogStart = value
				if worldConfig.Fog then
					WorldVisuals:Update()
				end
			end
		})

		SectionRight:Slider({
			Name = "Fog End",
			Flag = "World_FogEnd",
			Default = worldConfig.FogEnd,
			Compact = true,
			Min = 0,
			Max = 5000,
			Decimals = 1,
			Suffix = " st",
			Callback = function(value)
				worldConfig.FogEnd = value
				if worldConfig.Fog then
					WorldVisuals:Update()
				end
			end
		})

		local ccToggle = SectionRight:Toggle({
			Name = "Color Correction",
			Flag = "World_ColorCorrection",
			Default = worldConfig.ColorCorrection,
			Callback = function(value)
				worldConfig.ColorCorrection = value
				WorldVisuals:Update()
			end
		})

		ccToggle:Colorpicker({
			Flag = "World_Tint",
			Default = worldConfig.Tint,
			Alpha = 0,
			Callback = function(value)
				worldConfig.Tint = value
				if worldConfig.ColorCorrection then
					WorldVisuals:Update()
				end
			end
		})

		SectionRight:Slider({
			Name = "Saturation",
			Flag = "World_Saturation",
			Default = worldConfig.Saturation,
			Compact = true,
			Min = -2,
			Max = 2,
			Decimals = 1,
			Suffix = "",
			Callback = function(value)
				worldConfig.Saturation = value
				if worldConfig.ColorCorrection then
					WorldVisuals:Update()
				end
			end
		})

		SectionRight:Slider({
			Name = "Contrast",
			Flag = "World_Contrast",
			Default = worldConfig.Contrast,
			Compact = true,
			Min = -2,
			Max = 2,
			Decimals = 1,
			Suffix = "",
			Callback = function(value)
				worldConfig.Contrast = value
				if worldConfig.ColorCorrection then
					WorldVisuals:Update()
				end
			end
		})

		local atmoToggle = SectionRight:Toggle({
			Name = "Atmosphere",
			Flag = "World_Atmosphere",
			Default = worldConfig.Atmosphere,
			Callback = function(value)
				worldConfig.Atmosphere = value
				WorldVisuals:Update()
			end
		})

		atmoToggle:Colorpicker({
			Flag = "World_AtmosphereColor",
			Default = worldConfig.AtmosphereColor,
			Alpha = 0,
			Callback = function(value)
				worldConfig.AtmosphereColor = value
				if worldConfig.Atmosphere then
					WorldVisuals:Update()
				end
			end
		})

		atmoToggle:Colorpicker({
			Flag = "World_AtmosphereDecay",
			Default = worldConfig.AtmosphereDecay,
			Alpha = 0,
			Callback = function(value)
				worldConfig.AtmosphereDecay = value
				if worldConfig.Atmosphere then
					WorldVisuals:Update()
				end
			end
		})

		SectionRight:Slider({
			Name = "Density",
			Flag = "World_AtmosphereDensity",
			Default = worldConfig.AtmosphereDensity,
			Compact = true,
			Min = 0,
			Max = 1,
			Decimals = 2,
			Suffix = "",
			Callback = function(value)
				worldConfig.AtmosphereDensity = value
				if worldConfig.Atmosphere then
					WorldVisuals:Update()
				end
			end
		})

		SectionRight:Slider({
			Name = "Offset",
			Flag = "World_AtmosphereOffset",
			Default = worldConfig.AtmosphereOffset,
			Compact = true,
			Min = 0,
			Max = 1,
			Decimals = 2,
			Suffix = "",
			Callback = function(value)
				worldConfig.AtmosphereOffset = value
				if worldConfig.Atmosphere then
					WorldVisuals:Update()
				end
			end
		})

		SectionRight:Slider({
			Name = "Haze",
			Flag = "World_AtmosphereHaze",
			Default = worldConfig.AtmosphereHaze,
			Compact = true,
			Min = 0,
			Max = 10,
			Decimals = 1,
			Suffix = "",
			Callback = function(value)
				worldConfig.AtmosphereHaze = value
				if worldConfig.Atmosphere then
					WorldVisuals:Update()
				end
			end
		})

		SectionRight:Slider({
			Name = "Glare",
			Flag = "World_AtmosphereGlare",
			Default = worldConfig.AtmosphereGlare,
			Compact = true,
			Min = 0,
			Max = 10,
			Decimals = 1,
			Suffix = "",
			Callback = function(value)
				worldConfig.AtmosphereGlare = value
				if worldConfig.Atmosphere then
					WorldVisuals:Update()
				end
			end
		})
	end
end
