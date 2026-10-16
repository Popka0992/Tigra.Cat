if getgenv().Syrniki and getgenv().Syrniki.Unload then
	pcall(getgenv().Syrniki.Unload, getgenv().Syrniki)
end

local getService = setmetatable({}, {
	__index = function(_, name)
		return cloneref(game:GetService(name))
	end
})

local workspaceService = getService["Workspace"]
local playersService = getService["Players"]
local runService = getService["RunService"]
local httpService = getService["HttpService"]

local localPlayer = playersService.LocalPlayer
local currentCamera = workspaceService.CurrentCamera
local worldToViewportPoint = currentCamera.WorldToViewportPoint

local newVector3 = Vector3.new
local newVector2 = Vector2.new
local newUDim = UDim.new
local newUDim2 = UDim2.new
local fromOffset = UDim2.fromOffset
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

local ZERO_VECTOR3 = newVector3(0, 0, 0)
local cameraPosition = ZERO_VECTOR3
local cachedFocalLength = 0
local viewportY = 0

local function updateCameraCache()
	currentCamera = workspaceService.CurrentCamera or currentCamera
	if not currentCamera then
		return
	end
	viewportY = currentCamera.ViewportSize.Y
	local halfFovRad = mathRad(currentCamera.FieldOfView) * 0.5
	local tanValue = mathTan(halfFovRad)
	if tanValue > 0 then
		cachedFocalLength = viewportY / (2 * tanValue)
	end
end

updateCameraCache()

local function fetchAsset(url, filename)
	if not isfile(filename) then
		local response = request({
			Url = url,
			Method = "GET"
		})
		if response and response.Body then
			writefile(filename, response.Body)
		end
	end
	return filename
end

