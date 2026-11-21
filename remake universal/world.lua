local lightingService = cloneref(game:GetService("Lighting"))
local runService = cloneref(game:GetService("RunService"))
local workspaceService = cloneref(game:GetService("Workspace"))

local genv = getgenv()
if genv.WorldVisuals then
	pcall(genv.WorldVisuals.Unload, genv.WorldVisuals)
end

---@module Features.Visuals.WorldVisuals
local WorldVisuals = {}

local SCAN_INTERVAL = 0.25

local FACE_KEYS = { "Bk", "Dn", "Ft", "Lf", "Rt", "Up" }
local FACE_PROPERTIES = { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" }

local SKYBOX_ASSETS = {
	["Roblox Default"] = {
		"rbxasset://textures/sky/sky512_bk.tex",
		"rbxasset://textures/sky/sky512_dn.tex",
		"rbxasset://textures/sky/sky512_ft.tex",
		"rbxasset://textures/sky/sky512_lf.tex",
		"rbxasset://textures/sky/sky512_rt.tex",
		"rbxasset://textures/sky/sky512_up.tex"
	},
	["Black Storm"] = { 15502511288, 15502508460, 15502510289, 15502507918, 15502509398, 15502511911 },
	["HD"] = { 16553658937, 16553660713, 16553662144, 16553664042, 16553665766, 16553667750 },
	["Snow"] = { 155657655, 155674246, 155657609, 155657671, 155657619, 155674931 },
	["Blue Space"] = { 15536110634, 15536112543, 15536116141, 15536114370, 15536118762, 15536117282 },
	["Realistic"] = { 653719502, 653718790, 653719067, 653719190, 653718931, 653719321 },
	["Stormy"] = { 18703245834, 18703243349, 18703240532, 18703237556, 18703235430, 18703232671 },
	["Pink"] = { 12216109205, 12216109875, 12216109489, 12216110170, 12216110471, 12216108877 },
	["Sunset"] = { 600830446, 600831635, 600832720, 600886090, 600833862, 600835177 },
	["Arctic"] = { 225469390, 225469395, 225469403, 225469450, 225469471, 225469481 },
	["Space"] = { 166509999, 166510057, 166510116, 166510092, 166510131, 166510114 },
	["Red Night"] = { 401664839, 401664862, 401664960, 401664881, 401664901, 401664936 },
	["Deep Space 1"] = { 149397692, 149397686, 149397697, 149397684, 149397688, 149397702 },
	["Pink Skies"] = { 151165214, 151165197, 151165224, 151165191, 151165206, 151165227 },
	["Purple Sunset"] = { 264908339, 264907909, 264909420, 264909758, 264908886, 264907379 },
	["Blue Night"] = { 12064107, 12064152, 12064121, 12063984, 12064115, 12064131 },
	["Blossom Daylight"] = { 271042516, 271077243, 271042556, 271042310, 271042467, 271077958 },
	["Blue Nebula"] = { 135207744, 135207662, 135207770, 135207615, 135207695, 135207794 },
	["Blue Planet"] = { 218955819, 218953419, 218954524, 218958493, 218957134, 218950090 },
	["Deep Space 2"] = { 159248188, 159248183, 159248187, 159248173, 159248192, 159248176 },
	["Summer"] = { 16648590964, 16648617436, 16648595424, 16648566370, 16648577071, 16648598180 },
	["Galaxy"] = { 15983968922, 15983966825, 15983965025, 15983967420, 15983966246, 15983964246 },
	["Stylized"] = { 18351376859, 18351374919, 18351376800, 18351376469, 18351376457, 18351377189 },
	["Minecraft"] = { 8735166756, 8735166707, 8735231668, 8735166755, 8735166751, 8735166729 },
	["Cloudy Rain"] = { 4498828382, 4498828812, 4498829917, 4498830911, 4498830417, 4498831746 },
	["Black Cloudy Rain"] = { 149679669, 149681979, 149679690, 149679709, 149679722, 149680199 }
}

local SKY_PARAMETERS = {
	StarCount = "SkyStarCount",
	SunAngularSize = "SkySunSize",
	MoonAngularSize = "SkyMoonSize",
	CelestialBodiesShown = "SkyCelestialBodies",
	SkyboxOrientation = "SkyOrientation"
}

local SKY_SNAPSHOT = {
	"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp",
	"StarCount", "SunAngularSize", "MoonAngularSize", "CelestialBodiesShown", "SkyboxOrientation"
}

local TECHNOLOGY_LIST = { "Compatibility", "Voxel", "ShadowMap", "Future" }

local REMOVABLE_CLASSES = {
	BloomEffect = true,
	BlurEffect = true,
	ColorCorrectionEffect = true,
	DepthOfFieldEffect = true,
	SunRaysEffect = true
}

local LIGHTING_RULES = {
	{ flag = "Ambient", property = "Ambient", key = "AmbientColor" },
	{ flag = "OutdoorAmbient", property = "OutdoorAmbient", key = "OutdoorAmbientColor" },
	{ flag = "Fog", property = "FogColor", key = "FogColor" },
	{ flag = "Fog", property = "FogStart", key = "FogStart" },
	{ flag = "Fog", property = "FogEnd", key = "FogEnd" },
	{ flag = "TimeChanger", property = "ClockTime", key = "ClockTime" },
	{ flag = "Brightness", property = "Brightness", key = "BrightnessValue" },
	{ flag = "Exposure", property = "ExposureCompensation", key = "ExposureValue" },
	{ flag = "ColorShift", property = "ColorShift_Top", key = "ColorShiftTop" },
	{ flag = "ColorShift", property = "ColorShift_Bottom", key = "ColorShiftBottom" },
	{ flag = "GlobalShadows", property = "GlobalShadows", key = "GlobalShadowsValue" },
	{ flag = "ShadowSoftness", property = "ShadowSoftness", key = "ShadowSoftnessValue" },
	{ flag = "EnvironmentDiffuse", property = "EnvironmentDiffuseScale", key = "EnvironmentDiffuseValue" },
	{ flag = "EnvironmentSpecular", property = "EnvironmentSpecularScale", key = "EnvironmentSpecularValue" }
}

local SKY_DEFINITION = {
	key = "Sky",
	className = "Sky",
	reuse = true,
	snapshot = SKY_SNAPSHOT
}

local EFFECTS = {
	{
		key = "Atmosphere",
		flag = "Atmosphere",
		className = "Atmosphere",
		reuse = true,
		properties = {
			Density = "AtmosphereDensity",
			Offset = "AtmosphereOffset",
			Haze = "AtmosphereHaze",
			Glare = "AtmosphereGlare",
			Color = "AtmosphereColor",
			Decay = "AtmosphereDecay"
		}
	},
	{
		key = "Clouds",
		flag = "Clouds",
		className = "Clouds",
		reuse = true,
		parent = function()
			return workspaceService.Terrain
		end,
		properties = {
			Cover = "CloudsCover",
			Density = "CloudsDensity",
			Color = "CloudsColor"
		}
	},
	{
		key = "ColorCorrection",
		flag = "ColorCorrection",
		className = "ColorCorrectionEffect",
		properties = {
			Saturation = "Saturation",
			Contrast = "Contrast",
			TintColor = "Tint"
		}
	},
	{
		key = "Bloom",
		flag = "Bloom",
		className = "BloomEffect",
		properties = {
			Intensity = "BloomIntensity",
			Size = "BloomSize",
			Threshold = "BloomThreshold"
		}
	},
	{
		key = "SunRays",
		flag = "SunRays",
		className = "SunRaysEffect",
		properties = {
			Intensity = "SunRaysIntensity",
			Spread = "SunRaysSpread"
		}
	},
	{
		key = "Blur",
		flag = "Blur",
		className = "BlurEffect",
		properties = {
			Size = "BlurSize"
		}
	},
	{
		key = "DepthOfField",
		flag = "DepthOfField",
		className = "DepthOfFieldEffect",
		properties = {
			FarIntensity = "DofFarIntensity",
			FocusDistance = "DofFocusDistance",
			InFocusRadius = "DofInFocusRadius",
			NearIntensity = "DofNearIntensity"
		}
	}
}

local originals = {}
local slots = { Sky = {} }
local owned = {}
local removed = {}
local lastScan = 0
local updateConnection = nil

for _, definition in ipairs(EFFECTS) do
	slots[definition.key] = {}
	definition.snapshot = {}
	for property in pairs(definition.properties) do
		table.insert(definition.snapshot, property)
	end
end

WorldVisuals.SkyboxNames = {}
for name in pairs(SKYBOX_ASSETS) do
	table.insert(WorldVisuals.SkyboxNames, name)
end
table.sort(WorldVisuals.SkyboxNames)

local technologyOk, currentTechnology = pcall(gethiddenproperty, lightingService, "Technology")

WorldVisuals.Config = {
	Enabled = false,
	Ambient = false,
	AmbientColor = lightingService.Ambient,
	OutdoorAmbient = false,
	OutdoorAmbientColor = lightingService.OutdoorAmbient,
	SkyChanger = false,
	SelectedSky = "Roblox Default",
	UseCustomSkybox = false,
	CustomSkyboxFaces = { Bk = "", Dn = "", Ft = "", Lf = "", Rt = "", Up = "" },
	SkyParameters = false,
	SkyStarCount = 3000,
	SkySunSize = 21,
	SkyMoonSize = 11,
	SkyCelestialBodies = true,
	SkyOrientation = Vector3.zero,
	Fog = false,
	FogColor = lightingService.FogColor,
	FogStart = lightingService.FogStart,
	FogEnd = lightingService.FogEnd,
	TimeChanger = false,
	ClockTime = lightingService.ClockTime,
	Brightness = false,
	BrightnessValue = lightingService.Brightness,
	Exposure = false,
	ExposureValue = lightingService.ExposureCompensation,
	ColorShift = false,
	ColorShiftTop = lightingService.ColorShift_Top,
	ColorShiftBottom = lightingService.ColorShift_Bottom,
	GlobalShadows = false,
	GlobalShadowsValue = lightingService.GlobalShadows,
	ShadowSoftness = false,
	ShadowSoftnessValue = lightingService.ShadowSoftness,
	EnvironmentDiffuse = false,
	EnvironmentDiffuseValue = lightingService.EnvironmentDiffuseScale,
	EnvironmentSpecular = false,
	EnvironmentSpecularValue = lightingService.EnvironmentSpecularScale,
	Technology = false,
	TechnologyValue = technologyOk and currentTechnology.Name or "ShadowMap",
	ColorCorrection = false,
	Saturation = 0,
	Contrast = 0,
	Tint = Color3.fromRGB(255, 255, 255),
	Atmosphere = false,
	AtmosphereDensity = 0.3,
	AtmosphereOffset = 0.25,
	AtmosphereHaze = 0,
	AtmosphereGlare = 0,
	AtmosphereColor = Color3.fromRGB(199, 199, 199),
	AtmosphereDecay = Color3.fromRGB(106, 112, 125),
	Clouds = false,
	CloudsCover = 0.5,
	CloudsDensity = 0.7,
	CloudsColor = Color3.fromRGB(255, 255, 255),
	Bloom = false,
	BloomIntensity = 0.4,
	BloomSize = 24,
	BloomThreshold = 0.95,
	SunRays = false,
	SunRaysIntensity = 0.25,
	SunRaysSpread = 1,
	Blur = false,
	BlurSize = 24,
	DepthOfField = false,
	DofFarIntensity = 0.75,
	DofFocusDistance = 0.05,
	DofInFocusRadius = 10,
	DofNearIntensity = 0.75,
	RemoveGameEffects = false
}

local function normalizeAsset(value)
	local text = tostring(value)
	if string.match(text, "^%d+$") then
		return "rbxassetid://" .. text
	end
	local assetId = string.match(text, "id=(%d+)")
	return assetId and ("rbxassetid://" .. assetId) or text
end

local function setIfChanged(instance, property, value)
	if instance[property] ~= value then
		instance[property] = value
	end
end

local function acquire(slot, definition)
	local instance = slot.instance
	if instance and instance.Parent then
		return instance
	end

	local parent = definition.parent and definition.parent() or lightingService
	instance = definition.reuse and parent:FindFirstChildOfClass(definition.className) or nil
	slot.created = instance == nil
	slot.applied = nil

	if slot.created then
		instance = Instance.new(definition.className)
		owned[instance] = true
		instance.Parent = parent
	end

	slot.snapshot = {}
	for _, property in ipairs(definition.snapshot) do
		slot.snapshot[property] = instance[property]
	end

	slot.instance = instance
	return instance
end

local function release(slot)
	local instance = slot.instance
	if not instance then return end

	slot.instance = nil
	slot.applied = nil

	if slot.created then
		owned[instance] = nil
		instance:Destroy()
		return
	end

	if instance.Parent and slot.snapshot then
		for property, value in pairs(slot.snapshot) do
			instance[property] = value
		end
	end
	slot.snapshot = nil
end

local function applyLighting(config, active)
	for _, rule in ipairs(LIGHTING_RULES) do
		local property = rule.property

		if active and config[rule.flag] then
			if originals[property] == nil then
				originals[property] = lightingService[property]
			end
			setIfChanged(lightingService, property, config[rule.key])
		elseif originals[property] ~= nil then
			lightingService[property] = originals[property]
			originals[property] = nil
		end
	end
end

local function applyTechnology(config, active)
	if active and config.Technology then
		if originals.Technology == nil then
			local ok, value = pcall(gethiddenproperty, lightingService, "Technology")
			if not ok then return end
			originals.Technology = value
		end

		local target = Enum.Technology[config.TechnologyValue]
		local ok, value = pcall(gethiddenproperty, lightingService, "Technology")
		if target and ok and value ~= target then
			pcall(sethiddenproperty, lightingService, "Technology", target)
		end
		return
	end

	if originals.Technology ~= nil then
		pcall(sethiddenproperty, lightingService, "Technology", originals.Technology)
		originals.Technology = nil
	end
end

local function resolveFaces(config)
	local faces = {}

	if config.UseCustomSkybox then
		for index, face in ipairs(FACE_KEYS) do
			local value = config.CustomSkyboxFaces[face]
			faces[index] = value ~= "" and normalizeAsset(value) or false
		end
		return faces, "custom|" .. table.concat({
			tostring(faces[1]), tostring(faces[2]), tostring(faces[3]),
			tostring(faces[4]), tostring(faces[5]), tostring(faces[6])
		}, "|")
	end

	local data = SKYBOX_ASSETS[config.SelectedSky]
	if not data then
		return faces, "none"
	end

	for index, value in ipairs(data) do
		faces[index] = normalizeAsset(value)
	end
	return faces, "preset|" .. config.SelectedSky
end

local function applySky(config, active)
	local wantFaces = active and config.SkyChanger
	local wantParameters = active and config.SkyParameters
	local slot = slots.Sky

	if not (wantFaces or wantParameters) then
		return release(slot)
	end

	local sky = acquire(slot, SKY_DEFINITION)
	local faces, signature = resolveFaces(config)
	local appliedSignature = wantFaces and signature or "off"

	if slot.applied ~= appliedSignature then
		for index, property in ipairs(FACE_PROPERTIES) do
			if wantFaces and faces[index] then
				sky[property] = faces[index]
			else
				sky[property] = slot.snapshot[property]
			end
		end
		slot.applied = appliedSignature
	end

	for property, key in pairs(SKY_PARAMETERS) do
		local value = wantParameters and config[key] or slot.snapshot[property]
		setIfChanged(sky, property, value)
	end
end

local function applyEffect(config, active, definition)
	local slot = slots[definition.key]

	if not (active and config[definition.flag]) then
		return release(slot)
	end

	local instance = acquire(slot, definition)
	for property, key in pairs(definition.properties) do
		setIfChanged(instance, property, config[key])
	end
end

local function applyRemoval(config, active)
	if not (active and config.RemoveGameEffects) then
		for instance, wasEnabled in pairs(removed) do
			if instance.Parent then
				instance.Enabled = wasEnabled
			end
			removed[instance] = nil
		end
		return
	end

	local now = os.clock()
	if now - lastScan < SCAN_INTERVAL then return end
	lastScan = now

	local containers = { lightingService, workspaceService.CurrentCamera }
	for _, container in ipairs(containers) do
		for _, child in ipairs(container:GetChildren()) do
			if REMOVABLE_CLASSES[child.ClassName] and not owned[child] then
				if removed[child] == nil then
					removed[child] = child.Enabled
				end
				setIfChanged(child, "Enabled", false)
			end
		end
	end
end

function WorldVisuals:Update()
	local config = self.Config
	local active = config.Enabled

	applyLighting(config, active)
	applyTechnology(config, active)
	applySky(config, active)
	for _, definition in ipairs(EFFECTS) do
		applyEffect(config, active, definition)
	end
	applyRemoval(config, active)
end

function WorldVisuals:SetCustomSkybox(id, face)
	local faces = self.Config.CustomSkyboxFaces
	local value = tostring(id) == "" and "" or normalizeAsset(id)

	if face and faces[face] ~= nil then
		faces[face] = value
	else
		for _, key in ipairs(FACE_KEYS) do
			faces[key] = value
		end
	end

	slots.Sky.applied = nil
end

function WorldVisuals:GetConfig()
	return self.Config
end

function WorldVisuals:GetSkyboxList()
	return self.SkyboxNames
end

function WorldVisuals:GetTechnologyList()
	return TECHNOLOGY_LIST
end

function WorldVisuals:Load()
	if updateConnection then return self end

	updateConnection = runService.RenderStepped:Connect(function()
		self:Update()
	end)

	return self
end

function WorldVisuals:Unload()
	if updateConnection then
		updateConnection:Disconnect()
		updateConnection = nil
	end

	local config = self.Config
	applyLighting(config, false)
	applyTechnology(config, false)
	applySky(config, false)
	for _, definition in ipairs(EFFECTS) do
		applyEffect(config, false, definition)
	end
	applyRemoval(config, false)
end

genv.WorldVisuals = WorldVisuals

return WorldVisuals
