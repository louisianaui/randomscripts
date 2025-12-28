task.spawn(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
    print([[                                .
   ___                      __ __     __ 
  / _ )__ _____  ___  __ __/ // /_ __/ / 
 / _  / // / _ \/ _ \/ // / _  / // / _ \
/____/\_,_/_//_/_//_/\_, /_//_/\_,_/_.__/
                    /___/                
.]])
end)

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Repository = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(Repository .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repository .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(Repository .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local player = Players.LocalPlayer

-- System Variables
local fovValue = nil
local fovLoop = nil
local espEnabled = false
local espDrawings = {}

-- UI
local Window = Library:CreateWindow({
    Title = "Universal by usagiinc",
    Center = true,
    AutoShow = true,
    Size = UDim2.fromOffset(700, 500)
})

local Tabs = {
    Visuals = Window:AddTab("Visuals"),
    Misc = Window:AddTab("Misc"),
    Config = Window:AddTab("Config")
}

-- FOV Handler (from unistuff)
local function updateFOV(value)
    if fovLoop then fovLoop:Disconnect() fovLoop = nil end

    if value then
        fovValue = value
        Workspace.CurrentCamera.FieldOfView = fovValue

        fovLoop = RunService.RenderStepped:Connect(function()
            if Workspace.CurrentCamera.FieldOfView ~= fovValue then
                Workspace.CurrentCamera.FieldOfView = fovValue
            end
        end)
    else
        fovValue = nil
    end
end

-- SIMPLE BOX ESP SYSTEM - NEW
local function createDrawing(type, properties)
    local drawing = Drawing.new(type)
    for prop, value in pairs(properties) do
        drawing[prop] = value
    end
    return drawing
end

local function initESP(targetPlayer)
    if espDrawings[targetPlayer] then return end
    
    local drawings = {
        BoxOutline = createDrawing("Quad", {
            Visible = false,
            Color = Color3.new(0, 0, 0),
            Thickness = 2,
            Filled = false,
            Transparency = 1
        }),
        Box = createDrawing("Quad", {
            Visible = false,
            Color = Color3.fromRGB(255, 50, 50),
            Thickness = 1,
            Filled = false,
            Transparency = 1
        }),
        HealthBarOutline = createDrawing("Line", {
            Visible = false,
            Color = Color3.new(0, 0, 0),
            Thickness = 4,
            Transparency = 1
        }),
        HealthBar = createDrawing("Line", {
            Visible = false,
            Thickness = 2,
            Transparency = 1
        })
    }
    
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not espEnabled or not targetPlayer or not targetPlayer.Character then
            for _, drawing in pairs(drawings) do
                drawing.Visible = false
            end
            return
        end
        
        local character = targetPlayer.Character
        local humanoid = character:FindFirstChild("Humanoid")
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        
        if not humanoid or not humanoidRootPart or humanoid.Health <= 0 then
            for _, drawing in pairs(drawings) do
                drawing.Visible = false
            end
            return
        end
        
        local camera = Workspace.CurrentCamera
        local position, onScreen = camera:WorldToViewportPoint(humanoidRootPart.Position)
        
        if not onScreen then
            for _, drawing in pairs(drawings) do
                drawing.Visible = false
            end
            return
        end
        
        -- Calculate box size
        local distance = (camera.CFrame.Position - humanoidRootPart.Position).Magnitude
        local scale = math.clamp(1000 / distance, 0.5, 3)
        local width = 25 * scale
        local height = 45 * scale
        
        -- Box coordinates
        local topLeft = Vector2.new(position.X - width/2, position.Y - height/2)
        local topRight = Vector2.new(position.X + width/2, position.Y - height/2)
        local bottomLeft = Vector2.new(position.X - width/2, position.Y + height/2)
        local bottomRight = Vector2.new(position.X + width/2, position.Y + height/2)
        
        -- Update box
        drawings.BoxOutline.PointA = topLeft
        drawings.BoxOutline.PointB = topRight
        drawings.BoxOutline.PointC = bottomRight
        drawings.BoxOutline.PointD = bottomLeft
        
        drawings.Box.PointA = topLeft
        drawings.Box.PointB = topRight
        drawings.Box.PointC = bottomRight
        drawings.Box.PointD = bottomLeft
        
        -- Health bar
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        local healthHeight = height * healthPercent
        
        drawings.HealthBarOutline.From = Vector2.new(position.X - width/2 - 6, position.Y + height/2)
        drawings.HealthBarOutline.To = Vector2.new(position.X - width/2 - 6, position.Y - height/2)
        
        drawings.HealthBar.From = Vector2.new(position.X - width/2 - 6, position.Y + height/2)
        drawings.HealthBar.To = Vector2.new(position.X - width/2 - 6, position.Y + height/2 - healthHeight)
        
        -- Health bar color
        local green = Color3.fromRGB(0, 255, 0)
        local red = Color3.fromRGB(255, 0, 0)
        drawings.HealthBar.Color = red:lerp(green, healthPercent)
        
        -- Team color check
        if targetPlayer.Team and player.Team then
            if targetPlayer.Team == player.Team then
                drawings.Box.Color = Color3.fromRGB(50, 255, 50) -- Green for teammates
            else
                drawings.Box.Color = Color3.fromRGB(255, 50, 50) -- Red for enemies
            end
        end
        
        -- Show all drawings
        for _, drawing in pairs(drawings) do
            drawing.Visible = true
        end
    end)
    
    drawings.connection = connection
    espDrawings[targetPlayer] = drawings
end

local function removeESP(targetPlayer)
    if espDrawings[targetPlayer] then
        if espDrawings[targetPlayer].connection then
            espDrawings[targetPlayer].connection:Disconnect()
        end
        
        for name, drawing in pairs(espDrawings[targetPlayer]) do
            if name ~= "connection" and drawing and drawing.Remove then
                drawing:Remove()
            end
        end
        
        espDrawings[targetPlayer] = nil
    end
end

local function toggleESP(value)
    espEnabled = value
    
    if value then
        -- Initialize ESP for existing players
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer ~= player then
                initESP(targetPlayer)
            end
        end
    else
        -- Clean up all ESP drawings
        for targetPlayer, drawings in pairs(espDrawings) do
            removeESP(targetPlayer)
        end
    end
end

-- Anti-Lag Features (your requests)
local function removeLightingInstances()
    local count = 0
    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("PostEffect") or child:IsA("Atmosphere") or 
           child:IsA("BloomEffect") or child:IsA("BlurEffect") or 
           child:IsA("SunRaysEffect") then
            child:Destroy()
            count = count + 1
        end
    end
    return count
end

local function removeTextures()
    local count = 0
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("MeshPart") then
            part.Material = Enum.Material.SmoothPlastic
            for _, child in ipairs(part:GetChildren()) do
                if child:IsA("Decal") or child:IsA("Texture") then
                    child:Destroy()
                    count = count + 1
                end
            end
        end
    end
    return count
end

-- VISUALS TAB
do
    local CameraGroupbox = Tabs.Visuals:AddLeftGroupbox("Camera")
    local ESPGroupbox = Tabs.Visuals:AddRightGroupbox("ESP")

    CameraGroupbox:AddInput("FOV", {
        Default = "70",
        Numeric = true,
        Finished = false,
        Text = "Field of View",
        Placeholder = "70",
        Callback = function(value)
            updateFOV(tonumber(value))
        end
    })

    CameraGroupbox:AddButton("Reset FOV", function()
        updateFOV(70)
        Library:Notify({
            Title = "FOV Reset",
            Description = "Field of View reset to default (70).",
            Time = 2
        })
    end)

    ESPGroupbox:AddToggle("ESP", {
        Text = "Enable ESP",
        Default = false,
        Callback = toggleESP
    })

    ESPGroupbox:AddLabel("Simple 2D Box ESP with Health Bars")
end

-- MISC TAB
do
    local AntiLagGroupbox = Tabs.Misc:AddLeftGroupbox("AntiLag")
    local TimeGroupbox = Tabs.Misc:AddRightGroupbox("Time")

    AntiLagGroupbox:AddButton("Remove Lighting Instances", function()
        local count = removeLightingInstances()
        Library:Notify({
            Title = "Lighting Cleanup",
            Description = "Removed " .. count .. " lighting instances",
            Time = 2
        })
    end)

    AntiLagGroupbox:AddButton("Remove Textures/Decals", function()
        local count = removeTextures()
        Library:Notify({
            Title = "Texture Removal",
            Description = "Removed " .. count .. " textures/decals",
            Time = 2
        })
    end)

    AntiLagGroupbox:AddLabel("Removes post-effects and textures")

    TimeGroupbox:AddSlider("TimeOfDay", {
        Text = "Time of Day",
        Default = 14,
        Min = 0,
        Max = 24,
        Rounding = 1,
        Compact = true,
        Suffix = ":00",
        Callback = function(value)
            Lighting.ClockTime = value
        end
    })

    TimeGroupbox:AddButton("Reset Time", function()
        Options.TimeOfDay:SetValue(14)
        Lighting.ClockTime = 14
        Library:Notify({
            Title = "Time Reset",
            Description = "Time reset to 14:00",
            Time = 2
        })
    end)
end

--// config tab
do
    local MenuGroupbox = Tabs.Config:AddLeftGroupbox("Menu")
    
    MenuGroupbox:AddButton("Unload", function()
        Library:Unload()
    end)

    local MenuKeybindLabel = MenuGroupbox:AddLabel("Menu bind")
    MenuKeybindLabel:AddKeyPicker("MenuKeybind", {
        Default = "RightShift",
        NoUI = false,
        Text = "Menu keybind"
    })

    Library.ToggleKeybind = Options.MenuKeybind

    -- Simple save system (no broken SaveManager)
    local SettingsGroupbox = Tabs.Config:AddRightGroupbox("Settings")
    
    SettingsGroupbox:AddButton("Save Settings", function()
        local settings = {
            ESP = Toggles.ESP.Value,
            TimeOfDay = Options.TimeOfDay.Value,
            FOV = fovValue or 70
        }
        
        writefile("Universal_Settings.txt", game:GetService("HttpService"):JSONEncode(settings))
        Library:Notify({
            Title = "Settings Saved",
            Description = "Configuration saved to file.",
            Time = 2
        })
    end)

    SettingsGroupbox:AddButton("Load Settings", function()
        if isfile("Universal_Settings.txt") then
            local success, settings = pcall(function()
                return game:GetService("HttpService"):JSONDecode(readfile("Universal_Settings.txt"))
            end)
            
            if success and settings then
                if settings.ESP ~= nil then
                    Toggles.ESP:SetValue(settings.ESP)
                end
                if settings.TimeOfDay ~= nil then
                    Options.TimeOfDay:SetValue(settings.TimeOfDay)
                end
                if settings.FOV ~= nil then
                    updateFOV(settings.FOV)
                end
                
                Library:Notify({
                    Title = "Settings Loaded",
                    Description = "Configuration loaded from file.",
                    Time = 2
                })
            end
        else
            Library:Notify({
                Title = "No Settings",
                Description = "No saved settings found.",
                Time = 2
            })
        end
    end)
end

-- Event Handlers
Players.PlayerAdded:Connect(function(newPlayer)
    if espEnabled and newPlayer ~= player then
        task.wait(1)
        initESP(newPlayer)
    end
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
    if espDrawings[leavingPlayer] then
        removeESP(leavingPlayer)
    end
end)

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if fovValue and fovLoop then
        Workspace.CurrentCamera.FieldOfView = fovValue
    end
end)

Library:Notify({
    Title = "Universal",
    Description = "Script loaded successfully by usagiinc",
    Time = 3
})
