shared.Hastelepasta = nil
getgenv().Abysall = nil
getgenv().Abysall_LoadedAddons = {} -- Защита от дублирования аддонов

local MY_INFO_URL = "https://raw.githubusercontent.com/Artem3107/Wwooum/refs/heads/main/MyInfo.luau"
local MY_ENV_URL  = "https://raw.githubusercontent.com/Artem3107/Wwooum/refs/heads/main/BetterEnvironment.luau"
local MAIN_URL    = "https://raw.githubusercontent.com/therealcookiemonsterof1966/AbysallContinued/main/Games/Doors/Main.luau"

-- ==========================================
-- 0. ПАТЧЕР Main.luau
-- ==========================================
local function PatchMainScript(src)
    if type(src) ~= "string" then return src end
    
    -- 1. Патч EntityDistances (все дистанции = 70)
    local startIdx = src:find("local EntityDistances%s*=%s*{")
    if startIdx then
        local braceStart = src:find("{", startIdx, true)
        if braceStart then
            local depth = 0
            local closeIdx
            for i = braceStart, #src do
                local c = src:sub(i, i)
                if c == "{" then depth = depth + 1
                elseif c == "}" then
                    depth = depth - 1
                    if depth == 0 then closeIdx = i break end
                end
            end
            if closeIdx then
                local before = src:sub(1, braceStart)
                local body = src:sub(braceStart + 1, closeIdx - 1)
                local after = src:sub(closeIdx)
                local newBody = body:gsub("=%s*%d+", "= 70")
                src = before .. newBody .. after
                print("[Patch] EntityDistances пропатчен — все дистанции = 70")
            end
        end
    end

    -- 2. Патч радиуса DoorReach (меняем 75 на 30)
    local doorPatched, count = src:gsub("LocalPlayer:DistanceFromCharacter%(Object%.Door%.Position%)%s*<%s*75", "LocalPlayer:DistanceFromCharacter(Object.Door.Position) < 30")
    if count > 0 then
        print("[Patch] Радиус DoorReach пропатчен: 75 -> 30 studs")
        src = doorPatched
    end

    -- 3. Внедрение кода аддонов
    local injectAddonCode = [[
    local OldAddTab = Window.AddTab
    local InjectSettingsTab
    Window.AddTab = function(self, name, icon, ...)
        local tab = OldAddTab(self, name, icon, ...)
        if name == "Settings" or icon == "settings" then
            InjectSettingsTab = tab
        end
        return tab
    end

    local OldApplySettingsTab = Abysall.Interface.ApplySettingsTab
    Abysall.Interface.ApplySettingsTab = function(Win)
        OldApplySettingsTab(Win)
        if InjectSettingsTab then
            local AddonGroup = InjectSettingsTab:AddRightGroupbox("Дополнения (Addons)")
            
            local function LoadAddon(name, url, buttonObj)
                if getgenv().Abysall_LoadedAddons and getgenv().Abysall_LoadedAddons[name] then
                    if buttonObj then
                        pcall(function() buttonObj:SetDisabled(true) end)
                        pcall(function() buttonObj:SetText(name .. " (Загружен)") end)
                    end
                    Library.OldNotify({Title = "Ошибка", Description = "Аддон '" .. name .. "' уже загружен!"})
                    return
                end
                
                task.spawn(function()
                    local success, err = pcall(function()
                        local code = game:HttpGet(url)
                        local addon = loadstring(code)()
                        addon(Win)
                    end)
                    
                    if success then
                        if not getgenv().Abysall_LoadedAddons then getgenv().Abysall_LoadedAddons = {} end
                        getgenv().Abysall_LoadedAddons[name] = true
                        Library.OldNotify({Title = "Успех", Description = "Аддон " .. name .. " загружен!"})
                        
                        -- Блокируем кнопку после успешной загрузки
                        if buttonObj then
                            pcall(function() buttonObj:SetDisabled(true) end)
                            pcall(function() buttonObj:SetText(name .. " (Загружен)") end)
                        end
                    else
                        Library.OldNotify({Title = "Ошибка", Description = "Не удалось загрузить: " .. tostring(err)})
                    end
                end)
            end

            local btn1
            btn1 = AddonGroup:AddButton({
                Text = "Загрузить PositionSpoof Fix",
                Tooltip = "Фикс лестниц для PositionSpoof",
                Func = function()
                    LoadAddon("skidzopositionspooffix", "https://raw.githubusercontent.com/therealcookiemonsterof1966/AbysallContinued/refs/heads/main/Games/Doors/Addons/skidzopostionspooffix", btn1)
                end
            })
            
            local btn2
            btn2 = AddonGroup:AddButton({
                Text = "Загрузить HipHeight Addon",
                Tooltip = "Управление высотой персонажа",
                Func = function()
                    LoadAddon("userdisover addon", "https://raw.githubusercontent.com/therealcookiemonsterof1966/AbysallContinued/refs/heads/main/Games/Doors/Addons/userdiscover8HipHeight", btn2)
                end
            })
        end
    end
    ]]
    
    local patchedSrc, found = src:gsub("Abysall%.Interface%.ApplySettingsTab%(Window%)", injectAddonCode .. "\nAbysall.Interface.ApplySettingsTab(Window)")
    if found > 0 then
        src = patchedSrc
        print("[Patch] Вкладка Addons внедрена в Settings")
    end

    return src
