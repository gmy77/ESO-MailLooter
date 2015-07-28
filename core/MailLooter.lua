

MailLooter = MailLooter or {}
local ADDON = MailLooter
ADDON.Core = ADDON.Core or {}
local CORE = ADDON.Core


-- MAIL_TYPE
local MAILTYPE_UNKNOWN  = 1
local MAILTYPE_AVA      = 2
local MAILTYPE_HIRELING = 3
local MAILTYPE_STORE    = 4
local MAILTYPE_COD      = 5
local MAILTYPE_RETURNED = 6

-- exported
CORE.MAILTYPE_UNKNOWN  = MAILTYPE_UNKNOWN
CORE.MAILTYPE_AVA      = MAILTYPE_AVA
CORE.MAILTYPE_HIRELING = MAILTYPE_HIRELING
CORE.MAILTYPE_STORE    = MAILTYPE_STORE
CORE.MAILTYPE_COD      = MAILTYPE_COD
CORE.MAILTYPE_RETURNED = MAILTYPE_RETURNED

local TitlesAvA = { 
  -- English
  ["Rewards for the Worthy!"] = true,
  -- ["For the Covenant!"] = true,  -- TODO: Need AD and EP versions too

  -- German
  ["Gerechter Lohn!"] = true,

  -- French
  ["La récompense des braves !"] = true,

}

local TitlesHirelings = {
  -- English
  ["Raw Blacksmith Materials"] = true, 
  ["Raw Woodworker Materials"] = true, 
  ["Raw Clothier Materials"] = true, 
  ["Raw Enchanter Materials"] = true, 
  ["Raw Provisioner Materials"] = true,

  -- German
  ["Schmiedematerial"] = true,
  ["Schreinermaterial"] = true,
  ["Schneidermaterial"] = true,
  ["Verzauberermaterial"] = true,
  ["Versorgerzutaten"] = true,

  -- French
  ["Matériaux bruts de forge"] = true,
  ["Matériaux bruts de travail du bois"] = true,
  ["Matériaux bruts de couture"] = true,
  ["Matériaux bruts d'enchantement"] = true,
  ["Matériaux bruts de cuisine"] = true,
}

local TitlesStores = {
  -- English
  ["Item Expired"] = true,
  ["Item Purchased"] = true,
  ["Item Canceled"] = true,
  ["Item Sold"] = true,

  -- German
  -- Need Expired
  ["Gegenstand gekauft"] = true, 
  ["Verkauf abgebrochen"] = true,
  ["Gegenstand verkauft"] = true, 

  -- French
  -- Need Expired
  ["Objet acheté"] = true,
  ["Objet annulé"] = true,
  ["Objet vendu"] = true,
  
}

local _

CORE.deconSpace = false

CORE.initialized = false
CORE.state = nil
CORE.loot = {items={}, money=0, mails=0, codTotal=0}
CORE.currentMail = {}
CORE.currentItems = {}

CORE.callbacks = nil

local testData = {}

local mailboxOpen = false
local mailLooterOpen = false

-- Processing States
local STATE_IDLE   = 0
local STATE_OPEN   = 1
local STATE_UPDATE = 11
local STATE_SCAN   = 2
local STATE_READ   = 3
local STATE_LOOT   = 4
local STATE_ITEMS  = 5
local STATE_MONEY  = 6
local STATE_DELETE = 7
local STATE_CLOSE  = 8
local STATE_TEST   = 42

CORE.state = STATE_IDLE


CORE.filters = {}
CORE.filters[MAILTYPE_UNKNOWN] = true
CORE.filters[MAILTYPE_AVA] = true
CORE.filters[MAILTYPE_HIRELING] = true
CORE.filters[MAILTYPE_STORE] = true
CORE.filters[MAILTYPE_COD] = false 
CORE.filters[MAILTYPE_RETURNED] = true 

--
-- Local Functions
--

-- Placeholder.
local function DEBUG(str) end

