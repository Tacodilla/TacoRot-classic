-- druid_ids.lua — Classic Anniversary Druid IDs
DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[TacoRot]|r Druid IDS loaded")

local IDS = {
  Ability = {
    Main       = 5176,  -- Wrath
    Buff       = 774,   -- Rejuvenation
    AutoAttack = 6603,
  },
  Rank = {
    Main = {5176,5177,5178,5179,5180,6780,8905,9912},
    Buff = {774,1058,1430,2090,2091,3627,8910,9839,9840,9841},
    AutoAttack = {6603},
  },
  Spell = {
    Balance = {
      Wrath        = 5176,
      Moonfire     = 8921,
      Starfire     = 2912,
      InsectSwarm  = 5570,
      Hurricane    = 16914,
    },
    Feral = {
      Claw         = 1082,
      Rake         = 1822,
      Shred        = 5221,
      Rip          = 1079,
      FerociousBite= 22568,
      Prowl        = 5215,
      Maul         = 6807,
      Swipe        = 779,
      Growl        = 6795,
      DemoralizingRoar = 99,
      Bash         = 5211,
    },
    Restoration = {
      HealingTouch = 5185,
      Regrowth     = 8936,
      Rejuvenation = 774,
      Swiftmend    = 18562,
      Tranquility  = 740,
      Innervate    = 29166,
    }
  }
}

local function bestRank(list)
  if not list then return nil end
  for i = #list, 1, -1 do
    local id = list[i]
    if IsSpellKnown and IsSpellKnown(id) then
      return id
    end
  end
  return list[#list] or list[1]
end

function IDS:UpdateRanks()
  for key, list in pairs(self.Rank) do
    local id = bestRank(list)
    if id then self.Ability[key] = id end
  end
end

_G.TacoRot_IDS_Druid = IDS

_G.TacoRotIconFallbacks = _G.TacoRotIconFallbacks or {}
local fb = _G.TacoRotIconFallbacks
local function setOnce(id, tex) if id and not fb[id] then fb[id] = tex end end
setOnce(5176, "Interface\\Icons\\Spell_Nature_StarFall")
setOnce(774,  "Interface\\Icons\\Spell_Nature_Rejuvenation")
setOnce(6603, "Interface\\Icons\\Ability_MeleeDamage")
