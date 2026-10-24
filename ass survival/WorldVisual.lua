
-- Services.
local lightingService = cloneref(game:GetService("Lighting"))
local runService = cloneref(game:GetService("RunService"))

---@module Features.Visuals.WorldVisuals
local WorldVisuals = {}
WorldVisuals.__index = WorldVisuals

-- Constants.
local SKYBOX_ASSETS = {
	["Roblox Default"] = {
		Bk = "rbxasset://textures/sky/sky512_bk.tex",
		Dn = "rbxasset://textures/sky/sky512_dn.tex",
		Ft = "rbxasset://textures/sky/sky512_ft.tex",
		Lf = "rbxasset://textures/sky/sky512_lf.tex",
		Rt = "rbxasset://textures/sky/sky512_rt.tex",
		Up = "rbxasset://textures/sky/sky512_up.tex"
	},
	["Black Storm"] = {
		Bk = "rbxassetid://15502511288",
		Dn = "rbxassetid://15502508460",
		Ft = "rbxassetid://15502510289",
		Lf = "rbxassetid://15502507918",
		Rt = "rbxassetid://15502509398",
		Up = "rbxassetid://15502511911"
	},
	["HD"] = {
		Bk = "http://www.roblox.com/asset/?id=16553658937",
		Dn = "http://www.roblox.com/asset/?id=16553660713",
		Ft = "http://www.roblox.com/asset/?id=16553662144",
		Lf = "http://www.roblox.com/asset/?id=16553664042",
		Rt = "http://www.roblox.com/asset/?id=16553665766",
		Up = "http://www.roblox.com/asset/?id=16553667750"
	},
	["Snow"] = {
		Bk = "http://www.roblox.com/asset/?id=155657655",
		Dn = "http://www.roblox.com/asset/?id=155674246",
		Ft = "http://www.roblox.com/asset/?id=155657609",
		Lf = "http://www.roblox.com/asset/?id=155657671",
		Rt = "http://www.roblox.com/asset/?id=155657619",
		Up = "http://www.roblox.com/asset/?id=155674931"
	},
	["Blue Space"] = {
		Bk = "rbxassetid://15536110634",
		Dn = "rbxassetid://15536112543",
		Ft = "rbxassetid://15536116141",
		Lf = "rbxassetid://15536114370",
		Rt = "rbxassetid://15536118762",
		Up = "rbxassetid://15536117282"
	},
	["Realistic"] = {
		Bk = "rbxassetid://653719502",
		Dn = "rbxassetid://653718790",
		Ft = "rbxassetid://653719067",
		Lf = "rbxassetid://653719190",
		Rt = "rbxassetid://653718931",
		Up = "rbxassetid://653719321"
	},
	["Stormy"] = {
		Bk = "http://www.roblox.com/asset/?id=18703245834",
		Dn = "http://www.roblox.com/asset/?id=18703243349",
		Ft = "http://www.roblox.com/asset/?id=18703240532",
		Lf = "http://www.roblox.com/asset/?id=18703237556",
		Rt = "http://www.roblox.com/asset/?id=18703235430",
		Up = "http://www.roblox.com/asset/?id=18703232671"
	},
	["Pink"] = {
		Bk = "rbxassetid://12216109205",
		Dn = "rbxassetid://12216109875",
		Ft = "rbxassetid://12216109489",
		Lf = "rbxassetid://12216110170",
		Rt = "rbxassetid://12216110471",
		Up = "rbxassetid://12216108877"
	},
	["Sunset"] = {
		Bk = "rbxassetid://600830446",
		Dn = "rbxassetid://600831635",
		Ft = "rbxassetid://600832720",
		Lf = "rbxassetid://600886090",
		Rt = "rbxassetid://600833862",
		Up = "rbxassetid://600835177"
	},
	["Arctic"] = {
		Bk = "http://www.roblox.com/asset/?id=225469390",
		Dn = "http://www.roblox.com/asset/?id=225469395",
		Ft = "http://www.roblox.com/asset/?id=225469403",
		Lf = "http://www.roblox.com/asset/?id=225469450",
		Rt = "http://www.roblox.com/asset/?id=225469471",
		Up = "http://www.roblox.com/asset/?id=225469481"
	},
	["Space"] = {
		Bk = "http://www.roblox.com/asset/?id=166509999",
		Dn = "http://www.roblox.com/asset/?id=166510057",
		Ft = "http://www.roblox.com/asset/?id=166510116",
		Lf = "http://www.roblox.com/asset/?id=166510092",
		Rt = "http://www.roblox.com/asset/?id=166510131",
		Up = "http://www.roblox.com/asset/?id=166510114"
	},
	["Red Night"] = {
		Bk = "http://www.roblox.com/asset/?id=401664839",
		Dn = "http://www.roblox.com/asset/?id=401664862",
		Ft = "http://www.roblox.com/asset/?id=401664960",
		Lf = "http://www.roblox.com/asset/?id=401664881",
		Rt = "http://www.roblox.com/asset/?id=401664901",
		Up = "http://www.roblox.com/asset/?id=401664936"
	},
	["Deep Space 1"] = {
		Bk = "http://www.roblox.com/asset/?id=149397692",
		Dn = "http://www.roblox.com/asset/?id=149397686",
		Ft = "http://www.roblox.com/asset/?id=149397697",
		Lf = "http://www.roblox.com/asset/?id=149397684",
		Rt = "http://www.roblox.com/asset/?id=149397688",
		Up = "http://www.roblox.com/asset/?id=149397702"
	},
	["Pink Skies"] = {
		Bk = "http://www.roblox.com/asset/?id=151165214",
		Dn = "http://www.roblox.com/asset/?id=151165197",
		Ft = "http://www.roblox.com/asset/?id=151165224",
		Lf = "http://www.roblox.com/asset/?id=151165191",
		Rt = "http://www.roblox.com/asset/?id=151165206",
		Up = "http://www.roblox.com/asset/?id=151165227"
	},
	["Purple Sunset"] = {
		Bk = "rbxassetid://264908339",
		Dn = "rbxassetid://264907909",
		Ft = "rbxassetid://264909420",
		Lf = "rbxassetid://264909758",
		Rt = "rbxassetid://264908886",
		Up = "rbxassetid://264907379"
	},
	["Blue Night"] = {
		Bk = "http://www.roblox.com/asset/?id=12064107",
		Dn = "http://www.roblox.com/asset/?id=12064152",
		Ft = "http://www.roblox.com/asset/?id=12064121",
		Lf = "http://www.roblox.com/asset/?id=12063984",
		Rt = "http://www.roblox.com/asset/?id=12064115",
		Up = "http://www.roblox.com/asset/?id=12064131"
	},
	["Blossom Daylight"] = {
		Bk = "http://www.roblox.com/asset/?id=271042516",
		Dn = "http://www.roblox.com/asset/?id=271077243",
		Ft = "http://www.roblox.com/asset/?id=271042556",
		Lf = "http://www.roblox.com/asset/?id=271042310",
		Rt = "http://www.roblox.com/asset/?id=271042467",
		Up = "http://www.roblox.com/asset/?id=271077958"
	},
	["Blue Nebula"] = {
		Bk = "http://www.roblox.com/asset?id=135207744",
		Dn = "http://www.roblox.com/asset?id=135207662",
		Ft = "http://www.roblox.com/asset?id=135207770",
		Lf = "http://www.roblox.com/asset?id=135207615",
		Rt = "http://www.roblox.com/asset?id=135207695",
		Up = "http://www.roblox.com/asset?id=135207794"
	},
	["Blue Planet"] = {
		Bk = "rbxassetid://218955819",
		Dn = "rbxassetid://218953419",
		Ft = "rbxassetid://218954524",
		Lf = "rbxassetid://218958493",
		Rt = "rbxassetid://218957134",
		Up = "rbxassetid://218950090"
	},
	["Deep Space 2"] = {
		Bk = "http://www.roblox.com/asset/?id=159248188",
		Dn = "http://www.roblox.com/asset/?id=159248183",
		Ft = "http://www.roblox.com/asset/?id=159248187",
		Lf = "http://www.roblox.com/asset/?id=159248173",
		Rt = "http://www.roblox.com/asset/?id=159248192",
		Up = "http://www.roblox.com/asset/?id=159248176"
	},
	["Summer"] = {
		Bk = "rbxassetid://16648590964",
		Dn = "rbxassetid://16648617436",
		Ft = "rbxassetid://16648595424",
		Lf = "rbxassetid://16648566370",
		Rt = "rbxassetid://16648577071",
		Up = "rbxassetid://16648598180"
	},
	["Galaxy"] = {
		Bk = "rbxassetid://15983968922",
		Dn = "rbxassetid://15983966825",
		Ft = "rbxassetid://15983965025",
		Lf = "rbxassetid://15983967420",
		Rt = "rbxassetid://15983966246",
		Up = "rbxassetid://15983964246"
	},
	["Stylized"] = {
		Bk = "rbxassetid://18351376859",
		Dn = "rbxassetid://18351374919",
		Ft = "rbxassetid://18351376800",
		Lf = "rbxassetid://18351376469",
		Rt = "rbxassetid://18351376457",
		Up = "rbxassetid://18351377189"
	},
	["Minecraft"] = {
		Bk = "rbxassetid://8735166756",
		Dn = "http://www.roblox.com/asset/?id=8735166707",
		Ft = "http://www.roblox.com/asset/?id=8735231668",
		Lf = "http://www.roblox.com/asset/?id=8735166755",
		Rt = "http://www.roblox.com/asset/?id=8735166751",
		Up = "http://www.roblox.com/asset/?id=8735166729"
	},
	["Cloudy Rain"] = {
		Bk = "http://www.roblox.com/asset/?id=4498828382",
		Dn = "http://www.roblox.com/asset/?id=4498828812",
		Ft = "http://www.roblox.com/asset/?id=4498829917",
		Lf = "http://www.roblox.com/asset/?id=4498830911",
		Rt = "http://www.roblox.com/asset/?id=4498830417",
		Up = "http://www.roblox.com/asset/?id=4498831746"
	},
	["Black Cloudy Rain"] = {
		Bk = "http://www.roblox.com/asset/?id=149679669",
		Dn = "http://www.roblox.com/asset/?id=149681979",
		Ft = "http://www.roblox.com/asset/?id=149679690",
		Lf = "http://www.roblox.com/asset/?id=149679709",
		Rt = "http://www.roblox.com/asset/?id=149679722",
		Up = "http://www.roblox.com/asset/?id=149680199"
	}
}

