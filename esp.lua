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
local replicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local httpService = cloneref(game:GetService("HttpService"))

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

-- Baseline state.
local localPlayer = playersService.LocalPlayer
local currentCamera = workspaceService.CurrentCamera
local uiContainer = (gethui and gethui()) or coreGuiService

if not pcall(function() return uiContainer.Name end) then
	uiContainer = localPlayer:WaitForChild("PlayerGui")
end

-- Static Raycast optimization.
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
local currentRunId = httpService:GenerateGUID(false)
local labelStrokeMap = setmetatable({}, { __mode = "k" })
local loadedFonts = {}

local weaponDatabase = {}
local iconDatabase = {}

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
			if colorId then
				textures[colorId] = isHandle and 5 or 2
			end

			local packId = extractNumericId(desc.TexturePack)
			if packId then
				textures[packId] = isHandle and 5 or 2
			end

			local baseColorAttr = desc:GetAttribute("BaseColor")
			if baseColorAttr then
				local attrId = extractNumericId(tostring(baseColorAttr))
				if attrId then
					textures[attrId] = isHandle and 5 or 2
				end
			end
		elseif desc:IsA("MeshPart") and desc.TextureID ~= "" then
			local meshTexId = extractNumericId(desc.TextureID)
			if meshTexId then
				textures[meshTexId] = isHandle and 5 or 2
			end
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
	local count = 0

	local assets = replicatedStorage:FindFirstChild("Assets") or replicatedStorage:WaitForChild("Assets", 3)
	local prefabs = assets and (assets:FindFirstChild("Prefabs") or assets:WaitForChild("Prefabs", 3))
	local tools = prefabs and (prefabs:FindFirstChild("Tools") or prefabs:WaitForChild("Tools", 3))

	if not tools then return 0 end

	for _, toolFolder in ipairs(tools:GetChildren()) do
		if toolFolder.Name:find("ADMIN") then continue end

		local wm = toolFolder:FindFirstChild("Worldmodel") or toolFolder:FindFirstChild("WorldModel")
		if wm then
			local textures, parts = extractSignatures(wm)
			weaponDatabase[toolFolder.Name] = {
				Textures = textures,
				Parts = parts
			}
			count = count + 1
		end
	end

	return count
end

---Build 2D item icon database directly from crafting UI.
local function buildIconDatabase()
	table.clear(iconDatabase)
	local count = 0

	local playerGui = localPlayer:FindFirstChild("PlayerGui")
	if not playerGui then return 0 end

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

	if not scrollingFrame then return 0 end

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
			count = count + 1
		end
	end

	return count
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
	if not wm or #wm:GetChildren() == 0 then
		return nil, 0
	end

	local charTextures, charParts = extractSignatures(wm)
	local bestMatch = nil
	local highestScore = 0

	for weaponName, data in pairs(weaponDatabase) do
		local score = 0

		for texId, weight in pairs(charTextures) do
			if data.Textures[texId] then
				score = score + (weight * 10)
			end
		end

		for partName in pairs(charParts) do
			if data.Parts[partName] then
				score = score + (GENERIC_PARTS[partName] and 1 or 5)
			end
		end

		if score > highestScore then
			highestScore = score
			bestMatch = weaponName
		end
	end

	if highestScore >= 12 then
		return bestMatch, highestScore
	end

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

