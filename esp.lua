-- Services.
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local httpService = game:GetService("HttpService")
local coreGui = game:GetService("CoreGui")

if shared.Arbuzi then
	shared.Arbuzi:Unload()
end

local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
local camera = workspace.CurrentCamera
local localPlayer = players.LocalPlayer

local ASSETS = {
	Fonts = {
		SmallestPixel = {
			Url = "https://raw.githubusercontent.com/sametexe001/luas/main/smallest_pixel-7.ttf",
			File = "smallest_pixel-7.ttf",
			FontFile = "smallest_pixel-7.font",
			Name = "SmallestPixel7"
		}
	},
	Glow = "rbxassetid://110204605000367"
}

local function fetchAsset(url, path)
	if not isfile(path) then
		local response = httpRequest({
			Url = url,
			Method = "GET"
		})
		if response and response.Body then
			writefile(path, response.Body)
		end
	end
	return getcustomasset(path)
end

local defaultFont = Font.fromEnum(Enum.Font.Code)
pcall(function()
	local fontData = ASSETS.Fonts.SmallestPixel
	local ttfAsset = fetchAsset(fontData.Url, fontData.File)
	if not isfile(fontData.FontFile) then
		local info = {
			name = fontData.Name,
			faces = {
				{
					name = "Normal",
					weight = 400,
					style = "Normal",
					assetId = ttfAsset
				}
			}
		}
		writefile(fontData.FontFile, httpService:JSONEncode(info))
	end
	defaultFont = Font.new(getcustomasset(fontData.FontFile), Enum.FontWeight.Regular, Enum.FontStyle.Normal)
end)

local function getGuiParent()
	local success, result = pcall(function()
		return gethui()
	end)
	if success and result then
		return result
	end
	return coreGui
end

local Arbuzi = {
	Loaded = false,
	Connections = {},
	Entries = {},
	Config = {
		Enabled = true,
		Boxes = true,
		BoxColor = Color3.fromRGB(255, 255, 255),
		BoxFill = false,
		BoxFillColor = Color3.fromRGB(0, 0, 0),
		BoxFillTransparency = 0.6,
		Glow = true,
		GlowColor = Color3.fromRGB(0, 0, 0),
		HealthBar = true,
		HealthText = true,
		HealthBarColorHigh = Color3.fromRGB(80, 220, 80),
		HealthBarColorLow = Color3.fromRGB(220, 50, 50),
		Names = true,
		NameColor = Color3.fromRGB(255, 255, 255),
		Distance = true,
		DistanceColor = Color3.fromRGB(180, 180, 180),
		Weapon = true,
		WeaponColor = Color3.fromRGB(200, 200, 200),
		Chams = false,
		ChamsFillColor = Color3.fromRGB(150, 100, 255),
		ChamsFillTransparency = 0.5,
		ChamsOutlineColor = Color3.fromRGB(255, 255, 255),
		ChamsOutlineTransparency = 0,
		MaxDistance = 2000,
		TargetFolderName = "Players"
	}
}

local function calculateBoundingBox(model)
	local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso") or model.PrimaryPart
	if not root then return nil end

	local head = model:FindFirstChild("Head")
	local rootCf = root.CFrame
	local rootPos = rootCf.Position

	local topY = head and (head.Position.Y + (head.Size.Y * 0.5) + 0.35) or (rootPos.Y + 2.8)
	local bottomY = rootPos.Y - 3.2

	local height = math.max(topY - bottomY, 2)
	local centerPos = Vector3.new(rootPos.X, bottomY + (height * 0.5), rootPos.Z)
	local extents = Vector3.new(2.4, height * 0.5, 1.6)

	local boxCf = CFrame.new(centerPos, centerPos + rootCf.LookVector)

	local corners = {
		boxCf * Vector3.new(-extents.X, -extents.Y, -extents.Z),
		boxCf * Vector3.new(extents.X, -extents.Y, -extents.Z),
		boxCf * Vector3.new(-extents.X, extents.Y, -extents.Z),
		boxCf * Vector3.new(extents.X, extents.Y, -extents.Z),
		boxCf * Vector3.new(-extents.X, -extents.Y, extents.Z),
		boxCf * Vector3.new(extents.X, -extents.Y, extents.Z),
		boxCf * Vector3.new(-extents.X, extents.Y, extents.Z),
		boxCf * Vector3.new(extents.X, extents.Y, extents.Z)
	}

	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge
	local anyOnScreen = false
	local centerScreen, onScreen = camera:WorldToViewportPoint(centerPos)

	if not onScreen or centerScreen.Z <= 0 then
		return nil
	end

	for i = 1, 8 do
		local scr = camera:WorldToViewportPoint(corners[i])
		if scr.Z > 0 then
			anyOnScreen = true
			minX = math.min(minX, scr.X)
			minY = math.min(minY, scr.Y)
			maxX = math.max(maxX, scr.X)
			maxY = math.max(maxY, scr.Y)
		end
	end

	if not anyOnScreen or minX >= maxX or minY >= maxY then
		return nil
	end

	return {
		Position = Vector2.new(math.floor(minX), math.floor(minY)),
		Size = Vector2.new(math.floor(maxX - minX), math.floor(maxY - minY)),
		Distance = centerScreen.Z
	}
