-- warlock_ids.lua — Classic Anniversary Warlock IDs
DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[TacoRot]|r Warlock IDS loaded")

local IDS = {
  Ability = {
    Main       = 686,   -- Shadow Bolt
    Buff       = 687,   -- Demon Skin
    AutoAttack = 6603,
    Wand       = 5019,
  },
  Rank = {
    Main = {686,695,705,1088,1106,7641,11659,11660,11661,25307},
    Buff = {687,696,706,1086,11733,11734,11735},
    Wand = {5019},
    AutoAttack = {6603},
  },
  Spell = {
    Affliction = {
      Corruption    = 172,
      CurseOfAgony  = 980,
      DrainLife     = 689,
      LifeTap       = 1454,
      SiphonLife    = 18265,
    },
    Demonology = {
      SummonImp       = 688,
      SummonVoidwalker= 697,
      SummonSuccubus  = 712,
      SummonFelhunter = 691,
      Soulstone       = 20707,
      Healthstone     = 6201,
      DemonArmor      = 706,
    },
    Destruction = {
      ShadowBolt    = 686,
      Immolate      = 348,
      Conflagrate   = 17962,
      Shadowburn    = 17877,
      SearingPain   = 5676,
      RainOfFire    = 5740,
      Hellfire      = 1949,
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

_G.TacoRot_IDS_Warlock = IDS

_G.TacoRotIconFallbacks = _G.TacoRotIconFallbacks or {}
local fb = _G.TacoRotIconFallbacks
local function setOnce(id, tex) if id and not fb[id] then fb[id] = tex end end
setOnce(686,  "Interface\\Icons\\Spell_Shadow_ShadowBolt")
setOnce(687,  "Interface\\Icons\\Spell_Shadow_RagingScream")
setOnce(5019, "Interface\\Icons\\INV_Wand_01")
setOnce(6603, "Interface\\Icons\\Ability_MeleeDamage")