-- Detect the type of a mail message.
local function GetMailType(subject, fromSystem, codAmount, returned)

  if fromSystem then
    if TitlesAvA[subject] then
      return MAILTYPE_AVA
    elseif TitlesHirelings[subject] then
      return MAILTYPE_HIRELING
    elseif TitlesStores[subject] then
      return MAILTYPE_STORE
    end
  else
    if returned then return MAILTYPE_RETURNED end

    if codAmount > 0 then
      return MAILTYPE_COD
    end
  end

  return MAILTYPE_UNKNOWN
end

-- placeholder
local function LootThisMailCOD(codAmount, codTotal)
  return false
end

-- Return based on mailType and type filter.
local function LootThisMail(mailType, codAmount)

  -- filter
  if CORE.filters[mailType] then
    
    -- COD checks
    if (mailType == MAILTYPE_COD) then
  
      -- price check
      if codAmount > GetCurrentMoney() then return false end

      -- policy check
      return LootThisMailCOD(codAmount, CORE.loot.codTotal)
    end

    return true
  else
    return false
  end

end

local function GetFreeLootSpace()
  local space = GetNumBagFreeSlots(BAG_BACKPACK)

  if CORE.deconSpace then
    if space > 4 then space=space-4 else space=0 end
  end

  return space
end


local function IsRoomToLoot(mailId, numAtt)

  -- NOTE: Testing seems to show that you can not loot items that will
  --       stack unless at least one inventory space is open.
  if GetNumBagFreeSlots(BAG_BACKPACK) == 0 then return false end


  local space = GetFreeLootSpace()

  -- Easy case: there is room
  DEBUG("   numAtt: " .. numAtt .. " space: " .. space)
  if (numAtt <= space) then return true end

  -- harder case: see if items will stack
  local roomNeeded = 0

  for i=1,numAtt do
    local link = GetAttachedItemLink(mailId, i, LINK_STYLE_DEFAULT)

    if IsItemLinkStackable(link) then
      -- Stackable Item
      local _, stack = GetAttachedItemInfo(mailId, i)
      local stackCountBackpack = GetItemLinkStacks(link)

      if (stackCountBackpack == 0) then
        -- No item in backpack to stack with.
        DEBUG("No stacks for: " .. link)
        roomNeeded = roomNeeded + 1
      else
        -- We now might be able to stack.  To do this right we need to search 
        -- the backpack for the matching link?  And use:
        -- stack, maxStack = GetSlotStackSize(BAG_BACKPACK, slotIndex)
        -- to get the max stack size.
        --
        -- HACK: for now assume a max stack size of 200.
        --
        stackCountBackpack = stackCountBackpack % 200
        if (stackCountBackpack == 0) or 
           ((stack + stackCountBackpack) > 200) then

          DEBUG("Can not stack with: " .. link)
          roomNeeded = roomNeeded + 1

        else
          DEBUG("Will stack: " .. link .. 
                " s: " .. stack .. 
                " i: " .. stackCountBackpack)
        end
      end
    else
      -- NOT Stackable Item
      DEBUG("Not stackable: " .. link)
      roomNeeded = roomNeeded + 1
    end
  end

  DEBUG("   roomNeeded: " .. roomNeeded .. " space: " .. space)
  return (roomNeeded <= space)

end

local function AddItemsToHistory(loot, currentItems)

  local newItemType = false

  for ind,item in ipairs(currentItems) do

    if loot.items[item.link] == nil then
      loot.items[item.link] = item
      newItemType = true
    else
      loot.items[item.link].stack = loot.items[item.link].stack + item.stack
    end

    DEBUG( "MailLooter: " .. tostring(item.link))
    CORE.callbacks.ListUpdateCB(loot, false, item.link, newItemType)
  end

end

local function DoDeleteCmd()
  DEBUG( "DoDeleteCmd" )

  if CORE.state ~= STATE_DELETE then return end
  DeleteMail(CORE.currentMail.id, true)
end

