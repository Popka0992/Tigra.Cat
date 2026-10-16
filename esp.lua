-- Check for table that is shared between executions.
if not shared then
	return warn("No shared, no script.")
end

-- Initialize Luraph globals if they do not exist.
loadstring("getfenv().LPH_NO_VIRTUALIZE = function(...) return ... end")()

getfenv().PP_SCRAMBLE_NUM = function(...) return ... end
getfenv().PP_SCRAMBLE_STR = function(...) return ... end
getfenv().PP_SCRAMBLE_RE_NUM = function(...) return ... end

-- Unload previous instance.
if shared.Arbuzi and shared.Arbuzi.Unload then
	pcall(shared.Arbuzi.Unload, shared.Arbuzi)
end

-- Services.
local workspaceService = cloneref(game:GetService("Workspace"))
local playersService = cloneref(game:GetService("Players"))
local runService = cloneref(game:GetService("RunService"))
local httpService = cloneref(game:GetService("HttpService"))

-- State and Aliases.
local localPlayer = playersService.LocalPlayer
local camera = workspaceService.CurrentCamera
local worldToViewportPoint = camera.WorldToViewportPoint
local findFirstChildOfClass = game.FindFirstChildOfClass
local findFirstChild = game.FindFirstChild

local newVector3 = Vector3.new
local newVector2 = Vector2.new
local newUDim = UDim.new
local newUDim2 = UDim2.new
local udim2FromOffset = UDim2.fromOffset
local numSeq = NumberSequence.new
local numKey = NumberSequenceKeypoint.new

local stringFormat = string.format
local tableClear = table.clear
local mathFloor = math.floor
local mathClamp = math.clamp
local mathAbs = math.abs
local mathTan = math.tan
local mathRad = math.rad
local mathHuge = math.huge
local tableRemove = table.remove

local zeroVector3 = newVector3(0, 0, 0)
local cameraPosition = newVector3(0, 0, 0)
local cachedFocalLength = 0
local viewPortY = 0

local function updateCameraCache()
	viewPortY = camera.ViewportSize.Y
	cachedFocalLength = viewPortY / (2 * mathTan(mathRad(camera.FieldOfView) * 0.5))
end

updateCameraCache()
camera:GetPropertyChangedSignal("FieldOfView"):Connect(updateCameraCache)
camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateCameraCache)

local Arbuzi = {
	Directory = "Esp",
	Cache = {},
	Holder = nil,
	Threads = {},
	Connections = {},
	PreRender = nil,
	PostRender = nil,
	Table = {
		Enabled = true,
		Bots = {
			Enabled = false,
			Name = "bot"
		},
		Boxes = {
			Enabled = true,
			["Bounding Box"] = {
				Enabled = false,
				IncludeAccessories = false,
				BoxX = 0,
				BoxY = 2
			},
			["Box Glow"] = {
				Enabled = true,
				Top = Color3.fromRGB(255, 255, 255),
				Bot = Color3.fromRGB(255, 255, 255),
				Transparency = { 0.85, 0.85 }
			},
			Gradients = {
				Top = Color3.fromRGB(255, 255, 255),
				Bot = Color3.fromRGB(255, 255, 255)
			},
			Filled = {
				Enabled = true,
				Top = Color3.fromRGB(255, 255, 255),
				Bot = Color3.fromRGB(255, 255, 255),
				Transparency = { 0.85, 0.85 }
			}
		},
		Bars = {
			["Health Bar"] = {
				Enabled = true,
				Color = Color3.fromRGB(255, 255, 255)
			}
		},
		Texts = {
			Name = {
				Enabled = true,
				Color = Color3.fromRGB(255, 255, 255)
			},
			Distance = {
				Enabled = true,
				Color = Color3.fromRGB(200, 200, 200)
			},
			Weapon = {
				Enabled = true,
				Color = Color3.fromRGB(255, 255, 255)
			},
			State = {
				Enabled = true,
				Color = Color3.fromRGB(255, 255, 255)
			}
		}
	}
}

Arbuzi.__index = Arbuzi
local config = Arbuzi.Table

