-- VIPER GUI | authorized visual/debug interface
-- Install as a LocalScript in StarterPlayer > StarterPlayerScripts.
-- This build contains visual customization only. It does not inject into clients
-- or alter other players/gameplay. Upload wallpapers to Roblox and paste asset IDs.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("VIPER_GUI")
if old then old:Destroy() end

local WALLPAPERS = {
    Ocean = "rbxassetid://0",
    Fireplace = "rbxassetid://0",
    Snowfall = "rbxassetid://0",
}

local Themes = {
    Dark = {bg=Color3.fromRGB(12,14,22), panel=Color3.fromRGB(23,26,39), field=Color3.fromRGB(13,16,25), text=Color3.fromRGB(241,243,250), muted=Color3.fromRGB(157,165,185), accent=Color3.fromRGB(75,202,244), stroke=Color3.fromRGB(57,64,88)},
    Light = {bg=Color3.fromRGB(231,235,245), panel=Color3.fromRGB(250,251,255), field=Color3.fromRGB(222,226,239), text=Color3.fromRGB(29,33,48), muted=Color3.fromRGB(91,99,120), accent=Color3.fromRGB(34,157,204), stroke=Color3.fromRGB(190,198,218)},
    Midnight = {bg=Color3.fromRGB(5,9,19), panel=Color3.fromRGB(13,20,37), field=Color3.fromRGB(7,13,26), text=Color3.fromRGB(226,239,255), muted=Color3.fromRGB(124,151,183), accent=Color3.fromRGB(91,148,255), stroke=Color3.fromRGB(35,78,125)},
}
local themeName = "Dark"
local accent
local crosshairOn, fpsOn, blurOn, snowOn = true, true, true, false
local menuOpen = true
local waitingForBind = nil
local binds = {Menu=Enum.KeyCode.RightShift, Crosshair=Enum.KeyCode.C, FPS=Enum.KeyCode.F, Blur=Enum.KeyCode.B}
local pages, nav, themed = {}, {}, {}

local function theme() return Themes[themeName] end
accent = theme().accent

local gui = Instance.new("ScreenGui")
gui.Name = "VIPER_GUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- Separate top-layer overlay keeps the reticle and FPS visible above the menu.
local overlay = Instance.new("ScreenGui")
overlay.Name = "VIPER_Overlay"
overlay.ResetOnSpawn = false
overlay.IgnoreGuiInset = true
overlay.DisplayOrder = 100
overlay.ZIndexBehavior = Enum.ZIndexBehavior.Global
overlay.Parent = playerGui

local function new(class, props, parent)
    local o = Instance.new(class)
    for k,v in pairs(props or {}) do o[k] = v end
    o.Parent = parent
    return o
end
local function round(o, px)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, px or 10); c.Parent = o
end
local function outline(o)
    local s = Instance.new("UIStroke"); s.Name="VIPERStroke"; s.Thickness=1; s.Transparency=0.25; s.Parent=o
    table.insert(themed,{object=s,role="stroke"})
end
local function tag(o, role)
    table.insert(themed,{object=o,role=role})
    return o
end

local blur = Lighting:FindFirstChild("VIPER_MenuBlur") or Instance.new("BlurEffect")
blur.Name = "VIPER_MenuBlur"
blur.Size = 0
blur.Parent = Lighting

local main = new("Frame", {
    Name="Main", AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5),
    Size=UDim2.new(0.82,0,0.78,0), BackgroundColor3=theme().bg, BorderSizePixel=0,
}, gui)
main.ClipsDescendants = true
round(main,18)
local mainConstraint = Instance.new("UISizeConstraint")
mainConstraint.MinSize=Vector2.new(340,330); mainConstraint.MaxSize=Vector2.new(900,650); mainConstraint.Parent=main
tag(main,"bg"); outline(main)

