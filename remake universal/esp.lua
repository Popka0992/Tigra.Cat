if shared.Arbuzi and shared.Arbuzi.Unload then
	pcall(shared.Arbuzi.Unload, shared.Arbuzi)
end

local cloneref = cloneref or function(instance) return instance end
local workspaceService = cloneref(game:GetService("Workspace"))
local playersService = cloneref(game:GetService("Players"))
local runService = cloneref(game:GetService("RunService"))
local httpService = cloneref(game:GetService("HttpService"))
local coreGui = cloneref(game:GetService("CoreGui"))

local LOCAL_PLAYER = playersService.LocalPlayer
local HTTP_REQUEST = request or (syn and syn.request) or (http and http.request) or http_request

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
local osClock = os.clock

local camera = workspaceService.CurrentCamera
local zeroVector3 = newVector3(0, 0, 0)
local cameraPosition = zeroVector3
local cachedFocalLength = 0
local viewPortY = 0
local viewportCache = {}

--------------------------------------------------------------------------------
-- helpers
--------------------------------------------------------------------------------

local function set(obj, prop, value)
	if obj[prop] ~= value then
		obj[prop] = value
	end
end

local function changed(data, key, value)
	if data.Last[key] == value then return false end
	data.Last[key] = value
	return true
end

local function normalizeName(name)
	if typeof(name) ~= "string" then return "" end
	return (name:lower():gsub("[%s_%-]", ""))
end

local function isIgnoredPartName(name)
	local lower = name:lower()
	return lower:find("hitbox")
		or lower:find("collider")
		or lower:find("trigger")
		or lower:find("root")
		or lower:find("bound")
		or lower:find("ray")
		or lower:find("aim")
		or lower:find("muzzle")
		or lower:find("hand")
		or lower:find("arm")
		or lower:find("glove")
		or lower:find("body")
		or lower:find("attach")
		or lower:find("point")
		or lower:find("node")
		or lower:find("origin")
		or lower:find("flash")
		or lower:find("light")
		or lower:find("laser")
		or lower:find("effect")
		or lower:find("emitter")
		or lower:find("pos")
		or lower:find("weld")
end

local function getGuiParent()
	local ok, result = pcall(gethui)
	if ok and result then return result end
	return coreGui
end

local function updateCameraCache()
	camera = workspaceService.CurrentCamera or camera
	if not camera then return end
	local vp = camera.ViewportSize
	if vp.Y > 0 then
		viewPortY = vp.Y
		local fov = camera.FieldOfView
		if fov and fov > 0 then
			cachedFocalLength = vp.Y / (2 * mathTan(mathRad(fov) * 0.5))
		end
	end
end

