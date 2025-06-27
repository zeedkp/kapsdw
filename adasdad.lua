if game.PlaceId == 79393329652220 then
    local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
    local Window = Library.CreateLib("Zeek Hub  |  ✂️ Defusal FPS 💣 [TESTE]", "DarkTheme")
    local TabESP = Window:NewTab("ESP")
    local TabAimbot = Window:NewTab("Aimbot")

    local SectionESP = TabESP:NewSection("Funções ESP")
    local SectionAimbot = TabAimbot:NewSection("Funções Aimbot")

    local espBox3D = false

    -- Checkbox para Box 3D
    SectionESP:NewToggle("Box 3D", "Desenha box 3D nos inimigos", function(state)
        espBox3D = state
    end)

    local espName = false

    -- Checkbox para mostrar nome
    SectionESP:NewToggle("Name", "Mostra o nome do inimigo acima da cabeça", function(state)
        espName = state
    end)

    local espDistance = false

    -- Checkbox para mostrar distância
    SectionESP:NewToggle("Distance", "Mostra a distância até o inimigo", function(state)
        espDistance = state
    end)

    local espHeadHitbox = false

    -- Checkbox para HeadHitbox
    SectionESP:NewToggle("Head Hitbox", "Desenha uma bola na hitbox da cabeça do inimigo", function(state)
        espHeadHitbox = state
    end)

    local boxColor = Color3.new(1,0,0)
    local nameColor = Color3.new(1,1,1)
    local distanceColor = Color3.new(0.5,1,1)
    local headHitboxColor = Color3.new(1,0.5,0)

    SectionESP:NewColorPicker("Cor Box 3D", "Escolha a cor da Box 3D", boxColor, function(color)
        boxColor = color
    end)

    SectionESP:NewColorPicker("Cor Name", "Escolha a cor do Nome", nameColor, function(color)
        nameColor = color
    end)

    SectionESP:NewColorPicker("Cor Distance", "Escolha a cor da Distância", distanceColor, function(color)
        distanceColor = color
    end)

    SectionESP:NewColorPicker("Cor Head Hitbox", "Escolha a cor da Head Hitbox", headHitboxColor, function(color)
        headHitboxColor = color
    end)

    local espBoxes = {}

    local function removeESP()
        for _, box in pairs(espBoxes) do
            if box then box:Remove() end
        end
        espBoxes = {}
    end

    local function getCharacterBoundingBox(character)
        local minVec, maxVec
        for _, part in ipairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                if not minVec then
                    minVec = part.Position - (part.Size / 2)
                    maxVec = part.Position + (part.Size / 2)
                else
                    minVec = Vector3.new(
                        math.min(minVec.X, part.Position.X - part.Size.X/2),
                        math.min(minVec.Y, part.Position.Y - part.Size.Y/2),
                        math.min(minVec.Z, part.Position.Z - part.Size.Z/2)
                    )
                    maxVec = Vector3.new(
                        math.max(maxVec.X, part.Position.X + part.Size.X/2),
                        math.max(maxVec.Y, part.Position.Y + part.Size.Y/2),
                        math.max(maxVec.Z, part.Position.Z + part.Size.Z/2)
                    )
                end
            end
        end
        if minVec and maxVec then
            -- Aumenta um pouco o tamanho da box (10%)
            local center = (minVec + maxVec) / 2
            local size = (maxVec - minVec) * 1.1
            return center, size
        end
        return nil, nil
    end

    local function get3DBoxCorners(center, size)
        local sx, sy, sz = size.X/2, size.Y/2, size.Z/2
        local points = {
            Vector3.new(-sx, -sy, -sz),
            Vector3.new(-sx, -sy, sz),
            Vector3.new(-sx, sy, -sz),
            Vector3.new(-sx, sy, sz),
            Vector3.new(sx, -sy, -sz),
            Vector3.new(sx, -sy, sz),
            Vector3.new(sx, sy, -sz),
            Vector3.new(sx, sy, sz),
        }
        local corners = {}
        for _, p in ipairs(points) do
            table.insert(corners, center + p)
        end
        return corners
    end

    local function draw3DBox(corners, camera)
        local lines = {}
        local edges = {
            {1,2},{1,3},{1,5},{2,4},{2,6},{3,4},{3,7},{4,8},
            {5,6},{5,7},{6,8},{7,8}
        }
        for _, edge in ipairs(edges) do
            local p1, onScreen1 = camera:WorldToViewportPoint(corners[edge[1]])
            local p2, onScreen2 = camera:WorldToViewportPoint(corners[edge[2]])
            if onScreen1 and onScreen2 then
                local line = Drawing.new("Line")
                line.From = Vector2.new(p1.X, p1.Y)
                line.To = Vector2.new(p2.X, p2.Y)
                line.Color = boxColor
                line.Thickness = 2
                line.Transparency = 1
                line.Visible = true
                table.insert(lines, line)
            end
        end
        return lines
    end

    -- Função para desenhar o círculo na cabeça do inimigo
    local function drawHeadHitbox(character, camera)
        local head = character:FindFirstChild("Head")
        if not head then return nil end
        local pos, onScreen, depth = camera:WorldToViewportPoint(head.Position)
        if not onScreen then return nil end

        -- Calcula o raio proporcional à distância (quanto mais longe, menor na tela)
        local cameraPos = camera.CFrame.Position
        local distance = (cameraPos - head.Position).Magnitude
        local scale = 1 / (distance * 0.15) -- Ajuste o fator para o seu jogo
        local baseRadius = head.Size.X * 35 -- Valor base para o círculo, ajuste conforme necessário
        local radius = math.clamp(baseRadius * scale, 6, 30) -- Raio mínimo/máximo

        local circle = Drawing.new("Circle")
        circle.Position = Vector2.new(pos.X, pos.Y)
        circle.Radius = radius
        circle.Color = headHitboxColor
        circle.Thickness = 2
        circle.Filled = false
        circle.Transparency = 1
        circle.Visible = true
        return circle
    end

    local function espLoop()
        removeESP()
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        local Camera = workspace.CurrentCamera

        local myChar = LocalPlayer.Character
        if not myChar then return end
        local myShirt = myChar:FindFirstChildOfClass("Shirt")
        if not myShirt then return end
        local myShirtColor = myShirt.ShirtTemplate

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local shirt = player.Character:FindFirstChildOfClass("Shirt")
                if shirt and shirt.ShirtTemplate ~= myShirtColor then
                    -- Box 3D
                    if espBox3D then
                        local center, size = getCharacterBoundingBox(player.Character)
                        if center and size then
                            local corners = get3DBoxCorners(center, size)
                            local lines = draw3DBox(corners, Camera)
                            for _, line in ipairs(lines) do
                                table.insert(espBoxes, line)
                            end
                        end
                    end
                    -- Name ESP
                    local head = player.Character:FindFirstChild("Head")
                    if espName and head then
                        local pos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 2, 0))
                        if onScreen then
                            local nameLabel = Drawing.new("Text")
                            nameLabel.Text = player.Name
                            nameLabel.Position = Vector2.new(pos.X, pos.Y)
                            nameLabel.Size = 16
                            nameLabel.Center = true
                            nameLabel.Outline = true
                            nameLabel.Color = nameColor
                            nameLabel.Visible = true
                            table.insert(espBoxes, nameLabel)
                        end
                    end
                    -- Distance ESP (abaixo dos pés)
                    if espDistance then
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2, 0))
                            if onScreen then
                                local distance = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
                                local distLabel = Drawing.new("Text")
                                distLabel.Text = tostring(distance) .. "m"
                                distLabel.Position = Vector2.new(pos.X, pos.Y + 15) -- 15 pixels abaixo dos pés
                                distLabel.Size = 14
                                distLabel.Center = true
                                distLabel.Outline = true
                                distLabel.Color = distanceColor
                                distLabel.Visible = true
                                table.insert(espBoxes, distLabel)
                            end
                        end
                    end
                    -- Head Hitbox ESP
                    if espHeadHitbox then
                        local headHitbox = drawHeadHitbox(player.Character, Camera)
                        if headHitbox then
                            table.insert(espBoxes, headHitbox)
                        end
                    end
                end
            end
        end
    end

    game:GetService("RunService").RenderStepped:Connect(function()
        if espBox3D or espName or espDistance or espHeadHitbox then
            espLoop()
        else
            removeESP()
        end
    end)

    local aimbotEnabled = false
    local aimbotHold = false
    local aimbotFov = 100 -- raio do círculo em pixels
    local aimbotFovColor = Color3.fromRGB(0, 255, 255) -- Cor padrão do círculo FOV
    local aimbotCircle

    SectionAimbot:NewToggle("Aimbot", "Ativa ou desativa o Aimbot", function(state)
        aimbotEnabled = state
        if not state and aimbotCircle then
            aimbotCircle.Visible = false
        end
    end)

    SectionAimbot:NewColorPicker("Cor FOV", "Escolha a cor do círculo FOV do aimbot", aimbotFovColor, function(color)
        aimbotFovColor = color
        if aimbotCircle then
            aimbotCircle.Color = aimbotFovColor
        end
    end)

    -- Desenhar círculo de FOV do aimbot
    local function updateAimbotCircle()
        if not aimbotCircle then
            aimbotCircle = Drawing.new("Circle")
            aimbotCircle.Color = aimbotFovColor
            aimbotCircle.Thickness = 2
            aimbotCircle.Filled = false
            aimbotCircle.Transparency = 0.7
            aimbotCircle.Radius = aimbotFov
        end
        aimbotCircle.Color = aimbotFovColor -- Atualiza a cor sempre
        local Camera = workspace.CurrentCamera
        aimbotCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        aimbotCircle.Visible = aimbotEnabled
    end

    -- Detectar botão direito do mouse
    game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            aimbotHold = true
        end
    end)
    game:GetService("UserInputService").InputEnded:Connect(function(input, gpe)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            aimbotHold = false
        end
    end)

    -- Função para encontrar o inimigo mais próximo do centro da tela DENTRO do círculo
    local function getClosestEnemyInFov()
        local closestPlayer = nil
        local closestDist = aimbotFov
        local Camera = workspace.CurrentCamera
        local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        local myChar = game.Players.LocalPlayer.Character
        if not myChar then return nil end
        local myShirt = myChar:FindFirstChildOfClass("Shirt")
        if not myShirt then return nil end
        local myShirtColor = myShirt.ShirtTemplate

        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local shirt = player.Character:FindFirstChildOfClass("Shirt")
                if shirt and shirt.ShirtTemplate ~= myShirtColor then
                    local head = player.Character:FindFirstChild("Head")
                    if head then
                        local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                        if onScreen then
                            local dist = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                            if dist < closestDist then
                                closestDist = dist
                                closestPlayer = player
                            end
                        end
                    end
                end
            end
        end
        return closestPlayer
    end

    -- Loop do aimbot
    game:GetService("RunService").RenderStepped:Connect(function()
        updateAimbotCircle()
        if aimbotEnabled and aimbotHold then
            local target = getClosestEnemyInFov()
            if target and target.Character and target.Character:FindFirstChild("Head") then
                local head = target.Character.Head
                local Camera = workspace.CurrentCamera
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    -- Move o mouse para a cabeça do alvo
                    local mouse = game:GetService("Players").LocalPlayer:GetMouse()
                    local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                    local moveTo = Vector2.new(pos.X, pos.Y)
                    -- Calcula o deslocamento
                    local delta = moveTo - screenCenter
                    -- Move o mouse (apenas em exploits que suportam mouse_event, exemplo: Synapse X)
                    -- Se não funcionar, remova/comment as linhas abaixo
                    pcall(function()
                        mousemoverel(delta.X, delta.Y)
                    end)
                end
            end
        end
    end)

end
