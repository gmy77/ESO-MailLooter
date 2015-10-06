
MailLooter = MailLooter or {}
local ADDON = MailLooter
ADDON.UI = ADDON.UI or {}
local UI = ADDON.UI

function ADDON.UI.CreateScene(
  summaryFragment, overviewFragment, filterFragment, lootFragment)

  MAIL_LOOTER_SCENE = ZO_Scene:New("mailLooter", SCENE_MANAGER)
  MAIL_LOOTER_SCENE:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW)
  MAIL_LOOTER_SCENE:AddFragmentGroup(
    FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL)
  MAIL_LOOTER_SCENE:AddFragment(RIGHT_BG_FRAGMENT)
  MAIL_LOOTER_SCENE:AddFragment(TREE_UNDERLAY_FRAGMENT)

  -- MAIL_LOOTER_SCENE:AddFragment(DISPLAY_NAME_FRAGMENT)
  MAIL_LOOTER_SCENE:AddFragment(TITLE_FRAGMENT)
  MAIL_LOOTER_SCENE:AddFragment(MAIL_TITLE_FRAGMENT)

  MAIL_LOOTER_SCENE:AddFragment(summaryFragment.FRAGMENT)
  MAIL_LOOTER_SCENE:AddFragment(overviewFragment.FRAGMENT)
  MAIL_LOOTER_SCENE:AddFragment(filterFragment.FRAGMENT)
  MAIL_LOOTER_SCENE:AddFragment(lootFragment.FRAGMENT)

  local index = #MAIN_MENU_KEYBOARD.sceneGroupInfo.mailSceneGroup.menuBarIconData + 1
  MAIN_MENU_KEYBOARD.sceneGroupInfo.mailSceneGroup.menuBarIconData[index] = {
    categoryName = SI_MAIL_LOOTER,
    descriptor = "mailLooter",
    normal = "EsoUI/Art/MainMenu/menuBar_inventory_up.dds",
    pressed = "EsoUI/Art/MainMenu/menuBar_inventory_down.dds",
    highlight = "EsoUI/Art/MainMenu/menuBar_inventory_over.dds",
  }

  local MAIL_CAT = MAIN_MENU_KEYBOARD.sceneGroupInfo.mailSceneGroup.category

  SCENE_MANAGER:GetSceneGroup("mailSceneGroup").scenes[index] = "mailLooter"
  MAIL_LOOTER_SCENE:AddFragment(
    ZO_FadeSceneFragment:New(MAIN_MENU_KEYBOARD.sceneGroupBar))

  MAIL_LOOTER_SCENE:RegisterCallback("StateChange", UI.SceneStateChange)

  MAIN_MENU_KEYBOARD:AddRawScene(
    "mailLooter", MAIL_CAT, MAIN_MENU_KEYBOARD.categoryInfo[MAIL_CAT], "mailSceneGroup")

end
