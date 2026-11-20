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
local targetPart, targetPlayer = nil, nil
local isInternalRaycast = false
local conns = {}

local entities, entityByModel = {}, {}
local originalPartSizes = setmetatable({}, { __mode = "k" })

local scannedPartsList = { "All Parts", "Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso" }
local scannedPartsSet = {}
for _, name in ipairs(scannedPartsList) do scannedPartsSet[name] = true end
local partsDirty = false
Combat.PartsList = scannedPartsList

local circleOutline, circleInline
local lastRadius, lastColor = nil, nil
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
		return bridge.Namecall(self, oldNamecall, ...)
	end))
end

local function isDefaultLimb(name)
	return name == "Head" or name:find("Torso") ~= nil or name:find("Arm") ~= nil or name:find("Leg") ~= nil
end

local function addPartRecord(e, part)
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
	local cfg = CombatConfig
	local se