local top = new("Frame",{Name="Topbar",Size=UDim2.new(1,0,0,66),BackgroundTransparency=1},main)
local logo = tag(new("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(22,7),Size=UDim2.fromOffset(180,30),Font=Enum.Font.GothamBlack,Text="V I P E R",TextSize=22,TextXAlignment=Enum.TextXAlignment.Left},top),"accentText")
local subtitle = tag(new("TextLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(24,36),Size=UDim2.fromOffset(220,16),Font=Enum.Font.Gotham,Text="VISUAL CONTROL CENTER",TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},top),"mutedText")
local close = tag(new("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-16,0.5,0),Size=UDim2.fromOffset(36,36),Text="×",TextSize=23,Font=Enum.Font.Gotham,BorderSizePixel=0,AutoButtonColor=true},top),"fieldButton")
round(close,10)

local sidebar = new("Frame",{Position=UDim2.fromOffset(16,76),Size=UDim2.new(0,142,1,-92),BackgroundTransparency=1},main)
local sideLayout = new("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},sidebar)
local content = new("ScrollingFrame",{
    Name="PageScroll",Position=UDim2.fromOffset(172,76),Size=UDim2.new(1,-188,1,-92),
    BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.new(),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,
},main)
new("UIPadding",{PaddingBottom=UDim.new(0,12),PaddingRight=UDim.new(0,8)},content)
local pageLayout = new("UIListLayout",{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder},content)

local function applyTheme()
    local t=theme()
    main.BackgroundColor3=t.bg
    for _,entry in ipairs(themed) do
        local o,r=entry.object,entry.role
        if o and o.Parent then
            if r=="bg" then o.BackgroundColor3=t.bg
            elseif r=="panel" then o.BackgroundColor3=t.panel
            elseif r=="field" or r=="fieldButton" then o.BackgroundColor3=t.field; if o:IsA("TextButton") or o:IsA("TextLabel") or o:IsA("TextBox") then o.TextColor3=t.text end
            elseif r=="preview" then o.BackgroundColor3=t.field
            elseif r=="text" then o.TextColor3=t.text
            elseif r=="mutedText" then o.TextColor3=t.muted
            elseif r=="accentText" then o.TextColor3=accent
            elseif r=="stroke" then o.Color=t.stroke
            elseif r=="nav" then
                local active=o:GetAttribute("VIPERActive")
                o.BackgroundColor3=active and accent or t.panel
                o.TextColor3=active and Color3.new(1,1,1) or t.muted
            end
        end
    end
end

local function makeLabel(parent,txt,height,role,bold,size)
    return tag(new("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,height or 22),
        Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,Text=txt,TextSize=size or (bold and 14 or 12),
        TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},parent),role or "text")
end
local function makePanel(parent,title)
    local p=tag(new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=theme().panel,BorderSizePixel=0},parent),"panel")
    round(p,13); outline(p)
    new("UIPadding",{PaddingTop=UDim.new(0,13),PaddingBottom=UDim.new(0,13),PaddingLeft=UDim.new(0,15),PaddingRight=UDim.new(0,15)},p)
    new("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},p)
    makeLabel(p,title,20,"mutedText",true,13)
    return p
end
local function button(parent,txt,fn)
    local b=tag(new("TextButton",{Size=UDim2.new(1,0,0,36),BackgroundColor3=theme().field,BorderSizePixel=0,
        Text=txt,TextColor3=theme().text,Font=Enum.Font.GothamMedium,TextSize=12,AutoButtonColor=true},parent),"fieldButton")
    round(b,9); outline(b)
    local base=b.BackgroundColor3
    b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.12),{BackgroundColor3=theme().panel}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.12),{BackgroundColor3=theme().field}):Play() end)
    b.MouseButton1Click:Connect(fn)
    return b
end
local function page(name)
    local p=new("Frame",{Name=name,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Visible=false},content)
    new("UIListLayout",{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder},p)
    pages[name]=p
    return p
end

-- FPS readout and crosshair: four separated arms with a center dot.
local fpsHud = tag(new("TextLabel",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-18,0,18),Size=UDim2.fromOffset(120,28),
    BackgroundTransparency=1,Text="FPS --",TextSize=14,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Right,Visible=true},overlay),"accentText")
