local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Voxel = ReplicatedStorage:WaitForChild("Voxel")

local HitPredict = require(Voxel:WaitForChild("HitPredict"))
local VoxelSound = require(Voxel:WaitForChild("VoxelSound"))

local Misc = {}

Misc.Config = {
    Fly = false,
    FlySpeed = 60,

    Speed = false,
    WalkSpeed = 32,

    Noclip = false,

    GunSound = false,
    GunSoundName = "AWP",

    HitSound = false,
    HitSoundName = "neverlose",

    SoundVolume = 1,
}

Misc.HitSounds = {
    ["neverlose"] = "rbxassetid://6607204501",
    ["rust"] = "rbxassetid://4764109000",
    ["gamesense"] = "rbxassetid://4817809188",
    ["fatality"] = "rbxassetid://94204395881101",
    ["csgo kill"] = "rbxassetid://7269900245",
    ["csgo headshot"] = "rbxassetid://6937353691",
    ["minecraft bow"] = "rbxassetid://1053296915",
    ["fortnite headshot"] = "rbxassetid://2513174484",
    ["arsenal headshot"] = "rbxassetid://8522515167",
    ["Bubble"] = "rbxassetid://198598793",
}

Misc.ShootSounds = {
    ["Scar20"] = "rbxassetid://91510933153450",
    ["SSg08"] = "rbxassetid://2476571739",
    ["AWP"] = "rbxassetid://2753888131",
    ["AK47-CS:GO"] = "rbxassetid://2476570846",
    ["G3SG1"] = "rbxassetid://18512294165",
    ["Deagle"] = "rbxassetid://82286818216627",
    ["USP-S"] = "rbxassetid://4108910200",
    ["USP"] = "rbxassetid://2515499360",
    ["HK416"] = "rbxassetid://8241511326",
    ["M4A1"] = "rbxassetid://9057685835",
    ["SKS"] = "rbxassetid://8660502251",
    ["SKS-Silenced"] = "rbxassetid://8660503874",
    ["FiveSeven"] = "rbxassetid://9057668558",
    ["AK47-Tarkov"] = "rbxassetid://122655160661494",
    ["AK47-Rust"] = "rbxassetid://7011577038",
    ["Arrow"] = "rbxassetid://76555891505373",
}

local Config = Misc.Config

local Connections = {}
local SavedCollisions = {}

local SavedHumanoid
local SavedWalkSpeed

local FlyAttachment
local FlyVelocity
local FlyOrientation

local Loaded = false
local Active = false

local function Connect(Signal, Callback)
    local Connection = Signal:Connect(Callback)
    table.insert(Connections, Connection)
    return Connection
end

local function PlaySound(SoundId)
    if not Active or not SoundId then
        return
    end

    local Sound = Instance.new("Sound")
    Sound.SoundId = SoundId
    Sound.Volume = Config.SoundVolume
    Sound.Parent = SoundService

    Sound.Ended:Connect(function()
        Sound:Destroy()
    end)

    Sound:Play()

    task.delay(10, function()
        if Sound.Parent then
            Sound:Destroy()
        end
    end)
end

function Misc:PlayGunSound()
    if Config.GunSound then
        PlaySound(self.ShootSounds[Config.GunSoundName])
    end
end

function Misc:PlayHitSound()
    if Config.HitSound then
        PlaySound(self.HitSounds[Config.HitSoundName])
    end
end

function Misc:TestGunSound()
    PlaySound(self.ShootSounds[Config.GunSoundName])
end

function Misc:TestHitSound()
    PlaySound(self.HitSounds[Config.HitSoundName])
end

local function StopFly()
    if FlyVelocity then
        FlyVelocity:Destroy()
        FlyVelocity = nil
    end

    if FlyOrientation then
        FlyOrientation:Destroy()
        FlyOrientation = nil
    end

    if FlyAttachment then
        FlyAttachment:Destroy()
        FlyAttachment = nil
    end
end

local function StartFly()
    StopFly()

    local Character = LocalPlayer.Character
    local Root = Character and Character:FindFirstChild("HumanoidRootPart")

    if not Root then
        return
    end

    FlyAttachment = Instance.new("Attachment")
    FlyAttachment.Name = "MiscFlyAttachment"
    FlyAttachment.Parent = Root

    FlyVelocity = Instance.new("LinearVelocity")
    FlyVelocity.Name = "MiscFlyVelocity"
    FlyVelocity.Attachment0 = FlyAttachment
    FlyVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    FlyVelocity.MaxForce = math.huge
    FlyVelocity.VectorVelocity = Vector3.zero
    FlyVelocity.Parent = Root

    FlyOrientation = Instance.new("AlignOrientation")
    FlyOrientation.Name = "MiscFlyOrientation"
    FlyOrientation.Attachment0 = FlyAttachment
    FlyOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    FlyOrientation.MaxTorque = math.huge
    FlyOrientation.Responsiveness = 20
    FlyOrientation.Parent = Root