local function getBonePosition(character, boneName)
	local part = character:FindFirstChild(boneName)
	if part then return part.Position end

	if boneName == "Head" then
		part = character:FindFirstChild("Head")
	elseif boneName == "UpperTorso" or boneName == "LowerTorso" then
		part = character:FindFirstChild("Torso")
		if boneName == "LowerTorso" and part then return (part.CFrame * CFrame.new(0, -1.2, 0)).Position end
	elseif boneName:find("LeftUpperArm") or boneName:find("LeftLowerArm") or boneName:find("LeftHand") then
		part = character:FindFirstChild("Left Arm") or character:FindFirstChild("LeftArm")
		if part and boneName == "LeftLowerArm" then return (part.CFrame * CFrame.new(0, -0.8, 0)).Position end
		if part and boneName == "LeftHand" then return (part.CFrame * CFrame.new(0, -1.5, 0)).Position end
	elseif boneName:find("RightUpperArm") or boneName:find("RightLowerArm") or boneName:find("RightHand") then
		part = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightArm")
		if part and boneName == "RightLowerArm" then return (part.CFrame * CFrame.new(0, -0.8, 0)).Position end
		if part and boneName == "RightHand" then return (part.CFrame * CFrame.new(0, -1.5, 0)).Position end
	elseif boneName:find("LeftUpperLeg") or boneName:find("LeftLowerLeg") or boneName:find("LeftFoot") then
		part = character:FindFirstChild("Left Leg") or character:FindFirstChild("LeftLeg")
		if part and boneName == "LeftLowerLeg" then return (part.CFrame * CFrame.new(0, -0.8, 0)).Position end
		if part and boneName == "LeftFoot" then return (part.CFrame * CFrame.new(0, -1.5, 0)).Position end
	elseif boneName:find("RightUpperLeg") or boneName:find("RightLowerLeg") or boneName:find("RightFoot") then
		part = character:FindFirstChild("Right Leg") or character:FindFirstChild("RightLeg")
		if part and boneName == "RightLowerLeg" then return (part.CFrame * CFrame.new(0, -0.8, 0)).Position end
		if part and boneName == "RightFoot" then return (part.CFrame * CFrame.new(0, -1.5, 0)).Position end
	end
	return part and part.Position
end

local function fastVisCheck(rootPart, targetModel)
	visFilterInstances[1] = uiContainer
	visFilterInstances[2] = targetModel
	visFilterInstances[3] = localPlayer.Character
	visRaycastParams.FilterDescendantsInstances = visFilterInstances

	local origin = currentCamera.CFrame.Position
	return workspaceService:Raycast(origin, rootPart.Position - origin, visRaycastParams) == nil
end

local function resolveConfig(path, override)
	if override then
		local current = override
		local found = true
		for seg in path:gmatch("[^.]+") do
			if type(current) == "table" and current[seg] ~= nil then
				current = current[seg]
			else
				found = false
				break
			end
		end
		if found then return current end
	end

	local current = ESPConfig
	for seg in path:gmatch("[^.]+") do
		if type(current) ~= "table" then return nil end
		current = current[seg]
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
		FlagLabels = {}, LastVisCheck = 0, CachedModelVisible = true, LastWeaponCheck = 0,
		CachedWeapon = nil
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

	for i = 1, 5 do
		local flag = Instance.new("TextLabel")
		setupLabel(flag)
		flag.TextSize = ESPConfig.Flags.TextSize
		applyLabelFont(flag, ESPConfig.Flags.Font)
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

	espObj.Adornments = {}
	espObj.Highlight = nil
	espObj.MeshShell = nil
	espObj.MeshHighlight = nil

	espObj.Destroy = function()
		container:Destroy()
		if espObj.Highlight then espObj.Highlight:Destroy() end
		if espObj.MeshShell then espObj.MeshShell:Destroy() end
		for _, a in pairs(espObj.Adornments) do a:Destroy() end
	end

	return espObj
end)

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

