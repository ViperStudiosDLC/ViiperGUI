--[[
VIPER GUI - visual-only Roblox client interface
Install as a LocalScript in StarterPlayer > StarterPlayerScripts
(or in StarterGui). Designed for an experience you own or are authorized to edit.

Notes:
- This is a normal Roblox LocalScript, not an executor payload.
- Roblox ImageLabels cannot display arbitrary GitHub GIF URLs.
  To use your wallpapers, upload each image to Roblox and replace the
  placeholder rbxassetid://0 values in WALLPAPERS below.
- Visual effects change Lighting locally on this client only.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GUI_NAME = "VIPER_GUI"
local old = playerGui:FindFirstChild(GUI_NAME)
if old then old:Destroy() end

local WALLPAPERS = {
    Ocean = "rbxassetid://0",       -- replace with your uploaded Ocean image ID
    Fireplace = "rbxassetid://0",   -- replace with your uploaded fireplace image ID
    Snowfall = "rbxassetid://0",    -- replace with your uploaded snowfall image ID
}

local themes = {
    Dark = {bg=Color3.fromRGB(13,15,23), panel=Color3.fromRGB(22,25,37), text=Color3.fromRGB(241,243,250), muted=Color3.fromRGB(151,159,180), accent=Color3.fromRGB(151,105,255), stroke=Color3.fromRGB(62,55,91)},
    Light = {bg=Color3.fromRGB(235,238,248), panel=Color3.fromRGB(250,251,255), text=Color3.fromRGB(28,30,44), muted=Color3.fromRGB(100,105,125), accent=Color3.fromRGB(111,75,220), stroke=Color3.fromRGB(204,207,224)},
    Midnight = {bg=Color3.fromRGB(5,9,20), panel=Color3.fromRGB(12,19,36), text=Color3.fromRGB(225,239,255), muted=Color3.fromRGB(117,148,180), accent=Color3.fromRGB(61,178,255), stroke=Color3.fromRGB(35,83,120)},
}

local currentTheme = "Dark"
local accentColor = themes.Dark.accent
local currentWallpaper = "None"
local effectsEnabled = false
local crosshairEnabled = true
local fpsEnabled = true
local snowEnabled = false
local guiVisible = true
local selectedTab = "Home"

local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.new(1,1,1)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = parent
    return s
end

local function make(className, props, parent)
    local obj = Instance.new(className)
    for k,v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local main = make("Frame", {
    Name="Main", AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5),
    Size=UDim2.fromOffset(760,500), BackgroundColor3=themes.Dark.bg, BorderSizePixel=0,
}, gui)
corner(main, 18)
local mainStroke = stroke(main, themes.Dark.stroke, 1.2, 0.1)

local scale = Instance.new("UIScale")
scale.Scale = math.clamp(math.min(workspace.CurrentCamera.ViewportSize.X/900, workspace.CurrentCamera.ViewportSize.Y/650), 0.68, 1)
scale.Parent = main
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    local v = workspace.CurrentCamera.ViewportSize
    scale.Scale = math.clamp(math.min(v.X/900, v.Y/650), 0.58, 1)
end)

local top = make("Frame", {Name="Topbar", Size=UDim2.new(1,0,0,62), BackgroundTransparency=1}, main)
local logo = make("TextLabel", {
    BackgroundTransparency=1, Position=UDim2.fromOffset(22,8), Size=UDim2.fromOffset(170,28),
    Font=Enum.Font.GothamBlack, Text="V I P E R", TextSize=21, TextXAlignment=Enum.TextXAlignment.Left,
    TextColor3=accentColor,
}, top)
make("TextLabel", {
    BackgroundTransparency=1, Position=UDim2.fromOffset(23,34), Size=UDim2.fromOffset(220,16),
    Font=Enum.Font.Gotham, Text="VISUAL CONTROL CENTER", TextSize=9,
    TextColor3=themes.Dark.muted, TextXAlignment=Enum.TextXAlignment.Left,
}, top)

