local cloneref = cloneref or function(o) return o end
local lightingService = cloneref(game:GetService("Lighting"))
local runService = cloneref(game:GetService("RunService"))
local workspaceService = cloneref(game:GetService("Workspace"))

local WorldVisuals = {}
WorldVisuals.__index = WorldVisuals

local originalAmbient = lightingService.Ambient
local originalOutdoorAmbient = lightingService.OutdoorAmbient
local originalFogColor = lightingService.FogColor
local originalFogStart = typeof(lightingService.FogStart) == "number" and lightingService.FogStart or 0
local originalFogEnd = typeof(lightingService.FogEnd) == "number" and lightingService.FogEnd or 1000
local originalClockTime = typeof(lightingService.ClockTime) == "number" and lightingService.ClockTime or 14
local originalBrightness = typeof(lightingService.Brightness) == "number" and lightingService.Brightness or 2
local originalExposure = typeof(lightingService.ExposureCompensation) == "number" and lightingService.ExposureCompensation or 0

local function getTerrainClouds()
	local terrain = workspaceService:FindFirstChildOfClass("Terrain") or workspaceService.Terrain
	if terrain then
		return terrain:FindFirstChildOfClass("Clouds")
	end
	return nil
end

local initialClouds = getTerrainClouds()
local originalCloudsEnabled = initialClouds and initialClouds.Enabled or true

local customColorCorrection = lightingService:FindFirstChild("CustomColorCorrection")
if not customColorCorrection then
	customColorCorrection = Instance.new("ColorCorrectionEffect")
	customColorCorrection.Name = "CustomColorCorrection"
	customColorCorrection.Enabled = false
	customColorCorrection.Parent = lightingService
end

local customAtmosphere = lightingService:FindFirstChildOfClass("Atmosphere")
local originalAtmosphere = {
	Density = (customAtmosphere and typeof(customAtmosphere.Density) == "number") and customAtmosphere.Density or 0.3,
	Offset = (customAtmosphere and typeof(customAtmosphere.Offset) == "number") and customAtmosphere.Offset or 0.25,
	Haze = (customAtmosphere and typeof(customAtmosphere.Haze) == "number") and customAtmosphere.Haze or 0,
	Glare = (customAtmosphere and typeof(customAtmosphere.Glare) == "number") and customAtmosphere.Glare or 0,
	Color = (customAtmosphere and customAtmosphere.Color) or Color3.fromRGB(199, 199, 199),
	Decay = (customAtmosphere and customAtmosphere.Decay) or Color3.fromRGB(106, 112, 125)
}

if not customAtmosphere then
	customAtmosphere = Instance.new("Atmosphere")
	customAtmosphere.Name = "CustomAtmosphere"
	customAtmosphere.Parent = lightingService
end

local initialSky = lightingService:FindFirstChildOfClass("Sky")
local skyboxes = {
	["default"] = {
		SkyboxBk = initialSky and initialSky.SkyboxBk or "",
		SkyboxDn = initialSky and initialSky.SkyboxDn or "",
		SkyboxFt = initialSky and initialSky.SkyboxFt or "",
		SkyboxLf = initialSky and initialSky.SkyboxLf or "",
		SkyboxRt = initialSky and initialSky.SkyboxRt or "",
		SkyboxUp = initialSky and initialSky.SkyboxUp or "",
		SunTextureId = initialSky and initialSky.SunTextureId or "",
		MoonTextureId = initialSky and initialSky.MoonTextureId or ""
	},
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

WorldVisuals.Config = {
	Enabled = false,
	Ambient = false,
	AmbientColor = originalAmbient,
	OutdoorAmbient = false,
	OutdoorAmbientColor = originalOutdoorAmbient,
	SkyChanger = false,
	SelectedSky = "default",
	NoClouds = false,

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

function WorldVisuals:ApplySkybox(name)
	local targetData = skyboxes[name] or skyboxes["default"]
	local skyObj = lightingService:FindFirstChildOfClass("Sky")
	if not skyObj then
		skyObj = Instance.new("Sky")
		skyObj.Name = "CustomSky"
		skyObj.Parent = lightingService
	end

	for prop, val in pairs(targetData) do
		pcall(function()
			skyObj[prop] = val
		end)
	end
end

function WorldVisuals:Update()
	local config = self.Config
	local clouds = getTerrainClouds()

	if config.Enabled then
		if clouds then
			clouds.Enabled = not config.NoClouds
		end

		lightingService.Ambient = config.Ambient and config.AmbientColor or originalAmbient
		lightingService.OutdoorAmbient = config.OutdoorAmbient and config.OutdoorAmbientColor or originalOutdoorAmbient

		if config.Fog then
			lightingService.FogColor = config.FogColor
			lightingService.FogStart = tonumber(config.FogStart) or originalFogStart
			lightingService.FogEnd = tonumber(config.FogEnd) or originalFogEnd
		else
			lightingService.FogColor = originalFogColor
			lightingService.FogStart = originalFogStart
			lightingService.FogEnd = originalFogEnd
		end

		if config.TimeChanger then
			lightingService.ClockTime = tonumber(config.ClockTime) or originalClockTime
		else
			lightingService.ClockTime = originalClockTime
		end

		lightingService.Brightness = config.Brightness and (tonumber(config.BrightnessValue) or originalBrightness) or originalBrightness
		lightingService.ExposureCompensation = config.Exposure and (tonumber(config.ExposureValue) or originalExposure) or originalExposure

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

		if config.SkyChanger then
			self:ApplySkybox(config.SelectedSky)
		else
			self:ApplySkybox("default")
		end
	else
		if clouds then
			clouds.Enabled = originalCloudsEnabled
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

function WorldVisuals:GetConfig()
	return self.Config
end

function WorldVisuals:Load()
	runService.RenderStepped:Connect(function()
		if not self.Config.Enabled then return end

		if self.Config.NoClouds then
			local clouds = getTerrainClouds()
			if clouds and clouds.Enabled then
				clouds.Enabled = false
			end
		end

		if self.Config.Ambient then
			lightingService.Ambient = self.Config.AmbientColor
		end
		if self.Config.OutdoorAmbient then
			lightingService.OutdoorAmbient = self.Config.OutdoorAmbientColor
		end
		if self.Config.Fog then
			lightingService.FogColor = self.Config.FogColor
			lightingService.FogStart = tonumber(self.Config.FogStart) or originalFogStart
			lightingService.FogEnd = tonumber(self.Config.FogEnd) or originalFogEnd
		end
		if self.Config.TimeChanger then
			lightingService.ClockTime = tonumber(self.Config.ClockTime) or originalClockTime
		end
		if self.Config.Brightness then
			lightingService.Brightness = tonumber(self.Config.BrightnessValue) or originalBrightness
		end
		if self.Config.Exposure then
			lightingService.ExposureCompensation = tonumber(self.Config.ExposureValue) or originalExposure
		end
	end)
end

return WorldVisuals
