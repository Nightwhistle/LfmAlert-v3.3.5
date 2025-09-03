-- Create the addon frame
local frame = CreateFrame("Frame")

-- Register chat events
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("CHAT_MSG_CHANNEL")
frame:RegisterEvent("CHAT_MSG_SAY")
frame:RegisterEvent("CHAT_MSG_YELL")
frame:RegisterEvent("CHAT_MSG_GUILD")
frame:RegisterEvent("CHAT_MSG_PARTY")
frame:RegisterEvent("CHAT_MSG_RAID")
frame:RegisterEvent("CHAT_MSG_WHISPER")

-- SavedVariables
LFMAlertDB = LFMAlertDB or {}

-- Event handler
frame:SetScript("OnEvent", function(self, event, msg, sender, ...)
    if not msg or type(msg) ~= "string" then return end
    CheckForLFM(msg, sender)
end)

-- Function to check for "LFM" and a saved keyword
function CheckForLFM(msg, sender)
    local lowered = string.lower(msg)

    if string.find(lowered, "lfm") or string.find(lowered, "lf%d+m") then
        for _, keyword in ipairs(LFMAlertDB) do
            if string.find(lowered, keyword) then
                ShowAlert(msg, sender)
                break
            end
        end
    end
end

-- Function to show alert
function ShowAlert(msg, sender)
    CreateAlertFrame(msg, sender)
end

-- Slash command to manage keywords
SLASH_LFM1 = "/lfm"
SlashCmdList["LFM"] = function(msg)
    local command, arg = string.match(msg, "(%S+)%s*(.*)")
    if command == "add" and arg ~= "" then
        table.insert(LFMAlertDB, string.lower(arg))
        print("|cff00ff00LFM Alert:|r Added keyword - " .. arg)
    elseif command == "remove" and arg ~= "" then
        for i, keyword in ipairs(LFMAlertDB) do
            if keyword == string.lower(arg) then
                table.remove(LFMAlertDB, i)
                print("|cffff0000LFM Alert:|r Removed keyword - " .. arg)
                break
            end
        end
    elseif command == "list" then
        print("|cff00ff00LFM Alert Keywords:|r")
        for _, keyword in ipairs(LFMAlertDB) do
            print("- " .. keyword)
        end
    elseif command == "clear" then
        LFMAlertDB = {}
        print("|cffff0000LFM Alert: Cleared all keywords.|r")
    else
        print("Usage: /lfm add <keyword>, /lfm remove <keyword>, /lfm list, /lfm clear")
    end
end

function CreateAlertFrame(msg, sender)
    -- clickable name
    local clickableName = "|Hplayer:" .. sender .. "|h|cff00ffff[" .. sender .. "]|r|h"
    local fullMsg = clickableName .. ": " .. msg

    -- show message in the RaidWarning frame (big text in middle of screen)
    RaidNotice_AddMessage(RaidWarningFrame, fullMsg, ChatTypeInfo["RAID_WARNING"])

    -- play sound
    PlaySoundFile("Sound\\Interface\\RaidWarning.wav")
end