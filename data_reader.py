from json import loads
import requests
import re

class Mob():
    def __init__(self, id: int):
        self.id = id
        self.wowhead = requests.get(f"https://www.wowhead.com/classic/npc={id}").text
        
        
        self.raw_copper = self.find_rawcopper()
        self.health = self.find_health()
        
        lvl_min, lvl_max, name, type_enemy, type_life, react_alliance, react_horde = self.get_infocard()
        self.name = name
        self.lvl_min = lvl_min
        self.lvl_max = lvl_max
        
        # Type 0 is normal, 1 is elite, 2 is Rare Elite, 3 is Boss, 4 is Rare.
        self.type_enemy = type_enemy
        
        self.type_life = type_life # Humanoid, Beast, Undead etc.
        
        # How they react to players of different factions: # -1 = hostile, 0 = neutral, 1 = friendly
        self.react_alliance = react_alliance
        self.react_horde = react_horde
        
        self.lvl = (lvl_min + lvl_max)/2 # Average level.

        self.drops = self.get_drops()
        self.vendor_worth = sum([drop.vendor_price *drop.chance for drop in self.drops])
        self.vendor_worth = round(self.vendor_worth, 0) # Round to nearest copper.
        
        self.ah_worth = sum([drop.buyout *drop.chance for drop in self.drops])
        self.ah_worth = round(self.ah_worth, 0) # Round to nearest copper.

        del self.wowhead # We don't need this anymore.
        
    def find_rawcopper(self):
        raw_copper_matches = re.findall(r"\[money=(\d+)\]", self.wowhead)
        
        # If no raw copper is dropped, return 0.
        if len(raw_copper_matches) == 0:
            return 0
        else:
            return int(raw_copper_matches[0])
    
    def find_health(self):
        health_matches = re.findall(r"Health: (\d+)<", self.wowhead)
        
        if len(health_matches) == 0: return 0
        
        return int(health_matches[-1].replace(",", "")) # The health is in the format 1,000,000. We need to remove the commas.
    
    def get_infocard(self):
        info_card = re.findall(f"\$.extend\(g_npcs\[{self.id}\], (.+)\);", self.wowhead)[0]
        info_card = loads(info_card) # Convert to dictionary.
        
        lvl_min = info_card["minlevel"]
        lvl_max = info_card["maxlevel"]
        name = info_card["name"]
        type_enemy = info_card["classification"]
        type_life = info_card["type"]
        react_alliance = info_card["react"][0]
        react_horde = info_card["react"][1]
        
        return lvl_min, lvl_max, name, type_enemy, type_life, react_alliance, react_horde
    
    def get_drops(self):
        # A first option is this, however it holds no information about the vendor price.
        # First we locate the section of the text that contains the drops.
        drops_match = re.findall("new Listview\(\{template: 'item', id: 'drops'(.+)", self.wowhead)
        if len(drops_match) == 0: return []
        drops_match = re.findall(", data:(.+)\}\);", drops_match[0])[0] # Then we extract the data from it.
        drops_list = loads(drops_match) # A list of dictionaries for each drop.

        # To get the vendor price we instead have to look at a different section of the text.
        # This will give us a dictionary with the item id as the key and other information as the value.
        all_items_info = re.findall("WH.Gatherer.addData\(3, 4, (.+)\);", self.wowhead)[-1] # The item list appears last.
        items_dict = loads(all_items_info)
        
        drops = []
        for drop in drops_list:
            
            # The item may not be sellable to a vendor.
            try: vendor_price = items_dict[str(drop["id"])]["jsonequip"]["sellprice"]
            except: # Sometimes they are containers, in which case we get the raw copper they may contain.
                try: vendor_price = items_dict[str(drop["id"])]["jsonequip"]["avgmoney"] # TODO: This ignores other items.
                except: vendor_price = 0;
            
            # The item may not be sellable to the auction house.
            try: buyout = items_dict[str(drop["id"])]["jsonequip"]["avgbuyout"]
            except: buyout = 0
            
            try:
                reported_count = drop["modes"]["0"]["count"]
                reported_attempts = drop["modes"]["0"]["outof"]
            except:
                continue

            
            chance = reported_count/reported_attempts
            
            item = ItemDrop(drop["id"], vendor_price, buyout, chance)
            drops.append(item)
        
        return drops
    
    def create_mob_table(self):
        import pandas as pd
        data = []
        for drop in self.drops:
            data.append([drop.id, drop.vendor_price, drop.buyout, drop.chance])
        
        df = pd.DataFrame(data, columns=["Item ID", "Vendor Price", "Buyout", "Chance"])
        return df
    
    def __repr__(self):
        return f"{self.name}: ({self.id})"

class ItemDrop():
    def __init__(self, item_id: int, vendor_price: int, buyout: int, chance: float):
        self.id = item_id # The id of the item.
        self.vendor_price = vendor_price # The price vendors will buy the item for.
        self.buyout = buyout # The average buyout price reported by wowhead.
        self.chance = chance # The chance of the item dropping.
    
    def __repr__(self):
        return f"ItemDrop({self.id})"