local crossGroup = new("Frame",{Name="Crosshair",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(32,32),BackgroundTransparency=1,ZIndex=50},overlay)
local crossParts={}
local function crossPart(pos,size)
    local f=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=pos,Size=size,BackgroundColor3=accent,BorderSizePixel=0,ZIndex=51},crossGroup)
    round(f,2); outline(f); table.insert(crossParts,f)
end
crossPart(UDim2.fromScale(.5,.12),UDim2.fromOffset(2,7))
crossPart(UDim2.fromScale(.5,.88),UDim2.fromOffset(2,7))
crossPart(UDim2.fromScale(.12,.5),UDim2.fromOffset(7,2))
crossPart(UDim2.fromScale(.88,.5),UDim2.fromOffset(7,2))
crossPart(UDim2.fromScale(.5,.5),UDim2.fromOffset(3,3))

local home=page("Home")
local welcome=makePanel(home,"WELCOME BACK")
makeLabel(welcome,"Your setup. Your style.",30,"text",true,21)
makeLabel(welcome,"A customizable visual dashboard for your session.",20,"mutedText")
local perf=makePanel(home,"LIVE PERFORMANCE")
local fpsBig=makeLabel(perf,"FPS  --",30,"accentText",true,24)

local visuals=page("Visuals")
local crossPanel=makePanel(visuals,"CROSSHAIR")
makeLabel(crossPanel,"A clean, centered five-piece reticle.",20,"mutedText")
button(crossPanel,"Toggle crosshair",function() crosshairOn=not crosshairOn; crossGroup.Visible=crosshairOn and not menuOpen end)
button(crossPanel,"Cycle crosshair color",function()
    accent = accent==Color3.fromRGB(75,202,244) and Color3.fromRGB(255,190,75) or Color3.fromRGB(75,202,244)
    applyTheme()
    for _,part in ipairs(crossParts) do part.BackgroundColor3=accent end
end)
local fx=makePanel(visuals,"VISUAL EFFECTS")
button(fx,"Toggle soft bloom + color grade",function()
    local bloom=Lighting:FindFirstChild("VIPER_Bloom") or Instance.new("BloomEffect")
    bloom.Name="VIPER_Bloom"; bloom.Intensity=bloom.Intensity>0 and 0 or 0.3; bloom.Size=22; bloom.Threshold=1.15; bloom.Parent=Lighting
    local cc=Lighting:FindFirstChild("VIPER_Color") or Instance.new("ColorCorrectionEffect")
    cc.Name="VIPER_Color"; cc.Saturation=cc.Saturation>0 and 0 or 0.1; cc.Contrast=cc.Contrast>0 and 0 or 0.06; cc.Parent=Lighting
end)
button(fx,"Toggle snowfall overlay",function() snowOn=not snowOn end)

local appearance=page("Appearance")
local themePanel=makePanel(appearance,"INTERFACE THEME")
for _,name in ipairs({"Dark","Light","Midnight"}) do
    button(themePanel,name.." theme",function() themeName=name; accent=theme().accent; for _,part in ipairs(crossParts) do part.BackgroundColor3=accent end; applyTheme() end)
end
local wallpaperPanel=makePanel(appearance,"WALLPAPER")
local wallpaperPreview=new("ImageLabel",{Size=UDim2.new(1,0,0,118),BackgroundColor3=theme().field,BorderSizePixel=0,Image="",ScaleType=Enum.ScaleType.Crop},wallpaperPanel)
round(wallpaperPreview,9); tag(wallpaperPreview,"preview")
local wallpaperInputs={}
for _,name in ipairs({"Ocean","Fireplace","Snowfall"}) do
    makeLabel(wallpaperPanel,name.." asset ID",18,"mutedText",true,11)
    local input=tag(new("TextBox",{Size=UDim2.new(1,0,0,34),BackgroundColor3=theme().field,BorderSizePixel=0,
        Text="",PlaceholderText="Paste Roblox image asset ID",PlaceholderColor3=theme().muted,
        TextColor3=theme().text,Font=Enum.Font.Gotham,TextSize=12,ClearTextOnFocus=false},wallpaperPanel),"field")
    round(input,8); outline(input)
    wallpaperInputs[name]=input
    button(wallpaperPanel,"Apply "..name.." wallpaper",function()
        local raw=input.Text:gsub("%s",""):gsub("rbxassetid://","")
        if raw:match("^%d+$") and raw~="0" then
            WALLPAPERS[name]="rbxassetid://"..raw
            wallpaperPreview.Image=WALLPAPERS[name]
        else
            input.Text=""
            input.PlaceholderText="Enter a valid numeric Roblox image ID"
        end
    end)