local function buildWeaponViewport(tool)
	local hasAnyMesh = false
	for _, desc in ipairs(tool:GetDescendants()) do
		if desc:IsA("MeshPart") or (desc:IsA("BasePart") and desc:FindFirstChildOfClass("SpecialMesh")) then
			hasAnyMesh = true
			break
		end
	end

	local visualParts = {}
	for _, desc in ipairs(tool:GetDescendants()) do
		if desc:IsA("BasePart") then
			local isMesh = desc:IsA("MeshPart") or desc:FindFirstChildOfClass("SpecialMesh")
			local include = true
			if hasAnyMesh and not isMesh then include = false end
			if isIgnoredPartName(desc.Name) or desc.Transparency >= 0.7 or desc.Size.Magnitude < 0.05 then
				include = false
			end
			if include then table.insert(visualParts, desc) end
		end
	end
	if #visualParts == 0 then
		for _, desc in ipairs(tool:GetDescendants()) do
			if desc:IsA("BasePart") and desc.Transparency < 0.9 and desc.Size.Magnitude >= 0.05 then
				table.insert(visualParts, desc)
			end
		end
	end
	if #visualParts == 0 then return nil end

	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency = 1
	vp.Size = newUDim2(1, 0, 1, 0)
	vp.Ambient = Color3.fromRGB(180, 180, 180)
	vp.LightColor = Color3.fromRGB(255, 255, 255)
	vp.LightDirection = newVector3(-1, -1.4, -1).Unit

	local model = Instance.new("Model")
	local clonedParts = {}
	for _, p in ipairs(visualParts) do
		local cp = p:Clone()
		cp.CanCollide = false
		cp.Anchored = true
		for _, child in ipairs(cp:GetChildren()) do
			if not child:IsA("SpecialMesh") and not child:IsA("Texture") then
				child:Destroy()
			end
		end
		cp.Parent = model
		table.insert(clonedParts, cp)
	end
	model.Parent = vp

	local centerCf = model:GetBoundingBox()
	for _, cp in ipairs(clonedParts) do
		cp.CFrame = centerCf:Inverse() * cp.CFrame
	end
	local _, size = model:GetBoundingBox()
	local sx, sy, sz = size.X, size.Y, size.Z
	local maxDim = math.max(sx, sy, sz)

	local camDir
	if sz == maxDim then
		camDir = newVector3(1.15, 0.35, 0.45).Unit
	elseif sx == maxDim then
		camDir = newVector3(0.45, 0.35, 1.15).Unit
	else
		camDir = newVector3(1.0, 0.3, 0.8).Unit
	end

	local fov = 30
	local camRot = CFrame.lookAt(camDir, zeroVector3).Rotation
	local tanV = mathTan(mathRad(fov / 2))
	local tanH = tanV * (50 / 26)
	local hx, hy, hz = sx / 2, sy / 2, sz / 2
	local corners = {
		newVector3(hx, hy, hz), newVector3(-hx, hy, hz),
		newVector3(hx, -hy, hz), newVector3(-hx, -hy, hz),
		newVector3(hx, hy, -hz), newVector3(-hx, hy, -hz),
		newVector3(hx, -hy, -hz), newVector3(-hx, -hy, -hz),
	}
	local maxDist = 0.5
	for _, pt in ipairs(corners) do
		local pCam = camRot:PointToObjectSpace(pt)
		local dX = pCam.Z + (mathAbs(pCam.X) / (tanH * 0.90))
		local dY = pCam.Z + (mathAbs(pCam.Y) / (tanV * 0.90))
		if dX > maxDist then maxDist = dX end
		if dY > maxDist then maxDist = dY end
	end

	local cam = Instance.new("Camera")
	cam.FieldOfView = fov
	cam.CFrame = CFrame.lookAt(camDir * maxDist, zeroVector3)
	cam.Parent = vp
	vp.CurrentCamera = cam
	return vp
end

local function getWeaponViewport(weaponName, tool)
	if not tool or weaponName == "none" then return nil end
	local key = normalizeName(weaponName)
	local cached = viewportCache[key]
	if cached == nil then
		cached = buildWeaponViewport(tool) or false
		viewportCache[key] = cached
	end
	if not cached then return nil end
	local clone = cached:Clone()
	local cam = clone:FindFirstChildOfClass("Camera")
	if cam then clone.CurrentCamera = cam end
	return clone
end

local function resolveEquippedWeapon(character)
	local tool = character:FindFirstChildOfClass("Tool")
	if tool then return tool.Name, tool end
	return "none", nil
end