local function SummaryScanMail()

  DEBUG( "SummaryScanMail" )

  local countAvA = 0
  local countHireling = 0
  local countCOD = 0
  local countStore = 0
  local countReturned = 0
  local countOther = 0
  local countItems = 0
  local countMoney = 0

  local id = GetNextMailId(nil)
  while id ~= nil do
    local sdn, scn, subject, icon, unread, fromSystem, fromCustomerService, returned, numAttachments, attachedMoney, codAmount, expiresInDays, secsSinceReceived = GetMailItemInfo(id)

    -- DEBUG(" -- Mail:" .. Id64ToString(id) .. " " .. subject .. " from:"..sdn.."/"..scn .. " sys:" .. tostring(fromSystem) .. " cs:"..tostring(fromCustomerService))

    countItems = countItems + numAttachments
    countMoney = countMoney + attachedMoney

    if codAmount > 0 then
      countCOD = countCOD + 1
      countMoney = countMoney + codAmount
    elseif TitlesAvA[subject] then
      countAvA = countAvA + 1
    elseif TitlesHirelings[subject] then
      countHireling = countHireling + 1
    elseif TitlesStores[subject] then
      countStore = countStore + 1
    elseif returned then
      countReturned = countReturned + 1
    else
      countOther = countOther + 1
    end

    id = GetNextMailId(id)
  end

  local result = { countAvA = countAvA, countHireling=countHireling, 
                   countCOD = countCOD, countStore = countStore,
                   countReturned = countReturned,
                   countOther = countOther, more = IsLocalMailboxFull(),
                   countItems = countItems, countMoney = countMoney }

  CORE.callbacks.ScanUpdateCB(result)

end

-- This function will loot zero to one mails.  Zero if there is no
-- room or no mail.  If there is a valid mail to loot then it will
-- be the loot process.
local function LootMails()
  DEBUG( "LootMails" )

  CORE.state = STATE_LOOT

  local failedNoSpace = false
  local id = GetNextMailId(nil)

  while id ~= nil do

    local sdn, scn, subject, icon, unread, fromSystem, fromCustomerService, returned, numAttachments, attachedMoney, codAmount, expiresInDays, secsSinceReceived = GetMailItemInfo(id)

    local mailType = GetMailType(subject, fromSystem, codAmount, returned)

    if LootThisMail(mailType, codAmount) then

      -- Loot this Mail
      DEBUG( "found mail: " .. Id64ToString(id) .. " '" .. 
             subject .. "' " .. numAttachments .. " " .. (secsSinceReceived/60))

      CORE.currentMail = { 
        id=id, att=numAttachments, money=attachedMoney, 
        codAmount=codAmount, mailType=mailType
      }

      -- Might care who it is from for non-system mail...
      if not fromSystem then
        CORE.currentMail.sdn = sdn
        CORE.currentMail.scn = scn
      end

      local v = CORE.currentMail

      local doItemLoot = false
      if (v.att > 0) then
        if IsRoomToLoot(id, numAttachments) then
          doItemLoot = true
        else
          failedNoSpace = true
        end
      end

      if doItemLoot then
        CORE.loot.mails = CORE.loot.mails + 1

        -- Setup currentItems moved from here to after readed event.

        DEBUG("items id=" .. Id64ToString(id))
        CORE.state = STATE_READ
        -- NOTE: Seems reading the mail help with getting items more reliably.
        RequestReadMail(id)
        return
      elseif (v.money ~= nil) and (v.money > 0) then
        DEBUG("money id=" .. Id64ToString(id))
        CORE.loot.mails = CORE.loot.mails + 1
        CORE.state = STATE_MONEY
        TakeMailAttachedMoney(id)
        return
      elseif v.att == 0 then 
        -- DELETE
        -- player may have manually looted and not deleted it.
        DEBUG("delete id=" .. Id64ToString(id))
        CORE.loot.mails = CORE.loot.mails + 1
        CORE.state = STATE_DELETE
        DeleteMail(id, true)
        return
      else
        -- NOOP
      end
    end

    CORE.currentMail = nil
    id = GetNextMailId(id)

  end

  if failedNoSpace then
    DEBUG ( "No room left in inventory" )
    CORE.callbacks.ListUpdateCB(CORE.loot, true, nil, false)
    CORE.state = STATE_IDLE
    CORE.loot = {items={}, money=0, mails=0, codTotal=0}
    CORE.callbacks.StatusUpdateCB(false, false, "Inventory Full")
    SummaryScanMail()
  else
    DEBUG ( "Done" )
    CORE.callbacks.ListUpdateCB(CORE.loot, true, nil, false)
    CORE.state = STATE_IDLE
    CORE.loot = {items={}, money=0, mails=0, codTotal=0}
    CORE.callbacks.StatusUpdateCB(false, true, nil)
    SummaryScanMail()
  end