end
button(wallpaperPanel,"Clear wallpaper preview",function() wallpaperPreview.Image="" end)
makeLabel(wallpaperPanel,"Upload each GIF/image to Roblox first, then paste its image asset ID above. GitHub raw URLs are not accepted by Roblox ImageLabels.",44,"mutedText")

local settings=page("Settings")
local display=makePanel(settings,"DISPLAY & BACKGROUND")
button(display,"Toggle FPS display",function() fpsOn=not fpsOn; fpsHud.Visible=fpsOn; fpsBig.Visible=fpsOn end)
button(display,"Toggle background blur",function()
    blurOn=not blurOn
    TweenService:Create(blur,TweenInfo.new(.18),{Size=(menuOpen and blurOn) and 14 or 0}):Play()
end)
button(display,"Reset visual settings",function()
    themeName="Dark"; accent=theme().accent; crosshairOn=true; fpsOn=true; blurOn=true; snowOn=false
    crossGroup.Visible=not menuOpen; fpsHud.Visible=true; fpsBig.Visible=true; blur.Size=menuOpen and 14 or 0
    for _,part in ipairs(crossParts) do part.BackgroundColor3=accent end
    for _,name in ipairs({"VIPER_Bloom","VIPER_Color"}) do local e=Lighting:FindFirstChild(name); if e then e:Destroy() end end
    applyTheme()
end)
local keybindsPage=page("Keybinds")
local keyPanel=makePanel(keybindsPage,"KEYBINDS")
local bindButtons={}
local function bindLabel(action)
    local key=binds[action]
    return action.."  •  "..(key and key.Name or "Unassigned")
end
for _,action in ipairs({"Menu","Crosshair","FPS","Blur"}) do
    local b
    b=button(keyPanel,bindLabel(action),function()
        waitingForBind=action
        b.Text="Press a key for "..action.." (Esc cancels)"
    end)
    bindButtons[action]=b
end
makeLabel(keyPanel,"Click a bind, then press the key you want to use.",20,"mutedText")

