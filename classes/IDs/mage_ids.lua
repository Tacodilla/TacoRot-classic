-- mage_ids.lua — Classic Anniversary Mage IDs
DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[TacoRot]|r Mage IDS loaded")

local IDS = {
  Ability = {
    Main       = 116,   -- Frostbolt
    Buff       = 1459,  -- Arcane Intellect
    AutoAttack = 6603,
    Wand       = 5019,  -- Shoot
  },
  Rank = {
    -- Full rank list up to level 60
    Main = {116,205,837,7322,8406,8407,8408,10179,10180,10181},
    Buff = {1459,1460,1461,10156,10157},
    Wand = {5019},
    AutoAttack = {6603},
  },
  Spell = {
    Arcane = {
      ArcaneMissiles    = 5143,
      ArcaneExplosion   = 1449,
      Counterspell      = 2139,
      Evocation         = 12051,
      ArcaneIntellect   = 1459,
      PresenceOfMind    = 12043,
      ManaShield        = 1463,
    },
    Fire = {
      Fireball          = 133,
      FireBlast         = 2136,
      Scorch            = 2948,
      Pyroblast         = 11366,
      Flamestrike       = 2120,
      BlastWave         = 11113,
      Combustion        = 11129,
    },
    Frost = {
      Frostbolt         = 116,
      FrostNova         = 122,
      ConeOfCold        = 120,
      Blizzard          = 10,
      IceBarrier        = 11426,
      IceBlock          = 11958,
      ColdSnap          = 12472,
    },
    Utility = {
      Blink             = 1953,
      Polymorph         = 118,
      RemoveLesserCurse = 475,
      DetectMagic       = 2855,
      AmplifyMagic      = 1008,
      DampenMagic       = 604,
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

_G.TacoRot_IDS_Mage = IDS

_G.TacoRotIconFallbacks = _G.TacoRotIconFallbacks or {}
local fb = _G.TacoRotIconFallbacks
local function setOnce(id, tex) if id and not fb[id] then fb[id] = tex end end
setOnce(116,  "Interface\\Icons\\Spell_Frost_FrostBolt02")
setOnce(1459, "Interface\\Icons\\Spell_Holy_MagicalSentry")
setOnce(5019, "Interface\\Icons\\INV_Wand_01")
setOnce(6603, "Interface\\Icons\\Ability_MeleeDamage")
