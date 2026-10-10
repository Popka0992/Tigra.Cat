local cloneref = cloneref or function(o) return o end

-- Services.
local playersService = cloneref(game:GetService("Players"))
local runService = cloneref(game:GetService("RunService"))
local userInputService = cloneref(game:GetService("UserInputService"))
local workspaceService = cloneref(game:GetService("Workspace"))
local replicatedStorage = cloneref(game:GetService("ReplicatedStorage"))

local localPlayer = playersService.LocalPlayer
local currentCamera = workspaceService.CurrentCamera

local Misc = {}
Misc.__index = Misc

local FLY_PULSE_DURATION = 0.7

local VALID_NAMES = {
	["doorframe"] = true,
	["door frame"] = true,
	["window frame"] = true,
	["windowframe"] = true,
	["triangle floor"] = true,
	["floor"] = true,
	["wall frame"] = true,
	["wallframe"] = true,
	["half wall"] = true,
	["halfwall"] = true,
	["wall"] = true,
	["foundation"] = true,
	["triangle foundation"] = true,
	["triange foundation"] = true,
	["iron door"] = true,
	["iron double door"] = true,
	["wood door"] = true,
	["wood double door"] = true,
	["steel door"] = true,
	["steel double door"] = true,
	["garage door"] = true,
	["door"] = true,
}

local flyStartTime = 0
local isPulsingGround = false

-- Zoom State.
local savedCameraFov = nil
local isZoomActive = false

-- X-Ray Cache.
local xrayActive = false
local cachedParts = {}
local cachedDecals = {}
local cachedSurfaceAppearances = {}
local xrayWatchConns = {}

local MiscConfig = {
	SpeedEnabled = false,
	SpeedValue = 28,

	FlyEnabled = false,
	FlyMethod = "CFrame",
	FlySpeed = 45,
	FlyTimerEnabled = true,
	FlyTimerDuration = 3,
	FlyTimerMode = "Pulse Ground",

	ZoomEnabled = false,
	ZoomFOV = 25,

	XRayEnabled = false,
	XRayTransparency = 1,

	InstantLoot = false,
	NoFall = false,
}

local heartbeatConn = nil
local renderSteppedConn = nil

---Setup QuickLoot delay override.
local function setupInstantLoot()
	task.spawn(function()
		local modules = replicatedStorage:WaitForChild("Modules", 10)
		if not modules then return end
		local client = modules:WaitForChild("Client", 10)
		if not client then return end
		local invFolder = client:WaitForChild("Inventory", 10)
		if not invFolder then return end
		local invMod = invFolder:FindFirstChild("Inventory")
		if not invMod then return end

		pcall(function()
			local invData = require(invMod)
			local qLoot = rawget(invData, "QuickLoot")
			if typeof(qLoot) == "function" and debug.info(qLoot, "s") ~= "[C]" then
				local origEnv = getfenv(qLoot)
				local fakeTask = setmetatable({
					delay = newcclosure(function(dTime, fn, ...)
						if MiscConfig.InstantLoot then
							return fn(...)
						end
						return task.delay(dTime, fn, ...)
					end)
				}, {__index = origEnv.task or task})
				setfenv(qLoot, setmetatable({task = fakeTask}, {__index = origEnv}))
			end
		end)
	end)
end

---Get normalized transparency between 0 and 1.
---@return number
local function getNormalizedTransparency()
	local raw = MiscConfig.XRayTransparency
	if typeof(raw) ~= "number" then return 1 end
	if raw > 1 then
		return math.clamp(raw / 100, 0, 1)
	end
	return math.clamp(raw, 0, 1)
end

---Check whether the instance is a valid base structure.
---@param inst Instance
---@return boolean
local function isTargetBuilding(inst)
	if not inst:IsA("BasePart") or inst:IsA("Terrain") then
		return false
	end

	local model = inst:FindFirstAncestorOfClass("Model")
	if model and (model:FindFirstChildOfClass("Humanoid") or playersService:GetPlayerFromCharacter(model)) then
		return false
	end

	local current = inst
	local isMatch = false

	while current and current ~= workspaceService do
		local lowerName = current.Name:lower()

		if lowerName:find("bear trap", 1, true) or lowerName:find("beartrap", 1, true) then
			return false
		end

		for validName in pairs(VALID_NAMES) do
			if lowerName:find(validName, 1, true) then
				isMatch = true
				break
			end
		end

		current = current.Parent
	end

	return isMatch
end