local crosshairPage=page("Crosshair")
local crossSettings=makePanel(crosshairPage,"CROSSHAIR CUSTOMIZATION")
local crossSize,crossGap,crossThickness=32,7,2
local function rebuildCrosshair()
    crossGroup:ClearAllChildren()
    table.clear(crossParts)
    local function piece(x,y,w,h)
        local f=new("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=accent,BorderSizePixel=0,ZIndex=51},crossGroup)
        round(f,2)
        table.insert(crossParts,f)
    end
    local center=crossSize/2
    piece(center,center-crossGap-crossSize*.16,crossThickness,crossSize*.18)
    piece(center,center+crossGap+crossSize*.16,crossThickness,crossSize*.18)
    piece(center-crossGap-crossSize*.16,center,crossSize*.18,crossThickness)
    piece(center+crossGap+crossSize*.16,center,crossSize*.18,crossThickness)
    piece(center,center,math.max(3,crossThickness+1),math.max(3,crossThickness+1))
end
button(crossSettings,"Increase crosshair size",function() crossSize=math.min(60,crossSize+4); crossGroup.Size=UDim2.fromOffset(crossSize,crossSize); rebuildCrosshair() end)
button(crossSettings,"Decrease crosshair size",function() crossSize=math.max(16,crossSize-4); crossGroup.Size=UDim2.fromOffset(crossSize,crossSize); rebuildCrosshair() end)
button(crossSettings,"Increase crosshair thickness",function() crossThickness=math.min(5,crossThickness+1); rebuildCrosshair() end)
button(crossSettings,"Decrease crosshair thickness",function() crossThickness=math.max(1,crossThickness-1); rebuildCrosshair() end)
button(crossSettings,"Cycle crosshair color",function() accent=accent==Color3.fromRGB(75,202,244) and Color3.fromRGB(255,190,75) or Color3.fromRGB(75,202,244); rebuildCrosshair(); applyTheme() end)
button(crossSettings,"Toggle crosshair",function() crosshairOn=not crosshairOn; crossGroup.Visible=crosshairOn and not menuOpen end)
rebuildCrosshair()

local debugPage=page("Debug")
local debugPanel=makePanel(debugPage,"NPC DEBUG VISUALS")
makeLabel(debugPanel,"Visual debugging for NPCs and test dummies in your own experience only.",34,"mutedText")
local npcEspOn,npcChamsOn,npcBoxesOn=false,false,false
local npcHighlights,npcBoxes={},{}
local function isNpcModel(model)
    if not model:IsA("Model") or not model:FindFirstChildOfClass("Humanoid") then return false end
    return Players:GetPlayerFromCharacter(model)==nil
end
local function clearDebugVisuals()
    for _,v in pairs(npcHighlights) do if v and v.Parent then v:Destroy() end end
    for _,v in pairs(npcBoxes) do if v and v.Parent then v:Destroy() end end
    table.clear(npcHighlights); table.clear(npcBoxes)
end
local function refreshNpcVisuals()
    clearDebugVisuals()
    if not (npcEspOn or npcChamsOn or npcBoxesOn) then return end
    for _,model in ipairs(workspace:GetDescendants()) do
        if isNpcModel(model) then
            if npcEspOn or npcChamsOn then
                local h=Instance.new("Highlight"); h.Name="VIPER_NPC_Debug"; h.Adornee=model
                h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                h.FillColor=Color3.fromRGB(75,202,244); h.OutlineColor=Color3.fromRGB(235,245,255)
                h.FillTransparency=npcChamsOn and 0.48 or 1; h.OutlineTransparency=npcEspOn and 0 or 1
                h.Parent=gui; table.insert(npcHighlights,h)
            end
            if npcBoxesOn then
                for _,part in ipairs(model:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local box=Instance.new("BoxHandleAdornment"); box.Name="VIPER_NPC_HitboxView"
                        box.Adornee=part; box.AlwaysOnTop=true; box.ZIndex=5; box.Size=part.Size
                        box.Transparency=.72; box.Color3=Color3.fromRGB(255,185,75); box.Parent=gui
                        table.insert(npcBoxes,box)
                    end
                end
            end
        end
    end
end
button(debugPanel,"Toggle NPC ESP outlines",function() npcEspOn=not npcEspOn; refreshNpcVisuals() end)
button(debugPanel,"Toggle NPC chams",function() npcChamsOn=not npcChamsOn; refreshNpcVisuals() end)
button(debugPanel,"Toggle NPC hitbox visualization",function() npcBoxesOn=not npcBoxesOn; refreshNpcVisuals() end)
makeLabel(debugPanel,"These are debug overlays only; they do not change player hitboxes or expose other players through walls.",42,"mutedText")

local tabs={"Home","Visuals","Crosshair","Appearance","Keybinds","Debug","Settings"}
local function selectPage(name)
    for n,p in pairs(pages) do p.Visible=(n==name) end
    for n,b in pairs(nav) do b:SetAttribute("VIPERActive",n==name) end
    applyTheme()
end
for i,name in ipairs(tabs) do
    local b=tag(new("TextButton",{Name=name,LayoutOrder=i,Size=UDim2.new(1,0,0,36),BackgroundColor3=theme().panel,
        BorderSizePixel=0,Text=name,TextSize=12,Font=Enum.Font.GothamMedium,AutoButtonColor=true},sidebar),"nav")
    round(b,9); nav[name]=b
    b.MouseButton1Click:Connect(function() selectPage(name) end)
end

-- Decorative snowfall particles.
local flakes={}
for i=1,22 do
    local f=new("TextLabel",{BackgroundTransparency=1,Text="❄",TextColor3=Color3.fromRGB(226,239,255),
        TextTransparency=.18,TextSize=math.random(10,17),Font=Enum.Font.Gotham,Size=UDim2.fromOffset(20,20),
        Position=UDim2.fromScale(math.random(),math.random()),Visible=false,ZIndex=15},gui)
    table.insert(flakes,f)
end

-- Drag the window by the header.
local dragging,dragStart,startPosition=false,nil,nil
top.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        dragging=true; dragStart=input.Position; startPosition=main.Position
        input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        local d=input.Position-dragStart
        main.Position=UDim2.new(startPosition.X.Scale,startPosition.X.Offset+d.X,startPosition.Y.Scale,startPosition.Y.Offset+d.Y)
    end
end)

local menuTween
local function setMenu(open)
    menuOpen=open
    crossGroup.Visible=crosshairOn and not open
    if menuTween then menuTween:Cancel() end
    if open then
        main.Visible=true
        main.Size=UDim2.new(0.79,0,0.74,0)
        blur.Size=0
        menuTween=TweenService:Create(main,TweenInfo.new(.22,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.new(0.82,0,0.78,0)})
        menuTween:Play()
        if blurOn then TweenService:Create(blur,TweenInfo.new(.22),{Size=14}):Play() end
    else
        menuTween=TweenService:Create(main,TweenInfo.new(.16,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=UDim2.new(0.77,0,0.72,0)})
        menuTween:Play()
        if blurOn then TweenService:Create(blur,TweenInfo.new(.16),{Size=0}):Play() end
        menuTween.Completed:Once(function() if not menuOpen then main.Visible=false end end)
    end
end
close.MouseButton1Click:Connect(function() setMenu(false) end)
UserInputService.InputBegan:Connect(function(input,processed)
    if waitingForBind then
        if input.KeyCode==Enum.KeyCode.Escape then
            waitingForBind=nil
        elseif input.KeyCode~=Enum.KeyCode.Unknown then
            binds[waitingForBind]=input.KeyCode
            waitingForBind=nil
        end
        for action,b in pairs(bindButtons) do b.Text=bindLabel(action) end
        return
    end
    if processed then return end
    for action,key in pairs(binds) do
        if input.KeyCode==key then
            if action=="Menu" then setMenu(not menuOpen)
            elseif action=="Crosshair" then crosshairOn=not crosshairOn; crossGroup.Visible=crosshairOn
            elseif action=="FPS" then fpsOn=not fpsOn; fpsHud.Visible=fpsOn; fpsBig.Visible=fpsOn
            elseif action=="Blur" then blurOn=not blurOn; blur.Size=(menuOpen and blurOn) and 14 or 0 end
        end
    end
end)

local frames,elapsed,snowClock=0,0,0
RunService.RenderStepped:Connect(function(dt)
    frames+=1; elapsed+=dt; snowClock+=dt
    if elapsed>=.5 then
        local fps=math.floor(frames/elapsed+.5)
        fpsHud.Text="FPS  "..fps; fpsBig.Text="FPS  "..fps
        frames=0; elapsed=0
    end
    for _,f in ipairs(flakes) do
        f.Visible=snowOn
        if snowOn then
            local y=f.Position.Y.Scale+dt*.11
            local x=f.Position.X.Scale+math.sin(snowClock+f.AbsolutePosition.X/80)*dt*.018
            if y>1.05 then y=-.05; x=math.random() end
            f.Position=UDim2.fromScale(x,y)
        end
    end
end)

selectPage("Home")
applyTheme()
setMenu(true)
print("VIPER GUI loaded. Default keys: RightShift menu, C crosshair, F FPS, B blur.")
