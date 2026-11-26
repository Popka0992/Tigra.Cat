local cloneref = cloneref or function(Object)
    return Object
end

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local Workspace = cloneref(game:GetService("Workspace"))

local LocalPlayer = Players.LocalPlayer

local Desync = {}
Desync.__index = Desync

local Config = {
    Enabled = false,
    PosSpoof = true,
    RotSpoof = true,
    Visualize = false,

    OffsetX = 0,
    OffsetY = -2.4,
    OffsetZ = 0,

    RotX = 90,
    RotY = 0,
    RotZ = 0,

    RandomPosition = false,
    RandomPositionRange = 3,
    RandomRotation = false,

    AnimID = "616119360",
    AnimPlaying = false,
    AnimFreeze = false,
    AnimFreezeTime = 0,

    VelocityDesync = false,
    VelocityType = "low",
    VelocityRotate = false,
    VelocityHealthCheck = false,
    VelocityHealthValue = 100,

    OrbitEnabled = false,
    OrbitAutoShoot = false,
    OrbitRadius = 8,
    OrbitHeight = 0,
    OrbitSpeed = 2,
}

local Connections = {}
local Loaded = false

local CurrentAnimTrack
local DummyClone

local RealCFrame
local RealVelocity
local SpoofedRoot
local LastSpoofedCFrame

local TargetPlayer
local OrbitAngle = 0
local ActivatedTool

local RandomGenerator = Random.new()

local function Connect(Signal, Callback)
    local Connection = Signal:Connect(Callback)
    table.insert(Connections, Connection)
    return Connection
end

function Desync:GetConfig()
    return Config
end

function Desync:SetTarget(Player)
    if Player ~= nil and (not Player:IsA("Player") or Player == LocalPlayer) then
        return
    end

    TargetPlayer = Player
end

function Desync:GetTarget()
    return TargetPlayer
end

function Desync:ClearDummy()
    if DummyClone then
        DummyClone:Destroy()
        DummyClone = nil
    end
end

function Desync:SetupDummy()
    self:ClearDummy()

    local Character = LocalPlayer.Character

    if not Character then
        return
    end

    local OriginalArchivable = Character.Archivable
    Character.Archivable = true

    local Success, Clone = pcall(function()
        return Character:Clone()
    end)

    Character.Archivable = OriginalArchivable

    if not Success or not Clone then
        return
    end

    DummyClone = Clone
    DummyClone.Name = "DesyncCharVis"

    local Humanoid = DummyClone:FindFirstChildOfClass("Humanoid")

    if Humanoid then
        Humanoid.PlatformStand = true
        Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

        for _, State in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
            pcall(function()
                Humanoid:SetStateEnabled(State, false)
            end)
        end
    end

    for _, Object in ipairs(DummyClone:GetDescendants()) do
        if Object:IsA("Script") or Object:IsA("LocalScript") then
            Object:Destroy()
        elseif Object:IsA("BasePart") then
            Object.CanCollide = false
            Object.CanTouch = false
            Object.CanQuery = false
            Object.Massless = true
            Object.Material = Enum.Material.ForceField
            Object.Color = Color3.fromRGB(150, 0, 255)
            Object.Transparency = Object.Name == "HumanoidRootPart" and 1 or 0.2
        elseif Object:IsA("Decal") or Object:IsA("Texture") then
            Object:Destroy()
        end
    end

    local Root = DummyClone:FindFirstChild("HumanoidRootPart")

    if Root then
        Root.Anchored = true
    end

    DummyClone.Parent = Workspace.CurrentCamera or Workspace
end

local function UpdateDummyPose(SpoofedCFrame)
    local Character = LocalPlayer.Character

    if not DummyClone or not Character then
        return
    end

    local DummyRoot = DummyClone:FindFirstChild("HumanoidRootPart")
    local CharacterRoot = Character:FindFirstChild("HumanoidRootPart")

    if DummyRoot then
        DummyRoot.CFrame = SpoofedCFrame
            or (CharacterRoot and CharacterRoot.CFrame)
            or DummyRoot.CFrame
    end

    for _, Motor in ipairs(Character:GetDescendants()) do
        if Motor:IsA("Motor6D") then
            local DummyMotor = DummyClone:FindFirstChild(Motor.Name, true)

            if DummyMotor and DummyMotor:IsA("Motor6D") then
                DummyMotor.Transform = Motor.Transform
            end
        end
    end
end

