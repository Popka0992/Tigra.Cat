if shared.Combat and shared.Combat.Unload then
	pcall(shared.Combat.Unload, shared.Combat)
end

local cloneref = cloneref or function(o) return o end

local playersService = cloneref(game:GetService("Players"))
local runService = cloneref(game:GetService("RunService"))
local userInputService = cloneref(game:GetService("UserInputService"))
local workspaceService = cloneref(game:GetService("Workspace"))

local localPlayer = playersService.LocalPlayer
local mouse = localPlayer:GetMouse()
local currentCamera = workspaceService.CurrentCamera

local kEntityRefresh = 0.5
local kHitboxInterval = 0.1
local kBindName = "LigraCombat"

local Combat = {}

local CombatConfig = {
	AimMode = "Silent Aim",
	Enabled = false,
	Keybind = Enum.UserInputType.MouseButton2,
	KeybindMode = "Hold",
	AimActive = false,
	HitPart = "Head",
	HitChance = 100,
	Smoothness = 2,
	Wallbang = false,
	ProjectionOverride = false,
	MagicBullet = false,
	TargetPlayers = true,
	TargetBots = true,
	TeamCheck = false,
	DeadCheck = true,
	DistCheck = false,
	MaxDistance = 1000,
	FOV = 100,
	ShowFOV = false,
	FOVColor = Color3.fromRGB(255, 255, 255),
	FOVOutline = false,
	Methods = {
		Raycast = true,
		FindPartOnRay = true,
		FindPartOnRayWithWhitelist = true,
		FindPartOnRayWithIgnoreList = true,
		ScreenPointToRay = true,
		ViewportPointToRay = true,
		Mouse = true,
	},
	HitboxEnabled = false,
	HitboxSize = 6,
	HitboxTrans = 0.6,
	HitboxPart = "All Parts",
	HitboxCustom = true,
}

local RAY_METHODS = {
	Raycast = true,
	ScreenPointToRay = true,
	ViewportPointToRay = true,
	FindPartOnRay = true,
	FindPartOnRayWithIgnoreList = true,
	FindPartOnRayWithWhitelist = true,
}

local loaded = false
local aimKeyActive = false
local targetPart = nil
local isInternalRaycast = false
local conns = {}
local entityTimer, hitboxTimer = 0, 0

local entities, entityByModel = {}, {}
local originalPartSizes = setmetatable({}, { __mode = "k" })
local touched = {}

local scannedPartsList = { "All Parts", "Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso" }
local scannedPartsSet = {}
for _, name in ipairs(scannedPartsList) do scannedPartsSet[name] = true end
local partsDirty = false
Combat.PartsList = scannedPartsList

local circleOutline, circleInline
local lastRadius, lastColor, lastPos = nil, nil, nil
local inlineShown, outlineShown = false, false

local env = getgenv()
local bridge = env.LigraCombatBridge
if not bridge then
	bridge = { Active = false }
	env.LigraCombatBridge = bridge

	local oldIndex
	oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
		if bridge.Active and self == bridge.Mouse and (key == "Hit" or key == "Target") and not checkcaller() then
			local handled, value = bridge.Index(key)
			if handled then return value end
		end
		return oldIndex(self, key)
	end))

	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		if not bridge.Active or checkcaller() then
			return oldNamecall(self, ...)
		end
		return bridge.Namecall(self, oldNamecall, getnamecallmethod(), ...)
	end))
end

local function isDefaultLimb(name)
	return name == "Head" or name:find("Torso") ~= nil or name:find("Arm") ~= nil or name:find("Leg") ~= nil
end

