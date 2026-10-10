local cloneref = cloneref or function(o) return o end

-- Services.
local playersService = cloneref(game:GetService("Players"))
local runService = cloneref(game:GetService("RunService"))
local userInputService = cloneref(game:GetService("UserInputService"))
local workspaceService = cloneref(game:GetService("Workspace"))
local replicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local contextActionService = cloneref(game:GetService("ContextActionService"))

local localPlayer = playersService.LocalPlayer
local originalCamera = workspaceService.CurrentCamera

local Misc = {}
Misc.__index = Misc

local FLY_PULSE_DURATION = 0.7
local flyStartTime = 0
local isPulsingGround = false

-- Freecam State (Virtual Camera).
local freecamActive = false
local freecamCamera = nil
local freecamPos = Vector3.zero
local freecamPitch = 0
local freecamYaw = 0
local savedCameraType = nil
local savedCameraSubject = nil
local savedAnchored = false
local frozenCharacterCFrame = nil

-- Zoom State.
local savedCameraFov = nil
local isZoomActive = false

-- X-Ray Cache.
local xrayActive = false
local cachedPartTransparencies = setmetatable({}, { __mode = "k" })
local xrayWatchConns = {}

local BLOCKED_FREECAM_KEYS = {
	[Enum.KeyCode.W] = true,
	[Enum.KeyCode.A] = true,
	[Enum.KeyCode.S] = true,
	[Enum.KeyCode.D] = true,
	[Enum.KeyCode.Space] = true,
	[Enum.KeyCode.LeftShift] = true,
	[Enum.KeyCode.LeftControl] = true,
	[Enum.KeyCode.Q] = true,
	[Enum.KeyCode.E] = true,
	[Enum.KeyCode.C] = true,
}

local TARGET_CONTAINER_NAMES = {
	["builtobjects"] = true,
	["builtobject"] = true,
	["doors"] = true,
	["door"] = true,
}

local TARGET_PART_NAMES = {
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
}