end

local EspEntry = {}
EspEntry.__index = EspEntry

function EspEntry.new(character, container)
	local self = setmetatable({}, EspEntry)
	self.Character = character
	self.Container = container

	self.BoxOutline = Instance.new("Frame")
	self.BoxOutline.BackgroundTransparency = 1
	self.BoxOutline.BorderSizePixel = 0
	self.BoxOutline.Visible = false
	self.BoxOutline.Parent = container

	self.BoxOutlineStroke = Instance.new("UIStroke")
	self.BoxOutlineStroke.Thickness = 1
	self.BoxOutlineStroke.Color = Color3.fromRGB(0, 0, 0)
	self.BoxOutlineStroke.LineJoinMode = Enum.LineJoinMode.Miter
	self.BoxOutlineStroke.Parent = self.BoxOutline

	self.BoxMain = Instance.new("Frame")
	self.BoxMain.BackgroundTransparency = 1
	self.BoxMain.BorderSizePixel = 0
	self.BoxMain.Position = UDim2.new(0, 1, 0, 1)
	self.BoxMain.Size = UDim2.new(1, -2, 1, -2)
	self.BoxMain.Parent = self.BoxOutline

	self.BoxMainStroke = Instance.new("UIStroke")
	self.BoxMainStroke.Thickness = 1
	self.BoxMainStroke.LineJoinMode = Enum.LineJoinMode.Miter
	self.BoxMainStroke.Parent = self.BoxMain

	self.BoxInline = Instance.new("Frame")
	self.BoxInline.BackgroundTransparency = 1
	self.BoxInline.BorderSizePixel = 0
	self.BoxInline.Position = UDim2.new(0, 1, 0, 1)
	self.BoxInline.Size = UDim2.new(1, -2, 1, -2)
	self.BoxInline.Parent = self.BoxMain

	self.BoxInlineStroke = Instance.new("UIStroke")
	self.BoxInlineStroke.Thickness = 1
	self.BoxInlineStroke.Color = Color3.fromRGB(0, 0, 0)
	self.BoxInlineStroke.LineJoinMode = Enum.LineJoinMode.Miter
	self.BoxInlineStroke.Parent = self.BoxInline

	self.BoxFill = Instance.new("Frame")
	self.BoxFill.BorderSizePixel = 0
	self.BoxFill.Position = UDim2.new(0, 1, 0, 1)
	self.BoxFill.Size = UDim2.new(1, -2, 1, -2)
	self.BoxFill.Visible = false
	self.BoxFill.Parent = self.BoxInline

	self.Glow = Instance.new("ImageLabel")
	self.Glow.BackgroundTransparency = 1
	self.Glow.Image = ASSETS.Glow
	self.Glow.ScaleType = Enum.ScaleType.Slice
	self.Glow.SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79))
	self.Glow.ImageTransparency = 0.4
	self.Glow.Position = UDim2.new(0, -15, 0, -15)
	self.Glow.Size = UDim2.new(1, 30, 1, 30)
	self.Glow.Visible = false
	self.Glow.Parent = self.BoxOutline

	self.HealthOutline = Instance.new("Frame")
	self.HealthOutline.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	self.HealthOutline.BorderSizePixel = 0
	self.HealthOutline.Visible = false
	self.HealthOutline.Parent = container

	self.HealthBackground = Instance.new("Frame")
	self.HealthBackground.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
	self.HealthBackground.BorderSizePixel = 0
	self.HealthBackground.Position = UDim2.new(0, 1, 0, 1)
	self.HealthBackground.Size = UDim2.new(1, -2, 1, -2)
	self.HealthBackground.Parent = self.HealthOutline

	self.HealthFill = Instance.new("Frame")
	self.HealthFill.BorderSizePixel = 0
	self.HealthFill.Parent = self.HealthBackground

	self.HealthGradient = Instance.new("UIGradient")
	self.HealthGradient.Rotation = 90
	self.HealthGradient.Parent = self.HealthFill

	self.HealthLabel = Instance.new("TextLabel")
	self.HealthLabel.BackgroundTransparency = 1
	self.HealthLabel.BorderSizePixel = 0
	self.HealthLabel.FontFace = defaultFont
	self.HealthLabel.TextSize = 9
	self.HealthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	self.HealthLabel.TextStrokeTransparency = 0
	self.HealthLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	self.HealthLabel.TextXAlignment = Enum.TextXAlignment.Right
	self.HealthLabel.Visible = false
	self.HealthLabel.Parent = container

	self.NameLabel = Instance.new("TextLabel")
	self.NameLabel.BackgroundTransparency = 1
	self.NameLabel.BorderSizePixel = 0
	self.NameLabel.FontFace = defaultFont
	self.NameLabel.TextSize = 10
	self.NameLabel.TextStrokeTransparency = 0
	self.NameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	self.NameLabel.AnchorPoint = Vector2.new(0.5, 1)
	self.NameLabel.Visible = false
	self.NameLabel.Parent = container

	self.DistanceLabel = Instance.new("TextLabel")
	self.DistanceLabel.BackgroundTransparency = 1
	self.DistanceLabel.BorderSizePixel = 0
	self.DistanceLabel.FontFace = defaultFont
	self.DistanceLabel.TextSize = 9
	self.DistanceLabel.TextStrokeTransparency = 0
	self.DistanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	self.DistanceLabel.AnchorPoint = Vector2.new(0.5, 0)
	self.DistanceLabel.Visible = false
	self.DistanceLabel.Parent = container

	self.WeaponLabel = Instance.new("TextLabel")
	self.WeaponLabel.BackgroundTransparency = 1
	self.WeaponLabel.BorderSizePixel = 0
	self.WeaponLabel.FontFace = defaultFont
	self.WeaponLabel.TextSize = 9
	self.WeaponLabel.TextStrokeTransparency = 0
	self.WeaponLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	self.WeaponLabel.AnchorPoint = Vector2.new(0.5, 0)
	self.WeaponLabel.Visible = false
	self.WeaponLabel.Parent = container

	self.Highlight = Instance.new("Highlight")
	self.Highlight.Adornee = character
	self.Highlight.Enabled = false
	self.Highlight.Parent = container

	return self
