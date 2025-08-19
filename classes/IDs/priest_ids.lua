-- priest_ids.lua — Classic Anniversary Priest IDs
DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[TacoRot]|r Priest IDS loaded")

local IDS = {
  Ability = {
    Main       = 585,   -- Smite
    Buff       = 1243,  -- Power Word: Fortitude
    AutoAttack = 6603,
    Wand       = 5019,
  },
  Rank = {
    Main = {585, 591, 598, 984},
    Buff = {1243, 1244, 1245},
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

_G.TacoRot_IDS_Priest = IDS

_G.TacoRotIconFallbacks = _G.TacoRotIconFallbacks or {}
local fb = _G.TacoRotIconFallbacks
local function setOnce(id, tex) if id and not fb[id] then fb[id] = tex end end
setOnce(585,  "Interface\\Icons\\Spell_Holy_HolyBolt")
setOnce(1243, "Interface\\Icons\\Spell_Holy_WordFortitude")
setOnce(5019, "Interface\\Icons\\INV_Wand_01")
setOnce(6603, "Interface\\Icons\\Ability_MeleeDamage")