local UpdateESPObj = LPHNoVirtualize(function(espObj, position, size, name, distanceStuds, instance, isCheap, nonHuman, noStatus, configOverride, onScreen, cfgCache)
	local function getCfg(path)
		local val = cfgCache[path]
		if val == nil then
			val = resolveConfig(path, configOverride)
			cfgCache[path] = val
		end
		return val
	end

	local now = os.clock()
	local humanoid = not nonHuman and instance:FindFirstChildOfClass("Humanoid") or nil
	local isDead = (humanoid and humanoid.Health <= 0)
	local chamsEnabled = getCfg("Chams.Enabled")

	-- Chams handling.
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
		applyLabelFont(espObj.Text, getCfg("Font"))
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

	-- Bounding Box drawing.
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

	-- Name.
	local nameY = y - textSize - (getCfg("TextGap") or 0) - topOffset
	if getCfg("Names") then
		espObj.Text.Position = UDim2.new(0, px - 50, 0, nameY)
		espObj.Text.Visible = true
	else
		espObj.Text.Visible = false
	end

	-- Distance.
	local currentBottomY = y + sy + (getCfg("Distance.Gap") or 0) + bottomOffset
	if getCfg("Distance.Enabled") then
		espObj.DistanceText.Visible = true
		espObj.DistanceText.Position = UDim2.new(0, px - 50, 0, currentBottomY)
		local distVal = getCfg("Distance.Unit") == "Meters" and math.floor(distanceStuds / getCfg("Distance.StudsPerMeter")) or math.floor(distanceStuds)
		espObj.DistanceText.Text = distVal .. getCfg("Distance.Ending")
		espObj.DistanceText.TextColor3 = getCfg("Distance.Color")
		espObj.DistanceText.TextSize = getCfg("Distance.TextSize") or textSize
		applyLabelFont(espObj.DistanceText, getCfg("Distance.Font"))
		applyTextOutline(espObj.DistanceText, getCfg("Distance.OutlineStyle") or textOutlineStyle, textOutlineColor)
		currentBottomY = currentBottomY + (getCfg("Distance.TextSize") or textSize) + (getCfg("Weapon.Gap") or 0)
	else
		espObj.DistanceText.Visible = false
	end

	-- Weapon Visuals (Text + 2D Icon).
	if getCfg("Weapon.Enabled") and instance:IsA("Model") then
		if (now - espObj.LastWeaponCheck) > 0.25 then
			espObj.LastWeaponCheck = now
			local detectedWeapon = resolveWeaponAccurate(instance)
			if not detectedWeapon and getCfg("Weapon.UseToolFallback") then
				local tool = instance:FindFirstChildOfClass("Tool")
				if tool then detectedWeapon = tool.Name end
			end
			espObj.CachedWeapon = detectedWeapon
		end

		local weaponName = espObj.CachedWeapon
		local showText = getCfg("Weapon.ShowText")
		local showIcon = getCfg("Weapon.ShowIcon")

		if weaponName and (showText or showIcon) then
			if showText then
				espObj.WeaponText.Visible = true
				espObj.WeaponText.Text = weaponName
				espObj.WeaponText.TextColor3 = getCfg("Weapon.Color")
				espObj.WeaponText.TextSize = getCfg("Weapon.TextSize") or textSize
				applyLabelFont(espObj.WeaponText, getCfg("Weapon.Font"))
				applyTextOutline(espObj.WeaponText, getCfg("Weapon.OutlineStyle") or textOutlineStyle, textOutlineColor)
				espObj.WeaponText.Position = UDim2.new(0, px - 50, 0, currentBottomY)
				currentBottomY = currentBottomY + (getCfg("Weapon.TextSize") or textSize) + (getCfg("Weapon.Gap") or 0)
			else
				espObj.WeaponText.Visible = false
			end

			if showIcon then
				local iconAsset = getWeaponIcon(weaponName)
				if iconAsset then
					local iconW = getCfg("Weapon.IconWidth") or 36
					local iconH = getCfg("Weapon.IconHeight") or 36
					espObj.WeaponIcon.Image = iconAsset
					espObj.WeaponIcon.Size = UDim2.new(0, iconW, 0, iconH)
					espObj.WeaponIcon.Position = UDim2.new(0, px - math.floor(iconW * 0.5), 0, currentBottomY)
					espObj.WeaponIcon.Visible = true
					currentBottomY = currentBottomY + iconH + (getCfg("Weapon.Gap") or 0)
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
	else
		espObj.WeaponText.Visible = false
		espObj.WeaponIcon.Visible = false
	end

	-- Health Bar & Health Number & Gradient.
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

		local showText = getCfg("HealthBar.ShowText")
		if getCfg("HealthBar.HideWhenFullHP") and health >= maxHealth then showText = false end
		local followColorText = showText and getCfg("HealthBar.FollowGradientColorText")
		local healthColor = Color3.fromHSV(healthPercent * 0.3, 1, 1)

		if getCfg("HealthBar.Gradient.Enabled") then
			espObj.HealthGradient.Enabled = true
			espObj.HealthGradient.Rotation = isHorizontal and 0 or 90
			espObj.HealthGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, getCfg("HealthBar.Gradient.Color1")),
				ColorSequenceKeypoint.new(0.5, getCfg("HealthBar.Gradient.Color2")),
				ColorSequenceKeypoint.new(1, getCfg("HealthBar.Gradient.Color3"))
			})
			espObj.HealthBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

			if followColorText then
				if healthPercent > 0.5 then
					healthColor = getCfg("HealthBar.Gradient.Color1"):Lerp(getCfg("HealthBar.Gradient.Color2"), (1 - healthPercent) * 2)
				else
					healthColor = getCfg("HealthBar.Gradient.Color2"):Lerp(getCfg("HealthBar.Gradient.Color3"), (0.5 - healthPercent) * 2)
				end
			end
		else
			espObj.HealthGradient.Enabled = false
			espObj.HealthBar.BackgroundColor3 = healthColor
		end

		if showText then
			espObj.HealthText.Visible = true
			espObj.HealthText.Text = tostring(math.floor(health))
			espObj.HealthText.TextSize = getCfg("HealthBar.TextSize")
			applyLabelFont(espObj.HealthText, getCfg("HealthBar.Font"))
			espObj.HealthText.TextColor3 = followColorText and healthColor or getCfg("TextColor")
			applyTextOutline(espObj.HealthText, getCfg("HealthBar.Outline.Style") or textOutlineStyle, textOutlineColor)

			if isHorizontal then
				local textY = espObj.HealthBarOutline.Position.Y.Offset
				espObj.HealthText.TextXAlignment = Enum.TextXAlignment.Center
				espObj.HealthText.Position = UDim2.new(0, getCfg("HealthBar.TextFollowBar") and (x + math.floor((sx + 1) * healthPercent) - 1) or (x + sx), 0, textY + (hpWidth * 0.5) + 1)
			else
				local barOutlineX = espObj.HealthBarOutline.Position.X.Offset
				espObj.HealthText.TextXAlignment = hpPos == "Left" and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
				local targetY = getCfg("HealthBar.TextFollowBar") and (y + (sy + 1) - math.floor((sy + 1) * healthPercent)) or y
				espObj.HealthText.Position = UDim2.new(0, hpPos == "Left" and (barOutlineX - 3) or (barOutlineX + hpWidth + 4), 0, targetY)
			end
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

