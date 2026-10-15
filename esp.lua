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

-- Baseline state.
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
local screenGui
local playerRemovingConnection
local inputBeganConnection
local trackedInstances = {}
local labelStrokeMap = setmetatable({}, { __mode = "k" })
local loadedFonts = {}
local weaponDatabase = {}
local iconDatabase = {}
local iconDatabaseScanned = false

if getgenv()["123ESP_Unload"] then
	pcall(getgenv()["123ESP_Unload"])
end

local function ensureRootInstances()
	if not chamsContainer or not chamsContainer.Parent then
		chamsContainer = Instance.new("Folder")
		chamsContainer.Name = "123ESP_Chams"
		chamsContainer.Parent = uiContainer
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
	VisibilityCheckRate = 0.5,
	Boxes = false,
	BoxType = "Normal",
	BoxColor = Color3.fromRGB(255, 255, 255),
	BoxThickness = 1,
	Outlines = { Style = "Full", Color = Color3.fromRGB(0, 0, 0), Thickness = 1 },
	HealthBar = {
		Enabled = false,
		Position = "Left",
		SideGap = 2,
		Width = 2,
		ShowText = false,
		TextFollowBar = false,
		HideWhenFullHP = false,
		Font = "Smallest Pixel-7",
		TextSize = 9,
		Outline = { Style = "Full", Color = Color3.fromRGB(0, 0, 0) },
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
		ShowIcon = false,
		Gap = 2,
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
		Font = "Proggy Clean",
		TextSize = 12,
		Color = Color3.fromRGB(255, 255, 255),
	},
	Chams = {
		Enabled = false,
		Type = "Highlight",
		Color = Color3.fromRGB(59, 144, 204),
		OutlineColor = Color3.fromRGB(255, 255, 255),
		VisibleColor = Color3.fromRGB(59, 204, 90),
		VisibleCheck = false,
		Highlight = { FillTransparency = 0.3, OutlineTransparency = 0 },
	},
	Directories = {}
}

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

local function applyLabelFont(label, fontName)
	local custom = loadedFonts[fontName]
	if custom then
		label.FontFace = custom
	else
		label.Font = FONT_MAP[fontName] or Enum.Font.Code
	end
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

local function cacheCharacterBones(character)
	local boneCache = {}
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local isR15 = humanoid and humanoid.RigType == Enum.HumanoidRigType.R15

	if isR15 then
		for _, def in ipairs(SKELETON_BONE_DEFS) do
			boneCache[def[1]] = character:FindFirstChild(def[1])
			boneCache[def[2]] = character:FindFirstChild(def[2])
		end
	else
		boneCache["Head"] = character:FindFirstChild("Head")
		boneCache["UpperTorso"] = character:FindFirstChild("Torso")
		boneCache["LowerTorso"] = character:FindFirstChild("Torso")
		boneCache["LeftUpperArm"] = character:FindFirstChild("Left Arm")
		boneCache["RightUpperArm"] = character:FindFirstChild("Right Arm")
		boneCache["LeftUpperLeg"] = character:FindFirstChild("Left Leg")
		boneCache["RightUpperLeg"] = character:FindFirstChild("Right Leg")
	end
	return boneCache
end

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