-- Font Registration.
local Fonts = {}
do
	local function fetchSource(url)
		local response = request({ Url = url, Method = "GET" })
		return response and response.Body or ""
	end

	local function registerFont(name, weight, style, asset)
		if isfile(asset.Id) then
			delfile(asset.Id)
		end

		writefile(asset.Id, asset.Font)

		if isfile(name .. ".font") then
			delfile(name .. ".font")
		end

		local info = {
			name = name,
			faces = {
				{
					name = "Normal",
					weight = weight,
					style = style,
					assetId = getcustomasset(asset.Id)
				}
			}
		}

		writefile(name .. ".font", httpService:JSONEncode(info))
		return getcustomasset(name .. ".font")
	end

	Fonts.Tahoma = registerFont("Tahoma", 400, "Normal", {
		Id = "Tahoma.ttf",
		Font = fetchSource("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/fs-tahoma-8px.ttf")
	})

	Fonts.SmallestPixel = registerFont("SmallestPixel", 400, "Normal", {
		Id = "smallest_pixel-7.ttf",
		Font = fetchSource("https://raw.githubusercontent.com/sametexe001/luas/main/smallest_pixel-7.ttf")
	})

	Arbuzi.Tahoma = Font.new(Fonts.Tahoma, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	Arbuzi.SmallestPixel = Font.new(Fonts.SmallestPixel, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
end

function Arbuzi:CreateObjects(name, properties)
	local instance = Instance.new(name)
	for prop, value in pairs(properties or {}) do
		instance[prop] = value
	end
	return instance
end

function Arbuzi:CreateThreads(name, signal, callback)
	local connection = signal:Connect(callback)
	self.Threads[name] = connection
	return connection
end

Arbuzi.Holder = Arbuzi:CreateObjects("ScreenGui", {
	Name = "\n",
	Parent = gethui(),
	ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
	ZIndexBehavior = Enum.ZIndexBehavior.Global,
	ResetOnSpawn = false,
	DisplayOrder = -1,
	IgnoreGuiInset = true
})

function Arbuzi:InitEsp(data)
	local objects = data.Objects

	objects.TargetHolder = self:CreateObjects("Frame", {
		Parent = self.Holder,
		Visible = false,
		BackgroundTransparency = 1,
		Position = newUDim2(0, 0, 0, 0),
		Size = newUDim2(0, 0, 0, 0),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects.TopHolder = self:CreateObjects("Frame", {
		Parent = objects.TargetHolder,
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = true,
		BackgroundTransparency = 1,
		AnchorPoint = newVector2(0, 1),
		Position = newUDim2(0, -2, 0, -5),
		Size = newUDim2(1, 4, 0, 0),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects.BottomHolder = self:CreateObjects("Frame", {
		Parent = objects.TargetHolder,
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = true,
		BackgroundTransparency = 1,
		Position = newUDim2(0, -2, 1, 3),
		Size = newUDim2(1, 4, 0, 0),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects.LeftHolder = self:CreateObjects("Frame", {
		Parent = objects.TargetHolder,
		AutomaticSize = Enum.AutomaticSize.X,
		Visible = true,
		BackgroundTransparency = 1,
		AnchorPoint = newVector2(1, 0),
		Position = newUDim2(0, -5, 0, -2),
		Size = newUDim2(0, 0, 1, 4),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects.RightHolder = self:CreateObjects("Frame", {
		Parent = objects.TargetHolder,
		AutomaticSize = Enum.AutomaticSize.X,
		Visible = true,
		BackgroundTransparency = 1,
		Position = newUDim2(1, 5, 0, -2),
		Size = newUDim2(0, 0, 1, 4),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects.TopTextHolder = self:CreateObjects("Frame", {
		Parent = objects.TopHolder,
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = true,
		BackgroundTransparency = 1,
		Position = newUDim2(0, 0, 0, 0),
		Size = newUDim2(1, 0, 0, 0),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects.BottomTextHolder = self:CreateObjects("Frame", {
		Parent = objects.BottomHolder,
		LayoutOrder = 2,
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = true,
		BackgroundTransparency = 1,
		Position = newUDim2(0, 0, 0, 0),
		Size = newUDim2(1, 0, 0, 0),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects.LeftTextHolder = self:CreateObjects("Frame", {
		Parent = objects.LeftHolder,
		AutomaticSize = Enum.AutomaticSize.XY,
		Visible = true,
		BackgroundTransparency = 1,
		Position = newUDim2(0, 0, 0, 0),
		Size = newUDim2(1, 0, 0, 0),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects.RightTextHolder = self:CreateObjects("Frame", {
		Parent = objects.RightHolder,
		LayoutOrder = 2,
		AutomaticSize = Enum.AutomaticSize.XY,
		Visible = true,
		BackgroundTransparency = 1,
		Position = newUDim2(0, 0, 0, 0),
		Size = newUDim2(0, 0, 0, 0),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects.LeftBarHolder = self:CreateObjects("Frame", {
		Parent = objects.LeftHolder,
		AutomaticSize = Enum.AutomaticSize.X,
		Visible = false,
		BackgroundTransparency = 1,
		Position = newUDim2(0, 0, 0, 0),
		Size = newUDim2(0, 0, 1, 0),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects.BottomBarHolder = self:CreateObjects("Frame", {
		Parent = objects.BottomHolder,
		LayoutOrder = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		BackgroundTransparency = 1,
		Position = newUDim2(0, 0, 0, 0),
		Size = newUDim2(1, 0, 0, 0),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	self:CreateObjects("UIListLayout", {
		Parent = objects.TopTextHolder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = newUDim(0, 1),
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	self:CreateObjects("UIListLayout", {
		Parent = objects.BottomTextHolder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = newUDim(0, -1),
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	self:CreateObjects("UIListLayout", {
		Parent = objects.LeftTextHolder,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = newUDim(0, 0),
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	self:CreateObjects("UIListLayout", {
		Parent = objects.RightTextHolder,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Padding = newUDim(0, 0),
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	self:CreateObjects("UIListLayout", {
		Parent = objects.LeftBarHolder,
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = newUDim(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	self:CreateObjects("UIListLayout", {
		Parent = objects.BottomBarHolder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = newUDim(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	self:CreateObjects("UIListLayout", {
		Parent = objects.TopHolder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = newUDim(0, 1),
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	self:CreateObjects("UIListLayout", {
		Parent = objects.BottomHolder,
		Padding = newUDim(0, 1),
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	self:CreateObjects("UIListLayout", {
		Parent = objects.LeftHolder,
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Padding = newUDim(0, 1),
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	self:CreateObjects("UIListLayout", {
		Parent = objects.RightHolder,
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Padding = newUDim(0, 1),
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	self:CreateObjects("UIPadding", { Parent = objects.TopTextHolder, PaddingBottom = newUDim(0, 0) })
	self:CreateObjects("UIPadding", { Parent = objects.BottomTextHolder, PaddingTop = newUDim(0, -1) })
	self:CreateObjects("UIPadding", { Parent = objects.LeftTextHolder, PaddingTop = newUDim(0, -3) })
	self:CreateObjects("UIPadding", { Parent = objects.RightTextHolder, PaddingTop = newUDim(0, -3) })
	self:CreateObjects("UIPadding", { Parent = objects.LeftBarHolder, PaddingRight = newUDim(0, 1) })
	self:CreateObjects("UIPadding", { Parent = objects.BottomBarHolder, PaddingTop = newUDim(0, 3) })
	self:CreateObjects("UIPadding", { Parent = objects.LeftHolder, PaddingRight = newUDim(0, 1) })

	objects.BoxGlow = self:CreateObjects("ImageLabel", {
		Parent = objects.TargetHolder,
		Image = "rbxassetid://110204605000367",
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(newVector2(21, 21), newVector2(79, 79)),
		AutomaticSize = Enum.AutomaticSize.XY,
		ImageTransparency = 0.65,
		ResampleMode = Enum.ResamplerMode.Pixelated,
		Visible = true,
		BackgroundTransparency = 1,
		Position = newUDim2(0, -21, 0, -21),
		Size = newUDim2(0, 0, 0, 0),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects.BoxGlowGradient = self:CreateObjects("UIGradient", {
		Parent = objects.BoxGlow,
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
		}),
		Transparency = numSeq({ numKey(0, 0), numKey(1, 0) })
	})

	self:CreateObjects("UIPadding", {
		Parent = objects.BoxGlow,
		PaddingTop = newUDim(0, 21),
		PaddingBottom = newUDim(0, 20),
		PaddingLeft = newUDim(0, 21),
		PaddingRight = newUDim(0, 20)
	})

	objects.BoxOutlineHolder = self:CreateObjects("Frame", {
		Parent = objects.BoxGlow,
		Visible = false,
		BackgroundTransparency = 1,
		Position = newUDim2(0, 0, 0, 0),
		Size = newUDim2(0, 0, 0, 0),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects.BoxOutline = self:CreateObjects("UIStroke", {
		Parent = objects.BoxOutlineHolder,
		Thickness = 3,
		LineJoinMode = Enum.LineJoinMode.Miter
	})

	objects.BoxOutlineGradient = self:CreateObjects("UIGradient", {
		Parent = objects.BoxOutline,
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
		}),
		Transparency = numSeq({ numKey(0, 0), numKey(1, 0) })
	})

	objects.BoxInlineHolder = self:CreateObjects("Frame", {
		Parent = objects.BoxGlow,
		Visible = false,
		BackgroundTransparency = 1,
		Position = newUDim2(0, -1, 0, -1),
		Size = newUDim2(0, 0, 0, 0),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects.BoxInline = self:CreateObjects("UIStroke", {
		Parent = objects.BoxInlineHolder,
		Color = Color3.fromRGB(255, 255, 255),
		LineJoinMode = Enum.LineJoinMode.Miter
	})

	objects.BoxInlineGradient = self:CreateObjects("UIGradient", {
		Parent = objects.BoxInline,
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
		}),
		Transparency = numSeq({ numKey(0, 0), numKey(1, 0) })
	})

	objects.BoxFill = self:CreateObjects("Frame", {
		Parent = objects.BoxGlow,
		Visible = false,
		BackgroundTransparency = 0,
		Position = newUDim2(0, 0, 0, 0),
		Size = newUDim2(0, 0, 0, 0),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects.BoxFillGradient = self:CreateObjects("UIGradient", {
		Parent = objects.BoxFill,
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
		}),
		Transparency = numSeq({ numKey(0, 1), numKey(1, 1) })
	})

	objects.HealthBarOutline = self:CreateObjects("Frame", {
		Parent = objects.LeftBarHolder,
		ZIndex = 5,
		LayoutOrder = 0,
		Visible = false,
		BackgroundTransparency = 0,
		Position = newUDim2(0, 0, 0, 0),
		Size = newUDim2(0, 2, 1, 0),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		ClipsDescendants = false
	})

	self:CreateObjects("UIStroke", {
		Parent = objects.HealthBarOutline,
		Thickness = 1,
		LineJoinMode = Enum.LineJoinMode.Miter
	})

	objects.HealthBar = self:CreateObjects("Frame", {
		Parent = objects.HealthBarOutline,
		ZIndex = 6,
		AnchorPoint = newVector2(0, 1),
		Position = newUDim2(0, 0, 1, 0),
		Size = newUDim2(1, 0, 1, 0),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		ClipsDescendants = true
	})

	objects.HealthBarGradient = self:CreateObjects("UIGradient", {
		Parent = objects.HealthBar,
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, config.Bars["Health Bar"].Color),
			ColorSequenceKeypoint.new(1, config.Bars["Health Bar"].Color)
		}),
		Transparency = numSeq({ numKey(0, 0), numKey(1, 0) })
	})

	objects.HealthBarText = self:CreateObjects("TextLabel", {
		Parent = objects.HealthBarOutline,
		FontFace = Arbuzi.SmallestPixel,
		TextSize = 9,
		ZIndex = 10,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		AnchorPoint = newVector2(0.5, 0.5),
		Position = newUDim2(0.5, 0, 1, 0),
		BorderSizePixel = 0,
		Visible = false,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = newUDim2(0, 0, 0, 0)
	})

	self:CreateObjects("UIStroke", {
		Parent = objects.HealthBarText,
		Color = Color3.fromRGB(0, 0, 0),
		LineJoinMode = Enum.LineJoinMode.Miter
	})

	objects.TargetName = self:CreateObjects("TextLabel", {
		Parent = objects.TopTextHolder,
		FontFace = Arbuzi.Tahoma,
		TextSize = 12,
		LayoutOrder = 2,
		TextColor3 = config.Texts.Name.Color,
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Center,
		BorderSizePixel = 0,
		Visible = false,
		BackgroundTransparency = 1,
		ZIndex = 5,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = newUDim2(0, 0, 0, 0)
	})

	self:CreateObjects("UIStroke", {
		Parent = objects.TargetName,
		Color = Color3.fromRGB(0, 0, 0),
		LineJoinMode = Enum.LineJoinMode.Miter
	})

	objects.Distance = self:CreateObjects("TextLabel", {
		Parent = objects.BottomTextHolder,
		FontFace = Arbuzi.SmallestPixel,
		TextSize = 9,
		LayoutOrder = 2,
		TextColor3 = config.Texts.Distance.Color,
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Center,
		BorderSizePixel = 0,
		Visible = false,
		BackgroundTransparency = 1,
		ZIndex = 5,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = newUDim2(0, 0, 0, 0)
	})

	self:CreateObjects("UIStroke", {
		Parent = objects.Distance,
		Color = Color3.fromRGB(0, 0, 0),
		LineJoinMode = Enum.LineJoinMode.Miter
	})

	objects.WalkFlag = self:CreateObjects("TextLabel", {
		Parent = objects.RightTextHolder,
		FontFace = Arbuzi.SmallestPixel,
		TextSize = 9,
		LayoutOrder = 1,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Text = "Walking",
		TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0,
		Visible = false,
		BackgroundTransparency = 1,
		ZIndex = 5,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = newUDim2(0, 0, 0, 0)
	})

	self:CreateObjects("UIStroke", {
		Parent = objects.WalkFlag,
		Color = Color3.fromRGB(0, 0, 0),
		LineJoinMode = Enum.LineJoinMode.Miter
	})

	objects.JumpFlag = self:CreateObjects("TextLabel", {
		Parent = objects.RightTextHolder,
		FontFace = Arbuzi.SmallestPixel,
		TextSize = 9,
		LayoutOrder = 2,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Text = "Jumping",
		TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0,
		Visible = false,
		BackgroundTransparency = 1,
		ZIndex = 5,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = newUDim2(0, 0, 0, 0)
	})

	self:CreateObjects("UIStroke", {
		Parent = objects.JumpFlag,
		Color = Color3.fromRGB(0, 0, 0),
		LineJoinMode = Enum.LineJoinMode.Miter
	})

	objects.StateFlag = self:CreateObjects("TextLabel", {
		Parent = objects.RightTextHolder,
		FontFace = Arbuzi.SmallestPixel,
		TextSize = 9,
		LayoutOrder = 3,
		TextColor3 = config.Texts.State.Color,
		Text = "Standing",
		TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0,
		Visible = false,
		BackgroundTransparency = 1,
		ZIndex = 5,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = newUDim2(0, 0, 0, 0)
	})

	self:CreateObjects("UIStroke", {
		Parent = objects.StateFlag,
		Color = Color3.fromRGB(0, 0, 0),
		LineJoinMode = Enum.LineJoinMode.Miter
	})

	objects.Weapon = self:CreateObjects("TextLabel", {
		Parent = objects.BottomTextHolder,
		FontFace = Arbuzi.SmallestPixel,
		TextSize = 9,
		LayoutOrder = 3,
		TextColor3 = config.Texts.Weapon.Color,
		Text = "none",
		TextXAlignment = Enum.TextXAlignment.Center,
		BorderSizePixel = 0,
		Visible = false,
		BackgroundTransparency = 1,
		ZIndex = 5,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = newUDim2(0, 0, 0, 0)
	})

	self:CreateObjects("UIStroke", {
		Parent = objects.Weapon,
		Color = Color3.fromRGB(0, 0, 0),
		LineJoinMode = Enum.LineJoinMode.Miter
	})
end

function Arbuzi:CalculateBox(data)
	local rootPart = data.RootPart
	if not rootPart then
		return nil, nil, nil, nil, false
	end

	local rootScreen, onScreen = worldToViewportPoint(camera, rootPart.Position)
	if not onScreen then
		return nil, nil, nil, nil, false
	end

	local boundingBox = config.Boxes["Bounding Box"]
	if boundingBox.Enabled then
		local children = data.Children
		if not children then
			local scale = (rootPart.Size.Y * viewPortY) / (rootScreen.Z * 2)
			local w, h = 3 * scale, 4.5 * scale
			return w, h, rootScreen.X - (w * 0.5), rootScreen.Y - (h * 0.5), onScreen
		end

		local includeAccessories = config.Boxes["Bounding Box"].IncludeAccessories
		local scrMinX, scrMinY = mathHuge, mathHuge
		local scrMaxX, scrMaxY = -mathHuge, -mathHuge
		local hasValidParts = false

		for _, part in ipairs(children) do
			if part:IsA("BasePart") and part.Transparency ~= 1 and part ~= rootPart then
				local parent = part.Parent
				if parent == nil then
					continue
				end
				if not includeAccessories and parent:IsA("Accessory") then
					continue
				end

				local partScreen, partOnScreen = worldToViewportPoint(camera, part.Position)
				if not partOnScreen or partScreen.Z <= 0 then
					continue
				end

				hasValidParts = true
				local cf = part.CFrame
				local sz = part.Size
				local hx, hy, hz = sz.X * 0.5, sz.Y * 0.5, sz.Z * 0.5
				local rx, uy, lz = cf.RightVector, cf.UpVector, cf.LookVector
				local depthScale = cachedFocalLength / partScreen.Z

				local ex = (mathAbs(rx.X * hx) + mathAbs(uy.X * hy) + mathAbs(lz.X * hz)) * depthScale
				local ey = (mathAbs(rx.Y * hx) + mathAbs(uy.Y * hy) + mathAbs(lz.Y * hz)) * depthScale

				local pMinX, pMaxX = partScreen.X - ex, partScreen.X + ex
				local pMinY, pMaxY = partScreen.Y - ey, partScreen.Y + ey

				if pMinX < scrMinX then scrMinX = pMinX end
				if pMaxX > scrMaxX then scrMaxX = pMaxX end
				if pMinY < scrMinY then scrMinY = pMinY end
				if pMaxY > scrMaxY then scrMaxY = pMaxY end
			end
		end

		if not hasValidParts then
			local scale = (rootPart.Size.Y * viewPortY) / (rootScreen.Z * 2)
			local w, h = 3 * scale, 4.5 * scale
			return w, h, rootScreen.X - (w * 0.5), rootScreen.Y - (h * 0.5), onScreen
		end

		local padX = boundingBox.BoxX
		local padY = boundingBox.BoxY
		local w = (scrMaxX - scrMinX) + padX
		local h = (scrMaxY - scrMinY) + padY
		return w, h, scrMinX - (padX * 0.5), scrMinY - (padY * 0.5), true
	else
		local scale = (rootPart.Size.Y * viewPortY) / (rootScreen.Z * 2)
		local w, h = 3 * scale, 4.5 * scale
		return w, h, rootScreen.X - (w * 0.5), rootScreen.Y - (h * 0.5), onScreen
	end
end

---Register a model target from workspace.Players.
function Arbuzi:AddTarget(target)
	if not target:IsA("Model") then
		return
	end

	-- Exclude our local player model.
	if target.Name == localPlayer.Name or (localPlayer.Character and target == localPlayer.Character) then
		return
	end

	if self.Cache[target] then
		return
	end

	local data = {
		Target = target,
		IsBot = false,
		IsPlayer = true,
		Objects = {},
		Conns = {},
		Character = target,
		RootPart = nil,
		Humanoid = nil,
		Children = {},
		Health = 0,
		MaxHealth = 100,
		CurrentTool = nil,
		Alive = false,
		LastW = nil,
		LastH = nil,
		LastX = nil,
		LastY = nil,
		WalkActive = false,
		JumpActive = false,
		IncludeAccessories = config.Boxes["Bounding Box"].IncludeAccessories,
		LastGlowTop = nil,
		LastGlowBot = nil,
		LastGlowT1 = nil,
		LastGlowT2 = nil,
		LastGradTop = nil,
		LastGradBot = nil,
		LastFillTop = nil,
		LastFillBot = nil,
		LastFillT1 = nil,
		LastFillT2 = nil,
		LastDist = nil,
		LastDistColor = nil,
		LastDisplayName = nil,
		LastNameColor = nil,
		LastHealthColor = nil,
		LastHealthFloor = nil,
		LastRatio = nil,
		LastWeapon = nil,
		LastWeaponColor = nil,
		LastStateColor = nil,
		LastDistance = nil
	}

	task.spawn(function()
		self:InitEsp(data)
	end)

	self.Cache[target] = data

	task.spawn(function()
		local rootPart = findFirstChild(target, "HumanoidRootPart") or target:WaitForChild("HumanoidRootPart", 5)
		local humanoid = findFirstChildOfClass(target, "Humanoid") or target:WaitForChild("Humanoid", 5)

		if not (rootPart and humanoid and target.Parent) then
			return
		end

		data.RootPart = rootPart
		data.Humanoid = humanoid
		data.Children = target:GetChildren()
		data.Health = humanoid.Health
		data.MaxHealth = humanoid.MaxHealth
		data.Alive = humanoid.Health > 0

		data.Conns.Health = humanoid.HealthChanged:Connect(function(newHealth)
			data.Alive = newHealth > 0
			data.Health = newHealth
		end)

		data.Conns.Died = humanoid.Died:Connect(function()
			data.Alive = false
		end)

		data.Conns.ChildAdded = target.ChildAdded:Connect(function(child)
			data.Children[#data.Children + 1] = child
		end)

		data.Conns.ChildRemoved = target.ChildRemoved:Connect(function(child)
			for i = #data.Children, 1, -1 do
				if data.Children[i] == child then
					tableRemove(data.Children, i)
					break
				end
			end
		end)

		local objects = data.Objects
		data.Conns.MoveDir = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
			local walking = humanoid.MoveDirection ~= zeroVector3
			if walking and not data.WalkActive then
				data.WalkActive = true
				objects.StateFlag.Visible = false
				objects.WalkFlag.Text = "Walking"
				objects.WalkFlag.Visible = true
				if data.JumpActive then
					objects.WalkFlag.LayoutOrder = 2
					objects.JumpFlag.LayoutOrder = 1
				else
					objects.WalkFlag.LayoutOrder = 1
				end
			elseif not walking and data.WalkActive then
				data.WalkActive = false
				objects.WalkFlag.Visible = false
				if data.JumpActive then
					objects.JumpFlag.LayoutOrder = 1
					objects.StateFlag.Visible = false
				else
					objects.StateFlag.Text = "Standing"
					objects.StateFlag.Visible = true
					objects.StateFlag.LayoutOrder = 1
				end
			end
		end)

		data.Conns.StateChange = humanoid.StateChanged:Connect(function(_, newState)
			local jumping = newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall
			if jumping and not data.JumpActive then
				data.JumpActive = true
				objects.StateFlag.Visible = false
				objects.JumpFlag.Text = "Jumping"
				objects.JumpFlag.Visible = true
				if data.WalkActive then
					objects.JumpFlag.LayoutOrder = 1
					objects.WalkFlag.LayoutOrder = 2
				else
					objects.JumpFlag.LayoutOrder = 1
				end
			elseif not jumping and data.JumpActive then
				data.JumpActive = false
				objects.JumpFlag.Visible = false
				if data.WalkActive then
					objects.WalkFlag.LayoutOrder = 1
					objects.StateFlag.Visible = false
				else
					objects.StateFlag.Text = "Standing"
					objects.StateFlag.Visible = true
					objects.StateFlag.LayoutOrder = 1
				end
			end
		end)

		data.Conns.Ancestry = target.AncestryChanged:Connect(function(_, parent)
			if not parent then
				self:RemoveTarget(target)
			end
		end)
	end)
end

function Arbuzi:RemoveTarget(target)
	local data = self.Cache[target]
	if not data then
		return
	end

	for _, conn in pairs(data.Conns) do
		conn:Disconnect()
	end
	tableClear(data.Conns)

	if data.Objects.TargetHolder then
		data.Objects.TargetHolder:Destroy()
	end
	tableClear(data.Objects)
	self.Cache[target] = nil
end

function Arbuzi:Update(target, data)
	local objects = data.Objects
	local character = data.Character

	if not character or not character.Parent then
		if objects.TargetHolder and objects.TargetHolder.Visible then
			objects.TargetHolder.Visible = false
		end
		return
	end

	local rootPart = data.RootPart or character:FindFirstChild("HumanoidRootPart")
	local humanoid = data.Humanoid or character:FindFirstChildOfClass("Humanoid")

	if not rootPart or not humanoid or humanoid.Health <= 0 then
		if objects.TargetHolder and objects.TargetHolder.Visible then
			objects.TargetHolder.Visible = false
		end
		return
	end

	data.RootPart = rootPart
	data.Humanoid = humanoid
	data.Health = humanoid.Health
	data.MaxHealth = humanoid.MaxHealth

	local w, h, x, y, onScreen = self:CalculateBox(data)
	if not onScreen or not w then
		if objects.TargetHolder and objects.TargetHolder.Visible then
			objects.TargetHolder.Visible = false
		end
		return
	end

	w = mathFloor(w)
	h = mathFloor(h)
	x = mathFloor(x)
	y = mathFloor(y)

	if not objects.TargetHolder.Visible then
		objects.TargetHolder.Visible = true
	end

	if data.LastX ~= x or data.LastY ~= y then
		objects.TargetHolder.Position = udim2FromOffset(x, y)
		data.LastX = x
		data.LastY = y
	end

	if data.LastW ~= w or data.LastH ~= h then
		objects.TargetHolder.Size = udim2FromOffset(w, h)
		objects.BoxGlow.Size = udim2FromOffset(w, h)
		objects.BoxOutlineHolder.Size = udim2FromOffset(w, h)
		objects.BoxInlineHolder.Size = udim2FromOffset(w + 2, h + 2)
		objects.BoxFill.Size = udim2FromOffset(w, h)
		data.LastW = w
		data.LastH = h
	end

	local boxesCfg = config.Boxes
	local textsCfg = config.Texts

	-- Boxes.
	if boxesCfg.Enabled then
		if boxesCfg["Box Glow"].Enabled then
			if objects.BoxGlow.ImageTransparency ~= 0 then
				objects.BoxGlow.ImageTransparency = 0
			end
			local glowTop = boxesCfg["Box Glow"].Top
			local glowBot = boxesCfg["Box Glow"].Bot
			if data.LastGlowTop ~= glowTop or data.LastGlowBot ~= glowBot then
				objects.BoxGlowGradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, glowTop),
					ColorSequenceKeypoint.new(1, glowBot)
				})
				data.LastGlowTop = glowTop
				data.LastGlowBot = glowBot
			end
			local t1 = boxesCfg["Box Glow"].Transparency[1]
			local t2 = boxesCfg["Box Glow"].Transparency[2]
			if data.LastGlowT1 ~= t1 or data.LastGlowT2 ~= t2 then
				objects.BoxGlowGradient.Transparency = numSeq({ numKey(0, t1), numKey(1, t2) })
				data.LastGlowT1 = t1
				data.LastGlowT2 = t2
			end
		else
			if objects.BoxGlow.ImageTransparency ~= 1 then
				objects.BoxGlow.ImageTransparency = 1
			end
		end

		if not objects.BoxOutlineHolder.Visible then
			objects.BoxOutlineHolder.Visible = true
		end
		if not objects.BoxInlineHolder.Visible then
			objects.BoxInlineHolder.Visible = true
		end

		local gradTop = boxesCfg.Gradients.Top
		local gradBot = boxesCfg.Gradients.Bot
		if data.LastGradTop ~= gradTop or data.LastGradBot ~= gradBot then
			objects.BoxInlineGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, gradTop),
				ColorSequenceKeypoint.new(1, gradBot)
			})
			data.LastGradTop = gradTop
			data.LastGradBot = gradBot
		end

		if boxesCfg.Filled.Enabled then
			if not objects.BoxFill.Visible then
				objects.BoxFill.Visible = true
			end
			local fillTop = boxesCfg.Filled.Top
			local fillBot = boxesCfg.Filled.Bot
			local fillT1 = boxesCfg.Filled.Transparency[1]
			local fillT2 = boxesCfg.Filled.Transparency[2]

			if data.LastFillTop ~= fillTop or data.LastFillBot ~= fillBot then
				objects.BoxFillGradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, fillTop),
					ColorSequenceKeypoint.new(1, fillBot)
				})
				data.LastFillTop = fillTop
				data.LastFillBot = fillBot
			end

			if data.LastFillT1 ~= fillT1 or data.LastFillT2 ~= fillT2 then
				objects.BoxFillGradient.Transparency = numSeq({ numKey(0, fillT1), numKey(1, fillT2) })
				data.LastFillT1 = fillT1
				data.LastFillT2 = fillT2
			end
		else
			if objects.BoxFill.Visible then
				objects.BoxFill.Visible = false
			end
		end
	else
		if objects.BoxGlow.ImageTransparency ~= 1 then
			objects.BoxGlow.ImageTransparency = 1
		end
		if objects.BoxOutlineHolder.Visible then
			objects.BoxOutlineHolder.Visible = false
		end
		if objects.BoxInlineHolder.Visible then
			objects.BoxInlineHolder.Visible = false
		end
		if objects.BoxFill.Visible then
			objects.BoxFill.Visible = false
		end
	end

	-- Name.
	if textsCfg.Name.Enabled then
		if not objects.TargetName.Visible then
			objects.TargetName.Visible = true
		end
		local playerObj = playersService:FindFirstChild(target.Name)
		local displayName = playerObj and playerObj.DisplayName or target.Name
		if data.LastDisplayName ~= displayName then
			objects.TargetName.Text = displayName
			data.LastDisplayName = displayName
		end
		local nameColor = textsCfg.Name.Color
		if data.LastNameColor ~= nameColor then
			objects.TargetName.TextColor3 = nameColor
			data.LastNameColor = nameColor
		end
	else
		if objects.TargetName.Visible then
			objects.TargetName.Visible = false
		end
	end

	-- Distance.
	if textsCfg.Distance.Enabled then
		if not objects.Distance.Visible then
			objects.Distance.Visible = true
		end
		local dist = mathFloor((cameraPosition - data.RootPart.Position).Magnitude)
		if data.LastDist ~= dist then
			objects.Distance.Text = stringFormat("%d st", dist)
			data.LastDist = dist
		end
		local distColor = textsCfg.Distance.Color
		if data.LastDistColor ~= distColor then
			objects.Distance.TextColor3 = distColor
			data.LastDistColor = distColor
		end
	else
		if objects.Distance.Visible then
			objects.Distance.Visible = false
		end
	end

	-- State Flags.
	if textsCfg.State.Enabled then
		if data.LastStateColor ~= textsCfg.State.Color then
			objects.StateFlag.TextColor3 = textsCfg.State.Color
			objects.WalkFlag.TextColor3 = textsCfg.State.Color
			objects.JumpFlag.TextColor3 = textsCfg.State.Color
			data.LastStateColor = textsCfg.State.Color
		end
	else
		objects.StateFlag.Visible = false
		objects.WalkFlag.Visible = false
		objects.JumpFlag.Visible = false
	end

	-- Health Bar.
	local healthCfg = config.Bars["Health Bar"]
	if healthCfg.Enabled then
		local health = data.Health or 0
		local maxHealth = data.MaxHealth or 100
		local ratio = mathClamp(health / maxHealth, 0, 1)

		if not objects.LeftBarHolder.Visible then
			objects.LeftBarHolder.Visible = true
		end
		if not objects.HealthBarOutline.Visible then
			objects.HealthBarOutline.Visible = true
		end

		if data.LastRatio ~= ratio then
			objects.HealthBar.Size = newUDim2(1, 0, ratio, 0)
			data.LastRatio = ratio
		end

		local barColor = healthCfg.Color
		if data.LastHealthColor ~= barColor then
			objects.HealthBarGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, barColor),
				ColorSequenceKeypoint.new(1, barColor)
			})
			data.LastHealthColor = barColor
		end

		if ratio < 1 then
			if not objects.HealthBarText.Visible then
				objects.HealthBarText.Visible = true
			end
			local flooredHealth = mathFloor(health)
			if data.LastHealthFloor ~= flooredHealth then
				objects.HealthBarText.Text = stringFormat("%d", flooredHealth)
				objects.HealthBarText.Position = newUDim2(0.5, 0, 1 - ratio, 0)
				data.LastHealthFloor = flooredHealth
			end
		else
			if objects.HealthBarText.Visible then
				objects.HealthBarText.Visible = false
			end
		end
	else
		if objects.HealthBarOutline.Visible then
			objects.HealthBarOutline.Visible = false
		end
		if objects.HealthBarText.Visible then
			objects.HealthBarText.Visible = false
		end
		if objects.LeftBarHolder.Visible then
			objects.LeftBarHolder.Visible = false
		end
	end

	-- Weapon.
	local weaponCfg = textsCfg.Weapon
	if weaponCfg.Enabled then
		if not objects.Weapon.Visible then
			objects.Weapon.Visible = true
		end
		local currentWeapon = "none"
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") then
				currentWeapon = child.Name
				break
			end
		end

		if data.LastWeapon ~= currentWeapon then
			objects.Weapon.Text = currentWeapon
			data.LastWeapon = currentWeapon
		end
		local weaponColor = weaponCfg.Color
		if data.LastWeaponColor ~= weaponColor then
			objects.Weapon.TextColor3 = weaponColor
			data.LastWeaponColor = weaponColor
		end
	else
		if objects.Weapon.Visible then
			objects.Weapon.Visible = false
		end
	end
end

-- Render Loops and Folder Watching.
do
	local postRenderCounter = 0
	local postRenderInterval = 2

	Arbuzi.PreRender = runService.RenderStepped:Connect(function()
		if not config.Enabled then
			for _, data in pairs(Arbuzi.Cache) do
				if data.Objects.TargetHolder and data.Objects.TargetHolder.Visible then
					data.Objects.TargetHolder.Visible = false
				end
			end
			return
		end

		cameraPosition = camera.CFrame.Position
		for target, data in pairs(Arbuzi.Cache) do
			pcall(function()
				Arbuzi:Update(target, data)
			end)
		end
	end)

	local function hookPlayersFolder(folder)
		for _, model in ipairs(folder:GetChildren()) do
			if model:IsA("Model") then
				Arbuzi:AddTarget(model)
			end
		end

		Arbuzi:CreateThreads("FolderChildAdded", folder.ChildAdded, function(child)
			if child:IsA("Model") then
				Arbuzi:AddTarget(child)
			end
		end)

		Arbuzi:CreateThreads("FolderChildRemoved", folder.ChildRemoved, function(child)
			Arbuzi:RemoveTarget(child)
		end)
	end

	local playersFolder = workspaceService:FindFirstChild("Players")
	if playersFolder then
		hookPlayersFolder(playersFolder)
	else
		Arbuzi:CreateThreads("WorkspaceFolderWatcher", workspaceService.ChildAdded, function(child)
			if child.Name == "Players" and child:IsA("Folder") then
				hookPlayersFolder(child)
			end
		end)
	end

	Arbuzi.PostRender = runService.Heartbeat:Connect(function()
		postRenderCounter = postRenderCounter + 1
		if postRenderCounter < postRenderInterval then
			return
		end
		postRenderCounter = 0

		pcall(function()
			local currentFolder = workspaceService:FindFirstChild("Players")
			if currentFolder then
				for _, model in ipairs(currentFolder:GetChildren()) do
					if model:IsA("Model") and not Arbuzi.Cache[model] then
						Arbuzi:AddTarget(model)
					end
				end
			end
		end)
	end)
end

function Arbuzi:Unload()
	if self.PreRender then
		self.PreRender:Disconnect()
		self.PreRender = nil
	end
	if self.PostRender then
		self.PostRender:Disconnect()
		self.PostRender = nil
	end

	for target in pairs(self.Cache) do
		self:RemoveTarget(target)
	end

	for _, conn in pairs(self.Connections) do
		conn:Disconnect()
	end
	tableClear(self.Connections)

	for _, conn in pairs(self.Threads) do
		conn:Disconnect()
	end
	tableClear(self.Threads)

	if self.Holder then
		self.Holder:Destroy()
		self.Holder = nil
	end

	tableClear(self.Cache)
end

shared.Arbuzi = Arbuzi

return Arbuzi
