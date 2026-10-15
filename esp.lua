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

local localPlayer = playersService.LocalPlayer
local currentCamera = workspaceService.CurrentCamera
local uiContainer = (gethui and gethui()) or coreGuiService

if not pcall(function() return uiContainer.Name end) then
	uiContainer = localPlayer:WaitForChild("PlayerGui")
end

local chamsContainer
local screenGui
local playerRemovingConnection
local inputBeganConnection
local trackedInstances = {}
local labelStrokeMap = setmetatable({}, { __mode = "k" })

local weaponDatabase = {}
local iconDatabase = {}
local characterWeaponCache = setmetatable({}, { __mode = "k" })

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
	MaxDistance = 1000,
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
	TextOutlineColor = Color3.fromRGB(0, 0, 0),
	TextGap = 3,
	Font = "Proggy Clean",
	Weapon = {
		Enabled = false,
		ShowText = true,
		ShowIcon = true,
		IconWidth = 28,
		IconHeight = 28,
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
		Color = Color3.fromRGB(59, 144, 204),
		OutlineColor = Color3.fromRGB(255, 255, 255),
		FillTransparency = 0.4,
		OutlineTransparency = 0,
	}
}

local function normalizeName(str)
	if not str then return "" end
	return (str:lower():gsub("[%s%-_]", ""))
end

local function extractNumericId(str)
	if not str or typeof(str) ~= "string" or str == "" then return nil end
	return str:match("%d+")
end

local function buildWeaponDatabase()
	table.clear(weaponDatabase)
	local assets = replicatedStorage:FindFirstChild("Assets")
	local prefabs = assets and assets:FindFirstChild("Prefabs")
	local tools = prefabs and prefabs:FindFirstChild("Tools")
	if not tools then return end

	for _, toolFolder in ipairs(tools:GetChildren()) do
		if toolFolder.Name:find("ADMIN") then continue end
		local wm = toolFolder:FindFirstChild("Worldmodel") or toolFolder:FindFirstChild("WorldModel")
		if wm then
			local textures = {}
			for _, desc in ipairs(wm:GetDescendants()) do
				if desc:IsA("SurfaceAppearance") then
					local colorId = extractNumericId(desc.ColorMap)
					if colorId then textures[colorId] = true end
				elseif desc:IsA("MeshPart") and desc.TextureID ~= "" then
					local meshId = extractNumericId(desc.TextureID)
					if meshId then textures[meshId] = true end
				end
			end
			weaponDatabase[toolFolder.Name] = textures
		end
	end
end

local function buildIconDatabase()
	table.clear(iconDatabase)
	local playerGui = localPlayer:FindFirstChild("PlayerGui")
	if not playerGui then return end

	local ui = playerGui:FindFirstChild("UI")
	local ingame = ui and ui:FindFirstChild("Ingame")
	local crafting = ingame and ingame:FindFirstChild("Crafting")
	local items = crafting and crafting:FindFirstChild("Items")
	local scrollingFrame = items and items:FindFirstChild("ScrollingFrame")
	if not scrollingFrame then return end

	for _, itemFrame in ipairs(scrollingFrame:GetChildren()) do
		if not itemFrame:IsA("GuiObject") then continue end
		local btn = itemFrame:FindFirstChild("Button")
		local iconAsset = btn and (btn:IsA("ImageButton") or btn:IsA("ImageLabel")) and btn.Image
		if iconAsset and iconAsset ~= "" then
			iconDatabase[itemFrame.Name] = iconAsset
			iconDatabase[normalizeName(itemFrame.Name)] = iconAsset
		end
	end
end

