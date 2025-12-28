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
local espHighlights = {}

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

-- ESP Handler (from unistuff)
local function toggleESP(value)
    espEnabled = value

    if value then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer and not espHighlights[player] then
                local highlight = Instance.new("Highlight")
                highlight.Parent = game.CoreGui
                highlight.FillColor = Color3.new(0, 0, 0)
                highlight.FillTransparency = 1
                highlight.OutlineColor = Color3.new(1, 1, 1)
                highlight.OutlineTransparency = 0

                espHighlights[player] = highlight

                local function updateCharacter()
                    highlight.Adornee = player.Character
                end

                updateCharacter()
                player.CharacterAdded:Connect(updateCharacter)
                player.CharacterRemoving:Connect(function()
                    highlight.Adornee = nil
                end)
            end
        end
    else
        for player, highlight in pairs(espHighlights) do
            highlight:Destroy()
        end
        espHighlights = {}
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

    ESPGroupbox:AddLabel("Displays player outlines")
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

-- CONFIG TAB (EXACT f.lua structure)
do
    local MenuGroupbox = Tabs.Config:AddLeftGroupbox("Menu")
    local ConfigGroupbox = Tabs.Config:AddRightGroupbox("Configuration")

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

    ThemeManager:SetFolder("Universal")
    SaveManager:SetFolder("Universal/Config")
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

    ThemeManager:BuildInterfaceSection(ConfigGroupbox)
    SaveManager:BuildConfigSection(ConfigGroupbox)
    ThemeManager:ApplyToTab(Tabs.Config)

    MenuGroupbox:AddButton("Save", function()
        SaveManager:Save("UniversalConfig")
        Library:Notify({
            Title = "Settings Saved",
            Description = "Configuration saved successfully.",
            Time = 2
        })
    end)

    MenuGroupbox:AddButton("Load", function()
        SaveManager:Load("UniversalConfig")
        Library:Notify({
            Title = "Settings Loaded",
            Description = "Configuration loaded successfully.",
            Time = 2
        })
    end)
end

-- Event Handlers
Players.PlayerAdded:Connect(function(player)
    if espEnabled and player ~= Players.LocalPlayer then
        task.wait(1)
        toggleESP(true)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if espHighlights[player] then
        espHighlights[player]:Destroy()
        espHighlights[player] = nil
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
