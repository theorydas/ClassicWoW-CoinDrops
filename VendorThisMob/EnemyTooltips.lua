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
        local TotalCopper = MobDrops[UnitID][1]
        local Score = MobDrops[UnitID][2]

        -- We need to convert the TotalCopper value to gold, silver and copper.
        local Gold = math.floor(TotalCopper / 10000)
        local Silver = math.floor((TotalCopper - (Gold * 10000)) / 100)
        local Copper = TotalCopper - (Gold * 10000) - (Silver * 100)
        
        local TooltipText = ""
        -- We need to add the gold, silver and copper values to the tooltip and use the ingame icons for them.
        if Gold == 0 and Silver == 0 and Copper > 0 then
            -- The color should be white.
            TooltipText = "|cffffffff|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t" .. Copper.. "|r"
        elseif Gold == 0 and Silver > 0 then
            TooltipText = "|cffffffff|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t" .. Silver .. " |TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t" .. Copper.. "|r"
        elseif Gold > 0 then
            TooltipText = "|cffffffff|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t" .. Gold .. " |TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t" .. Silver .. " |TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t" .. Copper.. "|r"
        end

        
        -- Additionally we show the score. If it is a positive integer we show that many stars, if it is a negative integer we show that many skulls.
        -- The textures are from Wow's own files.
        if Score ~= 0 then
            TooltipText = TooltipText.. "     ("
            local textrue = Score > 0 and "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1" or "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8"
            for i = 1, math.abs(Score) do

                TooltipText = TooltipText .. "|T" .. textrue .. ":0:0:2:0|t"
            end
            TooltipText = TooltipText .. ")"
        end

        Tooltip:AddLine(TooltipText)
        Tooltip:Show()
    end

end

GameTooltip:HookScript("OnTooltipSetUnit", VendorThisMob.OnEnemyTooltip)