end

function EspEntry:Update(config)
	if not (self.Character and self.Character.Parent) then
		self:SetVisible(false)
		return
	end

	local humanoid = self.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		self:SetVisible(false)
		return
	end

	local bounds = calculateBoundingBox(self.Character)
	if not bounds or bounds.Distance > config.MaxDistance then
		self:SetVisible(false)
		return
	end

	local pos = bounds.Position
	local size = bounds.Size

	if config.Boxes then
		self.BoxOutline.Position = UDim2.new(0, pos.X - 1, 0, pos.Y - 1)
		self.BoxOutline.Size = UDim2.new(0, size.X + 2, 0, size.Y + 2)
		self.BoxMainStroke.Color = config.BoxColor
		self.BoxOutline.Visible = true

		if config.BoxFill then
			self.BoxFill.BackgroundColor3 = config.BoxFillColor
			self.BoxFill.BackgroundTransparency = config.BoxFillTransparency
			self.BoxFill.Visible = true
		else
			self.BoxFill.Visible = false
		end

		if config.Glow then
			self.Glow.ImageColor3 = config.GlowColor
			self.Glow.Visible = true
		else
			self.Glow.Visible = false
		end
	else
		self.BoxOutline.Visible = false
	end

	if config.HealthBar then
		local hp = math.clamp(humanoid.Health, 0, humanoid.MaxHealth)
		local maxHp = humanoid.MaxHealth > 0 and humanoid.MaxHealth or 100
		local healthPercent = hp / maxHp
		local barWidth = 4
		local barHeight = size.Y

		self.HealthOutline.Position = UDim2.new(0, pos.X - barWidth - 3, 0, pos.Y)
		self.HealthOutline.Size = UDim2.new(0, barWidth, 0, barHeight)

		local totalTrack = barHeight - 2
		local fillSize = math.floor(totalTrack * healthPercent)
		local fillOffset = totalTrack - fillSize

		self.HealthFill.Position = UDim2.new(0, 0, 0, fillOffset)
		self.HealthFill.Size = UDim2.new(1, 0, 0, fillSize)

		self.HealthGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, config.HealthBarColorHigh),
			ColorSequenceKeypoint.new(1, config.HealthBarColorLow)
		})
		self.HealthOutline.Visible = true

		if config.HealthText and healthPercent < 1 then
			self.HealthLabel.Text = tostring(math.floor(hp))
			self.HealthLabel.Position = UDim2.new(0, pos.X - barWidth - 4, 0, pos.Y + fillOffset - 4)
			self.HealthLabel.Visible = true
		else
			self.HealthLabel.Visible = false
		end
	else
		self.HealthOutline.Visible = false
		self.HealthLabel.Visible = false
	end

	if config.Names then
		self.NameLabel.Text = self.Character.Name
		self.NameLabel.TextColor3 = config.NameColor
		self.NameLabel.Position = UDim2.new(0, pos.X + math.floor(size.X * 0.5), 0, pos.Y - 3)
		self.NameLabel.Visible = true
	else
		self.NameLabel.Visible = false
	end

	local bottomOffset = 1
	if config.Distance then
		self.DistanceLabel.Text = string.format("%d studs", math.floor(bounds.Distance))
		self.DistanceLabel.TextColor3 = config.DistanceColor
		self.DistanceLabel.Position = UDim2.new(0, pos.X + math.floor(size.X * 0.5), 0, pos.Y + size.Y + bottomOffset)
		self.DistanceLabel.Visible = true
		bottomOffset = bottomOffset + 10
	else
		self.DistanceLabel.Visible = false
	end

	if config.Weapon then
		local tool = self.Character:FindFirstChildOfClass("Tool")
		if tool then
			self.WeaponLabel.Text = string.lower(tool.Name)
			self.WeaponLabel.TextColor3 = config.WeaponColor
			self.WeaponLabel.Position = UDim2.new(0, pos.X + math.floor(size.X * 0.5), 0, pos.Y + size.Y + bottomOffset)
			self.WeaponLabel.Visible = true
		else
			self.WeaponLabel.Visible = false
		end
	else
		self.WeaponLabel.Visible = false
	end

	if config.Chams then
		self.Highlight.FillColor = config.ChamsFillColor
		self.Highlight.FillTransparency = config.ChamsFillTransparency
		self.Highlight.OutlineColor = config.ChamsOutlineColor
		self.Highlight.OutlineTransparency = config.ChamsOutlineTransparency
		self.Highlight.Enabled = true
	else
		self.Highlight.Enabled = false
	end