---Apply transparency and hide decals/appearances on a single part.
---@param part BasePart
---@param targetTransparency number
local function applyPartXRay(part, targetTransparency)
	if not isTargetBuilding(part) then return end

	if cachedParts[part] == nil then
		cachedParts[part] = part.Transparency
	end
	part.Transparency = targetTransparency

	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("SurfaceAppearance") then
			table.insert(cachedSurfaceAppearances, { Object = child, Parent = part })
			child.Parent = nil
		elseif child:IsA("Decal") or child:IsA("Texture") then
			if cachedDecals[child] == nil then
				cachedDecals[child] = child.Transparency
			end
			child.Transparency = targetTransparency
		end
	end
end

---Update transparency across all cached instances dynamically.
local function updateXRayTransparency()
	local targetTransparency = getNormalizedTransparency()

	for part in pairs(cachedParts) do
		if part and part.Parent then
			part.Transparency = targetTransparency
		end
	end

	for decal in pairs(cachedDecals) do
		if decal and decal.Parent then
			decal.Transparency = targetTransparency
		end
	end
end

---Disable X-Ray and restore original transparencies.
local function disableXRay()
	xrayActive = false

	for _, conn in ipairs(xrayWatchConns) do
		conn:Disconnect()
	end
	table.clear(xrayWatchConns)

	for _, item in ipairs(cachedSurfaceAppearances) do
		if item.Object and item.Parent and item.Parent.Parent then
			pcall(function()
				item.Object.Parent = item.Parent
			end)
		end
	end
	table.clear(cachedSurfaceAppearances)

	for part, original in pairs(cachedParts) do
		if part and part.Parent then
			pcall(function()
				part.Transparency = original
			end)
		end
	end
	table.clear(cachedParts)

	for decal, original in pairs(cachedDecals) do
		if decal and decal.Parent then
			pcall(function()
				decal.Transparency = original
			end)
		end
	end
	table.clear(cachedDecals)
end

---Enable X-Ray and scan Workspace.
local function enableXRay()
	if xrayActive then
		updateXRayTransparency()
		return
	end
	xrayActive = true

	local targetTransparency = getNormalizedTransparency()

	for _, desc in ipairs(workspaceService:GetDescendants()) do
		if desc:IsA("BasePart") then
			applyPartXRay(desc, targetTransparency)
		end
	end

	table.insert(xrayWatchConns, workspaceService.DescendantAdded:Connect(function(desc)
		if xrayActive and desc:IsA("BasePart") then
			task.defer(applyPartXRay, desc, getNormalizedTransparency())
		end
	end))
end

function Misc:GetConfig()
	return MiscConfig
end

function Misc:Unload()
	MiscConfig.SpeedEnabled = false
	MiscConfig.FlyEnabled = false
	MiscConfig.ZoomEnabled = false
	MiscConfig.XRayEnabled = false
	MiscConfig.InstantLoot = false
	MiscConfig.NoFall = false

	disableXRay()

	if isZoomActive and savedCameraFov then
		currentCamera.FieldOfView = savedCameraFov
		isZoomActive = false
	end

	if heartbeatConn then
		heartbeatConn:Disconnect()
		heartbeatConn = nil
	end

	if renderSteppedConn then
		renderSteppedConn:Disconnect()
		renderSteppedConn = nil
	end
end

