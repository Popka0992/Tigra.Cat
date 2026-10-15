-- Check for table that is shared between executions.
if not shared then
	return warn("No shared, no script.")
end

-- Initialize Luraph globals if they do not exist.
loadstring("getfenv().LPH_NO_VIRTUALIZE = function(...) return ... end")()
getfenv().PP_SCRAMBLE_NUM = function(...) return ... end
getfenv().PP_SCRAMBLE_STR = function(...) return ... end
getfenv().PP_SCRAMBLE_RE_NUM = function(...) return ... end

---@module Features.Visuals.ESP
local ESP = {}
local LPHNoVirtualize = LPH_NO_VIRTUALIZE

-- Constants.
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

local GENERIC_PARTS = {
	["cube"] = true,
	["handle"] = true,
	["part"] = true,
	["mesh"] = true,
	["model"] = true,
	["worldmodel"] = true,
}

-- Services.
local cloneref = cloneref or function(instance) return instance end
local userInputService = cloneref(game:GetService("UserInputService"))
local runService = cloneref(game:GetService("RunService"))
local playersService = cloneref(game:GetService("Players"))
local coreGuiService = cloneref(game:GetService("CoreGui"))
local workspaceService = cloneref(game:GetService("Workspace"))
local replicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local httpService = cloneref(game:GetService("HttpService"))

-- State.
local localPlayer = playersService.LocalPlayer
local currentCamera = workspaceService.CurrentCamera
local uiContainer = (gethui and gethui()) or coreGuiService

if not pcall(function() return uiContainer.Name end) then
	uiContainer = localPlayer:WaitForChild("PlayerGui")
end

local visRaycastParams = RaycastParams.new()
visRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
visRaycastParams.IgnoreWater = true
local visFilterInstances = table.create(3)

local chamsContainer
local meshChamsFolder
local screenGui
local playerRemovingConnection
local inputBeganConnection
local trackedInstances = {}
local labelStrokeMap = setmetatable({}, { __mode = "k" })
local loadedFonts = {}
local weaponDatabase = {}
local iconDatabase = {}