function Desync:HandleAnimation(State)
    if CurrentAnimTrack then
        CurrentAnimTrack:Stop()
        CurrentAnimTrack:Destroy()
        CurrentAnimTrack = nil
    end

    if not State then
        return
    end

    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local Animator = Humanoid and Humanoid:FindFirstChildOfClass("Animator")

    if not Animator then
        return
    end

    local Id = string.match(tostring(Config.AnimID), "%d+")

    if not Id then
        return
    end

    local Animation = Instance.new("Animation")
    Animation.AnimationId = "rbxassetid://" .. Id

    local Success, Track = pcall(function()
        return Animator:LoadAnimation(Animation)
    end)

    Animation:Destroy()

    if not Success or not Track then
        return
    end

    CurrentAnimTrack = Track
    Track.Priority = Enum.AnimationPriority.Action4
    Track.Looped = true
    Track:Play()

    if Config.AnimFreeze then
        Track:AdjustSpeed(0)

        task.delay(0.05, function()
            if CurrentAnimTrack == Track then
                Track.TimePosition = Config.AnimFreezeTime
            end
        end)
    end
end

local function StopOrbitTool()
    if ActivatedTool then
        pcall(function()
            ActivatedTool:Deactivate()
        end)

        ActivatedTool = nil
    end
end

function Desync:SetOrbitEnabled(State)
    Config.OrbitEnabled = State

    if not State then
        StopOrbitTool()
    end
end

function Desync:SetOrbitAutoShoot(State)
    Config.OrbitAutoShoot = State

    if not State then
        StopOrbitTool()
    end
end

local function GetAliveRoot(Player)
    if not Player or Player.Parent ~= Players then
        return nil, nil
    end

    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local Root = Character and Character:FindFirstChild("HumanoidRootPart")

    if not Humanoid or Humanoid.Health <= 0 or not Root then
        return nil, nil
    end

    return Root, Character
end

local function UpdateOrbit(DeltaTime)
    if not Config.OrbitEnabled then
        StopOrbitTool()
        return
    end

    local TargetRoot = GetAliveRoot(TargetPlayer)
    local LocalRoot, Character = GetAliveRoot(LocalPlayer)

    if not TargetRoot or not LocalRoot then
        StopOrbitTool()
        return
    end

    OrbitAngle = (OrbitAngle + DeltaTime * Config.OrbitSpeed) % (math.pi * 2)

    local Center = TargetRoot.Position
    local Position = Center + Vector3.new(
        math.cos(OrbitAngle) * Config.OrbitRadius,
        Config.OrbitHeight,
        math.sin(OrbitAngle) * Config.OrbitRadius
    )

    local LookAt = Vector3.new(Center.X, Position.Y, Center.Z)

    if (LookAt - Position).Magnitude > 0.001 then
        LocalRoot.CFrame = CFrame.lookAt(Position, LookAt)
    end

    if not Config.OrbitAutoShoot then
        StopOrbitTool()
        return
    end

    local Tool = Character:FindFirstChildOfClass("Tool")

    if Tool ~= ActivatedTool then
        StopOrbitTool()

        if Tool then
            ActivatedTool = Tool

            pcall(function()
                Tool:Activate()
            end)
        end
    end
end

local function RandomOffset()
    local Range = math.max(0, tonumber(Config.RandomPositionRange) or 0)

    return Vector3.new(
        RandomGenerator:NextNumber(-Range, Range),
        RandomGenerator:NextNumber(-Range, Range),
        RandomGenerator:NextNumber(-Range, Range)
    )
end

local function RandomRotation()
    return CFrame.Angles(
        math.rad(RandomGenerator:NextNumber(-180, 180)),
        math.rad(RandomGenerator:NextNumber(-180, 180)),
        math.rad(RandomGenerator:NextNumber(-180, 180))
    )
end

local function GetSpoofVelocity()
    if Config.VelocityType == "high y" then
        return Vector3.new(0, 16384, 0)
    end

    if Config.VelocityType == "limit" then
        return Vector3.new(
            RandomGenerator:NextNumber(-2147483648, 2147483647),
            RandomGenerator:NextNumber(-2147483648, 2147483647),
            RandomGenerator:NextNumber(-2147483648, 2147483647)
        )
    end

    local Magnitude = Config.VelocityType == "high" and 16384 or 300

    local function Signed()
        return RandomGenerator:NextInteger(0, 1) == 0
            and -Magnitude
            or Magnitude
    end

    return Vector3.new(Signed(), Signed(), Signed())
end

local function RestoreSpoof()
    if SpoofedRoot and SpoofedRoot.Parent and RealCFrame then
        SpoofedRoot.CFrame = RealCFrame

        if RealVelocity then
            SpoofedRoot.AssemblyLinearVelocity = RealVelocity
        end
    end

    SpoofedRoot = nil
    RealCFrame = nil
    RealVelocity = nil
