local cloneref = cloneref or function(o) return o end

-- Services.
local playersService = cloneref(game:GetService("Players"))
local runService = cloneref(game:GetService("RunService"))
local userInputService = cloneref(game:GetService("UserInputService"))
local workspaceService = cloneref(game:GetService("Workspace"))
local replicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local contextActionService = cloneref(game:GetService("ContextActionService"))

local localPlayer = playersService.LocalPlayer
local currentCamera = workspaceService.CurrentCamera

local Misc = {}
Misc.__index = Misc

local FLY_PULSE_DURATION = 0.7
local flyStartTime = 0
local isPulsingGround = false

-- Freecam State.
local freecamActive = false
local freecamPos = Vector3.zero
local freecamPitch = 0
local freecamYaw = 0
local savedCameraType = nil
local savedCameraSubject = nil
local savedAnchored = false
local frozenCharacterCFrame = nil
local heartbeatConn = nil
local renderSteppedConn = nil

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

	InstantLoot = false,
	NoFall = false
}

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

---Enable freecam scriptable control and freeze character.
local function enableFreecam()
	currentCamera = workspaceService.CurrentCamera or currentCamera
	savedCameraType = currentCamera.CameraType
	savedCameraSubject = currentCamera.CameraSubject

	local camCFrame = currentCamera.CFrame
	freecamPos = camCFrame.Position

	local _, yaw, _ = camCFrame:ToOrientation()
	local pitch = math.asin(camCFrame.LookVector.Y)
	freecamYaw = yaw
	freecamPitch = pitch

	currentCamera.CameraType = Enum.CameraType.Scriptable
	freecamActive = true

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

	currentCamera = workspaceService.CurrentCamera or currentCamera
	currentCamera.CameraType = savedCameraType or Enum.CameraType.Custom

	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	currentCamera.CameraSubject = savedCameraSubject or humanoid

	userInputService.MouseBehavior = Enum.MouseBehavior.Default
end

function Misc:GetConfig()
	return MiscConfig
end

function Misc:Unload()
	MiscConfig.SpeedEnabled = false
	MiscConfig.FlyEnabled = false
	MiscConfig.FreecamEnabled = false
	MiscConfig.InstantLoot = false
	MiscConfig.NoFall = false

	disableFreecam()

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

	-- Spoof Anchored property read for HumanoidRootPart during freecam.
	local oldIndex
	oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
		if not checkcaller() and freecamActive and key == "Anchored" then
			local char = localPlayer.Character
			if char and self == char:FindFirstChild("HumanoidRootPart") then
				return savedAnchored
			end
		end
		return oldIndex(self, key)
	end))

	-- Intercept IsKeyDown method to block movement in custom controllers.
	local oldIsKeyDown
	oldIsKeyDown = hookfunction(userInputService.IsKeyDown, newcclosure(function(self, key)
		if not checkcaller() and freecamActive and BLOCKED_FREECAM_KEYS[key] then
			return false
		end
		return oldIsKeyDown(self, key)
	end))

	-- Remote / Metamethod hooks.
	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		if checkcaller() then
			return oldNamecall(self, ...)
		end

		local method = getnamecallmethod()
		if method == "FireServer" then
			local remoteName = self.Name
			local firstArg = ...
			if (remoteName == "RemoteEvent" or self:IsA("RemoteEvent")) and firstArg == "TFD" and MiscConfig.NoFall then
				return
			end
		elseif method == "IsKeyDown" and freecamActive then
			local key = ...
			if BLOCKED_FREECAM_KEYS[key] then
				return false
			end
		end

		return oldNamecall(self, ...)
	end))

	-- Freecam Render Loop.
	renderSteppedConn = runService.RenderStepped:Connect(function(dt)
		currentCamera = workspaceService.CurrentCamera or currentCamera

		if MiscConfig.FreecamEnabled then
			if not freecamActive then
				enableFreecam()
			end

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

			currentCamera.CFrame = CFrame.new(freecamPos) * camRot
		else
			if freecamActive then
				disableFreecam()
			end
		end
	end)

	-- Movement / Fly Loop.
	heartbeatConn = runService.Heartbeat:Connect(function(dt)
		local character = localPlayer.Character
		if not character then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not (humanoid and rootPart and humanoid.Health > 0) then return end

		currentCamera = workspaceService.CurrentCamera or currentCamera
		local stepDt = math.clamp(dt, 0.001, 0.033)

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

return Misc
