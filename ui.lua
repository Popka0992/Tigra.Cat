-- made by samet september 14 2025 - dev
-- example at bottom

local LoadingTick = os.clock()

if getgenv().Library then
    getgenv().Library:Unload()
end

local Library do 
    local Workspace = game:GetService("Workspace")
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")
    local CoreGui = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")
    --local Lighting = game:GetService("Lighting")

    gethui = gethui or function()
        return CoreGui
    end

    local LocalPlayer = Players.LocalPlayer
    --local Camera = Workspace.CurrentCamera
    local Mouse = LocalPlayer:GetMouse()

    local FromRGB = Color3.fromRGB
    local FromHSV = Color3.fromHSV
    local FromHex = Color3.fromHex

    local RGBSequence = ColorSequence.new
    local RGBSequenceKeypoint = ColorSequenceKeypoint.new
    local NumSequence = NumberSequence.new
    local NumSequenceKeypoint = NumberSequenceKeypoint.new

    local UDim2New = UDim2.new
    local UDimNew = UDim.new
    local UDim2FromOffset = UDim2.fromOffset
    local Vector2New = Vector2.new
    --local Vector3New = Vector3.new

    local MathClamp = math.clamp
    local MathFloor = math.floor
    --local MathAbs = math.abs
    --local MathSin = math.sin

    local TableInsert = table.insert
    local TableFind = table.find
    local TableRemove = table.remove
    local TableConcat = table.concat
    local TableClone = table.clone
    local TableUnpack = table.unpack

    local StringFormat = string.format
    local StringFind = string.find
    local StringGSub = string.gsub
    local StringLower = string.lower
    local StringLen = string.len

    local InstanceNew = Instance.new

    --local RectNew = Rect.new

    Library = {
        Theme =  { },

        MenuKeybind = tostring(Enum.KeyCode.RightControl), 

        Flags = { },

        Tween = {
            Time = 0.3,
            Style = Enum.EasingStyle.Quart,
            Direction = Enum.EasingDirection.Out
        },

        FadeSpeed = 0.4,

        Folders = {
            Directory = "Tigra.cat",
            Configs = "Tigra.cat/Configs",
            Assets = "Tigra.cat/Images",
            Fonts = "Tigra.cat/Fonts"
        },

        Images = {
            ["Sat"] = {"Sat.png", "https://github.com/sametexe001/images/blob/main/saturation.png?raw=true" },
            ["Val"] = { "Val.png", "https://github.com/sametexe001/images/blob/main/value.png?raw=true" },
            ["Hue"] = { "Hue.png", "https://github.com/sametexe001/images/blob/main/horizontalhue.png?raw=true" },
            ["Alpha"] = { "Alpha.png", "https://github.com/sametexe001/images/blob/main/checkers.png?raw=true" },
        },

        -- Ignore below
        Pages = { },
        Sections = { },

        Connections = { },
        Threads = { },

        ThemeMap = { },
        ThemeItems = { },

        OpenFrames = { },

        SetFlags = { },

        UnnamedConnections = 0,
        UnnamedFlags = 0,

        Holder = nil,
        NotifHolder = nil,
        UnusedHolder = nil,
        KeyList = nil,

        Font = nil,
        SubFont = nil,
    }

    Library.__index = Library
    Library.Sections.__index = Library.Sections
    Library.Pages.__index = Library.Pages

    local Keys = {
        ["Unknown"]           = "Unknown",
        ["Backspace"]         = "Back",
        ["Tab"]               = "Tab",
        ["Clear"]             = "Clear",
        ["Return"]            = "Return",
        ["Pause"]             = "Pause",
        ["Escape"]            = "Escape",
        ["Space"]             = "Space",
        ["QuotedDouble"]      = '"',
        ["Hash"]              = "#",
        ["Dollar"]            = "$",
        ["Percent"]           = "%",
        ["Ampersand"]         = "&",
        ["Quote"]             = "'",
        ["LeftParenthesis"]   = "(",
        ["RightParenthesis"]  = " )",
        ["Asterisk"]          = "*",
        ["Plus"]              = "+",
        ["Comma"]             = ",",
        ["Minus"]             = "-",
        ["Period"]            = ".",
        ["Slash"]             = "`",
        ["Three"]             = "3",
        ["Seven"]             = "7",
        ["Eight"]             = "8",
        ["Colon"]             = ":",
        ["Semicolon"]         = ";",
        ["LessThan"]          = "<",
        ["GreaterThan"]       = ">",
        ["Question"]          = "?",
        ["Equals"]            = "=",
        ["At"]                = "@",
        ["LeftBracket"]       = "LeftBracket",
        ["RightBracket"]      = "RightBracked",
        ["BackSlash"]         = "BackSlash",
        ["Caret"]             = "^",
        ["Underscore"]        = "_",
        ["Backquote"]         = "`",
        ["LeftCurly"]         = "{",
        ["Pipe"]              = "|",
        ["RightCurly"]        = "}",
        ["Tilde"]             = "~",
        ["Delete"]            = "Delete",
        ["End"]               = "End",
        ["KeypadZero"]        = "Keypad0",
        ["KeypadOne"]         = "Keypad1",
        ["KeypadTwo"]         = "Keypad2",
        ["KeypadThree"]       = "Keypad3",
        ["KeypadFour"]        = "Keypad4",
        ["KeypadFive"]        = "Keypad5",
        ["KeypadSix"]         = "Keypad6",
        ["KeypadSeven"]       = "Keypad7",
        ["KeypadEight"]       = "Keypad8",
        ["KeypadNine"]        = "Keypad9",
        ["KeypadPeriod"]      = "KeypadP",
        ["KeypadDivide"]      = "KeypadD",
        ["KeypadMultiply"]    = "KeypadM",
        ["KeypadMinus"]       = "KeypadM",
        ["KeypadPlus"]        = "KeypadP",
        ["KeypadEnter"]       = "KeypadE",
        ["KeypadEquals"]      = "KeypadE",
        ["Insert"]            = "Insert",
        ["Home"]              = "Home",
        ["PageUp"]            = "PageUp",
        ["PageDown"]          = "PageDown",
        ["RightShift"]        = "RightShift",
        ["LeftShift"]         = "LeftShift",
        ["RightControl"]      = "RightControl",
        ["LeftControl"]       = "LeftControl",
        ["LeftAlt"]           = "LeftAlt",
        ["RightAlt"]          = "RightAlt"
    }

    local Themes = {
        ["Preset"] = {
            ["Accent"] = FromRGB(166, 147, 243),
            ["Dark Accent"] = FromRGB(110, 97, 161)
        }
    }

    Library.Theme = TableClone(Themes["Preset"])

    -- Folders
    for Index, Value in Library.Folders do 
        if not isfolder(Value) then
            makefolder(Value)
        end
    end

    -- Images
    for Index, Value in Library.Images do 
        local ImageData = Value

        local ImageName = ImageData[1]
        local ImageLink = ImageData[2]
        
        if not isfile(Library.Folders.Assets .. "/" .. ImageName) then
            writefile(Library.Folders.Assets .. "/" .. ImageName, game:HttpGet(ImageLink))
        end
    end

    -- Tweening
    local Tween = { } do
        Tween.__index = Tween

        Tween.Create = function(self, Item, Info, Goal, IsRawItem)
            Item = IsRawItem and Item or Item.Instance
            Info = Info or TweenInfo.new(Library.Tween.Time, Library.Tween.Style, Library.Tween.Direction)

            local NewTween = {
                Tween = TweenService:Create(Item, Info, Goal),
                Info = Info,
                Goal = Goal,
                Item = Item
            }

            NewTween.Tween:Play()

            setmetatable(NewTween, Tween)

            return NewTween
        end

        Tween.GetProperty = function(self, Item)
            Item = Item or self.Item 

            if Item:IsA("Frame") then
                return { "BackgroundTransparency" }
            elseif Item:IsA("TextLabel") or Item:IsA("TextButton") then
                return { "TextTransparency", "BackgroundTransparency" }
            elseif Item:IsA("ImageLabel") or Item:IsA("ImageButton") then
                return { "BackgroundTransparency", "ImageTransparency" }
            elseif Item:IsA("ScrollingFrame") then
                return { "BackgroundTransparency", "ScrollBarImageTransparency" }
            elseif Item:IsA("TextBox") then
                return { "TextTransparency", "BackgroundTransparency" }
            elseif Item:IsA("UIStroke") then 
                return { "Transparency" }
            end
        end

        Tween.FadeItem = function(self, Item, Property, Visibility, Speed)
            local Item = Item or self.Item 

            local OldTransparency = Item[Property]
            Item[Property] = Visibility and 1 or OldTransparency

            local NewTween = Tween:Create(Item, TweenInfo.new(Speed or Library.Tween.Time, Library.Tween.Style, Library.Tween.Direction), {
                [Property] = Visibility and OldTransparency or 1
            }, true)

            Library:Connect(NewTween.Tween.Completed, function()
                if not Visibility then 
                    task.wait()
                    Item[Property] = OldTransparency
                end
            end)

            return NewTween
        end

        Tween.Get = function(self)
            if not self.Tween then 
                return
            end

            return self.Tween, self.Info, self.Goal
        end

        Tween.Pause = function(self)
            if not self.Tween then 
                return
            end

            self.Tween:Pause()
        end

        Tween.Play = function(self)
            if not self.Tween then 
                return
            end

            self.Tween:Play()
        end

        Tween.Clean = function(self)
            if not self.Tween then 
                return
            end

            Tween:Pause()
            self = nil
        end
    end

    -- Instances
    local Instances = { } do
        Instances.__index = Instances

        Instances.Create = function(self, Class, Properties)
            local NewItem = {
                Instance = InstanceNew(Class),
                Properties = Properties,
                Class = Class
            }

            setmetatable(NewItem, Instances)

            for Property, Value in NewItem.Properties do
                NewItem.Instance[Property] = Value
            end

            return NewItem
        end

        Instances.FadeItem = function(self, Visibility, Speed)
            local Item = self.Instance

            if Visibility == true then 
                Item.Visible = true
            end

            local Descendants = Item:GetDescendants()
            TableInsert(Descendants, Item)

            local NewTween

            for Index, Value in Descendants do 
                local TransparencyProperty = Tween:GetProperty(Value)

                if not TransparencyProperty then 
                    continue
                end

                if type(TransparencyProperty) == "table" then 
                    for _, Property in TransparencyProperty do 
                        NewTween = Tween:FadeItem(Value, Property, not Visibility, Speed)
                    end
                else
                    NewTween = Tween:FadeItem(Value, TransparencyProperty, not Visibility, Speed)
                end
            end
        end

        Instances.AddToTheme = function(self, Properties)
            if not self.Instance then 
                return
            end

            Library:AddToTheme(self, Properties)
        end

        Instances.ChangeItemTheme = function(self, Properties)
            if not self.Instance then 
                return
            end

            Library:ChangeItemTheme(self, Properties)
        end

        Instances.Connect = function(self, Event, Callback, Name)
            if not self.Instance then 
                return
            end

            if not self.Instance[Event] then 
                return
            end

            return Library:Connect(self.Instance[Event], Callback, Name)
        end

        Instances.Tween = function(self, Info, Goal)
            if not self.Instance then 
                return
            end

            return Tween:Create(self, Info, Goal)
        end

        Instances.Disconnect = function(self, Name)
            if not self.Instance then 
                return
            end

            return Library:Disconnect(Name)
        end

        Instances.Clean = function(self)
            if not self.Instance then 
                return
            end

            self.Instance:Destroy()
            self = nil
        end

        Instances.MakeDraggable = function(self)
            if not self.Instance then 
                return
            end
        
            local Gui = self.Instance
            local Dragging = false 
            local DragStart
            local StartPosition 
        
            local Set = function(Input)
                local DragDelta = Input.Position - DragStart
                local NewX = StartPosition.X.Offset + DragDelta.X
                local NewY = StartPosition.Y.Offset + DragDelta.Y

                local ScreenSize = Gui.Parent.AbsoluteSize
                local GuiSize = Gui.AbsoluteSize
        
                NewX = MathClamp(NewX, 0, ScreenSize.X - GuiSize.X)
                NewY = MathClamp(NewY, 0, ScreenSize.Y - GuiSize.Y)
        
                self:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(0, NewX, 0, NewY)})
            end
        
            local InputChanged
        
            self:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = true
                    DragStart = Input.Position
                    StartPosition = Gui.Position
        
                    if InputChanged then 
                        return
                    end
        
                    InputChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            Dragging = false
                            InputChanged:Disconnect()
                            InputChanged = nil
                        end
                    end)
                end
            end)
        
            Library:Connect(UserInputService.InputChanged, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                    if Dragging then
                        Set(Input)
                    end
                end
            end)
        
            return Dragging
        end

        Instances.MakeResizeable = function(self, Minimum, Maximum)
            if not self.Instance then 
                return
            end

            local Gui = self.Instance

            local Resizing = false 
            local CurrentSide = nil

            local StartMouse = nil 
            local StartPosition = nil 
            local StartSize = nil
            
            local EdgeThickness = 2

            local MakeEdge = function(Name, Position, Size)
                local Button = Instances:Create("TextButton", {
                    Name = "\0",
                    Size = Size,
                    Position = Position,
                    BackgroundColor3 = FromRGB(166, 147, 243),
                    BackgroundTransparency = 1,
                    Text = "",
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Parent = Gui,
                    ZIndex = 99999,
                })  Button:AddToTheme({BackgroundColor3 = "Accent"})

                return Button
            end

            local Edges = {
                {Button = MakeEdge(
                    "Left", 
                    UDim2New(0, 0, 0, 0), 
                    UDim2New(0, EdgeThickness, 1, 0)), 
                    Side = "L"
                },

                {Button = MakeEdge(
                    "Right", 
                    UDim2New(1, -EdgeThickness, 0, 0), 
                    UDim2New(0, EdgeThickness, 1, 0)), 
                    Side = "R"
                },

                {Button = MakeEdge(
                    "Top", UDim2New(0, 0, 0, 0), 
                    UDim2New(1, 0, 0, EdgeThickness)), 
                    Side = "T"
                },

                {Button = MakeEdge(
                    "Bottom", 
                    UDim2New(0, 0, 1, -EdgeThickness), 
                    UDim2New(1, 0, 0, EdgeThickness)), 
                    Side = "B"
                },
            }

            local BeginResizing = function(Side)
                Resizing = true 
                CurrentSide = Side 

                StartMouse = UserInputService:GetMouseLocation()

                -- store offsets, not absolute screen pos
                StartPosition = Vector2New(Gui.Position.X.Offset, Gui.Position.Y.Offset)
                StartSize = Vector2New(Gui.Size.X.Offset, Gui.Size.Y.Offset)
                
                for Index, Value in Edges do 
                    Value.Button.Instance.BackgroundTransparency = (Value.Side == Side) and 0 or 1
                end
            end

            local EndResizing = function()
                Resizing = false 
                CurrentSide = nil

                for Index, Value in Edges do 
                    Value.Button.Instance.BackgroundTransparency = 1
                end
            end

            for Index, Value in Edges do 
                Value.Button:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        BeginResizing(Value.Side)
                    end
                end)
            end

            Library:Connect(UserInputService.InputEnded, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if Resizing then
                        EndResizing()
                    end
                end
            end)

            Library:Connect(RunService.RenderStepped, function()
                if not Resizing or not CurrentSide then 
                    return 
                end

                local MouseLocation = UserInputService:GetMouseLocation()
                local dx = MouseLocation.X - StartMouse.X
                local dy = MouseLocation.Y - StartMouse.Y
            
                local x, y = StartPosition.X, StartPosition.Y
                local w, h = StartSize.X, StartSize.Y

                if CurrentSide == "L" then
                    x = StartPosition.X + dx
                    w = StartSize.X - dx
                elseif CurrentSide == "R" then
                    w = StartSize.X + dx
                elseif CurrentSide == "T" then
                    y = StartPosition.Y + dy
                    h = StartSize.Y - dy
                elseif CurrentSide == "B" then
                    h = StartSize.Y + dy
                end
            
                if w < Minimum.X then
                    if CurrentSide == "L" then
                        x = x - (Minimum.X - w)
                    end
                    w = Minimum.X
                end
                if h < Minimum.Y then
                    if CurrentSide == "T" then
                        y = y - (Minimum.Y - h)
                    end
                    h = Minimum.Y
                end
            
                self:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2FromOffset(x, y)})
                self:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2FromOffset(w, h)})
            end)
        end

        Instances.OnHover = function(self, Function)
            if not self.Instance then 
                return
            end
            
            return Library:Connect(self.Instance.MouseEnter, Function)
        end

        Instances.OnHoverLeave = function(self, Function)
            if not self.Instance then 
                return
            end
            
            return Library:Connect(self.Instance.MouseLeave, Function)
        end
    end

    -- Custom font
    local CustomFont = { } do
        function CustomFont:New(Name, Weight, Style, Data)
            if not isfile(Data.Id) then 
                writefile(Data.Id, game:HttpGet(Data.Url))
            end

            local Data = {
                name = Name,
                faces = {
                    {
                        name = Name,
                        weight = Weight,
                        style = Style,
                        assetId = getcustomasset(Data.Id)
                    }
                }
            }

            writefile(`{Library.Folders.Fonts}/{Name}.font`, HttpService:JSONEncode(Data))
            return Font.new(getcustomasset(`{Library.Folders.Fonts}/{Name}.font`))
        end

        Library.Font = CustomFont:New("SegoeUIB", 400, "Regular", {
            Id = "SegoeUIB",
            Url = "https://github.com/Madelena/hass-config-public/raw/a34865410ae96c4f5d26938d45115e88b8032bc6/www/segoeuib.ttf"
        })

        Library.SubFont = CustomFont:New("SmallestPixel", 400, "Regular", {
            Id = "SmallestPixel",
            Url = "https://github.com/sametexe001/luas/raw/refs/heads/main/fonts/smallest_pixel-7.ttf"
        })
    end

    Library.Holder = Instances:Create("ScreenGui", {
        Parent = gethui(),
        Name = "\0",
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 2,
        IgnoreGuiInset = true,
        ResetOnSpawn = false
    })

    Library.UnusedHolder = Instances:Create("ScreenGui", {
        Parent = gethui(),
        Name = "\0",
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        Enabled = false,
        ResetOnSpawn = false
    })

    Library.NotifHolder = Instances:Create("Frame", {
        Parent = Library.Holder.Instance,
        Name = "\0",
        BackgroundTransparency = 1,
        Position = UDim2New(0, 0, 0, 65),
        Size = UDim2New(0, 0, 1, 0),
        BorderColor3 = FromRGB(0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = FromRGB(255, 255, 255)
    })
    
    Instances:Create("UIListLayout", {
        Parent = Library.NotifHolder.Instance,
        Name = "\0",
        Padding = UDimNew(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    
    Instances:Create("UIPadding", {
        Parent = Library.NotifHolder.Instance,
        Name = "\0",
        PaddingTop = UDimNew(0, 12),
        PaddingBottom = UDimNew(0, 12),
        PaddingRight = UDimNew(0, 12),
        PaddingLeft = UDimNew(0, 12)
    })

    Library.Unload = function(self)
        for Index, Value in self.Connections do 
            Value.Connection:Disconnect()
        end

        for Index, Value in self.Threads do 
            coroutine.close(Value)
        end

        if self.Holder then 
            self.Holder:Clean()
        end

        Library = nil 
        getgenv().Library = nil
    end

    Library.GetImage = function(self, Image)
        local ImageData = self.Images[Image]

        if not ImageData then 
            return
        end

        return getcustomasset(self.Folders.Assets .. "/" .. ImageData[1])
    end

    Library.Round = function(self, Number, Float)
        local Multiplier = 1 / (Float or 1)
        return MathFloor(Number * Multiplier) / Multiplier
    end

    Library.Thread = function(self, Function)
        local NewThread = coroutine.create(Function)
        
        coroutine.wrap(function()
            coroutine.resume(NewThread)
        end)()

        TableInsert(self.Threads, NewThread)
        return NewThread
    end
    
    Library.SafeCall = function(self, Function, ...)
        local Arguements = { ... }
        local Success, Result = pcall(Function, TableUnpack(Arguements))

        if not Success then
            warn(Result)
            return false
        end

        return Success
    end

    Library.Connect = function(self, Event, Callback, Name)
        Name = Name or StringFormat("connection_number_%s_%s", self.UnnamedConnections + 1, HttpService:GenerateGUID(false))

        local NewConnection = {
            Event = Event,
            Callback = Callback,
            Name = Name,
            Connection = nil
        }

        Library:Thread(function()
            NewConnection.Connection = Event:Connect(Callback)
        end)

        TableInsert(self.Connections, NewConnection)
        return NewConnection
    end

    Library.Disconnect = function(self, Name)
        for _, Connection in self.Connections do 
            if Connection.Name == Name then
                Connection.Connection:Disconnect()
                break
            end
        end
    end

    Library.NextFlag = function(self)
        local FlagNumber = self.UnnamedFlags + 1
        return StringFormat("flag_number_%s_%s", FlagNumber, HttpService:GenerateGUID(false))
    end

    Library.AddToTheme = function(self, Item, Properties)
        Item = Item.Instance or Item 

        local ThemeData = {
            Item = Item,
            Properties = Properties,
        }

        for Property, Value in ThemeData.Properties do
            if type(Value) == "string" then
                Item[Property] = self.Theme[Value]
            else
                Item[Property] = Value()
            end
        end

        TableInsert(self.ThemeItems, ThemeData)
        self.ThemeMap[Item] = ThemeData
    end

	Library.ToRich = function(self, Text, Color)
		return `<font color="rgb({MathFloor(Color.R * 255)}, {MathFloor(Color.G * 255)}, {MathFloor(Color.B * 255)})">{Text}</font>`
	end

    Library.GetConfig = function(self)
        local Config = { } 

        local Success, Result = Library:SafeCall(function()
            for Index, Value in Library.Flags do 
                if type(Value) == "table" and Value.Key then
                    Config[Index] = {Key = tostring(Value.Key), Mode = Value.Mode}
                elseif type(Value) == "table" and Value.Color then
                    Config[Index] = {Color = "#" .. Value.HexValue, Alpha = Value.Alpha}
                else
                    Config[Index] = Value
                end
            end
        end)

        return HttpService:JSONEncode(Config)
    end

    Library.LoadConfig = function(self, Config)
        local Decoded = HttpService:JSONDecode(Config)

        local Success, Result = Library:SafeCall(function()
            for Index, Value in Decoded do 
                local SetFunction = Library.SetFlags[Index]

                if not SetFunction then
                    continue
                end

                if type(Value) == "table" and Value.Key then 
                    SetFunction(Value)
                elseif type(Value) == "table" and Value.Color then
                    SetFunction(Value.Color, Value.Alpha)
                else
                    SetFunction(Value)
                end
            end
        end)

        return Success, Result
    end

    Library.DeleteConfig = function(self, Config)
        if isfile(Library.Folders.Configs .. "/" .. Config) then 
            delfile(Library.Folders.Configs .. "/" .. Config)
        end
    end

    Library.RefreshConfigsList = function(self, Element)
        local List = { }
        local ReturnList = { }

        List = listfiles(Library.Folders.Configs)

        for Index = 1, #List do 
            local File = List[Index]

            if File:sub(-5) == ".json" then
                local Position = File:find(".json", 1, true)
                local StartPosition = Position

                local Character = File:sub(Position, Position)
                while Character ~= "/" and Character ~= "\\" and Character ~= "" do
                    Position = Position - 1
                    Character = File:sub(Position, Position)
                end

                if Character == "/" or Character == "\\" then
                    TableInsert(ReturnList, File:sub(Position + 1, StartPosition - 1))
                end
            end
        end

        Element:Refresh(ReturnList)
    end

    Library.ChangeItemTheme = function(self, Item, Properties)
        Item = Item.Instance or Item

        if not self.ThemeMap[Item] then 
            return
        end

        self.ThemeMap[Item].Properties = Properties
        self.ThemeMap[Item] = self.ThemeMap[Item]
    end

    Library.ChangeTheme = function(self, Theme, Color)
        self.Theme[Theme] = Color

        for _, Item in self.ThemeItems do
            for Property, Value in Item.Properties do
                if type(Value) == "string" and Value == Theme then
                    Item.Item[Property] = Color
                elseif type(Value) == "function" then
                    Item.Item[Property] = Value()
                end
            end
        end
    end

    Library.RemoveFromTheme = function(self, Item)
        Item = Item.Instance or Item

        if not self.ThemeMap[Item] then 
            return
        end

        self.ThemeMap[Item].Properties = nil
        self.ThemeMap[Item] = nil
    end

    Library.IsMouseOverFrame = function(self, Frame)
        Frame = Frame.Instance

        local MousePosition = Vector2New(Mouse.X, Mouse.Y)

        return MousePosition.X >= Frame.AbsolutePosition.X and MousePosition.X <= Frame.AbsolutePosition.X + Frame.AbsoluteSize.X 
        and MousePosition.Y >= Frame.AbsolutePosition.Y and MousePosition.Y <= Frame.AbsolutePosition.Y + Frame.AbsoluteSize.Y
    end

    Library.GetLighterColor = function(self, Color, Increment)
        local Hue, Saturation, Value = Color:ToHSV()
        return FromHSV(Hue, Saturation, Value * Increment)
    end

    Library.GetDarkerColor = function(self, Color, Increment)
        local Hue, Saturation, Value = Color:ToHSV()
        return FromHSV(Hue, Saturation, Value / Increment)
    end

    do 
        Library.CreateColorpicker = function(self, Data)
            local Colorpicker = {
                Flag = Data.Flag,

                Hue = 0,
                Saturation = 0,
                Value = 0,

                Alpha = 0,

                Color = FromRGB(255, 255, 255),
                HexValue = "#ffffff",

                IsOpen = false
            }

            local Items = { } do
                Items["ColorpickerButton"] = Instances:Create("TextButton", {
                    Parent = Data.Parent.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    Size = UDim2New(0, 20, 0, 10),
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["ColorpickerButton"].Instance,
                    Name = "\0",
                    Rotation = 90,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(159, 159, 159))}
                })                

                Items["ColorpickerWindow"] = Instances:Create("Frame", {
                    Parent = Library.UnusedHolder.Instance,
                    Name = "\0",
                    Visible = false,
                    Position = UDim2New(0, 1123, 0, 238),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 192, 0, 210),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(20, 20, 20)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Instances:Create("UIStroke", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    Color = FromRGB(35, 35, 35),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })
                
                Items["Alpha"] = Instances:Create("TextButton", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 8, 1, -8),
                    Size = UDim2New(1, -16, 0, 15),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 240, 123)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Alpha"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 3)
                })
                
                Items["Checkers"] = Instances:Create("ImageLabel", {
                    Parent = Items["Alpha"].Instance,
                    Name = "\0",
                    ScaleType = Enum.ScaleType.Tile,
                    BorderColor3 = FromRGB(0, 0, 0),
                    TileSize = UDim2New(0, 6, 0, 6),
                    Image = "http://www.roblox.com/asset/?id=18274452449",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 1, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Checkers"].Instance,
                    Name = "\0",
                    Transparency = NumSequence{NumSequenceKeypoint(0, 1), NumSequenceKeypoint(0.37, 0.5), NumSequenceKeypoint(1, 0)}
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Checkers"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 3)
                })
                
                Items["AlphaDragger"] = Instances:Create("Frame", {
                    Parent = Items["Alpha"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 1, 1, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIStroke", {
                    Parent = Items["AlphaDragger"].Instance,
                    Name = "\0",
                    Color = FromRGB(35, 35, 35),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })
                
                Items["Palette"] = Instances:Create("TextButton", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    Position = UDim2New(0, 8, 0, 8),
                    Size = UDim2New(1, -39, 1, -39),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 240, 123)
                })
                
                Items["Saturation"] = Instances:Create("Frame", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 1, 1, 0),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Saturation"].Instance,
                    Name = "\0",
                    Transparency = NumSequence{NumSequenceKeypoint(0, 1), NumSequenceKeypoint(1, 0)}
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Saturation"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["Value"] = Instances:Create("Frame", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 1, 1, 1),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(0, 0, 0)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Value"].Instance,
                    Name = "\0",
                    Rotation = 90,
                    Transparency = NumSequence{NumSequenceKeypoint(0, 1), NumSequenceKeypoint(1, 0)}
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Value"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["PaletteDragger"] = Instances:Create("Frame", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, 5, 0, 5),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 3, 0, 3),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIStroke", {
                    Parent = Items["PaletteDragger"].Instance,
                    Name = "\0",
                    Color = FromRGB(35, 35, 35),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })
                
                Items["Hue"] = Instances:Create("TextButton", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0),
                    Position = UDim2New(1, -8, 0, 8),
                    Size = UDim2New(0, 15, 1, -39),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Hue"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["HueInline"] = Instances:Create("TextButton", {
                    Parent = Items["Hue"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    Size = UDim2New(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["HueInline"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["HueInline"].Instance,
                    Name = "\0",
                    Rotation = 90,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 0, 0)), RGBSequenceKeypoint(0.17, FromRGB(255, 255, 0)), RGBSequenceKeypoint(0.33, FromRGB(0, 255, 0)), RGBSequenceKeypoint(0.5, FromRGB(0, 255, 255)), RGBSequenceKeypoint(0.67, FromRGB(0, 0, 255)), RGBSequenceKeypoint(0.83, FromRGB(255, 0, 255)), RGBSequenceKeypoint(1, FromRGB(255, 0, 0))}
                })
                
                Items["HueDragger"] = Instances:Create("Frame", {
                    Parent = Items["HueInline"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 1),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIStroke", {
                    Parent = Items["HueDragger"].Instance,
                    Name = "\0",
                    Color = FromRGB(35, 35, 35),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })                
            end

            function Colorpicker:Get()
                return Colorpicker.Color, Colorpicker.Alpha
            end

            function Colorpicker:Update(IsFromAlpha)
                local Hue, Saturation, Value = Colorpicker.Hue, Colorpicker.Saturation, Colorpicker.Value
                Colorpicker.Color = FromHSV(Hue, Saturation, Value)
                Colorpicker.HexValue = Colorpicker.Color:ToHex()

                Library.Flags[Colorpicker.Flag] = {
                    Alpha = Colorpicker.Alpha,
                    Color = Colorpicker.Color,
                    HexValue = Colorpicker.HexValue
                }

                Items["ColorpickerButton"]:Tween(nil, {BackgroundColor3 = Colorpicker.Color})
                Items["Palette"]:Tween(nil, {BackgroundColor3 = FromHSV(Hue, 1, 1)})

                if not IsFromAlpha then 
                    Items["Alpha"]:Tween(nil, {BackgroundColor3 = Colorpicker.Color})
                end

                if Data.Callback then 
                    Library:SafeCall(Data.Callback, Colorpicker.Color, Colorpicker.Alpha)
                end
            end

            local CompareVectors = function(PointA, PointB)
                return (PointA.X < PointB.X) or (PointA.Y < PointB.Y)
            end

            local IsClipped = function(Object, Column)
                local Parent = Column
                
                local BoundryTop = Parent.AbsolutePosition
                local BoundryBottom = BoundryTop + Parent.AbsoluteSize

                local Top = Object.AbsolutePosition
                local Bottom = Top + Object.AbsoluteSize 

                return CompareVectors(Top, BoundryTop) or CompareVectors(BoundryBottom, Bottom)
            end

            Items["ColorpickerButton"]:Connect("Changed", function(Property)
                if Property == "AbsolutePosition" and Colorpicker.IsOpen then
                    Colorpicker.IsOpen = not IsClipped(Items["ColorpickerButton"].Instance, Data.Section.Items["Outline"].Instance.Parent)
                    Items["ColorpickerWindow"].Instance.Visible = Colorpicker.IsOpen
                end
            end)

            local SlidingPalette = false
            local PaletteChanged
            
            function Colorpicker:SlidePalette(Input)
                if not Input or not SlidingPalette then
                    return
                end

                local ValueX = MathClamp(1 - (Input.Position.X - Items["Palette"].Instance.AbsolutePosition.X) / Items["Palette"].Instance.AbsoluteSize.X, 0, 1)
                local ValueY = MathClamp(1 - (Input.Position.Y - Items["Palette"].Instance.AbsolutePosition.Y) / Items["Palette"].Instance.AbsoluteSize.Y, 0, 1)

                Colorpicker.Saturation = ValueX
                Colorpicker.Value = ValueY

                local SlideX = MathClamp((Input.Position.X - Items["Palette"].Instance.AbsolutePosition.X) / Items["Palette"].Instance.AbsoluteSize.X, 0, 0.98)
                local SlideY = MathClamp((Input.Position.Y - Items["Palette"].Instance.AbsolutePosition.Y) / Items["Palette"].Instance.AbsoluteSize.Y, 0, 0.98)

                Items["PaletteDragger"]:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(SlideX, 0, SlideY, 0)})
                Colorpicker:Update()
            end
            
            local SlidingHue = false
            local HueChanged

            function Colorpicker:SlideHue(Input)
                if not Input or not SlidingHue then
                    return
                end
                
                local ValueY = MathClamp((Input.Position.Y - Items["Hue"].Instance.AbsolutePosition.Y) / Items["Hue"].Instance.AbsoluteSize.Y, 0, 1)

                Colorpicker.Hue = ValueY

                local SlideY = MathClamp((Input.Position.Y - Items["Hue"].Instance.AbsolutePosition.Y) / Items["Hue"].Instance.AbsoluteSize.Y, 0, 0.995)

                Items["HueDragger"]:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, SlideY, 0)})
                Colorpicker:Update()
            end

            local SlidingAlpha = false 
            local AlphaChanged

            function Colorpicker:SlideAlpha(Input)
                if not Input or not SlidingAlpha then
                    return
                end

                local ValueX = MathClamp((Input.Position.X - Items["Alpha"].Instance.AbsolutePosition.X) / Items["Alpha"].Instance.AbsoluteSize.X, 0, 1)

                Colorpicker.Alpha = ValueX

                local SlideX = MathClamp((Input.Position.X - Items["Alpha"].Instance.AbsolutePosition.X) / Items["Alpha"].Instance.AbsoluteSize.X, 0, 0.995)

                Items["AlphaDragger"]:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(SlideX, 0, 0, 0)})
                Colorpicker:Update(true)
            end

            local Debounce = false
            local RenderStepped  

            function Colorpicker:SetOpen(Bool)
                if Debounce then 
                    return
                end

                Colorpicker.IsOpen = Bool

                Debounce = true 

                if Colorpicker.IsOpen then 
                    Items["ColorpickerWindow"].Instance.Visible = true
                    Items["ColorpickerWindow"].Instance.Parent = Library.Holder.Instance
                    
                    RenderStepped = RunService.RenderStepped:Connect(function()
                        Items["ColorpickerWindow"].Instance.Position = UDim2New(
                            0, 
                            Items["ColorpickerButton"].Instance.AbsolutePosition.X, 
                            0, 
                            Items["ColorpickerButton"].Instance.AbsolutePosition.Y + Items["ColorpickerButton"].Instance.AbsoluteSize.Y + 65
                        )
                    end)

                    for Index, Value in Library.OpenFrames do 
                        Value:SetOpen(false)
                    end

                    Library.OpenFrames[Colorpicker] = Colorpicker 
                else
                    if Library.OpenFrames[Colorpicker] then 
                        Library.OpenFrames[Colorpicker] = nil
                    end

                    if RenderStepped then 
                        RenderStepped:Disconnect()
                        RenderStepped = nil
                    end
                end

                local Descendants = Items["ColorpickerWindow"].Instance:GetDescendants()
                TableInsert(Descendants, Items["ColorpickerWindow"].Instance)

                local NewTween

                for Index, Value in Descendants do 
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then
                        continue 
                    end

                    if type(TransparencyProperty) == "table" then 
                        for _, Property in TransparencyProperty do 
                            NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                    end
                end
                
                NewTween.Tween.Completed:Connect(function()
                    Debounce = false 
                    Items["ColorpickerWindow"].Instance.Visible = Colorpicker.IsOpen
                    task.wait(0.2)
                    Items["ColorpickerWindow"].Instance.Parent = not Colorpicker.IsOpen and Library.UnusedHolder.Instance or Library.Holder.Instance
                end)
            end

            function Colorpicker:Set(Color, Alpha)
                if type(Color) == "table" then
                    Color = FromRGB(Color[1], Color[2], Color[3])
                    Alpha = Color[4]
                elseif type(Color) == "string" then
                    Color = FromHex(Color)
                end 

                Colorpicker.Hue, Colorpicker.Saturation, Colorpicker.Value = Color:ToHSV()
                Colorpicker.Alpha = Alpha or 0  

                local PaletteValueX = MathClamp(1 - Colorpicker.Saturation, 0, 0.98)
                local PaletteValueY = MathClamp(1 - Colorpicker.Value, 0, 0.98)

                local AlphaPositionX = MathClamp(Colorpicker.Alpha, 0, 0.99)
                    
                local HuePositionY = MathClamp(Colorpicker.Hue, 0, 0.99)

                Items["PaletteDragger"]:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(PaletteValueX, 0, PaletteValueY, 0)})
                Items["HueDragger"]:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, HuePositionY, 0)})
                Items["AlphaDragger"]:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(AlphaPositionX, 0, 0, 0)})
                Colorpicker:Update()
            end

            Items["Palette"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    SlidingPalette = true 

                    Colorpicker:SlidePalette(Input)

                    if PaletteChanged then
                        return
                    end

                    PaletteChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            SlidingPalette = false

                            PaletteChanged:Disconnect()
                            PaletteChanged = nil
                        end
                    end)
                end
            end)

            Items["HueInline"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    SlidingHue = true 

                    Colorpicker:SlideHue(Input)

                    if HueChanged then
                        return
                    end

                    HueChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            SlidingHue = false

                            HueChanged:Disconnect()
                            HueChanged = nil
                        end
                    end)
                end
            end)

            Items["Alpha"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    SlidingAlpha = true 

                    Colorpicker:SlideAlpha(Input)

                    if AlphaChanged then
                        return
                    end

                    AlphaChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            SlidingAlpha = false

                            AlphaChanged:Disconnect()
                            AlphaChanged = nil
                        end
                    end)
                end
            end)

            Library:Connect(UserInputService.InputChanged, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement then
                    if SlidingPalette then 
                        Colorpicker:SlidePalette(Input)
                    end

                    if SlidingHue then
                        Colorpicker:SlideHue(Input)
                    end

                    if SlidingAlpha then
                        Colorpicker:SlideAlpha(Input)
                    end
                end
            end)

            Library:Connect(UserInputService.InputBegan, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if not Colorpicker.IsOpen then
                        return
                    end

                    if Library:IsMouseOverFrame(Items["ColorpickerWindow"]) then
                        return
                    end

                    Colorpicker:SetOpen(false)
                end
            end)

            Items["ColorpickerButton"]:Connect("MouseButton1Down", function()
                Colorpicker:SetOpen(not Colorpicker.IsOpen)
            end)
            
            if Data.Default then
                Colorpicker:Set(Data.Default, Data.Alpha)
            end

            Library.SetFlags[Colorpicker.Flag] = function(Value, Alpha)
                Colorpicker:Set(Value, Alpha)
            end

            return Colorpicker, Items 
        end

        Library.CreateKeybind = function(self, Data)
            local Keybind = {
                Flag = Data.Flag,

                Key = "",
                Value = "",
                Mode = "",

                Toggled = false,
                IsOpen = false,

                Picking = false,
            }   

            local Items = { } do 
                Items["KeyButton"] = Instances:Create("TextButton", {
                    Parent = Data.Parent.Instance,
                    Name = "\0",
                    FontFace = Library.SubFont,
                    TextColor3 = FromRGB(135, 135, 135),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "[NONE]",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.XY,
                    TextSize = 9,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })                

                Items["KeybindWindow"] = Instances:Create("Frame", {
                    Parent = Library.UnusedHolder.Instance,
                    Name = "\0",
                    Position = UDim2New(0, 53, 0, 104),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Visible = false,
                    Size = UDim2New(0, 125, 0, 80),
                    BorderSizePixel = 2,
                    BackgroundColor3 = FromRGB(20, 20, 20)
                })
                
                Instances:Create("UIStroke", {
                    Parent = Items["KeybindWindow"].Instance,
                    Name = "\0",
                    Color = FromRGB(35, 35, 35),
                    LineJoinMode = Enum.LineJoinMode.Miter,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })                

                Instances:Create("UIListLayout", {
                    Parent = Items["KeybindWindow"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 2),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })                
            end

            local KeyListItem 

            if Library.KeyList then 
                KeyListItem = Library.KeyList:Add("", "")
            end

            local Modes = { }

            local Update = function()
                KeyListItem:SetText(Data.Name, Keybind.Mode)
                KeyListItem:Set(Keybind.Toggled)
            end

            function Keybind:SetMode(Mode)
                Keybind.Mode = Mode

                Library.Flags[Keybind.Flag] = {
                    Mode = Keybind.Mode,
                    Key = Keybind.Key,
                    Toggled = Keybind.Toggled
                }

                if Data.Callback then 
                    Library:SafeCall(Data.Callback, Keybind.Toggled)
                end

                Update()
            end

            local AddMode = function(Name) -- yo no problem
                local ModeItems = { }

                ModeItems[Name] = Instances:Create("TextButton", {
                    Parent = Items["KeybindWindow"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 25),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                local ModeButton = ModeItems[Name] -- i haev to do this idk why
                
                ModeItems["Accent1"] = Instances:Create("Frame", {
                    Parent = ModeItems[Name].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 1, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    BackgroundColor3 = FromRGB(166, 147, 243)
                })  ModeItems["Accent1"]:AddToTheme({BackgroundColor3 = "Accent"})
                
                ModeItems["Accent2"] = Instances:Create("Frame", {
                    Parent = ModeItems[Name].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 1, 1, 0),
                    Position = UDim2New(0, 1, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(110, 97, 161)
                })  ModeItems["Accent2"]:AddToTheme({BackgroundColor3 = "Dark Accent"})
                
                ModeItems["Text"] = Instances:Create("TextLabel", {
                    Parent = ModeItems[Name].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(166, 147, 243),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Name,
                    AnchorPoint = Vector2New(0, 0.5),
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 10, 0.5, -2),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  ModeItems["Text"]:AddToTheme({TextColor3 = function()
                    return FromRGB(74, 74, 74)
                end})
                
                ModeItems["Background"] = Instances:Create("Frame", {
                    Parent = ModeItems[Name].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIGradient", {
                    Parent = ModeItems["Background"].Instance,
                    Name = "\0",
                    Transparency = NumSequence{NumSequenceKeypoint(0, 0.956250011920929), NumSequenceKeypoint(0.06, 0.9750000238418579), NumSequenceKeypoint(0.739, 1), NumSequenceKeypoint(1, 1)}
                })

                function ModeItems:Toggle()
                    ModeItems.Accent1:Tween(nil, {BackgroundTransparency = 0, Size = UDim2New(0, 1, 1, 0)})
                    ModeItems.Accent2:Tween(nil, {BackgroundTransparency = 0, Size = UDim2New(0, 1, 1, 0)})
                    ModeItems.Text:ChangeItemTheme({TextColor3 = "Accent"})
                    ModeItems.Text:Tween(nil, {TextColor3 = Library.Theme.Accent})
                    ModeItems.Background:Tween(nil, {BackgroundTransparency = 0})

                    for Index, Value in Modes do
                        if Index ~= Name then
                            Value.Accent1:Tween(nil, {BackgroundTransparency = 1, Size = UDim2New(0, 1, 0, 0)})
                            Value.Accent2:Tween(nil, {BackgroundTransparency = 1, Size = UDim2New(0, 1, 0, 0)})
                            Value.Text:ChangeItemTheme({TextColor3 = function()
                                return FromRGB(74, 74, 74)
                            end})
                            Value.Text:Tween(nil, {TextColor3 = FromRGB(74, 74, 74)})
                            Value.Background:Tween(nil, {BackgroundTransparency = 1})
                        end
                    end
                end

                Library:Connect(ModeButton.Instance.MouseButton1Down, function()
                    ModeItems:Toggle()
                    Keybind:SetMode(Name)
                end)

                Modes[Name] = ModeItems
                return ModeItems
            end

            local CompareVectors = function(PointA, PointB)
                return (PointA.X < PointB.X) or (PointA.Y < PointB.Y)
            end

            local IsClipped = function(Object, Column)
                local Parent = Column
                
                local BoundryTop = Parent.AbsolutePosition
                local BoundryBottom = BoundryTop + Parent.AbsoluteSize

                local Top = Object.AbsolutePosition
                local Bottom = Top + Object.AbsoluteSize 

                return CompareVectors(Top, BoundryTop) or CompareVectors(BoundryBottom, Bottom)
            end

            Items["KeyButton"]:Connect("Changed", function(Property)
                if Property == "AbsolutePosition" and Keybind.IsOpen then
                    Keybind.IsOpen = not IsClipped(Items["KeybindWindow"].Instance, Data.Section.Items["Outline"].Instance.Parent)
                    Items["KeybindWindow"].Instance.Visible = Keybind.IsOpen
                end
            end)

            AddMode("Toggle")
            AddMode("Hold")
            AddMode("Always On")

            function Keybind:Get()
                return Keybind.Key, Keybind.Mode, Keybind.Toggled
            end

            function Keybind:Set(Key)
                if StringFind(tostring(Key), "Enum") then 
                    Keybind.Key = tostring(Key)

                    Key = Key.Name == "Backspace" and "None" or Key.Name

                    local KeyString = Keys[Keybind.Key] or StringGSub(Key, "Enum.", "") or "None"
                    local TextToDisplay = "["..StringGSub(StringGSub(KeyString, "KeyCode.", ""), "UserInputType.", "").."]" or "[None]"

                    Keybind.Value = TextToDisplay
                    Items["KeyButton"].Instance.Text = TextToDisplay

                    Library.Flags[Keybind.Flag] = {
                        Mode = Keybind.Mode,
                        Key = Keybind.Key,
                        Toggled = Keybind.Toggled
                    }

                    if Data.Callback then 
                        Library:SafeCall(Data.Callback, Keybind.Toggled)
                    end

                    Update()
                elseif type(Key) == "table" then
                    local RealKey = Key.Key == "Backspace" and "None" or Key.Key
                    Keybind.Key = tostring(Key.Key)

                    if Key.Mode then
                        Modes[Key.Mode]:Toggle()
                        Keybind:SetMode(Key.Mode)
                    else
                        Modes["Toggle"]:Toggle()
                        Keybind:SetMode("Toggle")
                    end

                    local KeyString = Keys[Keybind.Key] or StringGSub(tostring(RealKey), "Enum.", "") or RealKey
                    local TextToDisplay = KeyString and StringGSub(StringGSub(KeyString, "KeyCode.", ""), "UserInputType.", "") or "[None]"

                    TextToDisplay = "["..StringGSub(StringGSub(KeyString, "KeyCode.", ""), "UserInputType.", "").."]"

                    Keybind.Value = TextToDisplay
                    Items["KeyButton"].Instance.Text = TextToDisplay

                    if Data.Callback then 
                        Library:SafeCall(Data.Callback, Keybind.Toggled)
                    end

                    Update()
                elseif TableFind({"Toggle", "Hold", "Always On"}, Key) then
                    Modes[Key]:Toggle()
                    Keybind:SetMode(Key)

                    if Data.Callback then 
                        Library:SafeCall(Data.Callback, Keybind.Toggled)
                    end

                    Update()
                end

                Keybind.Picking = false
            end

            local Debounce = false
            local RenderStepped  

            function Keybind:SetOpen(Bool)
                if Debounce then 
                    return
                end

                Keybind.IsOpen = Bool

                Debounce = true 

                if Keybind.IsOpen then 
                    Items["KeybindWindow"].Instance.Visible = true
                    Items["KeybindWindow"].Instance.Parent = Library.Holder.Instance
                    
                    RenderStepped = RunService.RenderStepped:Connect(function()
                        Items["KeybindWindow"].Instance.Position = UDim2New(
                            0, 
                            Items["KeyButton"].Instance.AbsolutePosition.X, 
                            0, 
                            Items["KeyButton"].Instance.AbsolutePosition.Y + Items["KeyButton"].Instance.AbsoluteSize.Y + 65
                        )
                    end)

                    for Index, Value in Library.OpenFrames do 
                        Value:SetOpen(false)
                    end

                    Library.OpenFrames[Keybind] = Keybind 
                else
                    if Library.OpenFrames[Keybind] then 
                        Library.OpenFrames[Keybind] = nil
                    end

                    if RenderStepped then 
                        RenderStepped:Disconnect()
                        RenderStepped = nil
                    end
                end

                local Descendants = Items["KeybindWindow"].Instance:GetDescendants()
                TableInsert(Descendants, Items["KeybindWindow"].Instance)

                local NewTween

                for Index, Value in Descendants do 
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then
                        continue 
                    end

                    if type(TransparencyProperty) == "table" then 
                        for _, Property in TransparencyProperty do 
                            NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                    end
                end
                
                NewTween.Tween.Completed:Connect(function()
                    Debounce = false 
                    Items["KeybindWindow"].Instance.Visible = Keybind.IsOpen
                    task.wait(0.2)
                    Items["KeybindWindow"].Instance.Parent = not Keybind.IsOpen and Library.UnusedHolder.Instance or Library.Holder.Instance
                end)
            end

            function Keybind:Press(Bool)
                if Keybind.Mode == "Toggle" then 
                    Keybind.Toggled = not Keybind.Toggled
                elseif Keybind.Mode == "Hold" then 
                    Keybind.Toggled = Bool
                elseif Keybind.Mode == "Always On" then 
                    Keybind.Toggled = true
                end

                Library.Flags[Keybind.Flag] = {
                    Mode = Keybind.Mode,
                    Key = Keybind.Key,
                    Toggled = Keybind.Toggled
                }

                if Data.Callback then 
                    Library:SafeCall(Data.Callback, Keybind.Toggled)
                end

                Update()
            end

            Items["KeyButton"]:Connect("MouseButton1Click", function()
                Keybind.Picking = true 

                Items["KeyButton"].Instance.Text = "."
                Library:Thread(function()
                    local Count = 1

                    while true do 
                        if not Keybind.Picking then 
                            break
                        end

                        if Count == 4 then
                            Count = 1
                        end

                        Items["KeyButton"].Instance.Text = Count == 1 and "." or Count == 2 and ".." or Count == 3 and "..."
                        Count += 1
                        task.wait(0.35)
                    end
                end)

                local InputBegan
                InputBegan = UserInputService.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.Keyboard then 
                        Keybind:Set(Input.KeyCode)
                    else
                        Keybind:Set(Input.UserInputType)
                    end

                    InputBegan:Disconnect()
                    InputBegan = nil
                end)
            end)

            Items["KeyButton"]:Connect("MouseButton2Down", function()
                Keybind:SetOpen(not Keybind.IsOpen)
            end)

            Library:Connect(UserInputService.InputBegan, function(Input)
                if Keybind.Value == "None" then
                    return
                end

                if tostring(Input.KeyCode) == Keybind.Key then
                    if Keybind.Mode == "Toggle" then 
                        Keybind:Press()
                    elseif Keybind.Mode == "Hold" then 
                        Keybind:Press(true)
                    elseif Keybind.Mode == "Always On" then 
                        Keybind:Press(true)
                    end
                elseif tostring(Input.UserInputType) == Keybind.Key then
                    if Keybind.Mode == "Toggle" then 
                        Keybind:Press()
                    elseif Keybind.Mode == "Hold" then 
                        Keybind:Press(true)
                    elseif Keybind.Mode == "Always On" then 
                        Keybind:Press(true)
                    end
                end

                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if not Keybind.IsOpen then
                        return
                    end

                    if Library:IsMouseOverFrame(Items["KeybindWindow"]) then
                        return
                    end

                    Keybind:SetOpen(false)
                end
            end)

            Library:Connect(UserInputService.InputEnded, function(Input)
                if Keybind.Value == "None" then
                    return
                end

                if tostring(Input.KeyCode) == Keybind.Key then
                    if Keybind.Mode == "Hold" then 
                        Keybind:Press(false)
                    elseif Keybind.Mode == "Always On" then 
                        Keybind:Press(true)
                    end
                elseif tostring(Input.UserInputType) == Keybind.Key then
                    if Keybind.Mode == "Hold" then 
                        Keybind:Press(false)
                    elseif Keybind.Mode == "Always On" then 
                        Keybind:Press(true)
                    end
                end
            end)

            if Data.Default then 
                Keybind:Set({
                    Mode = Data.Mode or "Toggle",
                    Key = Data.Default,
                })
            end

            Library.SetFlags[Keybind.Flag] = function(Value)
                Keybind:Set(Value)
            end

            return Keybind, Items
        end

        Library.Notification = function(self, Name, Duration, Color)
            Color = Color or Library.Theme.Accent
            local Items = { } do
                Items["Notification"] = Instances:Create("Frame", {
                    Parent = Library.NotifHolder.Instance,
                    Name = "\0",
                    ClipsDescendants = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.XY,
                    BackgroundColor3 = FromRGB(20, 20, 20)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 2)
                })
                
                Instances:Create("UIStroke", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    Color = FromRGB(35, 35, 35),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })
                
                Items["Accent1"] = Instances:Create("Frame", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 1, 1, 10),
                    Position = UDim2New(0, -8, 0, -7),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color
                })  
                 
                Items["Accent2"] = Instances:Create("Frame", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 1, 1, 10),
                    Position = UDim2New(0, -7, 0, -7),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Library:GetDarkerColor(Color, 1.35)
                })  
                
                Items["Background"] = Instances:Create("Frame", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, -8, 0, -7),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, 10),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    Transparency = NumSequence{NumSequenceKeypoint(0, 0.90625), NumSequenceKeypoint(0.075, 0.9437500238418579), NumSequenceKeypoint(0.427, 0.981249988079071), NumSequenceKeypoint(0.739, 1), NumSequenceKeypoint(1, 1)}
                })
                
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    Position = UDim2New(0, 0, 0, -4),
                    TextColor3 = FromRGB(221, 221, 221),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Name,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.XY,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIPadding", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 7),
                    PaddingBottom = UDimNew(0, -12),
                    PaddingRight = UDimNew(0, 8),
                    PaddingLeft = UDimNew(0, 8)
                })                
            end

            local OldSize = Items["Notification"].Instance.AbsoluteSize
            Items["Notification"].Instance.BackgroundTransparency = 1
            Items["Notification"].Instance.Size = UDim2New(0, 0, 0, 25)

            for Index, Value in Items["Notification"].Instance:GetDescendants() do
                if Value:IsA("UIStroke") then 
                    Value.Transparency = 1
                elseif Value:IsA("TextLabel") then 
                    Value.TextTransparency = 1
                elseif Value:IsA("Frame") then 
                    Value.BackgroundTransparency = 1
                end
            end
            
            task.wait(0.2)

            Items["Notification"].Instance.AutomaticSize = Enum.AutomaticSize.Y
            local TweenInfoq = TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

            Library:Thread(function()
                Items["Notification"]:Tween(TweenInfoq, {BackgroundTransparency = 0, Size = UDim2New(0,  OldSize.X, 0, OldSize.Y)})
                
                task.wait(0.06)

                for Index, Value in Items["Notification"].Instance:GetDescendants() do
                    if Value:IsA("UIStroke") then
                        Tween:Create(Value, TweenInfoq, {Transparency = 0}, true)
                    elseif Value:IsA("TextLabel") then
                        Tween:Create(Value, TweenInfoq, {TextTransparency = 0}, true)
                    elseif Value:IsA("Frame") then
                        Tween:Create(Value, TweenInfoq, {BackgroundTransparency = 0}, true)
                    end
                end

                task.delay(Duration, function()
                    for Index, Value in Items["Notification"].Instance:GetDescendants() do
                        if Value:IsA("UIStroke") then
                            Tween:Create(Value, TweenInfoq, {Transparency = 1}, true)
                        elseif Value:IsA("TextLabel") then
                            Tween:Create(Value, TweenInfoq, {TextTransparency = 1}, true)
                        elseif Value:IsA("Frame") then
                            Tween:Create(Value, TweenInfoq, {BackgroundTransparency = 1}, true)
                        end
                    end

                    task.wait(0.06)
                    Items["Notification"]:Tween(TweenInfoq, {BackgroundTransparency = 1, Size = UDim2New(0, 0, 0, 0)})

                    task.wait(0.5)
                    Items["Notification"]:Clean()
                end)
            end)
        end

        Library.KeybindList = function(self)
            local KeybindList = { }
            Library.KeyList = KeybindList

            local Items = { } do
                Items["KeybindsList"] = Instances:Create("Frame", {
                    Parent = Library.Holder.Instance,
                    Name = "\0",
                    Size = UDim2New(0, 0, 0, 35),
                    Position = UDim2New(0.014184396713972092, 0, 0.3557213842868805, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.XY,
                    BackgroundColor3 = FromRGB(26, 26, 26)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["KeybindsList"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Instances:Create("UIStroke", {
                    Parent = Items["KeybindsList"].Instance,
                    Name = "\0",
                    Color = FromRGB(35, 35, 35),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })
                
                Items["Top"] = Instances:Create("Frame", {
                    Parent = Items["KeybindsList"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 150, 0, 25),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 26)
                })
                
                Items["Liner"] = Instances:Create("Frame", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 0, 1, -1),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 1),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(166, 147, 243)
                })  Items["Liner"]:AddToTheme({BackgroundColor3 = "Accent"})
                
                Instances:Create("UIGradient", {
                    Parent = Items["Liner"].Instance,
                    Name = "\0",
                    Transparency = NumSequence{NumSequenceKeypoint(0, 0.8812500238418579), NumSequenceKeypoint(0.027, 0.8812500238418579), NumSequenceKeypoint(0.057, 0.887499988079071), NumSequenceKeypoint(1, 0)}
                })
                
                Items["Liner2"] = Instances:Create("Frame", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 0, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 1),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(110, 97, 161)
                })  Items["Liner2"]:AddToTheme({BackgroundColor3 = "Dark Accent"})
                
                Instances:Create("UIGradient", {
                    Parent = Items["Liner2"].Instance,
                    Name = "\0",
                    Transparency = NumSequence{NumSequenceKeypoint(0, 0.8812500238418579), NumSequenceKeypoint(0.027, 0.8812500238418579), NumSequenceKeypoint(0.057, 0.887499988079071), NumSequenceKeypoint(1, 0)}
                })
                
                Items["Shadow"] = Instances:Create("Frame", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, 0, 1, -1),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(0, 0, 0)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Shadow"].Instance,
                    Name = "\0",
                    Rotation = 90,
                    Transparency = NumSequence{NumSequenceKeypoint(0, 1), NumSequenceKeypoint(0.025, 0.800000011920929), NumSequenceKeypoint(0.106, 0.7250000238418579), NumSequenceKeypoint(0.22, 0.8500000238418579), NumSequenceKeypoint(1, 1)}
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    Rotation = 90,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(180, 180, 180))}
                })
                
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(221, 221, 221),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "Keybinds",
                    AnchorPoint = Vector2New(0, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0.5, -2),
                    Size = UDim2New(0, 150, 1, 0),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["Content"] = Instances:Create("Frame", {
                    Parent = Items["KeybindsList"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, 25),
                    Size = UDim2New(1, 0, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIListLayout", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
                
                Instances:Create("UIPadding", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    PaddingBottom = UDimNew(0, 8),
                    PaddingTop = UDimNew(0, 5),
                    PaddingLeft = UDimNew(0, 8)
                })                
            end

            function KeybindList:SetVisibility(Bool)
                Items["KeybindsList"].Instance.Visible = Bool
            end

            function KeybindList:Add(Name, Mode)
                local NewKey = Instances:Create("TextLabel", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(122, 122, 122),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Name,
                    Size = UDim2New(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                local NewKeyMode = Instances:Create("TextLabel", {
                    Parent = NewKey.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(112, 112, 112),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Mode,
                    AnchorPoint = Vector2New(1, 0),
                    Size = UDim2New(0, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, 50, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIPadding", {
                    Parent = NewKey.Instance,
                    Name = "\0",
                    PaddingRight = UDimNew(0, 55)
                })                

                function NewKey:SetText(Name, Mode)
                    NewKey.Instance.Text = Name
                    NewKeyMode.Instance.Text = Mode
                end

                function NewKey:Set(Bool)
                    NewKey.Instance.Visible = Bool
                end

                return NewKey
            end

            return KeybindList
        end

        Library.Watermark = function(self, Name, Icon)
            local Watermark = { }

            local Items = { } do 
                Items["Watermark"] = Instances:Create("Frame", {
                    Parent = Library.Holder.Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    Position = UDim2New(1, -8, 0, 8),
                    Size = UDim2New(0, 0, 0, 28),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundColor3 = FromRGB(29, 29, 29)
                })
                
                Instances:Create("UIPadding", {
                    Parent = Items["Watermark"].Instance,
                    Name = "\0",
                    PaddingRight = UDimNew(0, 8),
                    PaddingLeft = UDimNew(0, 4)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Watermark"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Instances:Create("UIStroke", {
                    Parent = Items["Watermark"].Instance,
                    Name = "\0",
                    Color = FromRGB(35, 35, 35),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })
                
                Items["Logo"] = Instances:Create("ImageLabel", {
                    Parent = Items["Watermark"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(166, 147, 243),
                    ScaleType = Enum.ScaleType.Fit,
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    Image = Icon,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0.5, 0),
                    Size = UDim2New(0, 20, 0, 20),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Logo"]:AddToTheme({ImageColor3 = "Accent"})
                
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Watermark"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    RichText = true,
                    TextColor3 = FromRGB(74, 74, 74),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Name,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 28, 0.5, -2),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Watermark"].Instance,
                    Name = "\0",
                    Rotation = 90,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(158, 158, 158))}
                })                
            end

            function Watermark:SetText(Text)
                Text = tostring(Text)
                Items["Text"].Instance.Text = Text
            end

            function Watermark:SetVisibility(Bool)
                Items["Watermark"].Instance.Visible = Bool
            end

            return Watermark 
        end

        Library.Window = function(self, Data)
            Data = Data or { }

            local Window = {
                Logo = Data.Logo or Data.logo or "rbxassetid://90459883253339",
                Build = Data.Build or Data.build or "live",
                
                Pages = { },
                Items = { },
                IsOpen = false
            }

            local Items = { } do
                Items["MainFrame"] = Instances:Create("Frame", {
                    Parent = Library.Holder.Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 786, 0, 481),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(20, 20, 20)
                })
                
                Items["MainFrame"]:MakeDraggable()
                Items["MainFrame"]:MakeResizeable(Vector2New(786, 481), Vector2New(9999, 9999))

                Instances:Create("UICorner", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["Bottom"] = Instances:Create("Frame", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 0, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 25),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(20, 20, 20)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Bottom"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Instances:Create("Frame", {
                    Parent = Items["Bottom"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 2),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(20, 20, 20)
                })
                
                Instances:Create("Frame", {
                    Parent = Items["Bottom"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 1),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(35, 35, 35)
                })
                
                Items["BottomShadow"] = Instances:Create("Frame", {
                    Parent = Items["Bottom"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 0, 0, 1),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(0, 0, 0)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["BottomShadow"].Instance,
                    Name = "\0",
                    Rotation = -90,
                    Transparency = NumSequence{NumSequenceKeypoint(0, 1), NumSequenceKeypoint(0.025, 0.800000011920929), NumSequenceKeypoint(0.106, 0.7250000238418579), NumSequenceKeypoint(0.22, 0.8500000238418579), NumSequenceKeypoint(1, 1)}
                })
                
                Items["BuildText"] = Instances:Create("TextLabel", {
                    Parent = Items["Bottom"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    RichText = true,
                    TextColor3 = FromRGB(74, 74, 74),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "build: "..Window.Build,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 8, 0.5, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIStroke", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    Color = FromRGB(35, 35, 35),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })
                
                Items["Top"] = Instances:Create("Frame", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 46),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 26)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Instances:Create("Frame", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 0, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 2),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(20, 20, 20)
                })
                
                Items["TopShadow"] = Instances:Create("Frame", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, 0, 1, -1),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(0, 0, 0)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["TopShadow"].Instance,
                    Name = "\0",
                    Rotation = 90,
                    Transparency = NumSequence{NumSequenceKeypoint(0, 1), NumSequenceKeypoint(0.025, 0.800000011920929), NumSequenceKeypoint(0.106, 0.7250000238418579), NumSequenceKeypoint(0.22, 0.8500000238418579), NumSequenceKeypoint(1, 1)}
                })
                
                Items["Logo"] = Instances:Create("ImageLabel", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(166, 147, 243),
                    ScaleType = Enum.ScaleType.Fit,
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    Image = Window.Logo,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 6, 0.5, 0),
                    Size = UDim2New(0, 32, 0, 32),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Logo"]:AddToTheme({ImageColor3 = "Accent"})
                
                Items["Liner"] = Instances:Create("Frame", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 0, 1, -1),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 1),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(166, 147, 243)
                })  Items["Liner"]:AddToTheme({BackgroundColor3 = "Accent"})
                
                Instances:Create("UIGradient", {
                    Parent = Items["Liner"].Instance,
                    Name = "\0",
                    Transparency = NumSequence{NumSequenceKeypoint(0, 1), NumSequenceKeypoint(0.41, 1), NumSequenceKeypoint(1, 0)}
                })
                
                Items["SubPages"] = Instances:Create("Frame", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, 0, 0, 0),
                    Size = UDim2New(0, 0, 1, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIPadding", {
                    Parent = Items["SubPages"].Instance,
                    Name = "\0",
                    PaddingRight = UDimNew(0, 12),
                    PaddingLeft = UDimNew(0, 12)
                })
                
                Instances:Create("UIListLayout", {
                    Parent = Items["SubPages"].Instance,
                    Name = "\0",
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    FillDirection = Enum.FillDirection.Horizontal,
                    Padding = UDimNew(0, 20),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })                

                Items["Side"] = Instances:Create("Frame", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, 46),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 148, 1, -71),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["PageHolder"] = Instances:Create("Frame", {
                    Parent = Items["Side"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, 13),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, -13),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("Frame", {
                    Parent = Items["Side"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(1, 0),
                    Position = UDim2New(1, 0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 1, 1, 0),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(35, 35, 35)
                })                

                Window.Items = Items
            end
            
            local Debounce = false

            function Window:SetCenter()
                local CenterPosition = Items["MainFrame"].Instance.AbsolutePosition
                task.wait()
                Items["MainFrame"].Instance.AnchorPoint = Vector2New(0, 0)

                Items["MainFrame"].Instance.Position = UDim2New(0, CenterPosition.X, 0, CenterPosition.Y)
            end

            function Window:SetOpen(Bool)
                for Index, Value in Library.OpenFrames do 
                    Value:SetOpen(false)
                end

                if Debounce then 
                    return
                end

                Window.IsOpen = Bool

                Debounce = true 

                if Window.IsOpen then 
                    Items["MainFrame"].Instance.Visible = true 
                end

                local Descendants = Items["MainFrame"].Instance:GetDescendants()
                TableInsert(Descendants, Items["MainFrame"].Instance)

                local NewTween

                for Index, Value in Descendants do 
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then
                        continue 
                    end

                    if type(TransparencyProperty) == "table" then 
                        for _, Property in TransparencyProperty do 
                            NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                    end
                end
                
                NewTween.Tween.Completed:Connect(function()
                    Debounce = false 
                    Items["MainFrame"].Instance.Visible = Window.IsOpen
                end)
            end

            Library:Connect(UserInputService.InputBegan, function(Input)
                if tostring(Input.KeyCode) == Library.MenuKeybind or tostring(Input.UserInputType) == Library.MenuKeybind then
                    Window:SetOpen(not Window.IsOpen)
                end
            end)

            Window:SetCenter()
            task.wait()
            Window:SetOpen(true)
            return setmetatable(Window, Library)
        end

        Library.Page = function(self, Data)
            Data = Data or { }

            local Page = {
                Window = self,

                Icon = Data.Icon or Data.icon or "rbxassetid://86962395649126",

                Items = { },
                SubPages = { },
                Active = false
            }

            local Items = { } do
                Items["Inactive"] = Instances:Create("TextButton", {
                    Parent = Page.Window.Items["SubPages"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 20, 0, 20),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(74, 74, 74),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Image = Page.Icon,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Icon"]:AddToTheme({ImageColor3 = function()
                    return FromRGB(74, 74, 74)
                end})

                Items["PageContent"] = Instances:Create("Frame", {
                    Parent = Library.UnusedHolder.Instance,
                    Name = "\0",
                    Visible = false,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 149, 0, 45),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, -149, 1, -70),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["SubPages"] = Instances:Create("Frame", {
                    Parent = Page.Window.Items["PageHolder"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Visible = false,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })                

                Instances:Create("UIListLayout", {
                    Parent = Items["SubPages"].Instance,
                    Name = "\0",
                    SortOrder = Enum.SortOrder.LayoutOrder
                })    

                Items["Inactive"]:OnHover(function()
                    if Page.Active then return end
                    Items["Icon"]:Tween(nil, {ImageColor3 = FromRGB(145, 145, 145)})
                end)

                Items["Inactive"]:OnHoverLeave(function()
                    if Page.Active then return end
                    Items["Icon"]:Tween(nil, {ImageColor3 = FromRGB(74, 74, 74)})
                end)

                Page.Items = Items
            end

            local Debounce = false

            function Page:Turn(Bool)
                if Debounce then 
                    return 
                end

                Page.Active = Bool 
                
                Debounce = true
                Items["PageContent"].Instance.Visible = Bool 
                Items["PageContent"].Instance.Parent = Bool and Page.Window.Items["MainFrame"].Instance or Library.UnusedHolder.Instance
                Items["SubPages"].Instance.Visible = Bool

                if Page.Active then
                    Items["Icon"]:ChangeItemTheme({ImageColor3 = "Accent"})
                    Items["Icon"]:Tween(nil, {ImageColor3 = Library.Theme.Accent})
                else
                    Items["Icon"]:ChangeItemTheme({ImageColor3 = function()
                        return FromRGB(74, 74, 74)
                    end})
                    Items["Icon"]:Tween(nil, {ImageColor3 = FromRGB(74, 74, 74)})
                end

                local AllInstances = Items["PageContent"].Instance:GetDescendants()
                TableInsert(AllInstances, Items["PageContent"].Instance)
                
                local NewTween 

                for Index, Value in AllInstances do 
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then 
                        continue
                    end

                    if type(TransparencyProperty) == "table" then 
                        for _, Property in TransparencyProperty do 
                            NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                    end
                end

                Library:Connect(NewTween.Tween.Completed, function()
                    Debounce = false
                end)
            end

            Items["Inactive"]:Connect("MouseButton1Down", function()
                for Index, Value in Page.Window.Pages do 
                    Value:Turn(Value == Page)
                end
            end)

            if #Page.Window.Pages == 0 then 
                Page:Turn(true)
            end

            TableInsert(Page.Window.Pages, Page)
            return setmetatable(Page, Library.Pages)
        end

        Library.Pages.SubPage = function(self, Data)
            Data = Data or { }

            local Page = {
                Window = self.Window,
                Page = self,

                Name = Data.Name or Data.name or "SubPage",
                Items = { },
                Active = false
            }

            local Items = { } do
                Items["Inactive"] = Instances:Create("TextButton", {
                    Parent = Page.Page.Items["SubPages"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 30),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["Accent1"] = Instances:Create("Frame", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 1, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    Position = UDim2New(0, 0, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(166, 147, 243)
                })  Items["Accent1"]:AddToTheme({BackgroundColor3 = "Accent"})
                
                Items["Accent2"] = Instances:Create("Frame", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 1, 0.5, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    Size = UDim2New(0, 1, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(110, 97, 161)
                })  Items["Accent2"]:AddToTheme({BackgroundColor3 = "Dark Accent"})
                
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(74, 74, 74),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Page.Name:upper(),
                    AnchorPoint = Vector2New(0, 0.5),
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 14, 0.5, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 13,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = function()
                    return FromRGB(74, 74, 74)
                end})
                
                Items["Background"] = Instances:Create("Frame", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    Transparency = NumSequence{NumSequenceKeypoint(0, 0.956250011920929), NumSequenceKeypoint(0.06, 0.9750000238418579), NumSequenceKeypoint(0.739, 1), NumSequenceKeypoint(1, 1)}
                })                

                Items["PageContent"] = Instances:Create("Frame", {
                    Parent = Library.UnusedHolder.Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    Visible = false,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIPadding", {
                    Parent = Items["PageContent"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 15),
                    PaddingBottom = UDimNew(0, 15),
                    PaddingRight = UDimNew(0, 15),
                    PaddingLeft = UDimNew(0, 15)
                })
                
                Instances:Create("UIListLayout", {
                    Parent = Items["PageContent"].Instance,
                    Name = "\0",
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalFlex = Enum.UIFlexAlignment.Fill,
                    Padding = UDimNew(0, 15),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalFlex = Enum.UIFlexAlignment.Fill
                })

                Items["Inactive"]:OnHover(function()
                    if Page.Active then return end
                    Items["Background"]:Tween(nil, {BackgroundTransparency = 0})
                end)

                Items["Inactive"]:OnHoverLeave(function()
                    if Page.Active then return end
                    Items["Background"]:Tween(nil, {BackgroundTransparency = 1})
                end)

                Page.Items = Items
            end

            local Debounce = false

            function Page:Turn(Bool)
                if Debounce then 
                    return 
                end

                Page.Active = Bool 
                
                Debounce = true
                Items["PageContent"].Instance.Visible = Bool 
                Items["PageContent"].Instance.Parent = Bool and Page.Page.Items["PageContent"].Instance or Library.UnusedHolder.Instance

                if Page.Active then
                    Items["Text"]:ChangeItemTheme({TextColor3 = "Accent"})
                    Items["Text"]:Tween(nil, {TextColor3 = Library.Theme.Accent})
                    Items["Accent1"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0, Size = UDim2New(0, 1, 1, 0)})
                    Items["Accent2"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0, Size = UDim2New(0, 1, 1, 0)})
                    Items["Background"]:Tween(nil, {BackgroundTransparency = 0})
                else
                    Library:ChangeItemTheme({TextColor3 = function()
                        return FromRGB(74, 74, 74)
                    end})
                    Items["Text"]:Tween(nil, {TextColor3 = FromRGB(74, 74, 74)})
                    Items["Accent1"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 1, Size = UDim2New(0, 1, 0, 0)})
                    Items["Accent2"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 1, Size = UDim2New(0, 1, 0, 0)})
                    Items["Background"]:Tween(nil, {BackgroundTransparency = 1})
                end

                local AllInstances = Items["PageContent"].Instance:GetDescendants()
                TableInsert(AllInstances, Items["PageContent"].Instance)
                
                local NewTween 

                for Index, Value in AllInstances do 
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then 
                        continue
                    end

                    if type(TransparencyProperty) == "table" then 
                        for _, Property in TransparencyProperty do 
                            NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                    end
                end

                Library:Connect(NewTween.Tween.Completed, function()
                    Debounce = false
                end)
            end

            Items["Inactive"]:Connect("MouseButton1Down", function()
                for Index, Value in Page.Page.SubPages do 
                    Value:Turn(Value == Page)
                end
            end)

            if #Page.Page.SubPages == 0 then 
                Page:Turn(true)
            end

            TableInsert(Page.Page.SubPages, Page)
            return setmetatable(Page, Library.Pages)
        end

        Library.Pages.Section = function(self, Data)
            Data = Data or { }

            local Section = {
                Window = self.Window,
                Page = self,

                Name = Data.Name or Data.name or "Section",

                Items = { }
            }

            local Items = { } do
                Items["Outline"] = Instances:Create("Frame", {
                    Parent = Section.Page.Items["PageContent"].Instance,
                    Name = "\0",
                    ClipsDescendants = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 100, 0, 125),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(35, 35, 35)
                })
                
                Items["Background"] = Instances:Create("Frame", {
                    Parent = Items["Outline"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, 1, 0, 1),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, -2, 1, -2),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(18, 18, 18)
                })
                
                Items["TopPartBackground"] = Instances:Create("Frame", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, 1, 0, 1),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, -2, 0, 19),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(18, 18, 18)
                })
                
                Items["MinGrad1"] = Instances:Create("Frame", {
                    Parent = Items["TopPartBackground"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, -1, 0, -1),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 2, 0, 1),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(30, 30, 30)
                })
                
                Items["MinGrad2"] = Instances:Create("Frame", {
                    Parent = Items["TopPartBackground"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, -1, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 2, 0, 1),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(30, 30, 30)
                })
                
                Items["BottomGradient"] = Instances:Create("Frame", {
                    Parent = Items["TopPartBackground"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, -1, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 2, 0, 6),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(18, 18, 18)
                })
                
                Items["MainGrad"] = Instances:Create("Frame", {
                    Parent = Items["TopPartBackground"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, -1, 0, 1),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 2, 0, 12),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["MainGrad"].Instance,
                    Name = "\0",
                    Rotation = -90,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(19, 19, 19)), RGBSequenceKeypoint(1, FromRGB(26, 26, 26))}
                })
                
                Items["Top"] = Instances:Create("Frame", {
                    Parent = Items["TopPartBackground"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 19),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["Shadow"] = Instances:Create("Frame", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, 0, 1, -1),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(0, 0, 0)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Shadow"].Instance,
                    Name = "\0",
                    Rotation = 90,
                    Transparency = NumSequence{NumSequenceKeypoint(0, 1), NumSequenceKeypoint(0.025, 0.800000011920929), NumSequenceKeypoint(0.106, 0.7250000238418579), NumSequenceKeypoint(0.22, 0.8500000238418579), NumSequenceKeypoint(1, 1)}
                })
                
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(119, 119, 119),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Section.Name,
                    AnchorPoint = Vector2New(0, 0.5),
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 6, 0.5, -2),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["ShadowBottom"] = Instances:Create("Frame", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 0, 1, 1),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(0, 0, 0)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["ShadowBottom"].Instance,
                    Name = "\0",
                    Rotation = -90,
                    Transparency = NumSequence{NumSequenceKeypoint(0, 1), NumSequenceKeypoint(0.025, 0.800000011920929), NumSequenceKeypoint(0.106, 0.7250000238418579), NumSequenceKeypoint(0.22, 0.8500000238418579), NumSequenceKeypoint(1, 1)}
                })
                
                Items["ShadowLeft"] = Instances:Create("Frame", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, 0, 0, 19),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 15, 1, -19),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(0, 0, 0)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["ShadowLeft"].Instance,
                    Name = "\0",
                    Transparency = NumSequence{NumSequenceKeypoint(0, 1), NumSequenceKeypoint(0.025, 0.800000011920929), NumSequenceKeypoint(0.106, 0.7250000238418579), NumSequenceKeypoint(0.22, 0.8500000238418579), NumSequenceKeypoint(1, 1)}
                })
                
                Items["ShadowRight"] = Instances:Create("Frame", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(1, 0),
                    Position = UDim2New(1, 0, 0, 19),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 15, 1, -19),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(0, 0, 0)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["ShadowRight"].Instance,
                    Name = "\0",
                    Rotation = 180,
                    Transparency = NumSequence{NumSequenceKeypoint(0, 1), NumSequenceKeypoint(0.025, 0.800000011920929), NumSequenceKeypoint(0.106, 0.7250000238418579), NumSequenceKeypoint(0.22, 0.8500000238418579), NumSequenceKeypoint(1, 1)}
                })
                
                Items["Elements"] = Instances:Create("ScrollingFrame", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    Active = true,
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ZIndex = 1,
                    BorderSizePixel = 0,
                    CanvasSize = UDim2New(0, 0, 0, 0),
                    ScrollBarImageColor3 = FromRGB(35, 35, 35),
                    MidImage = "rbxassetid://112378059475801",
                    BorderColor3 = FromRGB(0, 0, 0),
                    ScrollBarThickness = 3,
                    Size = UDim2New(1, -2, 1, -23),
                    Position = UDim2New(0, 0, 0, 21),
                    TopImage = "rbxassetid://112378059475801",
                    CanvasPosition = Vector2New(0, 172),
                    BottomImage = "rbxassetid://112378059475801",
                    BackgroundTransparency = 1,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["ElementsHolder"] = Instances:Create("Frame", {
                    Parent = Items["Elements"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    SelectionGroup = true,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 14, 0, 7),
                    Size = UDim2New(1, -26, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIListLayout", {
                    Parent = Items["ElementsHolder"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 10),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })               
                
                Instances:Create("UIPadding", {
                    Parent = Items["Elements"].Instance,
                    Name = "\0",
                    PaddingBottom = UDimNew(0, 22)
                })
                
                Items["BottomArrow"] = Instances:Create("ImageLabel", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    ScaleType = Enum.ScaleType.Fit,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 7, 0, 7),
                    AnchorPoint = Vector2New(1, 1),
                    Image = "rbxassetid://108270041153906",
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, -11, 1, -8),
                    ResampleMode = Enum.ResamplerMode.Pixelated,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["TopArrow"] = Instances:Create("ImageLabel", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    ScaleType = Enum.ScaleType.Fit,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 7, 0, 7),
                    Rotation = 180,
                    AnchorPoint = Vector2New(1, 1),
                    Image = "rbxassetid://108270041153906",
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, -11, 0, 36),
                    ResampleMode = Enum.ResamplerMode.Pixelated,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Outline"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Section.Items = Items
            end

            return setmetatable(Section, Library.Sections)
        end

        Library.Sections.Toggle = function(self, Data)
            Data = Data or { }

            local Toggle = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Toggle",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Default = Data.Default or Data.default or false,
                Callback = Data.Callback or Data.callback or function() end,

                Value = false
            }

            local Items = { } do 
                Items["Toggle"] = Instances:Create("TextButton", {
                    Parent = Toggle.Section.Items["ElementsHolder"].Instance,
                    Name = "\0",
                    Active = false,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 13),
                    Selectable = false,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["Indicator"] = Instances:Create("Frame", {
                    Parent = Items["Toggle"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    Position = UDim2New(0, 0, 0.5, 0),
                    Size = UDim2New(0, 9, 0, 9),
                    BorderSizePixel = 2,
                    BackgroundColor3 = FromRGB(20, 20, 20)
                })  Items["Indicator"]:AddToTheme({BackgroundColor3 = function()
                    return FromRGB(20, 20, 20)
                end})
                
                Instances:Create("UIStroke", {
                    Parent = Items["Indicator"].Instance,
                    Name = "\0",
                    Color = FromRGB(35, 35, 35),
                    LineJoinMode = Enum.LineJoinMode.Miter,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Indicator"].Instance,
                    Name = "\0",
                    Rotation = 90,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(195, 195, 195))}
                })
                
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Toggle"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(221, 221, 221),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Toggle.Name,
                    Size = UDim2New(0, 0, 0, 13),
                    Position = UDim2New(0, 17, 0, -2),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })                

                Items["EXAMPLAR_"] = Instances:Create("Frame", {
                    Parent = Items["Toggle"].Instance,
                    Name = "\0",
                    Position = UDim2New(1, -8, 0, -2),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIListLayout", {
                    Parent = Items["EXAMPLAR_"].Instance,
                    Name = "\0",
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    Padding = UDimNew(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })                

                Items["Toggle"]:OnHover(function()
                    if Toggle.Value then return end 
                    Items["Indicator"]:Tween(nil, {BackgroundColor3 = Library:GetLighterColor(FromRGB(20, 20, 20), 1.45)})
                end)

                Items["Toggle"]:OnHoverLeave(function()
                    if Toggle.Value then return end 
                    Items["Indicator"]:Tween(nil, {BackgroundColor3 = FromRGB(20, 20, 20)})
                end)
            end

            function Toggle:Get()
                return Toggle.Value 
            end

            function Toggle:Set(Value)
                Toggle.Value = Value 
                Library.Flags[Toggle.Flag] = Value 

                if Toggle.Value then 
                    Items["Indicator"]:ChangeItemTheme({BackgroundColor3 = "Accent"})
                    Items["Indicator"]:Tween(nil, {BackgroundColor3 = Library.Theme.Accent})
                else
                    Items["Indicator"]:ChangeItemTheme({BackgroundColor3 = function()
                        return FromRGB(20, 20, 20)
                    end})
                    Items["Indicator"]:Tween(nil, {BackgroundColor3 = FromRGB(20, 20, 20)})
                end

                if Toggle.Callback then 
                    Library:SafeCall(Toggle.Callback, Toggle.Value)
                end
            end

            function Toggle:SetVisibility(Bool)
                Items["Toggle"].Instance.Visible = Bool 
            end

            function Toggle:Colorpicker(Data)
                Data = Data or { }

                local Colorpicker = {
                    Window = Toggle.Window,
                    Page = Toggle.Page,
                    Section = Toggle.Section,

                    Flag = Data.Flag or Data.flag or Library:NextFlag(),
                    Default = Data.Default or Data.default or Color3.fromRGB(255, 255, 255),
                    Alpha = Data.Alpha or Data.alpha or 0,
                    Callback = Data.Callback or Data.callback or function() end
                }

                local NewColorpicker, ColorpickerItems = Library:CreateColorpicker({
                    Parent = Items["EXAMPLAR_"],
                    Page = Colorpicker.Page,
                    Flag = Colorpicker.Flag,
                    Section = Colorpicker.Section,
                    Default = Colorpicker.Default,
                    Alpha = Colorpicker.Alpha,
                    Callback = Colorpicker.Callback,
                })

                return NewColorpicker
            end

            function Toggle:Keybind(Data)
                Data = Data or { }

                local Keybind = {
                    Window = Toggle.Window,
                    Page = Toggle.Page,
                    Section = Toggle.Section,

                    Name = Data.Name or Data.name or Toggle.Name,
                    Flag = Data.Flag or Data.flag or Library:NextFlag(),
                    Default = Data.Default or Data.default or Enum.KeyCode.RightShift,
                    Callback = Data.Callback or Data.callback or function() end,
                    Mode = Data.Mode or Data.mode or "Toggle",
                }

                local NewKeybind = Library:CreateKeybind({
                    Name = Keybind.Name,
                    Parent = Items["EXAMPLAR_"],
                    Flag = Keybind.Flag,
                    Default = Keybind.Default,
                    Mode = Keybind.Mode,
                    Section = Keybind.Section,
                    Callback = Keybind.Callback
                })

                return NewKeybind
            end

            Items["Toggle"]:Connect("MouseButton1Down", function()
                Toggle:Set(not Toggle.Value)
            end)

            Toggle:Set(Toggle.Default)

            Library.SetFlags[Toggle.Flag] = function(Value)
                Toggle:Set(Value)
            end

            return Toggle 
        end

        Library.Sections.Button = function(self, Data)
            Data = Data or { }

            local Button = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Button",
                Callback = Data.Callback or Data.callback or function() end
            }

            local Items = { } do
                Items["ButtonHolder"] = Instances:Create("Frame", {
                    Parent = Button.Section.Items["ElementsHolder"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 21),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["Outline"] = Instances:Create("Frame", {
                    Parent = Items["ButtonHolder"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, 17, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, -50, 0, 21),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(1, 1, 1)
                })
                
                Items["Inline"] = Instances:Create("Frame", {
                    Parent = Items["Outline"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, 1, 0, 1),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, -2, 1, -2),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(35, 35, 35)
                })
                
                Items["Indicator"] = Instances:Create("TextButton", {
                    Parent = Items["Inline"].Instance,
                    Text = "",
                    AutoButtonColor = false,
                    Name = "\0",
                    Position = UDim2New(0, 1, 0, 1),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, -2, 1, -2),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(20, 20, 20)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Indicator"].Instance,
                    Name = "\0",
                    Rotation = 90,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(195, 195, 195))}
                })
                
                Items["Value"] = Instances:Create("TextLabel", {
                    Parent = Items["Indicator"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(221, 221, 221),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Button.Name,
                    AnchorPoint = Vector2New(0, 0.5),
                    Size = UDim2New(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 6, 0.4166666567325592, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.XY,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Indicator"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 3)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Inline"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 3)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Outline"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 3)
                })                

                Items["ButtonHolder"]:OnHover(function()
                    Items["Indicator"]:Tween(nil, {BackgroundColor3 = Library:GetLighterColor(FromRGB(20, 20, 20), 1.45)})
                end)

                Items["ButtonHolder"]:OnHoverLeave(function()
                    Items["Indicator"]:Tween(nil, {BackgroundColor3 = FromRGB(20, 20, 20)})
                end)
            end

            function Button:Press()
                Items["Value"]:Tween(nil, {TextColor3 = Library.Theme.Accent})
                Library:SafeCall(Button.Callback)
                task.wait(0.1)
                Items["Value"]:Tween(nil, {TextColor3 = FromRGB(221, 221, 221)})
            end

            function Button:SetVisibility(Bool)
                Items["ButtonHolder"].Instance.Visible = Bool
            end

            Items["Indicator"]:Connect("MouseButton1Down", function()
                Button:Press()
            end)

            return Button
        end

        Library.Sections.Slider = function(self, Data)
            Data = Data or { }

            local Slider = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Slider",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Min = Data.Min or Data.min or 0,
                Decimals = Data.Decimals or Data.decimals or 1,
                Suffix = Data.Suffix or Data.suffix or "",
                Max = Data.Max or Data.max or 100,
                Default = Data.Default or Data.Default or 0,
                Callback = Data.Callback or Data.callback or function() end,

                Value = 0,
                Sliding = false
            }

            local Items = { } do 
                Items["Slider"] = Instances:Create("Frame", {
                    Parent = Slider.Section.Items["ElementsHolder"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 27),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["Indicator"] = Instances:Create("TextButton", {
                    Parent = Items["Slider"].Instance,
                    Text = "",
                    AutoButtonColor = false,
                    Name = "\0",
                    Position = UDim2New(0, 17, 0, 17),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, -50, 0, 9),
                    BorderSizePixel = 2,
                    BackgroundColor3 = FromRGB(20, 20, 20)
                })
                
                Instances:Create("UIStroke", {
                    Parent = Items["Indicator"].Instance,
                    Name = "\0",
                    Color = FromRGB(35, 35, 35),
                    LineJoinMode = Enum.LineJoinMode.Miter,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Indicator"].Instance,
                    Name = "\0",
                    Rotation = 90,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(195, 195, 195))}
                })
                
                Items["Accent"] = Instances:Create("Frame", {
                    Parent = Items["Indicator"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0.5, -2, 1, 0),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(166, 147, 243)
                })  Items["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})
                
                Instances:Create("UIGradient", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    Rotation = 90,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(195, 195, 195))}
                })
                
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Slider"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(221, 221, 221),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Slider.Name,
                    Size = UDim2New(0, 0, 0, 13),
                    Position = UDim2New(0, 17, 0, -2),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })                

                Items["Value"] = Instances:Create("TextLabel", {
                    Parent = Items["Slider"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(221, 221, 221),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AnchorPoint = Vector2New(1, 0),
                    Size = UDim2New(0, 0, 0, 13),
                    Position = UDim2New(1, -28, 0, -2),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })               

                Items["Indicator"]:OnHover(function()
                    Items["Indicator"]:Tween(nil, {BackgroundColor3 = Library:GetLighterColor(FromRGB(20, 20, 20), 1.45)})
                end)

                Items["Indicator"]:OnHoverLeave(function()
                    Items["Indicator"]:Tween(nil, {BackgroundColor3 = FromRGB(20, 20, 20)})
                end)
            end

            function Slider:Get()
                return Slider.Value
            end

            function Slider:Set(Value)
                Slider.Value = Library:Round(MathClamp(Value, Slider.Min, Slider.Max), Slider.Decimals)
                Library.Flags[Slider.Flag] = Slider.Value

                Items["Accent"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2New((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), 0, 1, 0)})
                Items["Value"].Instance.Text = StringFormat("%s%s", Slider.Value, Slider.Suffix)

                if Slider.Callback then 
                    Library:SafeCall(Slider.Callback, Slider.Value)
                end
            end

            function Slider:SetVisibility(Bool)
                Items["Slider"].Instance.Visible = Bool
            end

            Items["Indicator"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Slider.Sliding = true 

                    local SizeX = (Input.Position.X - Items["Indicator"].Instance.AbsolutePosition.X) / Items["Indicator"].Instance.AbsoluteSize.X
                    local Value = ((Slider.Max - Slider.Min) * SizeX) + Slider.Min

                    Slider:Set(Value)
                end
            end)

            Items["Indicator"]:Connect("InputEnded", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Slider.Sliding = false
                end
            end)

            Library:Connect(UserInputService.InputChanged, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement then 
                    if Slider.Sliding then
                        local SizeX = (Input.Position.X - Items["Indicator"].Instance.AbsolutePosition.X) / Items["Indicator"].Instance.AbsoluteSize.X
                        local Value = ((Slider.Max - Slider.Min) * SizeX) + Slider.Min

                        Slider:Set(Value)
                    end
                end
            end)

            if Slider.Default then
                Slider:Set(Slider.Default)
            end

            Library.SetFlags[Slider.Flag] = function(Value)
                Slider:Set(Value)
            end

            return Slider 
        end

        Library.Sections.Dropdown = function(self, Data)
            Data = Data or { }

            local Dropdown = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Dropdown",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Default = Data.Default or Data.default or "",
                Multi = Data.Multi or Data.multi or false,
                Items = Data.Items or Data.items or { },
                Callback = Data.Callback or Data.callback or function() end,

                Options = { },
                Value = { },
                IsOpen = false
            }

            local Items = { } do 
                Items["Dropdown"] = Instances:Create("Frame", {
                    Parent = Dropdown.Section.Items["ElementsHolder"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 38),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["Indicator"] = Instances:Create("TextButton", {
                    Parent = Items["Dropdown"].Instance,
                    Text = "",
                    AutoButtonColor = false,
                    Name = "\0",
                    Position = UDim2New(0, 17, 0, 17),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, -50, 0, 21),
                    BorderSizePixel = 2,
                    BackgroundColor3 = FromRGB(20, 20, 20),
                    ClipsDescendants = true,
                })
                
                Instances:Create("UIStroke", {
                    Parent = Items["Indicator"].Instance,
                    Name = "\0",
                    Color = FromRGB(35, 35, 35),
                    LineJoinMode = Enum.LineJoinMode.Miter,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Indicator"].Instance,
                    Name = "\0",
                    Rotation = 90,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(195, 195, 195))}
                })
                
                if not Dropdown.Multi then 
                    Items["Icon"] = Instances:Create("ImageLabel", {
                        Parent = Items["Indicator"].Instance,
                        Name = "\0",
                        ImageColor3 = FromRGB(74, 74, 74),
                        ScaleType = Enum.ScaleType.Fit,
                        BorderColor3 = FromRGB(0, 0, 0),
                        Size = UDim2New(0, 7, 0, 7),
                        AnchorPoint = Vector2New(1, 0.5),
                        Image = "rbxassetid://108270041153906",
                        BackgroundTransparency = 1,
                        Position = UDim2New(1, -8, 0.5, 0),
                        ResampleMode = Enum.ResamplerMode.Pixelated,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })
                else
                    Items["Icon"] = Instances:Create("ImageLabel", {
                        Parent = Items["Indicator"].Instance,
                        Name = "\0",
                        ImageColor3 = FromRGB(74, 74, 74),
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(1, 0.5),
                        Image = "rbxassetid://132890703695297",
                        BackgroundTransparency = 1,
                        Position = UDim2New(1, -8, 0.5, -1),
                        Size = UDim2New(0, 8, 0, 8),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(221, 221, 221)
                    })                    
                end
                
                Items["Value"] = Instances:Create("TextLabel", {
                    Parent = Items["Indicator"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(74, 74, 74),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "--",
                    Size = UDim2New(0.018518518656492233, 0, 0.8333333134651184, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    Position = UDim2New(0, 6, 0.4166666567325592, 0),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.XY,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Dropdown"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(221, 221, 221),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Dropdown.Name,
                    Size = UDim2New(0, 0, 0, 13),
                    Position = UDim2New(0, 17, 0, -2),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })                

                Items["DropdownHolder"] = Instances:Create("Frame", {
                    Parent = Library.UnusedHolder.Instance,
                    Name = "\0",
                    Size = UDim2New(0, 216, 0, 25),
                    Position = UDim2New(0, 253, 0, 84),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 2,
                    Visible = false,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(20, 20, 20)
                })

                Instances:Create("UIStroke", {
                    Parent = Items["DropdownHolder"].Instance,
                    Name = "\0",
                    Color = FromRGB(35, 35, 35),
                    LineJoinMode = Enum.LineJoinMode.Miter,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["DropdownHolder"].Instance,
                    Name = "\0",
                    SortOrder = Enum.SortOrder.LayoutOrder
                })            
                
                Items["Indicator"]:OnHover(function()
                    Items["Indicator"]:Tween(nil, {BackgroundColor3 = Library:GetLighterColor(FromRGB(20, 20, 20), 1.45)})
                end)

                Items["Indicator"]:OnHoverLeave(function()
                    Items["Indicator"]:Tween(nil, {BackgroundColor3 = FromRGB(20, 20, 20)})
                end)
            end
            
            local Debounce = false
            local RenderStepped  

            function Dropdown:SetOpen(Bool)
                if Debounce then 
                    return
                end

                Dropdown.IsOpen = Bool

                Debounce = true 

                if Dropdown.IsOpen then 
                    Items["DropdownHolder"].Instance.Visible = true
                    Items["DropdownHolder"].Instance.Parent = Library.Holder.Instance
                    
                    RenderStepped = RunService.RenderStepped:Connect(function()
                        Items["DropdownHolder"].Instance.Position = UDim2New(
                            0, 
                            Items["Indicator"].Instance.AbsolutePosition.X, 
                            0, 
                            Items["Indicator"].Instance.AbsolutePosition.Y + Items["Indicator"].Instance.AbsoluteSize.Y * 3 + 19 -- its weird
                        )
                        Items["DropdownHolder"].Instance.Size = UDim2New(0, Items["Indicator"].Instance.AbsoluteSize.X, 0, 0)
                    end)

                    for Index, Value in Library.OpenFrames do 
                        Value:SetOpen(false)
                    end

                    Library.OpenFrames[Dropdown] = Dropdown 
                else
                    if Library.OpenFrames[Dropdown] then 
                        Library.OpenFrames[Dropdown] = nil
                    end

                    if RenderStepped then 
                        RenderStepped:Disconnect()
                        RenderStepped = nil
                    end
                end

                local Descendants = Items["DropdownHolder"].Instance:GetDescendants()
                TableInsert(Descendants, Items["DropdownHolder"].Instance)

                local NewTween

                for Index, Value in Descendants do 
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then
                        continue 
                    end

                    if type(TransparencyProperty) == "table" then 
                        for _, Property in TransparencyProperty do 
                            NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                    end
                end
                
                NewTween.Tween.Completed:Connect(function()
                    Debounce = false 
                    Items["DropdownHolder"].Instance.Visible = Dropdown.IsOpen
                    task.wait(0.2)
                    Items["DropdownHolder"].Instance.Parent = not Dropdown.IsOpen and Library.UnusedHolder.Instance or Library.Holder.Instance
                end)
            end

            function Dropdown:SetVisibility(Bool)
                Items["Dropdown"].Instance.Visible = Bool
            end

            function Dropdown:Add(Option)
                local OptionItems = { } do 
                    OptionItems["Disabled"] = Instances:Create("TextButton", {
                        Parent = Items["DropdownHolder"].Instance,
                        Name = "\0",
                        Text = "",
                        AutoButtonColor = false,
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(0, 0, 0),
                        TextTransparency = 1,
                        Size = UDim2New(1, 0, 0, 25),
                        Selectable = true,
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        BorderColor3 = FromRGB(0, 0, 0),
                        Active = true,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })
                    
                    OptionItems["Accent1"] = Instances:Create("Frame", {
                        Parent = OptionItems["Disabled"].Instance,
                        Name = "\0",
                        BackgroundTransparency = 1,
                        Size = UDim2New(0, 1, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0, 0.5),
                        Position = UDim2New(0, 0, 0.5, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(166, 147, 243)
                    })  OptionItems["Accent1"]:AddToTheme({BackgroundColor3 = "Accent"})
                    
                    OptionItems["Accent2"] = Instances:Create("Frame", {
                        Parent = OptionItems["Disabled"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        BackgroundTransparency = 1,
                        Position = UDim2New(0, 1, 0.5, 0),
                        AnchorPoint = Vector2New(0, 0.5),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(110, 97, 161)
                    })  OptionItems["Accent2"]:AddToTheme({BackgroundColor3 = "Dark Accent"})
                    
                    OptionItems["Text"] = Instances:Create("TextLabel", {
                        Parent = OptionItems["Disabled"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(74, 74, 74),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = Option,
                        AnchorPoint = Vector2New(0, 0.5),
                        Size = UDim2New(0, 0, 0, 15),
                        BackgroundTransparency = 1,
                        Position = UDim2New(0, 10, 0.5, -2),
                        BorderSizePixel = 0,
                        AutomaticSize = Enum.AutomaticSize.X,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  OptionItems["Text"]:AddToTheme({TextColor3 = function()
                        return FromRGB(74, 74, 74)
                    end})
                    
                    OptionItems["Background"] = Instances:Create("Frame", {
                        Parent = OptionItems["Disabled"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        Size = UDim2New(1, 0, 1, 0),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })
                    
                    Instances:Create("UIGradient", {
                        Parent = OptionItems["Background"].Instance,
                        Name = "\0",
                        Transparency = NumSequence{NumSequenceKeypoint(0, 0.956250011920929), NumSequenceKeypoint(0.06, 0.9750000238418579), NumSequenceKeypoint(0.739, 1), NumSequenceKeypoint(1, 1)}
                    })                    
                end
                
                local OptionData = {
                    Button = OptionItems["Disabled"],
                    Accent1 = OptionItems["Accent1"],
                    Accent2 = OptionItems["Accent2"],
                    Text = OptionItems["Text"],
                    Background = OptionItems["Background"],
                    Name = Option,
                    Selected = false
                }

                function OptionData:Toggle(Status)
                    if Status == "Active" then 
                        OptionData.Accent1:Tween(nil, {BackgroundTransparency = 0, Size = UDim2New(0, 1, 1, 0)})
                        OptionData.Accent2:Tween(nil, {BackgroundTransparency = 0, Size = UDim2New(0, 1, 1, 0)})
                        OptionData.Text:ChangeItemTheme({TextColor3 = "Accent"})
                        OptionData.Text:Tween(nil, {TextColor3 = Library.Theme.Accent})
                        OptionData.Background:Tween(nil, {BackgroundTransparency = 0})
                    else
                        OptionData.Accent1:Tween(nil, {BackgroundTransparency = 1, Size = UDim2New(0, 1, 0, 0)})
                        OptionData.Accent2:Tween(nil, {BackgroundTransparency = 1, Size = UDim2New(0, 1, 0, 0)})
                        OptionData.Text:ChangeItemTheme({TextColor3 = function()
                            return FromRGB(74, 74, 74)
                        end})
                        OptionData.Text:Tween(nil, {TextColor3 = FromRGB(74, 74, 74)})
                        OptionData.Background:Tween(nil, {BackgroundTransparency = 1})
                    end
                end

                function OptionData:OnHover()
                    if OptionData.Selected then return end
                    OptionData.Text:Tween(nil, {TextColor3 = FromRGB(126, 126, 126)})
                end

                function OptionData:OnHoverLeave()
                    if OptionData.Selected then return end
                    OptionData.Text:Tween(nil, {TextColor3 = FromRGB(74, 74, 74)})
                end

                OptionData.Button:OnHover(OptionData.OnHover)
                OptionData.Button:OnHoverLeave(OptionData.OnHoverLeave)

                function OptionData:Set()
                    OptionData.Selected = not OptionData.Selected

                    if Dropdown.Multi then 
                        local Index = TableFind(Dropdown.Value, OptionData.Name)

                        if Index then 
                            TableRemove(Dropdown.Value, Index)
                        else
                            TableInsert(Dropdown.Value, OptionData.Name)
                        end

                        OptionData:Toggle(Index and "Inactive" or "Active")

                        Library.Flags[Dropdown.Flag] = Dropdown.Value

                        local TextFormat = #Dropdown.Value > 0 and TableConcat(Dropdown.Value, ", ") or "--"
                        Items["Value"].Instance.Text = TextFormat
                    else
                        if OptionData.Selected then 
                            Dropdown.Value = OptionData.Name
                            Library.Flags[Dropdown.Flag] = OptionData.Name

                            OptionData.Selected = true
                            OptionData:Toggle("Active")

                            for Index, Value in Dropdown.Options do 
                                if Value ~= OptionData then
                                    Value.Selected = false 
                                    Value:Toggle("Inactive")
                                end
                            end

                            Items["Value"].Instance.Text = OptionData.Name
                        else
                            Dropdown.Value = nil
                            Library.Flags[Dropdown.Flag] = nil

                            OptionData.Selected = false
                            OptionData:Toggle("Inactive")

                            Items["Value"].Instance.Text = "--"
                        end
                    end

                    if Dropdown.Callback then
                        Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                    end
                end

                OptionData.Button:Connect("MouseButton1Down", function()
                    OptionData:Set()
                end)

                Dropdown.Options[OptionData.Name] = OptionData
                return OptionData
            end

            function Dropdown:Set(Option)
                if Dropdown.Multi then 
                    if type(Option) ~= "table" then 
                        return
                    end

                    Dropdown.Value = Option
                    Library.Flags[Dropdown.Flag] = Option

                    for Index, Value in Option do
                        local OptionData = Dropdown.Options[Value]
                        
                        if not OptionData then
                            continue
                        end

                        OptionData.Selected = true 
                        OptionData:Toggle("Active")
                    end

                    Items["Value"].Instance.Text = TableConcat(Option, ", ")
                else
                    if not Dropdown.Options[Option] then
                        return
                    end

                    local OptionData = Dropdown.Options[Option]

                    Dropdown.Value = Option
                    Library.Flags[Dropdown.Flag] = Option

                    for Index, Value in Dropdown.Options do
                        if Value ~= OptionData then
                            Value.Selected = false 
                            Value:Toggle("Inactive")
                        else
                            Value.Selected = true 
                            Value:Toggle("Active")
                        end
                    end

                    Items["Value"].Instance.Text = Option
                end

                if Dropdown.Callback then   
                    Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                end
            end

            function Dropdown:Remove(Option)
                if not Dropdown.Options[Option] then
                    return
                end

                Dropdown.Options[Option].Button:Clean()
                Dropdown.Options[Option] = nil
            end

            function Dropdown:Refresh(List)
                for Index, Value in Dropdown.Options do 
                    Dropdown:Remove(Value.Name)
                end

                for Index, Value in List do 
                    Dropdown:Add(Value)
                end
            end

            local CompareVectors = function(PointA, PointB)
                return (PointA.X < PointB.X) or (PointA.Y < PointB.Y)
            end

            local IsClipped = function(Object, Column)
                local Parent = Column
                
                local BoundryTop = Parent.AbsolutePosition
                local BoundryBottom = BoundryTop + Parent.AbsoluteSize

                local Top = Object.AbsolutePosition
                local Bottom = Top + Object.AbsoluteSize 

                return CompareVectors(Top, BoundryTop) or CompareVectors(BoundryBottom, Bottom)
            end

            Items["Indicator"]:Connect("Changed", function(Property)
                if Property == "AbsolutePosition" and Dropdown.IsOpen then
                    Dropdown.IsOpen = not IsClipped(Items["DropdownHolder"].Instance, Dropdown.Section.Items["Outline"].Instance.Parent)
                    Items["DropdownHolder"].Instance.Visible = Dropdown.IsOpen
                end
            end)

            Items["Indicator"]:Connect("MouseButton1Down", function()
                Dropdown:SetOpen(not Dropdown.IsOpen)
            end)

            Library:Connect(UserInputService.InputBegan, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if not Dropdown.IsOpen then
                        return 
                    end

                    if Library:IsMouseOverFrame(Items["DropdownHolder"]) then 
                        return
                    end

                    Dropdown:SetOpen(false)
                end
            end)

            for Index, Value in Dropdown.Items do
                Dropdown:Add(Value)
            end

            if Dropdown.Default then 
                Dropdown:Set(Dropdown.Default)
            end

            Library.SetFlags[Dropdown.Flag] = function(Value)
                Dropdown:Set(Value)
            end

            return Dropdown
        end

        Library.Sections.Label = function(self, Text)
            local Label = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Text or "Label"
            }

            local Items = { } do
                Items["Label"] = Instances:Create("Frame", {
                    Parent = Label.Section.Items["ElementsHolder"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Label"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(74, 74, 74),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Label.Name,
                    Size = UDim2New(0, 0, 0, 13),
                    Position = UDim2New(0, 17, 0, -2),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["EXAMPLAR_"] = Instances:Create("Frame", {
                    Parent = Items["Label"].Instance,
                    Name = "\0",
                    Position = UDim2New(1, -8, 0, -2),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 0, 1, 0),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIListLayout", {
                    Parent = Items["EXAMPLAR_"].Instance,
                    Name = "\0",
                    VerticalAlignment = Enum.VerticalAlignment.Bottom,
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    Padding = UDimNew(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })                
            end

            function Label:SetText(Text)
                Text = tostring(Text)
                Items["Text"].Instance.Text = Text
            end

            function Label:SetVisibility(Bool)
                Items["Label"].Instance.Visible = Bool
            end
            
            function Label:Colorpicker(Data)
                Data = Data or { }

                local Colorpicker = {
                    Window = Label.Section.Window,
                    Page = Label.Section.Page,
                    Section = Label.Section,

                    Flag = Data.Flag or Data.flag or Library:NextFlag(),
                    Default = Data.Default or Data.default or Color3.fromRGB(255, 255, 255),
                    Alpha = Data.Alpha or Data.alpha or 0,
                    Callback = Data.Callback or Data.callback or function() end
                }

                local NewColorpicker, ColorpickerItems = Library:CreateColorpicker({
                    Parent = Items["EXAMPLAR_"],
                    Page = Colorpicker.Page,
                    Flag = Colorpicker.Flag,
                    Section = Colorpicker.Section,
                    Default = Colorpicker.Default,
                    Alpha = Colorpicker.Alpha,
                    Callback = Colorpicker.Callback,
                })

                return NewColorpicker
            end

            function Label:Keybind(Data)
                Data = Data or { }

                local Keybind = {
                    Window = Label.Window,
                    Page = Label.Page,
                    Section = Label.Section,

                    Name = Data.Name or Data.name or Label.Name,
                    Flag = Data.Flag or Data.flag or Library:NextFlag(),
                    Default = Data.Default or Data.default or Enum.KeyCode.RightShift,
                    Callback = Data.Callback or Data.callback or function() end,
                    Mode = Data.Mode or Data.mode or "Toggle",
                }

                local NewKeybind = Library:CreateKeybind({
                    Name = Keybind.Name,
                    Parent = Items["EXAMPLAR_"],
                    Flag = Keybind.Flag,
                    Section = Keybind.Section,
                    Default = Keybind.Default,
                    Mode = Keybind.Mode,
                    Callback = Keybind.Callback
                })

                return NewKeybind
            end

            return Label 
        end

        Library.Sections.Textbox = function(self, Data)
            Data = Data or { }

            local Textbox = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Default = Data.Default or Data.default or "",
                Callback = Data.Callback or Data.callback or function() end,
                Placeholder = Data.Placeholder or Data.placeholder or "Placeholder",
                Numeric = Data.Numeric or Data.numeric or false,
                Finished = Data.Finished or Data.finished or false,

                Value = ""
            }

            local Items = { } do
                Items["Textbox"] = Instances:Create("Frame", {
                    Parent = Textbox.Section.Items["ElementsHolder"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 1, 0, 1),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, -2, 0, 20),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(20, 20, 20)
                })
                
                Items["Input"] = Instances:Create("TextBox", {
                    Parent = Items["Textbox"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(221, 221, 221),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    ClipsDescendants = true,
                    Size = UDim2New(1, -50, 1, 0),
                    Position = UDim2New(0, 17, 0, 0),
                    PlaceholderColor3 = FromRGB(74, 74, 74),
                    CursorPosition = -1,
                    PlaceholderText = Textbox.Placeholder,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(20, 20, 20)
                })
                
                Instances:Create("UIPadding", {
                    Parent = Items["Input"].Instance,
                    Name = "\0",
                    PaddingLeft = UDimNew(0, 8)
                })                
            end
            
            function Textbox:Get()
                return Textbox.Value
            end

            function Textbox:SetVisibility(Bool)
                Items["Textbox"].Instance.Visible = Bool
            end

            function Textbox:Set(Value)
                if Textbox.Numeric then
                    if (not tonumber(Value)) and StringLen(tostring(Value)) > 0 then
                        Value = Textbox.Value
                    end
                end

                Textbox.Value = Value
                Items["Input"].Instance.Text = Value
                Library.Flags[Textbox.Flag] = Value

                if Textbox.Callback then
                    Library:SafeCall(Textbox.Callback, Value)
                end
            end
            
            if Textbox.Finished then 
                Items["Input"]:Connect("FocusLost", function(PressedEnterQuestionMark)
                    if PressedEnterQuestionMark then
                        Textbox:Set(Items["Input"].Instance.Text)
                    end
                end)
            else
                Items["Input"].Instance:GetPropertyChangedSignal("Text"):Connect(function()
                    Textbox:Set(Items["Input"].Instance.Text)
                end)
            end

            if Textbox.Default then
                Textbox:Set(Textbox.Default)
            end

            Library.SetFlags[Textbox.Flag] = function(Value)
                Textbox:Set(Value)
            end

            return Textbox
        end

        Library.Sections.Searchbox = function(self, Data) -- dropdowns but diff elements lol hahaha im not recoding it
            Data = Data or { }

            local Dropdown = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Dropdown",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Default = Data.Default or Data.default or "",
                Multi = Data.Multi or Data.multi or false,
                Items = Data.Items or Data.items or { },
                Callback = Data.Callback or Data.callback or function() end,

                Options = { },
                Value = { },
                IsOpen = false
            }

            local Items = { } do 
                Items["List"] = Instances:Create("Frame", {
                    Parent = Dropdown.Section.Items["ElementsHolder"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 0, 200),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["List"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(221, 221, 221),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Dropdown.Name,
                    Size = UDim2New(0, 0, 0, 13),
                    Position = UDim2New(0, 17, 0, -2),
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["ListBackground"] = Instances:Create("Frame", {
                    Parent = Items["List"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, 17, 0, 22),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, -50, 1, -22),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(0, 0, 0)
                })
                
                Items["Search"] = Instances:Create("Frame", {
                    Parent = Items["ListBackground"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, 1, 0, 1),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, -2, 0, 20),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(20, 20, 20)
                })
                
                Items["Input"] = Instances:Create("TextBox", {
                    Parent = Items["Search"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(221, 221, 221),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    Size = UDim2New(1, -16, 1, 0),
                    Position = UDim2New(0, 8, 0, 0),
                    ClipsDescendants = true,
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    PlaceholderColor3 = FromRGB(74, 74, 74),
                    CursorPosition = -1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["ListInline"] = Instances:Create("Frame", {
                    Parent = Items["ListBackground"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, 2, 0, 22),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, -4, 1, -24),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(18, 18, 18)
                })
                
                Instances:Create("UIStroke", {
                    Parent = Items["ListInline"].Instance,
                    Name = "\0",
                    Color = FromRGB(35, 35, 35),
                    LineJoinMode = Enum.LineJoinMode.Miter,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })
                
                Items["OptionHolder"] = Instances:Create("ScrollingFrame", {
                    Parent = Items["ListInline"].Instance,
                    Name = "\0",
                    ScrollBarImageColor3 = FromRGB(0, 0, 0),
                    Active = true,
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 0,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 1, 0),
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    CanvasSize = UDim2New(0, 0, 0, 0)
                })
                
                Instances:Create("UIListLayout", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    SortOrder = Enum.SortOrder.LayoutOrder
                })                
            end

            function Dropdown:SetVisibility(Bool)
                Items["List"].Instance.Visible = Bool
            end

            function Dropdown:Add(Option)
                local OptionItems = { } do 
                    OptionItems["Disabled"] = Instances:Create("TextButton", {
                        Parent = Items["OptionHolder"].Instance,
                        Name = "\0",
                        Text = "",
                        AutoButtonColor = false,
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(0, 0, 0),
                        TextTransparency = 1,
                        Size = UDim2New(1, 0, 0, 25),
                        Selectable = true,
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        BorderColor3 = FromRGB(0, 0, 0),
                        Active = true,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })
                    
                    OptionItems["Accent1"] = Instances:Create("Frame", {
                        Parent = OptionItems["Disabled"].Instance,
                        Name = "\0",
                        BackgroundTransparency = 1,
                        Size = UDim2New(0, 1, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0, 0.5),
                        Position = UDim2New(0, 0, 0.5, 0),
                        ZIndex = 1,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(166, 147, 243)
                    })  OptionItems["Accent1"]:AddToTheme({BackgroundColor3 = "Accent"})
                    
                    OptionItems["Accent2"] = Instances:Create("Frame", {
                        Parent = OptionItems["Disabled"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        BackgroundTransparency = 1,
                        Position = UDim2New(0, 1, 0.5, 0),
                        AnchorPoint = Vector2New(0, 0.5),
                        ZIndex = 1,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(110, 97, 161)
                    })  OptionItems["Accent2"]:AddToTheme({BackgroundColor3 = "Dark Accent"})
                    
                    OptionItems["Text"] = Instances:Create("TextLabel", {
                        Parent = OptionItems["Disabled"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(74, 74, 74),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = Option,
                        AnchorPoint = Vector2New(0, 0.5),
                        Size = UDim2New(0, 0, 0, 15),
                        BackgroundTransparency = 1,
                        Position = UDim2New(0, 10, 0.5, -2),
                        BorderSizePixel = 0,
                        AutomaticSize = Enum.AutomaticSize.X,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  OptionItems["Text"]:AddToTheme({TextColor3 = function()
                        return FromRGB(74, 74, 74)
                    end})
                    
                    OptionItems["Background"] = Instances:Create("Frame", {
                        Parent = OptionItems["Disabled"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        Size = UDim2New(1, 0, 1, 0),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })
                    
                    Instances:Create("UIGradient", {
                        Parent = OptionItems["Background"].Instance,
                        Name = "\0",
                        Transparency = NumSequence{NumSequenceKeypoint(0, 0.956250011920929), NumSequenceKeypoint(0.06, 0.9750000238418579), NumSequenceKeypoint(0.739, 1), NumSequenceKeypoint(1, 1)}
                    })                    
                end
                
                local OptionData = {
                    Button = OptionItems["Disabled"],
                    Accent1 = OptionItems["Accent1"],
                    Accent2 = OptionItems["Accent2"],
                    Text = OptionItems["Text"],
                    Background = OptionItems["Background"],
                    Name = Option,
                    Selected = false
                }

                function OptionData:Toggle(Status)
                    if Status == "Active" then 
                        OptionData.Accent1:Tween(nil, {BackgroundTransparency = 0, Size = UDim2New(0, 1, 1, 0)})
                        OptionData.Accent2:Tween(nil, {BackgroundTransparency = 0, Size = UDim2New(0, 1, 1, 0)})
                        OptionData.Text:ChangeItemTheme({TextColor3 = "Accent"})
                        OptionData.Text:Tween(nil, {TextColor3 = Library.Theme.Accent})
                        OptionData.Background:Tween(nil, {BackgroundTransparency = 0})
                    else
                        OptionData.Accent1:Tween(nil, {BackgroundTransparency = 1, Size = UDim2New(0, 1, 0, 0)})
                        OptionData.Accent2:Tween(nil, {BackgroundTransparency = 1, Size = UDim2New(0, 1, 0, 0)})
                        OptionData.Text:ChangeItemTheme({TextColor3 = function()
                            return FromRGB(74, 74, 74)
                        end})
                        OptionData.Text:Tween(nil, {TextColor3 = FromRGB(74, 74, 74)})
                        OptionData.Background:Tween(nil, {BackgroundTransparency = 1})
                    end
                end

                function OptionData:OnHover()
                    if OptionData.Selected then return end
                    OptionData.Text:Tween(nil, {TextColor3 = FromRGB(126, 126, 126)})
                end

                function OptionData:OnHoverLeave()
                    if OptionData.Selected then return end
                    OptionData.Text:Tween(nil, {TextColor3 = FromRGB(74, 74, 74)})
                end

                OptionData.Button:OnHover(OptionData.OnHover)
                OptionData.Button:OnHoverLeave(OptionData.OnHoverLeave)

                function OptionData:Set()
                    OptionData.Selected = not OptionData.Selected

                    if Dropdown.Multi then 
                        local Index = TableFind(Dropdown.Value, OptionData.Name)

                        if Index then 
                            TableRemove(Dropdown.Value, Index)
                        else
                            TableInsert(Dropdown.Value, OptionData.Name)
                        end

                        OptionData:Toggle(Index and "Inactive" or "Active")

                        Library.Flags[Dropdown.Flag] = Dropdown.Value
                    else
                        if OptionData.Selected then 
                            Dropdown.Value = OptionData.Name
                            Library.Flags[Dropdown.Flag] = OptionData.Name

                            OptionData.Selected = true
                            OptionData:Toggle("Active")

                            for Index, Value in Dropdown.Options do 
                                if Value ~= OptionData then
                                    Value.Selected = false 
                                    Value:Toggle("Inactive")
                                end
                            end
                        else
                            Dropdown.Value = nil
                            Library.Flags[Dropdown.Flag] = nil

                            OptionData.Selected = false
                            OptionData:Toggle("Inactive")
                        end
                    end

                    if Dropdown.Callback then
                        Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                    end
                end

                OptionData.Button:Connect("MouseButton1Down", function()
                    OptionData:Set()
                end)

                Dropdown.Options[OptionData.Name] = OptionData
                return OptionData
            end

            function Dropdown:Set(Option)
                if Dropdown.Multi then 
                    if type(Option) ~= "table" then 
                        return
                    end

                    Dropdown.Value = Option
                    Library.Flags[Dropdown.Flag] = Option

                    for Index, Value in Option do
                        local OptionData = Dropdown.Options[Value]
                        
                        if not OptionData then
                            continue
                        end

                        OptionData.Selected = true 
                        OptionData:Toggle("Active")
                    end
                else
                    if not Dropdown.Options[Option] then
                        return
                    end

                    local OptionData = Dropdown.Options[Option]

                    Dropdown.Value = Option
                    Library.Flags[Dropdown.Flag] = Option

                    for Index, Value in Dropdown.Options do
                        if Value ~= OptionData then
                            Value.Selected = false 
                            Value:Toggle("Inactive")
                        else
                            Value.Selected = true 
                            Value:Toggle("Active")
                        end
                    end
                end

                if Dropdown.Callback then   
                    Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                end
            end

            function Dropdown:Remove(Option)
                if not Dropdown.Options[Option] then
                    return
                end

                Dropdown.Options[Option].Button:Clean()
                Dropdown.Options[Option] = nil
            end

            function Dropdown:Refresh(List)
                for Index, Value in Dropdown.Options do 
                    Dropdown:Remove(Value.Name)
                end

                for Index, Value in List do 
                    Dropdown:Add(Value)
                end
            end

            local SearchStepped

            Items["Input"]:Connect("Focused", function()
                SearchStepped = RunService.RenderStepped:Connect(function()
                    for Index, Value in Dropdown.Options do
                        if StringFind(StringLower(Value.Name), StringLower(Items["Input"].Instance.Text)) then
                            Value.Button.Instance.Visible = true
                        else
                            Value.Button.Instance.Visible = false
                        end
                    end
                end)
            end)

            Items["Input"]:Connect("FocusLost", function()
                SearchStepped:Disconnect()
            end)

            for Index, Value in Dropdown.Items do
                Dropdown:Add(Value)
            end

            if Dropdown.Default then 
                Dropdown:Set(Dropdown.Default)
            end

            Library.SetFlags[Dropdown.Flag] = function(Value)
                Dropdown:Set(Value)
            end

            return Dropdown
        end
    end

    Library.CreateSettingsPage = function(self, Window, KeybindList, Watermark)
        local SettingsPage = Window:Page({Icon = "rbxassetid://101420508297304"})
        
        local MenuSubPage = SettingsPage:SubPage({Name = "Menu"})
        local ConfigsSubPage = SettingsPage:SubPage({Name = "Configs"})

        do -- Menu subpages
            local MenuSection = MenuSubPage:Section({Name = "Menu"}) do
                MenuSection:Toggle({Name = "Keybind List", Flag = "Keybind List", Default = true, Callback = function(Value)
                    KeybindList:SetVisibility(Value)
                end})

                MenuSection:Toggle({Name = "Watermark", Flag = "Watermark", Default = true, Callback = function(Value)
                    Watermark:SetVisibility(Value)
                end})

                MenuSection:Label("Menu Keybind"):Keybind({
                    Name = "UI",
                    Flag = "MenuKeybind",
                    Mode = "Toggle",
                    Default = Library.MenuKeybind,
                    Callback = function()
                        Library.MenuKeybind = Library.Flags["MenuKeybind"].Key
                    end
                })

                MenuSection:Slider({
                    Name = "Animation speed",
                    Flag = "Animation speed",
                    Default = Library.FadeSpeed,
                    Min = 0,
                    Max = 2,
                    Decimals = 0.01,
                    Callback = function(Value)
                        Library.FadeSpeed = Value
                    end
                })

                local AccentLabel = MenuSection:Label("Accent Color")
                AccentLabel:Colorpicker({
                    Flag = "AccentColor",
                    Default = Library.Theme.Accent,
                    Alpha = 0,
                    Callback = function(Value)
                        Library.Theme.Accent = Value
                        Library:ChangeTheme("Accent", Value)
                    end
                })

                AccentLabel:Colorpicker({
                    Flag = "DarkAccentColor",
                    Default = Library.Theme["Dark Accent"],
                    Alpha = 0,
                    Callback = function(Value)
                        Library.Theme["Dark Accent"]= Value
                        Library:ChangeTheme("Dark Accent", Value)
                    end
                })

                MenuSection:Button({Name = "Unload", Callback = function()
                    Library:Unload()
                end})
            end
        end

        do -- Config Subpages
            local ConfigsSection = ConfigsSubPage:Section({Name = "Profiles"}) do
                local ConfigName 
                local ConfigSelected
                
                local ConfigsSearchbox = ConfigsSection:Searchbox({
                    Name = "Profiles list",
                    Flag = "Profiles list",
                    Multi = false,
                    Items = { },
                    Callback = function(Value)
                        ConfigSelected = Value
                    end
                })

                ConfigsSection:Textbox({
                    Name = "Config name", 
                    Default = "", 
                    Flag = "ConfigName", 
                    Placeholder = "...", 
                    Callback = function(Value)
                        ConfigName = Value
                    end
                })

                ConfigsSection:Button({
                    Name = "Create",
                    Callback = function()
                        if ConfigName ~= "" then
                            if not isfile(Library.Folders.Configs .. "/" .. ConfigName .. ".json") then
                                writefile(Library.Folders.Configs .. "/" .. ConfigName .. ".json", Library:GetConfig())
                                Library:RefreshConfigsList(ConfigsSearchbox)
                                Library:Notification("Created config " .. ConfigName .. ".json", 5, FromRGB(0, 255, 0))
                            end
                        end
                    end
                })

                ConfigsSection:Button({
                    Name = "Delete",
                    Callback = function()
                        if ConfigSelected ~= nil then
                            delfile(Library.Folders.Configs .. "/" .. ConfigSelected .. ".json")
                            Library:RefreshConfigsList(ConfigsSearchbox)
                            Library:Notification("Deleted config " .. ConfigSelected .. ".json", 5, FromRGB(255, 0, 0))
                        end
                    end
                })

                ConfigsSection:Button({
                    Name = "Load",
                    Callback = function()
                        if ConfigSelected ~= nil then
                            local Success, Result = Library:LoadConfig(readfile(Library.Folders.Configs .. "/" .. ConfigSelected .. ".json"))
                            if Success then
                                Library:Notification("Loaded config " .. ConfigSelected .. ".json", 5, FromRGB(0, 255, 0))
                            else
                                Library:Notification("Failed to load config " .. ConfigSelected .. ".json", 5, FromRGB(255, 0, 0))
                            end
                        end
                    end
                })

                ConfigsSection:Button({
                    Name = "Save",
                    Callback = function()
                        if ConfigSelected ~= nil then
                            writefile(Library.Folders.Configs .. "/" .. ConfigSelected .. ".json", Library:GetConfig())
                            Library:Notification("Saved config " .. ConfigSelected .. ".json", 5, FromRGB(0, 255, 0))
                        end
                    end
                })

                ConfigsSection:Button({
                    Name = "Refresh",
                    Callback = function()
                        Library:RefreshConfigsList(ConfigsSearchbox)
                    end
                })

                Library:RefreshConfigsList(ConfigsSearchbox)
            end
        end
    end
end

getgenv().Library = Library
return Library
