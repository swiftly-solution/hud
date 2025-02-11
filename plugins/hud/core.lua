function GetPluginAuthor()
    return "m3ntorsky"
end
function GetPluginVersion()
    return "v1.0.0"
end
function GetPluginName()
    return "HUD"
end
function GetPluginWebsite()
    return "https://github.com/swiftly-solutions/hud"
end

local Panels = {}
local INTERVAL = 50000
local currentIndex = {}
local playerTextIDs = {}

local function ReplacePlaceholders(text, playerid)
    local player = GetPlayer(playerid)
    if not player then return text end

    text = text:gsub("{playerName}", player:CBasePlayerController().PlayerName)
    text = text:gsub("{players}", tostring(playermanager:GetPlayerCount()))
    text = text:gsub("{maxplayers}", tostring(server:GetMaxPlayers()))
    text = text:gsub("{map}", server:GetMap())

    return text
end

local function OnPluginStart(event)
    Panels = {}  
    config:Reload("hud")
    local panels = config:Fetch("hud.panels")
    INTERVAL = tonumber(config:Fetch("hud.interval")) or INTERVAL

    for i = 1, #panels do
        local panel = panels[i]
        table.insert(Panels, {
            messages = panel.messages or {"Default message"},
            color = panel.color or {r = 255, g = 255, b = 255, a = 100},
            position = panel.position or {x = 0.5, y = 0.5},
            font = panel.font or "Arial",
            background = panel.background or false,
        })
    end
end

local function UpdateHudMessage(playerid, panelIndex)
    if not Panels[panelIndex] then return end
    local panel = Panels[panelIndex]

    if not currentIndex[playerid] then
        currentIndex[playerid] = {}
    end
    if not currentIndex[playerid][panelIndex] then
        currentIndex[playerid][panelIndex] = 1
    end

    local messageIndex = currentIndex[playerid][panelIndex]
    local message = panel.messages[messageIndex] or "Default message"

    -- Przesunięcie indeksu do następnej wiadomości
    currentIndex[playerid][panelIndex] = (messageIndex % #panel.messages) + 1

    message = ReplacePlaceholders(message, playerid)

    local textID = playerTextIDs[playerid] and playerTextIDs[playerid][panelIndex]
    if textID then
        vgui:SetTextMessage(textID, message)
    end

    SetTimeout(INTERVAL, function()
        UpdateHudMessage(playerid, panelIndex)
    end)
end

local function ShowHud(playerid)
    playerTextIDs[playerid] = {}

    for i = 1, #Panels do
        local panel = Panels[i]

        local colorPanel = Color(panel.color.r, panel.color.g, panel.color.b, panel.color.a)
        local message = ReplacePlaceholders(panel.messages[1], playerid)

        local textID = vgui:ShowText(
            playerid,
            colorPanel,
            message,
            panel.position.x,
            panel.position.y,
            panel.font,
            panel.background
        )

        playerTextIDs[playerid][i] = textID

        SetTimeout(INTERVAL, function()
            UpdateHudMessage(playerid, i)
        end)
    end
end

 local function OnPostPlayerTeam(event)
    local playerid = event:GetInt("userid")
    local oldTeam = event:GetInt("oldteam")


    if oldTeam ~= Team.None then
        return
    end
    NextTick(function ()
        ShowHud(playerid)
    end)
 end


AddEventHandler("OnPluginStart", OnPluginStart)
AddEventHandler("OnPostPlayerTeam", OnPostPlayerTeam)
