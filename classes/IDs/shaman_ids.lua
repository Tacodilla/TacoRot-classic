-- shaman_ids.lua — Classic Anniversary Shaman IDs
DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[TacoRot]|r Shaman IDS loaded")

local IDS = {
  Ability = {
    Main       = 403,  -- Lightning Bolt
    Buff       = 324,  -- Lightning Shield
    AutoAttack = 6603,
  },
  Rank = {
    Main = {403,529,548,915,943,6041,10391,10392},
    Buff = {324,325,905,945,8134,10431,10432},
    AutoAttack = {6603},
  },
  Spell = {
    Elemental = {
      LightningBolt  = 403,
      ChainLightning = 421,
      EarthShock     = 8042,
      FlameShock     = 8050,
      FrostShock     = 8056,
    },
    Enhancement = {
      RockbiterWeapon = 8017,
      WindfuryWeapon  = 8232,
      Stormstrike     = 17364,
      GhostWolf       = 2645,
    },
    Restoration = {
      HealingWave      = 331,
      LesserHealingWave= 8004,
      ChainHeal        = 1064,
      ManaTideTotem    = 16190,
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

_G.TacoRot_IDS_Shaman = IDS

_G.TacoRotIconFallbacks = _G.TacoRotIconFallbacks or {}
local fb = _G.TacoRotIconFallbacks
local function setOnce(id, tex) if id and not fb[id] then fb[id] = tex end end
setOnce(403, "Interface\\Icons\\Spell_Nature_Lightning")
setOnce(324, "Interface\\Icons\\Spell_Nature_LightningShield")
setOnce(6603, "Interface\\Icons\\Ability_MeleeDamage")