end

local function LootMailsCont()
  DEBUG( "LootMailsCont" )

  -- Reading the attached items works better after reading the mail.
  CORE.currentItems = {}

  for i=1,CORE.currentMail.att do
    local icon, stack, creator = GetAttachedItemInfo(
      CORE.currentMail.id, i)
    local link = GetAttachedItemLink(
      CORE.currentMail.id, i, LINK_STYLE_DEFAULT)

    DEBUG("  item: " .. link .. " icon: " .. icon)

    table.insert(
      CORE.currentItems,
      { icon=icon, stack=stack, link=link, 
        mailType=CORE.currentMail.mailType }
    )
  end

  CORE.state = STATE_ITEMS
  -- BUG: Why does this sometimes fail???
  -- Work around: load the mail to be read first.
  TakeMailAttachedItems(CORE.currentMail.id)

end

local function Start(filter)
  DEBUG( "Start" )

  if CORE.state ~= STATE_IDLE then
    CORE.callbacks.StatusUpdateCB(false, false, "Core Not Ready")
    return
  end

  CORE.filters = filter

  CORE.loot = { items = {}, money = 0, mails = 0, codTotal=0 }
  CORE.currentMail = {}

  CORE.callbacks.StatusUpdateCB(true, true, nil)

  LootMails()

end

local function DoTestLoot()

  local step = testData.testSteps[testData.nextStep]
  if step ~= nil then
    testData.nextStep = testData.nextStep + 1

    testData.loot.money = testData.loot.money + step.money
    testData.loot.mails = testData.loot.mails + 1

    AddItemsToHistory(testData.loot, step.items)

    zo_callLater(DoTestLoot, 250)
  else
    DEBUG ( "Test Done" )
    CORE.callbacks.ListUpdateCB(testData.loot, true, nil, false)
    CORE.state = STATE_IDLE
    CORE.callbacks.StatusUpdateCB(false, true, nil)
    SummaryScanMail()
  end

end

--
-- Event Handler Functions
--

function CORE.OpenMailboxEvt( eventCode )

  DEBUG( "OpenMailbox" )
  mailboxOpen = true
  
  if mailLooterOpen then
    if CORE.state == STATE_OPEN then
      CORE.state = STATE_UPDATE
    end
  end

end

function CORE.CloseMailboxEvt( eventCode )

  DEBUG( "CloseMailbox state=" .. CORE.state)
  mailboxOpen = false

  if CORE.state == STATE_CLOSE then
    CORE.state = STATE_IDLE
    DEBUG( "MailLooter closed" )
  elseif mailLooterOpen then
    if CORE.state ~= STATE_IDLE then
      -- FIXME - Error!!
      CORE.state = STATE_IDLE
      DEBUG("MailLooter error!  Mailbox closed.")
      CORE.callbacks.StatusUpdateCB(false, false, "Mailbox Closed")
    end
  end

end

function CORE.InboxUpdateEvt( eventCode )
  DEBUG( "InboxUpdate state=" .. CORE.state )

  if mailLooterOpen then
    if (CORE.state == STATE_IDLE) or
       (CORE.state == STATE_UPDATE) then
      
      CORE.state = STATE_IDLE
      SummaryScanMail()
    end
  end
end

function CORE.MailReadableEvt( eventCode, mailId)
  DEBUG( "MailReadable state=" .. CORE.state .. " id=" .. Id64ToString(mailId) )

  if mailLooterOpen then
    if (CORE.state == STATE_READ) and (CORE.currentMail.id == mailId) then
        LootMailsCont()
    end
  end

end

