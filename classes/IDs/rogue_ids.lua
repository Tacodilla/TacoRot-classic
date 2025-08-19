-- rogue_ids.lua — Classic Anniversary Rogue IDs
DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[TacoRot]|r Rogue IDS loaded")

local IDS = {
  Ability = {
    Main       = 1752, -- Sinister Strike
    Buff       = 5171, -- Slice and Dice
    AutoAttack = 6603,
  },
  Rank = {
    Main = {1752,1757,1758,1759,1760,8621,11293,11294},
    Buff = {5171,6774},
    AutoAttack = {6603},
  },
  Spell = {
    Assassination = {
      Eviscerate     = 2098,
      Rupture        = 1943,
      Garrote        = 703,
      ColdBlood      = 14177,
    },
    Combat = {
      SinisterStrike = 1752,
      Gouge          = 1776,
      Kick           = 1766,
      Sprint         = 2983,
      BladeFlurry    = 13877,
    },
    Subtlety = {
      Backstab       = 53,
      Ambush         = 8676,
      CheapShot      = 1833,
      KidneyShot     = 408,
      Hemorrhage     = 16511,
      Vanish         = 1856,
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

_G.TacoRot_IDS_Rogue = IDS

_G.TacoRotIconFallbacks = _G.TacoRotIconFallbacks or {}
local fb = _G.TacoRotIconFallbacks
local function setOnce(id, tex) if id and not fb[id] then fb[id] = tex end end
setOnce(1752, "Interface\\Icons\\Ability_Rogue_SinisterStrike")
setOnce(5171, "Interface\\Icons\\Ability_Rogue_SliceDice")
setOnce(6603, "Interface\\Icons\\Ability_MeleeDamage")