local function resolveWeaponFast(char)
	if characterWeaponCache[char] ~= nil then
		return characterWeaponCache[char]
	end

	local tool = char:FindFirstChildOfClass("Tool")
	if tool then
		characterWeaponCache[char] = tool.Name
		return tool.Name
	end

	local wm = char:FindFirstChild("Worldmodel") or char:FindFirstChild("WorldModel")
	if not wm then
		characterWeaponCache[char] = false
		return nil
	end

	for _, desc in ipairs(wm:GetChildren()) do
		local tex = desc:IsA("MeshPart") and extractNumericId(desc.TextureID)
		if tex then
			for weaponName, textures in pairs(weaponDatabase) do
				if textures[tex] then
					characterWeaponCache[char] = weaponName
					return weaponName
				end
			end
		end
	end

	characterWeaponCache[char] = false
	return nil
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
	return nil
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
		Visible = false,
		Lines = {},
		Outlines = {},
		Bones = {},
		LastDistInt = -1,
		LastHpInt = -1
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

	local function setupLabel(label)
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(0, 100, 0, ESPConfig.TextSize)
		label.Font = FONT_MAP[ESPConfig.Font] or Enum.Font.SourceSans
		label.TextSize = ESPConfig.TextSize
		label.TextColor3 = ESPConfig.TextColor
		label.TextStrokeTransparency = 1
		label.ZIndex = 2
		label.Parent = container

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1
		stroke.Color = ESPConfig.TextOutlineColor
		stroke.Enabled = ESPConfig.TextOutline
		stroke.Parent = label
		labelStrokeMap[label] = stroke
	end

	local nameText = Instance.new("TextLabel")
	setupLabel(nameText)
	nameText.TextYAlignment = Enum.TextYAlignment.Bottom
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

	local healthBar = Instance.new("Frame")
	healthBar.BorderSizePixel = 0
	healthBar.ZIndex = 2
	healthBar.Parent = healthBarOutline
	espObj.HealthBar = healthBar

	for i = 1, #SKELETON_BONE_DEFS do
		local bone = Instance.new("Frame")
		bone.BorderSizePixel = 0
		bone.Visible = false
		bone.ZIndex = 1
		bone.Parent = container
		espObj.Bones[i] = bone
	end

	espObj.Highlight = nil

	espObj.Destroy = function()
		container:Destroy()
		if espObj.Highlight then
			espObj.Highlight:Destroy()
		end
	end

	return espObj
end)