local MiscConfig = {
	SpeedEnabled = false,
	SpeedValue = 28,

	FlyEnabled = false,
	FlyMethod = "CFrame",
	FlySpeed = 45,
	FlyTimerEnabled = true,
	FlyTimerDuration = 3,
	FlyTimerMode = "Pulse Ground",

	FreecamEnabled = false,
	FreecamSpeed = 45,
	FreecamShiftBoost = 2,

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

---Toggle default PlayerModule controls with safe identity bracketing.
local function setControlsEnabled(enabled)
	pcall(function()
		local playerScripts = localPlayer:FindFirstChild("PlayerScripts")
		local playerModule = playerScripts and playerScripts:FindFirstChild("PlayerModule")
		if playerModule then
			setthreadidentity(2)
			local controls = require(playerModule):GetControls()
			setthreadidentity(8)
			if enabled then
				controls:Enable()
			else
				controls:Disable()
			end
		end
	end)
end

---Sink movement inputs.
local function sinkMovementAction()
	return Enum.ContextActionResult.Sink
end

---Check whether an instance represents a base building or door.
---@param inst Instance?
---@return boolean
local function isBuildingInstance(inst)
	if not inst or not inst:IsA("BasePart") or inst:IsA("Terrain") then
		return false
	end

	local current = inst
	while current and current ~= workspaceService do
		local lowerName = current.Name:lower()

		if string.find(lowerName, "bear trap") or string.find(lowerName, "beartrap") then
			return false
		end

		if TARGET_CONTAINER_NAMES[lowerName] or TARGET_PART_NAMES[lowerName] then
			return true
		end

		current = current.Parent
	end

	return false
end

---Enable freecam using a completely separate virtual camera.
local function enableFreecam()
	originalCamera = workspaceService.CurrentCamera
	if not originalCamera then return end

	savedCameraType = originalCamera.CameraType
	savedCameraSubject = originalCamera.CameraSubject

	local startCFrame = originalCamera.CFrame
	freecamPos = startCFrame.Position
	local _, yaw, _ = startCFrame:ToOrientation()
	local pitch = math.asin(startCFrame.LookVector.Y)
	freecamYaw = yaw
	freecamPitch = pitch

	-- Создаем отдельную камеру исключительно для рендеринга свободного полета.
	freecamCamera = Instance.new("Camera")
	freecamCamera.Name = "FreecamVirtualCamera"
	freecamCamera.CameraType = Enum.CameraType.Scriptable
	freecamCamera.FieldOfView = originalCamera.FieldOfView
	freecamCamera.CFrame = startCFrame
	freecamCamera.Parent = workspaceService

	local character = localPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if rootPart then
		savedAnchored = rootPart.Anchored
		frozenCharacterCFrame = rootPart.CFrame
		rootPart.Anchored = true
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
	end

	if humanoid then
		humanoid:Move(Vector3.zero, false)
	end

	setControlsEnabled(false)

	-- Отключаем слушатели на переключение CurrentCamera на время Freecam.
	pcall(function()
		for _, conn in ipairs(getconnections(workspaceService:GetPropertyChangedSignal("CurrentCamera"))) do
			conn:Disable()
		end
	end)

	workspaceService.CurrentCamera = freecamCamera
	freecamActive = true

	contextActionService:BindActionAtPriority(
		"FreecamMovementSink",
		sinkMovementAction,
		false,
		Enum.ContextActionPriority.High.Value + 2000,
		Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Space
	)
end

---Disable freecam and restore original camera.
local function disableFreecam()
	if not freecamActive then return end
	freecamActive = false
	frozenCharacterCFrame = nil

	contextActionService:UnbindAction("FreecamMovementSink")
	setControlsEnabled(true)

	local character = localPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		rootPart.Anchored = savedAnchored
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
	end

	if originalCamera and originalCamera.Parent then
		workspaceService.CurrentCamera = originalCamera
		originalCamera.CameraType = savedCameraType or Enum.CameraType.Custom
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		originalCamera.CameraSubject = savedCameraSubject or humanoid
	end

	if freecamCamera then
		freecamCamera:Destroy()
		freecamCamera = nil
	end

	pcall(function()
		for _, conn in ipairs(getconnections(workspaceService:GetPropertyChangedSignal("CurrentCamera"))) do
			conn:Enable()
		end
	end)

	userInputService.MouseBehavior = Enum.MouseBehavior.Default
end

---Apply X-Ray transparency to a base part.
---@param inst Instance
local function applyInstanceXRay(inst)
	if not isBuildingInstance(inst) then return end

	if cachedPartTransparencies[inst] == nil then
		cachedPartTransparencies[inst] = inst.Transparency
	end

	inst.Transparency = MiscConfig.XRayTransparency
end

---Find structural root containers in workspace.
---@return table
local function findStructureRoots()
	local roots = {}

	for _, child in ipairs(workspaceService:GetChildren()) do
		local lower = child.Name:lower()
		if TARGET_CONTAINER_NAMES[lower] then
			table.insert(roots, child)
		end
	end

	return roots
end

---Enable or disable building X-Ray.
---@param state boolean
local function setXRayState(state)
	xrayActive = state

	if state then
		local roots = findStructureRoots()

		for _, root in ipairs(roots) do
			for _, desc in ipairs(root:GetDescendants()) do
				applyInstanceXRay(desc)
			end

			table.insert(xrayWatchConns, root.DescendantAdded:Connect(function(desc)
				if xrayActive then
					task.defer(applyInstanceXRay, desc)
				end
			end))
		end

		table.insert(xrayWatchConns, workspaceService.ChildAdded:Connect(function(child)
			if xrayActive and TARGET_CONTAINER_NAMES[child.Name:lower()] then
				for _, desc in ipairs(child:GetDescendants()) do
					applyInstanceXRay(desc)
				end

				table.insert(xrayWatchConns, child.DescendantAdded:Connect(function(desc)
					if xrayActive then
						task.defer(applyInstanceXRay, desc)
					end
				end))
			end
		end))
	else
		for _, conn in ipairs(xrayWatchConns) do
			conn:Disconnect()
		end
		table.clear(xrayWatchConns)

		for part, original in pairs(cachedPartTransparencies) do
			if part and part.Parent then
				part.Transparency = original
			end
		end
		table.clear(cachedPartTransparencies)
	end
end

function Misc:GetConfig()
	return MiscConfig
end

function Misc:Unload()
	MiscConfig.SpeedEnabled = false
	MiscConfig.FlyEnabled = false
	MiscConfig.FreecamEnabled = false
	MiscConfig.ZoomEnabled = false
	MiscConfig.XRayEnabled = false
	MiscConfig.InstantLoot = false
	MiscConfig.NoFall = false

	disableFreecam()
	setXRayState(false)

	local targetCam = freecamCamera or originalCamera or workspaceService.CurrentCamera
	if isZoomActive and savedCameraFov and targetCam then
		targetCam.FieldOfView = savedCameraFov
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

	-- Spoof CurrentCamera on Workspace and hide Virtual Camera from all game scripts.
	local oldIndex
	oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
		if not checkcaller() and freecamActive then
			if (self == workspaceService or (typeof(self) == "Instance" and self:IsA("Workspace"))) and (key == "CurrentCamera" or key == "currentCamera") then
				return originalCamera
			end
			if self == freecamCamera then
				return originalCamera
			end
			if key == "Anchored" then
				local char = localPlayer.Character
				if char and self == char:FindFirstChild("HumanoidRootPart") then
					return savedAnchored
				end
			end
		end
		return oldIndex(self, key)
	end))

	-- Intercept IsKeyDown method to block movement in custom controllers during freecam.
	local oldIsKeyDown
	oldIsKeyDown = hookfunction(userInputService.IsKeyDown, newcclosure(function(self, key)
		if not checkcaller() and freecamActive and BLOCKED_FREECAM_KEYS[key] then
			return false
		end
		return oldIsKeyDown(self, key)
	end))

	-- Namecall hooks to filter out freecamCamera and spoof queries.
	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		if checkcaller() then
			return oldNamecall(self, ...)
		end

		local method = getnamecallmethod()
		if freecamActive then
			if self == workspaceService then
				if method == "GetChildren" then
					local children = oldNamecall(self, ...)
					if freecamCamera then
						for i = #children, 1, -1 do
							if children[i] == freecamCamera then
								table.remove(children, i)
							end
						end
					end
					return children
				elseif method == "FindFirstChildOfClass" or method == "findFirstChildOfClass" then
					local className = ...
					if className == "Camera" then
						return originalCamera
					end
				end
			end
			if method == "IsKeyDown" then
				local key = ...
				if BLOCKED_FREECAM_KEYS[key] then
					return false
				end
			end
		end

		if method == "FireServer" and MiscConfig.NoFall then
			local remoteName = self.Name
			local firstArg = ...
			if firstArg == "TFD" or firstArg == "FallDamage" or firstArg == "Fall" or remoteName:find("Fall") then
				return
			end
		end

		return oldNamecall(self, ...)
	end))

	-- Camera Render Loop (Freecam & Zoom).
	renderSteppedConn = runService.RenderStepped:Connect(function(dt)
		local activeCam = (freecamActive and freecamCamera) or originalCamera or workspaceService.CurrentCamera

		-- Zoom Handler.
		if MiscConfig.ZoomEnabled and activeCam then
			if not isZoomActive then
				isZoomActive = true
				savedCameraFov = activeCam.FieldOfView
			end
			activeCam.FieldOfView = MiscConfig.ZoomFOV
		else
			if isZoomActive and activeCam then
				isZoomActive = false
				activeCam.FieldOfView = savedCameraFov or 70
				savedCameraFov = nil
			end
		end

		-- Virtual Freecam Controller.
		if MiscConfig.FreecamEnabled then
			if not freecamActive then
				enableFreecam()
			end

			if freecamCamera then
				local character = localPlayer.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid:Move(Vector3.zero, false)
				end

				if userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
					userInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
					local delta = userInputService:GetMouseDelta()
					freecamYaw = freecamYaw - math.rad(delta.X * 0.35)
					freecamPitch = math.clamp(freecamPitch - math.rad(delta.Y * 0.35), math.rad(-89), math.rad(89))
				else
					userInputService.MouseBehavior = Enum.MouseBehavior.Default
				end

				local camRot = CFrame.fromEulerAnglesYXZ(freecamPitch, freecamYaw, 0)
				local moveVector = Vector3.zero

				if userInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector - Vector3.zAxis end
				if userInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector + Vector3.zAxis end
				if userInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - Vector3.xAxis end
				if userInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + Vector3.xAxis end
				if userInputService:IsKeyDown(Enum.KeyCode.Space) or userInputService:IsKeyDown(Enum.KeyCode.E) then moveVector = moveVector + Vector3.yAxis end
				if userInputService:IsKeyDown(Enum.KeyCode.LeftControl) or userInputService:IsKeyDown(Enum.KeyCode.Q) then moveVector = moveVector - Vector3.yAxis end

				local speed = MiscConfig.FreecamSpeed
				if userInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
					speed = speed * MiscConfig.FreecamShiftBoost
				end

				if moveVector.Magnitude > 0 then
					local worldMove = (camRot * moveVector).Unit * (speed * dt)
					freecamPos = freecamPos + worldMove
				end

				freecamCamera.CFrame = CFrame.new(freecamPos) * camRot
			end
		else
			if freecamActive then
				disableFreecam()
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

		-- Freeze character in Freecam.
		if MiscConfig.FreecamEnabled and freecamActive then
			if frozenCharacterCFrame then
				rootPart.CFrame = frozenCharacterCFrame
				rootPart.AssemblyLinearVelocity = Vector3.zero
				rootPart.AssemblyAngularVelocity = Vector3.zero
			end
			return
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
				local cam = originalCamera or workspaceService.CurrentCamera
				local camCF = cam.CFrame
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
	setXRayState(enabled)
end

---Update X-Ray transparency value dynamically from slider.
---@param value number
function Misc:SetXRayTransparency(value)
	MiscConfig.XRayTransparency = value
	if xrayActive then
		for part in pairs(cachedPartTransparencies) do
			if part and part.Parent then
				part.Transparency = value
			end
		end
	end
end

return Misc
