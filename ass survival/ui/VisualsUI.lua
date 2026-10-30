-- [made by `@codethan` on discord]
return function(Window, Flags)
    local VisualsTab = Window:Tab({ Name = "Visuals" })

    ---------------------------------------------------------
    -- 1. Combined ESP SubPage (Player, Bot, World)
    ---------------------------------------------------------
    local ESPSubPage = VisualsTab:SubPage({ Name = "ESP" })

    -- LEFT SECTION: Player ESP
    local PlayerSec = ESPSubPage:Section({ Name = "Player ESP", Side = "Left" })

    PlayerSec:Toggle({
        Name = "Enable Player ESP",
        Flag = "ESP_Player_Enabled",
        Callback = function(val) Flags.ESP_Player_Enabled = val end
    })

    PlayerSec:Toggle({
        Name = "Boxes",
        Flag = "ESP_Player_Boxes",
        Callback = function(val) Flags.ESP_Player_Boxes = val end
    }):ColorPicker({
        Default = Color3.fromRGB(255, 255, 255),
        Flag = "ESP_Player_BoxColor",
        Callback = function(col) Flags.ESP_Player_BoxColor = col end
    })

    PlayerSec:Dropdown({
        Name = "Box Type",
        List = { "2D Box", "Corner Box", "3D Box" },
        Default = "2D Box",
        Flag = "ESP_Player_BoxType",
        Callback = function(val) Flags.ESP_Player_BoxType = val end
    })

    PlayerSec:Toggle({
        Name = "Tracers",
        Flag = "ESP_Player_Tracers",
        Callback = function(val) Flags.ESP_Player_Tracers = val end
    }):ColorPicker({
        Default = Color3.fromRGB(255, 0, 0),
        Flag = "ESP_Player_TracerColor",
        Callback = function(col) Flags.ESP_Player_TracerColor = col end
    })

    PlayerSec:Toggle({
        Name = "Show Name",
        Flag = "ESP_Player_Name",
        Callback = function(val) Flags.ESP_Player_Name = val end
    }):ColorPicker({
        Default = Color3.fromRGB(255, 255, 255),
        Flag = "ESP_Player_NameColor",
        Callback = function(col) Flags.ESP_Player_NameColor = col end
    })

    PlayerSec:Toggle({
        Name = "Show Health",
        Flag = "ESP_Player_Health",
        Callback = function(val) Flags.ESP_Player_Health = val end
    })

    PlayerSec:Toggle({
        Name = "Show Distance",
        Flag = "ESP_Player_Distance",
        Callback = function(val) Flags.ESP_Player_Distance = val end
    })

    PlayerSec:Toggle({
        Name = "Show Weapon",
        Flag = "ESP_Player_Weapon",
        Callback = function(val) Flags.ESP_Player_Weapon = val end
    })

    PlayerSec:Slider({
        Name = "Max Distance",
        Min = 100,
        Max = 3000,
        Default = 1000,
        Unit = "m",
        Flag = "ESP_Player_MaxDist",
        Callback = function(val) Flags.ESP_Player_MaxDist = val end
    })

    -- RIGHT SECTION: Bot & World ESP
    local WorldBotSec = ESPSubPage:Section({ Name = "Bot & World ESP", Side = "Right" })

    -- Bots
    WorldBotSec:Toggle({
        Name = "Enable Bot ESP",
        Flag = "ESP_Bot_Enabled",
        Callback = function(val) Flags.ESP_Bot_Enabled = val end
    }):ColorPicker({
        Default = Color3.fromRGB(255, 150, 0),
        Flag = "ESP_Bot_Color",
        Callback = function(col) Flags.ESP_Bot_Color = col end
    })

    WorldBotSec:Toggle({
        Name = "Bot Health & Name",
        Flag = "ESP_Bot_Info",
        Callback = function(val) Flags.ESP_Bot_Info = val end
    })

    -- Ores
    WorldBotSec:Toggle({
        Name = "Enable Ore ESP",
        Flag = "ESP_Ore_Enabled",
        Callback = function(val) Flags.ESP_Ore_Enabled = val end
    }):ColorPicker({
        Default = Color3.fromRGB(0, 200, 255),
        Flag = "ESP_Ore_Color",
        Callback = function(col) Flags.ESP_Ore_Color = col end
    })

    WorldBotSec:Dropdown({
        Name = "Ore Filter",
        List = { "All", "Sulfur", "Metal", "Stone" },
        Default = "All",
        Flag = "ESP_Ore_Filter",
        Callback = function(val) Flags.ESP_Ore_Filter = val end
    })

    -- Pickups & Animals
    WorldBotSec:Toggle({
        Name = "Pickups ESP",
        Flag = "ESP_Pickups_Enabled",
        Callback = function(val) Flags.ESP_Pickups_Enabled = val end
    }):ColorPicker({
        Default = Color3.fromRGB(0, 255, 100),
        Flag = "ESP_Pickups_Color",
        Callback = function(col) Flags.ESP_Pickups_Color = col end
    })

    WorldBotSec:Toggle({
        Name = "Animals ESP",
        Flag = "ESP_Animals_Enabled",
        Callback = function(val) Flags.ESP_Animals_Enabled = val end
    }):ColorPicker({
        Default = Color3.fromRGB(200, 200, 0),
        Flag = "ESP_Animals_Color",
        Callback = function(col) Flags.ESP_Animals_Color = col end
    })

    WorldBotSec:Slider({
        Name = "World Max Distance",
        Min = 50,
        Max = 2000,
        Default = 500,
        Unit = "m",
        Flag = "ESP_World_MaxDist",
        Callback = function(val) Flags.ESP_World_MaxDist = val end
    })

    ---------------------------------------------------------
    -- 2. Viewmodel SubPage
    ---------------------------------------------------------
    local VMSubPage = VisualsTab:SubPage({ Name = "Viewmodel" })
    local VMPosSec = VMSubPage:Section({ Name = "Position & Rotation", Side = "Left" })
    local VMChamsSec = VMSubPage:Section({ Name = "Chams & Visuals", Side = "Right" })

    -- Offset X/Y/Z
    VMPosSec:Slider({ Name = "Offset X", Min = -5, Max = 5, Default = 0, Decimals = 2, Flag = "VM_OffsetX", Callback = function(v) if getgenv().CrezVM then getgenv().CrezVM.Config.OffsetX = v end end })
    VMPosSec:Slider({ Name = "Offset Y", Min = -5, Max = 5, Default = 0, Decimals = 2, Flag = "VM_OffsetY", Callback = function(v) if getgenv().CrezVM then getgenv().CrezVM.Config.OffsetY = v end end })
    VMPosSec:Slider({ Name = "Offset Z", Min = -5, Max = 5, Default = 0, Decimals = 2, Flag = "VM_OffsetZ", Callback = function(v) if getgenv().CrezVM then getgenv().CrezVM.Config.OffsetZ = v end end })

    -- Rotation X/Y/Z
    VMPosSec:Slider({ Name = "Rotation X", Min = -180, Max = 180, Default = 0, Flag = "VM_RotX", Callback = function(v) if getgenv().CrezVM then getgenv().CrezVM.Config.RotX = v end end })
    VMPosSec:Slider({ Name = "Rotation Y", Min = -180, Max = 180, Default = 0, Flag = "VM_RotY", Callback = function(v) if getgenv().CrezVM then getgenv().CrezVM.Config.RotY = v end end })
    VMPosSec:Slider({ Name = "Rotation Z", Min = -180, Max = 180, Default = 0, Flag = "VM_RotZ", Callback = function(v) if getgenv().CrezVM then getgenv().CrezVM.Config.RotZ = v end end })

    -- Chams
    VMChamsSec:Dropdown({ Name = "Gun Chams Mode", List = { "Off", "ForceField", "Neon", "Glass", "Wireframe" }, Default = "Off", Flag = "VM_GunMode", Callback = function(v) if getgenv().CrezVM then getgenv().CrezVM.Config.GunChamsMode = v end end })
    VMChamsSec:ColorPicker({ Name = "Gun Color", Default = Color3.fromRGB(255, 0, 0), Flag = "VM_GunColor", Callback = function(c) if getgenv().CrezVM then getgenv().CrezVM.Config.GunChamsColor = c end end })

    VMChamsSec:Dropdown({ Name = "Hand Chams Mode", List = { "Off", "ForceField", "Neon", "Glass", "Wireframe" }, Default = "Off", Flag = "VM_HandMode", Callback = function(v) if getgenv().CrezVM then getgenv().CrezVM.Config.HandChamsMode = v end end })
    VMChamsSec:ColorPicker({ Name = "Hand Color", Default = Color3.fromRGB(0, 255, 255), Flag = "VM_HandColor", Callback = function(c) if getgenv().CrezVM then getgenv().CrezVM.Config.HandChamsColor = c end end })

    VMChamsSec:Slider({ Name = "Fill Transparency", Min = 0, Max = 1, Default = 0.5, Decimals = 2, Flag = "VM_Trans", Callback = function(v) if getgenv().CrezVM then getgenv().CrezVM.Config.ChamsTransparency = v end end })

    ---------------------------------------------------------
    -- 3. World Lighting SubPage
    ---------------------------------------------------------
    local WorldSubPage = VisualsTab:SubPage({ Name = "World Visuals" })
    local LightSec = WorldSubPage:Section({ Name = "Lighting", Side = "Left" })
    local EnvSec = WorldSubPage:Section({ Name = "Environment", Side = "Right" })

    LightSec:Toggle({ Name = "Fullbright", Flag = "World_Fullbright", Callback = function(v) Flags.World_Fullbright = v end })
    LightSec:Toggle({ Name = "No Shadows", Flag = "World_NoShadows", Callback = function(v) Flags.World_NoShadows = v end })

    EnvSec:Slider({ Name = "Field of View", Min = 60, Max = 120, Default = 90, Flag = "World_FOV", Callback = function(v) workspace.CurrentCamera.FieldOfView = v end })
end
