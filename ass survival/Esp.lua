if not shared then
	return warn("No shared, no script.")
end

loadstring("getfenv().LPH_NO_VIRTUALIZE = function(...) return ... end")()
getfenv().PP_SCRAMBLE_NUM = function(...) return ... end
getfenv().PP_SCRAMBLE_STR = function(...) return ... end
getfenv().PP_SCRAMBLE_RE_NUM = function(...) return ... end

if shared.Arbuzi and shared.Arbuzi.Unload then
	pcall(shared.Arbuzi.Unload, shared.Arbuzi)
end

local cloneref = cloneref or function(instance) return instance end
local workspaceService = cloneref(game:GetService("Workspace"))
local playersService = cloneref(game:GetService("Players"))
local runService = cloneref(game:GetService("RunService"))
local replicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local httpService = cloneref(game:GetService("HttpService"))
local coreGui = cloneref(game:GetService("CoreGui"))

local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
local localPlayer = playersService.LocalPlayer
local camera = workspaceService.CurrentCamera

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

local zeroVector3 = newVector3(0, 0, 0)
local cameraPosition = newVector3(0, 0, 0)
local cachedFocalLength = 0
local viewPortY = 0

local weaponMeshMap = {}
local toolSignatures = {}
local weaponIcons = {}

local function indexUniversalTools()
	pcall(function()
		local prefabs = workspaceService:FindFirstChild("Prefabs", true) or replicatedStorage:FindFirstChild("Prefabs", true) or workspaceService:FindFirstChild("Tools", true)
		if not prefabs then return end
		local tools = prefabs:FindFirstChild("Tools") or prefabs
		for _, tool in ipairs(tools:GetChildren()) do
			local worldModel = tool:FindFirstChild("Worldmodel")
			if worldModel then
				local signature = {}
				for _, part in ipairs(worldModel:GetChildren()) do
					if part:IsA("MeshPart") and part.MeshId ~= "" then
						weaponMeshMap[part.MeshId] = tool.Name
					end
					signature[part.Name] = true
				end
				toolSignatures[tool.Name] = signature
			end
		end
	end)
end
task.spawn(indexUniversalTools)

local function resolveEquippedWeapon(character)
	local tool = character:FindFirstChildOfClass("Tool")
	if tool then
		return tool.Name
	end

	local worldModel = character:FindFirstChild("Worldmodel")
	if not worldModel then
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") then
				return child.Name
			end
		end
		return "none"
	end

	local attr = worldModel:GetAttribute("Weapon")
		or worldModel:GetAttribute("Name")
		or character:GetAttribute("EquippedWeapon")
		or character:GetAttribute("Weapon")
	if attr and typeof(attr) == "string" and attr ~= "" then
		return attr
	end

	local children = worldModel:GetChildren()
	if #children == 0 then
		return "Worldmodel"
	end

	for _, part in ipairs(children) do
		if part:IsA("MeshPart") and part.MeshId ~= "" then
			local matched = weaponMeshMap[part.MeshId]
			if matched then return matched end
		end
	end

	local bestTool, bestScore = nil, 0
	for toolName, sig in pairs(toolSignatures) do
		local score = 0
		for _, part in ipairs(children) do
			if sig[part.Name] then
				score = score + 1
			end
		end
		if score > bestScore then
			bestScore = score
			bestTool = toolName
		end
	end

	if bestTool and bestScore >= 2 then
		return bestTool
	end

	return "Worldmodel"
end

local function updateCameraCache()
	camera = workspaceService.CurrentCamera or camera
	if not camera then return end
	local vp = camera.ViewportSize
	if vp.Y > 0 then
		viewPortY = vp.Y
		local fov = camera.FieldOfView
		if fov and fov > 0 then
			cachedFocalLength = viewPortY / (2 * mathTan(mathRad(fov) * 0.5))
		end
	end