local Arbuzi = {
	Loaded = false,
	Cache = {},
	PlayerConns = {},
	Threads = {},
	Holder = nil,
	PreRender = nil,
	LastRenderTime = 0,
	Table = {
		Enabled = false,
		LimitFPS = 0,
		TeamCheck = true,
		MaxDistance = 1000,
		Boxes = {
			Enabled = true,
			["Bounding Box"] = { Enabled = false, IncludeAccessories = false, BoxX = 0, BoxY = 2 },
			["Box Glow"] = {
				Enabled = true,
				Top = Color3.fromRGB(255, 255, 255),
				Bot = Color3.fromRGB(255, 255, 255),
				Transparency = { 0.85, 0.85 },
			},
			Gradients = {
				Top = Color3.fromRGB(255, 255, 255),
				Bot = Color3.fromRGB(255, 255, 255),
			},
			Filled = {
				Enabled = false,
				Top = Color3.fromRGB(255, 255, 255),
				Bot = Color3.fromRGB(255, 255, 255),
				Transparency = { 0.85, 0.85 },
			},
		},
		Bars = {
			["Health Bar"] = { Enabled = true, Color = Color3.fromRGB(255, 255, 255) },
		},
		Texts = {
			Name = { Enabled = true, Color = Color3.fromRGB(255, 255, 255) },
			Distance = { Enabled = true, Color = Color3.fromRGB(200, 200, 200) },
			Weapon = { Enabled = true, Color = Color3.fromRGB(255, 255, 255) },
			WeaponIcon = { Enabled = false, Size = 26 },
			State = { Enabled = false, Color = Color3.fromRGB(255, 255, 255) },
		},
	},
}
local config = Arbuzi.Table