end

function Desync:Load()
    if Loaded then
        return
    end

    Loaded = true

    Connect(LocalPlayer.CharacterAdded, function(Character)
        RestoreSpoof()
        StopOrbitTool()
        self:ClearDummy()
        self:HandleAnimation(false)

        task.spawn(function()
            Character:WaitForChild("Humanoid", 10)

            if not Loaded or LocalPlayer.Character ~= Character then
                return
            end

            if Config.Visualize then
                self:SetupDummy()
            end

            if Config.AnimPlaying then
                self:HandleAnimation(true)
            end
        end)
    end)

    Connect(Players.PlayerRemoving, function(Player)
        if TargetPlayer == Player then
            TargetPlayer = nil
            StopOrbitTool()
        end
    end)

    Connect(RunService.Heartbeat, function(DeltaTime)
        -- Восстановление на случай пропущенного render step.
        RestoreSpoof()

        UpdateOrbit(DeltaTime)

        local Character = LocalPlayer.Character
        local Root = Character and Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

        if Config.AnimPlaying and CurrentAnimTrack and Humanoid then
            local Animator = Humanoid:FindFirstChildOfClass("Animator")

            if Animator then
                for _, Track in ipairs(Animator:GetPlayingAnimationTracks()) do
                    if Track ~= CurrentAnimTrack then
                        Track:Stop()
                    end
                end
            end

            if Config.AnimFreeze then
                CurrentAnimTrack.TimePosition = Config.AnimFreezeTime
            end
        end

        if not Root or not Humanoid or Humanoid.Health <= 0 then
            LastSpoofedCFrame = nil
            return
        end

        local ShouldSpoofVelocity = Config.VelocityDesync

        if ShouldSpoofVelocity and Config.VelocityHealthCheck then
            local Fraction = Humanoid.MaxHealth > 0
                and Humanoid.Health / Humanoid.MaxHealth
                or 0

            if Fraction >= Config.VelocityHealthValue / 100 then
                ShouldSpoofVelocity = false
            end
        end

        local ShouldSpoofCFrame = Config.Enabled
            and (Config.PosSpoof or Config.RotSpoof)

        if ShouldSpoofCFrame or ShouldSpoofVelocity then
            SpoofedRoot = Root
            RealCFrame = Root.CFrame
            RealVelocity = Root.AssemblyLinearVelocity
        end

        if ShouldSpoofCFrame then
            local FinalCFrame = RealCFrame

            if Config.PosSpoof then
                local Offset = Config.RandomPosition
                    and RandomOffset()
                    or Vector3.new(Config.OffsetX, Config.OffsetY, Config.OffsetZ)

                FinalCFrame = FinalCFrame + Offset
            end

            if Config.RotSpoof then
                local Rotation = Config.RandomRotation
                    and RandomRotation()
                    or CFrame.Angles(
                        math.rad(Config.RotX),
                        math.rad(Config.RotY),
                        math.rad(Config.RotZ)
                    )

                FinalCFrame = FinalCFrame * Rotation
            end

            Root.CFrame = FinalCFrame
            LastSpoofedCFrame = FinalCFrame
        else
            LastSpoofedCFrame = nil
        end

        if ShouldSpoofVelocity then
            local Velocity = GetSpoofVelocity()
            local OldAngular = Root.AssemblyAngularVelocity

            Root.AssemblyLinearVelocity = Velocity

            if Config.VelocityRotate then
                Root.AssemblyAngularVelocity = Velocity

                task.spawn(function()
                    RunService.RenderStepped:Wait()

                    if Root.Parent then
                        Root.AssemblyAngularVelocity = OldAngular
                    end
                end)
            end
        end
    end)

    RunService:BindToRenderStep(
        "LigraDesyncCam",
        Enum.RenderPriority.Camera.Value - 1,
        function()
            if Config.Visualize then
                UpdateDummyPose(Config.Enabled and LastSpoofedCFrame or nil)
            end

            RestoreSpoof()
        end
    )
end

function Desync:Destroy()
    if not Loaded then
        return
    end

    Loaded = false
    Config.Enabled = false
    Config.VelocityDesync = false
    Config.OrbitEnabled = false
    Config.AnimPlaying = false

    StopOrbitTool()
    RestoreSpoof()
    self:HandleAnimation(false)
    self:ClearDummy()

    RunService:UnbindFromRenderStep("LigraDesyncCam")

    for _, Connection in ipairs(Connections) do
        Connection:Disconnect()
    end

    table.clear(Connections)
end

return Desync