local close = make("TextButton", {
    Name="Close", AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-18,0.5,0),
    Size=UDim2.fromOffset(34,34), Text="×", TextSize=24, Font=Enum.Font.Gotham,
    TextColor3=themes.Dark.text, BackgroundColor3=themes.Dark.panel, AutoButtonColor=true,
}, top)
corner(close, 10)

local sidebar = make("Frame", {Position=UDim2.fromOffset(16,72), Size=UDim2.new(0,150,1,-90), BackgroundTransparency=1}, main)
local content = make("ScrollingFrame", {
    Name="Content", Position=UDim2.fromOffset(180,72), Size=UDim2.new(1,-196,1,-90),
    BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=3,
    CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
}, main)
make("UIPadding", {PaddingBottom=UDim.new(0,12), PaddingRight=UDim.new(0,8)}, content)
make("UIListLayout", {Padding=UDim.new(0,12), SortOrder=Enum.SortOrder.LayoutOrder}, content)

local pages, navButtons = {}, {}
local function applyTheme()
    local t = themes[currentTheme]
    main.BackgroundColor3 = t.bg
    mainStroke.Color = t.stroke
    logo.TextColor3 = accentColor
    close.BackgroundColor3 = t.panel
    close.TextColor3 = t.text
    for _, page in pairs(pages) do
        for _, d in ipairs(page:GetDescendants()) do
            if d:IsA("Frame") and d:GetAttribute("ViperPanel") then d.BackgroundColor3=t.panel end
            if d:IsA("TextLabel") or d:IsA("TextButton") then
                if d:GetAttribute("ViperMuted") then d.TextColor3=t.muted
                elseif d:GetAttribute("ViperText") then d.TextColor3=t.text end
            end
            if d:IsA("UIStroke") and d:GetAttribute("ViperStroke") then d.Color=t.stroke end
        end
    end
    for name, b in pairs(navButtons) do
        b.BackgroundColor3 = (name == selectedTab) and accentColor or t.panel
        b.TextColor3 = (name == selectedTab) and Color3.new(1,1,1) or t.muted
    end
end

local function label(parent, text, size, color, bold)
    local l = make("TextLabel", {
        BackgroundTransparency=1, Size=size or UDim2.new(1,0,0,24),
        Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        Text=text, TextSize=bold and 14 or 12, TextXAlignment=Enum.TextXAlignment.Left,
        TextColor3=color or themes.Dark.text, TextWrapped=true,
    }, parent)
    l:SetAttribute("ViperText", true)
    return l
end

local function panel(parent, height)
    local f = make("Frame", {Size=UDim2.new(1,0,0,height), BackgroundColor3=themes.Dark.panel, BorderSizePixel=0}, parent)
    f:SetAttribute("ViperPanel", true)
    corner(f, 13)
    local s = stroke(f, themes.Dark.stroke, 1, 0.25)
    s:SetAttribute("ViperStroke", true)
    make("UIPadding", {PaddingTop=UDim.new(0,14), PaddingBottom=UDim.new(0,14), PaddingLeft=UDim.new(0,16), PaddingRight=UDim.new(0,16)}, f)
    make("UIListLayout", {Padding=UDim.new(0,9), SortOrder=Enum.SortOrder.LayoutOrder}, f)
    return f
end

local function actionButton(parent, text, callback)
    local b = make("TextButton", {
        Size=UDim2.new(1,0,0,34), BackgroundColor3=themes.Dark.bg, Text=text,
        TextColor3=themes.Dark.text, Font=Enum.Font.GothamMedium, TextSize=12,
        AutoButtonColor=true, BorderSizePixel=0,
    }, parent)
    b:SetAttribute("ViperText", true)
    corner(b, 9)
    stroke(b, themes.Dark.stroke, 1, 0.3)
    b.MouseButton1Click:Connect(callback)
    return b
end

local function makePage(name)
    local p = make("Frame", {Name=name, Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, Visible=false}, content)
    make("UIListLayout", {Padding=UDim.new(0,12), SortOrder=Enum.SortOrder.LayoutOrder}, p)
    pages[name] = p
    return p