local function addPartRecord(e, part)
	if e.PartSet[part] then return end
	e.PartSet[part] = true
	local name = part.Name
	e.Parts[#e.Parts + 1] = { Part = part, Name = name, Default = isDefaultLimb(name) }
	if not scannedPartsSet[name] then
		scannedPartsSet[name] = true
		table.insert(scannedPartsList, name)
		partsDirty = true
	end
end

local function findRoot(model)
	return model:FindFirstChild("HumanoidRootPart")
		or model.PrimaryPart
		or model:FindFirstChild("Torso")
		or model:FindFirstChild("UpperTorso")
end

local function addEntity(model, player)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = findRoot(model)
	if not (humanoid and root) then return end
	local e = {
		Model = model,
		Player = player,
		IsBot = player == nil,
		Humanoid = humanoid,
		RootPart = root,
		Parts = {},
		PartSet = {},
	}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then addPartRecord(e, d) end
	end
	e.Conn = model.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") then addPartRecord(e, d) end
	end)
	entityByModel[model] = e
	entities[#entities + 1] = e
end

local function removeEntityAt(i)
	local e = entities[i]
	if e.Conn then e.Conn:Disconnect() end
	entityByModel[e.Model] = nil
	table.remove(entities, i)
end

local function refreshEntities()
	local live = {}
	local myChar = localPlayer.Character

	for _, player in ipairs(playersService:GetPlayers()) do
		local char = player.Character
		if player ~= localPlayer and char and char.Parent then
			live[char] = player
		end
	end
	for _, obj in ipairs(workspaceService:GetChildren()) do
		if live[obj] == nil and obj ~= myChar and obj:IsA("Model") then
			if entityByModel[obj] or obj:FindFirstChildOfClass("Humanoid") then
				live[obj] = false
			end
		end
	end

	for i = #entities, 1, -1 do
		local e = entities[i]
		if live[e.Model] == nil or not e.Model.Parent or not e.Humanoid.Parent or not e.RootPart.Parent then
			removeEntityAt(i)
		end
	end
	for model, player in pairs(live) do
		if not entityByModel[model] then
			addEntity(model, player or nil)
		end
	end
end

local function isTargetable(e)
	local cfg = CombatConfig
	if not e.Model.Parent then return false end
	if e.IsBot then
		if not cfg.TargetBots then return false end
	else
		if not cfg.TargetPlayers then return false end
		if cfg.TeamCheck and localPlayer.Team and e.Player.Team == localPlayer.Team then return false end
	end
	if cfg.DeadCheck and e.Humanoid.Health <= 0 then return false end
	return true
end

local function rollHitChance()
	local chance = CombatConfig.HitChance
	if chance >= 100 then return true end
	if chance <= 0 then return false end
	return math.random(1, 100) <= chance
end

local function fovRadius()
	local fov = currentCamera.FieldOfView
	if fov <= 0 then fov = 70 end
	return (currentCamera.ViewportSize.X * (CombatConfig.FOV / fov)) / 2
end

local function getClosestPart(mousePos, maxRadius)
	local cfg = CombatConfig
	local camPos = currentCamera.CFrame.Position
	local hitName = cfg.HitPart
	local best, bestDist = nil, maxRadius

	for i = 1, #entities do
		local e = entities[i]
		if isTargetable(e) then
			local model = e.Model
			local part = model:FindFirstChild(hitName) or e.RootPart or model:FindFirstChild("Head")
			if part and part:IsA("BasePart") then
				local pos = part.Position
				if not cfg.DistCheck or (camPos - pos).Magnitude <= cfg.MaxDistance then
					local sp, onScreen = currentCamera:WorldToViewportPoint(pos)
					if onScreen then
						local d = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
						if d <= bestDist then
							best, bestDist = part, d
						end
					end
				end
			end
		end
	end
	return best
end

local function aimDirection(origin, direction, hitpos)
	local delta = hitpos - origin
	if delta.Magnitude < 1e-3 then return nil end
	if CombatConfig.ProjectionOverride then return delta end
	return delta.Unit * direction.Magnitude
end

local function indexHandler(key)
	local cfg = CombatConfig
	local part = targetPart
	if not cfg.Enabled or cfg.AimMode ~= "Silent Aim" or not cfg.Methods.Mouse then return false end
	if not part or not part.Parent or not rollHitChance() then return false end
	if key == "Target" then return true, part end
	return true, part.CFrame
end

local function namecallHandler(self, old, method, ...)
	if isInternalRaycast or not RAY_METHODS[method] then
		return old(self, ...)
	end

	local cfg = CombatConfig
	local hitpart = targetPart
	if not cfg.Enabled or cfg.AimMode ~= "Silent Aim" or not cfg.Methods[method] then
		return old(self, ...)
	end
	if not hitpart or not hitpart.Parent or not rollHitChance() then
		return old(self, ...)
	end

	local hitsize = hitpart.Size
	local hitpos = hitpart.Position + Vector3.new(
		(math.random() - math.random()) * (hitsize.X / 10),
		(math.random() - math.random()) * (hitsize.Y / 10),
		(math.random() - math.random()) * (hitsize.Z / 10)
	)

	if method == "Raycast" then
		local origin, direction = ...
		if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
			return old(self, ...)
		end
		local newDir = aimDirection(origin, direction, hitpos)
		if not newDir then return old(self, ...) end

		if cfg.Wallbang then
			local fakeParams = RaycastParams.new()
			fakeParams.FilterType = Enum.RaycastFilterType.Include
			fakeParams.FilterDescendantsInstances = { hitpart }
			fakeParams.IgnoreWater = true
			isInternalRaycast = true
			local ok, forced = pcall(workspaceService.Raycast, workspaceService, hitpos + Vector3.new(0, 2, 0), Vector3.new(0, -5, 0), fakeParams)
			isInternalRaycast = false
			if ok and forced then return forced end
		end
		return old(self, origin, newDir, select(3, ...))
	end

	if method == "ScreenPointToRay" or method == "ViewportPointToRay" then
		local ray = old(self, ...)
		local newDir = aimDirection(ray.Origin, ray.Direction, hitpos)
		if not newDir then return ray end
		return Ray.new(ray.Origin, newDir)
	end

	local ray = ...
	if typeof(ray) ~= "Ray" then return old(self, ...) end
	local origin = ray.Origin
	local newDir = aimDirection(origin, ray.Direction, hitpos)
	if not newDir then return old(self, ...) end

	if cfg.Wallbang then
		local pos = cfg.MagicBullet and Vector3.new(0 / 0, 0 / 0, 0 / 0) or hitpos
		return hitpart, pos, (origin - hitpos).Unit, hitpart.Material
	end
	return old(self, Ray.new(origin, newDir), select(2, ...))
end

local function createCircles()
	local ok = pcall(function()
		circleOutline = Drawing.new("Circle")
		circleOutline.Thickness = 3
		circleOutline.Color = Color3.new(0, 0, 0)
		circleOutline.Filled = false
		circleOutline.ZIndex = 1
		circleOutline.Visible = false

		circleInline = Drawing.new("Circle")
		circleInline.Thickness = 1
		circleInline.Filled = false
		circleInline.ZIndex = 2
		circleInline.Visible = false
	end)
	if not ok then
		circleOutline, circleInline = nil, nil
	end
end

local function updateCircles(show, radius, mousePos)
	if not circleInline then return end
	local cfg = CombatConfig

	if show then
		if mousePos ~= lastPos then
			circleInline.Position = mousePos
			circleOutline.Position = mousePos
			lastPos = mousePos
		end
		if radius ~= lastRadius then
			circleInline.Radius = radius
			circleOutline.Radius = radius
			lastRadius = radius
		end
		local color = cfg.FOVColor
		if color ~= lastColor then
			circleInline.Color = color
			lastColor = color
		end
	end

	if show ~= inlineShown then
		circleInline.Visible = show
		inlineShown = show
	end
	local outline = show and cfg.FOVOutline or false
	if outline ~= outlineShown then
		circleOutline.Visible = outline
		outlineShown = outline
	end
end

local function restorePart(part, data)
	if part.Parent then
		part.Size = data.Size
		part.Transparency = data.Transparency
		part.CanCollide = data.CanCollide
		part.Massless = data.Massless
	end
end

local function restoreAll()
	for part, data in pairs(originalPartSizes) do
		restorePart(part, data)
		originalPartSizes[part] = nil
	end
end

local function hitboxPass()
	local cfg = CombatConfig
	if not cfg.HitboxEnabled then
		if next(originalPartSizes) ~= nil then restoreAll() end
		return
	end

	local s = cfg.HitboxSize
	local targetSize = Vector3.new(s, s, s)
	local trans = cfg.HitboxTrans
	local mode = cfg.HitboxPart
	local custom = cfg.HitboxCustom
	table.clear(touched)

	for i = 1, #entities do
		local e = entities[i]
		if isTargetable(e) then
			local parts = e.Parts
			for j = #parts, 1, -1 do
				local rec = parts[j]
				local part = rec.Part
				if not part.Parent then
					e.PartSet[part] = nil
					table.remove(parts, j)
				elseif rec.Name ~= "HumanoidRootPart" then
					if mode == "All Parts" or mode == rec.Name or (custom and not rec.Default) then
						touched[part] = true
						if not originalPartSizes[part] then
							originalPartSizes[part] = {
								Size = part.Size,
								Transparency = part.Transparency,
								CanCollide = part.CanCollide,
								Massless = part.Massless,
							}
						end
						if part.Size ~= targetSize then part.Size = targetSize end
						if part.Transparency ~= trans then part.Transparency = trans end
						if part.CanCollide then part.CanCollide = false end
						if not part.Massless then part.Massless = true end
					end
				end
			end
		end
	end

	for part, data in pairs(originalPartSizes) do
		if not touched[part] then
			restorePart(part, data)
			originalPartSizes[part] = nil
		end
	end
end

local function onRender()
	local cfg = CombatConfig
	currentCamera = workspaceService.CurrentCamera or currentCamera
	local cam = currentCamera
	if not cam then return end

	local mousePos = userInputService:GetMouseLocation()
	local radius = fovRadius()
	local aiming = aimKeyActive or cfg.AimActive
	local silent = cfg.AimMode == "Silent Aim"

	updateCircles(cfg.Enabled and cfg.ShowFOV, radius, mousePos)

	if cfg.Enabled and (silent or aiming) then
		targetPart = getClosestPart(mousePos, radius)
	else
		targetPart = nil
	end

	bridge.Active = cfg.Enabled and silent and targetPart ~= nil

	if cfg.Enabled and not silent and aiming and targetPart and targetPart.Parent then
		local look = CFrame.lookAt(cam.CFrame.Position, targetPart.Position)
		local smooth = math.clamp(cfg.Smoothness, 1, 30)
		if smooth <= 1 then
			cam.CFrame = look
		else
			cam.CFrame = cam.CFrame:Lerp(look, 1 / smooth)
		end
	end
end

local function onHeartbeat(dt)
	entityTimer = entityTimer + dt
	if entityTimer >= kEntityRefresh then
		entityTimer = 0
		refreshEntities()
	end
	hitboxTimer = hitboxTimer + dt
	if hitboxTimer >= kHitboxInterval then
		hitboxTimer = 0
		hitboxPass()
	end
end


function Combat:GetConfig()
	return CombatConfig
end

function Combat:RefreshParts()
	refreshEntities()
	local dirty = partsDirty
	partsDirty = false
	return dirty
end

function Combat:SetAimActive(state)
	aimKeyActive = state and true or false
	CombatConfig.AimActive = aimKeyActive
end

function Combat:Load()
	if loaded then return self end
	loaded = true
	currentCamera = workspaceService.CurrentCamera or currentCamera

	createCircles()
	refreshEntities()

	bridge.Mouse = mouse
	bridge.Index = indexHandler
	bridge.Namecall = namecallHandler

	pcall(runService.UnbindFromRenderStep, runService, kBindName)
	runService:BindToRenderStep(kBindName, Enum.RenderPriority.Camera.Value + 1, onRender)
	conns[#conns + 1] = runService.Heartbeat:Connect(onHeartbeat)

	shared.Combat = self
	return self
end

function Combat:Unload()
	loaded = false
	bridge.Active = false
	bridge.Index = nil
	bridge.Namecall = nil

	pcall(runService.UnbindFromRenderStep, runService, kBindName)
	for _, c in ipairs(conns) do c:Disconnect() end
	table.clear(conns)

	restoreAll()
	for i = #entities, 1, -1 do removeEntityAt(i) end
	table.clear(touched)

	if circleInline then pcall(function() circleInline:Remove() end) end
	if circleOutline then pcall(function() circleOutline:Remove() end) end
	circleInline, circleOutline = nil, nil
	lastRadius, lastColor, lastPos = nil, nil, nil
	inlineShown, outlineShown = false, false

	targetPart = nil
	aimKeyActive = false
	CombatConfig.AimActive = false
	if shared.Combat == self then shared.Combat = nil end
end

return Combat