end

function Misc:SetFly(State)
    Config.Fly = State

    if State then
        StartFly()
    else
        StopFly()
    end
end

local function RestoreSpeed()
    if SavedHumanoid and SavedHumanoid.Parent and SavedWalkSpeed ~= nil then
        SavedHumanoid.WalkSpeed = SavedWalkSpeed
    end

    SavedHumanoid = nil
    SavedWalkSpeed = nil
end

function Misc:SetSpeed(State)
    Config.Speed = State

    if not State then
        RestoreSpeed()
    end
end

local function RestoreCollisions()
    for Part, Original in pairs(SavedCollisions) do
        if Part and Part.Parent then
            Part.CanCollide = Original
        end
    end

    table.clear(SavedCollisions)
end

function Misc:SetNoclip(State)
    Config.Noclip = State

    if not State then
        RestoreCollisions()
    end
end

-- Хуки остаются установленными после Destroy, но становятся неактивными.
-- Load повторно хуки не устанавливает.
local function HookShot(Name)
    local OriginalFunction = VoxelSound[Name]

    if type(OriginalFunction) ~= "function" then
        warn("[Misc] VoxelSound." .. Name .. " отсутствует")
        return
    end

    if type(hookfunction) ~= "function"
        or type(newcclosure) ~= "function" then
        warn("[Misc] hookfunction/newcclosure недоступны")
        return
    end

    local Original

    local Success, Err = pcall(function()
        Original = hookfunction(
            OriginalFunction,
            newcclosure(function(...)
                if Active and Config.GunSound then
                    PlaySound(Misc.ShootSounds[Config.GunSoundName])
                end

                return Original(...)
            end)
        )
    end)

    if not Success then
        warn("[Misc] Не удалось подключить " .. Name .. ": " .. tostring(Err))
    end
end

function Misc:Load()
    if Active then
        return
    end

    Active = true

    if not Loaded then
        Loaded = true

        HookShot("ownShot")
        HookShot("ownShotgun")
        HookShot("minigunOwn")
    end

    Connect(HitPredict.confirmed, function()
        if Config.HitSound then
            PlaySound(Misc.HitSounds[Config.HitSoundName])
        end
    end)

    Connect(RunService.Stepped, function()
        local Character = LocalPlayer.Character

        if not Character then
            return
        end

        if Config.Noclip then
            for _, Part in ipairs(Character:GetDescendants()) do
                if Part:IsA("BasePart") then
                    if SavedCollisions[Part] == nil then
                        SavedCollisions[Part] = Part.CanCollide
                    end

                    Part.CanCollide = false
                end
            end
        end

        if Config.Speed then
            local Humanoid = Character:FindFirstChildOfClass("Humanoid")

            if Humanoid then
                if SavedHumanoid ~= Humanoid then
                    RestoreSpeed()
                    SavedHumanoid = Humanoid
                    SavedWalkSpeed = Humanoid.WalkSpeed
                end

                Humanoid.WalkSpeed = Config.WalkSpeed
            end
        end
    end)

    Connect(RunService.RenderStepped, function()
        if not Config.Fly or not FlyVelocity or not FlyOrientation then
            return
        end

        local Camera = workspace.CurrentCamera

        if not Camera then
            return
        end

        local Direction = Vector3.zero

        if not UserInputService:GetFocusedTextBox() then
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                Direction += Camera.CFrame.LookVector
            end

            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                Direction -= Camera.CFrame.LookVector
            end

            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                Direction += Camera.CFrame.RightVector
            end

            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                Direction -= Camera.CFrame.RightVector
            end

            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                Direction += Vector3.yAxis
            end

            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                Direction -= Vector3.yAxis
            end
        end

        if Direction.Magnitude > 0 then
            Direction = Direction.Unit
        end

        FlyVelocity.VectorVelocity = Direction * Config.FlySpeed

        local Look = Camera.CFrame.LookVector
        local Horizontal = Vector3.new(Look.X, 0, Look.Z)

        if Horizontal.Magnitude > 0.001 then
            FlyOrientation.CFrame = CFrame.lookAt(
                Vector3.zero,
                Horizontal.Unit
            )
        end
    end)

    Connect(LocalPlayer.CharacterAdded, function(Character)
        StopFly()
        RestoreCollisions()
        RestoreSpeed()

        if Config.Fly then
            task.spawn(function()
                Character:WaitForChild("HumanoidRootPart", 10)

                if Active
                    and Config.Fly
                    and LocalPlayer.Character == Character then
                    StartFly()
                end
            end)
        end
    end)

    if Config.Fly then
        StartFly()
    end
end

function Misc:Destroy()
    if not Active then
        return
    end

    Active = false

    Config.Fly = false
    Config.Speed = false
    Config.Noclip = false

    StopFly()
    RestoreSpeed()
    RestoreCollisions()

    for _, Connection in ipairs(Connections) do
        Connection:Disconnect()
    end

    table.clear(Connections)
end

return Misc
