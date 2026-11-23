-- VIPER Admin Server
-- Place this Script in ServerScriptService in an experience you own/are authorized to edit.
-- IMPORTANT: replace 0 below with your Roblox UserId. Only listed IDs can use movement controls.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AUTHORIZED_USER_IDS = {
    [0] = true, -- REPLACE 0 with your numeric Roblox UserId
}

local remote = ReplicatedStorage:FindFirstChild("VIPER_AdminRemote")
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = "VIPER_AdminRemote"
    remote.Parent = ReplicatedStorage
end

local states = {}

local function authorized(player)
    return AUTHORIZED_USER_IDS[player.UserId] == true
end

local function getCharacter(player)
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then return end
    return character, humanoid, root
end

local function setFly(player, enabled)
    local _, _, root = getCharacter(player)
    if not root then return end
    local state = states[player] or {}
    states[player] = state
    state.fly = enabled
    if enabled then
        local velocity = root:FindFirstChild("VIPER_FlyVelocity") or Instance.new("BodyVelocity")
        velocity.Name = "VIPER_FlyVelocity"
        velocity.MaxForce = Vector3.new(1e6,1e6,1e6)
        velocity.P = 18000
        velocity.Velocity = Vector3.zero
        velocity.Parent = root
        local gyro = root:FindFirstChild("VIPER_FlyGyro") or Instance.new("BodyGyro")
        gyro.Name = "VIPER_FlyGyro"
        gyro.MaxTorque = Vector3.new(1e6,1e6,1e6)
        gyro.P = 12000
        gyro.CFrame = root.CFrame
        gyro.Parent = root
    else
        for _, name in ipairs({"VIPER_FlyVelocity","VIPER_FlyGyro"}) do
            local obj = root:FindFirstChild(name)
            if obj then obj:Destroy() end
        end
    end
end

local function setNoclip(player, enabled)
    local character = player.Character
    if not character then return end
    local state = states[player] or {}
    states[player] = state
    state.noclip = enabled
    state.originalCollision = state.originalCollision or {}
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if enabled then
                if state.originalCollision[part] == nil then
                    state.originalCollision[part] = part.CanCollide
                end
                part.CanCollide = false
            else
                local oldValue = state.originalCollision[part]
                if oldValue ~= nil then part.CanCollide = oldValue end
                state.originalCollision[part] = nil
            end
        end
    end
end

remote.OnServerEvent:Connect(function(player, action, value)
    if not authorized(player) then return end
    local state = states[player] or {}
    states[player] = state

    if action == "SetSpeed" then
        local _, humanoid = getCharacter(player)
        local n = tonumber(value)
        if humanoid and n then humanoid.WalkSpeed = math.clamp(n, 1, 100) end

    elseif action == "SetJumpPower" then
        local _, humanoid = getCharacter(player)
        local n = tonumber(value)
        if humanoid and n then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = math.clamp(n, 1, 150)
        end

    elseif action == "FlyToggle" then
        setFly(player, not state.fly)

    elseif action == "FlyInput" then
        if state.fly and typeof(value) == "Vector3" then
            local _, _, root = getCharacter(player)
            if root then
                local velocity = root:FindFirstChild("VIPER_FlyVelocity")
                if velocity then velocity.Velocity = value * 55 end
                local gyro = root:FindFirstChild("VIPER_FlyGyro")
                if gyro and value.Magnitude > 0.05 then
                    gyro.CFrame = CFrame.lookAt(root.Position, root.Position + Vector3.new(value.X, 0, value.Z))
                end
            end
        end

    elseif action == "NoclipToggle" then
        setNoclip(player, not state.noclip)
    end
end)

local function cleanup(player)
    local state = states[player]
    if state then
        if state.fly then setFly(player, false) end
        if state.noclip then setNoclip(player, false) end
    end
    states[player] = nil
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        local state = states[player]
        if state and state.noclip then setNoclip(player, true) end
    end)
end)
Players.PlayerRemoving:Connect(cleanup)

RunService.Heartbeat:Connect(function()
    for player, state in pairs(states) do
        if state.noclip and player.Character then
            for _, part in ipairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)
