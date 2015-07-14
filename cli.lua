
eso_addon_MailLooter = eso_addon_MailLooter or {}
local ADDON = eso_addon_MailLooter

local function CommandHandler(text)
  if text == "" then
    d( ADDON.NAME .. " version " .. ADDON.VERSION )
    d( "Commands:" )
    d( "debug on|off  - turns debug messages on and off" )
    d( "reset         - reset if it got stuck" )
    return
  elseif text == "debug off" then
    ADDON.SetSetting_debug(false)
  elseif text == "debug on" then
    ADDON.SetSetting_debug(true)
  elseif text == "reset" then
    ADDON.Core.Reset()
  end
end

-- Slash Commands --
SLASH_COMMANDS["/maillooter"] = CommandHandler

