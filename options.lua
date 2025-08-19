-----------------------------------
-- options.lua — Classic Anniversary Options
-----------------------------------

local TR = _G.TacoRot
if not TR then return end
local Registry = LibStub("AceConfigRegistry-3.0", true)
if not Registry then return end

local CLASS_NAMES = {
  WARRIOR = "Warrior",
  PALADIN = "Paladin",
  HUNTER = "Hunter",
  ROGUE = "Rogue",
  PRIEST = "Priest",
  SHAMAN = "Shaman",
  MAGE = "Mage",
  WARLOCK = "Warlock",
  DRUID = "Druid",
}

-- DB seeds
local function EnsurePad(token)
  if not (TR and TR.db and TR.db.profile) then return end
  TR.db.profile.pad = TR.db.profile.pad or {}
  TR.db.profile.pad[token] = TR.db.profile.pad[token] or { enabled = true, gcd = 1.5 }
  if TR.db.profile.pad[token].enabled == nil then TR.db.profile.pad[token].enabled = true end
  TR.db.profile.pad[token].gcd = TR.db.profile.pad[token].gcd or 1.5
end

local function EnsureBuff(token)
  if not (TR and TR.db and TR.db.profile) then return end
  TR.db.profile.buff = TR.db.profile.buff or {}
  TR.db.profile.buff[token] = TR.db.profile.buff[token] or { enabled = true }
  if TR.db.profile.buff[token].enabled == nil then TR.db.profile.buff[token].enabled = true end
end

local function EnsurePet(token)
  if not (TR and TR.db and TR.db.profile) then return end
  TR.db.profile.pet = TR.db.profile.pet or {}
  TR.db.profile.pet[token] = TR.db.profile.pet[token] or { enabled = true }
  if TR.db.profile.pet[token].enabled == nil then TR.db.profile.pet[token].enabled = true end
end

-- UI helpers
local function addPaddingGroup(node, token)
  EnsurePad(token)
  node.args.padding = {
    type = "group", name = "Padding", order = 2, inline = true,
    args = {
      enabled = {
        type = "toggle", order = 1, name = "Enable low-level padding",
        get = function() return TR.db.profile.pad[token].enabled end,
        set = function(_, v) TR.db.profile.pad[token].enabled = v and true or false end
      },
      gcd = {
        type = "range", order = 2, name = "Pad window (seconds)", min = 0, max = 2, step = 0.05,
        get = function() return TR.db.profile.pad[token].gcd end,
        set = function(_, v) TR.db.profile.pad[token].gcd = tonumber(v) or 1.5 end
      },
    },
  }
end

local function addBuffsGroup(node, token, fields)
  EnsureBuff(token)
  node.args.buffs = { type = "group", name = "Buffs", order = 3, inline = true, args = {} }
  local args = node.args.buffs.args
  args.enabled = {
    type = "toggle", order = 1, name = "Suggest out-of-combat buffs",
    get = function() return (TR.db.profile.buff[token] or {}).enabled ~= false end,
    set = function(_, v) TR.db.profile.buff[token].enabled = v and true or false end,
  }
  local ord = 2
  for key, label in pairs(fields or {}) do
    if TR.db.profile.buff[token][key] == nil then TR.db.profile.buff[token][key] = true end
    args[key] = {
      type = "toggle", order = ord, name = label,
      disabled = function() return (TR.db.profile.buff[token] or {}).enabled == false end,
      get = function() return (TR.db.profile.buff[token] or {})[key] ~= false end,
      set = function(_, v) TR.db.profile.buff[token][key] = v and true or false end,
    }
    ord = ord + 1
  end
end

local function addPetsGroup(node, token, fields)
  EnsurePet(token)
  node.args.pets = { type = "group", name = "Pets", order = 4, inline = true, args = {} }
  local args = node.args.pets.args
  args.enabled = {
    type = "toggle", order = 1, name = "Suggest pet actions (OOC)",
    get = function() return (TR.db.profile.pet[token] or {}).enabled ~= false end,
    set = function(_, v) TR.db.profile.pet[token].enabled = v and true or false end,
  }
  local ord = 2
  for key, label in pairs(fields or {}) do
    if TR.db.profile.pet[token][key] == nil then TR.db.profile.pet[token][key] = true end
    args[key] = {
      type = "toggle", order = ord, name = label,
      disabled = function() return (TR.db.profile.pet[token] or {}).enabled == false end,
      get = function() return (TR.db.profile.pet[token] or {})[key] ~= false end,
      set = function(_, v) TR.db.profile.pet[token][key] = v and true or false end,
    }
    ord = ord + 1
  end
