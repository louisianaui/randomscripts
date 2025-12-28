local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game.Workspace

local Obsidian = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"))()

local Window = Obsidian:CreateWindow({
    Title = "Universal by usagiinc",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Visuals = Window:AddTab("Visuals"),
    Misc = Window:AddTab("Misc"),
    Config = Window:AddTab("Config")
}

--// FOV HANDLER
local fovValue = nil
local fovLoop = nil

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

--// ESP HANDLER
local espEnabled = false
local espHighlights = {}

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

--// ANTILAG HANDLER
local function optimizeGraphics()
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("MeshPart") then
            part.Material = Enum.Material.SmoothPlastic
            for _, child in ipairs(part:GetChildren()) do
                if child:IsA("Decal") then
                    child:Destroy()
                end
            end
        end
    end
    
    Lighting.GlobalShadows = false
    Lighting.ShadowSoftness = 0
    Lighting.ClockTime = 14
    Lighting.Brightness = 0
    Lighting.Ambient = Color3.new(0, 0, 0)
    Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
    Lighting.FogEnd = 1000000
end

--// VISUALS TAB
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
        Obsidian:Notify("FOV Reset", "Field of View reset to default (70).")
    end)
    
    ESPGroupbox:AddToggle("ESP", {
        Text = "Enable ESP",
        Default = false,
        Callback = toggleESP
    })
    
    ESPGroupbox:AddLabel("Displays player outlines")
end

--// MISC TAB
do
    local OptimizationGroupbox = Tabs.Misc:AddLeftGroupbox("Optimization")
    
    OptimizationGroupbox:AddButton("AntiLag", function()
        optimizeGraphics()
        Obsidian:Notify("AntiLag", "Graphics optimized for performance.")
    end)
    
    OptimizationGroupbox:AddLabel("Removes textures & optimizes lighting")
end

--// CONFIG TAB
do
    local MenuGroupbox = Tabs.Config:AddLeftGroupbox("Menu")
    local ConfigGroupbox = Tabs.Config:AddRightGroupbox("Configuration")
    
    MenuGroupbox:AddButton("Unload", function()
        Window:Close()
    end)
    
    local MenuKeybindLabel = MenuGroupbox:AddLabel("Menu bind")
    MenuKeybindLabel:AddKeyPicker("MenuKeybind", {
        Default = "RightShift",
        NoUI = false,
        Text = "Menu keybind"
    })
    
    Window:SetKeybind(Options.MenuKeybind.Value)
    
    Obsidian.ThemeManager:SetFolder("Universal")
    Obsidian.SaveManager:SetFolder("Universal/Config")
    Obsidian.SaveManager:IgnoreThemeSettings()
    Obsidian.SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
    
    Obsidian.ThemeManager:BuildInterfaceSection(ConfigGroupbox)
    Obsidian.SaveManager:BuildConfigSection(ConfigGroupbox)
    Obsidian.ThemeManager:ApplyToTab(Tabs.Config)
    
    MenuGroupbox:AddButton("Save", function()
        Obsidian.SaveManager:Save("UniversalConfig")
        Obsidian:Notify("Settings Saved", "Configuration saved successfully.")
    end)
    
    MenuGroupbox:AddButton("Load", function()
        Obsidian.SaveManager:Load("UniversalConfig")
        Obsidian:Notify("Settings Loaded", "Configuration loaded successfully.")
    end)
end

--// EVENT HANDLERS
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

Obsidian:Notify("Universal", "Script loaded successfully by usagiinc")
