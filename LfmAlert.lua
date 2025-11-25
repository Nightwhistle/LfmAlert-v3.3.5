-- LfmAlert - LFM Pattern Alert Addon for WoW 3.5.5

LfmAlert = {}
LfmAlert.patterns = {}
LfmAlert.currentAlert = nil
LfmAlert.alertData = nil

-- Event handlers for all channels
local CHANNEL_EVENTS = {
	"CHAT_MSG_SAY",           -- Say
	"CHAT_MSG_GUILD",         -- Guild
	"CHAT_MSG_PARTY",         -- Party
	"CHAT_MSG_RAID",          -- Raid
	"CHAT_MSG_RAID_LEADER",   -- Raid Leader
	"CHAT_MSG_OFFICER",       -- Officer
	"CHAT_MSG_YELL",          -- Yell
	"CHAT_MSG_WHISPER",       -- Whisper
	"CHAT_MSG_CHANNEL",       -- Custom Channels (Trade, LFG, etc.)
}

-- Create main frame
local frame = CreateFrame("Frame", "LfmAlertFrame")
frame:RegisterEvent("PLAYER_LOGIN")

-- Register all channel events
for _, event in ipairs(CHANNEL_EVENTS) do
	frame:RegisterEvent(event)
end

-- Load saved patterns
local function LoadPatterns()
	if LfmAlertDB and LfmAlertDB.patterns then
		LfmAlert.patterns = LfmAlertDB.patterns
	else
		LfmAlert.patterns = {}
	end
end

-- Save patterns
local function SavePatterns()
	if not LfmAlertDB then
		LfmAlertDB = {}
	end
	LfmAlertDB.patterns = LfmAlert.patterns
end

-- Add pattern
local function AddPattern(pattern)
	if not pattern or pattern == "" then
		print("|cffff0000LfmAlert:|r Molim unesite pattern!")
		return
	end
	
	pattern = string.upper(pattern)
	
	-- Check if already exists
	for _, p in ipairs(LfmAlert.patterns) do
		if p == pattern then
			print("|cffff0000LfmAlert:|r Pattern '" .. pattern .. "' već postoji!")
			return
		end
	end
	
	table.insert(LfmAlert.patterns, pattern)
	SavePatterns()
	print("|cff00ff00LfmAlert:|r Pattern '" .. pattern .. "' je dodan!")
end

-- Remove pattern
local function RemovePattern(pattern)
	if not pattern or pattern == "" then
		print("|cffff0000LfmAlert:|r Molim unesite pattern!")
		return
	end
	
	pattern = string.upper(pattern)
	
	for i, p in ipairs(LfmAlert.patterns) do
		if p == pattern then
			table.remove(LfmAlert.patterns, i)
			SavePatterns()
			print("|cff00ff00LfmAlert:|r Pattern '" .. pattern .. "' je obrisan!")
			return
		end
	end
	
	print("|cffff0000LfmAlert:|r Pattern '" .. pattern .. "' nije pronađen!")
end

-- List patterns
local function ListPatterns()
	if #LfmAlert.patterns == 0 then
		print("|cffff0000LfmAlert:|r Nema dodanih paterna!")
		return
	end
	
	print("|cff00ff00LfmAlert - Paterne:|r")
	for i, pattern in ipairs(LfmAlert.patterns) do
		print("  " .. i .. ". " .. pattern)
	end
end

-- Clear patterns
local function ClearPatterns()
	LfmAlert.patterns = {}
	SavePatterns()
	print("|cff00ff00LfmAlert:|r Svi paterne su obrisani!")
end

