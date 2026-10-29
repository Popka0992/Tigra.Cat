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

local httpRequest = request or (syn and syn.request) or (http and http.request) or http_request
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
local weaponViewportCache = {}
local toolViewportCache = {}
local meshToWeapon = {}

local function normalizeName(name)
	if not name or typeof(name) ~= "string" then return "" end
	return name:lower():gsub("[%s_%-]", "")
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
			local shouldInclude = true

			if hasAnyMesh and not isMesh then
				shouldInclude = false
			end

			if isIgnoredPartName(desc.Name) or desc.Transparency >= 0.7 or desc.Size.Magnitude < 0.05 then
				shouldInclude = false
			end

			if shouldInclude then
				table.insert(visualParts, desc)
			end
		end
	end

	if #visualParts == 0 then
		for _, desc in ipairs(tool:GetDescendants()) do
			if desc:IsA("BasePart") and desc.Transparency < 0.9 and desc.Size.Magnitude >= 0.05 then
				table.insert(visualParts, desc)
			end
		end
	end

	if #visualParts == 0 and tool:IsA("BasePart") then
		table.insert(visualParts, tool)
	end

	if #visualParts == 0 then return nil end

	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency = 1
	vp.Size = newUDim2(1, 0, 1, 0)
	vp.Position = newUDim2(0, 0, 0, 0)
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

	local centerCf, size = model:GetBoundingBox()
	for _, cp in ipairs(clonedParts) do
		cp.CFrame = centerCf:Inverse() * cp.CFrame
	end
	centerCf, size = model:GetBoundingBox()

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
	local aspect = 50 / 26
	local tanV = mathTan(mathRad(fov / 2))
	local tanH = tanV * aspect

	local hx, hy, hz = sx / 2, sy / 2, sz / 2
	local corners = {
		newVector3(hx, hy, hz),
		newVector3(-hx, hy, hz),
		newVector3(hx, -hy, hz),
		newVector3(-hx, -hy, hz),
		newVector3(hx, hy, -hz),
		newVector3(-hx, hy, -hz),
		newVector3(hx, -hy, -hz),
		newVector3(-hx, -hy, -hz)
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

local function getWeaponViewport(weaponName, toolInst)
	if not weaponName or weaponName == "none" or weaponName == "Worldmodel" then
		return nil
	end
	local raw = weaponName:lower()
	local clean = normalizeName(raw)

	if not toolViewportCache[clean] and toolInst then
		local built = buildWeaponViewport(toolInst)
		if built then
			toolViewportCache[clean] = built
			toolViewportCache[raw] = built
		end
	end

	local cached = toolViewportCache[clean] or toolViewportCache[raw] or weaponViewportCache[clean] or weaponViewportCache[raw]
	if cached then
		local cloned = cached:Clone()
		local cam = cloned:FindFirstChildOfClass("Camera")
		if not cam and cached.CurrentCamera then
			pcall(function()
				cam = cached.CurrentCamera:Clone()
				cam.Parent = cloned
			end)
		end
		if cam then
			cloned.CurrentCamera = cam
		end
		return cloned
	end

	return nil
end

local function resolveEquippedWeapon(character)
	if not character or not character.Parent then return "none", nil end

	local tool = character:FindFirstChildOfClass("Tool")
	if tool then
		return tool.Name, tool
	end

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Model") and child.Name ~= "FustAvatarFace" and not child:IsA("Accessory") then
			if child:FindFirstChild("Handle") or child:FindFirstChildOfClass("MeshPart") or child:FindFirstChildOfClass("BasePart") then
				return child.Name, child
			end
		end
	end

	local worldModel = character:FindFirstChild("Worldmodel")
		or character:FindFirstChild("WorldModel")
		or character:FindFirstChild("worldmodel")

	if not worldModel then
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") then
				return child.Name, child
			elseif child:IsA("Model") and child.Name:lower():find("worldmodel") then
				worldModel = child
				break
			end
		end
	end

	if not worldModel then
		return "none", nil
	end

	local attr = worldModel:GetAttribute("Weapon")
		or worldModel:GetAttribute("Name")
		or worldModel:GetAttribute("Item")
		or character:GetAttribute("EquippedWeapon")
		or character:GetAttribute("Weapon")
		or character:GetAttribute("Equipped")
	if attr and typeof(attr) == "string" and attr ~= "" then
		return attr, worldModel
	end

	local children = worldModel:GetChildren()
	for _, part in ipairs(children) do
		if part:IsA("MeshPart") and part.MeshId ~= "" then
			local matched = weaponMeshMap[part.MeshId] or meshToWeapon[part.MeshId]
			if matched then
				return matched, worldModel
			end
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
		return bestTool, worldModel
	end

	if #children > 0 then
		return "Worldmodel", worldModel
	end

	return "none", nil
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

local function matchOreType(modelName)
	if not modelName or typeof(modelName) ~= "string" then return nil end
	local lower = modelName:lower()
	if lower:find("stone") then
		return "Stone"
	elseif lower:find("sulfur") then
		return "Sulfur"
	elseif lower:find("metal") or lower:find("iron") then
		return "Metal"
	end
	return nil
end

local function resolveEntityPart(model)
	if model:IsA("BasePart") then
		return model
	end
	return model:FindFirstChild("Rock")
		or model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChild("Torso")
		or model.PrimaryPart
		or model:FindFirstChildOfClass("MeshPart")
		or model:FindFirstChildOfClass("BasePart")
end

local function isItemAllowed(filter, itemName)
	if not filter then return true end
	if filter[itemName] ~= nil then
		return filter[itemName] == true
	end
	for k, v in pairs(filter) do
		if v == itemName or k == itemName then
			return true
		end
	end
	return false
end

local Arbuzi = {
	Loaded = false,
	Directory = "Esp",
	Cache = {},
	OreCache = {},
	PickupCache = {},
	AnimalCache = {},
	Holder = nil,
	WorldHolder = nil,
	Threads = {},
	PreRender = nil,
	LastRenderTime = 0,
	Table = {
		Enabled = true,
		LimitFPS = 0,
		Players = true,
		Bots = {
			Enabled = true,
			CustomColors = true,
			Name = "Bot",
			Boxes = {
				Gradients = {
					Top = Color3.fromRGB(255, 60, 60),
					Bot = Color3.fromRGB(255, 60, 60)
				},
				["Box Glow"] = {
					Top = Color3.fromRGB(255, 60, 60),
					Bot = Color3.fromRGB(255, 60, 60)
				},
				Filled = {
					Top = Color3.fromRGB(255, 60, 60),
					Bot = Color3.fromRGB(255, 60, 60)
				}
			},
			Bars = {
				["Health Bar"] = {
					Color = Color3.fromRGB(255, 60, 60)
				}
			},
			Texts = {
				Name = {
					Color = Color3.fromRGB(255, 60, 60)
				},
				Distance = {
					Color = Color3.fromRGB(255, 140, 140)
				},
				Weapon = {
					Color = Color3.fromRGB(255, 60, 60)
				},
				State = {
					Color = Color3.fromRGB(255, 60, 60)
				}
			}
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
				Size = 26
			},
			State = {
				Enabled = true,
				Color = Color3.fromRGB(255, 255, 255)
			}
		},
		Ores = {
			Enabled = true,
			MaxDistance = 2500,
			ShowDistance = true,
			Stone = {
				Enabled = true,
				Color = Color3.fromRGB(190, 190, 190),
				DisplayName = "Stone"
			},
			Sulfur = {
				Enabled = true,
				Color = Color3.fromRGB(245, 220, 60),
				DisplayName = "Sulfur"
			},
			Metal = {
				Enabled = true,
				Color = Color3.fromRGB(205, 125, 75),
				DisplayName = "Metal"
			}
		},
		Pickups = {
			Enabled = true,
			MaxDistance = 1500,
			ShowDistance = true,
			Color = Color3.fromRGB(140, 240, 140),
			Filter = {
				["WoodPile"] = true,
				["SulfurOrePile"] = true,
				["StoneOrePile"] = true,
				["MetalOrePile"] = true,
				["Pumpkin"] = true,
				["PotatoPlant"] = true,
				["Mushroom"] = true,
				["Hemp"] = true,
				["Corn"] = true,
				["CarrotPlant"] = true,
				["BerryBush"] = true,
				["ApplyPile"] = true
			}
		},
		Animals = {
			Enabled = true,
			MaxDistance = 2500,
			ShowDistance = true,
			Color = Color3.fromRGB(240, 180, 100)
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

	Fonts.SmallestPixel = registerFont("SmallestPixel", 400, "Normal", {
		Id = "smallest_pixel-7.ttf",
		Font = fetchSource("https://raw.githubusercontent.com/i77lhm/storage/main/fonts/smallest_pixel-7.ttf")
	})

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
		Padding = newUDim(0, 1),
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
		FontFace = Arbuzi.SmallestPixel,
		TextSize = 9,
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

	objects.WeaponIcon = self:CreateObjects("Frame", {
		Parent = objects.BottomTextHolder,
		LayoutOrder = 4,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		Size = udim2FromOffset(50, 26),
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
	if self.Cache[target] then return end

	self.Cache[target] = "pending"

	task.spawn(function()
		if not target.Parent or self.Cache[target] ~= "pending" then
			self.Cache[target] = nil
			return
		end

		local data = {
			Target = target,
			Objects = {},
			Conns = {},
			Character = target,
			RootPart = nil, 
			Humanoid = nil, 
			Health = 100,
			MaxHealth = 100,
			Alive = true,
			CurrentWeapon = "none",
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
			LastIconWeapon = nil,
			LastIconW = nil,
			LastIconH = nil
		}

		self:InitEsp(data)
		self.Cache[target] = data

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

function Arbuzi:AddWorldText(containerTable, instance, displayName)
	if not instance or containerTable[instance] then return end

	local part = resolveEntityPart(instance)
	if not part then
		local conn
		conn = instance.ChildAdded:Connect(function(child)
			if child:IsA("BasePart") then
				conn:Disconnect()
				self:AddWorldText(containerTable, instance, displayName)
			end
		end)
		return
	end

	local textLabel = self:CreateObjects("TextLabel", {
		Parent = self.WorldHolder,
		FontFace = Arbuzi.SmallestPixel,
		TextSize = 9,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = newVector2(0.5, 0.5),
		Position = newUDim2(0, 0, 0, 0),
		BorderSizePixel = 0,
		Visible = false,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		ZIndex = 4
	})

	self:CreateObjects("UIStroke", {
		Parent = textLabel,
		Color = Color3.fromRGB(0, 0, 0),
		LineJoinMode = Enum.LineJoinMode.Miter
	})

	local data = {
		Instance = instance,
		Part = part,
		Position = part.Position,
		Name = displayName or instance.Name,
		Label = textLabel,
		LastDist = -1,
		LastX = -1,
		LastY = -1,
		Ancestry = nil
	}

	data.Ancestry = instance.AncestryChanged:Connect(function(_, parent)
		if not parent then
			self:RemoveWorldText(containerTable, instance)
		end
	end)

	containerTable[instance] = data
end

function Arbuzi:RemoveWorldText(containerTable, instance)
	local data = containerTable[instance]
	if not data then return end

	if data.Ancestry then
		data.Ancestry:Disconnect()
		data.Ancestry = nil
	end

	if data.Label then
		data.Label:Destroy()
		data.Label = nil
	end

	containerTable[instance] = nil
end

function Arbuzi:AddOre(node)
	local oreType = matchOreType(node.Name)
	if not oreType then return end
	self:AddWorldText(self.OreCache, node, oreType)
	if self.OreCache[node] then
		self.OreCache[node].OreType = oreType
	end
end

function Arbuzi:RemoveOre(node)
	self:RemoveWorldText(self.OreCache, node)
end

function Arbuzi:AddPickup(pickup)
	self:AddWorldText(self.PickupCache, pickup, pickup.Name)
end

function Arbuzi:RemovePickup(pickup)
	self:RemoveWorldText(self.PickupCache, pickup)
end

function Arbuzi:AddAnimal(animal)
	self:AddWorldText(self.AnimalCache, animal, animal.Name)
end

function Arbuzi:RemoveAnimal(animal)
	self:RemoveWorldText(self.AnimalCache, animal)
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

	local isPlayer = playersService:GetPlayerFromCharacter(target) ~= nil
	local isBot = not isPlayer
	local useBotColors = isBot and config.Bots and config.Bots.CustomColors and config.Bots.Colors
	local botColorConfig = useBotColors and config.Bots.Colors

	if not humanoid or not humanoid.Parent then
		humanoid = character:FindFirstChildOfClass("Humanoid")
		data.Humanoid = humanoid
		
		if humanoid and not data.Conns.Health then
			data.Conns.Health = humanoid.HealthChanged:Connect(function(newHealth)
				data.Alive = newHealth > 0
				data.Health = newHealth
			end)

			data.Conns.Died = humanoid.Died:Connect(function()
				data.Alive = false
			end)

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
		end
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
		local glowTop = (botColorConfig and botColorConfig.Boxes["Box Glow"].Top) or boxesCfg["Box Glow"].Top
		local glowBot = (botColorConfig and botColorConfig.Boxes["Box Glow"].Bot) or boxesCfg["Box Glow"].Bot

		if boxesCfg["Box Glow"].Enabled then
			if objects.BoxGlow.ImageTransparency ~= 0 then objects.BoxGlow.ImageTransparency = 0 end
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

		local gradTop = (botColorConfig and botColorConfig.Boxes.Gradients.Top) or boxesCfg.Gradients.Top
		local gradBot = (botColorConfig and botColorConfig.Boxes.Gradients.Bot) or boxesCfg.Gradients.Bot
		if data.LastGradTop ~= gradTop or data.LastGradBot ~= gradBot then
			objects.BoxInlineGradient.Color = ColorSequence.new(gradTop, gradBot)
			data.LastGradTop = gradTop
			data.LastGradBot = gradBot
		end

		if boxesCfg.Filled.Enabled then
			if not objects.BoxFill.Visible then objects.BoxFill.Visible = true end
			local fillTop = (botColorConfig and botColorConfig.Boxes.Filled.Top) or boxesCfg.Filled.Top
			local fillBot = (botColorConfig and botColorConfig.Boxes.Filled.Bot) or boxesCfg.Filled.Bot
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

		if not playerObj and config.Bots and config.Bots.Name ~= "" then
			displayName = config.Bots.Name
		end

		if data.LastDisplayName ~= displayName then
			objects.TargetName.Text = displayName
			data.LastDisplayName = displayName
		end

		local nameColor = (botColorConfig and botColorConfig.Texts.Name.Color) or textsCfg.Name.Color
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

		local distColor = (botColorConfig and botColorConfig.Texts.Distance.Color) or textsCfg.Distance.Color
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

		local barColor = (botColorConfig and botColorConfig.Bars["Health Bar"].Color) or healthCfg.Color
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

	local stateColor = (botColorConfig and botColorConfig.Texts.State.Color) or textsCfg.State.Color
	if data.LastStateColor ~= stateColor then
		objects.StateFlag.TextColor3 = stateColor
		objects.WalkFlag.TextColor3 = stateColor
		objects.JumpFlag.TextColor3 = stateColor
		data.LastStateColor = stateColor
	end

	local currentWeapon, toolInst = resolveEquippedWeapon(character)
	data.CurrentWeapon = currentWeapon

	local iconCfg = textsCfg.WeaponIcon
	local hasValidWeapon = currentWeapon ~= "none" and currentWeapon ~= "Worldmodel"
	local showIcon = iconCfg and iconCfg.Enabled and hasValidWeapon

	local weaponCfg = textsCfg.Weapon
	if weaponCfg.Enabled and not showIcon then
		if hasValidWeapon then
			if not objects.Weapon.Visible then objects.Weapon.Visible = true end
			if data.LastWeapon ~= currentWeapon then
				objects.Weapon.Text = currentWeapon
				data.LastWeapon = currentWeapon
			end
			local weaponColor = (botColorConfig and botColorConfig.Texts.Weapon.Color) or weaponCfg.Color
			if data.LastWeaponColor ~= weaponColor then
				objects.Weapon.TextColor3 = weaponColor
				data.LastWeaponColor = weaponColor
			end
		else
			if objects.Weapon.Visible then objects.Weapon.Visible = false end
		end
	else
		if objects.Weapon.Visible then objects.Weapon.Visible = false end
	end

	if showIcon then
		local iconSize = iconCfg.Size or 26
		local iconW = typeof(iconSize) == "Vector2" and iconSize.X or mathFloor(iconSize * 1.9)
		local iconH = typeof(iconSize) == "Vector2" and iconSize.Y or iconSize

		if data.LastIconW ~= iconW or data.LastIconH ~= iconH then
			objects.WeaponIcon.Size = udim2FromOffset(iconW, iconH)
			data.LastIconW = iconW
			data.LastIconH = iconH
		end

		if data.LastIconWeapon ~= currentWeapon or #objects.WeaponIcon:GetChildren() == 0 then
			objects.WeaponIcon:ClearAllChildren()

			local newViewport = getWeaponViewport(currentWeapon, toolInst)
			if newViewport then
				newViewport.Size = newUDim2(1, 0, 1, 0)
				newViewport.Position = newUDim2(0, 0, 0, 0)
				newViewport.BackgroundTransparency = 1
				newViewport.BorderSizePixel = 0
				newViewport.Visible = true
				newViewport.ZIndex = 10
				newViewport.Parent = objects.WeaponIcon
				data.LastIconWeapon = currentWeapon
				if not objects.WeaponIcon.Visible then
					objects.WeaponIcon.Visible = true
				end
			else
				if objects.WeaponIcon.Visible then
					objects.WeaponIcon.Visible = false
				end
				data.LastIconWeapon = nil
			end
		else
			if not objects.WeaponIcon.Visible and #objects.WeaponIcon:GetChildren() > 0 then
				objects.WeaponIcon.Visible = true
			end
		end
	else
		if objects.WeaponIcon.Visible then
			objects.WeaponIcon.Visible = false
			objects.WeaponIcon:ClearAllChildren()
			data.LastIconWeapon = nil
		end
	end
end

function Arbuzi:Load()
	if self.Loaded then return self end

	updateCameraCache()

	self.Holder = self:CreateObjects("ScreenGui", {
		Name = "\n",
		Parent = getGuiParent(),
		ResetOnSpawn = false,
		DisplayOrder = 10,
		IgnoreGuiInset = true
	})

	self.WorldHolder = self:CreateObjects("Frame", {
		Parent = self.Holder,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = newUDim2(1, 0, 1, 0),
		Position = newUDim2(0, 0, 0, 0)
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

	local function bindFolder(folderName, callback)
		local folder = workspaceService:FindFirstChild(folderName)
		if folder then
			for _, child in ipairs(folder:GetChildren()) do
				callback(child)
			end
			self.Threads[folderName .. "_ChildAdded"] = folder.ChildAdded:Connect(callback)
		end
	end

	bindFolder("Npcs", function(child)
		if config.Bots and config.Bots.Enabled and child:IsA("Model") then
			self:AddTarget(child)
		end
	end)

	bindFolder("Nodes", function(child)
		self:AddOre(child)
	end)

	bindFolder("Pickups", function(child)
		self:AddPickup(child)
	end)

	bindFolder("Animals", function(child)
		self:AddAnimal(child)
	end)

	self.Threads["WorkspaceChildAdded"] = workspaceService.ChildAdded:Connect(function(child)
		local lowerName = child.Name:lower()
		if lowerName == "npcs" and child:IsA("Folder") then
			bindFolder(child.Name, function(npc) self:AddTarget(npc) end)
		elseif lowerName == "nodes" and child:IsA("Folder") then
			bindFolder(child.Name, function(node) self:AddOre(node) end)
		elseif lowerName == "pickups" and child:IsA("Folder") then
			bindFolder(child.Name, function(pickup) self:AddPickup(pickup) end)
		elseif lowerName == "animals" and child:IsA("Folder") then
			bindFolder(child.Name, function(animal) self:AddAnimal(animal) end)
		elseif matchOreType(child.Name) then
			self:AddOre(child)
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
			task.wait(1.5)

			if not self.Holder or not self.Holder.Parent then
				self.Holder = self:CreateObjects("ScreenGui", {
					Name = "\n",
					Parent = getGuiParent(),
					ResetOnSpawn = false,
					DisplayOrder = 10,
					IgnoreGuiInset = true
				})
				self.WorldHolder = self:CreateObjects("Frame", {
					Parent = self.Holder,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = newUDim2(1, 0, 1, 0),
					Position = newUDim2(0, 0, 0, 0)
				})
				for _, data in pairs(self.Cache) do
					if typeof(data) == "table" and data.Objects and data.Objects.TargetHolder then
						data.Objects.TargetHolder.Parent = self.Holder
					end
				end
				for _, data in pairs(self.OreCache) do
					if typeof(data) == "table" and data.Label then
						data.Label.Parent = self.WorldHolder
					end
				end
				for _, data in pairs(self.PickupCache) do
					if typeof(data) == "table" and data.Label then
						data.Label.Parent = self.WorldHolder
					end
				end
				for _, data in pairs(self.AnimalCache) do
					if typeof(data) == "table" and data.Label then
						data.Label.Parent = self.WorldHolder
					end
				end
			end

			if config.Players then
				for _, player in ipairs(playersService:GetPlayers()) do
					if player == localPlayer then continue end
					local char = player.Character or workspaceService:FindFirstChild(player.Name)
					if char and char:IsA("Model") and char.Parent and not self.Cache[char] then
						self:AddTarget(char)
					end
				end
			end

			if config.Bots and config.Bots.Enabled then
				for _, model in ipairs(workspaceService:GetChildren()) do
					if model:IsA("Model") and model ~= localPlayer.Character and not self.Cache[model] then
						local hum = model:FindFirstChildOfClass("Humanoid")
						if hum and not playersService:GetPlayerFromCharacter(model) then
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

			for node in pairs(self.OreCache) do
				if typeof(node) ~= "Instance" or not node.Parent or not node:IsDescendantOf(workspaceService) then
					self:RemoveOre(node)
				end
			end

			for pickup in pairs(self.PickupCache) do
				if typeof(pickup) ~= "Instance" or not pickup.Parent or not pickup:IsDescendantOf(workspaceService) then
					self:RemovePickup(pickup)
				end
			end

			for animal in pairs(self.AnimalCache) do
				if typeof(animal) ~= "Instance" or not animal.Parent or not animal:IsDescendantOf(workspaceService) then
					self:RemoveAnimal(animal)
				end
			end
		end
	end)

	self.PreRender = runService.RenderStepped:Connect(function()
		if not config.Enabled then
			for _, data in pairs(self.Cache) do
				if typeof(data) == "table" and data.Objects and data.Objects.TargetHolder and data.Objects.TargetHolder.Visible then
					data.Objects.TargetHolder.Visible = false
				end
			end
			for _, data in pairs(self.OreCache) do
				if typeof(data) == "table" and data.Label and data.Label.Visible then
					data.Label.Visible = false
				end
			end
			for _, data in pairs(self.PickupCache) do
				if typeof(data) == "table" and data.Label and data.Label.Visible then
					data.Label.Visible = false
				end
			end
			for _, data in pairs(self.AnimalCache) do
				if typeof(data) == "table" and data.Label and data.Label.Visible then
					data.Label.Visible = false
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

		-- ORES
		local oreCfg = config.Ores
		if oreCfg and oreCfg.Enabled then
			local maxDist = oreCfg.MaxDistance or 2500
			local showDist = oreCfg.ShowDistance

			for _, data in pairs(self.OreCache) do
				local typeCfg = oreCfg[data.OreType]
				if not typeCfg or not typeCfg.Enabled then
					if data.Label.Visible then data.Label.Visible = false end
					continue
				end

				local dist = (cameraPosition - data.Position).Magnitude
				if dist > maxDist then
					if data.Label.Visible then data.Label.Visible = false end
					continue
				end

				local screenPos, onScreen = camera:WorldToViewportPoint(data.Position)
				if not onScreen or screenPos.Z <= 0 then
					if data.Label.Visible then data.Label.Visible = false end
					continue
				end

				local posX = mathFloor(screenPos.X)
				local posY = mathFloor(screenPos.Y)
				local flooredDist = mathFloor(dist)

				if data.LastX ~= posX or data.LastY ~= posY then
					data.Label.Position = udim2FromOffset(posX, posY)
					data.LastX = posX
					data.LastY = posY
				end

				if data.LastDist ~= flooredDist then
					if showDist then
						data.Label.Text = stringFormat("%s [%d st]", typeCfg.DisplayName or data.OreType, flooredDist)
					else
						data.Label.Text = typeCfg.DisplayName or data.OreType
					end
					data.LastDist = flooredDist
				end

				if data.Label.TextColor3 ~= typeCfg.Color then
					data.Label.TextColor3 = typeCfg.Color
				end

				if not data.Label.Visible then data.Label.Visible = true end
			end
		else
			for _, data in pairs(self.OreCache) do
				if data.Label and data.Label.Visible then data.Label.Visible = false end
			end
		end

		-- PICKUPS
		local pickupCfg = config.Pickups
		if pickupCfg and pickupCfg.Enabled then
			local maxDist = pickupCfg.MaxDistance or 1500
			local showDist = pickupCfg.ShowDistance
			local color = pickupCfg.Color
			local filter = pickupCfg.Filter

			for _, data in pairs(self.PickupCache) do
				if filter and not isItemAllowed(filter, data.Name) then
					if data.Label.Visible then data.Label.Visible = false end
					continue
				end

				local dist = (cameraPosition - data.Position).Magnitude
				if dist > maxDist then
					if data.Label.Visible then data.Label.Visible = false end
					continue
				end

				local screenPos, onScreen = camera:WorldToViewportPoint(data.Position)
				if not onScreen or screenPos.Z <= 0 then
					if data.Label.Visible then data.Label.Visible = false end
					continue
				end

				local posX = mathFloor(screenPos.X)
				local posY = mathFloor(screenPos.Y)
				local flooredDist = mathFloor(dist)

				if data.LastX ~= posX or data.LastY ~= posY then
					data.Label.Position = udim2FromOffset(posX, posY)
					data.LastX = posX
					data.LastY = posY
				end

				if data.LastDist ~= flooredDist then
					if showDist then
						data.Label.Text = stringFormat("%s [%d st]", data.Name, flooredDist)
					else
						data.Label.Text = data.Name
					end
					data.LastDist = flooredDist
				end

				if data.Label.TextColor3 ~= color then
					data.Label.TextColor3 = color
				end

				if not data.Label.Visible then data.Label.Visible = true end
			end
		else
			for _, data in pairs(self.PickupCache) do
				if data.Label and data.Label.Visible then data.Label.Visible = false end
			end
		end

		-- ANIMALS
		local animalCfg = config.Animals
		if animalCfg and animalCfg.Enabled then
			local maxDist = animalCfg.MaxDistance or 2500
			local showDist = animalCfg.ShowDistance
			local color = animalCfg.Color

			for _, data in pairs(self.AnimalCache) do
				local part = data.Part
				if not part or not part.Parent then
					part = resolveEntityPart(data.Instance)
					data.Part = part
				end

				if not part then
					if data.Label.Visible then data.Label.Visible = false end
					continue
				end

				local worldPos = part.Position
				local dist = (cameraPosition - worldPos).Magnitude
				if dist > maxDist then
					if data.Label.Visible then data.Label.Visible = false end
					continue
				end

				local screenPos, onScreen = camera:WorldToViewportPoint(worldPos)
				if not onScreen or screenPos.Z <= 0 then
					if data.Label.Visible then data.Label.Visible = false end
					continue
				end

				local posX = mathFloor(screenPos.X)
				local posY = mathFloor(screenPos.Y)
				local flooredDist = mathFloor(dist)

				if data.LastX ~= posX or data.LastY ~= posY then
					data.Label.Position = udim2FromOffset(posX, posY)
					data.LastX = posX
					data.LastY = posY
				end

				if data.LastDist ~= flooredDist then
					if showDist then
						data.Label.Text = stringFormat("%s [%d st]", data.Name, flooredDist)
					else
						data.Label.Text = data.Name
					end
					data.LastDist = flooredDist
				end

				if data.Label.TextColor3 ~= color then
					data.Label.TextColor3 = color
				end

				if not data.Label.Visible then data.Label.Visible = true end
			end
		else
			for _, data in pairs(self.AnimalCache) do
				if data.Label and data.Label.Visible then data.Label.Visible = false end
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

	for node in pairs(self.OreCache) do
		self:RemoveOre(node)
	end

	for pickup in pairs(self.PickupCache) do
		self:RemovePickup(pickup)
	end

	for animal in pairs(self.AnimalCache) do
		self:RemoveAnimal(animal)
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
	tableClear(self.OreCache)
	tableClear(self.PickupCache)
	tableClear(self.AnimalCache)
	shared.Arbuzi = nil
end

return Arbuzi