local UpdateESPObj = LPHNoVirtualize(function(espObj, position, size, name, distanceStuds, instance, onScreen)
	local humanoid = instance:FindFirstChildOfClass("Humanoid")
	local isDead = humanoid and humanoid.Health <= 0

	-- Lightweight Chams via Engine Highlight (no part cloning).
	if ESPConfig.Chams.Enabled and not isDead then
		if not espObj.Highlight then
			local hl = Instance.new("Highlight")
			hl.Name = "Cham"
			hl.Adornee = instance
			hl.Parent = chamsContainer
			espObj.Highlight = hl
		end
		espObj.Highlight.FillColor = ESPConfig.Chams.Color
		espObj.Highlight.OutlineColor = ESPConfig.Chams.OutlineColor
		espObj.Highlight.FillTransparency = ESPConfig.Chams.FillTransparency
		espObj.Highlight.OutlineTransparency = ESPConfig.Chams.OutlineTransparency
		espObj.Highlight.Enabled = true
	else
		if espObj.Highlight then
			espObj.Highlight.Enabled = false
		end
	end

	if not onScreen or not position or not size or isDead then
		if espObj.Container.Visible then espObj.Container.Visible = false end
		return
	end

	espObj.Container.Visible = true

	local px, py = math.floor(position.X), math.floor(position.Y)
	local sx, sy = math.floor(size.X), math.floor(size.Y)
	local x, y = math.floor(px - sx * 0.5), math.floor(py - sy * 0.5)

	-- Boxes.
	if ESPConfig.Boxes then
		local t = ESPConfig.BoxThickness
		local o = ESPConfig.Outlines.Thickness

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
	else
		for i = 1, 4 do espObj.Lines[i].Visible = false end
	end

	-- Name.
	if ESPConfig.Names then
		espObj.Text.Position = UDim2.new(0, px - 50, 0, y - ESPConfig.TextSize - ESPConfig.TextGap)
		espObj.Text.Visible = true
	else
		espObj.Text.Visible = false
	end

	-- Distance.
	local bottomY = y + sy + ESPConfig.Distance.Gap
	if ESPConfig.Distance.Enabled then
		local distVal = math.floor(distanceStuds / ESPConfig.Distance.StudsPerMeter)
		if espObj.LastDistInt ~= distVal then
			espObj.LastDistInt = distVal
			espObj.DistanceText.Text = distVal .. ESPConfig.Distance.Ending
		end
		espObj.DistanceText.Position = UDim2.new(0, px - 50, 0, bottomY)
		espObj.DistanceText.Visible = true
		bottomY = bottomY + ESPConfig.Distance.TextSize + ESPConfig.Weapon.Gap
	else
		espObj.DistanceText.Visible = false
	end

	-- Weapon.
	if ESPConfig.Weapon.Enabled then
		local weaponName = resolveWeaponFast(instance)
		if weaponName then
			if ESPConfig.Weapon.ShowText then
				espObj.WeaponText.Text = weaponName
				espObj.WeaponText.Position = UDim2.new(0, px - 50, 0, bottomY)
				espObj.WeaponText.Visible = true
				bottomY = bottomY + ESPConfig.Weapon.TextSize
			else
				espObj.WeaponText.Visible = false
			end

			if ESPConfig.Weapon.ShowIcon and iconDatabase[weaponName] then
				espObj.WeaponIcon.Image = iconDatabase[weaponName]
				espObj.WeaponIcon.Size = UDim2.new(0, ESPConfig.Weapon.IconWidth, 0, ESPConfig.Weapon.IconHeight)
				espObj.WeaponIcon.Position = UDim2.new(0, px - math.floor(ESPConfig.Weapon.IconWidth * 0.5), 0, bottomY)
				espObj.WeaponIcon.Visible = true
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

	-- Health Bar.
	if ESPConfig.HealthBar.Enabled and humanoid then
		local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
		local barHeight = math.floor(sy * healthPercent)

		espObj.HealthBarOutline.Size = UDim2.new(0, ESPConfig.HealthBar.Width + 2, 0, sy + 2)
		espObj.HealthBarOutline.Position = UDim2.new(0, x - ESPConfig.HealthBar.Width - ESPConfig.HealthBar.SideGap - 2, 0, y - 1)
		espObj.HealthBarOutline.Visible = true

		espObj.HealthBar.Size = UDim2.new(0, ESPConfig.HealthBar.Width, 0, barHeight)
		espObj.HealthBar.Position = UDim2.new(0, 1, 0, sy - barHeight + 1)
		espObj.HealthBar.BackgroundColor3 = Color3.fromHSV(healthPercent * 0.3, 1, 1)
	else
		espObj.HealthBarOutline.Visible = false
	end

	-- Skeleton.
	if ESPConfig.Skeleton.Enabled and distanceStuds < 250 then
		for i, def in ipairs(SKELETON_BONE_DEFS) do
			local pA = getBonePosition(instance, def[1])
			local pB = getBonePosition(instance, def[2])
			if pA and pB then
				local spA, onA = currentCamera:WorldToViewportPoint(pA)
				local spB, onB = currentCamera:WorldToViewportPoint(pB)
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

---Fast 2D box projector using single viewport coordinate.
local function getFast2DBounds(rootPos)
	local screenPos, onScreen = currentCamera:WorldToViewportPoint(rootPos)
	if not onScreen then return false, nil, nil end

	local dist = (currentCamera.CFrame.Position - rootPos).Magnitude
	local height = math.clamp(1000 / dist * 1.8, 12, 400)
	local width = height * 0.65

	return true, Vector2.new(screenPos.X, screenPos.Y), Vector2.new(width, height)
end

local function scanEntities()
	local newTracked = {}

	if ESPConfig.Players then
		for _, player in ipairs(playersService:GetPlayers()) do
			if not ESPConfig.LocalPlayer and player == localPlayer then continue end
			if ESPConfig.TeamCheck and localPlayer.Team and player.Team == localPlayer.Team then continue end
			local char = player.Character
			if char and char:FindFirstChildOfClass("Humanoid") then
				newTracked[char] = player.DisplayName or player.Name
			end
		end
	end

	local playersFolder = workspaceService:FindFirstChild("Players")
	local aiFolder = workspaceService:FindFirstChild("AICharacters") or workspaceService:FindFirstChild("AI")

	if ESPConfig.Bots and aiFolder then
		for _, bot in ipairs(aiFolder:GetChildren()) do
			if bot:IsA("Model") and bot:FindFirstChildOfClass("Humanoid") then
				newTracked[bot] = (ESPConfig.BotTag or "[BOT] ") .. bot.Name
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
			characterWeaponCache[inst] = nil
			trackedInstances[inst] = nil
		end
	end
end

local lastScanTime = 0
local function runtimeStep()
	currentCamera = workspaceService.CurrentCamera or currentCamera
	if not ESPConfig.Enabled then
		for _, data in pairs(trackedInstances) do
			if data.espObj.Container.Visible then
				data.espObj.Container.Visible = false
			end
			if data.espObj.Highlight then
				data.espObj.Highlight.Enabled = false
			end
		end
		return
	end

	local now = os.clock()
	if now - lastScanTime > 2.0 then
		lastScanTime = now
		scanEntities()
	end

	local camPos = currentCamera.CFrame.Position
	local maxDist = ESPConfig.MaxDistance

	for inst, data in pairs(trackedInstances) do
		local root = inst:FindFirstChild("HumanoidRootPart") or inst.PrimaryPart or inst:FindFirstChild("Torso")
		if root then
			local rootPos = root.Position
			local dist = (camPos - rootPos).Magnitude
			if dist <= maxDist then
				local onScreen, pos2d, size2d = getFast2DBounds(rootPos)
				UpdateESPObj(data.espObj, pos2d, size2d, data.name, dist, inst, onScreen)
			else
				if data.espObj.Container.Visible then data.espObj.Container.Visible = false end
				if data.espObj.Highlight then data.espObj.Highlight.Enabled = false end
			end
		end
	end
end

function ESP:Unload()
	for inst, data in pairs(trackedInstances) do
		data.espObj:Destroy()
		trackedInstances[inst] = nil
	end
	if playerRemovingConnection then playerRemovingConnection:Disconnect(); playerRemovingConnection = nil end
	if inputBeganConnection then inputBeganConnection:Disconnect(); inputBeganConnection = nil end
	if getgenv()["123ESP_Loop"] then getgenv()["123ESP_Loop"]:Disconnect(); getgenv()["123ESP_Loop"] = nil end
	if screenGui then screenGui:Destroy(); screenGui = nil end
	if chamsContainer then chamsContainer:Destroy(); chamsContainer = nil end
	table.clear(characterWeaponCache)
end

function ESP:Load(config)
	self:Unload()
	if config then
		for k, v in pairs(config) do ESPConfig[k] = v end
	end

	ensureRootInstances()
	buildWeaponDatabase()
	buildIconDatabase()

	playerRemovingConnection = playersService.PlayerRemoving:Connect(function(player)
		for inst, data in pairs(trackedInstances) do
			if playersService:GetPlayerFromCharacter(inst) == player then
				data.espObj:Destroy()
				characterWeaponCache[inst] = nil
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
	scanEntities()
	return self
end

function ESP:GetConfig()
	return ESPConfig
end

getgenv()["123ESP_Unload"] = function() ESP:Unload() end

return ESP
