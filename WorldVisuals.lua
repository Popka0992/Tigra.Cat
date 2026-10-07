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
local runService = cloneref(game:GetService("RunService"))

-- Constants.
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

-- Cache terrain and clouds.
local terrain = workspaceService:FindFirstChildOfClass("Terrain") or workspaceService.Terrain
local cachedClouds = terrain and terrain:FindFirstChildOfClass("Clouds")
local originalCloudsEnabled = cachedClouds and cachedClouds.Enabled or true

-- Cache sun rays without GetChildren allocations.
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

local appliedSky = "default"

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

---Apply skybox textures directly.
---@param name string
function WorldVisuals:ApplySkybox(name)
	if appliedSky == name then return end
	appliedSky = name

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

---Updates static visual effects (Atmosphere, CC, Skybox).
function WorldVisuals:Update()
	local config = self.Config

	if not cachedClouds and terrain then
		cachedClouds = terrain:FindFirstChildOfClass("Clouds")
	end

	if config.Enabled then
		if cachedClouds then
			cachedClouds.Enabled = not config.NoClouds
		end

		for effect in pairs(cachedSunRays) do
			effect.Enabled = not config.NoSunRays
		end

		customColorCorrection.Enabled = config.ColorCorrection
		if config.ColorCorrection then
			customColorCorrection.Saturation = tonumber(config.Saturation) or 0
			customColorCorrection.Contrast = tonumber(config.Contrast) or 0
			customColorCorrection.TintColor = config.Tint or Color3.fromRGB(255, 255, 255)
		end

		if config.Atmosphere then
			customAtmosphere.Density = tonumber(config.AtmosphereDensity) or originalAtmosphere.Density
			customAtmosphere.Offset = tonumber(config.AtmosphereOffset) or originalAtmosphere.Offset
			customAtmosphere.Haze = tonumber(config.AtmosphereHaze) or originalAtmosphere.Haze
			customAtmosphere.Glare = tonumber(config.AtmosphereGlare) or originalAtmosphere.Glare
			customAtmosphere.Color = config.AtmosphereColor or originalAtmosphere.Color
			customAtmosphere.Decay = config.AtmosphereDecay or originalAtmosphere.Decay
		else
			customAtmosphere.Density = originalAtmosphere.Density
			customAtmosphere.Offset = originalAtmosphere.Offset
			customAtmosphere.Haze = originalAtmosphere.Haze
			customAtmosphere.Glare = originalAtmosphere.Glare
			customAtmosphere.Color = originalAtmosphere.Color
			customAtmosphere.Decay = originalAtmosphere.Decay
		end

		self:ApplySkybox(config.SkyChanger and config.SelectedSky or "default")
	else
		if cachedClouds then
			cachedClouds.Enabled = originalCloudsEnabled
		end

		for effect, state in pairs(cachedSunRays) do
			if effect and effect.Parent then
				effect.Enabled = state
			end
		end

		lightingService.Ambient = originalAmbient
		lightingService.OutdoorAmbient = originalOutdoorAmbient
		lightingService.FogColor = originalFogColor
		lightingService.FogStart = originalFogStart
		lightingService.FogEnd = originalFogEnd
		lightingService.ClockTime = originalClockTime
		lightingService.Brightness = originalBrightness
		lightingService.ExposureCompensation = originalExposure

		customColorCorrection.Enabled = false
		customAtmosphere.Density = originalAtmosphere.Density
		customAtmosphere.Offset = originalAtmosphere.Offset
		customAtmosphere.Haze = originalAtmosphere.Haze
		customAtmosphere.Glare = originalAtmosphere.Glare
		customAtmosphere.Color = originalAtmosphere.Color
		customAtmosphere.Decay = originalAtmosphere.Decay

		self:ApplySkybox("default")
	end
end

---Returns configuration table.
---@return table
function WorldVisuals:GetConfig()
	return self.Config
end

---Starts frame-level property protection without performance drops.
function WorldVisuals:Load()
	self:Update()

	runService.RenderStepped:Connect(function()
		local config = self.Config
		if not config.Enabled then return end

		-- Only re-assign when game's day/night scripts overwrite our target values.
		if config.Ambient and lightingService.Ambient ~= config.AmbientColor then
			lightingService.Ambient = config.AmbientColor
		end

		if config.OutdoorAmbient and lightingService.OutdoorAmbient ~= config.OutdoorAmbientColor then
			lightingService.OutdoorAmbient = config.OutdoorAmbientColor
		end

		if config.TimeChanger then
			local targetTime = tonumber(config.ClockTime) or originalClockTime
			if lightingService.ClockTime ~= targetTime then
				lightingService.ClockTime = targetTime
			end
		end

		if config.Brightness then
			local targetBrightness = tonumber(config.BrightnessValue) or originalBrightness
			if lightingService.Brightness ~= targetBrightness then
				lightingService.Brightness = targetBrightness
			end
		end

		if config.Exposure then
			local targetExposure = tonumber(config.ExposureValue) or originalExposure
			if lightingService.ExposureCompensation ~= targetExposure then
				lightingService.ExposureCompensation = targetExposure
			end
		end

		if config.Fog then
			if lightingService.FogColor ~= config.FogColor then
				lightingService.FogColor = config.FogColor
			end
			local targetStart = tonumber(config.FogStart) or originalFogStart
			if lightingService.FogStart ~= targetStart then
				lightingService.FogStart = targetStart
			end
			local targetEnd = tonumber(config.FogEnd) or originalFogEnd
			if lightingService.FogEnd ~= targetEnd then
				lightingService.FogEnd = targetEnd
			end
		end
	end)
end

return WorldVisuals