if getgenv()["123ESP_Unload"] then
	pcall(getgenv()["123ESP_Unload"])
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
	Outlines = { Style = "Full", Color = Color3.fromRGB(0, 0, 0), Thickness = 1, Enabled = true },
	BoxFill = {
		Enabled = false,
		Color = Color3.fromRGB(255, 255, 255),
		Transparency = 0.9,
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
	Weapon = {
		Enabled = false,
		ShowText = true,
		ShowIcon = true,
		IconWidth = 36,
		IconHeight = 36,
		Gap = 2,
		OutlineStyle = "Full",
		Font = "Proggy Clean",
		TextSize = 12,
		Color = Color3.fromRGB(255, 255, 255),
		UseToolFallback = true,
	},
	Skeleton = {
		Enabled = false,
		Color = Color3.fromRGB(255, 255, 255),
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
	Directories = {
		["WorkspacePlayers"] = {
			Path = "Workspace.Players",
			Multiple = true,
			Recursive = false,
			NonHuman = false,
			Cheap = false
		}
	}
}

---Normalize string to lowercase alphanumeric characters.
---@param str string
---@return string
local function normalizeName(str)
	if not str then return "" end
	return (str:lower():gsub("[%s%-_]", ""))
end

---Extract numeric asset ID from string.
---@param str string
---@return string?
local function extractNumericId(str)
	if not str or typeof(str) ~= "string" or str == "" then return nil end
	return str:match("%d+")
end

---Collect texture IDs and part names from a model.
---@param container Instance
---@return table, table
local function extractSignatures(container)
	local textures = {}
	local parts = {}

	for _, desc in ipairs(container:GetDescendants()) do
		local parentName = desc.Parent and desc.Parent.Name:lower() or ""
		local isHandle = (parentName == "handle")

		if desc:IsA("SurfaceAppearance") then
			local colorId = extractNumericId(desc.ColorMap)
			if colorId then textures[colorId] = isHandle and 5 or 2 end

			local packId = extractNumericId(desc.TexturePack)
			if packId then textures[packId] = isHandle and 5 or 2 end

			local baseColorAttr = desc:GetAttribute("BaseColor")
			if baseColorAttr then
				local attrId = extractNumericId(tostring(baseColorAttr))
				if attrId then textures[attrId] = isHandle and 5 or 2 end
			end
		elseif desc:IsA("MeshPart") and desc.TextureID ~= "" then
			local meshTexId = extractNumericId(desc.TextureID)
			if meshTexId then textures[meshTexId] = isHandle and 5 or 2 end
		end

		if desc:IsA("BasePart") then
			parts[desc.Name:lower()] = true
		end
	end

	return textures, parts
end

---Build detailed signature database for every weapon tool.
local function buildWeaponDatabase()
	table.clear(weaponDatabase)
	local assets = replicatedStorage:FindFirstChild("Assets") or replicatedStorage:WaitForChild("Assets", 3)
	local prefabs = assets and (assets:FindFirstChild("Prefabs") or assets:WaitForChild("Prefabs", 3))
	local tools = prefabs and (prefabs:FindFirstChild("Tools") or prefabs:WaitForChild("Tools", 3))
	if not tools then return end

	for _, toolFolder in ipairs(tools:GetChildren()) do
		if toolFolder.Name:find("ADMIN") then continue end
		local wm = toolFolder:FindFirstChild("Worldmodel") or toolFolder:FindFirstChild("WorldModel")
		if wm then
			local textures, parts = extractSignatures(wm)
			weaponDatabase[toolFolder.Name] = { Textures = textures, Parts = parts }
		end
	end
end

---Build 2D item icon database directly from crafting UI.
local function buildIconDatabase()
	table.clear(iconDatabase)
	local playerGui = localPlayer:FindFirstChild("PlayerGui")
	if not playerGui then return end

	local ui = playerGui:FindFirstChild("UI")
	local ingame = ui and ui:FindFirstChild("Ingame")
	local crafting = ingame and ingame:FindFirstChild("Crafting")
	local items = crafting and crafting:FindFirstChild("Items")
	local scrollingFrame = items and items:FindFirstChild("ScrollingFrame")

	if not scrollingFrame then
		for _, desc in ipairs(playerGui:GetDescendants()) do
			if desc:IsA("ScrollingFrame") and desc.Parent and desc.Parent.Name == "Items" then
				scrollingFrame = desc
				break
			end
		end
	end
	if not scrollingFrame then return end

	for _, itemFrame in ipairs(scrollingFrame:GetChildren()) do
		if not itemFrame:IsA("GuiObject") then continue end
		local iconAsset = nil
		local btn = itemFrame:FindFirstChild("Button")

		if btn and (btn:IsA("ImageButton") or btn:IsA("ImageLabel")) and btn.Image ~= "" then
			iconAsset = btn.Image
		else
			for _, child in ipairs(itemFrame:GetChildren()) do
				if (child:IsA("ImageLabel") or child:IsA("ImageButton")) and child.Name ~= "Favorite" and child.Name ~= "Locked" and child.Image ~= "" then
					iconAsset = child.Image
					break
				end
			end
		end

		if iconAsset then
			local rawName = itemFrame.Name
			local normName = normalizeName(rawName)
			iconDatabase[rawName] = iconAsset
			iconDatabase[normName] = iconAsset
		end
	end
end

---Resolve weapon 2D icon by weapon name.
---@param name string
---@return string?
local function getWeaponIcon(name)
	if not name then return nil end
	if iconDatabase[name] then return iconDatabase[name] end
	local norm = normalizeName(name)
	if iconDatabase[norm] then return iconDatabase[norm] end

	for key, asset in pairs(iconDatabase) do
		if norm:find(key, 1, true) or key:find(norm, 1, true) then
			return asset
		end
	end
	return nil
end

---Resolve weapon held by character using weighted scoring.
---@param char Model
---@return string?, number?
local function resolveWeaponAccurate(char)
	local wm = char:FindFirstChild("Worldmodel") or char:FindFirstChild("WorldModel")
	if not wm or #wm:GetChildren() == 0 then return nil, 0 end

	local charTextures, charParts = extractSignatures(wm)
	local bestMatch = nil
	local highestScore = 0

	for weaponName, data in pairs(weaponDatabase) do
		local score = 0
		for texId, weight in pairs(charTextures) do
			if data.Textures[texId] then score = score + (weight * 10) end
		end
		for partName in pairs(charParts) do
			if data.Parts[partName] then score = score + (GENERIC_PARTS[partName] and 1 or 5) end
		end
		if score > highestScore then
			highestScore = score
			bestMatch = weaponName
		end
	end

	if highestScore >= 12 then return bestMatch, highestScore end
	return nil, highestScore
end

local function deepCopy(tbl)
	if type(tbl) ~= "table" then return tbl end
	local copy = {}
	for k, v in pairs(tbl) do copy[k] = deepCopy(v) end
	return copy
end

local function deepMerge(base, override)
	if type(override) ~= "table" then return base end
	for k, v in pairs(override) do
		if type(v) == "table" and type(base[k]) == "table" then
			deepMerge(base[k], v)
		else
			base[k] = v
		end
	end
	return base
end

local defaultESPConfig = deepCopy(ESPConfig)

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

---Apply custom FontFace or fallback to system Font enum.
---@param label TextLabel
---@param fontName string
local function applyLabelFont(label, fontName)
	local custom = loadedFonts[fontName]
	if custom then
		label.FontFace = custom
	else
		label.Font = FONT_MAP[fontName] or Enum.Font.Code
	end
end

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

---Check target visibility using Raycast.
---@param rootPart BasePart
---@param targetModel Instance
---@return boolean
local function fastVisCheck(rootPart, targetModel)
	visFilterInstances[1] = uiContainer
	visFilterInstances[2] = targetModel
	visFilterInstances[3] = localPlayer.Character
	visRaycastParams.FilterDescendantsInstances = visFilterInstances

	local origin = currentCamera.CFrame.Position
	return workspaceService:Raycast(origin, rootPart.Position - origin, visRaycastParams) == nil
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

local function applyTextOutline(label, style, color)
	local stroke = labelStrokeMap[label]
	if not stroke then return end
	if style == "None" then
		stroke.Enabled = false
	else
		stroke.Enabled = true
		stroke.Thickness = 1
		stroke.Color = color or Color3.fromRGB(0, 0, 0)
	end
end

local CreateESPObj = LPHNoVirtualize(function(name)
	local espObj = {
		Visible = false, Lines = {}, Outlines = {}, CornerLines = {}, CornerOutlines = {},
		LastVisCheck = 0, CachedModelVisible = true
	}

	local container = Instance.new("Frame")
	container.BackgroundTransparency = 1
	container.Name = "ESPObj"
	container.Parent = screenGui
	espObj.Container = container

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
		applyLabelFont(label, ESPConfig.Font)
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

	local weaponIcon = Instance.new("ImageLabel")
	weaponIcon.BackgroundTransparency = 1
	weaponIcon.ScaleType = Enum.ScaleType.Fit
	weaponIcon.ZIndex = 2
	weaponIcon.Visible = false
	weaponIcon.Parent = container
	espObj.WeaponIcon = weaponIcon

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
	healthText.Size = UDim2.new(0, 0, 0, 0)
	healthText.ZIndex = 3
	healthText.Visible = false
	espObj.HealthText = healthText

	espObj.Bones = {}
	for i = 1, #SKELETON_BONE_DEFS do
		local bone = Instance.new("Frame")
		bone.BorderSizePixel = 0
		bone.Visible = false
		bone.ZIndex = 2
		bone.Parent = container
		espObj.Bones[i] = bone
	end

	espObj.Adornments = {}
	espObj.Highlight = nil

	espObj.Destroy = function()
		container:Destroy()
		if espObj.Highlight then espObj.Highlight:Destroy() end
		for _, a in pairs(espObj.Adornments) do a:Destroy() end
	end

	return espObj
end)

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

---Cache all character joints for fast skeleton access.
---@param char Model
---@return table
local function cacheCharacterBones(char)
	local bones = {}
	for _, part in ipairs(char:GetChildren()) do
		if part:IsA("BasePart") then
			bones[part.Name] = part
		end
	end
	return bones
end

---Optimized screen-space projection calculation.
---@param rootPos Vector3
---@param dist number
---@param isR15 boolean
---@return boolean, Vector2?, Vector2?
local Get2DBoundingBoxFast = LPHNoVirtualize(function(rootPos, dist, isR15)
	local screenPos, onScreen = currentCamera:WorldToViewportPoint(rootPos)
	if not onScreen then return false, nil, nil end

	local fovRad = math.rad(currentCamera.FieldOfView * 0.5)
	local heightFactor = (currentCamera.ViewportSize.Y * 0.5) / (math.tan(fovRad) * dist)
	local height = math.floor(heightFactor * (isR15 and 5.8 or 5.2))
	local width = math.floor(height * 0.65)

	return true, Vector2.new(math.floor(screenPos.X), math.floor(screenPos.Y)), Vector2.new(width, height)
end)

local UpdateESPObj = LPHNoVirtualize(function(tracked, position, size, distanceStuds, onScreen)
	local espObj = tracked.espObj
	local humanoid = tracked.humanoid
	local instance = tracked.instance
	local now = os.clock()

	-- Chams.
	local chamsCfg = ESPConfig.Chams
	if chamsCfg.Enabled and humanoid and humanoid.Health > 0 then
		local visCheck = chamsCfg.VisibleCheck
		local mainColor = chamsCfg.Color
		local visibleColor = chamsCfg.VisibleColor

		if visCheck and (now - espObj.LastVisCheck) > (ESPConfig.VisibilityCheckRate or 0.25) then
			espObj.LastVisCheck = now
			if tracked.rootPart then
				espObj.CachedModelVisible = fastVisCheck(tracked.rootPart, instance)
			end
		end

		if chamsCfg.Type == "Highlight" then
			if not espObj.Highlight then
				espObj.Highlight = Instance.new("Highlight")
				espObj.Highlight.Parent = chamsContainer
			end
			local h = espObj.Highlight
			h.Adornee = instance
			h.FillColor = (visCheck and espObj.CachedModelVisible) and visibleColor or mainColor
			h.FillTransparency = chamsCfg.Highlight.FillTransparency
			h.OutlineColor = chamsCfg.OutlineColor
			h.OutlineTransparency = chamsCfg.Highlight.OutlineTransparency
			h.DepthMode = visCheck and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
			h.Enabled = true
		end
	else
		if espObj.Highlight then espObj.Highlight.Enabled = false end
	end

	if not onScreen or not position or not size then
		espObj.Container.Visible = false
		return
	end

	espObj.Container.Visible = true

	local px, py = position.X, position.Y
	local sx, sy = size.X, size.Y
	local x, y = math.floor(px - sx * 0.5), math.floor(py - sy * 0.5)

	local health, maxHealth, healthPercent = 100, 100, 1
	if humanoid then
		health = humanoid.Health
		maxHealth = humanoid.MaxHealth
		healthPercent = math.clamp(health / maxHealth, 0, 1)
	end

	local t = ESPConfig.BoxThickness
	local o = ESPConfig.Outlines.Thickness

	-- Bounding Box.
	if ESPConfig.Boxes then
		if ESPConfig.BoxType == "Normal" then
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
				espObj.Lines[i].BackgroundColor3 = ESPConfig.BoxColor
				if ESPConfig.Outlines.Enabled then
					espObj.Outlines[i].Visible = true
					espObj.Outlines[i].Position = UDim2.new(0, -o, 0, -o)
					espObj.Outlines[i].Size = UDim2.new(1, o * 2, 1, o * 2)
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
				espObj.CornerLines[i].BackgroundColor3 = ESPConfig.BoxColor
			end
		end
	else
		for i = 1, 4 do espObj.Lines[i].Visible = false end
		for i = 1, 8 do espObj.CornerLines[i].Visible = false end
	end

	-- Name.
	if ESPConfig.Names then
		espObj.Text.Position = UDim2.new(0, px - 50, 0, y - ESPConfig.TextSize - (ESPConfig.TextGap or 0))
		espObj.Text.Visible = true
	else
		espObj.Text.Visible = false
	end

	-- Distance.
	local currentBottomY = y + sy + (ESPConfig.Distance.Gap or 0)
	if ESPConfig.Distance.Enabled then
		espObj.DistanceText.Visible = true
		espObj.DistanceText.Position = UDim2.new(0, px - 50, 0, currentBottomY)
		local distVal = ESPConfig.Distance.Unit == "Meters" and math.floor(distanceStuds / ESPConfig.Distance.StudsPerMeter) or math.floor(distanceStuds)
		espObj.DistanceText.Text = distVal .. ESPConfig.Distance.Ending
		currentBottomY = currentBottomY + ESPConfig.Distance.TextSize + ESPConfig.Weapon.Gap
	else
		espObj.DistanceText.Visible = false
	end

	-- Weapon.
	local weaponName = tracked.cachedWeapon
	if ESPConfig.Weapon.Enabled and weaponName then
		if ESPConfig.Weapon.ShowText then
			espObj.WeaponText.Visible = true
			espObj.WeaponText.Text = weaponName
			espObj.WeaponText.Position = UDim2.new(0, px - 50, 0, currentBottomY)
			currentBottomY = currentBottomY + ESPConfig.Weapon.TextSize + ESPConfig.Weapon.Gap
		else
			espObj.WeaponText.Visible = false
		end

		if ESPConfig.Weapon.ShowIcon then
			local iconAsset = getWeaponIcon(weaponName)
			if iconAsset then
				local iconW = ESPConfig.Weapon.IconWidth
				local iconH = ESPConfig.Weapon.IconHeight
				espObj.WeaponIcon.Image = iconAsset
				espObj.WeaponIcon.Size = UDim2.new(0, iconW, 0, iconH)
				espObj.WeaponIcon.Position = UDim2.new(0, px - math.floor(iconW * 0.5), 0, currentBottomY)
				espObj.WeaponIcon.Visible = true
			else
				espObj.WeaponIcon.Visible = false
			end
		else
			espObj.WeaponIcon.Visible = false
		end
	else
		espObj.WeaponText.Visible = false
		espObj.WeaponIcon.Visible = false
	end

	-- Health Bar.
	if ESPConfig.HealthBar.Enabled and humanoid then
		local hpWidth = ESPConfig.HealthBar.Width
		local hpSideGap = ESPConfig.HealthBar.SideGap
		local barHeight = math.floor((sy + 1) * healthPercent)

		espObj.HealthBarOutline.Visible = true
		espObj.HealthBarOutline.Size = UDim2.new(0, hpWidth + 2, 0, sy + 3)
		espObj.HealthBarOutline.Position = UDim2.new(0, x - o - hpSideGap - hpWidth - 1, 0, y - 1)
		espObj.HealthBarContainer.Size = UDim2.new(0, hpWidth, 0, barHeight)
		espObj.HealthBarContainer.Position = UDim2.new(0, 1, 0, (sy + 1) - barHeight + 1)
		espObj.HealthBar.Size = UDim2.new(0, hpWidth, 0, sy + 1)
		espObj.HealthBar.Position = UDim2.new(0, 0, 0, -(sy + 1 - barHeight))

		if ESPConfig.HealthBar.ShowText and (not ESPConfig.HealthBar.HideWhenFullHP or health < maxHealth) then
			espObj.HealthText.Visible = true
			espObj.HealthText.Text = tostring(math.floor(health))
			espObj.HealthText.Position = UDim2.new(0, x - o - hpSideGap - hpWidth - 4, 0, y + (sy + 1) - barHeight)
		else
			espObj.HealthText.Visible = false
		end
	else
		espObj.HealthBarOutline.Visible = false
		espObj.HealthText.Visible = false
	end

	-- Skeleton.
	if ESPConfig.Skeleton.Enabled and tracked.bones then
		local color = ESPConfig.Skeleton.Color
		for i, def in ipairs(SKELETON_BONE_DEFS) do
			local pA = tracked.bones[def[1]]
			local pB = tracked.bones[def[2]]
			if pA and pB then
				local spA, onA = currentCamera:WorldToViewportPoint(pA.Position)
				local spB, onB = currentCamera:WorldToViewportPoint(pB.Position)
				if onA and onB then
					DrawLine(espObj.Bones[i], spA, spB, 1, color)
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

---Register an entity to the tracked table.
---@param char Model
---@param name string
---@param cheap boolean
local function trackEntity(char, name, cheap)
	if trackedInstances[char] then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local rootPart = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChild("Torso")
	local isR15 = humanoid and (humanoid.RigType == Enum.HumanoidRigType.R15) or false

	local tracked = {
		instance = char,
		humanoid = humanoid,
		rootPart = rootPart,
		isR15 = isR15,
		name = name,
		cheap = cheap,
		espObj = CreateESPObj(name),
		cachedWeapon = nil,
		bones = cacheCharacterBones(char),
		connections = {},
	}

	local function updateWeapon()
		local detected = resolveWeaponAccurate(char)
		if not detected and ESPConfig.Weapon.UseToolFallback then
			local tool = char:FindFirstChildOfClass("Tool")
			if tool then detected = tool.Name end
		end
		tracked.cachedWeapon = detected
	end

	table.insert(tracked.connections, char.ChildAdded:Connect(function(child)
		if child:IsA("BasePart") then
			tracked.bones[child.Name] = child
		elseif child:IsA("Tool") or child.Name:lower():find("worldmodel") then
			task.defer(updateWeapon)
		end
	end))

	table.insert(tracked.connections, char.ChildRemoved:Connect(function(child)
		if child:IsA("BasePart") then
			tracked.bones[child.Name] = nil
		elseif child:IsA("Tool") or child.Name:lower():find("worldmodel") then
			task.defer(updateWeapon)
		end
	end))

	updateWeapon()
	trackedInstances[char] = tracked
end

---Untrack and clean up entity.
---@param char Model
local function untrackEntity(char)
	local tracked = trackedInstances[char]
	if not tracked then return end

	for _, conn in ipairs(tracked.connections) do
		conn:Disconnect()
	end
	tracked.espObj:Destroy()
	trackedInstances[char] = nil
end

local function getInstanceFromPath(path)
	local current = game
	for part in path:gmatch("[^.]+") do
		if current == game and (part == "Workspace" or part == "workspace") then
			current = workspaceService
		elseif current == game and part == "Players" then
			current = playersService
		else
			current = current:FindFirstChild(part)
			if not current then return nil end
		end
	end
	return current ~= game and current or nil
end

local ScanDirectories = LPHNoVirtualize(function()
	local active = {}

	if ESPConfig.Players then
		for _, player in ipairs(playersService:GetPlayers()) do
			if not ESPConfig.LocalPlayer and player == localPlayer then continue end
			if ESPConfig.TeamCheck and localPlayer.Team and player.Team == localPlayer.Team then continue end
			local char = player.Character
			if char and char.Parent then
				active[char] = true
				if not trackedInstances[char] then
					trackEntity(char, player.DisplayName or player.Name, false)
				end
			end
		end
	end

	if ESPConfig.Bots then
		for _, child in ipairs(workspaceService:GetChildren()) do
			if child:IsA("Model") and child ~= localPlayer.Character and not active[child] then
				local humanoid = child:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					active[child] = true
					if not trackedInstances[child] then
						trackEntity(child, (ESPConfig.BotTag or "[BOT] ") .. child.Name, false)
					end
				end
			end
		end
	end

	for _, config in pairs(ESPConfig.Directories) do
		local path = type(config) == "table" and config.Path or (type(config) == "string" and config or nil)
		if path then
			local folder = getInstanceFromPath(path)
			if folder then
				local children = (type(config) == "table" and config.Recursive) and folder:GetDescendants() or folder:GetChildren()
				for _, child in ipairs(children) do
					if child:IsA("Model") and not active[child] then
						local humanoid = child:FindFirstChildOfClass("Humanoid")
						if humanoid and humanoid.Health > 0 then
							active[child] = true
							if not trackedInstances[child] then
								trackEntity(child, child.Name, false)
							end
						end
					end
				end
			end
		end
	end

	for char in pairs(trackedInstances) do
		if not active[char] or not char.Parent then
			untrackEntity(char)
		end
	end
end)

local lastScan = 0
local function runtimeStep()
	if not ESPConfig.Enabled then
		for _, tracked in pairs(trackedInstances) do
			if tracked.espObj.Container.Visible then
				tracked.espObj.Container.Visible = false
			end
		end
		return
	end

	currentCamera = workspaceService.CurrentCamera or currentCamera
	local now = os.clock()

	if now - lastScan > 1.5 then
		lastScan = now
		ScanDirectories()
	end

	local camPos = currentCamera.CFrame.Position
	for char, tracked in pairs(trackedInstances) do
		local humanoid = tracked.humanoid
		if not char.Parent or (humanoid and humanoid.Health <= 0) then
			untrackEntity(char)
			continue
		end

		local rootPart = tracked.rootPart
		if rootPart and rootPart.Parent then
			local dist = (camPos - rootPart.Position).Magnitude
			local onScreen, pos2d, size2d = Get2DBoundingBoxFast(rootPart.Position, dist, tracked.isR15)
			UpdateESPObj(tracked, pos2d, size2d, dist, onScreen)
		else
			tracked.espObj.Container.Visible = false
		end
	end
end

---Unload and destroy all ESP instances.
function ESP:Unload()
	for char in pairs(trackedInstances) do
		untrackEntity(char)
	end
	if playerRemovingConnection then playerRemovingConnection:Disconnect(); playerRemovingConnection = nil end
	if inputBeganConnection then inputBeganConnection:Disconnect(); inputBeganConnection = nil end
	if getgenv()["123ESP_Loop"] then getgenv()["123ESP_Loop"]:Disconnect(); getgenv()["123ESP_Loop"] = nil end
	if screenGui then screenGui:Destroy(); screenGui = nil end
	if chamsContainer then chamsContainer:Destroy(); chamsContainer = nil end
	if meshChamsFolder then meshChamsFolder:Destroy(); meshChamsFolder = nil end
	getgenv()["123ESP_UI"] = nil
end

---Load ESP instance with optional configuration.
---@param config table?
---@return table
function ESP:Load(config)
	self:Unload()
	ESPConfig = deepMerge(deepCopy(defaultESPConfig), config or {})
	ensureRootInstances()
	lastScan = 0

	buildWeaponDatabase()
	buildIconDatabase()

	playerRemovingConnection = playersService.PlayerRemoving:Connect(function(player)
		for char in pairs(trackedInstances) do
			if playersService:GetPlayerFromCharacter(char) == player then
				untrackEntity(char)
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
