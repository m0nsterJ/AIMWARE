local groupbox = gui.Groupbox(gui.Reference("Misc", "Enhancement"), "Killstreaks", 17, 15, 298, 100)

local gui =
{
    cEnable = gui.Checkbox(groupbox, "misc.killstreaks", "Enable", false),
    cNoExpiry = gui.Checkbox(groupbox, "misc.killstreaks.noexpiry", "Infinite Streak", false),
    sExpiry = gui.Slider(groupbox, "misc.killstreaks.expiry", "Streak Expiry", 10, 10, 30),
}

gui.cEnable:SetDescription("Enable Unreal Tournament kill announcers.")
gui.cNoExpiry:SetDescription("Always retain your killstreaks per round.")

local killstreak =
{
    currStreak = nil,
    streakFont = draw.CreateFont("Verdana Bold", 30),
    amountFont = draw.CreateFont("Verdana Bold", 24),
    realTime = 0,
    comboKills = 0,
    color = 0,
}

local numericStreaks =
{
    {"First Blood!", "firstblood.wav"},
    {"Double Kill!", "doublekill.wav"},
    {"Multikill!", "multikill.wav"},
    {"Megakill!", "megakill.wav"},
    {"Ultrakill!", "ultrakill.wav"},
    {"Killing Spree!", "killingspree.wav"},
    {"Monsterkill!", "monsterkill.wav"},
    {"Berzerk!", "berzerk.wav"}
}

local otherStreaks =
{
    {"Holy Shit!", "holyshit.wav"},
    {"Rampage!", "rampage.wav"},
    {"Dominating!", "dominating.wav"},
    {"Unstoppable!", "unstoppable.wav"},
    {"Godlike!", "godlike.wav"},
    {"Combo Whore!", "combowhore.wav"},
    {"Ludicrous Kill!", "ludicrouskill.wav"},
    {"Whicked Sick!", "whickedsick.wav"},
}

local headshotStreaks =
{
    {"Hattrick!", "hattrick.wav"},
    {"Headhunter!", "headhunter.wav"},
    {"Headshot!", "headshot.wav"},
}

local colors =
{
    {66, 135, 245, 255},
    {209, 62, 40, 255},
    {40, 209, 203, 255},
    {45, 39, 196, 255},
    {141, 39, 196, 255},
    {171, 50, 88, 255},
    {148, 163, 36, 255},
    {35, 176, 49, 255},
    {251, 3, 255, 255},
}

local Winmm = ffi.load("Winmm")

ffi.cdef [[
  bool PlaySound(const char *pszSound, void *hmod, uint32_t fdwSound);
]]
-- credit: Squidoodle (https://aimware.net/forum/user/305824)
function PlaySound(path)
  Winmm.PlaySound(path, nil, 0x00020003)
end

local function KillHandler(headshot)

    if not gui.cEnable:GetValue() then return end

    local temp
    killstreak.realTime = globals.RealTime()

    if not gui.cNoExpiry:GetValue() then
        if globals.RealTime() - killstreak.realTime < gui.sExpiry:GetValue() then
            killstreak.comboKills = killstreak.comboKills + 1
        end
    else
        killstreak.comboKills = killstreak.comboKills + 1
    end

    if killstreak.comboKills >= 1 and killstreak.comboKills <= #numericStreaks then
        temp = numericStreaks[killstreak.comboKills]
    else
        temp = otherStreaks[math.random(1, #otherStreaks)]

        if headshot then
            temp = headshotStreaks[math.random(1, #headshotStreaks)]
        end
    end

    killstreak.currStreak = temp[1]
    PlaySound("C:/Program Files (x86)/Steam/steamapps/common/Counter-Strike Global Offensive/game/csgo/sounds/announcer/" .. temp[2]) --change this to your directory if it differs from this
    killstreak.color = math.random(1, #colors)
end

local function ResetScore()
    killstreak.currStreak = nil
    killstreak.comboKills = 0
    killstreak.realTime = 0
end

local function EventHandler(event)

    if not gui.cEnable:GetValue() then return end

    if event == nil then
        return
    end

    if event:GetName() == "player_death" then
        local attacker_controller = entities.GetByIndex(event:GetInt("attacker") + 1)
        local victim_controller = entities.GetByIndex(event:GetInt("userid") + 1)

        if attacker_controller ~= nil and victim_controller ~= nil then
            local attacker = attacker_controller:GetFieldEntity("m_hPawn")
            local victim = victim_controller:GetFieldEntity("m_hPawn")

            if attacker:GetIndex() ~= entities.GetLocalPlayer():GetIndex() then
                return
            end

            if victim:GetIndex() == entities.GetLocalPlayer():GetIndex() then
                ResetScore()
            else
                KillHandler(event:GetInt("headshot") == 1)
            end
        end
    end

    if event:GetName() == "round_prestart" then
        ResetScore()
    end
end
callbacks.Register("FireGameEvent", EventHandler)
client.AllowListener("player_death")
client.AllowListener("round_prestart")

local x, y = draw.GetScreenSize()
local function DrawStreaks()

    local expired = false
    local currStreak = killstreak.currStreak
    local streakAlpha, textAlpha = 255, 255
    local timeDiff = globals.RealTime() - killstreak.realTime
    local halfExpiry = gui.sExpiry:GetValue() / 2
    local fadeProgress = math.min(1, (timeDiff - halfExpiry) / (halfExpiry * 0.5))

    if killstreak.comboKills >= 1 then
        local r, g, b = unpack(colors[killstreak.color])
        local streak = "Streak: " .. tostring(killstreak.comboKills)

        if not gui.cNoExpiry:GetValue() then
            expired = timeDiff > gui.sExpiry:GetValue()
        end

        if expired then
            ResetScore()
        else
            if timeDiff > halfExpiry and not gui.cNoExpiry:GetValue() then
                streakAlpha = (1.0 - fadeProgress^3) * 180
                textAlpha = (1.0 - fadeProgress^3) * 180
            else
                streakAlpha = 255
                textAlpha = math.floor(math.sin(globals.RealTime() * 4) * 70 + 180)
            end

            draw.SetFont(killstreak.streakFont)
            draw.Color(r, g, b, textAlpha)
            draw.TextShadow((x  - draw.GetTextSize(currStreak)) / 2, y - (y / 1.425), currStreak)

            draw.SetFont(killstreak.amountFont)
            draw.Color(r, g, b, streakAlpha)
            draw.TextShadow((x  - draw.GetTextSize(streak)) / 2, y - (y / 1.5), streak)
        end
    end
end

callbacks.Register("Draw", function()
    gui.sExpiry:SetInvisible(gui.cNoExpiry:GetValue())
    gui.sExpiry:SetDescription("Reset killstreak after " .. gui.sExpiry:GetValue() .. " seconds.")

    if not gui.cEnable:GetValue() then return end

    DrawStreaks()
end)