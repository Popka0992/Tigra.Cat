-- Check for table that is shared between executions.
if not shared then
	return warn("No shared, no script.")
end

-- Initialize Luraph globals if they do not exist.
loadstring("getfenv().LPH_NO_VIRTUALIZE = function(...) return ... end")()
getfenv().PP_SCRAMBLE_NUM = function(...) return ... end
getfenv().PP_SCRAMBLE_STR = function(...) return ... end
getfenv().PP_SCRAMBLE_RE_NUM = function(...) return ... end

-- Services.
local cloneref = cloneref or function(instance) return instance end
local userInputService = cloneref(game:GetService("UserInputService"))
local runService = cloneref(game:GetService("RunService"))
local playersService = cloneref(game:GetService("Players"))
local coreGuiService = cloneref(game:GetService("CoreGui"))
local workspaceService = cloneref(game:GetService("Workspace"))
local httpService = cloneref(game:GetService("HttpService"))

---@module Features.Visuals.ESP
local ESP = {}
local LPHNoVirtualize = LPH_NO_VIRTUALIZE

-- Constants.
local HEAD_OFFSET = Vector3.new(0, 2.6, 0)
local FEET_OFFSET = Vector3.new(0, 3.2, 0)
local STATIC_FILTER_ARRAY = table.create(3)
local SKELETON_BONE_DEFS = {
	{ "UpperTorso", "LowerTorso" }, { "Head", "UpperTorso" },
	{ "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
}

local FONT_MAP = {
	["Proggy Clean"] = Enum.Font.SourceSans,
	["Smallest Pixel-7"] = Enum.Font.SourceSans,
	["Tahoma"] = Enum.Font.SourceSans,
	["Minecraftia"] = Enum.Font.SourceSans,
	["Tahoma Modern Bold"] = Enum.Font.SourceSansBold,
}

local FONTS_TO_DOWNLOAD = {
	["Tahoma"] = "https://github.com/LuckyHub1/LuckyHub/raw/main/zekton_rg.ttf",
	["Minecraftia"] = "https://github.com/LuckyHub1/LuckyHub/raw/refs/heads/main/Minecraftia.ttf",
	["Smallest Pixel-7"] = "https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/smallest_pixel-7.ttf",
	["Proggy Clean"] = "https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/ProggyClean.ttf",
	["Tahoma Modern Bold"] = "https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/Tahoma-Modern-Bold.ttf",
}

-- Baseline state.
local localPlayer = playersService.LocalPlayer
local currentCamera = workspaceService.CurrentCamera
local uiContainer = (gethui and gethui()) or coreGuiService
local currentRunId = httpService:GenerateGUID(false)
local labelStrokeMap = setmetatable({}, { __mode = "k" })
local loadedFonts = {}

-- Static RaycastParams to prevent GC allocations per check.
local visRaycastParams = RaycastParams.new()
visRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
visRaycastParams.IgnoreWater = true

local chamsContainer
local meshChamsFolder
local screenGui
local playerRemovingConnection
local inputBeganConnection
local trackedInstances = {}

-- Clean up older sessions.
if getgenv()["123ESP_Unload"] then
	pcall(getgenv()["123ESP_Unload"])
end

local function isMeshChamArtifact(obj)
	if not obj then return false end
	return obj:GetAttribute("123ESP_MeshCham") == true 
		or (obj:IsA("Model") and obj.Name == "ChamShells")
		or (obj:IsA("BasePart") and obj.Name:sub(1, 10) == "ChamShell_")
		or (obj:IsA("Highlight") and obj.Name == "ChamShellHighlight")
end

local function cleanupCharacterMeshChams(character)
	if not character then return end
	for _, child in ipairs(character:GetChildren()) do
		if isMeshChamArtifact(child) then
			pcall(child.Destroy, child)
		end
	end
end

local function ensureRootInstances()
	if not chamsContainer or not chamsContainer.Parent then
		chamsContainer = Instance.new("Folder")
		chamsContainer.Name = "123ESP_Chams"
		chamsContainer.Parent = uiContainer
	end

	if not meshChamsFolder or not meshChamsFolder.Parent then
		meshChamsFolder = Instance.new("Folder")
		meshChamsFolder.Name = "123ESP_MeshChams"
		meshChamsFolder.Parent = workspaceService
	end

	if not screenGui or not screenGui.Parent then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "123ESP"
		screenGui.ResetOnSpawn = false
		screenGui.IgnoreGuiInset = true
		screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
		screenGui.Parent = uiContainer
		getgenv()["123ESP_UI"] = screenGui
	end
end

local ESPConfig = {
	Enabled = false,
	Keybind = { Enabled = false, Key = Enum.KeyCode.Insert },
	Players = true,
	LocalPlayer = false,
	Bots = true,
	BotTag = "[BOT] ",
	TeamCheck = false,
	LimitFPS = 0,
	DynamicBoxes = false,
	VisibilityCheckRate = 0.25,
	Boxes = false,
	BoxType = "Normal",
	BoxColor = Color3.fromRGB(255, 255, 255),
	BoxThickness = 1,
	Outlines = { Style = "Full", Color = Color3.fromRGB(0, 0, 0), Thickness = 1 },
	BoxFill = {
		Enabled = false,
		Color = Color3.fromRGB(255, 255, 255),
		Transparency = 0.9,
		Gradient = {
			Enabled = false,
			Color1 = Color3.fromRGB(180, 255, 255),
			Color2 = Color3.fromRGB(0, 255, 255),
			Color3 = Color3.fromRGB(0, 120, 255),
			Rotation = 0,
			Animated = false,
			Speed = 64,
			Direction = "Right",
		}
	},
	HealthBar = {
		Enabled = false,
		Position = "Left",
		SideGap = 2,
		Width = 2,
		ShowText = false,
		TextFollowBar = false,
		HideWhenFullHP = false,
		FollowGradientColorText = false,
		Font = "Smallest Pixel-7",
		TextSize = 9,
		Outline = { Style = "Full", Color = Color3.fromRGB(0, 0, 0) },
		Gradient = {
			Enabled = false,
			Color1 = Color3.fromRGB(0, 255, 0),
			Color2 = Color3.fromRGB(255, 255, 0),
			Color3 = Color3.fromRGB(255, 0, 0),
		}
	},
	Names = false,
	TextSize = 12,
	TextColor = Color3.fromRGB(255, 255, 255),
	TextOutline = true,
	TextOutlineStyle = "Full",
	TextOutlineColor = Color3.fromRGB(0, 0, 0),
	TextGap = 3,
	Font = "Proggy Clean",
	TeamIndicator = {
		Enabled = false,
		Position = "Right",
		UseTeamColor = false,
		Color = Color3.fromRGB(255, 255, 255),
		Compact = false,
		TextSize = 10,
	},
	FriendlyIndicator = {
		Enabled = false,
		Position = "Right",
		CheckTeam = false,
		CheckFriends = false,
		Text = "[F]",
		Color = Color3.fromRGB(0, 255, 0),
	},
	Weapon = {
		Enabled = false,
		Gap = 1,
		OutlineStyle = "Full",
		Font = "Proggy Clean",
		TextSize = 12,
		Color = Color3.fromRGB(255, 255, 255),
		UseToolFallback = true,
	},
	Flags = {
		Enabled = false,
		Position = "Right",
		Gap = 2,
		SideGap = 4,
		TextGap = 2,
		OutlineStyle = "Full",
		Font = "Smallest Pixel-7",
		TextSize = 9,
		Options = { Idle = false, Moving = false, Jumping = false, Swimming = false },
		Colors = {
			Idle = Color3.fromRGB(255, 255, 255),
			Moving = Color3.fromRGB(255, 255, 255),
			Jumping = Color3.fromRGB(255, 255, 255),
			Swimming = Color3.fromRGB(65, 65, 255),
		}
	},
	Skeleton = {
		Enabled = false,
		Color = Color3.fromRGB(255, 255, 255),
		Outline = false,
		OutlineColor = Color3.fromRGB(0, 0, 0),
	},
	OffScreenArrows = {
		Enabled = false,
		Size = 14,
		Color = Color3.fromRGB(255, 255, 255),
		OrbitRadius = 100,
		ArrowMode = "Camera",
		Outline = false,
		OutlineColor = Color3.fromRGB(0, 0, 0),
		Names = {
			Enabled = false,
			Font = "Smallest Pixel-7",
			TextSize = 9,
			Color = Color3.fromRGB(255, 255, 255),
			Outline = true,
			OutlineColor = Color3.fromRGB(0, 0, 0),
			Side = "Bottom",
			Gap = 4,
		},
		Distance = {
			Enabled = false,
			Font = "Smallest Pixel-7",
			TextSize = 9,
			Color = Color3.fromRGB(255, 255, 255),
			Outline = false,
			OutlineColor = Color3.fromRGB(0, 0, 0),
			Side = "Bottom",
			Gap = 2,
		},
	},
	Distance = {
		Enabled = false,
		Unit = "Meters",
		StudsPerMeter = 3,
		Ending = "m",
		Gap = 3,
		OutlineStyle = "Full",
		Font = "Proggy Clean",
		TextSize = 12,
		Color = Color3.fromRGB(255, 255, 255),
	},
	Chams = {
		Enabled = false,
		Type = "MeshChams",
		Color = Color3.fromRGB(59, 144, 204),
		OutlineColor = Color3.fromRGB(255, 255, 255),
		VisibleColor = Color3.fromRGB(59, 204, 90),
		VisibleCheck = false,
		Highlight = { FillTransparency = 0.3, OutlineTransparency = 0 },
		Adornment = { Transparency = 0.5 },
		MeshChams = { FillTransparency = 0.4, OutlineTransparency = 0 },
	},
	Directories = {}
}

local function deepCopy(tbl)
	if type(tbl) ~= "table" then return tbl end
	local copy = {}
	for key, value in pairs(tbl) do copy[key] = deepCopy(value) end
	return copy
end

local function deepMerge(base, override)
	if type(override) ~= "table" then return base end
	for key, value in pairs(override) do
		if type(value) == "table" and type(base[key]) == "table" then
			deepMerge(base[key], value)
		else
			base[key] = value
		end
	end
	return base
end

local defaultESPConfig = deepCopy(ESPConfig)

local function colorToHex(color)
	local r = math.clamp(math.floor(color.R * 255 + 0.5), 0, 255)
	local g = math.clamp(math.floor(color.G * 255 + 0.5), 0, 255)
	local b = math.clamp(math.floor(color.B * 255 + 0.5), 0, 255)
	return string.format("#%02X%02X%02X", r, g, b)
end

-- Asynchronous font loader.
task.spawn(function()
	if not (writefile and isfile and getcustomasset) then return end
	for name, link in pairs(FONTS_TO_DOWNLOAD) do
		local fileName = name:gsub("%s+", "")
		if not isfile(fileName .. ".ttf") then
			local success, data = pcall(function() return game:HttpGet(link) end)
			if success and data and #data > 0 then
				writefile(fileName .. ".ttf", data)
				local cfg = { name = fileName, faces = { { name = "Regular", weight = 400, style = "normal", assetId = getcustomasset(fileName .. ".ttf") } } }
				writefile(fileName .. ".ttf.json", httpService:JSONEncode(cfg))
			end
		end
		if isfile(fileName .. ".ttf.json") then
			local ok, font = pcall(Font.new, getcustomasset(fileName .. ".ttf.json"), Enum.FontWeight.Regular)
			if ok and font then loadedFonts[name] = font end
		end
	end
end)

local DrawLine = LPHNoVirtualize(function(line, p1, p2, thickness, color)
	local diffX = p2.X - p1.X
	local diffY = p2.Y - p1.Y
	local dist = math.sqrt(diffX * diffX + diffY * diffY)

	line.Size = UDim2.new(0, math.floor(dist + 0.5), 0, thickness)
	line.Position = UDim2.new(0, math.floor(p1.X + diffX * 0.5 - dist * 0.5 + 0.5), 0, math.floor(p1.Y + diffY * 0.5 - thickness * 0.5 + 0.5))
	line.Rotation = math.deg(math.atan2(diffY, diffX))
	line.BackgroundColor3 = color
	line.Visible = true
end)

local function getBonePosition(character, boneName)
	local part = character:FindFirstChild(boneName)
	if part then return part.Position end

	if boneName == "Head" then
		part = character:FindFirstChild("Head")
	elseif boneName == "UpperTorso" or boneName == "LowerTorso" then
		part = character:FindFirstChild("Torso")
		if boneName == "LowerTorso" and part then return (part.CFrame * CFrame.new(0, -1.2, 0)).Position end
	end
	return part and part.Position
end

local function fastVisCheck(rootPart, targetModel)
	STATIC_FILTER_ARRAY[1] = uiContainer
	STATIC_FILTER_ARRAY[2] = targetModel
	STATIC_FILTER_ARRAY[3] = localPlayer.Character
	visRaycastParams.FilterDescendantsInstances = STATIC_FILTER_ARRAY

	local origin = currentCamera.CFrame.Position
	return workspaceService:Raycast(origin, rootPart.Position - origin, visRaycastParams) == nil
end

---Fast string traversal without allocations.
---@param path string
---@param override table?
---@return any
local function resolveConfigFast(path, override)
	if override then
		local current = override
		local found = true
		for segment in path:gmatch("[^.]+") do
			if type(current) == "table" and current[segment] ~= nil then
				current = current[segment]
			else
				found = false
				break
			end
		end
		if found then return current end
	end

	local current = ESPConfig
	for segment in path:gmatch("[^.]+") do
		if type(current) ~= "table" then return nil end
		current = current[segment]
	end
	return current
end

local function createLine(parent)
	local line = Instance.new("Frame")
	line.BorderSizePixel = 0
	line.BackgroundColor3 = ESPConfig.BoxColor
	line.Parent = parent

	local outline = Instance.new("Frame")
	outline.BorderSizePixel = 0
	outline.BackgroundColor3 = ESPConfig.Outlines.Color
	outline.ZIndex = 0
	outline.Parent = line
	return line, outline
end

local CreateESPObj = LPHNoVirtualize(function(name)
	local espObj = {
		Visible = false, Lines = {}, Outlines = {}, CornerLines = {}, CornerOutlines = {},
		FlagLabels = {}, LastVisCheck = 0, CachedModelVisible = true
	}

	local container = Instance.new("Frame")
	container.BackgroundTransparency = 1
	container.Name = "ESPObj"
	container.Parent = screenGui
	espObj.Container = container

	local boxFill = Instance.new("Frame")
	boxFill.BorderSizePixel = 0
	boxFill.ZIndex = 0
	boxFill.Visible = false
	boxFill.Parent = container
	espObj.BoxFill = boxFill

	local fillGradient = Instance.new("UIGradient")
	fillGradient.Parent = boxFill
	espObj.BoxFillGradient = fillGradient

	for i = 1, 4 do
		local line, outline = createLine(container)
		espObj.Lines[i] = line
		espObj.Outlines[i] = outline
	end

	for i = 1, 8 do
		local line, outline = createLine(container)
		line.Visible = false
		outline.Visible = false
		espObj.CornerLines[i] = line
		espObj.CornerOutlines[i] = outline
	end

	local function setupLabel(label)
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(0, 100, 0, ESPConfig.TextSize)
		label.Font = FONT_MAP[ESPConfig.Font] or Enum.Font.Code
		if loadedFonts[ESPConfig.Font] then label.FontFace = loadedFonts[ESPConfig.Font] end
		label.TextSize = ESPConfig.TextSize
		label.TextColor3 = ESPConfig.TextColor
		label.TextStrokeTransparency = 1
		label.ZIndex = 2
		label.Parent = container

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1
		stroke.Color = ESPConfig.TextOutlineColor or ESPConfig.Outlines.Color
		stroke.LineJoinMode = Enum.LineJoinMode.Miter
		stroke.Enabled = ESPConfig.TextOutline
		stroke.Parent = label
		labelStrokeMap[label] = stroke
	end

	local nameText = Instance.new("TextLabel")
	setupLabel(nameText)
	nameText.TextYAlignment = Enum.TextYAlignment.Bottom
	nameText.RichText = true
	nameText.Text = name
	nameText.Visible = ESPConfig.Names
	espObj.Text = nameText

	local distText = Instance.new("TextLabel")
	setupLabel(distText)
	distText.TextYAlignment = Enum.TextYAlignment.Top
	distText.Visible = false
	espObj.DistanceText = distText

	local weaponText = Instance.new("TextLabel")
	setupLabel(weaponText)
	weaponText.TextYAlignment = Enum.TextYAlignment.Top
	weaponText.Visible = false
	espObj.WeaponText = weaponText

	local healthBarOutline = Instance.new("Frame")
	healthBarOutline.BackgroundColor3 = ESPConfig.Outlines.Color
	healthBarOutline.BorderSizePixel = 0
	healthBarOutline.Visible = false
	healthBarOutline.ZIndex = 1
	healthBarOutline.Parent = container
	espObj.HealthBarOutline = healthBarOutline

	local healthBarContainer = Instance.new("Frame")
	healthBarContainer.BackgroundTransparency = 1
	healthBarContainer.ClipsDescendants = true
	healthBarContainer.BorderSizePixel = 0
	healthBarContainer.ZIndex = 2
	healthBarContainer.Parent = healthBarOutline
	espObj.HealthBarContainer = healthBarContainer

	local healthBar = Instance.new("Frame")
	healthBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	healthBar.BorderSizePixel = 0
	healthBar.ZIndex = 2
	healthBar.Parent = healthBarContainer
	espObj.HealthBar = healthBar

	local healthGradient = Instance.new("UIGradient")
	healthGradient.Enabled = false
	healthGradient.Parent = healthBar
	espObj.HealthGradient = healthGradient

	local healthText = Instance.new("TextLabel")
	setupLabel(healthText)
	healthText.TextYAlignment = Enum.TextYAlignment.Center
	healthText.ZIndex = 3
	healthText.Visible = false
	espObj.HealthText = healthText

	for i = 1, 5 do
		local flag = Instance.new("TextLabel")
		setupLabel(flag)
		flag.TextSize = ESPConfig.Flags.TextSize
		flag.Font = FONT_MAP[ESPConfig.Flags.Font] or Enum.Font.Code
		if loadedFonts[ESPConfig.Flags.Font] then flag.FontFace = loadedFonts[ESPConfig.Flags.Font] end
		flag.Visible = false
		espObj.FlagLabels[i] = flag
	end

	espObj.Bones = {}
	espObj.BoneOutlines = {}
	for i = 1, #SKELETON_BONE_DEFS do
		local outline = Instance.new("Frame")
		outline.BorderSizePixel = 0
		outline.Visible = false
		outline.ZIndex = 1
		outline.Parent = container
		espObj.BoneOutlines[i] = outline

		local bone = Instance.new("Frame")
		bone.BorderSizePixel = 0
		bone.Visible = false
		bone.ZIndex = 2
		bone.Parent = container
		espObj.Bones[i] = bone
	end

	local arrowInner = Instance.new("TextLabel")
	arrowInner.BackgroundTransparency = 1
	arrowInner.Text = "▲"
	arrowInner.TextColor3 = ESPConfig.OffScreenArrows.Color
	arrowInner.TextSize = ESPConfig.OffScreenArrows.Size
	arrowInner.Font = Enum.Font.SourceSans
	arrowInner.Size = UDim2.new(0, ESPConfig.OffScreenArrows.Size * 2, 0, ESPConfig.OffScreenArrows.Size * 2)
	arrowInner.ZIndex = 100
	arrowInner.Visible = false
	arrowInner.Parent = screenGui
	espObj.ArrowInner = arrowInner

	local arrowOutline = Instance.new("TextLabel")
	arrowOutline.BackgroundTransparency = 1
	arrowOutline.Text = "▲"
	arrowOutline.TextColor3 = ESPConfig.OffScreenArrows.OutlineColor
	arrowOutline.TextSize = ESPConfig.OffScreenArrows.Size + 2
	arrowOutline.Font = Enum.Font.SourceSans
	arrowOutline.Size = UDim2.new(0, (ESPConfig.OffScreenArrows.Size + 2) * 2, 0, (ESPConfig.OffScreenArrows.Size + 2) * 2)
	arrowOutline.ZIndex = 99
	arrowOutline.Visible = false
	arrowOutline.Parent = screenGui
	espObj.ArrowOutline = arrowOutline

	local function makeArrowLabel()
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.new(0, 150, 0, 12)
		l.TextStrokeTransparency = 1
		l.ZIndex = 110
		l.TextColor3 = Color3.fromRGB(255, 255, 255)
		l.Visible = false
		l.Parent = screenGui
		local stroke = Instance.new("UIStroke")
		stroke.Parent = l
		labelStrokeMap[l] = stroke
		return l
	end
	espObj.ArrowName = makeArrowLabel()
	espObj.ArrowDist = makeArrowLabel()

	espObj.Adornments = {}
	espObj.Highlight = nil

	espObj.Destroy = function()
		container:Destroy()
		if espObj.Highlight then espObj.Highlight:Destroy() end
		if espObj.MeshShell then espObj.MeshShell:Destroy() end
		for _, a in pairs(espObj.Adornments) do a:Destroy() end
		if espObj.ArrowInner then espObj.ArrowInner:Destroy() end
		if espObj.ArrowOutline then espObj.ArrowOutline:Destroy() end
		if espObj.ArrowName then espObj.ArrowName:Destroy() end
		if espObj.ArrowDist then espObj.ArrowDist:Destroy() end
	end

	return espObj
end)

local function applyTextOutline(label, style, color)
	local stroke = labelStrokeMap[label]
	if not stroke then return end
	if style == "None" then
		if stroke.Enabled then stroke.Enabled = false end
	else
		if not stroke.Enabled then stroke.Enabled = true end
		stroke.Thickness = 1
		stroke.Color = color or Color3.fromRGB(0, 0, 0)
	end
end

local UpdateESPObj = LPHNoVirtualize(function(espObj, position, size, name, distanceStuds, instance, isCheap, nonHuman, noStatus, configOverride, onScreen, cfgCache)
	local function getCfg(path)
		local val = cfgCache[path]
		if val == nil then
			val = resolveConfigFast(path, configOverride)
			cfgCache[path] = val
		end
		return val
	end

	local now = os.clock()
	local humanoid = not nonHuman and instance:FindFirstChildOfClass("Humanoid") or nil
	local isDead = (humanoid and humanoid.Health <= 0)
	local chamsEnabled = getCfg("Chams.Enabled")

	if chamsEnabled and not isDead then
		local chamType = getCfg("Chams.Type")
		local visCheck = getCfg("Chams.VisibleCheck")
		local mainColor = getCfg("Chams.Color")
		local outlineColor = getCfg("Chams.OutlineColor")
		local visibleColor = getCfg("Chams.VisibleColor")

		if visCheck and (now - espObj.LastVisCheck) > (getCfg("VisibilityCheckRate") or 0.25) then
			espObj.LastVisCheck = now
			local root = instance:IsA("Model") and (instance.PrimaryPart or instance:FindFirstChild("HumanoidRootPart") or instance:FindFirstChildWhichIsA("BasePart")) or instance
			if root and root:IsA("BasePart") then
				espObj.CachedModelVisible = fastVisCheck(root, instance)
			end
		end

		if chamType ~= "Highlight" and espObj.Highlight then espObj.Highlight:Destroy(); espObj.Highlight = nil end
		if chamType ~= "MeshChams" and espObj.MeshShell then espObj.MeshShell:Destroy(); espObj.MeshShell = nil; espObj.MeshHighlight = nil end
		if chamType ~= "Adornment" and espObj.Adornments then for _, a in pairs(espObj.Adornments) do a.Visible = false end end

		if chamType == "Highlight" and (instance:IsA("Model") or instance:IsA("BasePart")) then
			if not espObj.Highlight then espObj.Highlight = Instance.new("Highlight") end
			local h = espObj.Highlight
			h.Parent = chamsContainer
			h.Adornee = instance
			h.FillColor = (visCheck and espObj.CachedModelVisible) and visibleColor or mainColor
			h.FillTransparency = getCfg("Chams.Highlight.FillTransparency")
			h.OutlineColor = outlineColor
			h.OutlineTransparency = getCfg("Chams.Highlight.OutlineTransparency")
			h.DepthMode = visCheck and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
			h.Enabled = true

		elseif chamType == "Adornment" then
			local parts = instance:IsA("Model") and instance:GetChildren() or { instance }
			local idx = 0
			local finalColor = (visCheck and espObj.CachedModelVisible) and visibleColor or mainColor

			for _, p in ipairs(parts) do
				if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
					idx = idx + 1
					local a = espObj.Adornments[idx]
					if not a then
						a = Instance.new("BoxHandleAdornment")
						a.Name = "Cham"
						a.Parent = uiContainer
						espObj.Adornments[idx] = a
					end
					a.Adornee = p
					a.Size = p.Size
					a.Color3 = finalColor
					a.Transparency = getCfg("Chams.Adornment.Transparency")
					a.AlwaysOnTop = not visCheck
					a.ZIndex = 10
					a.Visible = true
				end
			end
			for i = idx + 1, #espObj.Adornments do espObj.Adornments[i].Visible = false end

		elseif chamType == "MeshChams" and instance:IsA("Model") then
			if not espObj.MeshShell or not espObj.MeshShell.Parent then
				if espObj.MeshShell then espObj.MeshShell:Destroy() end
				cleanupCharacterMeshChams(instance)

				local isR15 = humanoid and (humanoid.RigType == Enum.HumanoidRigType.R15)
				local bodyParts = isR15 and {
					"Head", "UpperTorso", "LowerTorso",
					"LeftUpperArm", "LeftLowerArm", "LeftHand",
					"RightUpperArm", "RightLowerArm", "RightHand",
					"LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
					"RightUpperLeg", "RightLowerLeg", "RightFoot",
				} or { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }

				local shellModel = Instance.new("Model")
				shellModel.Name = "ChamShells"
				shellModel:SetAttribute("123ESP_MeshCham", true)
				shellModel.Parent = instance

				for _, partName in ipairs(bodyParts) do
					local realPart = instance:FindFirstChild(partName)
					if realPart and realPart:IsA("BasePart") then
						local shell = Instance.new("Part")
						shell.Name = "ChamShell_" .. partName
						shell:SetAttribute("123ESP_MeshCham", true)
						shell.Size = realPart.Size * 1.015
						shell.Transparency = 0.9999999
						shell.CastShadow = false
						shell.CanCollide = false
						shell.CanQuery = false
						shell.CanTouch = false
						shell.Anchored = false
						shell.Massless = true
						shell.CFrame = realPart.CFrame
						shell.Parent = shellModel

						local weld = Instance.new("Weld")
						weld.Part0 = shell
						weld.Part1 = realPart
						weld.Parent = shell
					end
				end

				local hl = Instance.new("Highlight")
				hl.Name = "ChamShellHighlight"
				hl:SetAttribute("123ESP_MeshCham", true)
				hl.Adornee = shellModel
				hl.Parent = shellModel
				espObj.MeshShell = shellModel
				espObj.MeshHighlight = hl
			end

			if espObj.MeshHighlight then
				local hl = espObj.MeshHighlight
				hl.FillColor = (visCheck and espObj.CachedModelVisible) and visibleColor or mainColor
				hl.FillTransparency = getCfg("Chams.MeshChams.FillTransparency")
				hl.OutlineColor = outlineColor
				hl.OutlineTransparency = getCfg("Chams.MeshChams.OutlineTransparency")
				hl.DepthMode = visCheck and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
				hl.Enabled = true
			end
		end
	else
		if espObj.Highlight then espObj.Highlight:Destroy(); espObj.Highlight = nil end
		if espObj.Adornments then for _, a in pairs(espObj.Adornments) do a.Visible = false end end
		if espObj.MeshShell then espObj.MeshShell:Destroy(); espObj.MeshShell = nil; espObj.MeshHighlight = nil end
	end

	-- Screen visibility check.
	if not onScreen or not position or not size then
		espObj.Container.Visible = false
		return
	end

	espObj.Container.Visible = true
	espObj.Container.ZIndex = nonHuman and 1 or 10

	local textOutlineStyle = getCfg("TextOutline") == false and "None" or getCfg("TextOutlineStyle")
	local textOutlineColor = getCfg("TextOutlineColor") or getCfg("Outlines.Color")
	local t = getCfg("BoxThickness")
	local o = getCfg("Outlines.Thickness")
	local textSize = getCfg("TextSize")

	if getCfg("Names") then
		espObj.Text.Text = name
		espObj.Text.TextSize = textSize
		espObj.Text.TextColor3 = getCfg("TextColor")
		espObj.Text.Font = FONT_MAP[getCfg("Font")] or Enum.Font.Code
		if loadedFonts[getCfg("Font")] then espObj.Text.FontFace = loadedFonts[getCfg("Font")] end
		applyTextOutline(espObj.Text, textOutlineStyle, textOutlineColor)
	end

	local px, py = math.floor(position.X), math.floor(position.Y)
	local sx, sy = math.floor(size.X), math.floor(size.Y)
	local x, y = math.floor(px - sx * 0.5), math.floor(py - sy * 0.5)

	local health, maxHealth, healthPercent = 100, 100, 1
	if humanoid then
		health = humanoid.Health
		maxHealth = humanoid.MaxHealth
		healthPercent = math.clamp(health / maxHealth, 0, 1)
	end

	local topOffset, bottomOffset = 0, 0
	if getCfg("HealthBar.Enabled") and instance:IsA("Model") and humanoid then
		local hpPos = getCfg("HealthBar.Position")
		local thickness = getCfg("HealthBar.Width") + 2 + getCfg("HealthBar.SideGap")
		if hpPos == "Top" then topOffset = thickness
		elseif hpPos == "Bottom" then bottomOffset = thickness end
	end

	if isCheap then
		for i = 1, 4 do espObj.Lines[i].Visible = false; espObj.Outlines[i].Visible = false end
		espObj.HealthBarOutline.Visible = false; espObj.HealthText.Visible = false; espObj.WeaponText.Visible = false
		for _, l in ipairs(espObj.FlagLabels) do l.Visible = false end
		local distVal = getCfg("Distance.Unit") == "Meters" and math.floor(distanceStuds / getCfg("Distance.StudsPerMeter")) or math.floor(distanceStuds)
		espObj.Text.Text = name .. " " .. distVal .. getCfg("Distance.Ending")
		espObj.Text.Position = UDim2.new(0, px - 50, 0, py - (textSize * 0.5))
		espObj.Text.Visible = getCfg("Names")
		espObj.DistanceText.Visible = false
		return
	end

	-- Bounding boxes.
	local boxesEnabled = getCfg("Boxes")
	local useCornerBoxes = getCfg("BoxType") == "Corner"
	local hasOutline = getCfg("Outlines.Style") ~= "None" and getCfg("Outlines.Enabled") ~= false

	if boxesEnabled then
		if not useCornerBoxes then
			espObj.Lines[1].Position = UDim2.new(0, x, 0, y)
			espObj.Lines[1].Size = UDim2.new(0, sx, 0, t)

			espObj.Lines[2].Position = UDim2.new(0, x, 0, y + sy)
			espObj.Lines[2].Size = UDim2.new(0, sx + t, 0, t)

			espObj.Lines[3].Position = UDim2.new(0, x, 0, y)
			espObj.Lines[3].Size = UDim2.new(0, t, 0, sy)

			espObj.Lines[4].Position = UDim2.new(0, x + sx, 0, y)
			espObj.Lines[4].Size = UDim2.new(0, t, 0, sy + t)

			for i = 1, 4 do
				espObj.Lines[i].Visible = true
				espObj.Lines[i].BackgroundColor3 = getCfg("BoxColor")
				if hasOutline then
					espObj.Outlines[i].Visible = true
					espObj.Outlines[i].Position = UDim2.new(0, -o, 0, -o)
					espObj.Outlines[i].Size = UDim2.new(1, o * 2, 1, o * 2)
					espObj.Outlines[i].BackgroundColor3 = getCfg("Outlines.Color")
				else
					espObj.Outlines[i].Visible = false
				end
			end
		else
			local cw, ch = math.max(math.floor(sx * 0.25), t * 3), math.max(math.floor(sy * 0.25), t * 3)
			local cornerData = {
				{ x, y, cw, t }, { x, y, t, ch },
				{ x + sx - cw + t, y, cw, t }, { x + sx, y, t, ch },
				{ x, y + sy, cw, t }, { x, y + sy - ch + t, t, ch },
				{ x + sx - cw + t, y + sy, cw, t }, { x + sx, y + sy - ch + t, t, ch },
			}
			for i = 1, 8 do
				espObj.CornerLines[i].Position = UDim2.new(0, cornerData[i][1], 0, cornerData[i][2])
				espObj.CornerLines[i].Size = UDim2.new(0, cornerData[i][3], 0, cornerData[i][4])
				espObj.CornerLines[i].Visible = true
				espObj.CornerLines[i].BackgroundColor3 = getCfg("BoxColor")

				if hasOutline then
					espObj.CornerOutlines[i].Visible = true
					espObj.CornerOutlines[i].Position = UDim2.new(0, -o, 0, -o)
					espObj.CornerOutlines[i].Size = UDim2.new(1, o * 2, 1, o * 2)
					espObj.CornerOutlines[i].BackgroundColor3 = getCfg("Outlines.Color")
				else
					espObj.CornerOutlines[i].Visible = false
				end
			end
		end
	else
		for i = 1, 4 do espObj.Lines[i].Visible = false; espObj.Outlines[i].Visible = false end
		for i = 1, 8 do espObj.CornerLines[i].Visible = false; espObj.CornerOutlines[i].Visible = false end
	end

	-- Box Fill.
	local fill = espObj.BoxFill
	if getCfg("BoxFill.Enabled") and boxesEnabled then
		fill.Visible = true
		fill.Position = UDim2.new(0, x, 0, y)
		fill.Size = UDim2.new(0, sx, 0, sy)
		fill.BackgroundTransparency = getCfg("BoxFill.Transparency")
		fill.BackgroundColor3 = getCfg("BoxFill.Color")
	else
		fill.Visible = false
	end

	-- Text elements.
	local nameY = y - textSize - (getCfg("TextGap") or 0) - topOffset
	if getCfg("Names") then
		espObj.Text.Position = UDim2.new(0, px - 50, 0, nameY)
		espObj.Text.Visible = true
	else
		espObj.Text.Visible = false
	end

	local currentBottomY = y + sy + (getCfg("Distance.Gap") or 0) + bottomOffset
	if getCfg("Distance.Enabled") then
		espObj.DistanceText.Visible = true
		espObj.DistanceText.Position = UDim2.new(0, px - 50, 0, currentBottomY)
		local distVal = getCfg("Distance.Unit") == "Meters" and math.floor(distanceStuds / getCfg("Distance.StudsPerMeter")) or math.floor(distanceStuds)
		espObj.DistanceText.Text = distVal .. getCfg("Distance.Ending")
		currentBottomY = currentBottomY + (getCfg("Distance.TextSize") or textSize) + (getCfg("Weapon.Gap") or 0)
	else
		espObj.DistanceText.Visible = false
	end

	if getCfg("Weapon.Enabled") then
		local tool = instance:FindFirstChildWhichIsA("Tool")
		if tool then
			espObj.WeaponText.Visible = true
			espObj.WeaponText.Text = tool.Name
			espObj.WeaponText.Position = UDim2.new(0, px - 50, 0, currentBottomY)
		else
			espObj.WeaponText.Visible = false
		end
	else
		espObj.WeaponText.Visible = false
	end

	-- Health Bar.
	if getCfg("HealthBar.Enabled") and instance:IsA("Model") and humanoid then
		local hpPos = getCfg("HealthBar.Position")
		local hpWidth = getCfg("HealthBar.Width")
		local hpSideGap = getCfg("HealthBar.SideGap")
		local isHorizontal = (hpPos == "Top" or hpPos == "Bottom")

		espObj.HealthBarOutline.Visible = true
		espObj.HealthBarOutline.BackgroundColor3 = getCfg("HealthBar.Outline.Color")

		if isHorizontal then
			local barWidth = math.floor((sx + 1) * healthPercent)
			espObj.HealthBarOutline.Size = UDim2.new(0, sx + 3, 0, hpWidth + 2)
			espObj.HealthBarOutline.Position = UDim2.new(0, x - 1, 0, hpPos == "Top" and (y - o - hpSideGap - hpWidth - 1) or (y + sy + o + hpSideGap))
			espObj.HealthBarContainer.Size = UDim2.new(0, barWidth, 0, hpWidth)
			espObj.HealthBar.Size = UDim2.new(0, sx + 1, 0, hpWidth)
		else
			local barHeight = math.floor((sy + 1) * healthPercent)
			espObj.HealthBarOutline.Size = UDim2.new(0, hpWidth + 2, 0, sy + 3)
			espObj.HealthBarOutline.Position = UDim2.new(0, hpPos == "Left" and (x - o - hpSideGap - hpWidth - 1) or (x + sx + o + hpSideGap), 0, y - 1)
			espObj.HealthBarContainer.Size = UDim2.new(0, hpWidth, 0, barHeight)
			espObj.HealthBarContainer.Position = UDim2.new(0, 1, 0, (sy + 1) - barHeight + 1)
			espObj.HealthBar.Size = UDim2.new(0, hpWidth, 0, sy + 1)
			espObj.HealthBar.Position = UDim2.new(0, 0, 0, -(sy + 1 - barHeight))
		end

		espObj.HealthBar.BackgroundColor3 = Color3.fromHSV(healthPercent * 0.3, 1, 1)

		if getCfg("HealthBar.ShowText") and health < maxHealth then
			espObj.HealthText.Visible = true
			espObj.HealthText.Text = math.floor(health)
			local barOutlineX = espObj.HealthBarOutline.Position.X.Offset
			espObj.HealthText.Position = UDim2.new(0, hpPos == "Left" and (barOutlineX - 2) or (barOutlineX + hpWidth + 4), 0, y)
		else
			espObj.HealthText.Visible = false
		end
	else
		espObj.HealthBarOutline.Visible = false
		espObj.HealthText.Visible = false
	end

	-- Skeletons.
	if getCfg("Skeleton.Enabled") and instance:IsA("Model") then
		local skeletonColor = getCfg("Skeleton.Color")
		for i, def in ipairs(SKELETON_BONE_DEFS) do
			local pA = getBonePosition(instance, def[1])
			local pB = getBonePosition(instance, def[2])
			if pA and pB then
				local spA, onA = currentCamera:WorldToViewportPoint(pA)
				local spB, onB = currentCamera:WorldToViewportPoint(pB)
				if onA and onB then
					DrawLine(espObj.Bones[i], spA, spB, 1, skeletonColor)
				else
					espObj.Bones[i].Visible = false
				end
			else
				espObj.Bones[i].Visible = false
			end
		end
	else
		for _, b in ipairs(espObj.Bones) do b.Visible = false end
	end
end)

---Optimized zero-allocation 2D bounding box calculator.
---@param instance Instance
---@return boolean, Vector2?, Vector2?
local Get2DBoundingBox = LPHNoVirtualize(function(instance)
	local rootPart = instance:IsA("Model") and (instance.PrimaryPart or instance:FindFirstChild("HumanoidRootPart") or instance:FindFirstChild("Torso")) or (instance:IsA("BasePart") and instance)
	if not rootPart then return false, nil, nil end

	local rootPos = rootPart.Position
	local topScreen, topOn = currentCamera:WorldToViewportPoint(rootPos + HEAD_OFFSET)
	local bottomScreen, bottomOn = currentCamera:WorldToViewportPoint(rootPos - FEET_OFFSET)

	if not topOn and not bottomOn then return false, nil, nil end

	local height = math.abs(topScreen.Y - bottomScreen.Y)
	local width = height * 0.65

	return true, Vector2.new((topScreen.X + bottomScreen.X) * 0.5, (topScreen.Y + bottomScreen.Y) * 0.5), Vector2.new(width, height)
end)

local ScanDirectories = LPHNoVirtualize(function()
	local newTracked = {}

	if ESPConfig.Players then
		for _, player in ipairs(playersService:GetPlayers()) do
			if not ESPConfig.LocalPlayer and player == localPlayer then continue end
			if ESPConfig.TeamCheck and localPlayer.Team and player.Team == localPlayer.Team then continue end
			local char = player.Character
			if char then
				local humanoid = char:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					newTracked[char] = { name = player.DisplayName or player.Name, Cheap = false }
				end
			end
		end
	end

	if ESPConfig.Bots then
		for _, child in ipairs(workspaceService:GetChildren()) do
			if child:IsA("Model") and child ~= localPlayer.Character and not newTracked[child] then
				local player = playersService:GetPlayerFromCharacter(child)
				if not player then
					local humanoid = child:FindFirstChildOfClass("Humanoid")
					local root = child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart
					if humanoid and root and humanoid.Health > 0 then
						newTracked[child] = { name = (ESPConfig.BotTag or "[BOT] ") .. child.Name, Cheap = false }
					end
				end
			end
		end
	end

	for inst, data in pairs(newTracked) do
		if not trackedInstances[inst] then
			trackedInstances[inst] = { espObj = CreateESPObj(data.name), name = data.name, Cheap = data.Cheap }
		else
			trackedInstances[inst].name = data.name
			trackedInstances[inst].Cheap = data.Cheap
		end
	end

	for inst, data in pairs(trackedInstances) do
		if not newTracked[inst] or not inst.Parent then
			data.espObj:Destroy()
			trackedInstances[inst] = nil
		end
	end
end)

local lastScan = 0
local function runtimeStep()
	currentCamera = workspaceService.CurrentCamera or currentCamera
	local frameCfgCache = {}

	if not ESPConfig.Enabled then
		for inst, data in pairs(trackedInstances) do
			if data.espObj and data.espObj.Container.Visible then
				data.espObj.Container.Visible = false
			end
		end
		return
	end

	local now = os.clock()
	if now - lastScan > 1.5 then
		lastScan = now
		ScanDirectories()
	end

	for inst, data in pairs(trackedInstances) do
		if not inst or not inst.Parent then
			data.espObj:Destroy()
			trackedInstances[inst] = nil
			continue
		end

		local humanoid = inst:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health <= 0 then
			data.espObj:Destroy()
			trackedInstances[inst] = nil
			continue
		end

		local rootPart = inst:IsA("Model") and (inst.PrimaryPart or inst:FindFirstChild("HumanoidRootPart") or inst:FindFirstChild("Torso")) or inst
		if rootPart and rootPart:IsA("BasePart") then
			local onScreen, pos2d, size2d = Get2DBoundingBox(inst)
			local dist = (currentCamera.CFrame.Position - rootPart.Position).Magnitude
			UpdateESPObj(data.espObj, pos2d, size2d, data.name, dist, inst, data.Cheap, false, false, nil, onScreen, frameCfgCache)
		else
			UpdateESPObj(data.espObj, nil, nil, data.name, 0, inst, data.Cheap, false, false, nil, false, frameCfgCache)
		end
	end
end

---Unload and destroy all ESP instances.
function ESP:Unload()
	for inst, data in pairs(trackedInstances) do
		if data.espObj then data.espObj:Destroy() end
		trackedInstances[inst] = nil
	end
	if playerRemovingConnection then playerRemovingConnection:Disconnect(); playerRemovingConnection = nil end
	if inputBeganConnection then inputBeganConnection:Disconnect(); inputBeganConnection = nil end
	if getgenv()["123ESP_Loop"] then getgenv()["123ESP_Loop"]:Disconnect(); getgenv()["123ESP_Loop"] = nil end
	if screenGui then screenGui:Destroy(); screenGui = nil end
	if chamsContainer then chamsContainer:Destroy(); chamsContainer = nil end
	if meshChamsFolder then meshChamsFolder:Destroy(); meshChamsFolder = nil end

	for _, player in ipairs(playersService:GetPlayers()) do cleanupCharacterMeshChams(player.Character) end
	getgenv()["123ESP_UI"] = nil
end

---Load ESP instance with optional configuration.
---@param config table?
---@return table
function ESP:Load(config)
	self:Unload()
	ESPConfig = deepMerge(deepCopy(defaultESPConfig), config or {})
	ensureRootInstances()
	currentRunId = httpService:GenerateGUID(false)
	lastScan = 0

	playerRemovingConnection = playersService.PlayerRemoving:Connect(function(player)
		for inst, data in pairs(trackedInstances) do
			if playersService:GetPlayerFromCharacter(inst) == player then
				data.espObj:Destroy()
				trackedInstances[inst] = nil
			end
		end
	end)

	inputBeganConnection = userInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and ESPConfig.Keybind.Enabled and input.KeyCode == ESPConfig.Keybind.Key then
			ESPConfig.Enabled = not ESPConfig.Enabled
		end
	end)

	getgenv()["123ESP_Loop"] = runService.RenderStepped:Connect(runtimeStep)
	ScanDirectories()
	return self
end

---Retrieve current configuration table.
---@return table
function ESP:GetConfig()
	return ESPConfig
end

getgenv()["123ESP_Unload"] = function() ESP:Unload() end

return ESP