function CORE.MailRemovedEvt( eventCode, mailId )
  DEBUG( "MailRemoved state=" .. CORE.state .. " id=" .. Id64ToString(mailId) )

  if mailLooterOpen then
    if CORE.state ~= STATE_DELETE then return end

    if (CORE.currentMail.id == mailId) then
      CORE.currentMail = nil
      LootMails()
    end
  end

  DEBUG( "MailRemoved end" )
end

function CORE.TakeItemsEvt( eventCode, mailId )
  DEBUG( "TakeItems state=" .. CORE.state )

  if mailLooterOpen then
    if CORE.state ~= STATE_ITEMS then return end

    if CORE.currentMail.id == mailId then

      if CORE.currentMail.codAmount > 0 then
        CORE.loot.codTotal = CORE.loot.codTotal + CORE.currentMail.codAmount
      end

      AddItemsToHistory(CORE.loot, CORE.currentItems)
      CORE.currentItems = {}

      if (CORE.currentMail.money ~= nil) and (CORE.currentMail.money > 0) then
        CORE.state = STATE_MONEY
        TakeMailAttachedMoney(CORE.currentMail.id)
      else
        CORE.state = STATE_DELETE
        DeleteMail(CORE.currentMail.id, true)
      end
    end
  end

  DEBUG( "TakeItems end" )
end

function CORE.TakeMoneyEvt( eventCode, mailId )
  DEBUG( "TakeMoney state=" .. CORE.state )

  if mailLooterOpen then
    if CORE.state ~= STATE_MONEY then return end

    if (CORE.currentMail.id == mailId) then
      CORE.loot.money = CORE.loot.money + CORE.currentMail.money

      CORE.state = STATE_DELETE
      zo_callLater(DoDeleteCmd, 1)
      --DeleteMail(CORE.currentMail.id, true)
    end
  end

  DEBUG( "TakeMoney end" )
end

function CORE.InventoryFullEvt( eventCode, numSlotsReq, numSlotFree )
  DEBUG( "InventoryFull state=" .. CORE.state )

  if mailLooterOpen then
    if CORE.state ~= STATE_ITEMS then return end

    -- Must match the number of items we are looting.
    if numSlotsReq ~= CORE.currentMail.att then return end

    -- This is now PROBABLY in response to our take item request.

    -- Need to fail.  Trying again will lead to an infinite loop.
    DEBUG( "Inventory full ERROR!" )
    CORE.state = STATE_IDLE
    CORE.callbacks.StatusUpdateCB(false, false, "Inventory Full")
    SummaryScanMail()
  end

  DEBUG( "InventoryFull end" )
end

function CORE.NotEnoughMoneyEvt( eventCode )
  DEBUG( "NotEnoughMoney state=" .. CORE.state )

  if mailLooterOpen then
    if CORE.state ~= STATE_ITEMS then return end

    if CORE.currentMail.codAmount > 0 then 
      DEBUG( "Not enough money for COD!" )
      CORE.state = STATE_IDLE
      CORE.callbacks.StatusUpdateCB(false, false, "Not enough money")
      SummaryScanMail()
    end
  end
end

--
-- Public Functions
--

-- This function must be called from the client ADDON's 
-- EVENT_ADD_ON_LOADED handler.
function CORE.Initialize(saveDeconSpace, debugFunction, codTestFunction)

  if CORE.initialized then return end -- exit if already init'd.

  CORE.initialized = true

  CORE.deconSpace = saveDeconSpace

  if debugFunction then
    DEBUG = function(msg) debugFunction("CORE: " .. msg) end
  end

  if codTestFunction then
    LootThisMailCOD = codTestFunction
  end

  EVENT_MANAGER:RegisterForEvent(
    ADDON.NAME, EVENT_MAIL_OPEN_MAILBOX, CORE.OpenMailboxEvt )
  EVENT_MANAGER:RegisterForEvent(
    ADDON.NAME, EVENT_MAIL_CLOSE_MAILBOX, CORE.CloseMailboxEvt )
  EVENT_MANAGER:RegisterForEvent(
    ADDON.NAME, EVENT_MAIL_INBOX_UPDATE, CORE.InboxUpdateEvt )
  EVENT_MANAGER:RegisterForEvent(
    ADDON.NAME, EVENT_MAIL_READABLE, CORE.MailReadableEvt )

  EVENT_MANAGER:RegisterForEvent(
    ADDON.NAME, EVENT_MAIL_REMOVED, CORE.MailRemovedEvt )

  EVENT_MANAGER:RegisterForEvent(
    ADDON.NAME, EVENT_MAIL_TAKE_ATTACHED_ITEM_SUCCESS, CORE.TakeItemsEvt )
  EVENT_MANAGER:RegisterForEvent(
    ADDON.NAME, EVENT_MAIL_TAKE_ATTACHED_MONEY_SUCCESS, CORE.TakeMoneyEvt )

  EVENT_MANAGER:RegisterForEvent(
    ADDON.NAME, EVENT_INVENTORY_IS_FULL, CORE.InventoryFullEvt )
  EVENT_MANAGER:RegisterForEvent(
    ADDON.NAME, EVENT_NOT_ENOUGH_MONEY, CORE.NotEnoughMoneyEvt )

