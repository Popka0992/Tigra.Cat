-- Check for table that is shared between executions.
if not shared then
	return warn("No shared, no script.")
end

-- Initialize Luraph globals if they do not exist.
loadstring("getfenv().LPH_NO_VIRTUALIZE = function(...) return ... end")()

getfenv().PP_SCRAMBLE_NUM = function(...) return ... end
getfenv().PP_SCRAMBLE_STR = function(...) return ... end
getfenv().PP_SCRAMBLE_RE_NUM = function(...) return ... end

---@module Features.Visuals.WorldVisuals
local WorldVisuals = {}
WorldVisuals.__index = WorldVisuals

-- Services.
local cloneref = cloneref or function(instance) return instance end
local lightingService = cloneref(game:GetService("Lighting"))
local workspaceService = cloneref(game:GetService("Workspace"))

-- Constants.
local SKYBOX_PROPERTIES = { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp", "SunTextureId", "MoonTextureId" }
local SKYBOXES = {
	["default"] = {},
	["stormy"] = {
		SkyboxUp = "rbxassetid://18703232671",
		SkyboxBk = "rbxassetid://18703245834",
		SkyboxLf = "rbxassetid://18703237556",
		SkyboxDn = "rbxassetid://18703243349",
		SkyboxFt = "rbxassetid://18703240532",
		SkyboxRt = "rbxassetid://18703235430",
		SunTextureId = "",
		MoonTextureId = ""
	},
	["blue space"] = {
		SkyboxLf = "rbxassetid://15536114370",
		SkyboxUp = "rbxassetid://15536117282",
		SkyboxRt = "rbxassetid://15536118762",
		SkyboxFt = "rbxassetid://15536116141",
		SkyboxDn = "rbxassetid://15536112543",
		SkyboxBk = "rbxassetid://15536110634",
		SunTextureId = "",
		MoonTextureId = ""
	},
	["pink"] = {
		SkyboxUp = "rbxassetid://12216108877",
		SkyboxLf = "rbxassetid://12216110170",
		SkyboxRt = "rbxassetid://12216110471",
		SkyboxFt = "rbxassetid://12216109489",
		SkyboxBk = "rbxassetid://12216109205",
		SkyboxDn = "rbxassetid://12216109875",
		SunTextureId = "",
		MoonTextureId = ""
	},
	["black storm"] = {
		SkyboxLf = "rbxassetid://15502507918",
		SkyboxUp = "rbxassetid://15502511911",
		SkyboxRt = "rbxassetid://15502509398",
		SkyboxFt = "rbxassetid://15502510289",
		SkyboxDn = "rbxassetid://15502508460",
		SkyboxBk = "rbxassetid://15502511288",
		SunTextureId = "",
		MoonTextureId = ""
	},
	["realistic"] = {
		SkyboxUp = "rbxassetid://653719321",
		SkyboxDn = "rbxassetid://653718790",
		SkyboxLf = "rbxassetid://653719190",
		SkyboxFt = "rbxassetid://653719067",
		SkyboxRt = "rbxassetid://653718931",
		SkyboxBk = "rbxassetid://653719502",
		SunTextureId = "",
		MoonTextureId = ""
	}
}

-- Baseline state.
local originalAmbient = lightingService.Ambient
local originalOutdoorAmbient = lightingService.OutdoorAmbient
local originalFogColor = lightingService.FogColor
local originalFogStart = lightingService.FogStart
local originalFogEnd = lightingService.FogEnd
local originalClockTime = lightingService.ClockTime
local originalBrightness = lightingService.Brightness
local originalExposure = lightingService.ExposureCompensation

-- Instances caching.
local terrain = workspaceService:FindFirstChildOfClass("Terrain") or workspaceService.Terrain
local cachedClouds = terrain and terrain:FindFirstChildOfClass("Clouds")
local originalCloudsEnabled = cachedClouds and cachedClouds.Enabled or true

local cachedSunRays = {}
for _, child in ipairs(lightingService:GetChildren()) do
	if child:IsA("SunRaysEffect") then
		cachedSunRays[child] = child.Enabled
	end
end

lightingService.ChildAdded:Connect(function(child)
	if child:IsA("SunRaysEffect") then
		cachedSunRays[child] = child.Enabled
	end
end)

lightingService.ChildRemoved:Connect(function(child)
	cachedSunRays[child] = nil
end)

local customColorCorrection = lightingService:FindFirstChild("CustomColorCorrection")
if not customColorCorrection then
	customColorCorrection = Instance.new("ColorCorrectionEffect")
	customColorCorrection.Name = "CustomColorCorrection"
	customColorCorrection.Enabled = false
	customColorCorrection.Parent = lightingService
end

local customAtmosphere = lightingService:FindFirstChildOfClass("Atmosphere")
local originalAtmosphere = {
	Density = customAtmosphere and customAtmosphere.Density or 0.3,
	Offset = customAtmosphere and customAtmosphere.Offset or 0.25,
	Haze = customAtmosphere and customAtmosphere.Haze or 0,
	Glare = customAtmosphere and customAtmosphere.Glare or 0,
	Color = customAtmosphere and customAtmosphere.Color or Color3.fromRGB(199, 199, 199),
	Decay = customAtmosphere and customAtmosphere.Decay or Color3.fromRGB(106, 112, 125)
}

if not customAtmosphere then
	customAtmosphere = Instance.new("Atmosphere")
	customAtmosphere.Name = "CustomAtmosphere"
	customAtmosphere.Parent = lightingService
end

local customSky = lightingService:FindFirstChildOfClass("Sky")
SKYBOXES["default"] = {
	SkyboxBk = customSky and customSky.SkyboxBk or "",
	SkyboxDn = customSky and customSky.SkyboxDn or "",
	SkyboxFt = customSky and customSky.SkyboxFt or "",
	SkyboxLf = customSky and customSky.SkyboxLf or "",
	SkyboxRt = customSky and customSky.SkyboxRt or "",
	SkyboxUp = customSky and customSky.SkyboxUp or "",
	SunTextureId = customSky and customSky.SunTextureId or "",
	MoonTextureId = customSky and customSky.MoonTextureId or ""
}

if not customSky then
	customSky = Instance.new("Sky")
	customSky.Name = "CustomSky"
	customSky.Parent = lightingService
end

-- Shadow state to prevent redundant C++ bridge writes.
local appliedState = {
	ambient = originalAmbient,
	outdoorAmbient = originalOutdoorAmbient,
	fogColor = originalFogColor,
	fogStart = originalFogStart,
	fogEnd = originalFogEnd,
	clockTime = originalClockTime,
	brightness = originalBrightness,
	exposure = originalExposure,
	ccEnabled = false,
	ccSaturation = 0,
	ccContrast = 0,
	ccTint = Color3.fromRGB(255, 255, 255),
	sky = "default",
	noClouds = false,
	noSunRays = false
}

WorldVisuals.Config = {
	Enabled = false,
	Ambient = false,
	AmbientColor = originalAmbient,
	OutdoorAmbient = false,
	OutdoorAmbientColor = originalOutdoorAmbient,
	SkyChanger = false,
	SelectedSky = "default",
	NoClouds = false,
	NoSunRays = false,
	Fog = false,
	FogColor = originalFogColor,
	FogStart = originalFogStart,
	FogEnd = originalFogEnd,
	TimeChanger = false,
	ClockTime = originalClockTime,
	Brightness = false,
	BrightnessValue = originalBrightness,
	Exposure = false,
	ExposureValue = originalExposure,
	ColorCorrection = false,
	Saturation = 0,
	Contrast = 0,
	Tint = Color3.fromRGB(255, 255, 255),
	Atmosphere = false,
	AtmosphereDensity = originalAtmosphere.Density,
	AtmosphereOffset = originalAtmosphere.Offset,
	AtmosphereHaze = originalAtmosphere.Haze,
	AtmosphereGlare = originalAtmosphere.Glare,
	AtmosphereColor = originalAtmosphere.Color,
	AtmosphereDecay = originalAtmosphere.Decay
}

---Fast skybox application bypassing reflection overhead.
---@param name string
function WorldVisuals:ApplySkybox(name)
	if appliedState.sky == name then return end
	appliedState.sky = name

	local data = SKYBOXES[name] or SKYBOXES["default"]
	customSky.SkyboxBk = data.SkyboxBk or ""
	customSky.SkyboxDn = data.SkyboxDn or ""
	customSky.SkyboxFt = data.SkyboxFt or ""
	customSky.SkyboxLf = data.SkyboxLf or ""
	customSky.SkyboxRt = data.SkyboxRt or ""
	customSky.SkyboxUp = data.SkyboxUp or ""
	customSky.SunTextureId = data.SunTextureId or ""
	customSky.MoonTextureId = data.MoonTextureId or ""
end

---Updates world visuals using fast change detection.
function WorldVisuals:Update()
	local config = self.Config

	if not cachedClouds and terrain then
		cachedClouds = terrain:FindFirstChildOfClass("Clouds")
	end

	if config.Enabled then
		-- Clouds optimization.
		local targetClouds = not config.NoClouds
		if cachedClouds and appliedState.noClouds ~= config.NoClouds then
			appliedState.noClouds = config.NoClouds
			cachedClouds.Enabled = targetClouds
		end

		-- SunRays optimization.
		if appliedState.noSunRays ~= config.NoSunRays then
			appliedState.noSunRays = config.NoSunRays
			local enabled = not config.NoSunRays
			for effect in pairs(cachedSunRays) do
				effect.Enabled = enabled
			end
		end

		-- Lighting properties with dirty checking.
		local targetAmbient = config.Ambient and config.AmbientColor or originalAmbient
		if appliedState.ambient ~= targetAmbient then
			appliedState.ambient = targetAmbient
			lightingService.Ambient = targetAmbient
		end

		local targetOutdoor = config.OutdoorAmbient and config.OutdoorAmbientColor or originalOutdoorAmbient
		if appliedState.outdoorAmbient ~= targetOutdoor then
			appliedState.outdoorAmbient = targetOutdoor
			lightingService.OutdoorAmbient = targetOutdoor
		end

		local targetFogColor = config.Fog and config.FogColor or originalFogColor
		if appliedState.fogColor ~= targetFogColor then
			appliedState.fogColor = targetFogColor
			lightingService.FogColor = targetFogColor
		end

		local targetFogStart = config.Fog and config.FogStart or originalFogStart
		if appliedState.fogStart ~= targetFogStart then
			appliedState.fogStart = targetFogStart
			lightingService.FogStart = targetFogStart
		end

		local targetFogEnd = config.Fog and config.FogEnd or originalFogEnd
		if appliedState.fogEnd ~= targetFogEnd then
			appliedState.fogEnd = targetFogEnd
			lightingService.FogEnd = targetFogEnd
		end

		local targetClockTime = config.TimeChanger and config.ClockTime or originalClockTime
		if appliedState.clockTime ~= targetClockTime then
			appliedState.clockTime = targetClockTime
			lightingService.ClockTime = targetClockTime
		end

		local targetBrightness = config.Brightness and config.BrightnessValue or originalBrightness
		if appliedState.brightness ~= targetBrightness then
			appliedState.brightness = targetBrightness
			lightingService.Brightness = targetBrightness
		end

		local targetExposure = config.Exposure and config.ExposureValue or originalExposure
		if appliedState.exposure ~= targetExposure then
			appliedState.exposure = targetExposure
			lightingService.ExposureCompensation = targetExposure
		end

		-- Post-processing dirty checks.
		if appliedState.ccEnabled ~= config.ColorCorrection then
			appliedState.ccEnabled = config.ColorCorrection
			customColorCorrection.Enabled = config.ColorCorrection
		end

		if config.ColorCorrection then
			if appliedState.ccSaturation ~= config.Saturation then
				appliedState.ccSaturation = config.Saturation
				customColorCorrection.Saturation = config.Saturation
			end
			if appliedState.ccContrast ~= config.Contrast then
				appliedState.ccContrast = config.Contrast
				customColorCorrection.Contrast = config.Contrast
			end
			if appliedState.ccTint ~= config.Tint then
				appliedState.ccTint = config.Tint
				customColorCorrection.TintColor = config.Tint
			end
		end

		self:ApplySkybox(config.SkyChanger and config.SelectedSky or "default")
	else
		if cachedClouds and appliedState.noClouds then
			appliedState.noClouds = false
			cachedClouds.Enabled = originalCloudsEnabled
		end

		if appliedState.noSunRays then
			appliedState.noSunRays = false
			for effect, state in pairs(cachedSunRays) do
				if effect and effect.Parent then
					effect.Enabled = state
				end
			end
		end

		if appliedState.ambient ~= originalAmbient then
			appliedState.ambient = originalAmbient
			lightingService.Ambient = originalAmbient
		end

		if appliedState.outdoorAmbient ~= originalOutdoorAmbient then
			appliedState.outdoorAmbient = originalOutdoorAmbient
			lightingService.OutdoorAmbient = originalOutdoorAmbient
		end

		if appliedState.fogColor ~= originalFogColor then
			appliedState.fogColor = originalFogColor
			lightingService.FogColor = originalFogColor
		end

		if appliedState.fogStart ~= originalFogStart then
			appliedState.fogStart = originalFogStart
			lightingService.FogStart = originalFogStart
		end

		if appliedState.fogEnd ~= originalFogEnd then
			appliedState.fogEnd = originalFogEnd
			lightingService.FogEnd = originalFogEnd
		end

		if appliedState.clockTime ~= originalClockTime then
			appliedState.clockTime = originalClockTime
			lightingService.ClockTime = originalClockTime
		end

		if appliedState.brightness ~= originalBrightness then
			appliedState.brightness = originalBrightness
			lightingService.Brightness = originalBrightness
		end

		if appliedState.exposure ~= originalExposure then
			appliedState.exposure = originalExposure
			lightingService.ExposureCompensation = originalExposure
		end

		if appliedState.ccEnabled then
			appliedState.ccEnabled = false
			customColorCorrection.Enabled = false
		end

		self:ApplySkybox("default")
	end
end

---Initialize module.
function WorldVisuals:Load()
	self:Update()
end

return WorldVisuals