WorldVisuals.SkyboxNames = {}
for name in pairs(SKYBOX_ASSETS) do
	table.insert(WorldVisuals.SkyboxNames, name)
end
table.sort(WorldVisuals.SkyboxNames)

-- Lighting baselines.
local originalAmbient = lightingService.Ambient
local originalOutdoorAmbient = lightingService.OutdoorAmbient
local originalFogColor = lightingService.FogColor
local originalFogStart = lightingService.FogStart
local originalFogEnd = lightingService.FogEnd
local originalClockTime = lightingService.ClockTime
local originalBrightness = lightingService.Brightness
local originalExposure = lightingService.ExposureCompensation

local customSky = lightingService:FindFirstChildOfClass("Sky")
local originalSkyProps = {
	SkyboxBk = customSky and customSky.SkyboxBk or "rbxasset://textures/sky/sky512_bk.tex",
	SkyboxDn = customSky and customSky.SkyboxDn or "rbxasset://textures/sky/sky512_dn.tex",
	SkyboxFt = customSky and customSky.SkyboxFt or "rbxasset://textures/sky/sky512_ft.tex",
	SkyboxLf = customSky and customSky.SkyboxLf or "rbxasset://textures/sky/sky512_lf.tex",
	SkyboxRt = customSky and customSky.SkyboxRt or "rbxasset://textures/sky/sky512_rt.tex",
	SkyboxUp = customSky and customSky.SkyboxUp or "rbxasset://textures/sky/sky512_up.tex"
}