end

local function showPage(name)
    selectedTab = name
    for n,p in pairs(pages) do p.Visible = (n == name) end
    applyTheme()
end

local home = makePage("Home")
local welcome = panel(home, 112)
label(welcome, "WELCOME BACK", UDim2.new(1,0,0,18), themes.Dark.muted, true)
label(welcome, "Your setup. Your style.", UDim2.new(1,0,0,30), themes.Dark.text, true).TextSize=22
label(welcome, "A clean visual dashboard for your Roblox session.", UDim2.new(1,0,0,20), themes.Dark.muted, false)

local stats = panel(home, 88)
label(stats, "LIVE PERFORMANCE", UDim2.new(1,0,0,18), themes.Dark.muted, true)
local fpsLabel = label(stats, "FPS  --", UDim2.new(1,0,0,32), accentColor, true)
fpsLabel.TextSize = 24

local visual = makePage("Visuals")
local crossPanel = panel(visual, 116)
label(crossPanel, "CROSSHAIR", UDim2.new(1,0,0,18), themes.Dark.muted, true)
local crossInfo = label(crossPanel, "Center-screen visual reticle", UDim2.new(1,0,0,18), themes.Dark.text, false)
actionButton(crossPanel, "Toggle crosshair", function() crosshairEnabled = not crosshairEnabled end)
actionButton(crossPanel, "Change crosshair color", function()
    accentColor = (accentColor == Color3.fromRGB(151,105,255)) and Color3.fromRGB(68,205,255) or Color3.fromRGB(151,105,255)
    crosshair.BackgroundColor3 = accentColor
    logo.TextColor3 = accentColor
end)

local effectPanel = panel(visual, 132)
label(effectPanel, "VISUAL PRESETS", UDim2.new(1,0,0,18), themes.Dark.muted, true)
actionButton(effectPanel, "Toggle soft bloom + color grade", function()
    effectsEnabled = not effectsEnabled
    local bloom = Lighting:FindFirstChild("VIPER_Bloom") or Instance.new("BloomEffect")
    bloom.Name="VIPER_Bloom"; bloom.Intensity=effectsEnabled and 0.35 or 0; bloom.Size=24; bloom.Threshold=1.2; bloom.Parent=Lighting
    local cc = Lighting:FindFirstChild("VIPER_Color") or Instance.new("ColorCorrectionEffect")
    cc.Name="VIPER_Color"; cc.Saturation=effectsEnabled and 0.12 or 0; cc.Contrast=effectsEnabled and 0.08 or 0; cc.Parent=Lighting
end)
actionButton(effectPanel, "Toggle snowfall overlay", function() snowEnabled = not snowEnabled end)

local appearance = makePage("Appearance")
local themePanel = panel(appearance, 164)
label(themePanel, "INTERFACE THEME", UDim2.new(1,0,0,18), themes.Dark.muted, true)
for _, name in ipairs({"Dark","Light","Midnight"}) do
    actionButton(themePanel, name, function() currentTheme=name; applyTheme() end)
end
local wallPanel = panel(appearance, 190)
label(wallPanel, "WALLPAPER", UDim2.new(1,0,0,18), themes.Dark.muted, true)
local wallpaperImage = make("ImageLabel", {Size=UDim2.new(1,0,0,70), BackgroundColor3=themes.Dark.bg, Image="", ScaleType=Enum.ScaleType.Crop}, wallPanel)
corner(wallpaperImage, 9)
actionButton(wallPanel, "Ocean wallpaper", function()
    currentWallpaper="Ocean"; wallpaperImage.Image=WALLPAPERS.Ocean
end)
actionButton(wallPanel, "Fireplace wallpaper", function()
    currentWallpaper="Fireplace"; wallpaperImage.Image=WALLPAPERS.Fireplace
end)
actionButton(wallPanel, "Snowfall wallpaper", function()
    currentWallpaper="Snowfall"; wallpaperImage.Image=WALLPAPERS.Snowfall
end)
actionButton(wallPanel, "Clear wallpaper", function() currentWallpaper="None"; wallpaperImage.Image="" end)

