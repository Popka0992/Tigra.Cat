local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer

local HitSounds = {
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

local ShootSounds = {
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

local function SortedKeys(Source)
    local Result = {}

    for Key in pairs(Source) do
        table.insert(Result, Key)
    end

    table.sort(Result)

    return Result
end

return function(MiscPage)
    local Config = {
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

    local Connections = {}
    local ToolConnections = {}
    local SavedCollisions = {}

    local SavedWalkSpeed
    local SavedHumanoid

    local FlyAttachment
    local FlyVelocity
    local FlyOrientation

    local Destroyed = false

    local function Connect(Signal, Callback)
        local Connection = Signal:Connect(Callback)
        table.insert(Connections, Connection)
        return Connection
    end

    local function PlaySound(SoundId)
        if Destroyed or not SoundId then
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
        local Root = Character
            and Character:FindFirstChild("HumanoidRootPart")

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

    local function RestoreCollisions()
        for Part, Original in pairs(SavedCollisions) do
            if Part and Part.Parent then
                Part.CanCollide = Original
            end
        end

        table.clear(SavedCollisions)
    end

    local function RestoreSpeed()
        if SavedHumanoid and SavedHumanoid.Parent
            and SavedWalkSpeed ~= nil then
            SavedHumanoid.WalkSpeed = SavedWalkSpeed
        end

        SavedHumanoid = nil
        SavedWalkSpeed = nil
    end

    local MovementSub = MiscPage:SubPage({
        Name = "Movement",
    })

    local MovementSection = MovementSub:Section({
        Name = "Movement",
        Side = 1,
    })

    local FlyToggle = MovementSection:Toggle({
        Name = "Fly",
        Flag = "MiscFly",
        Default = false,
        Meta = true,
        Callback = function(State)
            Config.Fly = State

            if State then
                StartFly()
            else
                StopFly()
            end
        end,
    })

    local FlyChild = FlyToggle:Child({
        Name = "Fly options",
    })

    FlyChild:Slider({
        Name = "Fly speed",
        Flag = "MiscFlySpeed",
        Min = 10,
        Max = 200,
        Default = 60,
        Decimals = 1,
        Callback = function(Value)
            Config.FlySpeed = Value
        end,
    })

    local SpeedToggle = MovementSection:Toggle({
        Name = "Speed",
        Flag = "MiscSpeed",
        Default = false,
        Meta = true,
        Callback = function(State)
            Config.Speed = State

            if not State then
                RestoreSpeed()
            end
        end,
    })

    local SpeedChild = SpeedToggle:Child({
        Name = "Speed options",
    })

    SpeedChild:Slider({
        Name = "Walk speed",
        Flag = "MiscWalkSpeed",
        Min = 16,
        Max = 200,
        Default = 32,
        Decimals = 1,
        Callback = function(Value)
            Config.WalkSpeed = Value
        end,
    })

    MovementSection:Toggle({
        Name = "Noclip",
        Flag = "MiscNoclip",
        Default = false,
        Callback = function(State)
            Config.Noclip = State

            if not State then
                RestoreCollisions()
            end
        end,
    })

    local SoundsSub = MiscPage:SubPage({
        Name = "Sounds",
    })

    local GunSoundSection = SoundsSub:Section({
        Name = "Gun sound",
        Side = 1,
    })

    local HitSoundSection = SoundsSub:Section({
        Name = "Hit sound",
        Side = 2,
    })

    GunSoundSection:Toggle({
        Name = "Gun sound",
        Flag = "MiscGunSound",
        Default = false,
        Callback = function(State)
            Config.GunSound = State
        end,
    })

    GunSoundSection:Dropdown({
        Name = "Sound",
        Flag = "MiscGunSoundType",
        Items = SortedKeys(ShootSounds),
        Default = "AWP",
        Callback = function(Value)
            Config.GunSoundName = Value
        end,
    })

    GunSoundSection:Button({
        Name = "Test gun sound",
        Callback = function()
            PlaySound(ShootSounds[Config.GunSoundName])
        end,
    })

    HitSoundSection:Toggle({
        Name = "Hit sound",
        Flag = "MiscHitSound",
        Default = false,
        Callback = function(State)
            Config.HitSound = State
        end,
    })

    HitSoundSection:Dropdown({
        Name = "Sound",
        Flag = "MiscHitSoundType",
        Items = SortedKeys(HitSounds),
        Default = "neverlose",
        Callback = function(Value)
            Config.HitSoundName = Value
        end,
    })

    HitSoundSection:Button({
        Name = "Test hit sound",
        Callback = function()
            PlaySound(HitSounds[Config.HitSoundName])
        end,
    })

    HitSoundSection:Slider({
        Name = "Volume",
        Flag = "MiscSoundVolume",
        Min = 0,
        Max = 100,
        Default = 100,
        Decimals = 1,
        Suffix = "%",
        Callback = function(Value)
            Config.SoundVolume = Value / 100
        end,
    })

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

    local function BindTool(Tool)
        if not Tool:IsA("Tool") or ToolConnections[Tool] then
            return
        end

        local ActivatedConnection = Tool.Activated:Connect(function()
            if Config.GunSound then
                PlaySound(ShootSounds[Config.GunSoundName])
            end
        end)

        local DestroyingConnection

        DestroyingConnection = Tool.Destroying:Connect(function()
            ActivatedConnection:Disconnect()
            DestroyingConnection:Disconnect()
            ToolConnections[Tool] = nil
        end)

        ToolConnections[Tool] = {
            ActivatedConnection,
            DestroyingConnection,
        }
    end

    local function BindToolContainer(Container)
        for _, Child in ipairs(Container:GetChildren()) do
            BindTool(Child)
        end

        Connect(Container.ChildAdded, BindTool)
    end

    local Backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        or LocalPlayer:WaitForChild("Backpack")

    BindToolContainer(Backpack)

    if LocalPlayer.Character then
        BindToolContainer(LocalPlayer.Character)
    end

    Connect(LocalPlayer.CharacterAdded, function(Character)
        StopFly()
        table.clear(SavedCollisions)
        RestoreSpeed()

        BindToolContainer(Character)

        if Config.Fly then
            task.spawn(function()
                Character:WaitForChild("HumanoidRootPart", 10)

                if not Destroyed
                    and Config.Fly
                    and LocalPlayer.Character == Character then
                    StartFly()
                end
            end)
        end
    end)

    local Misc = {
        Config = Config,
    }

    function Misc:PlayHitSound()
        if Config.HitSound then
            PlaySound(HitSounds[Config.HitSoundName])
        end
    end

    function Misc:PlayGunSound()
        if Config.GunSound then
            PlaySound(ShootSounds[Config.GunSoundName])
        end
    end

    function Misc:Destroy()
        if Destroyed then
            return
        end

        Destroyed = true
        Config.Fly = false
        Config.Speed = false
        Config.Noclip = false

        StopFly()
        RestoreCollisions()
        RestoreSpeed()

        for _, Connection in ipairs(Connections) do
            Connection:Disconnect()
        end

        for _, ToolConnectionList in pairs(ToolConnections) do
            for _, Connection in ipairs(ToolConnectionList) do
                Connection:Disconnect()
            end
        end

        table.clear(Connections)
        table.clear(ToolConnections)
    end

    return Misc
end