end

local function addSpellToggles(groupNode, abilities)
  local order = 1
  for key, spellID in pairs(abilities or {}) do
    if type(spellID) == "number" then
      local name, _, icon = GetSpellInfo(spellID)
      name = name or tostring(key) or ("Spell " .. spellID)
      groupNode.args["s" .. spellID] = {
        type = "toggle", width = "full", order = order,
        name = (icon and ("|T" .. icon .. ":16|t ") or "") .. name,
        get = function() 
          local v = TR.db and TR.db.profile and TR.db.profile.spells and TR.db.profile.spells[spellID]
          return v ~= false
        end,
        set = function(_, v)
          TR.db.profile.spells = TR.db.profile.spells or {}
          TR.db.profile.spells[spellID] = v and true or false
        end,
      }
      order = order + 1
    end
  end
end

local function BuildClassOptions()
  local opts = TR.OptionsRoot
  if not (opts and opts.args) then return end
  if not opts.args.class then
    opts.args.class = { type = "group", name = "Class", order = 20, childGroups = "tree", args = {} }
  else
    opts.args.class.args = {}
  end

  local _, token = UnitClass("player")
  local function addClass(camel, idsGlobalName, key, buffFields, petFields)
    local IDS = _G[idsGlobalName]
    if IDS and IDS.UpdateRanks then IDS:UpdateRanks() end
    local node = {
      type = "group", name = camel, order = 1,
      args = {
        spells = { type = "group", name = "Spells", order = 1, args = {} }
      }
    }
    addSpellToggles(node.args.spells, IDS and IDS.Ability)
    addPaddingGroup(node, token)
    if buffFields then addBuffsGroup(node, token, buffFields) end
    if petFields then addPetsGroup(node, token, petFields) end
    opts.args.class.args[key] = node
  end

  -- Class-specific options
  if token == "HUNTER" then
    addClass("Hunter", "TacoRot_IDS_Hunter", "hunter",
      { aspect = "Aspect of the Hawk", trueshot = "Trueshot Aura" },
      { summon = "Call Pet", revive = "Revive Pet", mend = "Mend Pet" }
    )
  elseif token == "WARRIOR" then
    addClass("Warrior", "TacoRot_IDS_Warrior", "warrior",
      { battleShout = "Battle Shout" },
      nil
    )
  elseif token == "ROGUE" then
    addClass("Rogue", "TacoRot_IDS_Rogue", "rogue", nil, nil)
  elseif token == "MAGE" then
    addClass("Mage", "TacoRot_IDS_Mage", "mage",
      { armor = "Mage Armor", intellect = "Arcane Intellect" },
      nil
    )
  elseif token == "WARLOCK" then
    addClass("Warlock", "TacoRot_IDS_Warlock", "warlock",
      { armor = "Demon Armor" },
      { summon = "Summon Demon" }
    )
  elseif token == "PRIEST" then
    addClass("Priest", "TacoRot_IDS_Priest", "priest",
      { innerFire = "Inner Fire", fortitude = "Power Word: Fortitude" },
      nil
    )
  elseif token == "PALADIN" then
    addClass("Paladin", "TacoRot_IDS_Paladin", "paladin",
      { seal = "Seal", blessing = "Blessing" },
      nil
    )
  elseif token == "SHAMAN" then
    addClass("Shaman", "TacoRot_IDS_Shaman", "shaman",
      { lightningShield = "Lightning Shield", weapon = "Weapon Enchant" },
      nil
    )
  elseif token == "DRUID" then
    addClass("Druid", "TacoRot_IDS_Druid", "druid",
      { mark = "Mark of the Wild", thorns = "Thorns" },
      nil
    )
  end

  Registry:NotifyChange("TacoRot")
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
  for tok in pairs(CLASS_NAMES) do
    EnsurePad(tok)
    EnsureBuff(tok)
    EnsurePet(tok)
  end
  BuildClassOptions()
end)

function TR:RebuildOptions() BuildClassOptions() end