end

-- Call to start a MailLooter session.
function CORE.OpenMailLooter()

  mailLooterOpen = true

  if not mailboxOpen then
    CORE.state = STATE_OPEN
    RequestOpenMailbox()
  else
    CORE.state = STATE_IDLE
    SummaryScanMail()
  end
end

-- Call to end a MailLooter session.
function CORE.CloseMailLooter()
  if mailLooterOpen then
    mailLooterOpen = false
    CORE.state = STATE_CLOSE
    CloseMailbox()
  else
    CORE.state = STATE_CLOSE
  end
end

-- Set to true to reserve 4 inventory spaces that are needed to do deconstucts.
function CORE.SetSaveDeconSpace(val)
  CORE.deconSpace = val
end

function CORE.GetSaveDeconSpace()
  return CORE.deconSpace
end

-- Register callbacks with the Core.
--
-- listUpdateCB
--   This callback informs the upper layer of the items looted from 
--   the mailbox.  It is call for each item looted from mail, and then
--   once when the looting is complete.  The last time will have 
--   isDone=true and itemLink=nil.
--
--   function listUpdateCB(itemTable = {items ={[link] -> {icon, stack, creator, link}}, money, mails}, isDone, itemLink)
--
-- statusUpdateCB
--
--   function statusUpdateCB(inProgress, success, msg)
--
-- scanUpdateCB
--
--   function scanUpdateCB(summary = {countAVA, countHireling, countStore, countCOD, countOther, more})
--
function CORE.NewCallbacks(listUpdateCB, statusUpdateCB, scanUpdateCB)

  local s = {}
  s.ListUpdateCB = listUpdateCB
  s.StatusUpdateCB = statusUpdateCB
  s.ScanUpdateCB = scanUpdateCB

  CORE.callbacks = s

end


-- Start looting the mailbox.
function CORE.ProcessMailAll()

  if CORE.state ~= STATE_IDLE then 
    DEBUG( "MailLooter is currently running" )
    return
  end
 
  local filter = {}
  filter[MAILTYPE_UNKNOWN] = false
  filter[MAILTYPE_AVA] = true
  filter[MAILTYPE_HIRELING] = true
  filter[MAILTYPE_STORE] = true
  filter[MAILTYPE_RETURNED] = true

  -- Don't auto loot COD.  So one can troll you for
  -- lots of money if your not watching..
  filter[MAILTYPE_COD] = true

  DEBUG( "MailLooter starting all loot" )
  Start(filter)

end

-- New Version
-- Start looting the mailbox.
-- Allows filtering on mail type.
function CORE.ProcessMail(filter)
end

-- Attempt to recover from a failure, or cancel an ongoing looting.
function CORE.Reset()
  DEBUG( "MailLooter reset" )

  if mailLooterOpen then
    CORE.state = STATE_IDLE
    CORE.callbacks.StatusUpdateCB(false, false, "Cancel")
    SummaryScanMail()
  end
end

-- Returns true if the core is ready for a command.
function CORE.IsIdle()
  return CORE.state == STATE_IDLE
end

-- Returns true if the core is ready to perform a mailbox looting.
function CORE.IsActionReady()

  if (CORE.state == STATE_IDLE) and 
     (GetNumMailItems() > 0)
  then
    return true
  end

  return false