local Fonts = {}
do
	local function registerFont(name, weight, style, url, filename)
		fetchAsset(url, filename)
		local jsonName = name .. ".font"
		if isfile(jsonName) then
			delfile(jsonName)
		end
		local info = {
			name = name,
			faces = {
				{
					name = "Normal",
					weight = weight,
					style = style,
					assetId = getcustomasset(filename)
				}
			}
		}
		writefile(jsonName, httpService:JSONEncode(info))
		return Font.new(getcustomasset(jsonName), Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	end

	Fonts.Tahoma = registerFont(
		"Tahoma",
		400,
		"Normal",
		"https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/fs-tahoma-8px.ttf",
		"Tahoma.ttf"
	)
	Fonts.SmallestPixel = registerFont(
		"SmallestPixel",
		400,
		"Normal",
		"https://raw.githubusercontent.com/sametexe001/luas/main/smallest_pixel-7.ttf",
		"smallest_pixel-7.ttf"
	)
end

getgenv().Syrniki = {
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
				Transparency = {0.85, 0.85}
			},
			Gradients = {
				Top = Color3.fromRGB(255, 255, 255),
				Bot = Color3.fromRGB(255, 255, 255)
			},
			Filled = {
				Enabled = true,
				Top = Color3.fromRGB(255, 255, 255),
				Bot = Color3.fromRGB(255, 255, 255),
				Transparency = {0.85, 0.85}
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

local Syrniki = getgenv().Syrniki
local Table = Syrniki.Table
Syrniki.__index = Syrniki

function Syrniki:CreateObjects(name, properties)
	local instance = Instance.new(name)
	for property, value in properties or {} do
		instance[property] = value
	end
	return instance
end

function Syrniki:CreateThreads(name, signal, callback)
	local connection = signal:Connect(callback)
	self.Threads[name] = connection
	return connection
end

Syrniki.Holder = Syrniki:CreateObjects("ScreenGui", {
	Name = "\n",
	Parent = gethui(),
	ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
	ZIndexBehavior = Enum.ZIndexBehavior.Global,
	ResetOnSpawn = false,
	DisplayOrder = -1,
	IgnoreGuiInset = true
})

function Syrniki:InitEsp(data)
	local objects = data.Objects

	objects["TargetHolder"] = self:CreateObjects("Frame", {
		Parent = self.Holder,
		Visible = false,
		BackgroundTransparency = 1,
		Position = newUDim2(0, 0, 0, 0),
		Size = newUDim2(0, 0, 0, 0),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects["TopHolder"] = self:CreateObjects("Frame", {
		Parent = objects["TargetHolder"],
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

	objects["BottomHolder"] = self:CreateObjects("Frame", {
		Parent = objects["TargetHolder"],
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = true,
		BackgroundTransparency = 1,
		Position = newUDim2(0, -2, 1, 3),
		Size = newUDim2(1, 4, 0, 0),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects["LeftHolder"] = self:CreateObjects("Frame", {
		Parent = objects["TargetHolder"],
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

	objects["RightHolder"] = self:CreateObjects("Frame", {
		Parent = objects["TargetHolder"],
		AutomaticSize = Enum.AutomaticSize.X,
		Visible = true,
		BackgroundTransparency = 1,
		Position = newUDim2(1, 5, 0, -2),
		Size = newUDim2(0, 0, 1, 4),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects["TopTextHolder"] = self:CreateObjects("Frame", {
		Parent = objects["TopHolder"],
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = true,
		BackgroundTransparency = 1,
		Position = newUDim2(0, 0, 0, 0),
		Size = newUDim2(1, 0, 0, 0),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects["BottomTextHolder"] = self:CreateObjects("Frame", {
		Parent = objects["BottomHolder"],
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

	objects["LeftTextHolder"] = self:CreateObjects("Frame", {
		Parent = objects["LeftHolder"],
		AutomaticSize = Enum.AutomaticSize.XY,
		Visible = true,
		BackgroundTransparency = 1,
		Position = newUDim2(0, 0, 0, 0),
		Size = newUDim2(1, 0, 0, 0),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects["RightTextHolder"] = self:CreateObjects("Frame", {
		Parent = objects["RightHolder"],
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

	objects["LeftBarHolder"] = self:CreateObjects("Frame", {
		Parent = objects["LeftHolder"],
		AutomaticSize = Enum.AutomaticSize.X,
		Visible = false,
		BackgroundTransparency = 1,
		Position = newUDim2(0, 0, 0, 0),
		Size = newUDim2(0, 0, 1, 0),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects["BottomBarHolder"] = self:CreateObjects("Frame", {
		Parent = objects["BottomHolder"],
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
		Parent = objects["TopTextHolder"],
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = newUDim(0, 1),
		SortOrder = Enum.SortOrder.LayoutOrder
	})
	self:CreateObjects("UIListLayout", {
		Parent = objects["BottomTextHolder"],
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = newUDim(0, -1),
		SortOrder = Enum.SortOrder.LayoutOrder
	})
	self:CreateObjects("UIListLayout", {
		Parent = objects["LeftTextHolder"],
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = newUDim(0, 0),
		SortOrder = Enum.SortOrder.LayoutOrder
	})
	self:CreateObjects("UIListLayout", {
		Parent = objects["RightTextHolder"],
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Padding = newUDim(0, 0),
		SortOrder = Enum.SortOrder.LayoutOrder
	})
	self:CreateObjects("UIListLayout", {
		Parent = objects["LeftBarHolder"],
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = newUDim(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder
	})
	self:CreateObjects("UIListLayout", {
		Parent = objects["BottomBarHolder"],
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = newUDim(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder
	})
	self:CreateObjects("UIListLayout", {
		Parent = objects["TopHolder"],
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = newUDim(0, 1),
		SortOrder = Enum.SortOrder.LayoutOrder
	})
	self:CreateObjects("UIListLayout", {
		Parent = objects["BottomHolder"],
		Padding = newUDim(0, 1),
		SortOrder = Enum.SortOrder.LayoutOrder
	})
	self:CreateObjects("UIListLayout", {
		Parent = objects["LeftHolder"],
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Padding = newUDim(0, 1),
		SortOrder = Enum.SortOrder.LayoutOrder
	})
	self:CreateObjects("UIListLayout", {
		Parent = objects["RightHolder"],
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Padding = newUDim(0, 1),
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	self:CreateObjects("UIPadding", { Parent = objects["TopTextHolder"], PaddingBottom = newUDim(0, 0) })
	self:CreateObjects("UIPadding", { Parent = objects["BottomTextHolder"], PaddingTop = newUDim(0, -1) })
	self:CreateObjects("UIPadding", { Parent = objects["LeftTextHolder"], PaddingTop = newUDim(0, -3) })
	self:CreateObjects("UIPadding", { Parent = objects["RightTextHolder"], PaddingTop = newUDim(0, -3) })
	self:CreateObjects("UIPadding", { Parent = objects["LeftBarHolder"], PaddingRight = newUDim(0, 1) })
	self:CreateObjects("UIPadding", { Parent = objects["BottomBarHolder"], PaddingTop = newUDim(0, 3) })
	self:CreateObjects("UIPadding", { Parent = objects["LeftHolder"], PaddingRight = newUDim(0, 1) })

	objects["BoxGlow"] = self:CreateObjects("ImageLabel", {
		Parent = objects["TargetHolder"],
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

	objects["BoxGlowGradient"] = self:CreateObjects("UIGradient", {
		Parent = objects["BoxGlow"],
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
		}),
		Transparency = numSeq({ numKey(0, 0), numKey(1, 0) })
	})

	self:CreateObjects("UIPadding", {
		Parent = objects["BoxGlow"],
		PaddingTop = newUDim(0, 21),
		PaddingBottom = newUDim(0, 20),
		PaddingLeft = newUDim(0, 21),
		PaddingRight = newUDim(0, 20)
	})

	objects["BoxOutlineHolder"] = self:CreateObjects("Frame", {
		Parent = objects["BoxGlow"],
		Visible = false,
		BackgroundTransparency = 1,
		Position = newUDim2(0, 0, 0, 0),
		Size = newUDim2(0, 0, 0, 0),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects["BoxOutline"] = self:CreateObjects("UIStroke", {
		Parent = objects["BoxOutlineHolder"],
		Thickness = 3,
		LineJoinMode = Enum.LineJoinMode.Miter
	})

	objects["BoxOutlineGradient"] = self:CreateObjects("UIGradient", {
		Parent = objects["BoxOutline"],
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
		}),
		Transparency = numSeq({ numKey(0, 0), numKey(1, 0) })
	})

	objects["BoxInlineHolder"] = self:CreateObjects("Frame", {
		Parent = objects["BoxGlow"],
		Visible = false,
		BackgroundTransparency = 1,
		Position = newUDim2(0, -1, 0, -1),
		Size = newUDim2(0, 0, 0, 0),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects["BoxInline"] = self:CreateObjects("UIStroke", {
		Parent = objects["BoxInlineHolder"],
		Color = Color3.fromRGB(255, 255, 255),
		LineJoinMode = Enum.LineJoinMode.Miter
	})

	objects["BoxInlineGradient"] = self:CreateObjects("UIGradient", {
		Parent = objects["BoxInline"],
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
		}),
		Transparency = numSeq({ numKey(0, 0), numKey(1, 0) })
	})

	objects["BoxFill"] = self:CreateObjects("Frame", {
		Parent = objects["BoxGlow"],
		Visible = false,
		BackgroundTransparency = 0,
		Position = newUDim2(0, 0, 0, 0),
		Size = newUDim2(0, 0, 0, 0),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects["BoxFillGradient"] = self:CreateObjects("UIGradient", {
		Parent = objects["BoxFill"],
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
		}),
		Transparency = numSeq({ numKey(0, 1), numKey(1, 1) })
	})

	objects["HealthBarOutline"] = self:CreateObjects("Frame", {
		Parent = objects["LeftBarHolder"],
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
		Parent = objects["HealthBarOutline"],
		Thickness = 1,
		LineJoinMode = Enum.LineJoinMode.Miter
	})

	objects["HealthBar"] = self:CreateObjects("Frame", {
		Parent = objects["HealthBarOutline"],
		ZIndex = 6,
		AnchorPoint = newVector2(0, 1),
		Position = newUDim2(0, 0, 1, 0),
		Size = newUDim2(1, 0, 1, 0),
		BorderSizePixel = 0,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		ClipsDescendants = true
	})

	objects["HealthBarGradient"] = self:CreateObjects("UIGradient", {
		Parent = objects["HealthBar"],
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Table.Bars["Health Bar"].Color),
			ColorSequenceKeypoint.new(1, Table.Bars["Health Bar"].Color)
		}),
		Transparency = numSeq({ numKey(0, 0), numKey(1, 0) })
	})

	objects["HealthBarText"] = self:CreateObjects("TextLabel", {
		Parent = objects["HealthBarOutline"],
		FontFace = Fonts.SmallestPixel,
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
		Parent = objects["HealthBarText"],
		Color = Color3.fromRGB(0, 0, 0),
		LineJoinMode = Enum.LineJoinMode.Miter
	})

	objects["TargetName"] = self:CreateObjects("TextLabel", {
		Parent = objects["TopTextHolder"],
		FontFace = Fonts.Tahoma,
		TextSize = 12,
		LayoutOrder = 2,
		TextColor3 = Table.Texts.Name.Color,
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
		Parent = objects["TargetName"],
		Color = Color3.fromRGB(0, 0, 0),
		LineJoinMode = Enum.LineJoinMode.Miter
	})

	objects["Distance"] = self:CreateObjects("TextLabel", {
		Parent = objects["BottomTextHolder"],
		FontFace = Fonts.SmallestPixel,
		TextSize = 9,
		LayoutOrder = 2,
		TextColor3 = Table.Texts.Distance.Color,
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
		Parent = objects["Distance"],
		Color = Color3.fromRGB(0, 0, 0),
		LineJoinMode = Enum.LineJoinMode.Miter
	})

	objects["WalkFlag"] = self:CreateObjects("TextLabel", {
		Parent = objects["RightTextHolder"],
		FontFace = Fonts.SmallestPixel,
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
		Parent = objects["WalkFlag"],
		Color = Color3.fromRGB(0, 0, 0),
		LineJoinMode = Enum.LineJoinMode.Miter
	})

	objects["JumpFlag"] = self:CreateObjects("TextLabel", {
		Parent = objects["RightTextHolder"],
		FontFace = Fonts.SmallestPixel,
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
		Parent = objects["JumpFlag"],
		Color = Color3.fromRGB(0, 0, 0),
		LineJoinMode = Enum.LineJoinMode.Miter
	})

	objects["StateFlag"] = self:CreateObjects("TextLabel", {
		Parent = objects["RightTextHolder"],
		FontFace = Fonts.SmallestPixel,
		TextSize = 9,
		LayoutOrder = 3,
		TextColor3 = Table.Texts.State.Color,
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
		Parent = objects["StateFlag"],
		Color = Color3.fromRGB(0, 0, 0),
		LineJoinMode = Enum.LineJoinMode.Miter
	})

	objects["Weapon"] = self:CreateObjects("TextLabel", {
		Parent = objects["BottomTextHolder"],
		FontFace = Fonts.SmallestPixel,
		TextSize = 9,
		LayoutOrder = 3,
		TextColor3 = Table.Texts.Weapon.Color,
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
		Parent = objects["Weapon"],
		Color = Color3.fromRGB(0, 0, 0),
		LineJoinMode = Enum.LineJoinMode.Miter
	})
end

local STANDARD_RIG_PARTS = {
	["Head"] = true,
	["Torso"] = true,
	["HumanoidRootPart"] = true,
	["Left Arm"] = true,
	["Right Arm"] = true,
	["Left Leg"] = true,
	["Right Leg"] = true,
	["UpperTorso"] = true,
	["LowerTorso"] = true,
	["LeftUpperArm"] = true,
	["LeftLowerArm"] = true,
	["LeftHand"] = true,
	["RightUpperArm"] = true,
	["RightLowerArm"] = true,
	["RightHand"] = true,
	["LeftUpperLeg"] = true,
	["LeftLowerLeg"] = true,
	["LeftFoot"] = true,
	["RightUpperLeg"] = true,
	["RightLowerLeg"] = true,
	["RightFoot"] = true,
	["Humanoid"] = true,
	["Animate"] = true
}

local function resolveWeapon(target, character)
	if not character then
		return "None"
	end

	local tool = character:FindFirstChildOfClass("Tool")
	if tool then
		return tool.Name
	end

	local weaponAttribute = character:GetAttribute("CurrentWeapon")
		or character:GetAttribute("EquippedWeapon")
		or character:GetAttribute("Weapon")
		or character:GetAttribute("Gun")
		or (target:IsA("Player") and (target:GetAttribute("CurrentWeapon") or target:GetAttribute("EquippedWeapon") or target:GetAttribute("Weapon") or target:GetAttribute("Gun")))

	if weaponAttribute and type(weaponAttribute) == "string" and weaponAttribute ~= "" then
		return weaponAttribute
	end

	local weaponValue = character:FindFirstChild("CurrentWeapon")
		or character:FindFirstChild("EquippedWeapon")
		or character:FindFirstChild("Weapon")
		or character:FindFirstChild("EquippedTool")
		or (target:IsA("Player") and (target:FindFirstChild("CurrentWeapon") or target:FindFirstChild("EquippedWeapon") or target:FindFirstChild("Weapon")))

	if weaponValue then
		if weaponValue:IsA("StringValue") and weaponValue.Value ~= "" then
			return weaponValue.Value
		elseif weaponValue:IsA("ObjectValue") and weaponValue.Value then
			return weaponValue.Value.Name
		end
	end

	for _, child in character:GetChildren() do
		if child:IsA("Model") and not child:IsA("Accessory") and not STANDARD_RIG_PARTS[child.Name] then
			local lowerName = string.lower(child.Name)
			if not string.find(lowerName, "hitbox") and not string.find(lowerName, "ragdoll") and not string.find(lowerName, "armor") and not string.find(lowerName, "vest") and not string.find(lowerName, "helmet") then
				if child:FindFirstChild("Handle") or child:FindFirstChild("Muzzle") or child:FindFirstChild("FirePoint") or child:FindFirstChild("Sight") or child:FindFirstChild("Barrel") then
					return child.Name
				end
				if child:FindFirstChildOfClass("BasePart") then
					return child.Name
				end
			end
		end
	end

	local rightArm = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if rightArm then
		for _, child in rightArm:GetChildren() do
			if child:IsA("JointInstance") then
				local connectedPart = (child.Part1 ~= rightArm and child.Part1) or (child.Part0 ~= rightArm and child.Part0)
				if connectedPart and connectedPart.Parent and connectedPart.Parent ~= character and connectedPart.Parent:IsA("Model") and not connectedPart.Parent:IsA("Accessory") then
					return connectedPart.Parent.Name
				end
			end
		end
	end

	return "None"
end

function Syrniki:CalculateBox(data)
	local rootPart = data.RootPart
	if not rootPart or not rootPart.Parent then
		return nil, nil, nil, nil, false
	end

	local rootScreen, onScreen = worldToViewportPoint(currentCamera, rootPart.Position)
	if not onScreen or rootScreen.Z <= 0 then
		return nil, nil, nil, nil, false
	end

	local boundingBoxCfg = Table.Boxes["Bounding Box"]
	if boundingBoxCfg.Enabled then
		local children = data.Children or data.Character:GetChildren()
		local includeAccessories = boundingBoxCfg.IncludeAccessories
		local scrMinX, scrMinY = mathHuge, mathHuge
		local scrMaxX, scrMaxY = -mathHuge, -mathHuge
		local hasValidParts = false

		for _, part in children do
			if part:IsA("BasePart") and part.Transparency ~= 1 and part ~= rootPart then
				local partParent = part.Parent
				if not partParent then
					continue
				end
				if not includeAccessories and partParent:IsA("Accessory") then
					continue
				end

				local partScreen, partOnScreen = worldToViewportPoint(currentCamera, part.Position)
				if not partOnScreen or partScreen.Z <= 0 then
					continue
				end

				hasValidParts = true
				local cf = part.CFrame
				local sz = part.Size
				local hx, hy, hz = sz.X * 0.5, sz.Y * 0.5, sz.Z * 0.5
				local depthScale = (cachedFocalLength > 0 and cachedFocalLength / partScreen.Z) or (viewportY / (partScreen.Z * 2))

				local ex = (mathAbs(cf.RightVector.X * hx) + mathAbs(cf.UpVector.X * hy) + mathAbs(cf.LookVector.X * hz)) * depthScale
				local ey = (mathAbs(cf.RightVector.Y * hx) + mathAbs(cf.UpVector.Y * hy) + mathAbs(cf.LookVector.Y * hz)) * depthScale

				local pMinX, pMaxX = partScreen.X - ex, partScreen.X + ex
				local pMinY, pMaxY = partScreen.Y - ey, partScreen.Y + ey

				if pMinX < scrMinX then scrMinX = pMinX end
				if pMaxX > scrMaxX then scrMaxX = pMaxX end
				if pMinY < scrMinY then scrMinY = pMinY end
				if pMaxY > scrMaxY then scrMaxY = pMaxY end
			end
		end

		if not hasValidParts then
			local scale = (rootPart.Size.Y * viewportY) / (rootScreen.Z * 2)
			local w, h = 3 * scale, 4.5 * scale
			return w, h, rootScreen.X - (w * 0.5), rootScreen.Y - (h * 0.5), true
		end

		local padX = boundingBoxCfg.BoxX
		local padY = boundingBoxCfg.BoxY
		local w = (scrMaxX - scrMinX) + padX
		local h = (scrMaxY - scrMinY) + padY
		return w, h, scrMinX - (padX * 0.5), scrMinY - (padY * 0.5), true
	else
		local scale = (rootPart.Size.Y * viewportY) / (rootScreen.Z * 2)
		local w, h = 3 * scale, 4.5 * scale
		return w, h, rootScreen.X - (w * 0.5), rootScreen.Y - (h * 0.5), true
	end
end

function Syrniki:AddTarget(target)
	local isPlayer = target:IsA("Player")
	local botName = Table.Bots.Name or "bot"
	local isBot = not isPlayer and target:IsA("Model") and target.Name == botName

	if not isPlayer and not isBot then
		return
	end
	if self.Cache[target] then
		return
	end
	if isPlayer and target == localPlayer then
		return
	end

	local data = {
		Target = target,
		IsBot = isBot,
		IsPlayer = isPlayer,
		Objects = {},
		Character = nil,
		RootPart = nil,
		Humanoid = nil,
		Children = nil,
		Health = 100,
		MaxHealth = 100,
		Alive = false,
		LastW = nil,
		LastH = nil,
		LastX = nil,
		LastY = nil,
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
		LastStateColor = nil
	}

	self:InitEsp(data)
	self.Cache[target] = data
end

function Syrniki:RemoveTarget(target)
	local data = self.Cache[target]
	if not data then
		return
	end

	if data.Objects.TargetHolder then
		data.Objects.TargetHolder:Destroy()
	end
	tableClear(data.Objects)
	self.Cache[target] = nil
end

function Syrniki:Update(target, data)
	local objects = data.Objects
	local targetHolder = objects.TargetHolder
	if not targetHolder then
		return
	end

	local character
	if data.IsPlayer then
		character = target.Character
	else
		character = target
	end

	if not character or not character.Parent or not character:IsDescendantOf(workspaceService) then
		if targetHolder.Visible then
			targetHolder.Visible = false
		end
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") or character:FindFirstChildOfClass("BasePart")

	if not humanoid or not rootPart then
		if targetHolder.Visible then
			targetHolder.Visible = false
		end
		return
	end

	local isDead = humanoid.Health <= 0
		or humanoid:GetState() == Enum.HumanoidStateType.Dead
		or character:GetAttribute("Dead") == true
		or character:GetAttribute("IsDead") == true
		or (data.IsPlayer and (target:GetAttribute("Dead") == true or target:GetAttribute("IsDead") == true))

	if isDead then
		if targetHolder.Visible then
			targetHolder.Visible = false
		end
		return
	end

	data.Character = character
	data.Humanoid = humanoid
	data.RootPart = rootPart
	data.Children = character:GetChildren()
	data.Health = humanoid.Health
	data.MaxHealth = (humanoid.MaxHealth > 0 and humanoid.MaxHealth) or 100

	local w, h, x, y, onScreen = self:CalculateBox(data)
	if not onScreen or not w or not h or not x or not y then
		if targetHolder.Visible then
			targetHolder.Visible = false
		end
		return
	end

	w = mathFloor(w)
	h = mathFloor(h)
	x = mathFloor(x)
	y = mathFloor(y)

	if not targetHolder.Visible then
		targetHolder.Visible = true
	end

	if data.LastX ~= x or data.LastY ~= y then
		targetHolder.Position = fromOffset(x, y)
		data.LastX = x
		data.LastY = y
	end

	if data.LastW ~= w or data.LastH ~= h then
		targetHolder.Size = fromOffset(w, h)
		objects.BoxGlow.Size = fromOffset(w, h)
		objects.BoxOutlineHolder.Size = fromOffset(w, h)
		objects.BoxInlineHolder.Size = fromOffset(w + 2, h + 2)
		objects.BoxFill.Size = fromOffset(w, h)
		data.LastW = w
		data.LastH = h
	end

	local boxesCfg = Table.Boxes
	local textsCfg = Table.Texts

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

	if textsCfg.Name.Enabled then
		if not objects.TargetName.Visible then
			objects.TargetName.Visible = true
		end
		local displayName = (data.IsBot and "Soldier") or target.DisplayName
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

	if textsCfg.Distance.Enabled then
		if not objects.Distance.Visible then
			objects.Distance.Visible = true
		end
		local dist = mathFloor((cameraPosition - rootPart.Position).Magnitude)
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

	if textsCfg.State.Enabled then
		local humanoidState = humanoid:GetState()
		local isJumping = humanoidState == Enum.HumanoidStateType.Jumping or humanoidState == Enum.HumanoidStateType.Freefall
		local isWalking = humanoid.MoveDirection.Magnitude > 0.05

		if isJumping then
			objects.JumpFlag.Visible = true
			objects.WalkFlag.Visible = false
			objects.StateFlag.Visible = false
		elseif isWalking then
			objects.JumpFlag.Visible = false
			objects.WalkFlag.Visible = true
			objects.StateFlag.Visible = false
		else
			objects.JumpFlag.Visible = false
			objects.WalkFlag.Visible = false
			objects.StateFlag.Visible = true
		end

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

	local healthCfg = Table.Bars["Health Bar"]
	if healthCfg.Enabled then
		local ratio = mathClamp(data.Health / data.MaxHealth, 0, 1)

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
			local flooredHealth = mathFloor(data.Health)
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

	local weaponCfg = textsCfg.Weapon
	if weaponCfg.Enabled then
		if not objects.Weapon.Visible then
			objects.Weapon.Visible = true
		end

		local currentWeapon = resolveWeapon(target, character)
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

local postRenderCounter = 0
local POST_RENDER_INTERVAL = 2

Syrniki.PreRender = runService.RenderStepped:Connect(function()
	updateCameraCache()

	if not Table.Enabled then
		for _, data in Syrniki.Cache do
			if data.Objects.TargetHolder and data.Objects.TargetHolder.Visible then
				data.Objects.TargetHolder.Visible = false
			end
		end
		return
	end

	cameraPosition = currentCamera.CFrame.Position

	for target, data in Syrniki.Cache do
		Syrniki:Update(target, data)
	end
end)

Syrniki.PostRender = runService.Heartbeat:Connect(function()
	postRenderCounter = postRenderCounter + 1
	if postRenderCounter < POST_RENDER_INTERVAL then
		return
	end
	postRenderCounter = 0

	for _, player in playersService:GetPlayers() do
		if not Syrniki.Cache[player] then
			Syrniki:AddTarget(player)
		end
	end

	if Table.Bots.Enabled then
		local botName = Table.Bots.Name or "bot"
		for _, bot in workspaceService:GetChildren() do
			if bot:IsA("Model") and bot.Name == botName and not Syrniki.Cache[bot] then
				Syrniki:AddTarget(bot)
			end
		end
	end

	for target, data in Syrniki.Cache do
		if data.IsBot and not Table.Bots.Enabled then
			Syrniki:RemoveTarget(target)
		end
	end
end)

for _, player in playersService:GetPlayers() do
	Syrniki:AddTarget(player)
end

Syrniki:CreateThreads("PlayerAdded", playersService.PlayerAdded, function(player)
	Syrniki:AddTarget(player)
end)

Syrniki:CreateThreads("PlayerRemoving", playersService.PlayerRemoving, function(player)
	Syrniki:RemoveTarget(player)
end)

function Syrniki:Unload()
	if Syrniki.PreRender then
		Syrniki.PreRender:Disconnect()
		Syrniki.PreRender = nil
	end
	if Syrniki.PostRender then
		Syrniki.PostRender:Disconnect()
		Syrniki.PostRender = nil
	end

	for target in self.Cache do
		self:RemoveTarget(target)
	end

	for _, conn in self.Connections do
		conn:Disconnect()
	end
	tableClear(self.Connections)

	for _, conn in self.Threads do
		conn:Disconnect()
	end
	tableClear(self.Threads)

	if self.Holder then
		self.Holder:Destroy()
		self.Holder = nil
	end

	tableClear(self.Cache)
end

return Syrniki