local function CreateAlertFrame()
    local alertFrame = CreateFrame("Frame", "LfmAlertDisplay", UIParent)
    alertFrame:SetSize(900, 120)
	alertFrame:SetPoint("TOP", UIParent, "TOP", 0, -UIParent:GetHeight() * 0.10)
    alertFrame:Hide()

    -- Omogući klikove (3.3.5 samo ovo postoji)
    alertFrame:EnableMouse(true)

    alertFrame:SetFrameStrata("HIGH") -- preporučeno da klik radi

    -- Tekst poruke
    local msg = alertFrame:CreateFontString(nil, "ARTWORK")
    msg:SetPoint("CENTER", alertFrame, "CENTER", 0, 0)
    msg:SetWidth(850)
    msg:SetJustifyH("CENTER")
    msg:SetWordWrap(true)
    msg:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
    msg:SetShadowColor(0, 0, 0, 1)
    msg:SetShadowOffset(2, -2)
    alertFrame.msg = msg

    -- Klik otvara whisper
    alertFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and LfmAlert.alertData then
            local player = LfmAlert.alertData.player
            if player and player ~= "" then
                ChatFrame_OpenChat("/w " .. player .. " ", ChatFrame1)
            end
        end
        LfmAlert:HideAlert()
    end)

    -- Fade-out timer
    alertFrame:SetScript("OnUpdate", function(self, elapsed)
        if not LfmAlert.alertData then return end

        LfmAlert.alertData.elapsed = (LfmAlert.alertData.elapsed or 0) + elapsed

        if LfmAlert.alertData.elapsed > 6 then
            LfmAlert:HideAlert()
            return
        end

        local alpha = 1
        if LfmAlert.alertData.elapsed > 5 then
            alpha = 1 - (LfmAlert.alertData.elapsed - 5)
        end

        alertFrame:SetAlpha(alpha)
    end)

    return alertFrame
end

-- Show alert
function LfmAlert:ShowAlert(pattern, player, message)
    if not self.currentAlert then
        self.currentAlert = CreateAlertFrame()
    end

    self.alertData = {
        pattern = pattern,
        player = player,
        message = message,
        elapsed = 0
    }

    local formatted = "|cffffffff" .. player .. ":|r " .. message

    self.currentAlert:SetAlpha(1)
    self.currentAlert.msg:SetText(formatted)
    self.currentAlert:Show()
end

-- Hide alert
function LfmAlert:HideAlert()
	if self.currentAlert then
		self.currentAlert:Hide()
	end
	self.alertData = nil
end

-- Check if message contains pattern
local function CheckForPattern(message, player)
	message = string.upper(message)
	
	for _, pattern in ipairs(LfmAlert.patterns) do
		if string.find(message, pattern) then
			-- Check for LF*M (LF1M, LF2M, LF8M, LF10M, LF25M, itd)
			if string.find(message, "LF%dM") or string.find(message, "LFM") then
				LfmAlert:ShowAlert(pattern, player, message)
				return
			end
		end
	end
end

-- Event handler
frame:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_LOGIN" then
		LoadPatterns()
		print("|cff00ff00LfmAlert|r - Addon je učitan!")
		
    else
        -- All chat events pass message, player as first two arguments
        local message, player, language, channelName, _, _, _, channelNumber = ...

        -- Ako je poruka iz kanala /6, preskoči
        if event == "CHAT_MSG_CHANNEL" and tonumber(channelNumber) == 6 then
            return
        end

        -- Provera paterna u svim ostalim slučajevima
        CheckForPattern(message, player)
    end
end)

-- Slash commands
SLASH_LFMALERT1 = "/lfm"
local function SlashHandler(msg, editbox)
	local cmd, args = string.match(msg, "^(%S*)%s*(.*)")
	cmd = string.lower(cmd)
	
	if cmd == "add" then
		AddPattern(args)
	elseif cmd == "remove" then
		RemovePattern(args)
	elseif cmd == "list" then
		ListPatterns()
	elseif cmd == "clear" then
		ClearPatterns()
	else
		print("|cff00ff00LfmAlert - Komande:|r")
		print("  /lfm add <pattern> - Dodaj pattern")
		print("  /lfm remove <pattern> - Ukloni pattern")
		print("  /lfm list - Prikaži sve paterne")
		print("  /lfm clear - Obriši sve paterne")
	end
end

SlashCmdList["LFMALERT"] = SlashHandler