end

-- Test functions to fake loot mail.
function CORE.TestLoot()
  
  if not (mailLooterOpen and (CORE.state == STATE_IDLE)) then
    d("Test function can not run right now")
    return
  end

  DEBUG("TestLoot start")

  local realItem = {}
  realItem[1] =
  {
    ["stack"] = 1,
    ["icon"] = "/esoui/art/icons/crafting_forester_weapon_vendor_component_002.dds",
    ["mailType"] = MAILTYPE_HIRELING,
    ["link"] = "|H1:item:54171:32:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|hdwarven oil|h",
    ["creator"] = "",
  }

  realItem[2] =
  {
    ["stack"] = 5,
    ["icon"] = "/esoui/art/icons/crafting_ore_voidstone.dds",
    ["mailType"] = 3,
    ["link"] = "|H1:item:23135:30:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|hvoidstone ore|h",
    ["creator"] = "",
  }

  realItem[3] =
  {
    ["stack"] = 2,
    ["icon"] = "/esoui/art/icons/crafting_ore_palladium.dds",
    ["mailType"] = 3,
    ["link"] = "|H1:item:46152:30:50:0:0:0:0:0:0:0:0:0:0:0:0:15:0:0:0:0:0|hPalladium|h",
    ["creator"] = "",
  }

  realItem[4] = 
  {
    ["stack"] = 1,
    ["icon"] = "/esoui/art/icons/crafting_wood_turpen.dds",
    ["mailType"] = 3,
    ["link"] = "|H1:item:54179:32:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|hturpen|h",
    ["creator"] = "",
  }

  local testItem = {}
  for i=1,20 do
    testItem[i] = { 
      link=ZO_LinkHandler_CreateLink(
        "Test Trash" .. i, nil, ITEM_LINK_TYPE, 45336, 1, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 10000, 0),
      stack=1, 
      mailType=(i%6)+1, 
      icon='/esoui/art/icons/crafting_components_spice_004.dds',
      creator="",
      sdn="Lodur",
      scn="Lodur Ravensen",
    }
  end


  testData = {
    loot = { items={}, money=0, mails=0, codTotal=0 },
    nextStep = 1,
    testSteps = {
      { items={realItem[1],realItem[2],realItem[3]}, money=25 },
      { items={realItem[4]}, money=25 },
      { items={realItem[1],realItem[2],realItem[3]}, money=25 },
      { items={realItem[4]}, money=25 },
      { items={realItem[1],realItem[2],realItem[3]}, money=25 },
      { items={realItem[4]}, money=25 },
      { items={realItem[1],realItem[2],realItem[3]}, money=25 },
      { items={realItem[4]}, money=25 },
    },
  }

  for i=1,20 do
    table.insert(testData.testSteps, {items={testItem[i]}, money=1})
  end

  CORE.callbacks.StatusUpdateCB(true, true, nil)
  CORE.state = STATE_TEST

  zo_callLater(DoTestLoot, 250)

end

-- Scan inbox and print out interesting things about mails.
function CORE.Scan()

  if not (mailLooterOpen and (CORE.state == STATE_IDLE)) then
    d("Scan function can not run right now")
    return
  end

  local id = GetNextMailId(nil)

  local t = {}

  while id ~= nil do

    local _, _, subject, icon, unread, fromSystem, fromCustomerService, returned, 
      numAttachments, attachedMoney, codAmount, expiresInDays, secsSinceReceived = GetMailItemInfo(id)

    local mailType = GetMailType(subject, fromSystem, codAmount, returned)

    d("mail id=" .. Id64ToString(id) )
    d("-> subject='" .. subject .. "'")
    d("-> system=" .. tostring(fromSystem))
    d("-> custService=" .. tostring(fromCustomerService))
    d("-> returned=" .. tostring(returned))
    d("-> numAtt=" .. numAttachments .. " money=" .. attachedMoney .. " cod=" .. codAmount)

    table.insert(t, {id=id, subject=subject, system=fromSystem})

    id = GetNextMailId(id)
  end

  return t
end

