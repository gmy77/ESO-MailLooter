
eso_addon_MailLooter = eso_addon_MailLooter or {}
local ADDON = eso_addon_MailLooter
ADDON.UI = ADDON.UI or {}
local UI = ADDON.UI

-- local function AddNameLabel(name, text, parent, after)
--   local win = WINDOW_MANAGER:CreateControl(
--                 "MAIL_LOOTER_SUMMARY_NLABEL_" .. name,
--                 parent,
--                 CT_LABEL)
-- 
--   win:SetFont("ZoGameFont")
--   if after ~= nil then
--     win:SetText("   " .. text)
--     win:SetAnchor(LEFT, after, RIGHT, 0, 0)
--   else
--     win:SetText(text)
--   end
-- 
--   return win
-- end
-- 
-- local function AddValueLabel(name, parent, after)
--   local win = WINDOW_MANAGER:CreateControl(
--                 "MAIL_LOOTER_SUMMARY_VLABEL_" .. name,
--                 parent,
--                 CT_LABEL)
-- 
--   win:SetText("00+")
--   win:SetFont("ZoGameFont")
--   win:SetAnchor(LEFT, after, RIGHT, 0, 0)
-- 
--   return win
-- end

function UI.CreateSummaryFragment()
  local fragment = {}
  fragment.win = WINDOW_MANAGER:CreateTopLevelWindow(
                   "MailLooterSummaryFragment")
 
  fragment.win:SetWidth(ZO_MailInbox:GetWidth())
  fragment.win:SetAnchor(TOP, ZO_MailInbox, TOP, 0, 0)
  fragment.win:SetHidden(true)

  WINDOW_MANAGER:CreateControlFromVirtual(
    "MAIL_LOOTER_SUMMARY_TITLE", fragment.win, "ZO_PanelTitle")
  MAIL_LOOTER_SUMMARY_TITLE:SetAnchor(TOP, fragment.win, TOP, 0, 0)
  MAIL_LOOTER_SUMMARY_TITLELabel:SetText("SUMMARY")
  -- MAIL_LOOTER_SUMMARY_TITLELabel:SetFont("ZoFontBookSkin")
  MAIL_LOOTER_SUMMARY_TITLELabel:SetFont("ZoFontWinH2")
  MAIL_LOOTER_SUMMARY_TITLELabel:SetAnchor(
    CENTER, MAIL_LOOTER_SUMMARY_TITLEDivider, CENTER, 0, -15)
  MAIL_LOOTER_SUMMARY_TITLEDivider:SetDimensions(800,2)

--  fragment.background = WINDOW_MANAGER:CreateControl(
--    "MailLooterSummaryBackground", fragment.win, CT_BACKDROP)
--  fragment.background:SetAnchorFill(fragment.win)
--  fragment.background:SetCenterColor(1,0,0,1)


--  local strwin = WINDOW_MANAGER:CreateControl(
--                    "MAIL_LOOTER_SUMMARY_STRING",
--                    fragment.win, CT_CONTROL)
--  strwin:SetHidden(false)
--
--  local n1 = AddNameLabel("ALL", "All Mail: ", strwin, nil)
--  n1:SetAnchor(LEFT, strwin, LEFT, 0, 0)
--  local v1 = AddValueLabel("ALL", strwin, n1)
--
--  local n2 = AddNameLabel("UNREAD", "Unread: ", strwin, v1)
--  local v2 = AddValueLabel("UNREAD", strwin, n2)
--
--  local n3 = AddNameLabel("LOOTABLE", "Lootable: ", strwin, v2)
--  local v3 = AddValueLabel("LOOTABLE", strwin, n3)
--
--  local n4 = AddNameLabel("AVA", "AvA: ", strwin, v3)
--  local v4 = AddValueLabel("AVA", strwin, n4)
--
--  local n5 = AddNameLabel("HIRELING", "Hireling: ", strwin, v4)
--  local v5 = AddValueLabel("HIRELING", strwin, n5)
--
--  local n6 = AddNameLabel("STORE", "Store: ", strwin, v5)
--  local v6 = AddValueLabel("STORE", strwin, n6)
--
--  local n7 = AddNameLabel("COD", "CoD: ", strwin, v6)
--  local v7 = AddValueLabel("COD", strwin, n7)
--
--  local n8 = AddNameLabel("OTHER", "Other: ", strwin, v7)
--  local v8 = AddValueLabel("OTHER", strwin, n8)

--  strwin:SetHeight(n1:GetHeight())
--  strwin:SetWidth(500)
--  strwin:SetAnchor(TOP, MAIL_LOOTER_SUMMARY_TITLEDivider, BOTTOM, 0, 10)

--  local bstrwin = WINDOW_MANAGER:CreateControl(
--    "MailLooterSummaryBackgroundX", strwin, CT_BACKDROP)
--  bstrwin:SetAnchorFill(strwin)
--  bstrwin:SetCenterColor(0.1,0.1,0.1,0.2)
--
--  UI.summaryLabelFrame = strwin
--  UI.summaryLabelAll = v1
--  UI.summaryLabelUnread = v2
--  UI.summaryLabelLootable = v3
--  UI.summaryLabelAVA = v4
--  UI.summaryLabelHireling = v5
--  UI.summaryLabelStore = v6
--  UI.summaryLabelCOD = v7
--  UI.summaryLabelOther = v8

  local label = WINDOW_MANAGER:CreateControl(
    "MAIL_LOOTER_SUMMARY_TEXT", fragment.win, CT_LABEL)

  label:SetFont("ZoFontGame")
  label:SetText("XXX")
  label:SetWidth(800)
  label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
  label:SetAnchor(TOP, MAIL_LOOTER_SUMMARY_TITLEDivider, BOTTOM, 0, 10)

  UI.summaryLabel = label

  fragment.FRAGMENT = ZO_FadeSceneFragment:New(fragment.win)

  return fragment

end