function Misc:Load()
	setupInstantLoot()

	-- Network Remote Hook for Fall Damage.
	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		if checkcaller() then
			return oldNamecall(self, ...)
		end

		local method = getnamecallmethod()
		if method == "FireServer" and MiscConfig.NoFall then
			local remoteName = self.Name
			local firstArg = ...
			if firstArg == "TFD" or firstArg == "FallDamage" or firstArg == "Fall" or remoteName:find("Fall") then
				return
			end
		end

		return oldNamecall(self, ...)
	end))

	-- Camera Render Loop (Zoom).
	renderSteppedConn = runService.RenderStepped:Connect(function()
		currentCamera = workspaceService.CurrentCamera or currentCamera

		if MiscConfig.ZoomEnabled then
			if not isZoomActive then
				isZoomActive = true
				savedCameraFov = currentCamera.FieldOfView
			end
			currentCamera.FieldOfView = MiscConfig.ZoomFOV
		else
			if isZoomActive then
				isZoomActive = false
				currentCamera.FieldOfView = savedCameraFov or 70
				savedCameraFov = nil
			end
		end
	end)

	-- Movement, Fly & Fall Damage Dampening.
	heartbeatConn = runService.Heartbeat:Connect(function(dt)
		local character = localPlayer.Character
		if not character then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not (humanoid and rootPart and humanoid.Health > 0) then return end

		currentCamera = workspaceService.CurrentCamera or currentCamera
		local stepDt = math.clamp(dt, 0.001, 0.033)

		-- Physical Fall Damage Dampening.
		if MiscConfig.NoFall then
			local vel = rootPart.AssemblyLinearVelocity
			if vel.Y < -20 then
				rootPart.AssemblyLinearVelocity = Vector3.new(vel.X, -20, vel.Z)

				local rayParams = RaycastParams.new()
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				rayParams.FilterDescendantsInstances = {character}
				rayParams.IgnoreWater = true

				local hit = workspaceService:Raycast(rootPart.Position, Vector3.new(0, -10, 0), rayParams)
				if hit then
					rootPart.AssemblyLinearVelocity = Vector3.new(vel.X, -1, vel.Z)
					humanoid:ChangeState(Enum.HumanoidStateType.Landed)
				end
			end
		end

		-- Fly.
		local isFlying = MiscConfig.FlyEnabled
		if isFlying then
			if flyStartTime == 0 then
				flyStartTime = os.clock()
			end

			if MiscConfig.FlyTimerEnabled and not isPulsingGround and (os.clock() - flyStartTime >= MiscConfig.FlyTimerDuration) then
				flyStartTime = os.clock()

				if MiscConfig.FlyTimerMode == "Auto Disable" then
					MiscConfig.FlyEnabled = false
					return
				elseif MiscConfig.FlyTimerMode == "Pulse Ground" then
					task.spawn(function()
						isPulsingGround = true

						local rayParams = RaycastParams.new()
						rayParams.FilterType = Enum.RaycastFilterType.Exclude
						rayParams.FilterDescendantsInstances = {character}
						rayParams.IgnoreWater = true

						local castOrigin = rootPart.Position
						local rayResult = workspaceService:Raycast(castOrigin, Vector3.new(0, -2000, 0), rayParams)

						if rayResult then
							local airCFrame = rootPart.CFrame
							local hipHeight = humanoid.HipHeight > 0 and humanoid.HipHeight or 2
							local targetFloorY = rayResult.Position.Y + hipHeight + (rootPart.Size.Y / 2)

							rootPart.CFrame = CFrame.new(rootPart.Position.X, targetFloorY, rootPart.Position.Z)
							rootPart.AssemblyLinearVelocity = Vector3.new(0, -1, 0)
							humanoid:ChangeState(Enum.HumanoidStateType.Landed)

							task.wait(FLY_PULSE_DURATION)

							if MiscConfig.FlyEnabled and character and character.Parent then
								rootPart.CFrame = airCFrame
								rootPart.AssemblyLinearVelocity = Vector3.zero
							end
						else
							humanoid:ChangeState(Enum.HumanoidStateType.Landed)
							task.wait(FLY_PULSE_DURATION)
						end

						flyStartTime = os.clock()
						isPulsingGround = false
					end)
				end
			end

			if not isPulsingGround then
				local camCF = currentCamera.CFrame
				local flyDir = Vector3.zero

				if userInputService:IsKeyDown(Enum.KeyCode.W) then flyDir = flyDir + camCF.LookVector end
				if userInputService:IsKeyDown(Enum.KeyCode.S) then flyDir = flyDir - camCF.LookVector end
				if userInputService:IsKeyDown(Enum.KeyCode.D) then flyDir = flyDir + camCF.RightVector end
				if userInputService:IsKeyDown(Enum.KeyCode.A) then flyDir = flyDir - camCF.RightVector end
				if userInputService:IsKeyDown(Enum.KeyCode.Space) then flyDir = flyDir + Vector3.yAxis end
				if userInputService:IsKeyDown(Enum.KeyCode.LeftShift) then flyDir = flyDir - Vector3.yAxis end

				if MiscConfig.FlyMethod == "CFrame" then
					rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
					if flyDir.Magnitude > 0 then
						rootPart.CFrame = rootPart.CFrame + (flyDir.Unit * (MiscConfig.FlySpeed * stepDt))
					end
				elseif MiscConfig.FlyMethod == "Velocity" then
					if flyDir.Magnitude > 0 then
						rootPart.AssemblyLinearVelocity = flyDir.Unit * MiscConfig.FlySpeed
					else
						rootPart.AssemblyLinearVelocity = Vector3.new(0, 0.01, 0)
					end
				end
			end
			return
		else
			flyStartTime = 0
		end

		-- Speed.
		local isSpeeding = MiscConfig.SpeedEnabled
		if isSpeeding then
			local moveDir = humanoid.MoveDirection
			if moveDir.Magnitude > 0 then
				local flatDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
				rootPart.CFrame = rootPart.CFrame + (flatDir * (MiscConfig.SpeedValue * stepDt))
			end
		end
	end)

	return self
end

---Toggle X-Ray state from outside.
---@param enabled boolean
function Misc:SetXRay(enabled)
	MiscConfig.XRayEnabled = enabled
	if enabled then
		enableXRay()
	else
		disableXRay()
	end
end

---Update X-Ray transparency dynamically.
---@param value number
function Misc:SetXRayTransparency(value)
	MiscConfig.XRayTransparency = value
	if xrayActive then
		updateXRayTransparency()
	end
end

return Misc