local CreateESPObj = LPHNoVirtualize(function(name)
	local espObj = {
		Visible = false, Lines = {}, Outlines = {}, CornerLines = {}, CornerOutlines = {},
		LastVisCheck = 0, CachedModelVisible = true, LastWeaponCheck = 0,
		CachedWeapon = nil, BoneCache = nil
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
		stroke.Color = ESPConfig.TextOutlineColor
		stroke.LineJoinMode = Enum.LineJoinMode.Miter
		stroke.Enabled = ESPConfig.TextOutline
		stroke.Parent = label
		labelStrokeMap[label] = stroke
	end

	local nameText = Instance.new("TextLabel")
	setupLabel(nameText)
	nameText.TextYAlignment = Enum.TextYAlignment.Bottom
	nameText.RichText = false
	nameText.Text = name
	nameText.Visible = false
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
	healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	healthBar.BorderSizePixel = 0
	healthBar.ZIndex = 2
	healthBar.Parent = healthBarContainer
	espObj.HealthBar = healthBar

	espObj.Bones = {}
	for i = 1, #SKELETON_BONE_DEFS do
		local bone = Instance.new("Frame")
		bone.BorderSizePixel = 0
		bone.Visible = false
		bone.ZIndex = 2
		bone.Parent = container
		espObj.Bones[i] = bone
	end

	espObj.Highlight = nil

	espObj.Destroy = function()
		container:Destroy()
		if espObj.Highlight then espObj.Highlight:Destroy() end
	end

	return espObj
end)

local UpdateESPObj = LPHNoVirtualize(function(espObj, position, size, name, distanceStuds, instance, onScreen)
	local now = os.clock()
	local humanoid = instance:FindFirstChildOfClass("Humanoid")
	local isDead = humanoid and humanoid.Health <= 0

	if ESPConfig.Chams.Enabled and not isDead then
		if ESPConfig.Chams.VisibleCheck and (now - espObj.LastVisCheck) > ESPConfig.VisibilityCheckRate then
			espObj.LastVisCheck = now
			local root = instance.PrimaryPart or instance:FindFirstChild("HumanoidRootPart")
			if root then
				espObj.CachedModelVisible = fastVisCheck(root, instance)
			end
		end

		if not espObj.Highlight then
			espObj.Highlight = Instance.new("Highlight")
			espObj.Highlight.Parent = chamsContainer
			espObj.Highlight.Adornee = instance
		end

		local h = espObj.Highlight
		h.FillColor = (ESPConfig.Chams.VisibleCheck and espObj.CachedModelVisible) and ESPConfig.Chams.VisibleColor or ESPConfig.Chams.Color
		h.FillTransparency = ESPConfig.Chams.Highlight.FillTransparency
		h.OutlineColor = ESPConfig.Chams.OutlineColor
		h.OutlineTransparency = ESPConfig.Chams.Highlight.OutlineTransparency
		h.DepthMode = ESPConfig.Chams.VisibleCheck and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
		h.Enabled = true
	elseif espObj.Highlight then
		espObj.Highlight.Enabled = false
	end

	if not onScreen or not position or not size then
		espObj.Container.Visible = false
		return
	end

	espObj.Container.Visible = true

	local px, py = math.floor(position.X), math.floor(position.Y)
	local sx, sy = math.floor(size.X), math.floor(size.Y)
	local x, y = math.floor(px - sx * 0.5), math.floor(py - sy * 0.5)

	local t = ESPConfig.BoxThickness
	local o = ESPConfig.Outlines.Thickness

	if ESPConfig.Boxes then
		if ESPConfig.BoxType ~= "Corner" then
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
			end
		end
	else
		for i = 1, 4 do espObj.Lines[i].Visible = false end
	end

	if ESPConfig.Names then
		espObj.Text.Position = UDim2.new(0, px - 50, 0, y - ESPConfig.TextSize - ESPConfig.TextGap)
		espObj.Text.Visible = true
	else
		espObj.Text.Visible = false
	end

	local currentBottomY = y + sy + ESPConfig.Distance.Gap
	if ESPConfig.Distance.Enabled then
		espObj.DistanceText.Visible = true
		espObj.DistanceText.Position = UDim2.new(0, px - 50, 0, currentBottomY)
		local distVal = math.floor(distanceStuds / ESPConfig.Distance.StudsPerMeter)
		espObj.DistanceText.Text = distVal .. ESPConfig.Distance.Ending
		currentBottomY = currentBottomY + ESPConfig.Distance.TextSize + ESPConfig.Weapon.Gap
	else
		espObj.DistanceText.Visible = false
	end

	if ESPConfig.Weapon.Enabled and (now - espObj.LastWeaponCheck) > 1.0 then
		espObj.LastWeaponCheck = now
		local tool = instance:FindFirstChildOfClass("Tool")
		espObj.CachedWeapon = tool and tool.Name or nil
	end

	if ESPConfig.Weapon.Enabled and espObj.CachedWeapon then
		espObj.WeaponText.Visible = true
		espObj.WeaponText.Position = UDim2.new(0, px - 50, 0, currentBottomY)
		espObj.WeaponText.Text = espObj.CachedWeapon
	else
		espObj.WeaponText.Visible = false
	end

	if ESPConfig.HealthBar.Enabled and humanoid then
		local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
		local barHeight = math.floor((sy + 1) * healthPercent)
		local hpWidth = ESPConfig.HealthBar.Width

		espObj.HealthBarOutline.Visible = true
		espObj.HealthBarOutline.Size = UDim2.new(0, hpWidth + 2, 0, sy + 3)
		espObj.HealthBarOutline.Position = UDim2.new(0, x - o - ESPConfig.HealthBar.SideGap - hpWidth - 1, 0, y - 1)

		espObj.HealthBarContainer.Size = UDim2.new(0, hpWidth, 0, barHeight)
		espObj.HealthBarContainer.Position = UDim2.new(0, 1, 0, (sy + 1) - barHeight + 1)

		espObj.HealthBar.Size = UDim2.new(0, hpWidth, 0, sy + 1)
		espObj.HealthBar.Position = UDim2.new(0, 0, 0, -(sy + 1 - barHeight))
		espObj.HealthBar.BackgroundColor3 = Color3.fromHSV(healthPercent * 0.3, 1, 1)
	else
		espObj.HealthBarOutline.Visible = false
	end

	if ESPConfig.Skeleton.Enabled then
		if not espObj.BoneCache then
			espObj.BoneCache = cacheCharacterBones(instance)
		end

		for i, def in ipairs(SKELETON_BONE_DEFS) do
			local partA = espObj.BoneCache[def[1]]
			local partB = espObj.BoneCache[def[2]]
			if partA and partB then
				local spA, onA = currentCamera:WorldToViewportPoint(partA.Position)
				local spB, onB = currentCamera:WorldToViewportPoint(partB.Position)
				if onA and onB then
					DrawLine(espObj.Bones[i], spA, spB, 1, ESPConfig.Skeleton.Color)
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

local Get2DBoundingBox = LPHNoVirtualize(function(instance)
	local rootPart = instance.PrimaryPart or instance:FindFirstChild("HumanoidRootPart") or instance:FindFirstChild("Torso")
	if not rootPart then return false, nil, nil end

	local rootPos = rootPart.Position
	local screenPos, onScreen = currentCamera:WorldToViewportPoint(rootPos)
	if not onScreen then return false, nil, nil end

	local humanoid = instance:FindFirstChildOfClass("Humanoid")
	local isR6 = humanoid and humanoid.RigType == Enum.HumanoidRigType.R6

	local top2D = currentCamera:WorldToViewportPoint(rootPos + Vector3.new(0, isR6 and 2.8 or 3.0, 0))
	local bottom2D = currentCamera:WorldToViewportPoint(rootPos - Vector3.new(0, isR6 and 3.0 or 3.5, 0))
	local height = math.abs(top2D.Y - bottom2D.Y)

	return true, Vector2.new(screenPos.X, (top2D.Y + bottom2D.Y) * 0.5), Vector2.new(height * 0.65, height)
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
					newTracked[char] = player.DisplayName or player.Name
				end
			end
		end
	end

	for inst, name in pairs(newTracked) do
		if not trackedInstances[inst] then
			trackedInstances[inst] = { espObj = CreateESPObj(name), name = name }
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

	if not ESPConfig.Enabled then
		for _, data in pairs(trackedInstances) do
			if data.espObj.Container.Visible then
				data.espObj.Container.Visible = false
			end
		end
		return
	end

	local now = os.clock()
	if now - lastScan > 2.0 then
		lastScan = now
		ScanDirectories()
	end

	local camPos = currentCamera.CFrame.Position
	for inst, data in pairs(trackedInstances) do
		local rootPart = inst.PrimaryPart or inst:FindFirstChild("HumanoidRootPart") or inst:FindFirstChild("Torso")
		if rootPart then
			local onScreen, pos2d, size2d = Get2DBoundingBox(inst)
			local dist = (camPos - rootPart.Position).Magnitude
			UpdateESPObj(data.espObj, pos2d, size2d, data.name, dist, inst, onScreen)
		else
			data.espObj.Container.Visible = false
		end
	end
end

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

	getgenv()["123ESP_UI"] = nil
end

function ESP:Load(config)
	self:Unload()
	if config then
		for k, v in pairs(config) do ESPConfig[k] = v end
	end
	ensureRootInstances()

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

function ESP:GetConfig()
	return ESPConfig
end

getgenv()["123ESP_Unload"] = function() ESP:Unload() end

return ESP
