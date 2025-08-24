--// 🌙 MoonFinder - Target Pet Serverhopper
--// Özellikler: Auto serverhop, Target bulununca durma, Target çıkarsa devam etme,
--// Teleport retry, Discord Webhook bildirimi, Roblox Notification, Chat komutları

--== AYARLAR ==--
local WebhookURL = "https://discord.com/api/webhooks/1409064316363083816/OihtHhsoDyMutwqHY3AjJR-DYSCMRpp0prodkrE6kLBSm-9UJateWArPjdpFTHz5c6PR"

local TargetPets = {
    -- The Normal Secrets
    "La Vacca Saturno Saturnita",
    "Bisonte Giuppitere",
    "Karkerkar Kurkur",
    "Los Matteos",
    "Sammyni Spyderini",
    "Dul Dul Dul",
    "Blackhole Goat",
    "Agarrini la Palini",
    "Los Spyderinis",
    "Los Tralaleritos",
    "Las Tralaleritas",
    "Job Job Job Sahur",
    "Las Vaquitas Saturnitas",
    "Graipuss Medussi",
    "Nooo My Hotspot",
    "Chicleteira Bicicleteira",
    "La Grande Combinasion",
    "Los Combinasionas",
    "Nuclearo Dinossauro",
    "Los Hotspotsitos",
    "N/A", -- Coming soon...",
    "La Supreme Combinasion",
    "Garama and Madundung",
    "Dragon Cannelloni",

    -- From Secret Lucky Block
    "Torrtuginni Dragonfrutini",
    "Pot Hotspot",
    "Esok Sekolah",

    -- Lucky Blocks
    "Secret Lucky Block",
    "Admin Lucky Block"
}

--== SERVİS ==--
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--== FONKSİYONLAR ==--
local function Notify(title, text, duration)
    game.StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 5
    })
end

local function SendWebhook(pets)
    local data = {
        ["username"] = "MoonFinder 🎯",
        ["embeds"] = {{
            ["title"] = "🎯 Target Pet(s) Found!",
            ["description"] = table.concat(pets, "\n"),
            ["color"] = 65280
        }}
    }
    local body = HttpService:JSONEncode(data)

    if syn then
        syn.request({Url = WebhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = body})
    elseif http_request then
        http_request({Url = WebhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = body})
    else
        warn("HTTP request function not found for webhook!")
    end
end

--== TARGET BULMA ==--
local function ScanPets()
    local found = {}
    for _,pet in pairs(workspace:GetDescendants()) do
        if pet:IsA("Model") and table.find(TargetPets, pet.Name) then
            table.insert(found, "🎯 "..pet.Name)
            if not pet:FindFirstChild("BillboardGui") then
                local bb = Instance.new("BillboardGui", pet)
                bb.Size = UDim2.new(0,200,0,50)
                bb.AlwaysOnTop = true
                bb.Adornee = pet:FindFirstChildWhichIsA("BasePart")
                local tl = Instance.new("TextLabel", bb)
                tl.Size = UDim2.new(1,0,1,0)
                tl.Text = "🎯 Target Pet"
                tl.TextColor3 = Color3.fromRGB(255,0,0)
                tl.TextScaled = true
                tl.BackgroundTransparency = 1
                tl.Font = Enum.Font.GothamBold  -- Font değişti

                -- Stroke ekleme
                local stroke = Instance.new("UIStroke", tl)
                stroke.Thickness = 2
                stroke.Color = Color3.new(0,0,0)
                stroke.Transparency = 0
            end
        end
    end
    return found
end

--== SERVERHOP ==--
local function ServerHop()
    local success, servers = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
        ))
    end)

    if success and servers.data then
        for _,srv in pairs(servers.data) do
            -- 🎯 Filtre: boş servera girme, max değilse dene
            if srv.playing > 0 and srv.playing < srv.maxPlayers then
                local ok, err = pcall(function()
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
                end)
                if not ok then
                    warn("Teleport failed: retrying...")
                    task.wait(2)
                    ServerHop()
                end
                break
            end
        end
    else
        warn("Server listesi alınamadı, tekrar denenecek...")
        task.wait(5)
        ServerHop()
    end
end
--== ANA LOOP ==--
task.spawn(function()
    while task.wait(5) do
        local targets = ScanPets()
        if #targets > 0 then
            -- target bulundu
            Notify("MoonFinder 🎯", "Target Pet(s) bulundu!", 8)
            SendWebhook(targets)
            repeat
                task.wait(5)
                targets = ScanPets()
            until #targets == 0
            -- target yok oldu, devam et
            ServerHop()
        else
            -- target yoksa hop
            ServerHop()
        end
    end
end)

--== CHAT KOMUTLARI ==--
LocalPlayer.Chatted:Connect(function(msg)
    msg = msg:lower()
    if msg == "/sc" or msg == "/serverhop" or msg == "/serverchange" then
        Notify("MoonFinder", "Manual Serverhop Çalışıyor...", 5)
        ServerHop()
    end
end)
