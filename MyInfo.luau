return function(Window)
    local Abysall = getgenv().Abysall
    local Library = Abysall.Interface.Library
    local Player = game:GetService("Players").LocalPlayer
    local RunService = game:GetService("RunService")

    -- ==========================================
    -- НАСТРОЙКИ ТВОЕГО ПРОФИЛЯ (Будет видеть каждый)
    -- ==========================================
    local MY_STATIC_NAME = "Artem3107"        -- Твой ник, который увидят все
    local MY_ROLE = "Lead Developer & Forker" -- Твоя роль в списке

    local InfoTab = Window:AddTab("Info", "user")

    -- ==============================
    -- ЛЕВАЯ ЧАСТЬ (User Info - реальный игрок)
    -- ==============================
    local UserGroup = InfoTab:AddLeftGroupbox("User Info")
    
    local Thumb = game:GetService("Players"):GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    UserGroup:AddImage("Avatar", { Image = Thumb })
    
    UserGroup:AddLabel("Username: " .. Player.Name, true)
    UserGroup:AddLabel("Executions: " .. tostring(Abysall.TotalExecutions or 0), true)

    -- ==============================
    -- ПРАВАЯ ЧАСТЬ (Credits)
    -- ==============================
    local CreditsGroup = InfoTab:AddRightGroupbox("Credits")
    
    -- 1. СНАЧАЛА ДОБАВЛЯЕМ ТЕБЯ (Отдельный лейбл для радуги)
    local MyLabel = CreditsGroup:AddLabel("<font color='#ffffff'>" .. MY_STATIC_NAME .. " — " .. MY_ROLE .. "</font>", true)

    -- 2. ПОТОМ ДОБАВЛЯЕМ ОСТАЛЬНЫХ
    local OtherCredits = {
        "<font color='rgb(0, 255, 255)'>CookieMonster — Owner of the Continued Script</font>",
        "<font color='rgb(255, 165, 0)'>FireBacon — Owner of the Discontinued Script</font>",
        "<font color='rgb(197, 63, 132)'>Rhyan57 — Provided the Infinite Crucifix</font>",
        "<font color='rgb(241, 106, 212)'>Abbas - Basicly a developer</font>",
        "<font color='rgb(120, 200, 255)'>den4ik_top_off - Theme creator</font>",
        "<font color='rgb(120, 200, 255)'>sasanixx - Theme creator</font>"
    }
    
    for _, line in ipairs(OtherCredits) do
        CreditsGroup:AddLabel(line, true)
    end
    
    -- 3. ЗАПУСКАЕМ РАДУГУ ТОЛЬКО ДЛЯ ТВОЕГО ЛЕЙБЛА
    RunService.RenderStepped:Connect(function()
        if MyLabel and MyLabel.TextLabel then
            local hue = (tick() % 2) / 2 -- Скорость переливания
            local c = Color3.fromHSV(hue, 1, 1)
            local hex = string.format("#%02X%02X%02X", math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
            
            -- Перекрашиваем имя, а роль оставляем серой
            MyLabel.TextLabel.Text = string.format("<font color='%s'>%s</font> — <font color='#AAAAAA'>%s</font>", hex, MY_STATIC_NAME, MY_ROLE)
        end
    end)

    -- ==============================
    -- ПРАВАЯ ЧАСТЬ 2 (Executor Info)
    -- ==============================
    local ExecutorGroup = InfoTab:AddRightGroupbox("Executor Info")
    local ExecName, ExecVer = Abysall.Environment.identifyexecutor()
    
    ExecutorGroup:AddLabel("Executor: " .. tostring(ExecName), true)
    ExecutorGroup:AddLabel("Version: " .. tostring(ExecVer), true)
    ExecutorGroup:AddDivider()
    
    for _, res in pairs(Abysall.Environment.Results or {}) do
        local cleanRes = res:gsub("<", "("):gsub(">", ")")
        ExecutorGroup:AddLabel(cleanRes, true)
    end

    -- ==============================
    -- ЛЕВАЯ ЧАСТЬ 2 (Buttons)
    -- ==============================
    local ButtonsGroup = InfoTab:AddLeftGroupbox("Actions")
    
    ButtonsGroup:AddButton("Copy Loadstring", {
        Tooltip = "Копирует ссылку на скрипт",
        Func = function()
            toclipboard("loadstring(game:HttpGet('https://raw.githubusercontent.com/Artem3107/Wwooum/refs/heads/main/Ooooooo'))()")
            Library:Notify("Loadstring скопирован в буфер обмена!")
        end
    })
end
