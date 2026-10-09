local cloneref = cloneref or function(o) return o end

-- Services.
local playersService = cloneref(game:GetService("Players"))
local runService = cloneref(game:GetService("RunService"))
local userInputService = cloneref(game:GetService("UserInputService"))
local workspaceService = cloneref(game:GetService("Workspace"))

local localPlayer = playersService.LocalPlayer
local currentCamera = workspaceService.CurrentCamera

local Misc = {}
Misc.__index = Misc

local FLY_PULSE_DURATION = 0.7
local flyStartTime = 0
local isPulsingGround = false

local MiscConfig = {
	SpeedEnabled = false,
	SpeedValue = 28,

	FlyEnabled = false,
	FlyMethod = "CFrame",
	FlySpeed = 45,
	FlyTimerEnabled = true,
	FlyTimerDuration = 3,
	FlyTimerMode = "Pulse Ground"
}

function Misc:GetConfig()
	return MiscConfig
end

function Misc:Unload()
	MiscConfig.SpeedEnabled = false
	MiscConfig.FlyEnabled = false
end

function Misc:Load()
	runService.Heartbeat:Connect(function(dt)
		local character = localPlayer.Character
		if not character then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not (humanoid and rootPart and humanoid.Health > 0) then return end

		currentCamera = workspaceService.CurrentCamera or currentCamera
		local stepDt = math.clamp(dt, 0.001, 0.033)

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
