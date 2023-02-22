-- First we need to create a frame to listen to the events we want.
local MobDrops = VendorThisMob.MobDrops

function VendorThisMob.OnEnemyTooltip(Tooltip)
    local _, Unit = Tooltip:GetUnit()
    if Unit == nil then
        return
    end

    -- Hide friendly NPCs.
    local Reaction = UnitReaction(Unit, "player")
    if Reaction == nil or Reaction > 4 then -- 3, is hostile, 4 is neutral, 5 is friendly.
        return
    end
    
    local UnitID = tonumber(UnitGUID(Unit):match("-(%d+)-%x+$"), 10)
    
    -- If the UnitID is not in the MobDrops dict, we show a tooltip with the dictionary's value.
    if MobDrops[UnitID] ~= nil then
        local TotalCopper = MobDrops[UnitID]

        SetTooltipMoney(Tooltip, TotalCopper, nil, SELL_PRICE_TEXT)
    end
end

GameTooltip:HookScript("OnTooltipSetUnit", VendorThisMob.OnEnemyTooltip)