end

function EspEntry:SetVisible(state)
	self.BoxOutline.Visible = state
	self.HealthOutline.Visible = state
	self.HealthLabel.Visible = state
	self.NameLabel.Visible = state
	self.DistanceLabel.Visible = state
	self.WeaponLabel.Visible = state
	self.Highlight.Enabled = state
end

function EspEntry:Destroy()
	self.BoxOutline:Destroy()
	self.HealthOutline:Destroy()
	self.HealthLabel:Destroy()
	self.NameLabel:Destroy()
	self.DistanceLabel:Destroy()
	self.WeaponLabel:Destroy()
	self.Highlight:Destroy()
end

function Arbuzi:AddCharacter(character)
	if not character:IsA("Model") then return end
	if character.Name == localPlayer.Name or (localPlayer.Character and character == localPlayer.Character) then
		return
	end
	if self.Entries[character] then
		self.Entries[character]:Destroy()
	end
	self.Entries[character] = EspEntry.new(character, self.Container)
end

function Arbuzi:RemoveCharacter(character)
	if self.Entries[character] then
		self.Entries[character]:Destroy()
		self.Entries[character] = nil
	end
end

function Arbuzi:Load()
	if self.Loaded then
		return self
	end

	self.ScreenGui = Instance.new("ScreenGui")
	self.ScreenGui.Name = "ArbuziEsp"
	self.ScreenGui.ResetOnSpawn = false
	self.ScreenGui.DisplayOrder = 9999
	self.ScreenGui.Parent = getGuiParent()

	self.Container = Instance.new("Folder")
	self.Container.Name = "RenderContainer"
	self.Container.Parent = self.ScreenGui

	local targetFolder = workspace:FindFirstChild(self.Config.TargetFolderName) or workspace:WaitForChild(self.Config.TargetFolderName, 5)

	if targetFolder then
		for _, child in ipairs(targetFolder:GetChildren()) do
			self:AddCharacter(child)
		end

		table.insert(self.Connections, targetFolder.ChildAdded:Connect(function(child)
			self:AddCharacter(child)
		end))

		table.insert(self.Connections, targetFolder.ChildRemoved:Connect(function(child)
			self:RemoveCharacter(child)
		end))
	end

	table.insert(self.Connections, runService.RenderStepped:Connect(function()
		if not self.Config.Enabled then
			for _, entry in pairs(self.Entries) do
				entry:SetVisible(false)
			end
			return
		end

		for character, entry in pairs(self.Entries) do
			if character.Parent == nil then
				self:RemoveCharacter(character)
			else
				entry:Update(self.Config)
			end
		end
	end))

	self.Loaded = true
	shared.Arbuzi = self
	return self
end

function Arbuzi:GetConfig()
	return self.Config
end

function Arbuzi:Unload()
	for _, connection in ipairs(self.Connections) do
		connection:Disconnect()
	end
	self.Connections = {}

	for character, entry in pairs(self.Entries) do
		entry:Destroy()
	end
	self.Entries = {}

	if self.ScreenGui then
		self.ScreenGui:Destroy()
		self.ScreenGui = nil
	end

	self.Loaded = false
	shared.Arbuzi = nil
end

return Arbuzi