---Fast 2D bounding box calculator.
---@param instance Instance
---@return boolean, Vector2?, Vector2?
local Get2DBoundingBox = LPHNoVirtualize(function(instance)
	local rootPart = instance:IsA("Model") and (instance:FindFirstChild("HumanoidRootPart") or instance:FindFirstChild("Torso") or instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart")) or (instance:IsA("BasePart") and instance)
	if not rootPart then return false, nil, nil end

	local rootPos = rootPart.Position
	local screenPos, onScreen = currentCamera:WorldToViewportPoint(rootPos)
	if not onScreen then return false, nil, nil end

	local humanoid = instance:IsA("Model") and instance:FindFirstChildOfClass("Humanoid")
	local isR6 = humanoid and humanoid.RigType == Enum.HumanoidRigType.R6

	local top2D = currentCamera:WorldToViewportPoint(rootPos + Vector3.new(0, isR6 and 2.8 or 3.0, 0))
	local bottom2D = currentCamera:WorldToViewportPoint(rootPos - Vector3.new(0, isR6 and 3.0 or 3.5, 0))
	local height = math.abs(top2D.Y - bottom2D.Y)
	local width = height * 0.65

	return true, Vector2.new(screenPos.X, (top2D.Y + bottom2D.Y) * 0.5), Vector2.new(width, height)
end)

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

	for key, config in pairs(ESPConfig.Directories) do
		local path = type(config) == "table" and config.Path or (type(config) == "string" and config or nil)
		if path then
			local folder = getInstanceFromPath(path)
			if folder then
				local children = (type(config) == "table" and config.Recursive) and folder:GetDescendants() or folder:GetChildren()
				for _, child in ipairs(children) do
					if child:IsA("Model") and not newTracked[child] then
						local humanoid = child:FindFirstChildOfClass("Humanoid")
						if humanoid and humanoid.Health > 0 then
							newTracked[child] = { name = child.Name, Cheap = false }
						end
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
local lastDbCheck = 0
local function runtimeStep()
	currentCamera = workspaceService.CurrentCamera or currentCamera
	local frameCfgCache = {}

	if not ESPConfig.Enabled then
		for _, data in pairs(trackedInstances) do
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

	if next(iconDatabase) == nil and now - lastDbCheck > 3 then
		lastDbCheck = now
		buildIconDatabase()
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
	lastDbCheck = 0

	buildWeaponDatabase()
	buildIconDatabase()

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