local settings = makePage("Settings")
local settingPanel = panel(settings, 160)
label(settingPanel, "DISPLAY SETTINGS", UDim2.new(1,0,0,18), themes.Dark.muted, true)
actionButton(settingPanel, "Toggle FPS counter", function() fpsEnabled=not fpsEnabled; fpsLabel.Visible=fpsEnabled end)
actionButton(settingPanel, "Reset VIPER visual effects", function()
    effectsEnabled=false; snowEnabled=false; crosshairEnabled=true
    for _, name in ipairs({"VIPER_Bloom","VIPER_Color"}) do
        local e=Lighting:FindFirstChild(name); if e then e:Destroy() end
    end
    currentTheme="Dark"; accentColor=themes.Dark.accent; applyTheme()
end)
label(settingPanel, "RightShift: show / hide VIPER    •    Close button: hide", UDim2.new(1,0,0,32), themes.Dark.muted, false)

local tabNames = {"Home","Visuals","Appearance","Settings"}
for i,name in ipairs(tabNames) do
    local b = make("TextButton", {
        Name=name, Position=UDim2.fromOffset(0,(i-1)*44), Size=UDim2.new(1,0,0,36),
        BackgroundColor3=themes.Dark.panel, Text=name, TextColor3=themes.Dark.muted,
        Font=Enum.Font.GothamMedium, TextSize=12, BorderSizePixel=0, AutoButtonColor=true,
    }, sidebar)
    corner(b, 9)
    navButtons[name]=b
    b.MouseButton1Click:Connect(function() showPage(name) end)
end

-- Center reticle, independent from the menu.
local cross = make("Frame", {
    Name="VIPER_Crosshair", AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5),
    Size=UDim2.fromOffset(5,5), BackgroundColor3=accentColor, BorderSizePixel=0,
}, gui)
corner(cross, 3)
local crossStroke = stroke(cross, Color3.new(0,0,0), 1, 0.15)

-- Snowfall overlay uses lightweight UI flakes.
local flakes = {}
for i=1,24 do
    local flake = make("TextLabel", {
        BackgroundTransparency=1, Text="❄", TextColor3=Color3.fromRGB(225,235,255),
        TextTransparency=0.15, TextSize=math.random(10,18), Font=Enum.Font.Gotham,
        Position=UDim2.fromScale(math.random(),math.random()), Size=UDim2.fromOffset(22,22),
        Visible=false, ZIndex=20,
    }, gui)
    table.insert(flakes, flake)
end

-- Drag the window by its top bar.
local dragging, dragStart, startPos
top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging=true; dragStart=input.Position; startPos=main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging=false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta=input.Position-dragStart
        main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
    end
end)

local function setVisible(value)
    guiVisible=value
    main.Visible=value
end
close.MouseButton1Click:Connect(function() setVisible(false) end)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then setVisible(not guiVisible) end
end)

local frames, elapsed, fps = 0, 0, 0
local snowClock = 0
RunService.RenderStepped:Connect(function(dt)
    frames += 1; elapsed += dt; snowClock += dt
    if elapsed >= 0.5 then
        fps = math.floor(frames/elapsed + 0.5)
        fpsLabel.Text = "FPS  " .. tostring(fps)
        frames=0; elapsed=0
    end
    cross.Visible = crosshairEnabled
    for _, flake in ipairs(flakes) do
        flake.Visible = snowEnabled
        if snowEnabled then
            local y=flake.Position.Y.Scale + dt*0.12
            local x=flake.Position.X.Scale + math.sin(snowClock+flake.AbsolutePosition.X/90)*dt*0.025
            if y > 1.05 then y=-0.05; x=math.random() end
            flake.Position=UDim2.fromScale(x,y)
        end
    end
end)

showPage("Home")
applyTheme()
print("VIPER visual GUI loaded. RightShift toggles the menu.")