do
	local ok, font = pcall(function()
		local id = "smallest_pixel-7.ttf"
		if isfile(id) and #readfile(id) < 1000 then delfile(id) end
		if not isfile(id) then
			local res = HTTP_REQUEST({
				Url = "https://raw.githubusercontent.com/i77lhm/storage/main/fonts/smallest_pixel-7.ttf",
				Method = "GET",
			})
			writefile(id, res.Body)
		end
		if not isfile("SmallestPixel.font") then
			writefile("SmallestPixel.font", httpService:JSONEncode({
				name = "SmallestPixel",
				faces = {{ name = "Normal", weight = 400, style = "Normal", assetId = getcustomasset(id) }},
			}))
		end
		return Font.new(getcustomasset("SmallestPixel.font"), Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	end)
	Arbuzi.Font = ok and font or Font.fromEnum(Enum.Font.Code)
end

local function create(class, props)
	local instance = Instance.new(class)
	for prop, value in pairs(props or {}) do
		instance[prop] = value
	end
	return instance
end

local function createLabel(parent, order, text)
	local label = create("TextLabel", {
		Parent = parent,
		FontFace = Arbuzi.Font,
		TextSize = 9,
		LayoutOrder = order,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Text = text or "",
		BorderSizePixel = 0,
		Visible = false,
		BackgroundTransparency = 1,
		ZIndex = 5,
		AutomaticSize = Enum.AutomaticSize.XY,
	})
	create("UIStroke", { Parent = label, Color = Color3.fromRGB(0, 0, 0), LineJoinMode = Enum.LineJoinMode.Miter })
	return label
end

function Arbuzi:CreateHolder()
	self.Holder = create("ScreenGui", {
		Name = "\n",
		Parent = getGuiParent(),
		ResetOnSpawn = false,
		DisplayOrder = 10,
		IgnoreGuiInset = true,
	})
end

function Arbuzi:InitEsp(data)
	local o = data.Objects

	o.TargetHolder = create("Frame", {
		Parent = self.Holder, Visible = false, BackgroundTransparency = 1, BorderSizePixel = 0,
		Size = newUDim2(0, 0, 0, 0),
	})

	o.TopHolder = create("Frame", {
		Parent = o.TargetHolder, AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		AnchorPoint = newVector2(0, 1), Position = newUDim2(0, -2, 0, -5),
		Size = newUDim2(1, 4, 0, 0), BorderSizePixel = 0,
	})
	create("UIListLayout", {
		Parent = o.TopHolder, VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = newUDim(0, 1),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
  
	o.BottomHolder = create("Frame", {
		Parent = o.TargetHolder, AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		Position = newUDim2(0, -2, 1, 3), Size = newUDim2(1, 4, 0, 0), BorderSizePixel = 0,
	})
	create("UIListLayout", {
		Parent = o.BottomHolder, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = newUDim(0, 1), SortOrder = Enum.SortOrder.LayoutOrder,
	})

	o.RightHolder = create("Frame", {
		Parent = o.TargetHolder, AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1,
		Position = newUDim2(1, 5, 0, -2), Size = newUDim2(0, 0, 1, 4), BorderSizePixel = 0,
	})
	create("UIListLayout", {
		Parent = o.RightHolder, HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Padding = newUDim(0, 0), SortOrder = Enum.SortOrder.LayoutOrder,
	})

	o.BoxGlow = create("ImageLabel", {
		Parent = o.TargetHolder, Image = "rbxassetid://110204605000367",
		ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(newVector2(21, 21), newVector2(79, 79)),
		AutomaticSize = Enum.AutomaticSize.XY, ImageTransparency = 0.65,
		ResampleMode = Enum.ResamplerMode.Pixelated, BackgroundTransparency = 1,
		Position = newUDim2(0, -21, 0, -21), Size = newUDim2(0, 0, 0, 0), BorderSizePixel = 0,
	})
	o.BoxGlowGradient = create("UIGradient", {
		Parent = o.BoxGlow, Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(0, 0, 0)),
		Transparency = numSeq({ numKey(0, 0), numKey(1, 0) }),
	})
	create("UIPadding", {
		Parent = o.BoxGlow, PaddingTop = newUDim(0, 21), PaddingBottom = newUDim(0, 20),
		PaddingLeft = newUDim(0, 21), PaddingRight = newUDim(0, 20),
	})
	o.BoxOutlineHolder = create("Frame", {
		Parent = o.BoxGlow, Visible = false, BackgroundTransparency = 1,
		Size = newUDim2(0, 0, 0, 0), BorderSizePixel = 0,
	})
	create("UIStroke", { Parent = o.BoxOutlineHolder, Thickness = 3, LineJoinMode = Enum.LineJoinMode.Miter })
	o.BoxInlineHolder = create("Frame", {
		Parent = o.BoxGlow, Visible = false, BackgroundTransparency = 1,
		Position = newUDim2(0, -1, 0, -1), Size = newUDim2(0, 0, 0, 0), BorderSizePixel = 0,
	})
	local inline = create("UIStroke", {
		Parent = o.BoxInlineHolder, Color = Color3.fromRGB(255, 255, 255), LineJoinMode = Enum.LineJoinMode.Miter,
	})
	o.BoxInlineGradient = create("UIGradient", {
		Parent = inline, Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
	})
	o.BoxFill = create("Frame", {
		Parent = o.BoxGlow, Visible = false, BackgroundTransparency = 0,
		Size = newUDim2(0, 0, 0, 0), BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})
	o.BoxFillGradient = create("UIGradient", {
		Parent = o.BoxFill, Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
		Transparency = numSeq({ numKey(0, 1), numKey(1, 1) }),
	})

	o.HealthBarOutline = create("Frame", {
		Parent = o.TargetHolder, ZIndex = 5, Visible = false,
		AnchorPoint = newVector2(1, 0), Position = newUDim2(0, -5, 0, 0),
		Size = newUDim2(0, 2, 1, 0), BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	})
	create("UIStroke", { Parent = o.HealthBarOutline, Thickness = 1, LineJoinMode = Enum.LineJoinMode.Miter })
	o.HealthBar = create("Frame", {
		Parent = o.HealthBarOutline, ZIndex = 6, AnchorPoint = newVector2(0, 1),
		Position = newUDim2(0, 0, 1, 0), Size = newUDim2(1, 0, 1, 0), BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	})
	o.HealthBarGradient = create("UIGradient", {
		Parent = o.HealthBar, Rotation = 90, Color = ColorSequence.new(config.Bars["Health Bar"].Color),
	})
	o.HealthBarText = create("TextLabel", {
		Parent = o.HealthBarOutline, FontFace = Arbuzi.Font, TextSize = 9, ZIndex = 10,
		TextColor3 = Color3.fromRGB(255, 255, 255), Text = "",
		AnchorPoint = newVector2(0.5, 0.5), Position = newUDim2(0.5, 0, 1, 0),
		BorderSizePixel = 0, Visible = false, BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
	})
	create("UIStroke", { Parent = o.HealthBarText, Color = Color3.fromRGB(0, 0, 0), LineJoinMode = Enum.LineJoinMode.Miter })

	o.TargetName = createLabel(o.TopHolder, 2)
	o.Distance = createLabel(o.BottomHolder, 2)
	o.Weapon = createLabel(o.BottomHolder, 3, "none")
	o.StateFlag = createLabel(o.RightHolder, 1, "Standing")
	o.WeaponIcon = create("Frame", {
		Parent = o.BottomHolder, LayoutOrder = 4, BackgroundTransparency = 1, BorderSizePixel = 0,
		Visible = false, Size = udim2FromOffset(50, 26), ZIndex = 5,
	})
end

function Arbuzi:CalculateBox(data)
	if not camera then return nil, nil, nil, nil, false end
	local rootPart = data.RootPart
	if not rootPart or not rootPart.Parent then return nil, nil, nil, nil, false end

	local rootScreen, onScreen = camera:WorldToViewportPoint(rootPart.Position)
	if not onScreen or rootScreen.Z <= 0 then return nil, nil, nil, nil, false end

	local bb = config.Boxes["Bounding Box"]
	if bb.Enabled then
		local minX, minY = math.huge, math.huge
		local maxX, maxY = -math.huge, -math.huge
		local valid = false
		for _, part in ipairs(data.Character:GetChildren()) do
			if part:IsA("BasePart") and part.Transparency ~= 1 and part ~= rootPart then
				local sp, on = camera:WorldToViewportPoint(part.Position)
				if on and sp.Z > 0 then
					valid = true
					local cf, sz = part.CFrame, part.Size
					local hx, hy, hz = sz.X * 0.5, sz.Y * 0.5, sz.Z * 0.5
					local rx, uy, lz = cf.RightVector, cf.UpVector, cf.LookVector
					local depthScale = (cachedFocalLength > 0 and cachedFocalLength or (viewPortY * 0.7)) / sp.Z
					local ex = (mathAbs(rx.X * hx) + mathAbs(uy.X * hy) + mathAbs(lz.X * hz)) * depthScale
					local ey = (mathAbs(rx.Y * hx) + mathAbs(uy.Y * hy) + mathAbs(lz.Y * hz)) * depthScale
					if sp.X - ex < minX then minX = sp.X - ex end
					if sp.X + ex > maxX then maxX = sp.X + ex end
					if sp.Y - ey < minY then minY = sp.Y - ey end
					if sp.Y + ey > maxY then maxY = sp.Y + ey end
				end
			end
		end
		if valid then
			local w = (maxX - minX) + bb.BoxX
			local h = (maxY - minY) + bb.BoxY
			return w, h, minX - bb.BoxX * 0.5, minY - bb.BoxY * 0.5, true
		end
	end

	local scale = (rootPart.Size.Y * viewPortY) / (rootScreen.Z * 2)
	local w, h = 3 * scale, 4.5 * scale
	return w, h, rootScreen.X - w * 0.5, rootScreen.Y - h * 0.5, true
end

function Arbuzi:AddTarget(character)
	if not character or not character:IsA("Model") then return end
	if character == LOCAL_PLAYER.Character or self.Cache[character] then return end

	local data = {
		Character = character,
		Player = playersService:GetPlayerFromCharacter(character),
		Objects = {},
		Conns = {},
		Last = {},
		RootPart = nil,
		Humanoid = nil,
		CurrentWeapon = "none",
		ToolInstance = nil,
		WeaponDirty = true,
		IconWeapon = nil,
	}
	self:InitEsp(data)
	self.Cache[character] = data

	data.Conns.ChildAdded = character.ChildAdded:Connect(function() data.WeaponDirty = true end)
	data.Conns.ChildRemoved = character.ChildRemoved:Connect(function() data.WeaponDirty = true end)
	data.Conns.Ancestry = character.AncestryChanged:Connect(function(_, parent)
		if not parent then self:RemoveTarget(character) end
	end)
end

function Arbuzi:RemoveTarget(character)
	local data = self.Cache[character]
	if not data then return end
	for _, conn in pairs(data.Conns) do conn:Disconnect() end
	tableClear(data.Conns)
	if data.Objects.TargetHolder then data.Objects.TargetHolder:Destroy() end
	tableClear(data.Objects)
	self.Cache[character] = nil
end

function Arbuzi:HideTarget(data)
	local holder = data.Objects.TargetHolder
	if holder and holder.Visible then holder.Visible = false end
end

function Arbuzi:Update(character, data)
	local o = data.Objects
	local boxes, texts = config.Boxes, config.Texts

	if not character.Parent then return self:HideTarget(data) end

	if config.TeamCheck and data.Player and LOCAL_PLAYER.Team and data.Player.Team == LOCAL_PLAYER.Team then
		return self:HideTarget(data)
	end

	local root = data.RootPart
	if not root or not root.Parent then
		root = character:FindFirstChild("HumanoidRootPart")
			or character.PrimaryPart
			or character:FindFirstChild("Torso")
			or character:FindFirstChild("UpperTorso")
			or character:FindFirstChild("Head")
		data.RootPart = root
	end
	local humanoid = data.Humanoid
	if not humanoid or not humanoid.Parent then
		humanoid = character:FindFirstChildOfClass("Humanoid")
		data.Humanoid = humanoid
	end
	if not root or not humanoid or humanoid.Health <= 0 then return self:HideTarget(data) end

	local dist = (cameraPosition - root.Position).Magnitude
	if dist > config.MaxDistance then return self:HideTarget(data) end

	local w, h, x, y, onScreen = self:CalculateBox(data)
	if not onScreen or not w then return self:HideTarget(data) end
	w, h, x, y = mathFloor(w), mathFloor(h), mathFloor(x), mathFloor(y)

	set(o.TargetHolder, "Visible", true)
	if changed(data, "Pos", x * 100000 + y) then
		o.TargetHolder.Position = udim2FromOffset(x, y)
	end
	if changed(data, "Size", w * 100000 + h) then
		o.TargetHolder.Size = udim2FromOffset(w, h)
		o.BoxGlow.Size = udim2FromOffset(w, h)
		o.BoxOutlineHolder.Size = udim2FromOffset(w, h)
		o.BoxInlineHolder.Size = udim2FromOffset(w + 2, h + 2)
		o.BoxFill.Size = udim2FromOffset(w, h)
	end

	if boxes.Enabled then
		local glow = boxes["Box Glow"]
		set(o.BoxGlow, "ImageTransparency", glow.Enabled and 0 or 1)
		if glow.Enabled then
			local a, b = changed(data, "GlowTop", glow.Top), changed(data, "GlowBot", glow.Bot)
			if a or b then o.BoxGlowGradient.Color = ColorSequence.new(glow.Top, glow.Bot) end
			local t1, t2 = glow.Transparency[1], glow.Transparency[2]
			local c, d = changed(data, "GlowT1", t1), changed(data, "GlowT2", t2)
			if c or d then o.BoxGlowGradient.Transparency = numSeq({ numKey(0, t1), numKey(1, t2) }) end
		end
		set(o.BoxOutlineHolder, "Visible", true)
		set(o.BoxInlineHolder, "Visible", true)
		local a, b = changed(data, "GradTop", boxes.Gradients.Top), changed(data, "GradBot", boxes.Gradients.Bot)
		if a or b then o.BoxInlineGradient.Color = ColorSequence.new(boxes.Gradients.Top, boxes.Gradients.Bot) end

		local fill = boxes.Filled
		set(o.BoxFill, "Visible", fill.Enabled)
		if fill.Enabled then
			local c, d = changed(data, "FillTop", fill.Top), changed(data, "FillBot", fill.Bot)
			if c or d then o.BoxFillGradient.Color = ColorSequence.new(fill.Top, fill.Bot) end
			local t1, t2 = fill.Transparency[1], fill.Transparency[2]
			local e, f = changed(data, "FillT1", t1), changed(data, "FillT2", t2)
			if e or f then o.BoxFillGradient.Transparency = numSeq({ numKey(0, t1), numKey(1, t2) }) end
		end
	else
		set(o.BoxGlow, "ImageTransparency", 1)
		set(o.BoxOutlineHolder, "Visible", false)
		set(o.BoxInlineHolder, "Visible", false)
		set(o.BoxFill, "Visible", false)
	end

	set(o.TargetName, "Visible", texts.Name.Enabled)
	if texts.Name.Enabled then
		local name = data.Player and (data.Player.DisplayName or data.Player.Name) or character.Name
		if changed(data, "Name", name) then o.TargetName.Text = name end
		if changed(data, "NameColor", texts.Name.Color) then o.TargetName.TextColor3 = texts.Name.Color end
	end

	set(o.Distance, "Visible", texts.Distance.Enabled)
	if texts.Distance.Enabled then
		local d = mathFloor(dist)
		if changed(data, "Dist", d) then o.Distance.Text = stringFormat("%d st", d) end
		if changed(data, "DistColor", texts.Distance.Color) then o.Distance.TextColor3 = texts.Distance.Color end
	end

	local hb = config.Bars["Health Bar"]
	set(o.HealthBarOutline, "Visible", hb.Enabled)
	if hb.Enabled then
		local health = humanoid.Health
		local ratio = mathClamp(health / math.max(humanoid.MaxHealth, 1), 0, 1)
		if changed(data, "Ratio", ratio) then o.HealthBar.Size = newUDim2(1, 0, ratio, 0) end
		if changed(data, "HealthColor", hb.Color) then o.HealthBarGradient.Color = ColorSequence.new(hb.Color) end
		if ratio < 1 then
			set(o.HealthBarText, "Visible", true)
			local hp = mathFloor(health)
			if changed(data, "HP", hp) then
				o.HealthBarText.Text = stringFormat("%d", hp)
				o.HealthBarText.Position = newUDim2(0.5, 0, 1 - ratio, 0)
			end
		else
			set(o.HealthBarText, "Visible", false)
		end
	end

	set(o.StateFlag, "Visible", texts.State.Enabled)
	if texts.State.Enabled then
		local st = humanoid:GetState()
		local text = "Standing"
		if st == Enum.HumanoidStateType.Jumping or st == Enum.HumanoidStateType.Freefall then
			text = "Jumping"
		elseif humanoid.MoveDirection.Magnitude > 0 then
			text = "Walking"
		end
		if changed(data, "State", text) then o.StateFlag.Text = text end
		if changed(data, "StateColor", texts.State.Color) then o.StateFlag.TextColor3 = texts.State.Color end
	end

	if data.WeaponDirty then
		data.CurrentWeapon, data.ToolInstance = resolveEquippedWeapon(character)
		data.WeaponDirty = false
	end
	local weapon, tool = data.CurrentWeapon, data.ToolInstance
	local hasWeapon = weapon ~= "none"
	local iconCfg = texts.WeaponIcon
	local showIcon = iconCfg.Enabled and hasWeapon

	local showText = texts.Weapon.Enabled and hasWeapon and not showIcon
	set(o.Weapon, "Visible", showText)
	if showText then
		if changed(data, "Weapon", weapon) then o.Weapon.Text = weapon end
		if changed(data, "WeaponColor", texts.Weapon.Color) then o.Weapon.TextColor3 = texts.Weapon.Color end
	end

	if showIcon then
		local iconSize = iconCfg.Size or 26
		if changed(data, "IconSize", iconSize) then
			o.WeaponIcon.Size = udim2FromOffset(mathFloor(iconSize * 1.9), iconSize)
		end
		if data.IconWeapon ~= weapon then
			data.IconWeapon = weapon
			o.WeaponIcon:ClearAllChildren()
			local vp = getWeaponViewport(weapon, tool)
			if vp then
				vp.Size = newUDim2(1, 0, 1, 0)
				vp.Position = newUDim2(0, 0, 0, 0)
				vp.BackgroundTransparency = 1
				vp.BorderSizePixel = 0
				vp.ZIndex = 10
				vp.Visible = true
				vp.Parent = o.WeaponIcon
			end
		end
		set(o.WeaponIcon, "Visible", #o.WeaponIcon:GetChildren() > 0)
	elseif o.WeaponIcon.Visible or data.IconWeapon then
		o.WeaponIcon.Visible = false
		o.WeaponIcon:ClearAllChildren()
		data.IconWeapon = nil
	end
end

function Arbuzi:Load()
	if self.Loaded then return self end
	self.Loaded = true
	updateCameraCache()
	self:CreateHolder()

	local function bindPlayer(player)
		if player == LOCAL_PLAYER or self.PlayerConns[player] then return end
		if player.Character then self:AddTarget(player.Character) end
		self.PlayerConns[player] = {
			player.CharacterAdded:Connect(function(char) self:AddTarget(char) end),
			player.CharacterRemoving:Connect(function(char) self:RemoveTarget(char) end),
		}
	end
	for _, player in ipairs(playersService:GetPlayers()) do bindPlayer(player) end

	self.Threads.PlayerAdded = playersService.PlayerAdded:Connect(bindPlayer)
	self.Threads.PlayerRemoving = playersService.PlayerRemoving:Connect(function(player)
		if player.Character then self:RemoveTarget(player.Character) end
		local conns = self.PlayerConns[player]
		if conns then
			for _, c in ipairs(conns) do c:Disconnect() end
			self.PlayerConns[player] = nil
		end
	end)

	self.Threads.Watchdog = task.spawn(function() 
		while self.Loaded do
			task.wait(2.5)
			if not self.Holder or not self.Holder.Parent then
				self:CreateHolder()
				for _, data in pairs(self.Cache) do
					if data.Objects.TargetHolder then data.Objects.TargetHolder.Parent = self.Holder end
				end
			end
			for _, player in ipairs(playersService:GetPlayers()) do
				if player ~= LOCAL_PLAYER then
					local char = player.Character
					if char and char.Parent and not self.Cache[char] then self:AddTarget(char) end
				end
			end
			for char in pairs(self.Cache) do
				if not char.Parent or not char:IsDescendantOf(workspaceService) then
					self:RemoveTarget(char)
				end
			end
		end
	end)

	self.PreRender = runService.RenderStepped:Connect(function()
		if not config.Enabled then
			for _, data in pairs(self.Cache) do self:HideTarget(data) end
			return
		end
		if config.LimitFPS and config.LimitFPS > 0 then
			local now = osClock()
			if now - self.LastRenderTime < (1 / config.LimitFPS) then return end
			self.LastRenderTime = now
		end
		camera = workspaceService.CurrentCamera
		if not camera then return end
		updateCameraCache()
		cameraPosition = camera.CFrame.Position
		for char, data in pairs(self.Cache) do
			self:Update(char, data)
		end
	end)

	shared.Arbuzi = self
	return self
end

function Arbuzi:Unload()
	self.Loaded = false
	if self.PreRender then
		self.PreRender:Disconnect()
		self.PreRender = nil
	end
	for char in pairs(self.Cache) do self:RemoveTarget(char) end
	for _, conns in pairs(self.PlayerConns) do
		for _, c in ipairs(conns) do c:Disconnect() end
	end
	tableClear(self.PlayerConns)
	for _, conn in pairs(self.Threads) do
		if typeof(conn) == "thread" then
			pcall(task.cancel, conn)
		elseif conn.Disconnect then
			conn:Disconnect()
		end
	end
	tableClear(self.Threads)
	if self.Holder then
		self.Holder:Destroy()
		self.Holder = nil
	end
	for _, vp in pairs(viewportCache) do
		if vp then vp:Destroy() end
	end
	tableClear(viewportCache)
	if shared.Arbuzi == self then shared.Arbuzi = nil end
end

return Arbuzi
