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
        TotalCopper = MobDrops[UnitID]
        -- We need to convert the TotalCopper value to gold, silver and copper.
        Gold = math.floor(TotalCopper / 10000)
        Silver = math.floor((TotalCopper - (Gold * 10000)) / 100)
        Copper = TotalCopper - (Gold * 10000) - (Silver * 100)

        -- We need to add the gold, silver and copper values to the tooltip and use the ingame icons for them.
        if Gold == 0 and Silver == 0 and Copper > 0 then
            Tooltip:AddLine("|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t" .. Copper)
        elseif Gold == 0 and Silver > 0 and Copper > 0 then
            Tooltip:AddLine("|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t" .. Silver .. " |TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t" .. Copper)
        else
            Tooltip:AddLine("|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t" .. Gold .. " |TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t" .. Silver .. " |TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t" .. Copper)
        end

        Tooltip:Show()
    end
end

GameTooltip:HookScript("OnTooltipSetUnit", VendorThisMob.OnEnemyTooltip)