if not customSky then
	customSky = Instance.new("Sky")
	customSky.Name = "CustomSky"
	customSky.Parent = lightingService
end

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

WorldVisuals.Config = {
	Enabled = false,
	Ambient = false,
	AmbientColor = originalAmbient,
	OutdoorAmbient = false,
	OutdoorAmbientColor = originalOutdoorAmbient,
	SkyChanger = false,
	SelectedSky = "Roblox Default",

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
	local targetData = SKYBOX_ASSETS[name]
	if not customSky or not customSky.Parent then
		customSky = lightingService:FindFirstChildOfClass("Sky") or Instance.new("Sky", lightingService)
	end

	if targetData then
		customSky.SkyboxBk = targetData.Bk
		customSky.SkyboxDn = targetData.Dn
		customSky.SkyboxFt = targetData.Ft
		customSky.SkyboxLf = targetData.Lf
		customSky.SkyboxRt = targetData.Rt
		customSky.SkyboxUp = targetData.Up
	else
		for prop, val in pairs(originalSkyProps) do
			customSky[prop] = val
		end
	end
end

function WorldVisuals:Update()
	local config = self.Config
	if config.Enabled then
		lightingService.Ambient = config.Ambient and config.AmbientColor or originalAmbient
		lightingService.OutdoorAmbient = config.OutdoorAmbient and config.OutdoorAmbientColor or originalOutdoorAmbient

		if config.Fog then
			lightingService.FogColor = config.FogColor
			lightingService.FogStart = config.FogStart
			lightingService.FogEnd = config.FogEnd
		else
			lightingService.FogColor = originalFogColor
			lightingService.FogStart = originalFogStart
			lightingService.FogEnd = originalFogEnd
		end

		if config.TimeChanger then
			lightingService.ClockTime = config.ClockTime
		else
			lightingService.ClockTime = originalClockTime
		end

		lightingService.Brightness = config.Brightness and config.BrightnessValue or originalBrightness
		lightingService.ExposureCompensation = config.Exposure and config.ExposureValue or originalExposure

		customColorCorrection.Enabled = config.ColorCorrection
		if config.ColorCorrection then
			customColorCorrection.Saturation = config.Saturation
			customColorCorrection.Contrast = config.Contrast
			customColorCorrection.TintColor = config.Tint
		end

		if config.Atmosphere then
			customAtmosphere.Density = config.AtmosphereDensity
			customAtmosphere.Offset = config.AtmosphereOffset
			customAtmosphere.Haze = config.AtmosphereHaze
			customAtmosphere.Glare = config.AtmosphereGlare
			customAtmosphere.Color = config.AtmosphereColor
			customAtmosphere.Decay = config.AtmosphereDecay
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
			self:ApplySkybox(nil)
		end
	else
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

		self:ApplySkybox(nil)
	end
end

function WorldVisuals:GetConfig()
	return self.Config
end

function WorldVisuals:GetSkyboxList()
	return self.SkyboxNames
end

function WorldVisuals:Load()
	runService.RenderStepped:Connect(function()
		if not self.Config.Enabled then return end
		if self.Config.Ambient then
			lightingService.Ambient = self.Config.AmbientColor
		end
		if self.Config.OutdoorAmbient then
			lightingService.OutdoorAmbient = self.Config.OutdoorAmbientColor
		end
		if self.Config.Fog then
			lightingService.FogColor = self.Config.FogColor
			lightingService.FogStart = self.Config.FogStart
			lightingService.FogEnd = self.Config.FogEnd
		end
		if self.Config.TimeChanger then
			lightingService.ClockTime = self.Config.ClockTime
		end
		if self.Config.Brightness then
			lightingService.Brightness = self.Config.BrightnessValue
		end
		if self.Config.Exposure then
			lightingService.ExposureCompensation = self.Config.ExposureValue
		end
	end)
	return self
end

return WorldVisuals
