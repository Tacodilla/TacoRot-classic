-- druid_ids.lua — Classic Anniversary Druid IDs
DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[TacoRot]|r Druid IDS loaded")

local IDS = {
  Ability = {
    Main       = 5176,  -- Wrath
    Buff       = 774,   -- Rejuvenation
    AutoAttack = 6603,
  },
  Rank = {
    Main = {5176, 5177, 5178},
    Buff = {774, 1058, 1430},
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

_G.TacoRot_IDS_Druid = IDS

_G.TacoRotIconFallbacks = _G.TacoRotIconFallbacks or {}
local fb = _G.TacoRotIconFallbacks
local function setOnce(id, tex) if id and not fb[id] then fb[id] = tex end end
setOnce(5176, "Interface\\Icons\\Spell_Nature_StarFall")
setOnce(774,  "Interface\\Icons\\Spell_Nature_Rejuvenation")
setOnce(6603, "Interface\\Icons\\Ability_MeleeDamage")
