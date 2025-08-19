-- paladin_ids.lua — Classic Anniversary Paladin IDs
DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[TacoRot]|r Paladin IDS loaded")

local IDS = {
  Ability = {
    Main       = 20271, -- Judgement
    Buff       = 19740, -- Blessing of Might
    AutoAttack = 6603,
  },
  Rank = {
    Main = {20271},
    Buff = {19740,19834,19835,19836,19837,19838},
    AutoAttack = {6603},
  },
  Spell = {
    Holy = {
      HolyLight          = 635,
      FlashOfLight       = 19750,
      HolyShock          = 20473,
      Cleanse            = 4987,
      LayOnHands         = 633,
    },
    Protection = {
      DevotionAura       = 465,
      Consecration       = 26573,
      HammerOfJustice    = 853,
      BlessingOfProtection = 1022,
      DivineShield       = 642,
    },
    Retribution = {
      Judgement          = 20271,
      SealOfCommand      = 20375,
      Exorcism           = 879,
      HolyWrath          = 2812,
      SealOfRighteousness= 21084,
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

_G.TacoRot_IDS_Paladin = IDS

_G.TacoRotIconFallbacks = _G.TacoRotIconFallbacks or {}
local fb = _G.TacoRotIconFallbacks
local function setOnce(id, tex) if id and not fb[id] then fb[id] = tex end end
setOnce(20271, "Interface\\Icons\\Spell_Holy_RighteousFury")
setOnce(19740, "Interface\\Icons\\Spell_Holy_FistOfJustice")
setOnce(6603,  "Interface\\Icons\\Ability_MeleeDamage")
