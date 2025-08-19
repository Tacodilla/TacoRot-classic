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
    Main = {116, 205, 837, 7322},
    Buff = {1459, 1460, 1461},
    Wand = {5019},
    AutoAttack = {6603},
  },
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
