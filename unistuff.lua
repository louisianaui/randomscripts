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
local espLoop = nil

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

-- SIMPLE HIGHLIGHT ESP SYSTEM
local function createHighlight(targetPlayer)
    if espHighlights[targetPlayer] then return end
    
    local character = targetPlayer.Character
    if not character then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = Color3.fromRGB(255, 50, 50) -- Red for enemies
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.Parent = character
    
    espHighlights[targetPlayer] = {
        highlight = highlight,
        player = targetPlayer
    }
    
    -- Listen for character changes (respawns)
    local characterAddedConnection
    characterAddedConnection = targetPlayer.CharacterAdded:Connect(function(newCharacter)
        if espHighlights[targetPlayer] and espHighlights[targetPlayer].highlight then
            espHighlights[targetPlayer].highlight:Destroy()
        end
        
        local newHighlight = Instance.new("Highlight")
        newHighlight.Name = "ESP_Highlight"
        newHighlight.Adornee = newCharacter
        newHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        newHighlight.FillColor = Color3.fromRGB(255, 255, 255)
        newHighlight.FillTransparency = 0.5
        newHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        newHighlight.OutlineTransparency = 0
        newHighlight.Parent = newCharacter
        
        espHighlights[targetPlayer].highlight = newHighlight
        espHighlights[targetPlayer].character = newCharacter
    end)
    
    -- Listen for character removal (death)
    local characterRemovingConnection
    characterRemovingConnection = targetPlayer.CharacterRemoving:Connect(function()
        if espHighlights[targetPlayer] and espHighlights[targetPlayer].highlight then
            espHighlights[targetPlayer].highlight:Destroy()
            espHighlights[targetPlayer].highlight = nil
        end
    end)
    
    -- Store connections for cleanup
    espHighlights[targetPlayer].connections = {
        characterAdded = characterAddedConnection,
        characterRemoving = characterRemovingConnection
    }
end

local function removeHighlight(targetPlayer)
    if espHighlights[targetPlayer] then
        -- Clean up highlight
        if espHighlights[targetPlayer].highlight then
            espHighlights[targetPlayer].highlight:Destroy()
        end
        
        -- Disconnect events
        if espHighlights[targetPlayer].connections then
            for _, connection in pairs(espHighlights[targetPlayer].connections) do
                if connection then
                    connection:Disconnect()
                end
            end
        end
        
        espHighlights[targetPlayer] = nil
    end
end

local function isEnemy(targetPlayer)
    -- Check if target is on a different team
    if targetPlayer.Team and player.Team then
        return targetPlayer.Team ~= player.Team
    end
    -- If no teams exist, consider everyone enemy except yourself
    return targetPlayer ~= player
end

local function updateHighlights()
    if not espEnabled then return end
    
    -- Update existing highlights based on team status
    for targetPlayer, data in pairs(espHighlights) do
        if targetPlayer and data and data.highlight then
            local shouldHighlight = isEnemy(targetPlayer)
            
            if shouldHighlight then
                -- Enemy - show highlight
                data.highlight.Enabled = true
                data.highlight.FillColor = Color3.fromRGB(255, 255, 255)
            else
                -- Teammate or self - hide highlight
                data.highlight.Enabled = false
            end
        end
    end
    
    -- Create highlights for new enemies
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer ~= player and isEnemy(targetPlayer) and not espHighlights[targetPlayer] then
            createHighlight(targetPlayer)
        end
    end
end

local function toggleESP(value)
    espEnabled = value
    
    if value then
        -- Start ESP loop
        if espLoop then
            espLoop:Disconnect()
        end
        
        espLoop = RunService.Heartbeat:Connect(function()
            updateHighlights()
        end)
        
        -- Initialize highlights for existing enemies
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer ~= player and isEnemy(targetPlayer) then
                createHighlight(targetPlayer)
            end
        end
        
    else
        -- Stop ESP loop
        if espLoop then
            espLoop:Disconnect()
            espLoop = nil
        end
        
        -- Clean up all highlights
        for targetPlayer, _ in pairs(espHighlights) do
            removeHighlight(targetPlayer)
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
        Text = "Enable Enemy Highlight",
        Default = false,
        Callback = toggleESP
    })

    ESPGroupbox:AddLabel("Highlights enemy players in red")
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
    if espEnabled then
        task.wait(1) -- Wait for character to load
        if isEnemy(newPlayer) then
            createHighlight(newPlayer)
        end
    end
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
    removeHighlight(leavingPlayer)
end)

-- Team change detection
local function monitorTeamChanges()
    while true do
        for targetPlayer, data in pairs(espHighlights) do
            if targetPlayer and targetPlayer.Team then
                -- Team property exists, check if highlight needs updating
                local wasEnemy = data.highlight and data.highlight.Enabled
                local isNowEnemy = isEnemy(targetPlayer)
                
                if wasEnemy ~= isNowEnemy then
                    -- Team status changed, update highlight
                    if data.highlight then
                        data.highlight.Enabled = isNowEnemy
                    end
                end
            end
        end
        wait(0.5) -- Check every 0.5 seconds
    end
end

-- Start team monitoring when ESP is enabled
local teamMonitorThread = nil
Toggles.ESP:OnChanged(function(value)
    if value then
        if teamMonitorThread then
            coroutine.close(teamMonitorThread)
        end
        teamMonitorThread = coroutine.create(monitorTeamChanges)
        coroutine.resume(teamMonitorThread)
    elseif teamMonitorThread then
        coroutine.close(teamMonitorThread)
        teamMonitorThread = nil
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