end

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
	Directory = "Esp",
	Cache = {},
	Holder = nil,
	Threads = {},
	PreRender = nil,
	LastRenderTime = 0,
	Table = {
		Enabled = true,
		LimitFPS = 0,
		Players = true,
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
				Enabled = false,
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
			WeaponIcon = {
				Enabled = true,
				Size = 24
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

local Fonts = {}
do
	local function fetchSource(url)
		local response = httpRequest({ Url = url, Method = "GET" })
		return response and response.Body or ""
	end

	local function registerFont(name, weight, style, asset)
		if isfile(asset.Id) then
			local content = readfile(asset.Id)
			if #content < 1000 then
				delfile(asset.Id)
			end
		end

		if not isfile(asset.Id) then
			writefile(asset.Id, asset.Font)
		end

		if not isfile(name .. ".font") then
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
		end
		return getcustomasset(name .. ".font")
	end

	Fonts.Tahoma = registerFont("Tahoma", 400, "Normal", {
		Id = "Tahoma.ttf",
		Font = fetchSource("https://raw.githubusercontent.com/i77lhm/storage/main/fonts/fs-tahoma-8px.ttf")
	})

	Fonts.SmallestPixel = registerFont("SmallestPixel", 400, "Normal", {
		Id = "smallest_pixel-7.ttf",
		Font = fetchSource("https://raw.githubusercontent.com/i77lhm/storage/main/fonts/smallest_pixel-7.ttf")
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

function Arbuzi:InitEsp(data)
	local objects = data.Objects

	objects.TargetHolder = self:CreateObjects("Frame", {
		Parent = self.Holder,
		Visible = false,
		BackgroundTransparency = 1,
		Position = newUDim2(0, 0, 0, 0),
		Size = newUDim2(0, 0, 0, 0),
		BorderSizePixel = 0
	})

	objects.TopHolder = self:CreateObjects("Frame", {
		Parent = objects.TargetHolder,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		AnchorPoint = newVector2(0, 1),
		Position = newUDim2(0, -2, 0, -5),
		Size = newUDim2(1, 4, 0, 0),
		BorderSizePixel = 0
	})

	objects.BottomHolder = self:CreateObjects("Frame", {
		Parent = objects.TargetHolder,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Position = newUDim2(0, -2, 1, 3),
		Size = newUDim2(1, 4, 0, 0),
		BorderSizePixel = 0
	})

	objects.LeftHolder = self:CreateObjects("Frame", {
		Parent = objects.TargetHolder,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		AnchorPoint = newVector2(1, 0),
		Position = newUDim2(0, -5, 0, -2),
		Size = newUDim2(0, 0, 1, 4),
		BorderSizePixel = 0
	})

	objects.RightHolder = self:CreateObjects("Frame", {
		Parent = objects.TargetHolder,
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Position = newUDim2(1, 5, 0, -2),
		Size = newUDim2(0, 0, 1, 4),
		BorderSizePixel = 0
	})

	objects.TopTextHolder = self:CreateObjects("Frame", {
		Parent = objects.TopHolder,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = newUDim2(1, 0, 0, 0),
		BorderSizePixel = 0
	})

	objects.BottomTextHolder = self:CreateObjects("Frame", {
		Parent = objects.BottomHolder,
		LayoutOrder = 2,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = newUDim2(1, 0, 0, 0),
		BorderSizePixel = 0
	})

	objects.LeftTextHolder = self:CreateObjects("Frame", {
		Parent = objects.LeftHolder,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Size = newUDim2(1, 0, 0, 0),
		BorderSizePixel = 0
	})

	objects.RightTextHolder = self:CreateObjects("Frame", {
		Parent = objects.RightHolder,
		LayoutOrder = 2,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Size = newUDim2(0, 0, 0, 0),
		BorderSizePixel = 0
	})

	objects.LeftBarHolder = self:CreateObjects("Frame", {
		Parent = objects.LeftHolder,
		AutomaticSize = Enum.AutomaticSize.X,
		Visible = false,
		BackgroundTransparency = 1,
		Size = newUDim2(0, 0, 1, 0),
		BorderSizePixel = 0
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
		BorderSizePixel = 0
	})

	objects.BoxGlowGradient = self:CreateObjects("UIGradient", {
		Parent = objects.BoxGlow,
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(0, 0, 0)),
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
		Size = newUDim2(0, 0, 0, 0),
		BorderSizePixel = 0
	})

	objects.BoxOutline = self:CreateObjects("UIStroke", {
		Parent = objects.BoxOutlineHolder,
		Thickness = 3,
		LineJoinMode = Enum.LineJoinMode.Miter
	})

	objects.BoxInlineHolder = self:CreateObjects("Frame", {
		Parent = objects.BoxGlow,
		Visible = false,
		BackgroundTransparency = 1,
		Position = newUDim2(0, -1, 0, -1),
		Size = newUDim2(0, 0, 0, 0),
		BorderSizePixel = 0
	})

	objects.BoxInline = self:CreateObjects("UIStroke", {
		Parent = objects.BoxInlineHolder,
		Color = Color3.fromRGB(255, 255, 255),
		LineJoinMode = Enum.LineJoinMode.Miter
	})

	objects.BoxInlineGradient = self:CreateObjects("UIGradient", {
		Parent = objects.BoxInline,
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	})

	objects.BoxFill = self:CreateObjects("Frame", {
		Parent = objects.BoxGlow,
		Visible = false,
		BackgroundTransparency = 0,
		Size = newUDim2(0, 0, 0, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects.BoxFillGradient = self:CreateObjects("UIGradient", {
		Parent = objects.BoxFill,
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
		Transparency = numSeq({ numKey(0, 1), numKey(1, 1) })
	})

	objects.HealthBarOutline = self:CreateObjects("Frame", {
		Parent = objects.LeftBarHolder,
		ZIndex = 5,
		Visible = false,
		Position = newUDim2(0, 0, 0, 0),
		Size = newUDim2(0, 2, 1, 0),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0)
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
		BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	})

	objects.HealthBarGradient = self:CreateObjects("UIGradient", {
		Parent = objects.HealthBar,
		Rotation = 90,
		Color = ColorSequence.new(config.Bars["Health Bar"].Color)
	})

	objects.HealthBarText = self:CreateObjects("TextLabel", {
		Parent = objects.HealthBarOutline,
		FontFace = Arbuzi.SmallestPixel,
		TextSize = 9,
		ZIndex = 10,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = newVector2(0.5, 0.5),
		Position = newUDim2(0.5, 0, 1, 0),
		BorderSizePixel = 0,
		Visible = false,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY
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
		AutomaticSize = Enum.AutomaticSize.XY
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
		AutomaticSize = Enum.AutomaticSize.XY
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
		BorderSizePixel = 0,
		Visible = false,
		BackgroundTransparency = 1,
		ZIndex = 5,
		AutomaticSize = Enum.AutomaticSize.XY
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
		BorderSizePixel = 0,
		Visible = false,
		BackgroundTransparency = 1,
		ZIndex = 5,
		AutomaticSize = Enum.AutomaticSize.XY
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
		BorderSizePixel = 0,
		Visible = false,
		BackgroundTransparency = 1,
		ZIndex = 5,
		AutomaticSize = Enum.AutomaticSize.XY
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
		BorderSizePixel = 0,
		Visible = false,
		BackgroundTransparency = 1,
		ZIndex = 5,
		AutomaticSize = Enum.AutomaticSize.XY
	})

	self:CreateObjects("UIStroke", {
		Parent = objects.Weapon,
		Color = Color3.fromRGB(0, 0, 0),
		LineJoinMode = Enum.LineJoinMode.Miter
	})

	objects.WeaponIcon = self:CreateObjects("ImageLabel", {
		Parent = objects.BottomTextHolder,
		LayoutOrder = 4,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		Size = udim2FromOffset(24, 24),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 5
	})
end

function Arbuzi:CalculateBox(data)
	if not camera then
		return nil, nil, nil, nil, false
	end

	local rootPart = data.RootPart
	if not rootPart or not rootPart.Parent then
		return nil, nil, nil, nil, false
	end

	local rootScreen, onScreen = camera:WorldToViewportPoint(rootPart.Position)
	if not onScreen or rootScreen.Z <= 0 then
		return nil, nil, nil, nil, false
	end

	local boundingBox = config.Boxes["Bounding Box"]
	if boundingBox.Enabled then
		local character = data.Character
		local scrMinX, scrMinY = math.huge, math.huge
		local scrMaxX, scrMaxY = -math.huge, -math.huge
		local hasValidParts = false
		local includeAccessories = boundingBox.IncludeAccessories

		for _, part in ipairs(character:GetChildren()) do
			if part:IsA("BasePart") and part.Transparency ~= 1 and part ~= rootPart then
				local parent = part.Parent
				if not includeAccessories and parent and parent:IsA("Accessory") then
					continue
				end

				local partScreen, partOnScreen = camera:WorldToViewportPoint(part.Position)
				if not partOnScreen or partScreen.Z <= 0 then
					continue
				end

				hasValidParts = true
				local cf = part.CFrame
				local sz = part.Size
				local hx, hy, hz = sz.X * 0.5, sz.Y * 0.5, sz.Z * 0.5
				local rx, uy, lz = cf.RightVector, cf.UpVector, cf.LookVector
				local depthScale = (cachedFocalLength > 0 and cachedFocalLength or (viewPortY * 0.7)) / partScreen.Z

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

function Arbuzi:AddTarget(target)
	if not target or not target:IsA("Model") then return end
	if target == localPlayer.Character or (localPlayer and target.Name == localPlayer.Name) then return end
	if self.Cache[target] and typeof(self.Cache[target]) == "table" then return end
	if self.Cache[target] == "pending" then return end

	self.Cache[target] = "pending"

	task.spawn(function()
		local rootPart, humanoid
		local attempts = 0

		while target.Parent and self.Cache[target] == "pending" and attempts < 25 do
			rootPart = target:FindFirstChild("HumanoidRootPart")
				or target:FindFirstChild("Torso")
				or target:FindFirstChild("UpperTorso")
				or target.PrimaryPart
				or target:FindFirstChild("Head")

			humanoid = target:FindFirstChildOfClass("Humanoid")
			if rootPart and humanoid then break end
			attempts = attempts + 1
			task.wait(0.1)
		end

		if not target.Parent or self.Cache[target] ~= "pending" or not rootPart or not humanoid then
			self.Cache[target] = nil
			return
		end

		local data = {
			Target = target,
			Objects = {},
			Conns = {},
			Character = target,
			RootPart = rootPart,
			Humanoid = humanoid,
			Health = humanoid.Health,
			MaxHealth = humanoid.MaxHealth,
			Alive = humanoid.Health > 0,
			CurrentWeapon = resolveEquippedWeapon(target),
			WalkActive = false,
			JumpActive = false,
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
			LastStateColor = nil,
			LastIcon = nil,
			LastIconSize = nil
		}

		self:InitEsp(data)
		self.Cache[target] = data

		data.Conns.Health = humanoid.HealthChanged:Connect(function(newHealth)
			data.Alive = newHealth > 0
			data.Health = newHealth
		end)

		data.Conns.Died = humanoid.Died:Connect(function()
			data.Alive = false
		end)

		data.Conns.ChildAdded = target.ChildAdded:Connect(function(child)
			if child:IsA("Tool") or child.Name == "Worldmodel" then
				task.delay(0.05, function()
					data.CurrentWeapon = resolveEquippedWeapon(target)
				end)
			end
		end)

		data.Conns.ChildRemoved = target.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") or child.Name == "Worldmodel" then
				task.delay(0.05, function()
					data.CurrentWeapon = resolveEquippedWeapon(target)
				end)
			end
		end)

		local objects = data.Objects
		data.Conns.MoveDir = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
			local walking = humanoid.MoveDirection ~= zeroVector3
			if walking and not data.WalkActive then
				data.WalkActive = true
				objects.StateFlag.Visible = false
				objects.WalkFlag.Visible = true
			elseif not walking and data.WalkActive then
				data.WalkActive = false
				objects.WalkFlag.Visible = false
				if not data.JumpActive then
					objects.StateFlag.Visible = true
				end
			end
		end)

		data.Conns.StateChange = humanoid.StateChanged:Connect(function(_, newState)
			local jumping = newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall
			if jumping and not data.JumpActive then
				data.JumpActive = true
				objects.StateFlag.Visible = false
				objects.JumpFlag.Visible = true
			elseif not jumping and data.JumpActive then
				data.JumpActive = false
				objects.JumpFlag.Visible = false
				if not data.WalkActive then
					objects.StateFlag.Visible = true
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
	if not data then return end

	if typeof(data) ~= "table" then
		self.Cache[target] = nil
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

	local rootPart = data.RootPart
	local humanoid = data.Humanoid

	if not rootPart or not rootPart.Parent then
		rootPart = character:FindFirstChild("HumanoidRootPart")
			or character:FindFirstChild("Torso")
			or character:FindFirstChild("UpperTorso")
			or character.PrimaryPart
			or character:FindFirstChild("Head")
		data.RootPart = rootPart
	end

	if not humanoid or not humanoid.Parent then
		humanoid = character:FindFirstChildOfClass("Humanoid")
		data.Humanoid = humanoid
	end

	if not rootPart or not humanoid or humanoid.Health <= 0 then
		if objects.TargetHolder and objects.TargetHolder.Visible then
			objects.TargetHolder.Visible = false
		end
		return
	end

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

	if not objects.TargetHolder.Visible then objects.TargetHolder.Visible = true end

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

	if boxesCfg.Enabled then
		if boxesCfg["Box Glow"].Enabled then
			if objects.BoxGlow.ImageTransparency ~= 0 then objects.BoxGlow.ImageTransparency = 0 end
			local glowTop = boxesCfg["Box Glow"].Top
			local glowBot = boxesCfg["Box Glow"].Bot
			if data.LastGlowTop ~= glowTop or data.LastGlowBot ~= glowBot then
				objects.BoxGlowGradient.Color = ColorSequence.new(glowTop, glowBot)
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
			if objects.BoxGlow.ImageTransparency ~= 1 then objects.BoxGlow.ImageTransparency = 1 end
		end

		if not objects.BoxOutlineHolder.Visible then objects.BoxOutlineHolder.Visible = true end
		if not objects.BoxInlineHolder.Visible then objects.BoxInlineHolder.Visible = true end

		local gradTop = boxesCfg.Gradients.Top
		local gradBot = boxesCfg.Gradients.Bot
		if data.LastGradTop ~= gradTop or data.LastGradBot ~= gradBot then
			objects.BoxInlineGradient.Color = ColorSequence.new(gradTop, gradBot)
			data.LastGradTop = gradTop
			data.LastGradBot = gradBot
		end

		if boxesCfg.Filled.Enabled then
			if not objects.BoxFill.Visible then objects.BoxFill.Visible = true end
			local fillTop = boxesCfg.Filled.Top
			local fillBot = boxesCfg.Filled.Bot
			local fillT1 = boxesCfg.Filled.Transparency[1]
			local fillT2 = boxesCfg.Filled.Transparency[2]

			if data.LastFillTop ~= fillTop or data.LastFillBot ~= fillBot then
				objects.BoxFillGradient.Color = ColorSequence.new(fillTop, fillBot)
				data.LastFillTop = fillTop
				data.LastFillBot = fillBot
			end

			if data.LastFillT1 ~= fillT1 or data.LastFillT2 ~= fillT2 then
				objects.BoxFillGradient.Transparency = numSeq({ numKey(0, fillT1), numKey(1, fillT2) })
				data.LastFillT1 = fillT1
				data.LastFillT2 = fillT2
			end
		else
			if objects.BoxFill.Visible then objects.BoxFill.Visible = false end
		end
	else
		if objects.BoxGlow.ImageTransparency ~= 1 then objects.BoxGlow.ImageTransparency = 1 end
		if objects.BoxOutlineHolder.Visible then objects.BoxOutlineHolder.Visible = false end
		if objects.BoxInlineHolder.Visible then objects.BoxInlineHolder.Visible = false end
		if objects.BoxFill.Visible then objects.BoxFill.Visible = false end
	end

	if textsCfg.Name.Enabled then
		if not objects.TargetName.Visible then objects.TargetName.Visible = true end
		local playerObj = playersService:GetPlayerFromCharacter(target) or playersService:FindFirstChild(target.Name)
		local displayName = playerObj and (playerObj.DisplayName or playerObj.Name) or target.Name
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
		if objects.TargetName.Visible then objects.TargetName.Visible = false end
	end

	if textsCfg.Distance.Enabled then
		if not objects.Distance.Visible then objects.Distance.Visible = true end
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
		if objects.Distance.Visible then objects.Distance.Visible = false end
	end

	local healthCfg = config.Bars["Health Bar"]
	if healthCfg.Enabled then
		local health = humanoid.Health or data.Health or 0
		local maxHealth = humanoid.MaxHealth or data.MaxHealth or 100
		local ratio = mathClamp(health / maxHealth, 0, 1)

		if not objects.LeftBarHolder.Visible then objects.LeftBarHolder.Visible = true end
		if not objects.HealthBarOutline.Visible then objects.HealthBarOutline.Visible = true end

		if data.LastRatio ~= ratio then
			objects.HealthBar.Size = newUDim2(1, 0, ratio, 0)
			data.LastRatio = ratio
		end

		local barColor = healthCfg.Color
		if data.LastHealthColor ~= barColor then
			objects.HealthBarGradient.Color = ColorSequence.new(barColor)
			data.LastHealthColor = barColor
		end

		if ratio < 1 then
			if not objects.HealthBarText.Visible then objects.HealthBarText.Visible = true end
			local flooredHealth = mathFloor(health)
			if data.LastHealthFloor ~= flooredHealth then
				objects.HealthBarText.Text = stringFormat("%d", flooredHealth)
				objects.HealthBarText.Position = newUDim2(0.5, 0, 1 - ratio, 0)
				data.LastHealthFloor = flooredHealth
			end
		else
			if objects.HealthBarText.Visible then objects.HealthBarText.Visible = false end
		end
	else
		if objects.HealthBarOutline.Visible then objects.HealthBarOutline.Visible = false end
		if objects.LeftBarHolder.Visible then objects.LeftBarHolder.Visible = false end
	end

	if data.CurrentWeapon == "Worldmodel" or data.CurrentWeapon == "none" or not data.CurrentWeapon then
		data.CurrentWeapon = resolveEquippedWeapon(character)
	end

	local currentWeapon = data.CurrentWeapon or "none"
	local iconId = weaponIcons[currentWeapon]
	local iconCfg = textsCfg.WeaponIcon
	local showIcon = iconCfg and iconCfg.Enabled and iconId ~= nil

	local weaponCfg = textsCfg.Weapon
	if weaponCfg.Enabled and not showIcon then
		if not objects.Weapon.Visible then objects.Weapon.Visible = true end
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
		if objects.Weapon.Visible then objects.Weapon.Visible = false end
	end

	if showIcon then
		if not objects.WeaponIcon.Visible then objects.WeaponIcon.Visible = true end
		if data.LastIcon ~= iconId then
			objects.WeaponIcon.Image = iconId
			data.LastIcon = iconId
		end
		local iconSize = iconCfg.Size or 24
		if data.LastIconSize ~= iconSize then
			objects.WeaponIcon.Size = udim2FromOffset(iconSize, iconSize)
			data.LastIconSize = iconSize
		end
	else
		if objects.WeaponIcon.Visible then objects.WeaponIcon.Visible = false end
	end
end

function Arbuzi:Load()
	if self.Loaded then return self end

	updateCameraCache()

	self.Holder = self:CreateObjects("ScreenGui", {
		Name = "\n",
		Parent = getGuiParent(),
		ResetOnSpawn = false,
		DisplayOrder = -1,
		IgnoreGuiInset = true
	})

	local function bindPlayer(player)
		if player == localPlayer then return end

		if player.Character then
			self:AddTarget(player.Character)
		end

		player.CharacterAdded:Connect(function(char)
			self:AddTarget(char)
		end)

		player.CharacterRemoving:Connect(function(char)
			self:RemoveTarget(char)
		end)
	end

	for _, player in ipairs(playersService:GetPlayers()) do
		bindPlayer(player)
	end

	self.Threads["PlayerAdded"] = playersService.PlayerAdded:Connect(bindPlayer)
	self.Threads["PlayerRemoving"] = playersService.PlayerRemoving:Connect(function(player)
		if player.Character then
			self:RemoveTarget(player.Character)
		end
	end)

	self.Threads["LocalPlayerRespawn"] = localPlayer.CharacterAdded:Connect(function()
		task.defer(function()
			updateCameraCache()
			for _, player in ipairs(playersService:GetPlayers()) do
				if player ~= localPlayer then
					local char = player.Character or workspaceService:FindFirstChild(player.Name)
					if char and char:IsA("Model") and not self.Cache[char] then
						self:AddTarget(char)
					end
				end
			end
		end)
	end)

	self.Threads["WatchdogScanner"] = task.spawn(function()
		while self.Loaded do
			task.wait(1.2)

			if not self.Holder or not self.Holder.Parent then
				self.Holder = self:CreateObjects("ScreenGui", {
					Name = "\n",
					Parent = getGuiParent(),
					ResetOnSpawn = false,
					DisplayOrder = -1,
					IgnoreGuiInset = true
				})
				for _, data in pairs(self.Cache) do
					if typeof(data) == "table" and data.Objects and data.Objects.TargetHolder then
						data.Objects.TargetHolder.Parent = self.Holder
					end
				end
			end

			for _, player in ipairs(playersService:GetPlayers()) do
				if player == localPlayer then continue end
				local char = player.Character or workspaceService:FindFirstChild(player.Name)
				if char and char:IsA("Model") and char.Parent then
					if not self.Cache[char] then
						self:AddTarget(char)
					else
						local data = self.Cache[char]
						if typeof(data) == "table" then
							if not data.RootPart or not data.RootPart.Parent or not data.Humanoid or not data.Humanoid.Parent then
								data.RootPart = char:FindFirstChild("HumanoidRootPart")
									or char:FindFirstChild("Torso")
									or char:FindFirstChild("UpperTorso")
									or char.PrimaryPart
									or char:FindFirstChild("Head")
								data.Humanoid = char:FindFirstChildOfClass("Humanoid")
							end
							if data.Humanoid then
								data.Health = data.Humanoid.Health
								data.MaxHealth = data.Humanoid.MaxHealth
								data.Alive = data.Humanoid.Health > 0
							end
						end
					end
				end
			end

			if config.Bots and config.Bots.Enabled then
				for _, model in ipairs(workspaceService:GetChildren()) do
					if model:IsA("Model") and model ~= localPlayer.Character and not self.Cache[model] then
						local hum = model:FindFirstChildOfClass("Humanoid")
						if hum then
							self:AddTarget(model)
						end
					end
				end
			end

			for target in pairs(self.Cache) do
				if typeof(target) ~= "Instance" or not target.Parent or not target:IsDescendantOf(workspaceService) then
					self:RemoveTarget(target)
				end
			end
		end
	end)

	self.PreRender = runService.RenderStepped:Connect(function()
		if not config.Enabled then
			for _, data in pairs(self.Cache) do
				if typeof(data) == "table" and data.Objects.TargetHolder and data.Objects.TargetHolder.Visible then
					data.Objects.TargetHolder.Visible = false
				end
			end
			return
		end

		if config.LimitFPS and config.LimitFPS > 0 then
			local now = tick()
			if now - self.LastRenderTime < (1 / config.LimitFPS) then
				return
			end
			self.LastRenderTime = now
		end

		camera = workspaceService.CurrentCamera
		if not camera then return end

		local vpY = camera.ViewportSize.Y
		if vpY > 0 then
			viewPortY = vpY
			local fov = camera.FieldOfView
			if fov and fov > 0 then
				cachedFocalLength = vpY / (2 * mathTan(mathRad(fov) * 0.5))
			end
		end
		cameraPosition = camera.CFrame.Position

		for target, data in pairs(self.Cache) do
			if typeof(data) == "table" then
				self:Update(target, data)
			end
		end
	end)

	self.Loaded = true
	shared.Arbuzi = self
	return self
end

function Arbuzi:GetConfig()
	return self.Table
end

function Arbuzi:Unload()
	self.Loaded = false

	if self.PreRender then
		self.PreRender:Disconnect()
		self.PreRender = nil
	end

	for target in pairs(self.Cache) do
		self:RemoveTarget(target)
	end

	for _, conn in pairs(self.Threads) do
		if typeof(conn) == "thread" then
			task.cancel(conn)
		elseif conn.Disconnect then
			conn:Disconnect()
		end
	end
	tableClear(self.Threads)

	if self.Holder then
		self.Holder:Destroy()
		self.Holder = nil
	end

	tableClear(self.Cache)
	shared.Arbuzi = nil
end
print("hello nigga")
return Arbuzi