end

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
local oldNewIndex = mt.__newindex
local oldIndex = mt.__index
setreadonly(mt, false)

-- ==========================================
-- 1. ГЛАВНЫЙ ХУК
-- ==========================================
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if method == "HttpGet" and self == game then
        if type(args[1]) == "string" and string.find(args[1], "Components/Environment%.luau") then
            print("[Patch] Подмена Environment на BetterEnvironment")
            return oldNamecall(self, MY_ENV_URL .. "?nocache=" .. os.time())
        end

        if type(args[1]) == "string" and string.find(args[1], "Components/Analytics%.luau") then
            print("[Patch] Аналитика удалена")
            return "return {}"
        end
        
        if type(args[1]) == "string" and string.find(args[1], "Components/InfoTab%.luau") then
            return oldNamecall(self, MY_INFO_URL .. "?nocache=" .. os.time())
        end
        
        if type(args[1]) == "string" and string.find(args[1], "Games/Doors/Main%.luau") then
            local src = oldNamecall(self, ...)
            if type(src) == "string" then return PatchMainScript(src) end
            return src
        end
    end

    if method == "new" and self == Instance then
        local env = getfenv(2)
        if env and env.script and env.script.Name == "PromptGate" then return nil end
    end

    if method == "Destroy" then
        local ok, name = pcall(function() return self.Name end)
        local okP, parent = pcall(function() return self.Parent end)
        if ok and okP and name == "Screech" and parent and parent.Name == "Camera" then
            pcall(function()
                for _, desc in ipairs(self:GetDescendants()) do
                    if desc:IsA("BasePart") then desc.CanTouch = false; desc.CanCollide = false; desc.Transparency = 1
                    elseif desc:IsA("Sound") then desc.Volume = 0 end
                end
            end)
            return nil
        end
    end

    if (self.Name == "SallyFace" or self.Name == "SallyFace_Real") and (method == "FireServer" or method == "InvokeServer") then
        return nil
    end

    if method == "FireServer" and self.Name == "DropItem" then
        local Tool = args[1]
        if Tool and Tool.Name == "Crucifix" then
            local Abysall = getgenv().Abysall
            if Abysall and Abysall.Interface and Abysall.Interface.Library and Abysall.Interface.Library.Toggles.InfCrucifix and Abysall.Interface.Library.Toggles.InfCrucifix.Value then
                task.spawn(function()
                    local LP = game:GetService("Players").LocalPlayer
                    local StartTime = tick()
                    local FireFunc = fireproximityprompt
                    repeat
                        task.wait(0.01)
                        local Drops = workspace:FindFirstChild("Drops")
                        if Drops then
                            local Drop = Drops:FindFirstChild("Crucifix")
                            if Drop then
                                local Prompt = Drop:FindFirstChildOfClass("ProximityPrompt")
                                if Prompt and Prompt.Enabled then
                                    if FireFunc then FireFunc(Prompt) else Prompt:InputHoldBegin() Prompt:InputHoldEnd() end
                                end
                            end
                        end
                    until (LP.Character and LP.Character:FindFirstChild("Crucifix")) or (tick() - StartTime) > 1.2
                end)
            end
        end
    end

    return oldNamecall(self, ...)
end)

mt.__newindex = newcclosure(function(self, key, value)
    if key == "Parent" and value == nil then
        local ok, name = pcall(function() return self.Name end)
        if ok and name == "Screech" and self:IsA("RemoteEvent") then
            local hidden = (gethui and gethui()) or game:GetService("CoreGui")
            return oldNewIndex(self, key, hidden)
        end
    end
    return oldNewIndex(self, key, value)
end)

