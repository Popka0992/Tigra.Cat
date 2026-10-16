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
		Glow = true,
		GlowColor = Color3.fromRGB(0, 0, 0),
		HealthBar = true,
		HealthBarColorHigh = Color3.fromRGB(75, 175, 75),
		HealthBarColorLow = Color3.fromRGB(255, 50, 50),
		Names = true,
		NameColor = Color3.fromRGB(255, 255, 255),
		Distance = true,
		DistanceColor = Color3.fromRGB(180, 180, 180),
		MaxDistance = 1500,
		TargetFolderName = "Players"
	}
}

local function calculateBoundingBox(model)
	local cframe, size = model:GetBoundingBox()
	local screenPos, onScreen = camera:WorldToViewportPoint(cframe.Position)
	if not onScreen or screenPos.Z <= 0 then
		return nil
	end

	local viewPortY = camera.ViewportSize.Y
	local focalLength = viewPortY / (2 * math.tan(math.rad(camera.FieldOfView) * 0.5))
	local depthScale = focalLength / screenPos.Z

	local boxHeight = math.clamp(size.Y * depthScale, 8, 2048)
	local boxWidth = math.clamp(size.X * depthScale, 6, 2048)

	local xMin = screenPos.X - boxWidth * 0.5
	local yMin = screenPos.Y - boxHeight * 0.5

	return {
		Position = Vector2.new(math.floor(xMin), math.floor(yMin)),
		Size = Vector2.new(math.floor(boxWidth), math.floor(boxHeight)),
		Distance = screenPos.Z
	}
end

local EspEntry = {}
EspEntry.__index = EspEntry

function EspEntry.new(character, container)
	local self = setmetatable({}, EspEntry)
	self.Character = character
	self.Container = container
	self.Visible = false

	self.BoxFrame = Instance.new("Frame")
	self.BoxFrame.BackgroundTransparency = 1
	self.BoxFrame.BorderSizePixel = 0
	self.BoxFrame.Visible = false
	self.BoxFrame.Parent = container

	self.BoxStroke = Instance.new("UIStroke")
	self.BoxStroke.Thickness = 1
	self.BoxStroke.LineJoinMode = Enum.LineJoinMode.Miter
	self.BoxStroke.Parent = self.BoxFrame

	self.GlowImage = Instance.new("ImageLabel")
	self.GlowImage.BackgroundTransparency = 1
	self.GlowImage.Image = ASSETS.Glow
	self.GlowImage.ScaleType = Enum.ScaleType.Slice
	self.GlowImage.SliceCenter = Rect.new(Vector2.new(21, 21), Vector2.new(79, 79))
	self.GlowImage.SliceScale = 1
	self.GlowImage.ImageTransparency = 0.4
	self.GlowImage.Position = UDim2.new(0, -15, 0, -15)
	self.GlowImage.Size = UDim2.new(1, 30, 1, 30)
	self.GlowImage.Parent = self.BoxFrame

	self.HealthOutline = Instance.new("Frame")
	self.HealthOutline.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	self.HealthOutline.BorderSizePixel = 0
	self.HealthOutline.Visible = false
	self.HealthOutline.Parent = container

	self.HealthFill = Instance.new("Frame")
	self.HealthFill.BorderSizePixel = 0
	self.HealthFill.Size = UDim2.new(1, -2, 1, -2)
	self.HealthFill.Position = UDim2.new(0, 1, 0, 1)
	self.HealthFill.AnchorPoint = Vector2.new(0, 0)
	self.HealthFill.Parent = self.HealthOutline

	self.HealthGradient = Instance.new("UIGradient")
	self.HealthGradient.Rotation = 90
	self.HealthGradient.Parent = self.HealthFill

	self.NameLabel = Instance.new("TextLabel")
	self.NameLabel.BackgroundTransparency = 1
	self.NameLabel.BorderSizePixel = 0
	self.NameLabel.FontFace = defaultFont
	self.NameLabel.TextSize = 10
	self.NameLabel.TextStrokeTransparency = 0
	self.NameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	self.NameLabel.Visible = false
	self.NameLabel.Parent = container

	self.DistanceLabel = Instance.new("TextLabel")
	self.DistanceLabel.BackgroundTransparency = 1
	self.DistanceLabel.BorderSizePixel = 0
	self.DistanceLabel.FontFace = defaultFont
	self.DistanceLabel.TextSize = 10
	self.DistanceLabel.TextStrokeTransparency = 0
	self.DistanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	self.DistanceLabel.Visible = false
	self.DistanceLabel.Parent = container

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
		self.BoxFrame.Position = UDim2.new(0, pos.X, 0, pos.Y)
		self.BoxFrame.Size = UDim2.new(0, size.X, 0, size.Y)
		self.BoxStroke.Color = config.BoxColor
		self.BoxFrame.Visible = true

		if config.Glow then
			self.GlowImage.ImageColor3 = config.GlowColor
			self.GlowImage.Visible = true
		else
			self.GlowImage.Visible = false
		end
	else
		self.BoxFrame.Visible = false
	end

	if config.HealthBar then
		local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
		local barWidth = 3
		local barHeight = size.Y

		self.HealthOutline.Position = UDim2.new(0, pos.X - barWidth - 3, 0, pos.Y)
		self.HealthOutline.Size = UDim2.new(0, barWidth, 0, barHeight)

		local fillOffset = math.floor((barHeight - 2) * (1 - healthPercent))
		self.HealthFill.Position = UDim2.new(0, 1, 0, 1 + fillOffset)
		self.HealthFill.Size = UDim2.new(1, -2, 0, (barHeight - 2) - fillOffset)

		self.HealthGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, config.HealthBarColorHigh),
			ColorSequenceKeypoint.new(1, config.HealthBarColorLow)
		})
		self.HealthOutline.Visible = true
	else
		self.HealthOutline.Visible = false
	end

	if config.Names then
		self.NameLabel.Text = self.Character.Name
		self.NameLabel.TextColor3 = config.NameColor
		self.NameLabel.Position = UDim2.new(0, pos.X + (size.X * 0.5), 0, pos.Y - 12)
		self.NameLabel.Visible = true
	else
		self.NameLabel.Visible = false
	end

	if config.Distance then
		self.DistanceLabel.Text = string.format("%d studs", math.floor(bounds.Distance))
		self.DistanceLabel.TextColor3 = config.DistanceColor
		self.DistanceLabel.Position = UDim2.new(0, pos.X + (size.X * 0.5), 0, pos.Y + size.Y + 2)
		self.DistanceLabel.Visible = true
	else
		self.DistanceLabel.Visible = false
	end
end

function EspEntry:SetVisible(state)
	self.BoxFrame.Visible = state
	self.HealthOutline.Visible = state
	self.NameLabel.Visible = state
	self.DistanceLabel.Visible = state
end

function EspEntry:Destroy()
	self.BoxFrame:Destroy()
	self.HealthOutline:Destroy()
	self.NameLabel:Destroy()
	self.DistanceLabel:Destroy()
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