local dummyInstance = setmetatable({}, { __index = function(_, k) return function() return nil end end })
mt.__index = newcclosure(function(self, key)
    if key == "Instance" then
        local env = getfenv(2)
        if env and env.script and env.script.Name == "PromptGate" then return dummyInstance end
    end
    return oldIndex(self, key)
end)

setreadonly(mt, true)

-- ==========================================
-- 2. Загрузка хаба
-- ==========================================
print("[Loader] Загрузка хаба...")
local ok, err = pcall(function()
    local src = game:HttpGet(MAIN_URL .. "?t=" .. os.time())
    loadstring(src)()
end)
if not ok then warn("Ошибка: " .. tostring(err)) end

-- ==========================================
-- 3. Добавление режимов Down / Up
-- ==========================================
task.spawn(function()
    while not (getgenv().Abysall and getgenv().Abysall.Interface and getgenv().Abysall.Interface.Library) do task.wait(0.5) end
    local Library = getgenv().Abysall.Interface.Library
    local Options = Library.Options
    local Toggles = Library.Toggles
    
    if Options.VelocityManipulationMode then
        pcall(function()
            local currentVals = Options.VelocityManipulationMode.Values
            local hasDown, hasUp = false, false
            for _, v in ipairs(currentVals) do
                if v == "Down" then hasDown = true end
                if v == "Up" then hasUp = true end
            end
            if not hasDown then table.insert(currentVals, "Down") end
            if not hasUp then table.insert(currentVals, "Up") end
            Options.VelocityManipulationMode:SetValues(currentVals)
        end)
    end
    
    local RunService = game:GetService("RunService")
    local LP = game:GetService("Players").LocalPlayer
    local DownVelocity = Instance.new("BodyVelocity")
    DownVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    
    RunService.RenderStepped:Connect(function()
        if not (Toggles.VelocityManipulationToggle and Toggles.VelocityManipulationToggle.Value) then 
            if DownVelocity.Parent then DownVelocity.Parent = nil end
            return 
        end
        local Char = LP.Character
        local Root = Char and Char:FindFirstChild("HumanoidRootPart")
        if Root then
            if Options.VelocityManipulationMode and Options.VelocityManipulationMode.Value == "Down" then
                DownVelocity.Parent = Root
                DownVelocity.Velocity = Vector3.new(0, -2.25, 0)
            elseif Options.VelocityManipulationMode and Options.VelocityManipulationMode.Value == "Up" then
                DownVelocity.Parent = Root
                DownVelocity.Velocity = Vector3.new(0, 2.25, 0)
            else
                if DownVelocity.Parent then DownVelocity.Parent = nil end
            end
        end
    end)
end)

-- ==========================================
-- 4. Anti Sally
-- ==========================================
task.spawn(function()
    while not (getgenv().Abysall and getgenv().Abysall.Interface and getgenv().Abysall.Interface.Library) do task.wait(0.5) end
    local Library = getgenv().Abysall.Interface.Library
    local Tabs = Library.Tabs
    local ExploitsTab = Tabs and (Tabs.Exploits or Tabs["Exploits"])
    
    if ExploitsTab then
        local CustomGroup = ExploitsTab:AddRightGroupbox("Custom Removers")
        local SallyToggle = CustomGroup:AddToggle("AntiSallyHard", { Text = "Anti Sally", Default = false })
        
        local function HideAndNeutralizeSally(obj)
            if obj and obj.Name == "SallyMoving" then
                task.wait(0.1)
                if obj and obj.Parent then
                    for _, desc in ipairs(obj:GetDescendants()) do
                        if desc:IsA("BasePart") then desc.CanTouch = false; desc.CanCollide = false; desc.Transparency = 1
                        elseif desc:IsA("Sound") then desc.Volume = 0 
                        elseif desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") then desc.Enabled = false end
                    end
                end
            end
        end

        SallyToggle:OnChanged(function(val)
            if val then
                for _, obj in ipairs(workspace:GetChildren()) do
                    if obj.Name == "SallyMoving" then task.spawn(function() HideAndNeutralizeSally(obj) end) end
                end
            end
        end)

        workspace.ChildAdded:Connect(function(child)
            if SallyToggle.Value and child.Name == "SallyMoving" then task.spawn(function() HideAndNeutralizeSally(child) end) end
        end)
    end
end)
