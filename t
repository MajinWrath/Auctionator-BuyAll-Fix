
local addonName, addonTable = ...; 
local zc = addonTable.zc;


-----------------------------------------

local auctionator_orig_GameTooltip_OnTooltipAddMoney;

-----------------------------------------

function auctionator_GameTooltip_OnTooltipAddMoney (self, cost, maxcost)

	if (AUCTIONATOR_V_TIPS == 1) then
		return;
	end

	auctionator_orig_GameTooltip_OnTooltipAddMoney (self, cost, maxcost);
end

-----------------------------------------

function Atr_Hook_OnTooltipAddMoney()
	auctionator_orig_GameTooltip_OnTooltipAddMoney = GameTooltip_OnTooltipAddMoney;
	GameTooltip_OnTooltipAddMoney = auctionator_GameTooltip_OnTooltipAddMoney;
end

------------------------------------------------

local function Atr_AppendHint (results, price, text, volume)

	if (price and price > 0) then
		local e = {};
		e.price		= price;
		e.text		= text;
		e.volume	= volume;
		
		table.insert (results, e);
	end

end

------------------------------------------------

function Atr_BuildHints (itemName)

	local results = {};

	local itemLink = Atr_GetItemLink (itemName);

	if (itemLink == nil and itemName == nil) then
		return results;
	end

	-- Auctionator Full Scan
	
	if (itemName ~= nil and gAtr_ScanDB[itemName] ~= nil) then
		Atr_AppendHint (results, gAtr_ScanDB[itemName], ZT("Auctionator scan data"));
	end

	-- most recent historical price
	
	local price = Atr_GetMostRecentSale(itemName);
	if (price ~= nil) then
		Atr_AppendHint (results, price, ZT("your most recent posting"));
	end

	-- Wowecon

	if (Wowecon and Wowecon.API) then
	
		local priceG, volG, priceS, volS;
		
		if (itemLink) then
			priceG, volG = Wowecon.API.GetAuctionPrice_ByLink (itemLink, Wowecon.API.GLOBAL_PRICE)
			priceS, volS = Wowecon.API.GetAuctionPrice_ByLink (itemLink, Wowecon.API.SERVER_PRICE)
		else
			priceG, volG = Wowecon.API.GetAuctionPrice_ByName (itemName, Wowecon.API.GLOBAL_PRICE)
			priceS, volS = Wowecon.API.GetAuctionPrice_ByName (itemName, Wowecon.API.SERVER_PRICE)
		end
		
		Atr_AppendHint (results, priceG, ZT("Wowecon global price"), volG);
		Atr_AppendHint (results, priceS, ZT("Wowecon server price"), volS);
		
	end
	
	if (itemLink) then
	
		-- GoingPrice Wowhead
		
		local id = zc.ItemIDfromLink (itemLink);
		
		id = tonumber(id);

		if (GoingPrice_Wowhead_Data and GoingPrice_Wowhead_Data[id] and GoingPrice_Wowhead_SV._index) then
			local index = GoingPrice_Wowhead_SV._index["Buyout price"];

			if (index ~= nil) then
				local price = GoingPrice_Wowhead_Data[id][index];
			
				Atr_AppendHint (results, price, "GoingPrice - Wowhead");
			end
		end

		-- GoingPrice Allakhazam
		
		if (GoingPrice_Allakhazam_Data and GoingPrice_Allakhazam_Data[id] and GoingPrice_Allakhazam_SV._index) then
			local index = GoingPrice_Allakhazam_SV._index["Median"];

			if (index ~= nil) then
				local price = GoingPrice_Allakhazam_Data[id][index];
			
				Atr_AppendHint (results, price, "GoingPrice - Allakhazam");
			end
		end
	end
	
	return results;

end

-----------------------------------------

function Atr_ShowHints ()

	Atr_Col1_Heading:Hide();
	Atr_Col3_Heading:Hide();
	Atr_Col4_Heading:Hide();

	Atr_Col3_Heading:SetText (ZT("Source"));

	local currentPane = Atr_GetCurrentPane();

	currentPane.hints = Atr_BuildHints (currentPane.activeScan.itemName);
	
	local numrows = currentPane.hints and #currentPane.hints or 0;

	if (numrows > 0) then
		Atr_Col1_Heading:Show();
		Atr_Col3_Heading:Show();
	end

	local line;							-- 1 through 12 of our window to scroll
	local dataOffset;					-- an index into our data calculated from the scroll offset

	FauxScrollFrame_Update (AuctionatorScrollFrame, numrows, 12, 16);

	for line = 1,12 do

		dataOffset = line + FauxScrollFrame_GetOffset (AuctionatorScrollFrame);

		local lineEntry = getglobal ("AuctionatorEntry"..line);

		lineEntry:SetID(dataOffset);

		if (dataOffset <= numrows and currentPane.hints[dataOffset]) then

			local data = currentPane.hints[dataOffset];

			local lineEntry_item_tag = "AuctionatorEntry"..line.."_PerItem_Price";

			local lineEntry_item		= getglobal(lineEntry_item_tag);
			local lineEntry_itemtext	= getglobal("AuctionatorEntry"..line.."_PerItem_Text");
			local lineEntry_text		= getglobal("AuctionatorEntry"..line.."_EntryText");
			local lineEntry_stack		= getglobal("AuctionatorEntry"..line.."_StackPrice");

			lineEntry_item:Show();
			lineEntry_itemtext:Hide();
			lineEntry_stack:SetText	("");

			Atr_SetMFcolor (lineEntry_item_tag, true);

			MoneyFrame_Update (lineEntry_item_tag, zc.round(data.price) );

			local text = data.text;
			if (data.volume) then
				text = text.." ("..ZT("trade volume")..": "..data.volume..")";
			end
			
			lineEntry_text:SetText (text);
			lineEntry_text:SetTextColor (0.8, 0.8, 1.0);

			lineEntry:Show();
		else
			lineEntry:Hide();
		end
	end

	Atr_HighlightEntry (currentPane.hintsIndex);
end


-----------------------------------------

function Atr_SetMFcolor (frameName, blue)

	local goldButton = getglobal(frameName.."GoldButton");
	local silverButton = getglobal(frameName.."SilverButton");
	local copperButton = getglobal(frameName.."CopperButton");

	if (blue) then
		goldButton:SetNormalFontObject(NumberFontNormalRightATRblue);
		silverButton:SetNormalFontObject(NumberFontNormalRightATRblue);
		copperButton:SetNormalFontObject(NumberFontNormalRightATRblue);
	else
		goldButton:SetNormalFontObject(NumberFontNormalRight);
		silverButton:SetNormalFontObject(NumberFontNormalRight);
		copperButton:SetNormalFontObject(NumberFontNormalRight);
	end
	
end


-----------------------------------------

function Atr_GetAuctionPrice (item)  -- itemName or itemID

	local itemName;
	
	if (type (item) == "number") then
		itemName = GetItemInfo (item);
	else
		itemName = item;
	end

	if (itemName == nil) then
		return nil;
	end

	if (gAtr_ScanDB[itemName]) then
		return gAtr_ScanDB[itemName];
	end
	
	return Atr_GetMostRecentSale (itemName);
end	

-----------------------------------------

local function Atr_CalcTextWid (price)

	local wid = 15;
	
	if (price > 9)			then wid = wid + 12;	end;
	if (price > 99)			then wid = wid + 44;	end;
	if (price > 999)		then wid = wid + 12;	end;
	if (price > 9999)		then wid = wid + 44;	end;
	if (price > 99999)		then wid = wid + 12;	end;
	if (price > 999999)		then wid = wid + 12;	end;
	if (price > 9999999)	then wid = wid + 12;	end;
	if (price > 99999999)	then wid = wid + 12;	end;
	
	return wid;
end

-----------------------------------------

local function Atr_CalcTTpadding (price1, price2)

	local padding = "";

	if (price1 and price2) then
		local vpwidth = Atr_CalcTextWid (price1);
		local apwidth = Atr_CalcTextWid (price2);

		local padlen = math.floor ((apwidth - vpwidth)/6);
		local k;
		
		for k = 1,padlen do
			padding = padding.." ";
		end
	end

	return padding;

end

-----------------------------------------

local UNCOMMON	= 2;
local RARE		= 3;
local EPIC		= 4;

local WEAPON = 1;
local ARMOR  = 2;

local LESSER_MAGIC		= 10938;
local GREATER_MAGIC		= 10939;
local STRANGE_DUST		= 10940;

local SMALL_GLIMMERING	= 10978;
local LESSER_ASTRAL		= 10998;

local GREATER_ASTRAL	= 11082;
local SOUL_DUST			= 11083;
local LARGE_GLIMMERING	= 11084;

local LESSER_MYSTIC		= 11134;
local GREATER_MYSTIC	= 11135;
local VISION_DUST		= 11137;
local SMALL_GLOWING		= 11138;
local LARGE_GLOWING		= 11139;

local LESSER_NETHER		= 11174;
local GREATER_NETHER	= 11175;
local DREAM_DUST		= 11176;
local SMALL_RADIANT		= 11177;
local LARGE_RADIANT		= 11178;

local SMALL_BRILLIANT	= 14343;
local LARGE_BRILLIANT	= 14344;

local LESSER_ETERNAL	= 16202;
local GREATER_ETERNAL	= 16203;
local ILLUSION_DUST		= 16204;

local NEXUS_CRYSTAL		= 20725;

local ARCANE_DUST		= 22445;
local GREATER_PLANAR	= 22446;
local LESSER_PLANAR		= 22447;
local SMALL_PRISMATIC	= 22448;
local LARGE_PRISMATIC	= 22449;
local VOID_CRYSTAL		= 22450;

local DREAM_SHARD		= 34052;
local SMALL_DREAM		= 34053;

local INFINITE_DUST		= 34054;
local GREATER_COSMIC	= 34055;
local LESSER_COSMIC		= 34056;
local ABYSS_CRYSTAL		= 34057;

local engDEnames = {};

engDEnames [LESSER_MAGIC]		= "Lesser Magic Essence";
engDEnames [GREATER_MAGIC]		= "Greater Magic Essence";
engDEnames [STRANGE_DUST]		= "Strange Dust";

engDEnames [SMALL_GLIMMERING]	= "Small Glimmering Shard";
engDEnames [LESSER_ASTRAL]		= "Lesser Astral Essence";

engDEnames [GREATER_ASTRAL]		= "Greater Astral Essence";
engDEnames [SOUL_DUST]			= "Soul Dust";
engDEnames [LARGE_GLIMMERING]	= "Large Glimmering Essence";

engDEnames [LESSER_MYSTIC]		= "Lesser Mystic Essence";
engDEnames [GREATER_MYSTIC]		= "Greater Mystic Essence";
engDEnames [VISION_DUST]		= "Vision Dust";
engDEnames [SMALL_GLOWING]		= "Small Glowing Shard";
engDEnames [LARGE_GLOWING]		= "Large Glowing Shard";

engDEnames [LESSER_NETHER]		= "Lesser Nether Essence";
engDEnames [GREATER_NETHER]		= "Greater Nether Essence";
engDEnames [DREAM_DUST]			= "Dream Dust";
engDEnames [SMALL_RADIANT]		= "Small Radiant";
engDEnames [LARGE_RADIANT]		= "Large Radiant";

engDEnames [SMALL_BRILLIANT]	= "Small Brilliant Shard";
engDEnames [LARGE_BRILLIANT]	= "Large Brilliant Shard";

engDEnames [LESSER_ETERNAL]		= "Lesser Eternal Essence";
engDEnames [GREATER_ETERNAL]	= "Greater Eternal Essence";
engDEnames [ILLUSION_DUST]		= "Illusion Dust";

engDEnames [NEXUS_CRYSTAL]		= "Nexus Crystal";

engDEnames [ARCANE_DUST]		= "Arcane Dust";
engDEnames [GREATER_PLANAR]		= "Greater Planar Essence";
engDEnames [LESSER_PLANAR]		= "Lesser Planar Essence";
engDEnames [SMALL_PRISMATIC]	= "Small Prismatic Shard";
engDEnames [LARGE_PRISMATIC]	= "Large Prismatic Shard";
engDEnames [VOID_CRYSTAL]		= "Void Crystal";

engDEnames [DREAM_SHARD]		= "Dream Shard";
engDEnames [SMALL_DREAM]		= "Small Dream Shard";

engDEnames [INFINITE_DUST]		= "Infinite Dust";
engDEnames [GREATER_COSMIC]		= "Greater Cosmic Essence";
engDEnames [LESSER_COSMIC]		= "Lesser Cosmic Essence";
engDEnames [ABYSS_CRYSTAL]		= "Abyss Crystal";


local dustsAndEssences = {};

tinsert (dustsAndEssences, LESSER_MAGIC)
tinsert (dustsAndEssences, GREATER_MAGIC)
tinsert (dustsAndEssences, STRANGE_DUST)

tinsert (dustsAndEssences, SMALL_GLIMMERING)
tinsert (dustsAndEssences, LESSER_ASTRAL)

tinsert (dustsAndEssences, GREATER_ASTRAL)
tinsert (dustsAndEssences, SOUL_DUST)
tinsert (dustsAndEssences, LARGE_GLIMMERING)

tinsert (dustsAndEssences, LESSER_MYSTIC)
tinsert (dustsAndEssences, GREATER_MYSTIC)
tinsert (dustsAndEssences, VISION_DUST)
tinsert (dustsAndEssences, SMALL_GLOWING)
tinsert (dustsAndEssences, LARGE_GLOWING)

tinsert (dustsAndEssences, LESSER_NETHER)
tinsert (dustsAndEssences, GREATER_NETHER)
tinsert (dustsAndEssences, DREAM_DUST)
tinsert (dustsAndEssences, SMALL_RADIANT)
tinsert (dustsAndEssences, LARGE_RADIANT)

tinsert (dustsAndEssences, SMALL_BRILLIANT)
tinsert (dustsAndEssences, LARGE_BRILLIANT)

tinsert (dustsAndEssences, LESSER_ETERNAL)
tinsert (dustsAndEssences, GREATER_ETERNAL)
tinsert (dustsAndEssences, ILLUSION_DUST)

tinsert (dustsAndEssences, NEXUS_CRYSTAL)

tinsert (dustsAndEssences, ARCANE_DUST)
tinsert (dustsAndEssences, GREATER_PLANAR)
tinsert (dustsAndEssences, LESSER_PLANAR)
tinsert (dustsAndEssences, SMALL_PRISMATIC)
tinsert (dustsAndEssences, LARGE_PRISMATIC)
tinsert (dustsAndEssences, VOID_CRYSTAL)

tinsert (dustsAndEssences, DREAM_SHARD)
tinsert (dustsAndEssences, SMALL_DREAM)

tinsert (dustsAndEssences, INFINITE_DUST)
tinsert (dustsAndEssences, GREATER_COSMIC)
tinsert (dustsAndEssences, LESSER_COSMIC)
tinsert (dustsAndEssences, ABYSS_CRYSTAL)

gAtr_dustCacheIndex = 1;
local dustCacheState = 0;

-----------------------------------------

function Atr_GetNextDustIntoCache()		-- make sure all the dusts and essences are in the local cache
										-- only needed after a major patch and a cache wipe
	if (gAtr_dustCacheIndex == 0) then
		return;
	end

	local itemID		= dustsAndEssences[gAtr_dustCacheIndex];
	local itemString	= "item:"..itemID..":0:0:0:0:0:0:0";
	
	local itemName, itemLink = GetItemInfo(itemString);
	
	if (itemLink == nil and dustCacheState == 0) then
		dustCacheState = 1;
		zc.md ("pulling "..itemString.." into the local cache");
		AtrScanningTooltip:SetHyperlink(itemString);
	end

	if (itemLink) then
		--zc.md (itemName.." is already in local cache");
		dustCacheState = 0;
		gAtr_dustCacheIndex = gAtr_dustCacheIndex + 1;
		
		if (gAtr_dustCacheIndex > #dustsAndEssences) then
			gAtr_dustCacheIndex = 0;		-- finished
		end
	end
end

-----------------------------------------

local deItemNames = {};

local function Atr_GetDEitemName (itemID)

	if (deItemNames[itemID] == nil) then
		local itemName = GetItemInfo (itemID);
		if (itemName == nil) then
			zc.md ("defaulting to english DE mat name: "..engDEnames [itemID]);
			return engDEnames [itemID];
		end
		
		deItemNames[itemID] = itemName;
	end
	
	return deItemNames[itemID];

end

-----------------------------------------

function Atr_GetAuctionPriceDE (itemID)  -- same as Atr_GetAuctionPrice but understands that some "lesser" essences are convertible with "greater"

	local lesserPrice;
	local greaterPrice;
	
	if (itemID == LESSER_COSMIC) then
		lesserPrice  = Atr_GetAuctionPrice (Atr_GetDEitemName (LESSER_COSMIC));
		greaterPrice = Atr_GetAuctionPrice (Atr_GetDEitemName (GREATER_COSMIC));
	end
	
	if (itemID == LESSER_PLANAR) then
		lesserPrice  = Atr_GetAuctionPrice (Atr_GetDEitemName (LESSER_PLANAR));
		greaterPrice = Atr_GetAuctionPrice (Atr_GetDEitemName (GREATER_PLANAR));
	end
	
	if (lesserPrice ~= nil and greaterPrice ~= nil and lesserPrice * 3 > greaterPrice) then
		return math.floor (greaterPrice / 3);
	end
	
	return Atr_GetAuctionPrice (Atr_GetDEitemName (itemID));
end

-----------------------------------------

local deTable = {};

-----------------------------------------

local function deKey (itemType, itemRarity)
	local s = tostring(itemType).."_"..itemRarity
	return s;
end

-----------------------------------------

local function DEtableInsert(t, info)

	local entry = {};

	local x, i, n;
	
	entry[1]	= info[1];
	entry[2]	= info[2];
	
	n = 3;
	
	for x = 3,#info,3 do
		local nums = info[x+1];
		if (type(nums) == "number") then
			entry[n]   = info[x];
			entry[n+1] = info[x+1];
			entry[n+2] = info[x+2];
			n = n + 3;
		else
			for i = nums[1],nums[2] do
				entry[n]   = info[x]/(nums[2]-nums[1]+1);
				entry[n+1] = i;
				entry[n+2] = info[x+2];
				n = n + 3;				
			end
		end
	end
	
	table.insert (t, entry);

end


-----------------------------------------

function Atr_InitDETable()		-- based on table at wowwiki.com/Disenchanting_tables


	-- UNCOMMON ARMOR

	deTable[deKey(ARMOR, UNCOMMON)] = {};
	
	local t = deTable[deKey(ARMOR, UNCOMMON)];
	
	
	DEtableInsert (t, {5, 15,		80, {1,2}, STRANGE_DUST,	20, {1,2}, LESSER_MAGIC});
	DEtableInsert (t, {16, 20,		75, {2,3}, STRANGE_DUST,	20, {1,2}, GREATER_MAGIC,	5, 1, SMALL_GLIMMERING});
	DEtableInsert (t, {21, 25,		75, {4,6}, STRANGE_DUST,	15, {1,2}, LESSER_ASTRAL,	10, 1, SMALL_GLIMMERING});
	DEtableInsert (t, {26, 30,		75, {1,2}, SOUL_DUST,		20, {1,2}, GREATER_ASTRAL,	5, 1, LARGE_GLIMMERING});
	DEtableInsert (t, {31, 35,		75, {2,5}, SOUL_DUST,		20, {1,2}, LESSER_MYSTIC,	5, 1, SMALL_GLOWING});
	DEtableInsert (t, {36, 40,		75, {1,2}, VISION_DUST,		20, {1,2}, GREATER_MYSTIC,	5, 1, LARGE_GLOWING});
	DEtableInsert (t, {41, 45,		75, {2,5}, VISION_DUST,		20, {1,2}, LESSER_NETHER,	5, 1, SMALL_RADIANT});
	DEtableInsert (t, {46, 50,		75, {1,2}, DREAM_DUST,		20, {1,2}, GREATER_NETHER,	5, 1, LARGE_RADIANT});
	DEtableInsert (t, {51, 55,		75, {2,5}, DREAM_DUST,		20, {1,2}, LESSER_ETERNAL,	5, 1, SMALL_BRILLIANT});
	DEtableInsert (t, {56, 60,		75, {1,2}, ILLUSION_DUST,	20, {1,2}, GREATER_ETERNAL,	5, 1, LARGE_BRILLIANT});
	DEtableInsert (t, {61, 65,		75, {2,5}, ILLUSION_DUST,	20, {2,3}, GREATER_ETERNAL,	5, 1, LARGE_BRILLIANT});
	DEtableInsert (t, {66, 80,		75, {1,3}, ARCANE_DUST,		22, {1,3}, LESSER_PLANAR,	3, 1, SMALL_PRISMATIC});
	DEtableInsert (t, {81, 99,		75, {2,3}, ARCANE_DUST,		22, {2,3}, LESSER_PLANAR,	3, 1, SMALL_PRISMATIC});
	DEtableInsert (t, {100, 120,	75, {2,5}, ARCANE_DUST,		22, {1,2}, GREATER_PLANAR,	3, 1, LARGE_PRISMATIC});
	DEtableInsert (t, {121, 151,	75, {1,3}, INFINITE_DUST,	22, {1,2}, LESSER_COSMIC,	3, 1, SMALL_DREAM});
	DEtableInsert (t, {152, 200,	75, {4,7}, INFINITE_DUST,	22, {1,2}, GREATER_COSMIC,	3, 1, DREAM_SHARD});


	-- UNCOMMON WEAPONS

	deTable[deKey(WEAPON, UNCOMMON)] = {};
	
	local t = deTable[deKey(WEAPON, UNCOMMON)];

	DEtableInsert (t, {6, 15,		20, {1,2}, STRANGE_DUST,	80, {1,2}, LESSER_MAGIC});
	DEtableInsert (t, {16, 20,		20, {2,3}, STRANGE_DUST,	75, {1,2}, GREATER_MAGIC,	5, 1, SMALL_GLIMMERING});
	DEtableInsert (t, {21, 25,		15, {4,6}, STRANGE_DUST,	75, {1,2}, LESSER_ASTRAL,	10, 1, SMALL_GLIMMERING});
	DEtableInsert (t, {26, 30,		20, {1,2}, SOUL_DUST,		75, {1,2}, GREATER_ASTRAL,	5, 1, LARGE_GLIMMERING});
	DEtableInsert (t, {31, 35,		20, {2,5}, SOUL_DUST,		75, {1,2}, LESSER_MYSTIC,	5, 1, SMALL_GLOWING});
	DEtableInsert (t, {36, 40,		20, {1,2}, VISION_DUST,		75, {1,2}, GREATER_MYSTIC,	5, 1, LARGE_GLOWING});
	DEtableInsert (t, {41, 45,		20, {2,5}, VISION_DUST,		75, {1,2}, LESSER_NETHER,	5, 1, SMALL_RADIANT});
	DEtableInsert (t, {46, 50,		20, {1,2}, DREAM_DUST,		75, {1,2}, GREATER_NETHER,	5, 1, LARGE_RADIANT});
	DEtableInsert (t, {51, 55,		22, {2,5}, DREAM_DUST,		75, {1,2}, LESSER_ETERNAL,	5, 1, SMALL_BRILLIANT});
	DEtableInsert (t, {56, 60,		22, {1,2}, ILLUSION_DUST,	75, {1,2}, GREATER_ETERNAL,	5, 1, LARGE_BRILLIANT});
	DEtableInsert (t, {61, 65,		22, {2,5}, ILLUSION_DUST,	75, {2,3}, GREATER_ETERNAL,	5, 1, LARGE_BRILLIANT});
	DEtableInsert (t, {66, 99,		22, {2,3}, ARCANE_DUST,		75, {2,3}, LESSER_PLANAR,	3, 1, SMALL_PRISMATIC});
	DEtableInsert (t, {100, 120,	22, {2,5}, ARCANE_DUST,		75, {1,2}, GREATER_PLANAR,	3, 1, LARGE_PRISMATIC});
	DEtableInsert (t, {121, 151,	22, {1,3}, INFINITE_DUST,	75, {1,2}, LESSER_COSMIC,	3, 1, SMALL_DREAM});
	DEtableInsert (t, {152, 200,	22, {4,7}, INFINITE_DUST,	75, {1,2}, GREATER_COSMIC,	3, 1, DREAM_SHARD});
	
	-- RARE ITEMS
	
	deTable[deKey(ARMOR, RARE)] = {};
	
	t = deTable[deKey(ARMOR, RARE)];

	DEtableInsert (t, {11, 25,		100, 1, SMALL_GLIMMERING});
	DEtableInsert (t, {26, 30,		100, 1, LARGE_GLIMMERING});
	DEtableInsert (t, {31, 35,		100, 1, SMALL_GLOWING});
	DEtableInsert (t, {36, 40,		100, 1, LARGE_GLOWING});
	DEtableInsert (t, {41, 45,		100, 1, SMALL_RADIANT});
	DEtableInsert (t, {46, 50,		100, 1, LARGE_RADIANT});
	DEtableInsert (t, {51, 55,		100, 1, SMALL_BRILLIANT});
	DEtableInsert (t, {56, 65,		99.5, 1, LARGE_BRILLIANT,		0.5, 1, NEXUS_CRYSTAL});
	DEtableInsert (t, {66, 99,		99.5, 1, SMALL_PRISMATIC,		0.5, 1, NEXUS_CRYSTAL});
	DEtableInsert (t, {100, 120,	99.5, 1, LARGE_PRISMATIC,		0.5, 1, VOID_CRYSTAL});
	DEtableInsert (t, {121, 164,	99.5, 1, SMALL_DREAM,			0.5, 1, ABYSS_CRYSTAL});
	DEtableInsert (t, {165, 999,	99.5, 1, DREAM_SHARD,			0.5, 1, ABYSS_CRYSTAL});

	deTable[deKey(WEAPON, RARE)] = deTable[deKey(ARMOR, RARE)];


	-- EPIC ITEMS
	
	deTable[deKey(ARMOR, EPIC)] = {};
	
	t = deTable[deKey(ARMOR, EPIC)];

	DEtableInsert (t, {40, 45,		100, {2,4}, SMALL_RADIANT});
	DEtableInsert (t, {46, 50,		100, {2,4}, LARGE_RADIANT});
	DEtableInsert (t, {51, 55,		100, {2,4}, SMALL_BRILLIANT});
	DEtableInsert (t, {56, 60,		100, 1, NEXUS_CRYSTAL});
--	DEtableInsert (t, {61, 80,  FILLED IN BELOW
	DEtableInsert (t, {95, 100,		100, {1,2}, VOID_CRYSTAL});
	DEtableInsert (t, {105, 164,	33.3, 1, VOID_CRYSTAL,	66.6, 2, VOID_CRYSTAL});
	DEtableInsert (t, {165, 200,	100, 1, ABYSS_CRYSTAL});
	DEtableInsert (t, {200, 999,	100, 1, ABYSS_CRYSTAL});

	deTable[deKey(WEAPON, EPIC)] = zc.CopyDeep (deTable[deKey(ARMOR, EPIC)]);	-- copy it this time because of differences

	DEtableInsert (deTable[deKey(ARMOR,  EPIC)], {61, 80,	50,   1, NEXUS_CRYSTAL, 	50,   2, NEXUS_CRYSTAL});
	DEtableInsert (deTable[deKey(WEAPON, EPIC)], {61, 80,	33.3, 1, NEXUS_CRYSTAL, 	66.6, 2, NEXUS_CRYSTAL});

end

-----------------------------------------

local function Atr_FindDEentry (itemType, itemRarity, itemLevel)

	local itemTypeNum = Atr_ItemType2AuctionClass (itemType);

	local t = deTable[deKey(itemTypeNum, itemRarity)];

	if (t) then
		local n;
		for n = 1, #t do
			
			local ta = t[n];
			
			if (itemLevel >= ta[1] and itemLevel <= ta[2]) then
				return ta;
			end
		end
	end


end

-----------------------------------------

local function Atr_AddDEDetailsToTip (tip, itemType, itemRarity, itemLevel, DEreqLevel)

	local ta = Atr_FindDEentry (itemType, itemRarity, itemLevel);

	if (ta) then
		local x;
		for x = 3,#ta,3 do
			local percent = math.floor (ta[x]*100) / 100;

			local deitem = Atr_GetDEitemName(ta[x+2]);
			if (deitem == nil) then
				deitem = "???";
			end

			tip:AddLine ("  |cFFFFFFFF"..percent.."%|r   "..ta[x+1].." "..deitem);
		end
	end

	tip:AddLine ("  |cFFAAAAFF"..ZT("Required DE skill level")..": "..DEreqLevel);
end

-----------------------------------------

function Atr_DumpDETable (itemType, itemRarity)

	local t = deTable[deKey(itemType, itemRarity)];

	if (t) then
		local n, x;
		for n = 1, #t do
			local ta = t[n];
			
			zc.msg_pink ("iLvl: "..ta[1].."-"..ta[2]);
			
			for x = 3,#ta,3 do
				zc.msg_pink ("   "..ta[x].."%  "..ta[x+1].."  "..Atr_GetDEitemName(ta[x+2]).."  ("..Atr_GetAuctionPrice (Atr_GetDEitemName(ta[x+2]))..")");
			end
		end
	end

end

-----------------------------------------

function Atr_CalcDisenchantPrice (itemType, itemRarity, itemLevel)

	if (Atr_IsWeaponType (itemType) or Atr_IsArmorType (itemType)) then
		if (itemRarity == UNCOMMON or itemRarity == RARE or itemRarity == EPIC) then

			local dePrice = 0;

			local ta = Atr_FindDEentry (itemType, itemRarity, itemLevel);
			if (ta) then
				local x;
				for x = 3,#ta,3 do
					local price = Atr_GetAuctionPriceDE (ta[x+2]);
					if (price) then
						dePrice = dePrice + (ta[x] * ta[x+1] * price);
					end
				end
			end

			return math.floor (dePrice/100);
		end
	end
	
	return nil;		-- can't be disenchanted
end

-----------------------------------------

local function ShowTipWithPricing (tip, link, num)

	if (link == nil) then
		return;
	end

--[[
	if (num == "tradeskill") then
	
		local skill = link;
	
		local n;
		for n = 1,GetTradeSkillNumReagents(skill) do
			local rname, _, rnum = GetTradeSkillReagentInfo(skill, n);
			local rlink = GetTradeSkillReagentItemLink (skill, n);
			zc.md (skill, rlink, rnum);
		end
	
		return;
	end
]]--

	local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, _, _, _, _, itemVendorPrice = GetItemInfo (link);

	local itemID = zc.ItemIDfromLink (link);
	itemID = tonumber(itemID);
	
	local vendorPrice	= 0;
	local auctionPrice	= 0;
	local dePrice		= nil;
	
	if (AUCTIONATOR_V_TIPS == 1) then vendorPrice	= itemVendorPrice; end;
	if (AUCTIONATOR_A_TIPS == 1) then auctionPrice	= Atr_GetAuctionPrice (itemName); end;
	if (AUCTIONATOR_D_TIPS == 1) then dePrice		= Atr_CalcDisenchantPrice (itemType, itemRarity, itemLevel); end;
	
	local xstring = "";
	local showStackPrices = IsShiftKeyDown();
	
	if (AUCTIONATOR_SHIFT_TIPS == 2) then
		showStackPrices = not IsShiftKeyDown();
	end

	if (num and showStackPrices) then
		if (auctionPrice)	then	auctionPrice = auctionPrice * num;	end;
		if (vendorPrice)	then	vendorPrice  = vendorPrice  * num;	end;
		if (dePrice)  		then	dePrice  	 = dePrice  * num;	end;
		xstring = "|cFFAAAAFF x"..num.."|r";
	end;

	if (vendorPrice == nil) then
		vendorPrice = 0;
	end

	-- vendor info

	if (AUCTIONATOR_V_TIPS == 1 and vendorPrice > 0) then
		local vpadding = Atr_CalcTTpadding (vendorPrice, auctionPrice);
		tip:AddDoubleLine (ZT("Vendor")..xstring, "|cFFFFFFFF"..zc.priceToMoneyString (vendorPrice))
	end
	
	-- auction info

	if (AUCTIONATOR_A_TIPS == 1) then
		
		local bonding = Atr_GetBonding(itemID);
		local isBOP   = (bonding == 1);
		local isQuest = (bonding == 4 or bonding == 5);
		
		if (isBOP) then
			tip:AddDoubleLine (ZT("Auction")..xstring, "|cFFFFFFFF"..ZT("BOP").."  ");		
		elseif (isQuest) then
			tip:AddDoubleLine (ZT("Auction")..xstring, "|cFFFFFFFF"..ZT("Quest Item").."  ");		
		elseif (auctionPrice ~= nil) then
			tip:AddDoubleLine (ZT("Auction")..xstring, "|cFFFFFFFF"..zc.priceToMoneyString (auctionPrice));
		else
			tip:AddDoubleLine (ZT("Auction")..xstring, "|cFFFFFFFF"..ZT("unknown").."  ");
		end
	end
	
	-- disenchanting info

	if (AUCTIONATOR_D_TIPS == 1 and dePrice ~= nil) then
		if (dePrice > 0) then
			tip:AddDoubleLine (ZT("Disenchant")..xstring, "|cFFFFFFFF"..zc.priceToMoneyString(dePrice));
		else
			tip:AddDoubleLine (ZT("Disenchant")..xstring, "|cFFFFFFFF"..ZT("unknown").."  ");
		end
	end

	local showDetails = true;
	
	if (AUCTIONATOR_DE_DETAILS_TIPS == 1) then showDetails = IsShiftKeyDown(); end;
	if (AUCTIONATOR_DE_DETAILS_TIPS == 2) then showDetails = IsControlKeyDown(); end;
	if (AUCTIONATOR_DE_DETAILS_TIPS == 3) then showDetails = IsAltKeyDown(); end;
	if (AUCTIONATOR_DE_DETAILS_TIPS == 4) then showDetails = false; end;
	if (AUCTIONATOR_DE_DETAILS_TIPS == 5) then showDetails = true; end;
	
	if (showDetails and dePrice ~= nil) then
		Atr_AddDEDetailsToTip (tip, itemType, itemRarity, itemLevel, Atr_DEReqLevel(itemID));
	end

	tip:Show()

end

-----------------------------------------

hooksecurefunc (GameTooltip, "SetBagItem",
	function(tip, bag, slot)
		local _, num = GetContainerItemInfo(bag, slot);
		ShowTipWithPricing (tip, GetContainerItemLink(bag, slot), num);
	end
);

hooksecurefunc (GameTooltip, "SetAuctionItem",
	function (tip, type, index)
		local _, _, num = GetAuctionItemInfo(type, index);
		ShowTipWithPricing (tip, GetAuctionItemLink(type, index), num);
	end
);

hooksecurefunc (GameTooltip, "SetAuctionSellItem",
	function (tip)
		local name, _, count = GetAuctionSellItemInfo();
		local __, link = GetItemInfo(name);
		ShowTipWithPricing (tip, link, num);
	end
);


hooksecurefunc (GameTooltip, "SetLootItem",
	function (tip, slot)
		if LootSlotIsItem(slot) then
			local link, _, num = GetLootSlotLink(slot);
			ShowTipWithPricing (tip, link, num);
		end
	end
);

hooksecurefunc (GameTooltip, "SetLootRollItem",
	function (tip, slot)
		local _, _, num = GetLootRollItemInfo(slot);
		ShowTipWithPricing (tip, GetLootRollItemLink(slot), num);
	end
);


hooksecurefunc (GameTooltip, "SetInventoryItem",
	function (tip, unit, slot)
		ShowTipWithPricing (tip, GetInventoryItemLink(unit, slot), GetInventoryItemCount(unit, slot));
	end
);

hooksecurefunc (GameTooltip, "SetGuildBankItem",
	function (tip, tab, slot)
		local _, num = GetGuildBankItemInfo(tab, slot);
		ShowTipWithPricing (tip, GetGuildBankItemLink(tab, slot), num);
	end
);

hooksecurefunc (GameTooltip, "SetTradeSkillItem",
	function (tip, skill, id)
		local link = GetTradeSkillItemLink(skill);
		local num  = GetTradeSkillNumMade(skill);
		if id then
			link = GetTradeSkillReagentItemLink(skill, id);
			num = select (3, GetTradeSkillReagentInfo(skill, id));
		end

		ShowTipWithPricing (tip, link, num);
	end
);

hooksecurefunc (GameTooltip, "SetTradePlayerItem",
	function (tip, id)
		local _, _, num = GetTradePlayerItemInfo(id);
		ShowTipWithPricing (tip, GetTradePlayerItemLink(id), num);
	end
);

hooksecurefunc (GameTooltip, "SetTradeTargetItem",
	function (tip, id)
		local _, _, num = GetTradeTargetItemInfo(id);
		ShowTipWithPricing (tip, GetTradeTargetItemLink(id), num);
	end
);

hooksecurefunc (GameTooltip, "SetQuestItem",
	function (tip, type, index)
		local _, _, num = GetQuestItemInfo(type, index);
		ShowTipWithPricing (tip, GetQuestItemLink(type, index), num);
	end
);

hooksecurefunc (GameTooltip, "SetQuestLogItem",
	function (tip, type, index)
		local num, _;
		if type == "choice" then
			_, _, num = GetQuestLogChoiceInfo(index);
		else
			_, _, num = GetQuestLogRewardInfo(index)
		end

		ShowTipWithPricing (tip, GetQuestLogItemLink(type, index), num);
	end
);

hooksecurefunc (GameTooltip, "SetInboxItem",
	function (tip, index, attachIndex)
		local _, _, num = GetInboxItem(index, attachIndex);
		ShowTipWithPricing (tip, GetInboxItemLink(index, attachIndex), num);
	end
);

hooksecurefunc (GameTooltip, "SetSendMailItem",
	function (tip, id)
		local name, _, num = GetSendMailItem(id)
		local name, link = GetItemInfo(name);
		ShowTipWithPricing (tip, link, num);
	end
);

hooksecurefunc (GameTooltip, "SetHyperlink",
	function (tip, itemstring, num)
		local name, link = GetItemInfo (itemstring);
		ShowTipWithPricing (tip, link, num);
	end
);

hooksecurefunc (ItemRefTooltip, "SetHyperlink",
	function (tip, itemstring)
		local name, link = GetItemInfo (itemstring);
		ShowTipWithPricing (tip, link);
	end
);












local addonName, addonTable = ...; 
local zc = addonTable.zc;


-----------------------------------------

AtrL = {};

-----------------------------------------

function Atr_PickLocalizationTable (locale)

	local f = getglobal ("AtrBuildLTable_"..locale);
	if (type (f) == "function") then
		f();
--		DEFAULT_CHAT_FRAME:AddMessage (locale.." found");
	else
		AtrBuildLTable_enUS();
--		DEFAULT_CHAT_FRAME:AddMessage (locale.." not found");
	end

end

-----------------------------------------

Atr_PickLocalizationTable (GetLocale());
--Atr_PickLocalizationTable ("esES");

-----------------------------------------

function ZT (s)

	if (s == nil or s == "") then
		return s;
	end
	
	if (AtrL) then
		local s1 = AtrL[s];
		if (s1 and s1 ~= "" and not zc.StringStartsWith ("XXXXX")) then		
			return s1;
		end
	end
		
	return s;
end


-----------------------------------------

function zc.IsEnglishLocale()

	return (GetLocale() == "enUS" or GetLocale() == "enGB");

end

-----------------------------------------

local testt = {};
local Atr_excludes = { Cancel=1, Okay=1, Done=1, Close=1 }

-----------------------------------------

local function Atr_LocalizeChildText (frame)

	local child;
	local subregions = { frame:GetRegions() };
	for _, child in ipairs(subregions) do

		if  (type (child.GetText) == "function") then
			local ftext = child:GetText();
			local fname = tostring(child:GetName());
			
			if (ftext and ftext ~= "" and not Atr_excludes[ftext] and not zc.StringStartsWith (fname, "AuctionatorEntry")) then
				testt[ftext] = 1;
				child:SetText (ZT(ftext));
			end
		end
	end
	
	local kids = { frame:GetChildren() };
	for _, child in ipairs(kids) do
		
		if  (type (child.GetText) == "function") then
			local ftext = child:GetText();
			local fname = tostring(child:GetName());
			
			if (ftext and ftext ~= "" and not Atr_excludes[ftext] and not zc.StringStartsWith (fname, "AuctionatorEntry")) then
				testt[ftext] = 1;
				
				if (child:GetObjectType() == "Button") then
					local oldwid = math.floor(child:GetWidth());
					child:SetText (ZT(ftext));
					local newwid = math.floor(child:GetTextWidth()) + 15;
					if (newwid > oldwid) then
						child:SetWidth (newwid+20);
					end
				else
					child:SetText (ZT(ftext));
				end
			end
		end
			
		if (child:GetObjectType() ~= "Button") then
			Atr_LocalizeChildText (child);
		end
	end			

end

-----------------------------------------

function Atr_LocalizeFrames ()

	local frame = EnumerateFrames()
	while frame do
		local fname		= frame:GetName();
		local pname		= (frame:GetParent() and frame:GetParent():GetName() or nil);
		
		local isAuctionatorFrame = (zc.StringStartsWith (fname, "Atr") or zc.StringStartsWith (fname, "Auctionator")) and zc.StringSame (pname, "UIParent");
		if (fname == "Atr_Main_Panel") then
			isAuctionatorFrame = true;
		end
		
		if ( isAuctionatorFrame ) then
			Atr_LocalizeChildText (frame);
		end
		
		frame = EnumerateFrames(frame)
	end

--	zc.PrintKeysSorted (testt);

end

-----------------------------------------

local kUncutGems = {
	36924, 		-- sky sapphire
	36925, 		-- majestic zircon

	36918, 		-- scarlet ruby
	36919, 		-- cardinal ruby

	36933, 		-- forest emerald
	36934, 		-- eye of zul

	36930, 		-- monarch topaz
	36931, 		-- ametrine

	36927, 		-- twilight opal
	36928, 		-- dreadstone

	36921, 		-- autumns glow
	36922, 		-- kings amber

	41334, 		-- earthsiege diamond
	41266, 		-- skyflare diamond

	42225 		-- dragon's eye
	}

-----------------------------------------

function Atr_IsCutGem (itemLink)

	if (not Atr_IsGem (itemLink)) then
		return false;
	end
	
	local itemID = zc.ItemIDfromLink (itemLink);

	for n = 1, #kUncutGems do
		if (itemID == tostring (kUncutGems[n])) then
			return false;
		end
	end
	
	return true;
end

-----------------------------------------


function Atr_IsGlyph				(itemLink)		return (Atr_IsClass (itemLink, 5));		end
function Atr_IsGem					(itemLink)		return (Atr_IsClass (itemLink, 10));	end
function Atr_IsItemEnhancement		(itemLink)		return (Atr_IsClass (itemLink, 4, 6));	end
function Atr_IsPotion				(itemLink)		return (Atr_IsClass (itemLink, 4, 2));	end
function Atr_IsElixir				(itemLink)		return (Atr_IsClass (itemLink, 4, 3));	end
function Atr_IsFlask				(itemLink)		return (Atr_IsClass (itemLink, 4, 4));	end
function Atr_IsHerb					(itemLink)		return (Atr_IsClass (itemLink, 6, 6));	end

-----------------------------------------

-----------------------------------------
-- if Blizz introduces new auction classes this might need to change

function Atr_IsWeaponType				(itemType)		return (Atr_ItemType2AuctionClass (itemType) == 1);		end
function Atr_IsArmorType				(itemType)		return (Atr_ItemType2AuctionClass (itemType) == 2);		end

-----------------------------------------

function Atr_IsClass (itemLink, class, subclass)

	if (itemLink == nil) then
		return false;
	end

	local _, _, _, _, _, itemType, itemSubType = GetItemInfo (itemLink);

	local itemClass = Atr_ItemType2AuctionClass (itemType);
	local itemSubClass;
	
	if (itemClass == class) then
	
		if (subclass == nil) then
			return true;
		end
	
		itemSubClass = Atr_SubType2AuctionSubclass (itemClass, itemSubType)

		if (subclass == itemSubClass) then
			return true;
		end
	end
		
	return false;
end

-----------------------------------------

local gItemClasses;
local gItemSubClasses;

-----------------------------------------

function Atr_GetAuctionClasses()

	if (gItemClasses == nil) then
		gItemClasses = { GetAuctionItemClasses() };
	end
	
	return gItemClasses;
end

-----------------------------------------

function Atr_GetAuctionSubclasses (auctionClass)

	if (gItemSubClasses == nil) then
		gItemSubClasses = {};
	end
	
	if (gItemSubClasses[auctionClass] == nil) then
		gItemSubClasses[auctionClass] = { GetAuctionItemSubClasses(auctionClass) };
	end
	
	return gItemSubClasses[auctionClass];
end

-----------------------------------------

function Atr_ItemType2AuctionClass(itemType)

	local itemClasses = Atr_GetAuctionClasses();
		
	if #itemClasses > 0 then
	local itemClass;
		for x, itemClass in pairs(itemClasses) do
			if (zc.StringSame (itemClass, itemType)) then
				return x;
			end
		end
	end

	return 0;
end


-----------------------------------------

function Atr_SubType2AuctionSubclass(auctionClass, itemSubtype)

	local subclasses = Atr_GetAuctionSubclasses (auctionClass);

	if #subclasses > 0 then
	local itemSubClass;
		for x, itemSubClass in pairs(subclasses) do
			if (zc.StringSame (itemSubClass, itemSubtype)) then
				return x;
			end
		end
	end

	return 0;
end



AtrPane = {};
AtrPane.__index = AtrPane;

ATR_SHOW_CURRENT	= 1;
ATR_SHOW_HISTORY	= 2;
ATR_SHOW_HINTS		= 3;

function AtrPane.create ()

	local pane = {};
	setmetatable (pane,AtrPane);

	pane.fullStackSize	= 0;

	pane.totalItems		= 0;		-- total in bags for this item

	pane.UINeedsUpdate	= false;
	pane.showWhich		= ATR_SHOW_CURRENT;
	
	pane.activeSearch	= nil;
	pane.sortedHist		= nil;
	pane.hints			= nil;
	
	pane.hlistScrollOffset	= 0;
	
	pane:ClearSearch();
	
	return pane;
end


-----------------------------------------

function AtrPane:DoSearch (searchText, exact, rescanThreshold, callback)

	self.currIndex			= nil;
	self.histIndex			= nil;
	self.hintsIndex			= nil;
	
	self.sortedHist			= nil;
	self.hints				= nil;
	
	self.SS_hilite_itemName	= searchText;		-- by name for search summary
	
	Atr_ClearBuyState();

	self.activeScan = Atr_FindScan (nil);
	
	Atr_ClearAll();		-- it's fast, might as well just do it now for cleaner UE
	
	self.UINeedsUpdate = false;		-- will be set when scan finishes
			
	self.activeSearch = Atr_NewSearch (searchText, exact, rescanThreshold, callback);
	
	if (exact) then
		self.activeScan = self.activeSearch:GetFirstScan();
	end
	
	local cacheHit = false;
	
	if (searchText ~= "") then
		if (self.activeScan.whenScanned == 0) then		-- check whenScanned so we don't rescan cache hits
			self.activeSearch:Start();
		else
			self.UINeedsUpdate = true;
			cacheHit = true;
		end
	end
	
	return cacheHit;
end

-----------------------------------------

function AtrPane:ClearSearch ()
	self:DoSearch ("", true);
end

-----------------------------------------

function AtrPane:GetProcessingState ()
	
	if (self.activeSearch) then
		return self.activeSearch.processing_state;
	end
	
	return KM_NULL_STATE;
end

-----------------------------------------

function AtrPane:IsScanEmpty ()
	
	return (self.activeScan == nil or self.activeScan:IsNil());
	
end

-----------------------------------------

function AtrPane:ShowCurrent ()
	
	return self.showWhich == ATR_SHOW_CURRENT;
	
end

-----------------------------------------

function AtrPane:ShowHistory ()
	
	return self.showWhich == ATR_SHOW_HISTORY;
	
end

-----------------------------------------

function AtrPane:ShowHints ()
	
	return self.showWhich == ATR_SHOW_HINTS;
	
end

-----------------------------------------

function AtrPane:SetToShowCurrent ()
	
	self.showWhich = ATR_SHOW_CURRENT;
	
end

-----------------------------------------

function AtrPane:SetToShowHistory ()
	
	self.showWhich = ATR_SHOW_HISTORY;
	
end

-----------------------------------------

function AtrPane:SetToShowHints ()
	
	self.showWhich = ATR_SHOW_HINTS;
	
end



-----------------------------------------

AtrQuery = {};
AtrQuery.__index = AtrQuery;

-----------------------------------------

function Atr_NewQuery ()

	local query = {};
	setmetatable (query, AtrQuery);

	query.prevPage			= nil;
	query.numDupPages		= 0;
	query.pagenum			= -1;
	
	return query;
end			

-----------------------------------------

function AtrQuery:CheckForDuplicatePage (pagenum)

	local numBatchAuctions = GetNumAuctionItems("list");

	local thisPage		= {};
	thisPage.numOnPage	= numBatchAuctions;
	thisPage.items		= {};
	thisPage.pagenum	= pagenum;


	if (self.prevPage) then
--		zc.msg_atr ("Comparing page ", pagenum, " to pge ", self.prevPage.pagenum);
	
		if (self.prevPage.pagenum == pagenum) then
			return false;
		end
	end
	
	if (numBatchAuctions == 0) then
		self.prevPage = thisPage;
		return false;
	end

	local x;
	local prevPage			= self.prevPage;
	local dupPageFound		= true;
	local numDupItems		= 0;
	local allItemsIdentical	= true;
	
	for x = 1, numBatchAuctions do
	
		local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, owner = GetAuctionItemInfo("list", x);

		thisPage.items[x] = self:BuildItemIDstr (name, count, minBid, buyoutPrice, bidAmount);

		if (prevPage == nil or (thisPage.items[x] ~= prevPage.items[x])) then
		
			dupPageFound = false;
		else
			numDupItems = numDupItems + 1;
		end

		if (x > 1 and allItemsIdentical and thisPage.items[x] ~= thisPage.items[x-1]) then		-- handle those numnuts who post 200 identical auctions
			allItemsIdentical = false;
		end
					

	end

	if (prevPage ~= nil and prevPage.numOnPage ~= thisPage.numOnPage) then
	
--		zc.msg_pink ("page is unique - numauctions didn't match");
		dupPageFound = false;
		
	elseif (dupPageFound and allItemsIdentical) then
	
--		zc.msg_red ("Dup page found but all items identical: thisPage.numOnPage: ", thisPage.numOnPage);
		dupPageFound = false;
	
	elseif (not dupPageFound) then
	
--		zc.msg_pink ("page is unique");
	end
	
	
	if (dupPageFound) then
	
		self.numDupPages = self.numDupPages + 1;
--		zc.msg_atr ("DUPLICATE PAGE FOUND: thisPage.numOnPage: ", thisPage.numOnPage, "  numDupItems: ", numDupItems);
	else
		self.prevPage = thisPage;
	end

	return dupPageFound;
end


-----------------------------------------

function AtrQuery:IsLastPage (pagenum)

	local _, totalAuctions = GetNumAuctionItems("list");

	return (((pagenum + 1) * 50) >= totalAuctions);
end

-----------------------------------------

function AtrQuery:BuildItemIDstr(name, count, minBid, buyoutPrice, bidAmount)

	if (name) then
		return name.."_"..count.."_"..minBid.."_"..buyoutPrice.."_"..bidAmount;
	end
		
	return "";
end


local addonName, addonTable = ...; 
local zc = addonTable.zc;

KM_NULL_STATE	= 0;
KM_PREQUERY		= 1;
KM_INQUERY		= 2;
KM_POSTQUERY	= 3;
KM_ANALYZING	= 4;
KM_SETTINGSORT	= 5;

local AUCTION_CLASS_WEAPON = 1;
local AUCTION_CLASS_ARMOR  = 2;

local gAllScans = {};

local BIGNUM = 999999999999;

local ATR_SORTBY_NAME_ASC = 0;
local ATR_SORTBY_NAME_DES = 1;
local ATR_SORTBY_PRICE_ASC = 2;
local ATR_SORTBY_PRICE_DES = 3;

-----------------------------------------

AtrScan = {};
AtrScan.__index = AtrScan;

-----------------------------------------

AtrSearch = {};
AtrSearch.__index = AtrSearch;

-----------------------------------------

function Atr_NewSearch (itemName, exact, rescanThreshold, callback)

	local srch = {};
	setmetatable (srch, AtrSearch);
	srch:Init (itemName, exact, rescanThreshold, callback);

	return srch;
end

-----------------------------------------

function AtrSearch:Init (searchText, exact, rescanThreshold, callback)

	if (searchText == nil) then
		searchText = "";
	end

	self.origSearchText = searchText;
	
	if (not exact) then
		if (zc.StringStartsWith (searchText, "\"") and zc.StringEndsWith (searchText, "\"")) then
			searchText = string.sub (searchText, 2, searchText:len()-1);
			exact = true;
		end
	end		

	self.searchText			= searchText;
	self.exact				= exact;
	self.processing_state	= KM_NULL_STATE
	self.current_page		= -1
	self.items				= {};
	self.query				= Atr_NewQuery();
	self.sortedScans		= nil;
	self.sortHow			= ATR_SORTBY_PRICE_ASC;
	self.callback			= callback;
	
	if (exact) then	

		if (rescanThreshold and rescanThreshold > 0) then
			local scan = Atr_FindScan (searchText);
			if (scan and (time() - scan.whenScanned) <= rescanThreshold) then
				self.items[searchText] = scan;
			end
		end
		
		if (not self.items[searchText]) then		
			self.items[searchText] = Atr_FindScanAndInit (searchText);
		end
		
	end
	
end

-----------------------------------------

function Atr_FindScanAndInit (itemName)

	return Atr_FindScan (itemName, true);
end

-----------------------------------------

function Atr_FindScan (itemName, init)

	if (itemName == nil or itemName == "") then
		itemName = "nil";
	end

	local itemNameLC = string.lower (itemName);

	if (gAllScans[itemNameLC] == nil) then

		local scn = {};
		setmetatable (scn, AtrScan);
		scn:Init (itemName);

		gAllScans[itemNameLC] = scn;
	elseif (init) then
		gAllScans[itemNameLC]:Init (itemName);
	end
	
	return gAllScans[itemNameLC];
end

-----------------------------------------

function Atr_ClearScanCache ()

--	zc.msg_red ("Clearing Scan Cache");

	for a,v in pairs (gAllScans) do
		if (a ~= "nil") then
			gAllScans[a] = nil;
		end
	end

end

-----------------------------------------

function AtrScan:Init (itemName)
	self.itemName			= itemName;
	self.itemLink			= nil;
	self.scanData			= {};
	self.sortedData			= {};
	self.whenScanned		= 0;
	self.lowprices			= {BIGNUM, BIGNUM, BIGNUM};
	self.absoluteBest		= nil;
	self.itemClass			= 0;
	self.itemSubclass		= 0;
	self.yourBestPrice		= nil;
	self.yourWorstPrice		= nil;
	self.numYourSingletons	= 0;
	self.itemTextColor 		= { 1.0, 1.0, 1.0 };
	self.searchWasExact		= false;
	
	self:UpdateItemLink (Atr_GetItemLink (itemName));
end

-----------------------------------------

function AtrScan:UpdateItemLink (itemLink)

	self.itemLink = itemLink;
	
	if (itemLink) then
	
		Atr_AddToItemLinkCache (self.itemName, itemLink);

		local _, _, quality, _, _, sType, sSubType = GetItemInfo(itemLink);

		self.itemQuality	= quality;
		self.itemClass		= Atr_ItemType2AuctionClass (sType);
		self.itemSubclass	= Atr_SubType2AuctionSubclass (self.itemClass, sSubType);	

		self.itemTextColor = { 1.0, 1.0, 1.0 };

		if (quality == 0)	then	self.itemTextColor = { 0.6, 0.6, 0.6 };	end
		if (quality == 2)	then	self.itemTextColor = { 0.2, 1.0, 0.0 };	end
		if (quality == 3)	then	self.itemTextColor = { 0.0, 0.5, 1.0 };	end
		if (quality == 4)	then	self.itemTextColor = { 0.7, 0.3, 1.0 };	end
	end

end


-----------------------------------------

function AtrSearch:NumScans()

	if (self.sortedScans) then
		return #self.sortedScans;
	end

	local count = 0;
	for name,scn in pairs (self.items) do
		count = count + 1;
	end

	return count;
end

-----------------------------------------

function AtrSearch:NumSortedScans()

	if (self.sortedScans) then
		return #self.sortedScans;
	end

	return 0;
end

-----------------------------------------

function AtrSearch:GetFirstScan()

	if (self.sortedScans) then
		return self.sortedScans[1];
	end

	for name,scn in pairs (self.items) do
		return scn;
	end
	
	return nil;

end


-----------------------------------------

function AtrSearch:Start ()

	if (self.searchText == "") then
		return;
	end
	
	if (Atr_IsCompoundSearch (self.searchText)) then
			
		local _, itemClass = Atr_ParseCompoundSearch (self.searchText);
	
		if (itemClass == 0) then
			Atr_Error_Display (ZT("The first part of this compound\n\nsearch is not a valid category."));
			return;
		end

		self.sortHow = ATR_SORTBY_PRICE_DES;

	end
	
	self.processing_state = KM_SETTINGSORT;
	
	SortAuctionClearSort ("list");

	BrowseName:SetText (self.searchText);		-- not necessary but nice when user switches to Browse tab

	self.current_page		= 0;
	self.processing_state	= KM_PREQUERY;

	self:Continue();
	
end

-----------------------------------------

function AtrSearch:Abort ()

	if (self.processing_state == KM_NULL_STATE) then
		return;
	end

	self.processing_state = KM_NULL_STATE;
	self:Init();
end

-----------------------------------------

function AtrSearch:CheckForDuplicatePage ()

	local isDup = self.query:CheckForDuplicatePage(self.current_page);

	if (isDup) then
--		zc.msg_red ("DUPLICATE PAGE FOUND: ", "  current_page: ", self.current_page, "  numDupPages: ", self.query.numDupPages);

		self.current_page	= self.current_page - 1;   -- requery the page
		
		self.processing_state = KM_PREQUERY;
	end
		
	return isDup;
end


-----------------------------------------

function AtrSearch:AnalyzeResultsPage()

	self.processing_state = KM_ANALYZING;

	if (self.query.numDupPages > 10) then 	 -- hopefully this will never happen but need check to avoid looping
		return true;						 -- done
	end


	local numBatchAuctions, totalAuctions = GetNumAuctionItems("list");

	if (self.current_page == 1 and totalAuctions > 2000) then -- give Blizz servers a break
		Atr_Error_Display (ZT("Too many results\n\nPlease narrow your search"));
		return true;  -- done
	end

	if (totalAuctions >= 50) then
		Atr_SetMessage (string.format (ZT("Scanning auctions: page %d"), self.current_page));
	end

	-- analyze

	local numNilOwners = 0;

	if (numBatchAuctions > 0) then

		local x;

		for x = 1, numBatchAuctions do

			local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, owner = GetAuctionItemInfo("list", x);

			if (owner == nil) then
				numNilOwners = numNilOwners + 1;
			end
			
			local exactMatch = zc.StringSame (name, self.searchText);

			if (exactMatch or not self.exact) then

				if (self.items[name] == nil) then
					self.items[name] = Atr_FindScanAndInit (name);
				end
				
				local curpage = (tonumber(self.current_page)-1);

				local scn = self.items[name];

				scn:AddScanItem (name, count, buyoutPrice, owner, 1, curpage);
				
				if (scn.itemLink == nil or self.itemClass == nil) then
					scn:UpdateItemLink (GetAuctionItemLink("list", x));
				end

				if (self.callback) then
					self.callback (x, numBatchAuctions, count, buyoutPrice, owner);
				end
				
			end
		end
	end
	
	local done = (numBatchAuctions < 50);

	if (not done) then
		self.processing_state = KM_PREQUERY;
	end
	
	return done;
end

-----------------------------------------

function AtrScan:AddScanItem (name, stackSize, buyoutPrice, owner, numAuctions, curpage)

	local sd = {};
	local i;

	if (numAuctions == nil) then
		numAuctions = 1;
	end

	for i = 1, numAuctions do
		sd["stackSize"]		= stackSize;
		sd["buyoutPrice"]	= buyoutPrice;
		sd["owner"]			= owner;
		sd["pagenum"]		= curpage;

		tinsert (self.scanData, sd);
		
		local itemPrice = math.floor (buyoutPrice / stackSize);

		Atr_AddToLowPrices (self.lowprices, itemPrice);
	end

end


-----------------------------------------

function AtrScan:AddSDXToScan (price, owner, volume)	-- helper function for AddExternalDataToScan

	local sd = {};

	if (price and price > 0) then
		sd["stackSize"]		= 1;
		sd["buyoutPrice"]	= price;
		sd["owner"]			= owner;

		if (volume) then
			sd["volume"] = volume;
		end

		tinsert (self.scanData, sd);
	end
	
end

-----------------------------------------

function AtrScan:AddExternalDataToScan ()

	if (self.itemLink == nil) then
		return;
	end

	-- Wowecon

	if (Wowecon and Wowecon.API) then
	
		local priceG, volG = Wowecon.API.GetAuctionPrice_ByLink (self.itemLink, Wowecon.API.GLOBAL_PRICE)
		local priceS, volS = Wowecon.API.GetAuctionPrice_ByLink (self.itemLink, Wowecon.API.SERVER_PRICE)

		self:AddSDXToScan (priceG, "__wowEconG", volG);
		self:AddSDXToScan (priceS, "__wowEconS", volS);
		
	end
	
	-- GoingPrice Wowhead
	
	local id = zc.ItemIDfromLink (self.itemLink);
	
	id = tonumber(id);

	if (GoingPrice_Wowhead_Data and GoingPrice_Wowhead_Data[id] and GoingPrice_Wowhead_SV._index) then
		local index = GoingPrice_Wowhead_SV._index["Buyout price"];

		if (index ~= nil) then
			local price = GoingPrice_Wowhead_Data[id][index];
		
			self:AddSDXToScan (price, "__wowHead");
		end
	end

	-- GoingPrice Allakhazam
	
	if (GoingPrice_Allakhazam_Data and GoingPrice_Allakhazam_Data[id] and GoingPrice_Allakhazam_SV._index) then
		local index = GoingPrice_Allakhazam_SV._index["Median"];

		if (index ~= nil) then
			local price = GoingPrice_Allakhazam_Data[id][index];
		
			self:AddSDXToScan (price, "__allakhazam");
		end
	end

	-- most recent historical price
	
	local price = Atr_Process_Historydata();
	if (price ~= nil) then
		self:AddSDXToScan (price, "__atrLast");
	end

end

-----------------------------------------

function AtrScan:SubtractScanItem (name, stackSize, buyoutPrice)

	local sd;
	local i;

	for i,sd in ipairs (self.scanData) do
		
		if (sd.stackSize == stackSize and sd.buyoutPrice == buyoutPrice) then
			
			tremove (self.scanData, i);
			return;
		end
	end

end

-----------------------------------------

function Atr_IsCompoundSearch (searchString)
	
	return zc.StringContains (searchString, ">") or zc.StringContains (searchString, "/");
end

-----------------------------------------

function Atr_ParseCompoundSearch (searchString)

	local delim = "/";

	if (zc.StringContains (searchString, ">")) then
		delim = ">";
	end

	local tbl	= { strsplit (delim, searchString) };
	
	local queryString	= "";
	local itemClass		= 0;
	local itemSubclass	= 0;
	local minLevel		= nil;
	local maxLevel		= nil;
	local prevWasItemClass;
	local n;
	
	for n = 1,#tbl do
		local s = tbl[n];

		local handled = false;

		if (not handled and tonumber(s)) then
			if (minLevel == nil) then
				minLevel = tonumber(s);
			elseif (maxLevel == nil) then
				maxLevel = tonumber(s);
			end
			
			handled = true;
			prevWasItemClass = false;
		end
		
		if (not handled and prevWasItemClass and itemSubclass == 0) then
			itemSubclass = Atr_SubType2AuctionSubclass (itemClass, s);
			if (itemSubclass > 0) then
				handled = true;
				prevWasItemClass = false;
			end
		end
		
		if (not handled and itemClass == 0) then
			itemClass = Atr_ItemType2AuctionClass (s);
			if (itemClass > 0) then
				prevWasItemClass = true;
				handled = true;
			end
		end
		
		if (not handled) then
			queryString = s;
			handled = true;
		end
	end	

	return queryString, itemClass, itemSubclass, minLevel, maxLevel;
end

-----------------------------------------

function AtrSearch:Continue()

	if (CanSendAuctionQuery()) then

		self.processing_state = KM_IN_QUERY;

		local queryString = self.searchText;

--	zc.md (queryString.."  page:"..self.current_page);
		
		local itemClass		= 0;
		local itemSubclass	= 0;
		local minLevel		= nil;
		local maxLevel		= nil;
		
		if (self.exact) then
			local scn = self:GetFirstScan();
			itemClass		= scn.itemClass;
			itemSubclass	= scn.itemSubclass;
		end

		if (Atr_IsCompoundSearch(queryString)) then
		
			queryString, itemClass, itemSubclass, minLevel, maxLevel = Atr_ParseCompoundSearch (queryString);
		
		end

		queryString = zc.UTF8_Truncate (queryString,63);	-- attempting to reduce number of disconnects

		QueryAuctionItems (queryString, minLevel, maxLevel, nil, itemClass, itemSubclass, self.current_page, nil, nil);

		self.query_sent_when	= gAtr_ptime;
		self.processing_state	= KM_POSTQUERY;
		self.current_page		= self.current_page + 1;
	end

end

-----------------------------------------

local gSortScansBy;

-----------------------------------------

local function Atr_SortScans (x, y)

	if (gSortScansBy == ATR_SORTBY_NAME_ASC) then		return string.lower (x.itemName) < string.lower (y.itemName);	end
	if (gSortScansBy == ATR_SORTBY_NAME_DES) then		return string.lower (x.itemName) > string.lower (y.itemName);	end

	local xprice = 0;
	local yprice = 0;
	
	if (x.absoluteBest) then	xprice = zc.round(x.absoluteBest.buyoutPrice/x.absoluteBest.stackSize);		end;
	if (y.absoluteBest) then	yprice = zc.round(y.absoluteBest.buyoutPrice/y.absoluteBest.stackSize);		end;
	
	if (gSortScansBy == ATR_SORTBY_PRICE_ASC) then		return xprice < yprice;		end
	if (gSortScansBy == ATR_SORTBY_PRICE_DES) then		return xprice > yprice;		end

end

-----------------------------------------

function AtrSearch:Finish()

	local finishTime = time();
	
	self.processing_state	= KM_NULL_STATE;
	self.current_page		= -1;
	self.query_sent_when	= nil;
	
	self.sortedScans = nil;
	
	local wasExactSearch = (self:NumScans() == 1);		-- search returned only 1 item
	
	local x = 1;
	self.sortedScans = {};
	
	for name,scn in pairs (self.items) do
	
		self.sortedScans[x] = scn;
		x = x + 1;
		
		scn.whenScanned		= finishTime;
		scn.searchWasExact	= wasExactSearch;

		scn:CondenseAndSort ();

		-- update the fullscan DB
		
		local newprice = Atr_CalcNewDBprice (scn.itemName, scn.lowprices);
		
		if (newprice > 0) then
			if (scn.itemQuality + 1 >= AUCTIONATOR_SCAN_MINLEVEL) then
				gAtr_ScanDB[scn.itemName] = newprice;
			end
		end
	end
	
	Atr_ClearBrowseListings();
	
	gSortScansBy = self.sortHow;
	table.sort (self.sortedScans, Atr_SortScans);
	
end

-----------------------------------------

function AtrSearch:ClickPriceCol()

	if (self.sortHow == ATR_SORTBY_PRICE_ASC) then
		self.sortHow = ATR_SORTBY_PRICE_DES;
	else
		self.sortHow = ATR_SORTBY_PRICE_ASC;
	end

	gSortScansBy = self.sortHow;
	table.sort (self.sortedScans, Atr_SortScans);

end

-----------------------------------------

function AtrSearch:ClickNameCol()

	if (self.sortHow == ATR_SORTBY_NAME_ASC) then
		self.sortHow = ATR_SORTBY_NAME_DES;
	else
		self.sortHow = ATR_SORTBY_NAME_ASC;
	end

	gSortScansBy = self.sortHow;
	table.sort (self.sortedScans, Atr_SortScans);
end

-----------------------------------------

function AtrSearch:UpdateArrows()

	Atr_Col1_Heading_ButtonArrow:Hide();
	Atr_Col3_Heading_ButtonArrow:Hide();
	
	if (self.sortHow == ATR_SORTBY_PRICE_ASC) then
		Atr_Col1_Heading_ButtonArrow:Show();
		Atr_Col1_Heading_ButtonArrow:SetTexCoord(0, 0.5625, 0, 1.0);
	elseif (self.sortHow == ATR_SORTBY_PRICE_DES) then
		Atr_Col1_Heading_ButtonArrow:Show();
		Atr_Col1_Heading_ButtonArrow:SetTexCoord(0, 0.5625, 1.0, 0);
	elseif (self.sortHow == ATR_SORTBY_NAME_ASC) then
		Atr_Col3_Heading_ButtonArrow:Show();
		Atr_Col3_Heading_ButtonArrow:SetTexCoord(0, 0.5625, 0, 1.0);
	elseif (self.sortHow == ATR_SORTBY_NAME_DES) then
		Atr_Col3_Heading_ButtonArrow:Show();
		Atr_Col3_Heading_ButtonArrow:SetTexCoord(0, 0.5625, 1.0, 0);
	end
end

-----------------------------------------

function Atr_ClearBrowseListings()
	
	local start = time();

	while (time() - start < 5) do
	
		if (CanSendAuctionQuery()) then
			QueryAuctionItems("xyzzy", 43, 43, 0, 7, 0);
			break;
		end
	end

end

-----------------------------------------

function Atr_SortAuctionData (x, y)

	return x.itemPrice < y.itemPrice;

end

-----------------------------------------

function AtrScan:CondenseAndSort ()

	----- Condense the scan data into a table that has only a single entry per stacksize/price combo

	self.sortedData	= {};

	local i,sd;
	local conddata = {};

	for i,sd in ipairs (self.scanData) do

		local ownerCode = "x";
		local dataType  = "n";		-- normal
		
		if (sd.owner == UnitName("player")) then
			ownerCode = "y";
--		elseif (Atr_IsMyToon (sd.owner)) then
--			ownerCode = sd.owner;
		elseif (sd.owner == "__wowEconG") then
			dataType = "eg";
		elseif (sd.owner == "__wowEconS") then
			dataType = "es";
		elseif (sd.owner == "__wowHead") then
			dataType = "h";
		elseif (sd.owner == "__allakhazam") then
			dataType = "k";
		elseif (sd.owner == "__atrLast") then
			dataType = "a";
		end

		local key = "_"..sd.stackSize.."_"..sd.buyoutPrice.."_"..ownerCode..dataType;

		if (conddata[key]) then
			conddata[key].count		= conddata[key].count + 1;
			conddata[key].minpage 	= zc.Min (conddata[key].minpage, sd.pagenum);
			conddata[key].maxpage 	= zc.Max (conddata[key].maxpage, sd.pagenum);
		else
			local data = {};

			data.stackSize 		= sd.stackSize;
			data.buyoutPrice	= sd.buyoutPrice;
			data.itemPrice		= sd.buyoutPrice / sd.stackSize;
			data.minpage		= sd.pagenum;
			data.maxpage		= sd.pagenum;
			data.count			= 1;
			data.type			= dataType;
			data.yours			= (ownerCode == "y");
			
			if (ownerCode ~= "x" and ownerCode ~= "y") then
				data.altname = ownerCode;
			end
			
			if (sd.volume) then
				data.volume = sd.volume;
			end
			
			conddata[key] = data;
		end

	end

	----- create a table of these entries

	local n = 1;

	local i, v;

	for i,v in pairs (conddata) do
		self.sortedData[n] = v;
		n = n + 1;
	end

	-- sort the table by itemPrice

	table.sort (self.sortedData, Atr_SortAuctionData);

	-- analyze and store some info about the data

	self:AnalyzeSortData ();

end

-----------------------------------------

function AtrScan:AnalyzeSortData ()

	self.absoluteBest			= nil;
	self.bestPrices				= {};		-- a table with one entry per stacksize that is the cheapest auction for that particular stacksize
	self.numMatches				= 0;
	self.numMatchesWithBuyout	= 0;
	self.hasStack				= false;
	self.yourBestPrice			= nil;
	self.yourWorstPrice			= nil;
	self.numYourSingletons		= 0;

	local j, sd;

	----- find the best price per stacksize and overall -----

	for j,sd in ipairs(self.sortedData) do

		if (sd.type == "n") then

			self.numMatches = self.numMatches + 1;

			if (sd.itemPrice > 0) then

				self.numMatchesWithBuyout = self.numMatchesWithBuyout + 1;

				if (self.bestPrices[sd.stackSize] == nil or self.bestPrices[sd.stackSize].itemPrice >= sd.itemPrice) then
					self.bestPrices[sd.stackSize] = sd;
				end

				if (self.absoluteBest == nil or self.absoluteBest.itemPrice > sd.itemPrice) then
					self.absoluteBest = sd;
				end
				
				if (sd.yours) then
					if (self.yourBestPrice == nil or self.yourBestPrice > sd.itemPrice) then
						self.yourBestPrice = sd.itemPrice;
					end
					
					if (self.yourWorstPrice == nil or self.yourWorstPrice < sd.itemPrice) then
						self.yourWorstPrice = sd.itemPrice;
					end
					
					if (sd.stackSize == 1) then
						self.numYourSingletons = self.numYourSingletons + sd.count;
					end
				end
			end

			if (sd.stackSize > 1) then
				self.hasStack = true;
			end
		end
	end
end

-----------------------------------------

function AtrScan:FindInSortedData (stackSize, buyoutPrice)
	local j = 1;
	for j = 1,#self.sortedData do
		sd = self.sortedData[j];
		if (sd.stackSize == stackSize and sd.buyoutPrice == buyoutPrice and sd.yours) then
			return j;
		end
	end
	
	return 0;
end


-----------------------------------------

function AtrScan:FindMatchByStackSize (stackSize)

	local index = nil;

	local basedata = self.absoluteBest;

	if (self.bestPrices[stackSize]) then
		basedata = self.bestPrices[stackSize];
	end

	local numrows = #self.sortedData;

	local n;

	for n = 1,numrows do

		local data = self.sortedData[n];

		if (basedata and data.itemPrice == basedata.itemPrice and data.stackSize == basedata.stackSize and data.yours == basedata.yours) then
			index = n;
			break;
		end
	end

	return index;
	
end

-----------------------------------------

function AtrScan:FindMatchByYours ()

	local index = nil;

	local j;
	for j = 1,#self.sortedData do
		sd = self.sortedData[j];
		if (sd.yours) then
			index = j;
			break;
		end
	end

	return index;

end

-----------------------------------------

function AtrScan:FindCheapest ()

	local index = nil;

	local j;
	for j = 1,#self.sortedData do
		sd = self.sortedData[j];
		if (sd.itemPrice > 0) then
			index = j;
			break;
		end
	end

	return index;

end


-----------------------------------------

function AtrScan:GetNumAvailable ()

	local num = 0;

	local j, data;
	for j = 1,#self.sortedData do

		data = self.sortedData[j];
		num = num + (data.count * data.stackSize);
	end
	
	return num;
end

-----------------------------------------

function AtrScan:IsNil ()

	if (self.itemName == nil or self.itemName == "" or self.itemName == "nil") then
		return true;
	end
	
	return false;
end

-----------------------------------------

ATR_FS_NULL			= 0;
ATR_FS_STARTED		= 1;
ATR_FS_ANALYZING	= 2;
ATR_FS_CLEANING_UP	= 3;

gAtr_FullScanState = ATR_FS_NULL;


-----------------------------------------

function Atr_GetDBsize()

	local n = 0;
	local a,v;

	for a,v in pairs (gAtr_ScanDB) do
		n = n + 1;
	end
	
	return n;
end

-----------------------------------------

local gNumAdded, gNumUpdated;

-----------------------------------------

function Atr_FullScanStart()

	local canQuery,canQueryAll = CanSendAuctionQuery();
	
	if (canQueryAll) then
	
		Atr_FullScanStatus:SetText (ZT("Scanning").."...");
		Atr_FullScanStartButton:Disable();
		Atr_FullScanDone:Disable();
	
		gAtr_FullScanState = ATR_FS_STARTED;

		SortAuctionClearSort ("list");

		gNumAdded = 0;
		gNumUpdated = 0;

		QueryAuctionItems ("", nil, nil, 0, 0, 0, 0, 0, 0, true);
	end

end

-----------------------------------------

function Atr_CalcNewDBprice (name, prices)
		
	if (prices[1] ~= BIGNUM) then
		return prices[1];
	end

	return 0;
	
end

-----------------------------------------

function Atr_AddToLowPrices (lowprices, itemPrice)
	
	if (itemPrice > 0) then
		if (itemPrice < lowprices[1]) then
			if (lowprices[1] < lowprices[2]) then
				lowprices[2] = lowprices[1];
			end
			lowprices[1] = itemPrice;
			return true;
		elseif (itemPrice < lowprices[2]) then
			lowprices[2] = itemPrice;
			return true;
		end
	end

	return false;
end




-----------------------------------------

local gScanDetails = {}

-----------------------------------------

function Atr_FullScanMoreDetails ()

	zc.msg (" ");
	zc.msg_atr (ZT("Auctions scanned")..": |cffffffff", gScanDetails.numBatchAuctions, " |r("..gScanDetails.totalItems, "items)");
	zc.msg_atr ("|cffa335ee   "..ZT("Epic items")..": |r",		gScanDetails.numEachQual[5]);
	zc.msg_atr ("|cff0070dd   "..ZT("Rare items")..": |r",		gScanDetails.numEachQual[4]);
	zc.msg_atr ("|cff1eff00   "..ZT("Uncommon items")..": |r",	gScanDetails.numEachQual[3]);
	zc.msg_atr ("|cffffffff   "..ZT("Common items")..": |r",		gScanDetails.numEachQual[2]);
	zc.msg_atr ("|cff9d9d9d   "..ZT("Poor items")..": |r",		gScanDetails.numEachQual[1]);
	
	
	if (gScanDetails.numRemoved[4] > 0) then		zc.msg_atr (ZT("Rare items").." "..ZT("removed from database")..": |cffffffff",		gScanDetails.numRemoved[4]);		end
	if (gScanDetails.numRemoved[3] > 0) then		zc.msg_atr (ZT("Uncommon items").." "..ZT("removed from database")..": |cffffffff",	gScanDetails.numRemoved[3]);		end
	if (gScanDetails.numRemoved[2] > 0) then		zc.msg_atr (ZT("Common items").." "..ZT("removed from database")..": |cffffffff",	gScanDetails.numRemoved[2]);		end
	if (gScanDetails.numRemoved[1] > 0) then		zc.msg_atr (ZT("Poor items").." "..ZT("removed from database")..": |cffffffff",		gScanDetails.numRemoved[1]);		end
	
	zc.msg_atr (ZT("Items added to database")..": |cffffffff", gScanDetails.gNumAdded);
	zc.msg_atr (ZT("Items updated in database")..": |cffffffff", gScanDetails.gNumUpdated);
	zc.msg_atr (ZT("Items ignored")..": |cffffffff", gScanDetails.totalItems - (gScanDetails.gNumAdded + gScanDetails.gNumUpdated));
	zc.msg (" ");
end

-----------------------------------------

function Atr_FullScanAnalyze()

	gAtr_FullScanState = ATR_FS_ANALYZING;

	Atr_FullScanStatus:SetText (ZT("Processing"));
	

	local numBatchAuctions, totalAuctions = GetNumAuctionItems("list");

	zc.md ("FULL SCAN:"..numBatchAuctions.." out of  "..totalAuctions)

	local lowprices = {};
	local x;
	
	local qualities = {};
	
	if (numBatchAuctions > 0) then

		for x = 1, numBatchAuctions do

			local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice = GetAuctionItemInfo("list", x);

			qualities[name] = quality;
			
			if (name ~= nil and buyoutPrice ~= nil) then
			
				local itemPrice = math.floor (buyoutPrice / count);
			
				if (itemPrice > 0) then
					if (not lowprices[name]) then
						lowprices[name] = {BIGNUM,BIGNUM,BIGNUM};		-- one extra for later
					end
					
					Atr_AddToLowPrices (lowprices[name], itemPrice);
				end
			end

			if (x % 100 == 0) then
				Atr_FullScanStatus:SetText (ZT("Processing").." ("..x..")");
			end
		end
	end

	local numEachQual = {0, 0, 0, 0, 0, 0, 0, 0, 0};
	local totalItems = 0;
	local numRemoved = { 0, 0, 0, 0, 0, 0, 0, 0 };
	
	for name,prices in pairs (lowprices) do
		
		local newprice = Atr_CalcNewDBprice (name, prices);
		
		if (newprice > 0) then
		
			local qx = qualities[name] + 1;
			
			numEachQual[qx]	= numEachQual[qx] + 1;
			totalItems		= totalItems + 1;
			
			if (qx < AUCTIONATOR_SCAN_MINLEVEL and gAtr_ScanDB[name]) then
				numRemoved[qx] = numRemoved[qx] + 1;
				gAtr_ScanDB[name] = nil;
				zc.md ("removed: |cffbbbbbb", name, "   ("..qx..")");
			end
			
			if (qx >= AUCTIONATOR_SCAN_MINLEVEL) then

				if (gAtr_ScanDB[name] == nil) then
					gNumAdded = gNumAdded + 1;
				else
					gNumUpdated = gNumUpdated + 1;
				end

				gAtr_ScanDB[name] = newprice;
			end
		end
	end

	gScanDetails.numBatchAuctions		= numBatchAuctions;
	gScanDetails.totalItems				= totalItems;
	gScanDetails.numEachQual			= numEachQual;
	gScanDetails.numRemoved				= numRemoved;
	gScanDetails.gNumAdded				= gNumAdded;
	gScanDetails.gNumUpdated			= gNumUpdated;


	if (Atr_PrintBargains and Atr_CheckForBargain and numBatchAuctions > 0) then

		for x = 1, numBatchAuctions do
			Atr_CheckForBargain (x);
		end
		
		Atr_PrintBargains();
	end
	
	gAtr_FullScanState = ATR_FS_CLEANING_UP;

	Atr_FullScanMoreDetails();

	Atr_FullScanStatus:SetText (ZT("Cleaning up"));

	Atr_FullScanStartButton:Enable();
	Atr_FullScanDone:Enable();
	Atr_FullScanStatus:SetText ("");
	
	Atr_FSR_scanned_count:SetText	(numBatchAuctions);
	Atr_FSR_added_count:SetText		(gNumAdded);
	Atr_FSR_updated_count:SetText	(gNumUpdated);
	Atr_FSR_ignored_count:SetText	(totalItems - (gNumAdded + gNumUpdated));
	
	Atr_FullScanHTML:Hide();
	Atr_FullScanResults:Show();
	
	Atr_FullScanResults:SetBackdropColor (0.3, 0.3, 0.4);
	
	AUCTIONATOR_LAST_SCAN_TIME = time();
	
	Atr_UpdateFullScanFrame ();

	Atr_ClearBrowseListings();
	
	lowprices = {};
	collectgarbage ("collect");
end

-----------------------------------------

function auctionator_AuctionFrameBrowse_Update ()

	return auctionator_orig_AuctionFrameBrowse_Update ();

end

-----------------------------------------

function Atr_ShowFullScanFrame()

	Atr_FullScanHTML:Show();
	Atr_FullScanResults:Hide();

	Atr_FullScanFrame:Show();
	Atr_FullScanFrame:SetBackdropColor(0,0,0,100);
	
	Atr_UpdateFullScanFrame();
	Atr_FullScanStatus:SetText ("");

	local expText = "<html><body>"
					.."<p>"
					..ZT("Scanning is entirely optional.")
					.."<br/><br/>"
					..ZT("SCAN_EXPLANATION")
					.."</p>"
					.."</body></html>"
					;



	Atr_FullScanHTML:SetText (expText);
	Atr_FullScanHTML:SetSpacing (3);
end

-----------------------------------------

function Atr_UpdateFullScanFrame()

	Atr_FullScanDBsize:SetText (Atr_GetDBsize());
	
	if (AUCTIONATOR_LAST_SCAN_TIME) then
		Atr_FullScanDBwhen:SetText (date ("%A, %B %d at %I:%M %p", AUCTIONATOR_LAST_SCAN_TIME));
	else
		Atr_FullScanDBwhen:SetText (ZT("Never"));
	end

	local canQuery,canQueryAll = CanSendAuctionQuery();

	if (canQueryAll) then
		Atr_FullScanStatus:SetText ("");
		Atr_FullScanStartButton:Enable();
		Atr_FullScanNext:SetText(ZT("Now"));
	else	
		Atr_FullScanStartButton:Disable();

		if (AUCTIONATOR_LAST_SCAN_TIME) then
			local when = 15*60 - (time() - AUCTIONATOR_LAST_SCAN_TIME);
		
			when = math.floor (when/60);
		
			if (when == 0) then
				Atr_FullScanNext:SetText (ZT("in less than a minute"));
			elseif (when == 1) then
				Atr_FullScanNext:SetText (ZT("in about one minute"));
			elseif (when > 0) then
				Atr_FullScanNext:SetText (string.format (ZT("in about %d minutes"), when));
			else
				Atr_FullScanNext:SetText (ZT("unknown"));
			end
		else
			Atr_FullScanNext:SetText (ZT("unknown"));
		end
	end
end

-----------------------------------------

function Atr_FullScanFrameIdle()

	if (gAtr_FullScanState == ATR_FS_CLEANING_UP) then
	
		Atr_FullScanStatus:SetText ("Cleaning up");
		
		if (GetNumAuctionItems("list") < 100) then
		
			Atr_FullScanStatus:SetText (ZT("Scan complete"));
			PlaySound("AuctionWindowClose");
			
			gAtr_FullScanState = ATR_FS_NULL;
		end
	
	end
	
	if (gAtr_FullScanState == ATR_FS_STARTED) then

		local btext = Atr_FullScanStatus:GetText ();
		
		if (btext) then
			if (string.len (btext) > 25) then
				Atr_FullScanStatus:SetText (ZT("Scanning")..".");
			else
				Atr_FullScanStatus:SetText (btext..".");
			end
		end
	end
	
end









local addonName, addonTable = ...; 
local zc = addonTable.zc;

-----------------------------------------

Atr_SList = {};
Atr_SList.__index = Atr_SList;

local SLITEMS_NUM_LINES = 15;

local gCurrentSList;

-----------------------------------------

function Atr_ShoppingListsInit ()

	local num = #AUCTIONATOR_SHOPPING_LISTS;
	local x;
	
	for x = 1,num do
		setmetatable (AUCTIONATOR_SHOPPING_LISTS[x], Atr_SList);
	end
	
end

-----------------------------------------

function Atr_SList.create (name, isRecents)

	local slist = {};
	setmetatable (slist,Atr_SList);

	slist.name		= name;
	slist.items		= {};
	
	if (isRecents) then
		slist.isRecents = 1;
	end
	
	table.insert (AUCTIONATOR_SHOPPING_LISTS, slist);

	table.sort (AUCTIONATOR_SHOPPING_LISTS, Atr_SortSlists);
	Atr_DropDownSL_Initialize ();
	
	return slist;
end


-----------------------------------------

function Atr_SortSlists (x, y)

	if (x.isRecents) then return true; end;
	if (y.isRecents) then return false; end;

	return (string.lower(x.name) < string.lower(y.name));

end

-----------------------------------------

function Atr_SList:AddItem (itemName)

	if (itemName == "" or itemName == nil) then
		return;
	end

	if (self.isRecents) then
		table.insert (self.items, 1, itemName);
		
		while (#self.items > 50) do		-- max 50 items on recents list
			table.remove (self.items);
		end
	else
		table.insert (self.items, itemName);
		self.isSorted = false;
	end

	
end

-----------------------------------------

function Atr_SList:RemoveItem (itemName)

	local num = #self.items;
	local n;
	
	for n = 1,num do
		if (zc.StringSame (self.items[n], itemName)) then
			table.remove (self.items, n);
			return;
		end
	end

end

-----------------------------------------

function Atr_DisplaySlist ()
	if (gCurrentSList) then
		gCurrentSList:DisplayX ();
	end
end



-----------------------------------------

function sortSlist (x, y)

	return (string.lower(x) < string.lower(y));

end

-----------------------------------------

function Atr_SList:DisplayX ()

	gCurrentSList = self;

	local currentPane = Atr_GetCurrentPane();

	if (not (self.isRecents or self.isSorted)) then
		self.isSorted = true;
		table.sort (self.items, sortSlist);
	end


	local numrows = #self.items;

	local line;							-- 1 through NN of our window to scroll
	local dataOffset;					-- an index into our data calculated from the scroll offset

	FauxScrollFrame_Update (Atr_Hlist_ScrollFrame, numrows, SLITEMS_NUM_LINES, 16);

	for line = 1,SLITEMS_NUM_LINES do

		currentPane.hlistScrollOffset = FauxScrollFrame_GetOffset (Atr_Hlist_ScrollFrame);
		
		dataOffset = line + currentPane.hlistScrollOffset;

		local lineEntry = getglobal ("AuctionatorHEntry"..line);

		lineEntry:SetID(dataOffset);

		local slItem = self.items[dataOffset];
		
		if (dataOffset <= numrows and slItem) then

			local lineEntry_text = getglobal("AuctionatorHEntry"..line.."_EntryText");

			lineEntry_text:SetText		(Atr_AbbrevItemName (slItem));
			lineEntry_text:SetTextColor	(.6,.6,.6);

			if (currentPane.activeSearch.origSearchText ~= "" and zc.StringSame (slItem , currentPane.activeSearch.origSearchText)) then
				lineEntry:SetButtonState ("PUSHED", true);
			elseif (currentPane.activeSearch.searchText == "" and zc.StringSame (slItem , Atr_Search_Box:GetText())) then
				lineEntry:SetButtonState ("PUSHED", true);
			else
				lineEntry:SetButtonState ("NORMAL", false);
			end

			lineEntry:Show();
		else
			lineEntry:Hide();
		end
	end


end

-----------------------------------------

function Atr_SList:FindItemIndex (itemName)

	local num = #self.items;
	local n;
	
	for n = 1,num do
		if (zc.StringSame (itemName, self.items[n])) then
			return n;
		end
	end
	
	return 0;

end

-----------------------------------------

function Atr_SList:IsItemOnList (itemName)

	return (self:FindItemIndex(itemName) > 0);
	
end

-----------------------------------------

function Atr_Search_Onclick ()

	local currentPane = Atr_GetCurrentPane();

	local searchText = Atr_Search_Box:GetText();

	Atr_Search_Button:Disable();
	Atr_Adv_Search_Button:Disable();
	Atr_Buy1_Button:Disable();
	Atr_AddToSListButton:Disable();
	Atr_RemFromSListButton:Disable();
	
	Atr_ClearAll();
	
	currentPane:DoSearch (searchText);

	Atr_Process_Historydata ();
end

-----------------------------------------

function Atr_Shop_OnFinishScan ()
	
	local currentPane = Atr_GetCurrentPane();

	local searchText = currentPane.activeSearch.origSearchText;

	Atr_Search_Box:SetText (searchText);
	
	local recentsList = AUCTIONATOR_SHOPPING_LISTS[1];
	if (recentsList) then

		local isRecentsShown = (gCurrentSList == recentsList);
		
		local n = recentsList:FindItemIndex(searchText);

		if (n > 14 or (not isRecentsShown and n > 0)) then
			table.remove (recentsList.items, n);
		end
		
		n = recentsList:FindItemIndex(searchText);
		
		if (n == 0) then
			recentsList:AddItem (searchText);
		end
		
		if (isRecentsShown) then
			FauxScrollFrame_SetOffset (Atr_Hlist_ScrollFrame, 0);
		end
		
	end

	if (#currentPane.activeScan.sortedData > 0) then
		currentPane.currIndex = 1;
	end

	currentPane.UINeedsUpdate = true;
	
	Atr_Search_Button:Enable();
	Atr_Adv_Search_Button:Enable();
end


-----------------------------------------

function Atr_DropDownSL_OnLoad (self)
	UIDropDownMenu_Initialize (self, Atr_DropDownSL_Initialize);
	UIDropDownMenu_SetSelectedValue (Atr_DropDownSL, 1);
	Atr_DropDownSL:Show();
end

-----------------------------------------

function Atr_DropDownSL_Initialize()

	local info = UIDropDownMenu_CreateInfo();

	local num = #AUCTIONATOR_SHOPPING_LISTS;
	local x;
	
	for x = 1,num do
	
		local slist = AUCTIONATOR_SHOPPING_LISTS[x];
		
		info.text = slist.name;
		info.value = x;
		info.func = Atr_DropDownSL_OnClick;
		info.checked = nil;
		info.owner = this:GetParent();

		UIDropDownMenu_AddButton(info);

	end

end

-----------------------------------------

function Atr_DropDownSL_OnClick(self)
	
	UIDropDownMenu_SetSelectedValue (self.owner, self.value);
	
	gCurrentSList = AUCTIONATOR_SHOPPING_LISTS[self.value];
	
	Atr_SetUINeedsUpdate();

end

-----------------------------------------

function Atr_SEntryOnClick ()

	local line			= this;
	local entryIndex	= line:GetID();

	local itemName = gCurrentSList.items[entryIndex];
	
	Atr_Search_Box:SetText (itemName);

	if (IsAltKeyDown()) then
		Atr_GetCurrentPane():ClearSearch();
		Atr_RemFromSListOnClick();
	else
		Atr_Search_Onclick ();
	end
	
	Atr_Shop_UpdateUI();

--	gCurrentSList:DisplayX();		-- for the highlight
end



-----------------------------------------

local function FinishCreateNewSList(text)

	local slist = Atr_SList.create(text);

	local num = #AUCTIONATOR_SHOPPING_LISTS;
	local n;
	
	for n = 1,num do
		if (AUCTIONATOR_SHOPPING_LISTS[n] == slist) then
			UIDropDownMenu_SetSelectedValue(Atr_DropDownSL, n);
			UIDropDownMenu_SetText (Atr_DropDownSL, text);	-- needed to fix bug in UIDropDownMenu
			slist:DisplayX();
			Atr_SetUINeedsUpdate();
			break;
		end
	end
	

end

-----------------------------------------

StaticPopupDialogs["ATR_NEW_SHOPPING_LIST"] = {
	text = "",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 32,
	OnAccept = function(self)
		local text = self.editBox:GetText();
		FinishCreateNewSList (text);
	end,
	EditBoxOnEnterPressed = function(self)
		local text = self:GetParent().editBox:GetText();
		FinishCreateNewSList (text);
		self:GetParent():Hide();
	end,
	OnShow = function(self)
		self.editBox:SetText("");
		self.editBox:SetFocus();
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};

-----------------------------------------

StaticPopupDialogs["ATR_DEL_SHOPPING_LIST"] = {
	text = "",
	button1 = YES,
	button2 = NO,
	OnAccept = function(self)
		local x;
		for x = 1,#AUCTIONATOR_SHOPPING_LISTS do
			if (AUCTIONATOR_SHOPPING_LISTS[x] == gCurrentSList) then
				table.remove (AUCTIONATOR_SHOPPING_LISTS, x);
				gCurrentSList = AUCTIONATOR_SHOPPING_LISTS[1];
				UIDropDownMenu_SetSelectedValue(Atr_DropDownSL, 1);
				UIDropDownMenu_SetText (Atr_DropDownSL, gCurrentSList.name);	-- needed to fix bug in UIDropDownMenu
				Atr_SetUINeedsUpdate();
				return;
			end
		end
	end,
	OnShow = function(self)
		local s = string.format (ZT("Really delete the shopping list %s ?"), ": \n\n"..gCurrentSList.name);
		
		self.text:SetText("\n"..s.."\n\n");
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
};

-----------------------------------------

function Atr_NewSlist_OnClick ()

	StaticPopupDialogs["ATR_NEW_SHOPPING_LIST"].text = ZT("Name for your new shopping list");

	StaticPopup_Show("ATR_NEW_SHOPPING_LIST");
	
end

-----------------------------------------

function Atr_DelSList_OnClick ()

	StaticPopup_Show("ATR_DEL_SHOPPING_LIST");
	
end



-----------------------------------------

function Atr_AddToSListOnClick ()

	local currentPane = Atr_GetCurrentPane();

	if (gCurrentSList) then
		if (#gCurrentSList.items >= 50) then
			Atr_Error_Text:SetText (string.format (ZT("You may have no more than\n\n%d items on a shopping list."), 50));
			Atr_Error_Frame.withMask = 1;
			Atr_Error_Frame:Show ();
		else		
			gCurrentSList:AddItem (Atr_Search_Box:GetText());
			Atr_SetUINeedsUpdate();
		end
	end

end

-----------------------------------------

function Atr_RemFromSListOnClick ()

	local currentPane = Atr_GetCurrentPane();

	if (gCurrentSList) then
		gCurrentSList:RemoveItem (Atr_Search_Box:GetText());
		Atr_SetUINeedsUpdate();

	end

end


-----------------------------------------

function Atr_Shop_UpdateUI ()

	local currentPane = Atr_GetCurrentPane();

	Atr_AddToSListButton:Disable();
	Atr_RemFromSListButton:Disable();
	Atr_DelSListButton:Disable();
	
	if (gCurrentSList == nil) then
		gCurrentSList = AUCTIONATOR_SHOPPING_LISTS[1];
	end

	if (gCurrentSList) then
		gCurrentSList:DisplayX ();
	
		local iName = Atr_Search_Box:GetText();

		if (gCurrentSList:IsItemOnList (iName)) then
			Atr_RemFromSListButton:Enable();
		elseif (iName ~= "" and iName ~= nil and gCurrentSList ~= AUCTIONATOR_SHOPPING_LISTS[1]) then		-- hack
			Atr_AddToSListButton:Enable();
		end
		
		if (gCurrentSList ~= AUCTIONATOR_SHOPPING_LISTS[1]) then
			Atr_DelSListButton:Enable();
		end
		
	end
	
	if (currentPane.activeSearch:NumScans() > 1 and not currentPane:IsScanEmpty()) then
		Atr_Back_Button:Show();
	else
		Atr_Back_Button:Hide();
	end
	
end


-----------------------------------------

function Atr_Adv_Search_Onclick ()

	local searchText = Atr_Search_Box:GetText();

	Atr_Adv_Search_Dialog:Show();

	if (Atr_IsCompoundSearch (searchText)) then
		local queryString, itemClass, itemSubclass, minLevel, maxLevel = Atr_ParseCompoundSearch (searchText);
		
		Atr_AS_Searchtext:SetText (queryString);
		
		UIDropDownMenu_SetSelectedValue (Atr_ASDD_Class, itemClass);
		Atr_ASDD_UpdateSubclassMenu();
		UIDropDownMenu_SetSelectedValue (Atr_ASDD_Subclass, itemSubclass);

		if (minLevel == nil) then minLevel = ""; end
		if (maxLevel == nil) then maxLevel = ""; end
		
		Atr_AS_Minlevel:SetText (minLevel);
		Atr_AS_Maxlevel:SetText (maxLevel);

	else
		Atr_AS_Searchtext:SetText (searchText);
	end


end

-----------------------------------------


function Atr_ASDD_Class_OnLoad (self)

	UIDropDownMenu_Initialize(self, Atr_ASDD_Class_Initialize);
	UIDropDownMenu_SetSelectedValue(Atr_ASDD_Class, 0);
	Atr_ASDD_Class:Show();
end

-----------------------------------------

function Atr_ASDD_Class_Initialize (self)

	local itemClasses = Atr_GetAuctionClasses();
	local n;
	
	Atr_Dropdown_AddPick (Atr_ASDD_Subclass, "-------", 0);

	if (#itemClasses > 0) then
		local text;
		for n, text in pairs(itemClasses) do
			Atr_Dropdown_AddPick (self, text, n, Atr_ASDD_Class_OnClick);
		end
	end
	
end

-----------------------------------------

function Atr_ASDD_Class_OnClick (info, frame, arg2, checked)

	UIDropDownMenu_SetSelectedValue(frame, info.value);

	Atr_ASDD_UpdateSubclassMenu();

end

-----------------------------------------

function Atr_ASDD_UpdateSubclassMenu ()

	Atr_ASDD_Subclass:Hide();
	Atr_ASDD_Subclass_Initialize (Atr_ASDD_Subclass);
	Atr_ASDD_Subclass:Show();

end

-----------------------------------------


function Atr_ASDD_Subclass_OnLoad (self)

	UIDropDownMenu_Initialize (self, Atr_ASDD_Subclass_Initialize);
	UIDropDownMenu_SetSelectedValue (Atr_ASDD_Subclass, 0);
	Atr_ASDD_Subclass:Show();

end


-----------------------------------------

function Atr_ASDD_Subclass_Initialize (self)

	local itemClass = UIDropDownMenu_GetSelectedValue (Atr_ASDD_Class);

	Atr_Dropdown_AddPick (Atr_ASDD_Subclass, "-------", 0);

	if (itemClass) then

		local itemSubclasses = Atr_GetAuctionSubclasses(itemClass);
		local n;
		
		if (#itemSubclasses > 0) then
			local text;
			for n, text in pairs(itemSubclasses) do

				Atr_Dropdown_AddPick (Atr_ASDD_Subclass, text, n);
			end
		end
	end
	
end


-----------------------------------------

function Atr_Adv_Search_Reset()

	Atr_AS_Searchtext:SetText ("");
	
	UIDropDownMenu_SetSelectedValue (Atr_ASDD_Class, 0);
	Atr_ASDD_UpdateSubclassMenu();
	UIDropDownMenu_SetSelectedValue (Atr_ASDD_Subclass, 0);

	Atr_AS_Minlevel:SetText ("");
	Atr_AS_Maxlevel:SetText ("");
end

-----------------------------------------

function Atr_Adv_Search_Do()

	local itemClass		= UIDropDownMenu_GetSelectedValue (Atr_ASDD_Class);
	local itemSublass	= UIDropDownMenu_GetSelectedValue (Atr_ASDD_Subclass);

	local itemClassList		= Atr_GetAuctionClasses();
	local itemSubclassList	= Atr_GetAuctionSubclasses(itemClass);

	
	local searchText = itemClassList[itemClass];
	
	if (itemSublass > 0) then
		searchText = searchText.."/"..itemSubclassList[itemSublass];
	end
	
	local minLevel	= Atr_AS_Minlevel:GetNumber ();
	local maxLevel	= Atr_AS_Maxlevel:GetNumber ();
	local text		= Atr_AS_Searchtext:GetText();

	if (maxLevel > 0 and minLevel == 0) then
		minLevel = 1;
	end
	
	if (minLevel > 0)	then	searchText = searchText.."/"..minLevel;		end
	if (maxLevel > 0)	then	searchText = searchText.."/"..maxLevel;		end
	if (text ~= "")		then	searchText = searchText.."/"..text;			end
	
	Atr_Search_Box:SetText(searchText);

	Atr_Search_Onclick();

	Atr_Adv_Search_Dialog:Hide();

end




local addonName, addonTable = ...; 
local zc = addonTable.zc;

-----------------------------------------

-- item data from the armory

local gAtr_MI = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAICAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAABCCAAAAAAAAAEAABCAAAAAAAAAAAAAAAEAAABAEAEAEAAAEAEFBAEAAAAAEAAAEAAAECCGCAACCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAAAADCAAAAAAAEAAAEAAAAAAAAAAAABCBCDCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGCHCICHCAAAAAABCAAAAAABCBCAAAAAAAABCBCAAAEAAAABCICAAABAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABAAGCECECDCFCFCFCFCECGCBBECAAAAAAAAAAAABCAAAAAAAEBCCCAACBAEBCAABCAAAAAEAECCAABCAAAAAAAAAAAAAAAAAAAAAEBCAACCCCAEAEAAABAABCAEAAAAAAAAAAAAAAAAAAAAAAAAECBCECECAEAEGCAAHCGCJCAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAABBBABABAAAEAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBCCCAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADBAAAAAAAABCAAAAAAAAAAABAAAEAEBBABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABCBBBAAABABAAABAAAAAAAAAAAAICGCAAABBBABAAAAAAAAAAAAAAAAABABAAAAAAABAABCBCABAAAAAAAAAAAAAAAAAAAAAAHCFCAAAAECAEAAAABCAAAABCBCDCAABCBCBCAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAEAEAAAAAEAEABICCBECAAAAAAAABBAAAABBAABBCBAAAAAAECAADBAEAEAAAABCAAAAAAAABBAEAEAABCDCAABCBCAABBBBBBAABBABAAAEBBAAAAAABCHCAABBBCBBAAAAABAAAAAEAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAACCAAAEAABCAAAAAEABABAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEABABAAAAABBCAAAAAABCAAAABCAAAAAAAAAAAAAAAAAAFBBCBCAEAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAABBAAAAAABCAAAAICAAAABCGCBCBBAAAEAAAECCBCAABCBCBCBCBCBCAAAAECAAAEAABCAAAAAABCAAAAAAAAAAABBBBCBCBCBCAABCAADCBCGBBCAACCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAAFCECECAEAAAAAAAEAAAAAAAEAAAAAAAAABAABCAAAAAAAAAAAAAACBAAAAAAAAAAAAAAAAAABBAAAABCBBAAAAAAAABBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAEAAAAAAECAAFCAAAAHCGCAAAAAAAAFCAAAAAAAAAAAAAAAAAAAAFCFCAAAAAAAAAAAAAAAAAAAAAAAEAAGCFCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAECAAAAAAAAFCAAAAAAAAAAAAAAAAAAAAAAAAGCECECFCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFCFCFCECCCFCAAGCHCFCAAAAAAECCCJCABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABCAAAAAAAAAEAAAABCBCBCBCBCBCAEAABCBCBCBCBBBCAEAAAEAEBCBCBCAEAAAAAAAABCAAAAAACCAEAABCBCAAAAABAAAAAAAAAAAEAAABAEABICBCCCCCAACCGCFCFCFCAAAAAAFCAEECAAECDCECECGCAAECDCDCAADBAAAAAAAEAEAEAEAEAAAACCAACCCCCCCCCCCCAABCBCAAAAAAAAAAAAAAAAAAAAEBBBBCBCBBBBAACCGCBBBBDBDBAABCABABAAAAAAAAAAAAAAAAAACCBCAAAAAAAAAAAAAAAAAAAAAAAACCBCBBBCAACCBCBCDCAAABAACCAAAABCBCBBAAAAAAAAAAAAAAAACCICGCAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAABCAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAEAEHCFCABBCBCBCBBAAAAABABAABCAAAAAAAAAAAAAAAAAAAAABAEAEAAAAAAAAAABCABAAAAAAAAAAAAAABCBCBCAAAAAAAAAAAAAAAAAAAAAAAABBAAAAAAAAAEABABCCCCAAAABBEBBCCCCCBCBCABABAEABBCAAJCICICICAAAAABAEAAAEAABCAABCAAAAAAAAAAECBBCCBCBCBCAAAAAABCAABCBCAAECDCDCAACBBCAABCBCAAAAAAAAAAAAGCBCAAAAAAAAAAAADCBCAAAAAAAAAAAABCBCBCBCBCBCAABCBCBCBCAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAACBAAABAECCAAAAAAAAAAAAAAAAAAAAAEAEABAEGCDCCCBCAABCAAABBCAAAAAAAAAABCAABCAABCBCAABCABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAAAEAEAEAAAAAAAAAAAAAAAEECECECFCFCAEAAAAAEAEAAAABCAAAEAAAEAEAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAEABABBCAAAEAEAAAAAAAEAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAABABAAAABBAAAEAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAEAEAAAAAAAAAAAEAEDCAEAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAEAAAAAAAEAAAAAAAAAAABAEAAAEAAAACCJCFCAAAADBAEBCABAAAAAAAAAAAAFCDBBBBBCCGBBCBCBCHCFCAAAAAEAEAEAEAEAEAEAAAAAEAAABAAAAAAAEAAAAAEAABCBCBCAAAAAABCAEAEBCAEAEAAAAAAAABCBCBCBCBCCCCCAAAEAAABAEAEDCCCBCAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAABCABAACBBBBBABCBBBBBAEBBBCDCCBAAHCDBDBAAAAAAAAAAAAAAAEAEAAAAAAAAAAAADBAAAAAAAAAAAEAACBCBDBDBAAAAAAAABBBBECAADBDBECAEBCBCAAAABCBCAAAABCBCAAAABCBCAAAABCBCAABCBCBCAABCBCBCBCBCBCBCBCBCBCBCBCBCAAAAAAAAAAAEAEBCAAAAAAAAAAAAAAAAAAAAECAAAAAEAAAEAEBCBCDCBCBCAAAAAAAAAAAAAAAAAAAAAAAAAEBCDCAABCBCDCDCAAAACCAACCCCCCAAAAAACCAACCCCBCBCAAAAAAAAAAAABCBCCCAACCABABCCCCBCHCBCAACBBBAEAEAEAEAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBAAAAAAAAAAAAAEAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABBBAEAEAEABAABBBBAEAEAAAEBBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBCDCCCFCBCAAAACBBCBCBCBCBCDCBCBCAACCBCCCCCBCCCAAGCDBCCBCCCAAAAAAABBBAEAAAAAABCBCAAAAAABCCBBCCBBCAAAAAEBBAEAEAEAAAAAAAAAAAAAAAAAAAEAAAEABAEAEAEAEAEAEAEAAAAAAAAAAAEAEAEABABABABAAABABABABABABAAAAAAAABCBCAAAAAABCBCAAAABCBCAAAAAAAAAEAAAAAAAABCAAAABCBCBCBCBCBCAAAABCBCBCAAABAEAAAAAAAAAACBAAAAAAAAAABCAAAAAAAAAACCAEAAAEAADCABABBBECAAAEAEAEAAAAABAEAEAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACCAAAAAAAAAEAAAABBAAAAAAAAAEAEAEAEAEAAAEAEBCCCBCCCCCAEAAAAAAAAAAAAAEAAAAAABCFCBBAAAAABABAAABAAABBBAAABABABABBBABAABBBBBBBBABABABABBBBBAAAEBBBBABAAAAAAAEAEAAAABCBCBCBCJCAEAEAAAABCBCCCCCCCCCAABCBCBCBCBCCCCBAAAEAEAEAEAEAAAAAEAAAAAEAEAAAEAEAEBBAAAAAEAEAEAEAEAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAEAEBBCBAABBBBDBCBCBBCAEBBCBBBAACCBBBCBBABABAAAAAABBAAAABBBBABAABBBBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAABABAAAAAAAAAAAAAAAEAEAEAEAEAEAEAAAEAEAEAAAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAAAAAAAABCAABCAAAAAABCBCBCBCBCCCAEAEAEAEAAAAAAAAAAAAAAABAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAEAEAEAEAEAEAAAAAAAAAAAAAAAEAAAAAEAAABAAAEAAAEAAAAAAAEAEAEAEAECCAEAEAAAAAAAAAAAAAAAAAAAAABBBAAAAAAAABBBBBCBBCBCBAEAAAACBCBCBCBCBBBDBDBDBAAAADBDBDBDBAAEBEBEBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADBAAAAAAAAAAAAAAAAAAAAABABDCDCECAEAEDCDCDCDCECECECECBCDCDCDCDCECECECECAAAAAAAAAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAAEAEAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEABAAAEAEBCAAAEAEAEAEAEAEAEAEAEAEAAAEAEAEAEAEAEAEAEAEAEAEAEAAAAAAAEAAAEAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAEAEAEAAAAAAAAAEDCCCCCECDCDCECECECECFCFCFCDCCCDCCCDCAEDCDCAAECFCECECFCFCFCCCECDCECECGCFCDCCCDCECDCDCDCECECFCAAGCFCGCAEEBFCGCGCGCGCAAAAAEAAAAAAAAAAAAAAAAAEAEAEAEEBEBFBFBFBFBFBFBEBFBFBGBFBEBDBEBEBEBFBDBEBFBFBGBFBEBEBGBDBFBFBFBEBDBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACCEBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABCAAAABCBCBCAABCCCCCBCBCCCCCCCCCDCDCDCDCECECAAECAAECAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABCAAAAAAAAAAAAAAAAAAAAAAAABCAAAAAABCBCBCBCBCBCBCBCBCBCBCCCCCBCCCDCDCCCDCECECECECAABCAAAAAAAAAAAAAAAAAAAAAABCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABCAAAAAAAAAABCBCAAAABCBCAAAAAAAAAACCAACAAACCAACCAAAAAAAAAAAAAAECAAAAECACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEFBAAAEABBCAEBCBCCCBCAEAEAAEBBCBCCCCCCCCCAEAAAAAECCDCDCAAAEAAAAAADCDCDCDCAEAEAEAEAAAAAEAEDCAADCDCFCAAAAAAAEAEAEAEAAAEAEAEAEAEAEAEAEAEAAAAAAAAAAAAAEAEDBDBAEFBFBEBAEEBAEAEAEAEAEAEAEAEAEAEAEAAAAAEAEAEAEAEAEAEAEAECBDBAAAAAAAAAAAAAAEBAAEBABEBFBGBGBAEAAAAAAAAAAAAAAAAAABCBCAABCAABCBCBCBCBCBCAAAAAABCBCBCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAEAAAEABABAEAEAAAAAAAAAEAEAAAAAAAEAEAEAEAEAEAAAAAAAEAAAAAAAAAEAEAADBAEAEAEAEAEAEAEAAFBFBAEAAAAAAAAAABCCCAAAAAAAAAAAAAAAAAAAAAAAAAAAABCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABCICBCAABCAABCAEAEABCCBCCCBCBCBCCCCCCCCCCCDCDCDCDCDCDCDCCCCCECECECAAECAAECECGCFCFCFCFCFCAEAEEBAEGBEBEBEBAAAAAAAAAEAEAEAAAEAAAAAEAEAAAAAABCAABCBCBCBCAEAEBCAAAAAAAAAABCBCAAAABCBCAEAABCBCAABCBCBCAABCBCBCBCBCBCBCBCBCAEAEAEAEAEAEAEAEAEECAAAAAAAAAABCBCBCAEBCBCBCAECCCCCCCCCCCCCCCCCCCCAECCCCCCCCAAABAEAAABABABAEAEAEAEAEABAAAAABAAAAAAAAAEAABCAEAEAEAAAEAAAAAEAEAEAAAAAAAAAAAAAAAAAAABAAAEAAAAAEAEAEAAAEAEAEAEAEAEAEAEAEAAAAAAAAABAEAEABABABBBABABAAABABABABABAEABABABABABABABABAAABABAAABABABAAABABABABBBABABABABABABABBBBBBCAAAAABABABAAAAABABAAAAABABABBBABAAABABABABBBABABBBEBEBFBEBFBEBAAABFBFBAAAEFBAAGBGBAAAEAAAAAEAAAABCCCCCCCCCDCAADCAEDCAAECAAECAEAAAAAADBAEAEAEAAAEAEAEAAAEAEAEGCGCAEAAAAAAAAAAAAAAAEAAAEAAAAAAAAAAAAAAAAAAAEAAAAAAAEAEAEAAAEABABAEAEAEAEAEAAAEAEBCAABCAEAEAEAAAEAEAEECAEAAAAAAAEAEAEAEABAEAAAAABABABAAAEAEAEABAEAEABABAEAAAAAAAAAAAABCBCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAEAEAEAEAAAAAAAAABABABABABDCDCBCBCAEAEAEBBAEAEAEBBBBBBBBBBBBBBBBBBBBBBBBAEAEAAAABCAAAAAAAABCDCDCFCFCAEAEAEAEAEAAAAAAAAAAAAAAAAAAAAABAEAEABAAAAAAAABBBBBBBBCBDCCBEBEBEBCBAEBBEBBBBCDCECAAAAAAAAAAAAAAAAHCJCAAAAAEAEAEAECBBBAAAAAABBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBAAAABBAAAAAABBAAAABBBBBBBBBBBBBBBBBBBBAABBBBCBBBBBBBBBBBBBAAAAAAABAAAEABAEBBAEAEBBBBAABBBBBBBBAAAEAAAABBABAAAECBCBCBAAAEAEAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAAAEAEABAEAEAEAEABABABABABABABABAAAAAAAABBABAAAAAAAAABAEAEAEAEAEAEAAAAABBBABBCBCAEBCBCAAAAAAAAAAAAAAAAAAAAAEAAAAAEAAAEBBBBAEAAAAAAAAAAAAAAAAAAAEAEABABBBAEAEAEAEAEAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAAAAAAAEAAAAAEAEAAAAAAAAAAAAAAAAAAAAAEAAAAAEAAAAAAAAABABAAAAAAAAAEAEAEAAAAAAAAAAAAAAAAAAAAAAAEAEAEAEAEAEAEBCCCBCAAAEAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAABABABAEAEAEAEABBBAEABABABABABAEABABAAAAAAAAAAAAAABBABABAAECBBBBBBABBBDBBBGCBBABAEAEAEBBAEECAABBBBAEBBBBAAAAAAAAAAAAAAAEAEAAAAAAAAAAAEAEAAAAAAAAAAAAAAAAABABAAAAAEAAAAAAAAAEABAAAAABAEAAAAAAAAAAAEAAAAAAAAAAAEAAAAAAAAAEAEAAAEAEAEABABABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAEAEAEABAEECAAAAECECACAAAAAABCBCBCBCCCDCDCDCECBBAAAAAAABAAAAAAAACCAAABABCCAAAAAAAAAAABABABABBCBCDCECAAAAAAAAAAAAAEAAAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEBBDBCBDBABCBCBDCDBBBBBAAAEAEAEAEAAAAAEAEAEAAAEAEAEAEAEAAAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAAAAAAAAAEAEAEABABAEAEAEAEAEAAAAABABAAAAAEABAAAEAEAEAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAEABABABAEBBBBAEAEAEAEAAAEABAEAAAAAAAAAABCAEAEBCDCDCDCECECBCBCBCBBCCAAAAAABCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAECAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABABABABAEAEAEAEAAAEABAEAEAEAEAAABAEABAEAEAEAEAEBBBBAEBBAAAEAAAEBBCBBBBBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAEAEABABABACAEABABAEBCBCAEAAAAAEABBBBBBBABAEBBAAAEDBBCABBCCCBCCCAAAAAADCBCAAAAAAAAAAAAAEAABCBBAAAAABAACBAAAADBAAAABBAAAAAAAAAAAAAAAAAAAAAABCBCBCBCBCBCAAAEAEAEAEAEAEAEAEAEAAAAAAAEAEAEAAAAAABCBCABBCBCBCBCAAAAAAAAAAAAAAAAAAAAAAAEDBAEAEAEAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAECBCCAAAACBCBCBCBAABBCBAAAAECAAAAAAECBCBCAACBBCBCAAABCBBBAAAAAAAAAAAAAAAABCAAAAAAAAAAAAAAAAAABCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABCBCBCBCBCBCAAAACCCCCCDCAAAACBCCCCCCDCCCCCCCDCAAECDCDCECDCDCDCDCDCFCECECCBFCECECECECECECECFCFCFCFCGCFCFCGCFCFCFCAAAEABAAAAAAGCAEAEAEAAAAABBBBBBBAAAAAAAAAAAAAAAAAABBBBCBAECBAEBBBCBCBCBBAAAABBBBAAAAAABBBBAEBBBBBBAAAAAAAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAABBBBBBBBAAAAAAAAAABCBCAAAAAAAAAAAAAAAAAAAAAAAAAAAABCBCAAAABCAAAAAEAEBCBCBCBCBCBCBCBCAABCBCBCBCAABCBCBCBCBCAABCBCBCBCBCBCBCBCBCBCAABCBCBCBCBCBCBCBCBCBCBCBCAABCBCBCBCBCBCBCBCAAAACCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCAACCCCDCDCCCCCCCCCCCDCCCAAAAAAAAJCAAAEAEAECBBCBBBBBBBBBBAEABABABAAAAAECBBBAAAAAAAAAAAAAAAAAAAEAEAEAEAEAAAEBBHCAAAAAACBCBBBCBCBBBCBCBAAAAAACBCBCBCBCBAADBDBAAAECBDBDBDBDBDBDBEBEBEBDBDBDBAAAAAAAAAAAAAAAAAAAAAABCAAAAAAABAAAAAAAEAECBEBBBCBFBAAEBFBFBAAEBBCBCEBCCAAAAAADBDBCBCBABEBBBDBDBEBEBDBDBDBCBCBAEAAABABEBAAAAAAAAAAAAAAAAABAEAAAAAAAAAAFBFBABABAAAAAAEBAEAEAEEBAEAAAAFBFBDBEBEBEBEBAAAAEBEBAEAEEBFBFBDBAEEBAAAEAEAEAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBFBFBFBFBAAAAAAAAAAAEAEAEAEAEAEAEAEAEAEAEAEAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAEAEAAAABBAAEBCBCBCBCBCBCBBBBBDBDBDBAEAEAEAEABAAAAAAAAAAAAAAAAAAAEAEAEAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAEDBAAAAAAAAAAAAAAAAAAAAAAAABBBBBBBBBBDBCBCBDBEBEBEBBBBBBBBBBBBBBBBBAAAAAAAEAEAEAEAEAEAEABAEBBAEBBCBCBCBCBAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACCCCCCCCDCDCDCDCEBDCECECDCECECECECFCFCDCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADBDBBCAADCECFCGCAABBBBBBBBAEBBAAAAAAAAAAAEAEAEDBDBAECBCBAEAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABCBCFCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAABBBBAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAEAEAEAEAEAEAAAAAAAAAABCBCBCBCBCBCAAAAAAAAAAAEAEAEAEABAAABBBAAAAAAAAAAAAAAAEAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBBBBBBBDCDCFCAECBCBBBAAAAAAAAAAAAAEDBAEAEAABCCCAAAACCDCDCDCCCDCCCCCAAAAAAAAAAAEDCDCDCDCDCAAAADCDCDCAEECECAAAAAAAAAAAAAAECECAAAEECECAAAAAAAAAAAAAAAAAAAAAAAAAAAADCDCDCDCDCDCDCDCDCCCDCDCDCCCDCDCDCDCDCAAAAAAAAECECECECECECECDCECECECECECABECECECECECECAAAAAAAAAAECECECECECECDCECECECAEECAAAAFCFCFCFCFCFCECFCECFCFCFCFCFCFCECFCFCFCFCFCFCFCFCECECFCFCFCAAAEAEAEAAAAAAAAAABCBBBBBBBBDBDBEBEBEBABGCGCGCGCGCFCGCFCFCGCGCGCGCGCGCGCFCFCGCGCGCGCGCGCGCGCGCFCFCGCAAAAGCAAGCFCGCBCFCECGCBCBCAAAAAAAAAAAAAEAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBBBBCDCFCGCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAEABAEAEAEAEGBAEAEAAAAAAAEAEAADBDBDBEBDBDBDBDBDBDBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADBDBEBEBEBEBEBAEAAFBFBFBFBFBFBFBFBAAFBDCDCDCDCDBAAAEHCAEECAEBBBBAAAAAAAAAAAAFBFBFBFBDBCBDCDCCCECDBECECECECECAAAAAAAAAEAEAEAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAACCDCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAEAAAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEGBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEABAEAAAAAAAADCDADCECECFCFCFCFCFCAEFCFCFCFCFCFCGCGCGCGCGCGCGCGCFCGCAAFCFCFCGCGCGCHCDBEBFBDBEBFBGCAABCCCCCGCHCGCAAECAAAAAAAAAEAAABAAAAAAAAAAAAAAAAAAAAAAAAABABABABABABAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAECABABAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAAABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAEAEAEABABAEAEAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAEBBAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAHCGCGCGCGCGCGCHCGCGCGCGCGCHCFCGCGCGCGCGCHCGCGCGCGCGCHCGCHCGCAEFCGCFCFCFCFCGCFCAAAAAAAAAEAAAAAAAAAAAEECFCECECECECFCFCAAAAAAAAAAAAAAAAAAAAECFCFCAABCAABCAAAACCCCGCCCFCECFCHCGCFCGCFCGCFCGCFCGCFCFCGCFCFCFCGCGCGCGCFCFCGCGCFCGCGCAAAAAAAAAAAAECECECDCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAICHCHCGCHCHCHCICHCHCGCHCGCICGCHCHCHCHCHCICHCHCHCHCHCICHCGCHCICGCGCGCGCGCGCHCJCICICHCICICICJCICICICICICJCHCICICICICICJCICICICICICJCICHCICJCHCHCHCHCICHCICAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEFCGCFCGCGCBCAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAHCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABABABABAAABABABAAAAAAAAAAAAAAAAAAAAABABAAAAAAAEAAAAAEABAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEABAEAEAEAEABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEABAEABAAAAABABAEAEABAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAABAAABABAAAAAAAAAAAAAAAAAAAAABABABABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAEAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABAAAEGBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFBAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAEAEAAABABAAFBAEAEAEAEAEAAABAAAAAAAAABABABABAEAAAAAAAEAAAAAEAAAAAAAAAAAAAAAAAEAAAEAEABAEAEAEAEAEFCFCFCFCFCFCFCFCAAAAAAAAAAAAAEAAAAAAAAAAAAAEAEAAAEAAAAAAAAAAAAAEAAAAAEAEAEAEAEAEAAABAAAEAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFCAAAADBABAEAEFCAAAEAEABAEHBAAAAECAAAAECGBGBECECECECECECFBEBFBEBECECECFBDCECECEBAAFBFBICEBFBDCDCEBFBFBFBFBGBGBGBGBGBAAGBGBECAAFCFCFCFCFCFCDCFCFCFCFCGCFCECAEAEAEAEAEAEAEAAAADBDBDBDBDBDBAADBDBDBDBDBDBEBEBAEEBAEAEAAFCAEGBAEGBGBAEAEGBGBGBGBGBGBGBGCGCGCGCGCCCCCCCCCDBCCDCEBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEDCCCDCGCGCBBBBDBDBEBEBEBFBFBEBAEAAAAAAGBAEAAAEGBAAGBGBCBCBAADBAAAAAAAEAEAEAEAEAEAEAAAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAEAAAEAEAEAEAEAEAEAEAEAAAAAAAAAAABDBAEAEAEAEAEAEAEAEAEBBBBABABBBBBCBCBAEBBDBDBAAAAAAAAAAAAAAAAAEAEAEAEDBEBEBEBFBFBAEAEFBFBFBFBGBFBFBFBGBGBGBGBGBHBHBGBGBGBGBHBHBHBHBGBGBGBGBGBFBAAFBFBFBFBFBGBGBAAAAAAAAAAAAAAAAAAAAAAFBFBFBAAFBHBHBHBHBDBAAAAAAAAAAAAAAAAAAAADBDBAAAAAAFBFBFBFBAAAAAAAAAAAAAAAAAAAAAAECAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAEAAAAAAAAAABCBCBCAAAAAABCAAAABCBCAAAAAAAAAABCBCBCBCBCBCCCBCBCCCCCCCBCBCBCBCBCBCBCBCBCBCBCBCBCBCBCBCCCBCBCBCCCCCCCCCCCCCBCCCCCCCBCCCCCCCCCBCBCBCBCBCBCBCCCBCDCDCCCCCDCDCDCDCCCDCCCDCCCDCDCDCDCDCCCCCDCDCDCDCDCECDCDCDCECECECECECDCECDCECDCECECDCDCECECECDCECDCDCDCECECECECFCECECECFCECECFCFCFCFCECECFCAAECECECECFCFCECECFCECFCECECFCFCFCGCFCFCFCFCFCGCFCGCGCFCFCFCFCFCFCFCGCFCGCFCFCFCFCFCFCFCFCFCFCFCGCGCGCGCGCGCGCHCHCGCHCGCGCGCHCGCGCGCHCGCGCGCGCFCGCGCGCGCGCGCFCFCFCFCFCFCFCFCHCAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFCFCABFCFCFCFCAEAAFCFCFCFCFCAAAAAAAAAAAAFCFCFCFCAEFCGCGCGCGCGCGCGCGCGCGCAAAAAAAAGCGCAAGCFCDBGCAAAABCBCBBAAAAAAAAAAAAAAHCGCGCGCHCHCHCHCHCGCGCHCGCHCGCHCHCHCHCGCHCHCGCGCGCHCHCHCHCGCGCFCFCGCGCGCHCFCICHCICHCHCICICICHCICICICHCHCHCHCICICICAAAAAAAAICICHCICHCICICICHCGCHCGCGCGCHCHCHCJCICJCICJCJCJCJCJCICICJCICICJCJCJCJCJCJCJCICJCJCICJCJCJCJCICHCHCHCICICICHCHCHCHCHCHCICICHCHCICICHCHCHCHCHCICHCHCHCHCHCGCHCHCHCHCHCHCGCGCHCHCGCGCGCGCGCICICICICICJCICJCJCICJCICICICICICJCJCICICICHCICICICICICICHCHCHCHCHCHCHCHCJCJCJCJCJCJCJCJCJCJCJCJCICJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCICICICHCICICICICAEAAAAAACCDCDCAAAAAAAAAAAAAAAACBDBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEECECFBECDCECAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBEBAAAAICICICICJCJCJCICICICICJCICICICICJCJCICICJCJCJCJCJCJCJCJCJCICAAAAAAAAAAAAAABBBCBCBCBCCCAADCAADCDCBBBBBBBCAEAAAAAAABAAAEAAAADCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEABAEABAEAEAEAEAAAAAAAAAAAAABIBABAAAEAEAAFBGBAAAEAEAEAEAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADCFCFCFCGCGCAAGCAAFCAEFCAEAAAAAAAEAAAAFCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAEFBFBABFBAAABAABBABAEAEBCBCAAAEAAAAAAAAAAAAAEAEAEAEECAAABECECECECECABGCACECAAAAECECECECAAAAABGCAEABAAAAAAAAAAAAAEAEAEAEAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAABAEGCGCGCGCGCGCGCHCGCGCHCGCABABBBBBAEAEAEAEAEAAABAAAAAAAEAAAAHBCBDBABABCBBBIBAEAEAEAEABAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAEAEAAABAAHBABABABABAEAEAEAEABIBIBIBAEFBFBFBFBGBGBGBHBHBHBEBFBAEAAAEAEACAEAEAAACFCAEAAFCABGCABAAAAAAAAAAAAAAAAAAAAAEHBHBHBHBHBHBGBGBFBFBHBHBHBABAEAEAEAAAEFBAEEBFBFBFBFBFBEBFBFBFBFBFBFBABFBFBFBFBIBIBHBHBHBHBHBHBHBHBHBAEABABAEAEAEHBHBHBHBHBHBHBHBHBHBHBHBHBHBAAAAAAAAAAAAAAAAAAABAEBBBBAAFBFBAAGBGBIBIBABABABIBABIBIBIBHBAAAAAAHBHBHBHBHBIBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAAAAAAAAAAGBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAEAEAEAEAEAAAAABAAAEAEAEAAABAAGBAEHBCBGBHBHBAEAEAEAAAEABAEAEAEAAAAAEAAAAAAABAEAEAEAAABAEAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAEAAAAAEAEAAAAAAAAAAAEAAAAAAAAAAAAAAABAAABABABABIBIBIBIBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAEAADBAEABAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFBEBAAFBAEAEAEAEAEAAAAAAAAAAAAAAAAAAAAAAAEAEAAAAAEACACACACAAAAAAAAAAAAAAAAAAAAAAHCBCBCDCDCGCGCAEGBGBAEAEAAABAEAAAEAEAEAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAEAEAAAAAAAAAAAAAAAAABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEABAEAEAEAEAEGBAEABAEAAABABAEAEAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGBAEAEAAAAAEABAEAEAEABABABABABAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABABABABAEABABAAAAAAAAAAAAAAAAAAAAAAABAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHCIBICICICHCAEAAAAAAAEABABAEAEAAAAAAAAABHBHBHBHBHBHBHBAAHBHBHBHBHBAAAAAAAAAAAAABABABABABABABABAAAAAAAAAAAAAAAAAAAAAAAAHBAAAAHBAAAAABIBAAAAAAAAAEHBAAHBHBHBAAAAAEAAIBHBHBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHBHBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHBAEAEAEIBAEIBIBIBIBAAAAAAIBAAAAAAAAAAAAABHBIBIBIBHBHBHBHBABABABAAIBAAAAAAAAAAAAAAAAIBIBIBIBIBAAAAAAAAAAAAAAAAAAAAAAAAAAIBIBHBIBIBIBAAAAAAAAAAAAAAAAAAAAAAAAAAAAIBIBAEIBAAIBIBIBIBHBIBAAIBIBIBIBAAIBIBIBIBIBHBABABABABAEAEAEIBAEAEAEAAAEAAHBABHBHBAEAEABAAABABABABABABBBBBBBFBGBFBFBGBGBHBHBHBHBHBHBHBHBHBHBHBIBIBHBIBAAAAAAAAAAIBABDBAAAEABGBGBAAAAAAAAAAAAAAAAAAAAAAAAIBAAIBIBHBHBHBHBHBHBAEHBABHBHBHBHBHBIBIBIBIBIBIBIBIBIBIBIBIBIBIBJBIBBBAAAAAAAAAAAAAAAAHBHBAEABAEABABABABAEAEAAAAAAAAAAAAHBHBHBBCAABCCCCCDCECECFCGCGCHCHCICJCJCBCBCCCCCDCECFCGCHCHCICJCBCBCCCDCECFCGCHBGCHCAAICJCBCBCCCDCECFCFCGCHCICJCJCHBDCECHBFCFCGCHCICJCDCDCECFCGCAAHCICJCAAHBDCECHBFCGCHCICICCCJCHBHBHBBCBCBCHCICICJCIBAEIBIBAAABIBIBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIBIBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHBJBIBIBIBIBIBIBIBIBIBIBIBIBAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIBAAAAAAAAAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAABAAAAAAAAAEAAAAAAAEAEAEAEAAAAAAAEAEHBAAAAAADCDCDCDCECECFCFCGCGCFCFCECECAAAEAEABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAEABAEAAAEAEAEAABBBBAAAAABABAEABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAEABABABAAAAABAAAAAAAEABABABAAABAAAEAEAEJBAEAEAEAAAEAEABAEABABAEAEAAAEAAAAAAAAAAAAAAAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAABAEABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAGCGCAAHCICICAEAEAAICHCHCICICICJCAAICAAHCHCICICHCJCAAAAAAAAAAAAAAAEAEAAAAAAAAAAAEAAABABABABABABAAAAAAABAAABABABABAAHBHBHBHBHBAEAAGBGBGBAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBAAAEAEAAHCHCABAEHCICABABHCAAAAAAAAAAAAHCIBIBIBHCICIBHCHCICHCIBIBHCIBIBABAAAAAAAEABABAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAIBJBABAAAAJBJBJBJBAAJBAAAAAAAAAAAAAAAAAAJBJBIBIBJBAAIBJBICICJCJCJCJCJCJCJCJCJCIBAEAEHCICIBAEICAAAEICICICIBAEJCIBAEJCJCJCAEAAAAAAABABAEAEABIBAEIBABAAAAAAAAAAAAAAABAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABAAABAAAAAAAAAAABAAAAABABABAAAAAAABABABAEJBAEAAAEAAABABAAAAABABAAAEAEAEAEABABABAAAAABAAAEAEABABABAEABABAEAEAAAAAAAAAAAAAAAAAAAAJBABAAAAJBJBAAAAAAAAAAAAHCAEAEAAAEHCAEABHCHBHCICICICAAIBABICIBJCJCAEAAAAAAAAJCHBICHBJCIBJCJCJCAAAAAAICAAAAAAABAEAAAAAAAAABAEAEAEAAAAAAABAAAAAEABAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAABABABABABAAABAEABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAEAEAAAAAEAAAAAEJBAEAEAEAEAEAAAAJBJCJBAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAEABAEJBJBAEJBIBAAAAAAAAJBJBAAABJBJBAAAEAAAAJBAEAAAAAAAAAAIBIBAEAEAEAEAAAAIBAAAAJBJBJBJBJBJBJBJBAAAAAADCBCBCBCBCBCAAAABCBCBCBCAABCBCBCBCAABCAABCAABCBCBCBCJCJCICICICCCJCICHCHCCCCCCCICHCJCCCECGCDCECGCHCJCCCECFCHCJCFCHCCCCCDCFCGCICDCECGCICCCFCGCICDCGCICDCCCAAFCHCICECGCICCCFCHCICAACCDCFCGCHCHCFCAAICFCICHCGCJCGCICAACCJBECGCJCDCHCABDCFCGCJBICAAECCCFCICCCJBCCFCICGCECAAECDCJCDCGCECHCGCJCCCFCJCFCICECHCECHCJCDCGCHCDCGCECICCCFCJCGCICBCDCFCGCABJBJBJBHCECICAAJBAAAAAAAAAAAAAEAEAEABAAAAJBJBJBJBAAIBIBIBIBIBJBAEABAEIBAEIBIBIBABIBIBIBJBJBAEAEAEAEAEAEAEAEAEAEAEAEIBFCAAAAAEIBIBJBJBAEJBABIBIBIBIBAAAAJBJBJBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJBIBBBJBABIBJBABAEIBIBIBIBAAIBJBJBJCIBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIBIBIBIBIBAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEJBJBAAABAAAAAEABABABAAAAABABABABAAABABABABABAAAAAAAAJBAAAAAAJBJBJBAEJBJBAEAEAEJBABAAABABJBJBJBJBAAAAAAAAAAAAJBJBAEIBIBIBIBIBIBABIBIBJBJBJBIBIBJBJBJBJBJBJBJBJBJBIBIBIBJBJBIBIBJBIBIBIBIBAAAAIBIBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAAHBIBHBAAAAAAAAAAAAABABABABAAAAAAAAAAAAAAAAAAAAAAAAIBAAAAABJBABAAJBAAAEABABAAAAAAAAABIBAAABAAAAAAAAAAABJBJBJBJBJBJBJBJBJBJBIBIBAEIBIBIBAAAAAEAAIBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEABABABAAABABABABABAAABABABABABABABABABABABABABABAAAAAEAAAAAAAAAAAAAAAAAEABABABABABABABABABABABABAAABABABABABABABABABABABAAABABAAABABAAABABAAABABABAAAAABABABABABABABABABABAAAAABAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAEAEAAAAHCHCHCAAHCAAAAHCICICICJCHCHCHCICAEABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJBJBAAAAAAAAAAJBAAAAAAAAAAJBJBJBJBJBJBJBJBIBIBJBIBIBIBJBJBJBJBJBJBAAAAAAAAAAAAAAAAAAAAAAAAJBJBJBAAJBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJBJBJBBCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHCHCHCICAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABCBCAAAABCAABCBCAAAAHCHCAAHCICAAJCHCICBCAAICJCBCBCAAAABCAABCBCBCBCBCBCBCAABCICBCJCBCHCBCHCAAICICICJCJCHCHCHCICBBJCBBBBBBBBBBJBJBJBAAACAACCBCBCBCBCCCBCBCBCBCBCAAAABCBCBCBCBCCCCCDCBCCCCCCCCCCCCCCCCCCCDCDCCCDCDCCCCCDCCCDCDCDCDCECDCECDCDCECECDCDCDCDCECDCECFCECECDCECDCECECECFCECAAFCECFCECECECFCECECGCFCECECFCFCFCGCFCFCFCFCGCFCECFCFCGCFCAAFCFCGCFCFCFCGCGCHCGCHCGCGCFCGCGCGCHCHCGCHCGCGCGCHCGCHCICGCGCICICHCHCGCGCHCHCHCHCICICHCHCHCICICHCICICICJCICICHCJCHCICICICJCJCICICHCJCICICJCJCICJCJCJCICJCJCJCJCJCJCAEAEJBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABCBCBCBCAABCBCBCCCBCBCBCBCCCCCCCCCAEAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEDCDCDCCCDCCCDCDCDCCCECDCDCECDCECECDCECDCFCECECECFCECECFCFCECGCFCFCFCFCFCGCGCFCGCHCGCGCGCGCGCGCHCHCGCHCHCICHCHCHCICHCICJCICICICJCJCJCJCJCICAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAABJBAAAAAAAAAAABAAAAAAAAAAAAAAAAJBJBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJBAEAAJBAAAAJBAAAAIBAAAAAAAAJCJBJBJBAEJBAEJBAEJBAEAEJBFCGCGCHCJCJCJCAAJCJCBCBCBCBCBCBCBCBCBCBCBCCCBCBCCCCCAAIBJBCCDCCCDCCCDCDCDCAADCECECDCECECDCECECECAAECFCECFCECFCFCFCFCECDCAAAEJBJBAEJBJBJBABAAAEJBJBJBJBJBAEJBAAAEJBAAJBJBJBAAAAJBJBJBAAJBJBAAAAAEAEABABABABABABFCGCFCGCFCGCGCGCGCGCHCGCHCGCHCHCHCHCICICHCHCHCICICICICAEJCJCICICICJCJCJCJCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABCBCBCBCBCBCAABCBCAAAAAAAAAAAAAAAAAAAAAABCBCCCBCBCBCBCCCCCDCCCDCCCCCCCDCDCDCECDCECDCDCECECECFCFCECECECECFCFCFCFCFCGCGCFCFCGCGCGCGCGCGCHCHCGCGCGCGCHCHCHCICICICHCHCHCICICICHCICJCICJCJCICJCJCJCJCAAAAAAFCAAAAAAFCFCFCFCFCFCFCFCFCFCGCAAAAFCFCGCFCGCGCHCAAGCGCGCHCHCHCHCGCICHCHCHCICICICHCJCICICICJCJCJCICAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABFCECECECFCECFCFCECGCFCFCGCGCFCFCGCGCGCGCHCHCGCGCHCHCGCHCGCICICHCHCHCHCICJCICICICICJCICICGCFCFCFCFCFCFCFCGCHCGCGCGCGCGCHCGCFCHCICHCHCHCHCHCICGCJCICHCICICICICICHCJCJCICJCJCJCJCJCICAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAABCBCBCBCAABCAABCBCBCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEHCHCJCICICICICICICHCJCICHCICICICHCICICHCICICHCJCICICHCICHCHCICHCHCHCICICJCICHCHCJCICICICAAJCHCHCICICICJCAAAAAAAAAAAEAEEBEBEBEBEBBBBCBCBCBCBCBCCCBCCCICCCCCBCCCBCCCCCCCDCDCDCDCCCDCECCCDCDCICDCDCJCDCDCECECECDCDCECECECFCECECECFCFCECFCECFCFCFCGCFCFCGCFCFCHCGCGCGCGCHCGCGCGCICHCHCHCGCHCICHCHCICICHCICICJCJCJCABABABABABAABBBBBBBBBBBBAEAEBCBCCCECECFCHCHCICICJCJCBCBCBCDCECGCHCHCBCDCDCECECGCHCHCICJCJCCCCCECFCGCJCJCBCCCDCFCGCHCHCICICJCJCBCECECGCGCICICJCJCBCBCGCICICJCHCHCICABICHCHCICICJCCCDCDCFCJCJCABHCABABHCHCJCAABCAAAAAAAABCBCBCBCBCBCBCBCBCBCAAAEAAAAAAAAAAAAAAECGCICICAAAAAEBCBCBCCCBCCCBBCCCCCCDCCCCCCCCCDCDCDCCCCCDCDCCCDCECDCDCECDCDCFCECECECFCECECECECECFCFCFCFCGCFCFCGCFCGCGCGCHCFCGCGCGCGCGCHCHCICICGCHCHCHCBBBBABBBABABABBBBBBBBBAAAAAAAAJBAAJBAAAAAAAAJBAAAAJBAAAABBHCICHCICICICICICJCJCJCICJCJCJCJCJCJCBBBBBBAAAEAEBBBBBBBBBBAEEBEBCBCBCBAABBBBBBCBCBCBDBCBCBCBCBAAAAAAAAAABCAABCAAAAAAAAAABCBCBCBCBCAABCBCBCBCBCAABCBCBCBCBCBCBCBCAABCBCBCBCBCBCBCBCCCBCCCBCCCBCCCCCCCCCDCCCBCCCCCCCDCCCCCDCDCCCDCCCCCCCDCDCDCDCDCCCECCCDCDCDCDCECDCDCDCDCECECDCDCECECECAAECDCECDCECECDCECECECECECECFCDCECECECFCFCDBAADBDBFCECFCFCFCECECFCFCECFCFCGCFCFCGCFCFCFCFCGCFCFCFCFCFCGCGCFCGCGCGCHCHCGCFCGCGCGCGCGCGCHCGCHCHCGCGCHCGCGCICHCHCGCHCHCHCHCICHCICICHCHCHCICHCICICHCJCHCICICICICICJCICJCJCICICICICJCJCJCJCJCJCICJCICJCJCJCJCAADBFBEBEBICHCEBAAEBEBABAAAAHBHBIBIBIBIBIBIBAEAAAAAAAAAAAAAAAAAAAAAAAEABAAAAAAAAAAAAABAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAEAEAAAAAAAAAAAAAAAAAAAAABAAAAAAIBIBIBAEIBIBAEIBAEIBIBAAAAIBIBIBAAIBIBIBICAEIBJBJBAAAAAAAAAAIBIBIBIBAAAAAAAAAAAAHBHBIBIBAEIBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAEAAAEAEAEAEAEAEIBIBIBIBIBIBIBIBIBHBHBEBEBBBIBAEAAAAAAAAIBAEABAEAEAEAEAEAEAEAEAEAEABJCAAAAICCCDCBCBCAAAAAAAAAAAAAAABAAAAAAAAAAAEAAAAAEBCAEAEAEAEAEECAEAEAEAEAEAEBCBCCCDCECICJCBCBCDCDCHCHCICICJCJCJCJCBCBCBCCCAAAAAAAAAAAAAAAAAAAAAAAAAAAADCECFCGCHCICJCBCBCBCBCCCCCDCECECFCFCGCGCHCHCICICICJCJCJCECJCAAAAAAHCAAAAAEHCAAAEAEAEHCAAAAJCICICAAAAAAAAAAAAAAAAAAAAAAAAICAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAICAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAAAEAAAAAAAAAAAAAAAAAAAAAAAAAEAAABAEAEAEAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABABAEAEAAJBAEAEAEAEAEAAABABABABABABABABABABABABABABABABAEAEAAABAAAAAAAAAAABABAAAAABABABABABABABABABABABABABABABABABABABABABABAAABABAAABABABABABABABABABABABABABABABABABABABABABABABAAAAABABAAAAAAABAAABAAABABAAABABABAAAAABABABABABABABABABABABABABABABABABABABABABABABABABAAAAABABABABABAAABAAABABABABABABABABABABAAABAAAAABABAAABABABABAAAAABABABABABABABABABABAAAAABABABABABAAABABABABAAABAAABABABABAAABABABABABABABABABABAAAAABABABABAAABABAAABABABABABABABABAAABABABABABABABAAAAABABABABABABABAAAAABABABABABAAABABAAAAABAAABABABABABABABABABABAAABAAABABAAAAABABABABAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEBBBBBBBBBBAAAAAAAAAAAAAAAAAAAAAAAAAAIBIBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABAAAAAAAAAAAAAAAAAAAAAAAAAADBCBCBCBAEAEHCABJBJBJBIBIBICICICJBIBICJBJBIBICICIBICICICJBJBJBIBJBIBICJBJBIBICICJBJBJBIBICICIBICJBJBIBJBICIBICICICIBICICIBJBJBJBICICICIBJBJBJBIBJBJBJBIBIBICICICGBGBDBDBAEAEAEAEABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAEAAAAHBHBAAAAAAAAAAAAAAAAAAAAAAAAABAEAEAEAEAEEBEBABEBECEBEBJBJBJBJBJCJBJBJCJBJCJBJCJBJBJBJBJBJBJBJBJBJBJCJBJCJBJBJBJBJBJCJBJCJCJBJCJBJBJBJBJBJBJBJCJBJCJBJBJBJBJBJBJBJBJBJCJCJBJBJBJBJBJCJCJBJBJCJBJBJCJBJBJBJBAEAEAEAEEBAAAAAAAAAAAAAAAAAAAAAAAACBCBAEBBBBBBABABBBABABJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBAEAEAEAEAAAEAEAECBAECBCBJCJCBBICICJCBBBBCBJCICCBAEIBIBIBIBJBJBJBICAAJBJBJBJBCBCBHCABAEAAAAAAICICJCJCABABAAAAAAABABAAABAAAAAAAAAAAAAAAAAAAAAAAAAAEBAAAAEBEBJBJBDBCBABABHCABABABGCGCAAAAAAABABICAAJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBAAAAAAJBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJBJBJBJBJBJBAAJBJBJBJBJBAEAAAAAEAEAAAAAAAAAAABAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAABAAJCAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJBABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAEAEAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAABABABAEAEAEAEABAAAAAAAAAAAAAAAAAAAAAAAEAEAAABABAAABABABAAAEAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABAAAAAAFBAAAAAAAAAAAAAAAAAAAAAAAAAAAEIBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAABAAABABABABABABABABAAAAABABABABABABAAABABAAABAAABAAABABABABABAAABAAABABABABABABABABAAABABAAABABABABAAAAABABABAAABAAABABABABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEABFBFBEBABABABBBAEBBCBAEAAAAAAAAAAAEAEECHBAAHBAAAAHBHBABHBHBHBAAHBHBHBAAECAAAAAAAAABABHBAAHBAAHBHBHBAEHBHBHBHBHBHBHBHBHBHBHBAAHBHBHBHBGBHBGBGBAEAEAEIBAEABABABABABHBHBGBGBGBAAFBFBGBGBGBGBGBGBHBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABABABABABABABABAAAAAAAAAAAAAAAAAAAAAAAABCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIBIBAAAAJBIBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGBGBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJBJBJBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABABABABAEABABAEAEAAAAAAAAAAAAAAABAAAAAAAAAAAAAAJCABABABABABAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJBJBJBJBABABJBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAECAAABABABABABABABABABABABAAABAAAAAAAAAAAAAAAAAEAAJCABAAABABABABAAAAAAAAAAAAAAAAAAAAAAAAJCAAABAAAAAAAAICABABABAAAAHCICABICAEAAIBIBIBIBIBIBIBIBIBIBIBIBIBIBIBAAIBIBIBIBIBIBIBIBIBIBIBIBABABABAAAAAAAAAEICICICICICICICICIBIBJBABJBJBJBJBJBIBAAAAAAAAAAAAAAAAAAAAAAIBIBIBIBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBIBJBJBJBJBJBJBJBJBJBJBJBJBIBAAIBJBJBJCJBJCJCJCIBIBAEJCAAABABABABAAJBJBABABJBIBAEABABABABAAABAAABABABABAAAAABABABABABABAAABABABIBIBABABABABABABIBIBIBABIBIBIBJBJBJBJBJBJBJBJBJBAAIBIBIBIBIBIBIBIBJBJBJBJCAAAEABJBIBAEIBIBJBIBIBIBJBJBABJBJBJCJBJCJBJCJCJCJCAAABABABABAAAAAAJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBIBIBJBJBAEAEJBJBJBJBJBJBJBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADBDBAAAAAAAEAEAAAAAAAAAAABABAAAAAEIBAEAEAEABABJBJBACACACAAAAAAAAAAAAAAAAAAAEAEAEAEAEAAABABAAAAAAAAHCAAAAHAICICAAAAAEAEAAAAJBAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAABAAJCAAAAAAAAABICICICICAAJCJCJCJCJBJBJBJBJBAAJBAEAAJBJBJBIBJBJBJBJBHCICICICICICABAAABABABABGCGCGCGCABABABJBJBJBAEJBJBJBJBABIBIBIBIBIBIBAAAAAAJBJBJCJBJBJBJBJCICICICICAEAAAAAEAAAAAEAEJBJBJBJBJBJBJBJBHBAAAAAAABABABAAAAAAABABABAEABABABAAAAAAAAAAAAABABABABABABABAEABABABABABABABAAAAABJBAEJBJBJBJBJBJBJBJBJBJBJBJBJBABAEJBJBJBJBJBABABABABJBABABJBABABABABABABABABABJBABABABABABABABABABABABABABABABABABABJBABABABABABABABABJBABJBABABJBABABJBJBAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAEAEDCAAAAAAAEAEAEAEAEBBAEAEAEAEAEAAAAAAAAAAAAABAAAAABAAAAAAAAAAAAAAAAAAAAAAHDAAHDABAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABAAAAAAAAAAAAAAAAAAAAAAAAABAEABABAEAAGBAEHBAEAAABAAABABABABAEAEABAEGBGBGBGBGBGBICICABABICJCJCJCICICAAABABICJCJCJCABABABAAAEIBABABABAEAEAEAAAAAAAAAAAAAAAAAAAAAAABABABABABABABABABABABABABABABABABABABABABABJBJBJBJBJBJBJBJBJBHBHBGBGBGBGBHBHBAAGBGBGBGBGBGBGBJBJBJBJBJBJBJBJBJBJBJBGBJBJBJBJBJBJBJCJCABABABABABABJCJCAAHBABAAJCJCJCJCJCJCJCJCJCAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABABABABABABABABABABAAABABABABABABAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAABABABABABABABABABABABABABABABABABABABABAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJCJCJCJCAAAAAAAAAAAAAAAAAAAAABHBHBAAAAAAABABABABABABAAAAABABABABABABABAAABABABABABABABABABABABJBJBJBJBAEJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBAAJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBAAJBJBJBAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABABJBAAAAAAJBJBJBJBJBJBJBJBJBJBAAAAABABABABABABABABABABABABABAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJBAAAAAAAAAAAAAAAAAAAAAAAAAAABABFBFBFBABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJCJCJCJCJCJCJCJCJCJCJCJCJCJCABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABABABABABABABAEAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABAAAAABABABABABAAAEABABABABABABABABABABABABABABABAAAAAAAAAAAAAAAAAAAAAAABABAAABABABFCAAAAAAABAAAAAAAAAAAAAAAAAAABABABABABABABABABABABABABABABAAABABABABABABAAABABAAABABAEAEJBJBJBJBJBJBABJBAAJBJBJBJBJBJBJBAAJBJBJBABJBJBJBJBJBJBAAAEAEAEAEJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBABJBJBJBJBJBJBJBJBAEJBJBABJBAAAAJBJBJBJCJBJBAAJBAAJBJBJBJBAAAAAAAAAAAAAAAAABABABABAAJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBAAJBJBJBJBJBAAJBJBEBBBABEBAEAAAAAAAAAAJBAAAAHBAAHBAAHBAAAAAAHBHBHBJBABABABABJCJCABABAAHBAAHBHBAAAAAAAAABABABABAAAAAEAEAEAAAEAEAEAAAEAAAEAEAEAAABJBABABHBHBHBJBJCABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAAAAABABABABABABHBHBAAAEABAEABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABHBABABAAJBMBMBMBMBMBMBMBMBAAAAABMCAAAAMAABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABJBABJBJBJBIBIBABAAABABABABABABABABABABABABABABABABAAJBJBABJBABABJCJBJBAAJBAAJBJBABABHBABJBJCJCJBJCJBJCJBJBJBMCMBMCMBMBMBMBMBAAMBAAMBMBAAJBJBABJBJCJBJBAAJBAAJBJBAAAAICHCJCJBJBJCJBJBJBJBAAJBAAJBJBABJCJBJBJCJBJBJBJBAAJBAAJBJBMCMCMBMBMCMBMBMBAAAAMBMBMBAAJCJCJBJBJCJBJBAAAAJBJBJBJBJCJCJBJBJCJBJBAAAAJBJBJBJBAAAAAAAAAAHBAAABAAAEAEAEAEAEAEAEJCAAABAEAAAEAAAEABABABABABABAEAEAEABABABABAEABABAAAAAAAAAAABABABAAABABABAAAAAAAAAAAAAAAAAAABABABABABABABAAAAABAAAAABABABABABABABABAAAAAAAAAAAAAAAAAEAEAEAEAEAEAEAAABAAABABAEAEAEAAABAEAEAEAAABAAJCJCJCJCJCJCAEABAAAAAAAAAAAAAEAEAEAEAEAEAEAEAAAAAAAAHBHBHBHBABABABABABABHBAAAAAAABHBAAAEAAHBHBAAHBAAAAAAAAAAHBAAAAAAHBAAHBJCJCJCAAAAAAAAAAAAAAAAAAJCJCJCAAAAAAAAHBABABABABABABABABABABABABABABABABABABBCAAJBJBJBJBJBJBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJBJBABABABAEAEAEAEAEAAAEAEAEAEAEJBJBJBJBJBABJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBFBFBGBGBABIBIBIBJBIBIBABICICIBICICIBICICIBICICIBJCJCJBJCJCJBJCJCJBJCJCJBAAAAAAAAJBJBJBJBJBJBJBJBJBJBJBJBICICICJCJCJCJCJBJBJBJBJBJBJBJBJBAAAAJBJBJBJBJBJBJBJBAAAAJCJCJCJBJBAAABABABABABABABABABABABAAAAAAAAABABAEAAAAAAAAAAAAAAAAAAAAAAAAABABAAAEAEABAAAAAEABAAAAAAAAAAAEAEJBJBJBJCJBJCJBJBAAJBAAJCJBJCJBJBJCJBJBAAJBAAJBJCAEAAAEABABABAEAEABABABABABABAAAAAAAAAAAAAABCAABCBCAABCAAAACCCCCCAACCDCDCDCAAABABABABABABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABAAABABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABCBCAACCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABABABABABABAEAEAAAAABABABABABABABABAAABABABDCAEAAAADCDCAAAADCECECECAAAAFCAAECECAAFCAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABABABABABABABABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAAAAAEAAAAAAAAABAAABABABABAAAAJCJCJBJBJCJBJBAAAAJBJBJBJBJCJCJBJBJCJBJBAAAAJBJBJBJBAAAAJCJCJBJBJCJBJBAAAAJBJBJBJBJCJCJBJBJCJBJBAAAAJBJBJBJBAAABAAAAABABABABABABABABABABAAAAABABABABABABAAAAAAJBJBJBJBJBAAABABABABJBAAAEAEAEAEAAAAAAABAEAEAEAEAEAEAAAAAAAAAAAEABABABAAABABAAAAAAABABABAAAAAAAAAAAAAAABABAAJBJBJBJBJBJBJBJBJBJBJBABABABAAAAAAAAABABABABABABABABABABABABABABABAEABAAAAABABAAABAAABABAAAAAAAAAAAAAAABABAAABAAAAABAAABAAAAAAABJBAAJBABAAAAABABABABABABABABABABABABABABABABABABABAAJBJBABABJBJBAAJBAAAAHCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAAAAAAADAAAAADADABGBGBAAABABHBHBIBIBIBABIBABABABJBABABJBJBJBJBJBJBJBJBJBJBJBACACACJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBAAJBJBJBJBABJBJBJBJBJBAAJBAAJBJBJBJBJBABABABABABABABABABABJBJBJBJBJBABABABABABABABABABABABABABABABABABABABABABABABABABABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAABAAAAAAAAAAAAAAAAAAAAAAAAAAJBJBJBJBJBJBJBJBJBJBJBJBJBAAJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBABABABABABABABABAAJBAAABJBJBJBJBABABJBJBABJBJBJBJBAEAEAEAAABABABABABAAABABAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAABABABABAAAAAAAAAAAAAAAAAAAAJBAAJBJBJBJBJBJBJBJBAAAAAAAAAAJBAAJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBAAAAAAAAAAAAAAJBAAAAAAJBABAAAAAAAAJBAAJBJBAAJBJBJBAAAAAAAAAAAAAAAAAAAAJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBABJBAAAAJBAAAAAAAAAAAAAAAAABABABABABABABABABABABABABAAAAAAABABABABABABABAAEBABABABAAGCGCFCEBAEFBAAFBAAAAGBGCGCACHCHCHBAEAEAAAAHCICABHBICJCJCAEAAAEIBAAAAAAAAIBICIBJCAAAAAAAAAAAAAAJCJCJCJCJCJCJBAEAEJBJBAAABABJBABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJBJBJBJBAAACAAACAAAAMCMCMCJCJCJCLCLCLCLCJBAAACLCLCLCLCMCMCMCLCLCLCMCMCMCACMCMCMCACAAAAAAAAAAAAAAAAAAAAAAJBJBJBJBAAAAAAAAAAAAAAAAAAAAAAABABABABABABABABABABABABABABABABABAEAEAAAAAAAEAEAAAEAAAABCBCBCBCAEAEAEAEAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAABABABAEABAEAEABAEAEAEAAAAAAAAJBIBJBIBIBIBJBJBJBIBJBIBIBJBJBIBJBJBAAIBABIBJBJBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAEAEAEABABABABAAAAAAABABAAABIBIBJBJBIBIBIBJBJBIBJBJBJBJBIBIBIBIBJBJBIBIBJBIBIBJBJBIBJBIBIBIBJBJBAEJBIBIBJBIBJBJBIBAAAAAAJBIBJBIBIBJBJBIBABABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAEABAAAAAAAAAAAAAAAAAAJBJBAAAAAAABABABABABAAAAAAAAAAABABABAAAAAAAAAAAAAAAAAAAAAAAAABABABABABABABABABABABABJCABABJCJCJCJCJCAAABAEAAAAIBIBABIBIBABAAAAIBAAABAAAEAEAAABAAABAAHBAEIBAEAEAEAEHBJBJBAAHBABABABABABHBIBIBABABIBACJBACACACACACJBIBIBIBIBAAABABAAAAAAAEAEIBJBJBJBHBIBHBHBHBIBABABABAAABABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJBJBJBJBJBJBAAAAAAABJBABJBJBJBAAJBJBJBABJBJBAAAAJBJBJBJBJBJBJBJBJBJBJBJBJBAEJBJBAAJBJBABJBAAJBJBABABABABABABABABABABABABABABABABABABABABABABABABAAAAAAAAJBJBJBJBAEAEJCJCICAEAEAAAAAAAAABAAJBIBJBIBJBJBIBJBJBJBJBJBJBJBJBJBJBJBJBAEAEAAMBJBJBJBJBJBJBJBJBMBJBJBJBJBJBJBAEJBAEAEMBJBJBJBJBJBJBJBAEAAAAAAAAAAAAAAAAAAAAAAAAAAHBAAAAABABABMBJBJBJBJBJBJBJBJBAEAAAAMBJBJBJBJBJBJBJBABAAAAAEMBJBJBJBJBJBJBJBMBJBJBJBJBJBJBJBMBJBJBJBJBJBJBJBMBJBJBJBJBJBJBJBABAAAAABABAAAAAAAAAAABABAAABABABABABABAAAAAAAAABABABAAABAAAEAEABABAAABABABAAAAABABABAAAAAAAAAEAEABAAAEABAAAAAAAAAAAAAAAEAEAAAAAEAAAAAAAAAAABAEAEAEAEAEAEAAABAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEABABABAEAEABABABABAEAEAAAAAAAAAAAAAAABABABABJCAEJCJCIBIBJCIBJCJCJCJCJCJCJCIBIBJCJCJCABABAEAEABAEIBABJBJBAAABAAAAAAAAJBJBJBJBAAAEAAAAAAAAAAJBJBJBJBAAAAAAAEJBAEAAAAJBJBJBJBJBJBAEJBABJBJBJBABAAJBABABADABJBJBJBAEAEAEAAABAAAAABABABABABABABABABABABAAABABABAEJCJCJCJCJCJCJCJCJCAAABABABABABABABABABAEAEAEABABABABBCBBBBAAAAAAAAAAAAAAAAAAAAAAAEAAJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBMBJBMBAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAABAAAAABABABABABABAAABABABABAAABABABABAAABABABABABABABABABABABABABABABABABAEAAAAAEAEAEAAAAAAAAAAAAAAAAAAAAABABAAABAAABAAAAAAAAABABABABAAABABABABABABAAABAAAAAEAAAEAAAEJBJBJBJBJBJBJBJBJBAEAEAEJBAEAEAEABABABJBAEABABABABJBJBAEABABABABJBJBBBABBBABABABABABABAEBBBBJBBBJBBBABABABJBAAABABABABJBBBBBBBBBABJBJBABAEJBJBJBABABJBABABABABJBABABJBJBJBJBJBAAJBABJBAAJBJBJBJBJBJBJBJBJBJBJBJBJBMBMBJBMBJBMBMBMBMBMBMBAAAAMBJBAAJBMBMBMBMBMBMBMBMBMBMBMBJBJBJBJBMBJBAAJBAAAAJBAAAAJBJBABJBJBAAJBJBJBJCJCJCJCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABIBIBIBJBJBJBABAAJBABABAAABAAABJBAAAAABABAAABABAAAAABABAAAAAAAAABJBAAAAAAABABAAAAAAAEAEAEDBDBDBBBAABBAAAAAAFBFBABABABABABABAAAAAAAAAAAAAEABABABABABJCJBJCJBJBAAJCAAAEABABAAAAAAABAAAAAEABAAAEAEJBJBJBAAAAAAAAJBAEABAAAAAAAAAAAAAAAAJBJBAEAAAAJBABABAAABABAEABAEABABABABABABABABABABABABABABABABABAEAEABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAAAAAAABABAAABABAAAAAAAAAAAAAAAAAEAEABAEAEAEAEAEAAAAAAAAAAAAAAAAAEAAAAAAAAAAABAAAEABMAMAAAABAAABABAAABABABABAAABABABAAABAAAAAAAAAAAAAAAEAAABABABABABAEABABABABBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBAAAEAAAABBBBBBBBAAAAAAAAAABBBBBBBBBBBBABAAAAAAAAAAAAAEAAABAAAAAAAAAAAAABABABABABABABABABAEABAAAAABABABABABABAAAAAAAAAAAAAAAAAAAAAEAAJCAEJCAEAEJCJCLCJCJCABJCJCABAAJCJCJCABABLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCAAAAAAMCMCMCMCMCMCMCMCMCMCMCMCMCMCABMCABABABAEAEAEAEMCMCMCJBJBAAABABABMBMBMBAEAAAEAEJBAAAAAAAAAAAAJBAAAAABAAAAAAABABABJBAEAEAAAAAAAAAAAAAAABABABABABABABABABABABABABABABABABAEABAAABABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAEAEABAEAEAAAAAAAAAAAAAAABAAAAAEAEAEAEAEAEJBJBJBJBJBJBAEAEAEAEAAAAAEAAAEABAEAEAEAEAAAAAEAEAEAEAAAAAEAEAEAEAAAAAEAAAAAAAAAEAEAAABAEAEAAABAAABABABBBAABBAEAAAAABAAAAAEAAAAAEAAAAAEABABAEAEABAEAAAAAEAEAAAAJCAAAEABLCLCLCAEAEAEAEAEAAABAAAELCABAEJCLCLCAAAAAAADAAAAAAAAAAAAACACAEABAEAEAEAAAAAAAAAAAAAAAEAEAEAEABAAAAAAAAABAEAAABAEAAAAAAAAABAAABABAAAAAAAAABAAAAAAABAAAAAAAAAALCLCAAAAMBMBAEAAAAAEAEJCJCABMBMBAAAAAAAEBBAEABAAAAAEABAEABAAAAAAAAAAAAAEAEAAAAAEAAAAAAAAAAAEABABAAAEABAEAEAEAAAEAEAEABAAAAAAAEABABAAABAEABAEAEAAAEAEAEAEABAEAEAEAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAEAAAAAAAABBAEAEAEAEAEAEBBAEAEAEAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAABABAAAAABAAAAAAAAAEAEAAAEAAABABABABABABAAABABABABAAAAAAAAAAAAAAAAAAAAJBJBJBJBJBAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAEJBJBJBAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAJBJBAAAAAAAAJBAAAAAAJBJCJCJCJCJCLCLCAELCJBABLCLCLCLCLCJBJBLCLCJBLCJBLCLCAEAAAAAAABABAALCBBBBBBLCBBBBBBLCAALCLCDBDBDBLCMCMCLBLBLBLBLBABABABABABABABBBJBBBAEABABABAAAAAAAAAAAAAAJBJBAEAEJBJBAEAEABABABABABAAAAAAAAAAAAAAAAAAABABABABABABABABABABABABAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAEICABAEAEAEABAAAAAEAAAAAEAAAAAEAEAEAEAEABAAAAAAAAAAAEAELCLCLCLCLCLCMCMCMCMCMCMCMCMCMCMCMBMCMCAAAAACAAAAAAAAAAAAABABAEAEAAAAAAAEAEAEABAAABAAAAABABABABAAAAAAAAAAAAAAAAAAAAAAAAABABABABABABABABAAAEAEAAAAAAAAAEAAAAAAAAAAAAABAAAAAABBABABAEAABBBBBBBBBBABAABBBBBBBBBBBBBBBBBBABJBJBAAJBJBJBJBJBJBJBJBABAAAAAAAAAEAEAEAEJBAAJBJBJBJBAEAEJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBAEAEAAABAAAAAAAAABABAAAAAEAAJBABAEAEABAAAEAAABAEABABABAEAEAEABABABABABABABABABBBBBBBABABABABABABABABAAJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBAEAEAEAEAEAEAEAEABAAAAAAAAAEJBAEABABAEAEAEAEAEABAAAEAEABAAAEAEAEAEAEABAEAEABAEAAAAAAAAAAAAAAAEAEAAAAAAAAAAABAAABAEMAMAMBMBABMBMCMBMBAAMBAAMBMBABAAABAAAEAEABABABABABABABABABABABABABABABABAEAAAAAAAAAAAAAAAAAAAAAAAAAEAAJCAAAAAAABAAABJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCAALCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCJCJCJCJCJCJCJCLCLCLCLCLCLCLCJCJCJCJCJCJCJCLCLCLCLCLCLCLCJCJCJCJCJCJCJCLCLCLCLCLCLCLCJCJCJCJCJCJCJCLCLCLCLCLCLCLCJCJCJCJCJCJCJCLCLCLCLCLCLCLCJCJCJCJCJCJCJCLCLCLCLCLCLCLCJCJCJCJCJCJCJCLCLCLCLCLCLCLCJCJCJCJCJCJCJCLCLCLCLCLCLCLCJCJCJCJCJCJCJCLCLCLCLCLCLCLCJCJCJCJCJCJCJCLCLCLCLCLCLCLCJCJCJCJCJCJCJCLCLCLCLCLCLCLCJCJCJCJCJCJCJCLCLCLCLCLCLCLCJCJCJCJCJCJCJCLCLCLCLCLCLCLCJCJCJCJCJCJCJCLCLCLCLCLCLCLCJCJCJCJCJCJCJCLCLCLCLCLCLCLCJCJCJCJCJCJCJCLCLCLCLCLCLCLCJCJCJCJCJCJCJCLCLCLCLCLCLCLCJCJCJCJCJCJCJCLCLCLCLCLCLCLCJCJCJCJCJCJCJCLCLCLCLCLCLCLCJCJCJCJCJCJCJCLCLCLCLCLCLCLCJCJCJCJCJCJCJCLCLCLCLCLCLCLCJCJCJCJCJCJCJCLCLCLCLCLCLCLCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAABABABAAAAAAAAAAAAAAAAABAAAAAAAABCBCAAAAAAAAAAAAAAAAAEAEAAAAAAAAAAAAAAAAAEABAEAEAEAACBABAAAAAEABABABABABABABABABJBJBJBJBJBJBJBJBJBJBJBJBAEAEJBJBJBJBJBAAABJBJBJBJBJBJBJBJBJBJBAEJBJBJBJBJBJBJBJBJBJBAAAAJBJBJBJBABABABABJBABABABJBABJBJBJBABJBJBJBLBLBLBLCLBAAABAALBABABAEABLBLBLBJBJBJBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBAEAAAALBAELBLBLBLBLBAAJBJBJBJBJBJBJBAEJBJBJBJBJBJBJBJBJBLBJBJBJBJBJBJBJBLBLBLBLBLBLCLBLBLBLBLBLBLBAELBLBAELBLBABAELBLBLBAAAEAEAAAAAAAAJCJCJCJCLCABLCLCJCJCAAAAAAAEAAJCJCJCLCAEJCJCJCLCAEAEAALCLCLCLCAALCLCLCAALCLCLCLCLCLCLCLCLCAAAAAAJBJBAAAAAAAAAAAAAAJBJBJBJBJBJBJBJBJBAAAAABABAAAAAAAAAEABABABABABABABABABABABABABABABABAAAEAEAAAAAAAAAEAAAAAEAEAEAEAALBLBLBLBLBLBAEABAEAEAEAEAELBLBLBLBLBLBLBLBLBJBJBJBJBJBJBJBLBLBLBLBLBLBLBLBLBLBAAMCAAAAAALBLBLBLBAELBLBLBLBAEAAAEAEAAAEAALBLBLBLBABABABABABABABABABABABABABABAEABAAAAAEAEAAAAAAAAAAAAAAAEAAAEABABABABABABAAAAAAAEAEAEAEABAAAAABABAAAAAAAAAAAAAAHBAAABABABABAAAAAAAAAAAEAAAEAAAAAAAAAAAAAAAAABAAABABABAAAAAAABAAABAEAEJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBAEJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBLBJBJBJBJBJBJBJBJBJBJBJBJBJBIBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBABABABABABABAABBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBABABABABAAAAAEBBBBBBBBBBBBLBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBBBBAAAAAAAAAAAAAABBBBBBBBBBBBBBAAAAAALBLBLBLBLBLBLBLBLBLBLBAELBAAAALBLBAALBLBLBAALBLBLBLBLBAALBAAAAAALBAAAAAAAAABAALBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBABABABABABLBLBLBLBLBABAEAAAALBLBLBAALBLBLBLBLBLBLBLBLBAALBAAAAAAAAAAAAAALBLBLBLBLBLBAALBAALBAAAALBLBLBLBLBLBLBLBLBLBLBLBLBAALBAALBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJBAEAEAEAAAAABABABBBBBAAABABABABABABABABAAABABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAALBLBAAAAAAAAAAABABAAAALBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABABABABABABABABLBLBLBJBJBJBJBJBJBJBJBJBJBJBJBJBJBAAJBJBJBJBJBJBAALBLBLBLBLBLBLBLBLBLBLBLBJBJBJBJBJBJBLBJBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBAALBLBABLBLBLBLBAALBLBABABLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBAEABABAAAAABLBLBLBLBLBLBAAABLBLBLBLBLBLBLBLBLBABLBABABABLBAALBLBLBLBAELBLBLBLBLBLBLBAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAALBLBLBLBLBLBLBLBLBLBLBLBLBLBABABABABABLBLBLBLBLBLBLBLBLBLBAALBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBABABABAAABLBABABABABABABAAAAAAAALBLBLBABAAAAABAEAAAALBABLBABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAALBAAAALBLBAAABABLBLBLBLBABABABAALBLBLBLBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAJBJBJBJBJBJBJBLBLBAAAAAAABAEJBJBJBAAAAJBAAAEAEAAJBJBJBAAJBJBAAJBAAAAAAAAJBJBJBJBJBAAABJBJBABABABJBJBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAEAEAAJBJBAALBABAAAAAAAEAAAAAAAALBAAAALBAAABABABABABAAABAALBAAABABABABABBBBBBBBBBBBBBBBBBBBBBBBBBBBBABBBBBABBBBBBBABBBABAAJBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBAAAAAAAAAAAAAALBLBLBLBLBLBAAAELBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBABABABABABABABABABABABABABABLBLBLBLBLBLBLBLBLBLBLBLBLBAALBLBLBLBLBLBLBLBAAABABABABLBABABLBAAAAABAAAEAALBLBAELBAAAAAAAEABABABLBABABABABLBABBBLBABLBABABABABLBABABABLBLBLBLBABABLBLBLBLBLBAALBLBAAAAABABABABABAELBLBLBLBLBLBLBLBLBABLBLBLBLBAEAEAEAAABABABABAEABABAAAAAEAAAALBAEAELBLBLBLBLBLBAEABABABABABAAABLBABLBLBAAAALBLBLBLBLBABLBLBLBAALBLBABLBABABLBLBEBABABABLBLBLBLBLBAELBLBAAAAABABABMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBABABABABABABABABABAAMBMBAEAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAEABMBAEAEAAABABMBMBMBAAAAAAAAAEJCJCJCJCJCJCJCJCAAAEAAMBMBMBMBMBMBMBMBMBMBMBAEMBMBMBMBMBMBMBMBMBMBMBMBAEAEMBMBMBJCJCJCJCJCJCJCLCLCLCLCLCLCLCMBAAAEAEAAAEAEABABAEABABABABABABABAEAEAEMBMBMBMBMBMBAEMBMBABABABABMBMBAEMBMBMBMBMBMBMBMBMBMBMBMBMBMBAAAAMBAAMBMBMBMBMBMBABMBAEMBMBMBMBMBABABABABABABABABMBABABABABABABABABABMBABMBAEAEAEAEABABABABABABABABABMBAAMBAAAEMBMBMBMBMBMBMBMBMBMBMBMBAEAEMBAEAEMBMBMBMBMBMBMBAAAEAAABABABAAABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAEMBMBMBMBMBMBMBMBMBMBAAAAAAAAMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBABABABABMBMBMBMBMBMBMBAEMBMBMBMBMBMBMBMBMBMBMBMBMBMBAEMBAEAEABMBMBMBMBMBMBMBMBMBAAMBMBMBMBMBMBABABABABABMBABABABABABAAABABABABABMBMBMBMBMBMBMBAEMBABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAAAAABAAAAABABAAAAABABABABABAAAAAAAAAAAAAAAAAAAAAAAAAAABABAAAAABABABABABABAEAAABAAABABABABABABABABABABABABABABABAAABAEABABABABABABABABABABABABABABABABABABABABABABABAAABABAAAEMBMBAAMBMBMBAEAEAEIBABABABABABABAAABABABABABABABABABABABABABABABABABABABABABABABABABABABAAAAAAAAMBMBAAAAMBMBMBAEMBMBMBMBMBABAAAEAEMBMBMBMBMBMBMBMBMBMBMBMBMBAAMBMBMBMBMBMBMBMBMBAEAAMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBAEABABABABAEAAJBJBAAAAAAAEAAABABABABABAAABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAEABABECECICICAEAEAEAEABABABABABABABABABABABABABAAABABABABABABABABABAAABABABABABABABABABABABDBBCECICLCAEAEAEAAABJBLBJBABABABAEABABABABABABABABAAAEABABABABABABABABABABMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBAAMBMBMBAEMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBABABABABABABABABABABABABABABABABAAAAABABABABABABABABABABABABABABABABAAAAJBJBJBJBLBLBLBLBLBLBLBLBAEJBJBJBJBLBLBAELBLBLBLBLBLBAELBLBLBJBJBJBJBMBMBMBMBMBMBMBMBMBMBMBMBAAMBMBAEMBAAAAAEAEMBMBMBMBLCLCMBMBMBMBLCLCMBLCMBMBMBMBMBMBMBMBMBMBLCAAAAAAAAAEAEJBJBJBAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAAAAAAAAABAAAAAAAAAAAAAAAAABAAAEAAAEAAAAAAAAAAAAAAAAABABMBAEAAAEAAMBAEABABABABABABABABAEAEAEABAEAEAAAEAEAEAAAAAAAAAAAALCLCLCLCLCLCLCLCLCLCLCLCAEMCMCMCMCMCMCMCMCMCMCMCAEMCMBMBMBAAMBMBMBMBMBMBMBMBMBAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBCBCAAAEAAABAEABAEABABABABABABABABABABABABABABABABABABABABABABABABABABAEAAAAAAAAAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAABAAAAABABABABAAABAAAAAAAAABAAABAAAAAAAAABAAABAAABAAAAAAAAABAEABABABABABAAAAAAAAAAAAAAAAABAAAAAAABAAABABABABAAAAAAAAAAAAAAAAAAAAAAAAABABAEABAAAAAEAEABABABABABAAAEAAAEAAABABABABABABABABABABABABABABABAEAEAELBLBLBLBLBLBLBAELBLBLBLBLBLBLBLBLBLBLBAALBLBLBLBAEABAEAEAAAAAEAAAELBAELBLBLBAALBLBLBLBLBLBAAAEAEAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAAJBJBJBJBAEJBJBJBJBJBMBJBMBMBMBMBMBMBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBJBMBMBMBMBMBAEAALBLBAAAAAALBAAAEMBAEHBMBMBLBLBLBHBHBMBLBLBLBMBMBLBLBLBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBLBLBLBLBLBLBLBLBMBMBLBLBLBLBLBLBMBLBMBMBLBMBMBMBMBMBMBMBMBMBMBMBMBMCMBMCMBMCMBMCMBMCMBMCMBMCMBMCMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBHBHBHBHBHBLBMBLBLBAAMBMBMBMBMBMBMBLBLBLBLBMBMBMBLBAEMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBAAMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBAAMBMBMBMBMBMBMBAAAAAEAEMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBAEAEAAAEAAAAAAAAAAAAAEMBABABABMBMBAAMBAAMBAAMBAAAAAAABABAAABAAMBMBMBAAAAMBMBMBMBMBMBMBMBLBMBMBMBMBMBLBLBLBLBMBMBMBMBMBMBMBMBABABABABABABABABABABABABABABABAELBLBLBLBLBLBLBABABAALBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBABABAAAALBLBLBLBLBLBLBLBAALBLBLBLBLBLBLBLBABABABABAAAAAAAAABAAAAAAAAAAAEAAAAAAAAABABABAAAAAAAEAELBLBLBLBLBLBLBLBLBLBLBLBLBLBLBABABABABAAABABABABLBAEAEAAAEABABABABABLBLBLBLBLBAALBLBLBLBLBLBLBLBAALBLBLBLBLBLBLBLBLBLBAAAAAAAAAAAAAALBLBLBLBLBLBLBLBLBAAAEAAAAAAAAAAAAAAAAAEAAAEAEAEICBCCCGCHCAAAAAEABAAAEAEAEABAEAEAEAEAAAAAAAAAAAAAEABABAAMBMBMBMBMBAEAAAEAEAAAAAAAALCLCLCAELCLCLCAAAAAEAAAAAAAAAAAAAAAAAAAAAEABAEAAAAAAAAABABABABABABAAAAAAAAAAABABABAEAEAAAEBBBBAAAAAAAAAAAAAAAALBLBLBLBLBLBLBLBLBLBAEAEAEAEAAAEAEMBMBMBMBMBMBAAMBAAAEMBJDMBJDAAABABABABABABABABABABABAAABABABAEAAABABABABAELBABLBABABABABABAAAAAAABAAABABABABABABABABABABABABABABAAAELBABLBABABABABABABABABABABAAABABAEAEABAEAEAEMBMBMBABABAAAAMBMBAEMBAAAEABABABABAAABAEAEAEMBMBMBMBAEAEAAAAAEAEAAAAAAAAAEAEAEAEAEAAAAAAMBMBMBMBMBMBAAAAAAAEMBMBMBMBMBMBAEMBMBMBMBMBMBMBMBAEAEABAEAEAEAEAEHBAAAAAAAEAEAAAAAELBAELBLBLBLBAAABAEAAAAAEAAAAABMBABMCMCMCMCMCMCMCMCMCMCMCMCMCMCMCMCMCMCMCMCAEAEACACACACACAAAAAAAAJCAAJCABAAAAAAAAMBMBMBMBAAMBMBMBMBMBAAMBMBMBAAMBAAMBMBMBAAAEAEAAAEAELBLBLBAAAEAEAAAEAAAAAEAEAEAEAAAAAEBCAAAAAEAEAAAAAEAAAAAAAAAAAAAEAEAAAAAEABAELCABAEAEAEABLCABABABABABLCLCLCAEABABABABAAABABAAAEAEAEAEAEAEJBJBJBABLBLBMBMBMBMBMBMBAEMBMBMBMBMBMBMBAEAEAAMBMBMBMBMBMBMBMBMBMBMBMBAEMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBMBMBLBMBLBMBMBMBMBMBMBMBLBMBMBLBMBLBMBMBMBMBMBMBMBMBMBMBMBMBLBLBMBLBMBMBMBMBMBMBLBLBMBMBLBMBMBMBMBMBMBMBMBMBMBMBLBMBMBMBMBMBLBMBLBMBMBLBMBLBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBLBMBMBMBMBMBMBMBMBLBLBLBLBLBLBLBLBAAACAAAAAAABAEAEAAAAABABABABABABABABABABABABABABABLBLBLBLBABLBLBLBLBABLBLBABABABAEABABABAEAEJCJCJCAEAEAEJCAEJCJCAEJCJCJCJCJCAEJCJCAEJCAEJCJCJCJCJCJCJCCCLCLCLCLCLCLCLCLCLCLCLCLCAAJCAEJCAAJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCJCLCJCLCLCLCLCLCLCLCLCAAAAAAAALCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCJCJCJCLCJCJCJCLCJCJCLCJCABLCABJCJCJCABJCJCJCJCJCABAEAAJCLCBCAALCAAAEAEAEBCBCAAAAAABCBCBCAELCAAAALCLCLCAEAELCLCLCLCLCLCLCLCLCLCLCLCLCLCLCLCAALCLCLCAEAAAALCLCLCLCAELCAAABAALBLBLBLBAEAEMCMCMCMCMCMCAEAAMCAAMCMCMCMCMCMCMCMCMCABMCMCMCABMCMCAEABAEAEAAAEAEAEAAAAABABABABABABAEABABABMCAEAEMCMCMCMCMCAEAEAEABABABABABLBLBLBLBABAAAEABAAAAABABABABABABABABMCMCABABABAEABABABABABABABABABABLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBABLBLBLBLBLBLBLBLBLBLBLBABABABLBLBLBLBLBLBLBLBLBLBLBAELBLBAAAAAAAALBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBLBABLBLBLBLBLBABAAAAAAAAAAAAAAAAAEAAAAAALBLBLBLBLBLBLBLBLBABABLBLBLBAELBAEAELBLBLBAEAELBLBLBLBABAELBLBLBLBLBLBLBLBLBLBLBLBLBAAAALBLBLCLBLCLBLBLBLBLBLCLBLCLBLBLBLBLBLCLBLCLBLBLBLBLBLCLBLCLBLBLBABABABABABABABABABABABABABABABABAAAAAAAAAAAAAEAEAAAAAEAAAAABABLBABLBABABABABABABABABABABABABABABABABABABABABABABABABABABABAAABABABABABAEAEAEAAAEAEJBJBJBLBJBAEAEAEAAABAAAEAAAAAAAAAAABABAAAAAEAAABABABLBLBLBLBLBLBLBLBLBLBLBLBLBLBAEABLBLBLBAELBABAEAEABAEAEAELBLBLBLBJBAEJBJBJBJBAEAEJBJBJBJBJBJBJBJBJBJBJBJBABAEABAAAAAEAEAEAAAELBMBLBLBLBAEAEAEAEAEAEJBAEJBJBABJBJBAEJBJBJBAAJBAEJBAAAEABABABABABABABABABJBJBJBJBJBJBJBJBLBLBLBLBJBAEJBJBJBAAABAAAAAAABAAAAAEAEAEAEAEAEAEAEAELBLBLBLBLBLBAALBAAAEAEAEAAABABABABABABABABAAABABABABAAAAAAAAAAAAAAAAAAAAABABABABMCMCMCMCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMBMBMBMBMBMBLBLBLBLBLBAAAAAAAAAALBLBLBLBLBLCAALCLBAAAAAEAAAAABAEABAAAEAAAEAEABABABABABABABABABABABABABAAABABABABABABABABABABABABABABABABABABABABABABABAEABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAEAAAAABAAAAAAAAAEABABMBMBAEAAMBMBMBAAMBMBMBMBMBMBMBMBMBMBMBAAABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMBABMBMBMBMBMBMBMBMBMBMBAEMBAAMBMBAAMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBAAMBABMBMBABMBMBMBABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAEABAEABABABABAEAEAAMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBAEAEAEAEAEAAMBMBMBAEMBMBMBMBMBMBAAAAMBMBMBMBMBEBAEAEAAAEAEAAABABLBAAMCMCMCMCMCMCMCMCMCMCMCMCMCMCMCMCABAELBABAAAAAAABAAMBMBMBMBMBMBMCMBMBAAAAAAAAABAAABABABABABABABABABABABABABABABABABABABAAABABABABAAABAAAEAAABAEAAMBAEAAAAABAAAEAAAEAAMBMBMBMBMBMBAAMBMBMBJBABMBAAABABABABABABABABABMBMBMBMBABAAMBMBAEAEAAMBABAALCAEMBAAMBMBLBMBMBMBMBMBLBMBLBABMBMBMBMBMBLBAALBLBLBLBLCLBLBABABMCMCABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAEAAABAEMCABMBMCABMBMCMBAAMCABMBMCMBMCMBMCMBMCMBABMBMBMBMBMBAAAAAAAAAAAAAAAAABAAAAAAMBAAMBMBAAAAAAAAAAAAABABAAAEAAABABAEABABABABABABABABAAAAABABABABABABABABAAABAAMBAEMBMBABLBMBLBLBLBMCMCABLCLCLCLCLCLCLCLCAEAAAAAAAAAAAAAAAAAAAAAAAAAAAEABABABABAAAAAEABABABABABABABABAEAEAEAAABABABABABABABABABABABABABABAAAAAAAAAAMBAAABAAAEABAAABAAAAAAAAAAAEAEAEAAABAAABAAAAAEAEAAABAAABAAABAAABAAABAAABAAMCABAAABAAAAAAAAAAAAAAAAABLBABABJCAALCAALCABLBLBLBLBJBABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAAABABABABABABAEABAAAEAAAAABLBLBLBLBAAAEABAAABABAAABAAAEAEABABABABAEAAAAAAAAAEMCAAAAABABABABABABJBABLBLBLBLBLBLBLBLBAAAAAAAAAAAAAAAAAAABABAAAAAAAAABAAAAAAAAAAAAABABAAABABABABAAABABAAAEAEAAABABAABBAAAABBAABBBBBBBBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMBMBMBMBMBMBAAAAAAAAAAAAAAMBMBMBMBMBMBAEABABABABAAAAAAAAAAAAAAABABABABABABABABABABABABABABABABABABABABABABABABABABABABAAAAAAAAABAAABAEAEAEAEAAAAAEAAAEBBBBBBBBBBBBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAEAEAAAAAEABAAABAAAAABAEAAAAMBMBABABMBAAAAAEAAAAABABABABABAEAEAEAEAAAAAAABABABABAAAAAEABAEAEAEAEAEAAAAAEAAAAAAAEAAAAAEAEAAAEABAEAAABAEAEAEAEAEAEAEAEABABAAABAAAEAEAAMCAEABAAAEAEAAAEAAABABABABABAAAAABAAABAAAAABABAAAAAAABABABABABABABABABABABABABAAAAAEAEABAEAAAAAAAAAAAALCABAEABAAAAAAAAAAABADABAAAAAEAEABAEMBMBAAAAAAAAAAAAAAAAAAAEMBMCABMBMBAAAAAAMBAAAAMBMBMBAAAAABAAAEMBABABABAAAAEBEBEBEBEBEBAAEBAAEBAEEBEBEBEBEBEBEBAAEBEBEBEBEBEBEBAAEBEBEBEBEBEBEBEBEBEBEBEBEBEBEBEBEBEBEBEBAAAAAEAEMBMBMBAEMBAEMBMBMBAAABAEMBABMBAAAAMBMBMBMBMBAAAAMBMBABAEABAEABAEAEABABABAAAAMBAAAAAAAEMBAEMBMBMBMBMBMBAEMBMBMBMBAEAEAEAAAEAEAEAEAEAEABAEABAEAEAAAEAEAAMBAEMBMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMBAEMBMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAEAAAEMBAAAAAAAAAAAAAAAAAAAAMBAAAAAAAAAAAAAAAAAEAAAAAAAAMBAAAAAAAEAAAAMBAAABAAAAAAAAAAAAAAMBMBMBMBMBMBMBAAMBAEMBMBAAMBABMBMBMBMBMBMBMBAEAEAEAEMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBAAMBMBMBMBMBMBMBMBMBAAMBMBMBAAAAMBMBMBMBMBMBMBMBMBMBMBMBMBMBAEAAAAAAAEAAAAAAAAAAAAMBAAAEAAAAMBAEMBAAAAAAAEAAAAMBAAAAAAAAAAAAAAAAAAAAMBMBMBMBAEMBMBMBMBMBMBMBMBMBMBMBMBAAAAAAAAAAAEAAAAAAAAAEAEAEAEAAAAAAAEAEAEAEAEAEAEAEAEAEAEABAAAAAAAAAEAEAAAAAAAAAAABAEAAAEAAAAMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAAAAAEAAAAAAAEAEAEAEAAABABAAAAAAAAAAAABCAAAAAEAAAEABAAAAAAABAAAAABMBAEAAABABMBABABABAEAEABAAABAELBAEAAAAAAAAAEAEMBMBMBMBMBAEAEAEAEAEAEAEAEABABABABAAAAAEAEAEAEAEAEABAAAAAAABAEAEAEAEABABABAAAAAAABABABABAAABAAABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAAABABABABAAAAAAAAAAABABABABABABABABABABABABABABABABABABABABAAAEABABAAABAEABABAAMBMBABABABABMBMBMBMBMBAAABABABAAAAAAAAAAAAAEAAAAAAAAAAAAAAABAAAAAAAAAAABABABABABAAAAAAAAABMBMBMBMBAEABABABAAAAAAAAAAAAAEAEAAAEAEABMBAAAEAEABAAAEAAAAAAAAAEAEAEAEAAAAAAAAAAMBMBAEAAAAAAAAAAAAAAABAAAAAAAAAAAAABABAAAEAEAAAAABABABABABABAAAAAEAEAEAEAAAAAAAEAEABABABAAAAAAAAAAAAACACAEAEAAAAACACBBAAABAAAEAEAAABAEAEAEAEABAEAEAEAEAEAAABAEAEABABAEAEAEAEAEAEAENBNBIBAEAAAAMBMBPBMBMBPBAAAAAAAAAAAAAAAEAAAAAEAAMBMBMBMBMBMBMBMBMBAAABABABABMBMBMBMBMBMBMBMBMBMBMBAAMBMBMBAAMBMBMBMBMBMBMBMBABABMBMBMBMBMBAAMBMBMBMBMBMBMBMBMBAAABAAAAAAAEAEAEAEAEEBMBMBMBMBMBMBMBAEAEAEAEAEMBMBMBMBMBMBAEMBAEAAAAAAAAAEAEAEABAEAAAEAAABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAMBAAMBMBMBABMBMBMBAEMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMCMCMCMBMBMCMCAEMBMCMBMCMBMCMBMCMBMCMBMCMBMBMBMBMBMBAEMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBAAAAAAABAEGBGBGBGBGBAEGBGBIBIBABABMBMBMBMBMBMBMBMBMBMBMBMBMBAAMBMBMBMBMBMBMBMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEABMBMBMBMBABAEAAAEABAEABAAACAEABMBABMBMBAEACABABABAAAAAAAAAAABAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABAAAAAAAAAAAAAAMBMBABABAAAAAEAAAAAAAAAAAAABMBMBMBAAMBMBMBAAMBAAAAAAAAMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBABABABABABAAABAAAAAAAAABABABABAAABAEAAAEMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBAEAEAEAEAEMCAEAEMBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABABABABAAABABABABABAAABIBAAAAABABABAAAEABABABABABABABABABABABAAAAABABABABAAAEABAEAEAEAAAAAEAALBLBLBLBLBLBLBLBLBLBLBLBAEAEAEAAAEAEAEAAAAAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAEAAABAEAEABAEAELBAAAEAEAELBLBLBLBLBLBLBLBLBLBLBMBAEAEAEAAAEAAAEMBMBMBMBAEAEAEAEABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAEABAAABMCAAAAAAAAAEAAAEABAAMBABAAAAABABABABABABABABAAAAAAAEABAEAEAEAEAEABAEABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAMBMBMBMBMBMBMBMBMBMBAEMBAAMBMBMBMBMBMBMBAAAEAEMBMBMBAEMBAEMBMBMBMBAEMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBMBAEMBMBMBMBAEAEABAEAEAEAEABAEAEAEAEAAAAAAAEAAAAAEAEAEAEAEAEAEABAEAEAEAEAEABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAEAAAAAEAAAEAEAEAAAEAEAEAAABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABMBMBMBMBMBAAAAABAAAAAAAAAAAAAAAAAAABABABAAAAAAABABAAAAABABAAAAABABABABAAAAAAAAAAABAEABAEABABABAEAEABAEABAEAEAAAAAEABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAEABAAJBAEAEAEABABAEMBMBMBAAAAAAAEAEMBMBMBAEABABABABABABABABABABABABABABABABABABAAABAAAAAAABAAABABMBABABMBABMBMBABABABABABABABABABABABABABABABABABABABABABABABAAAEAEAEAEABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAAAAAAAAAAAEABABABABABABABABABABABABABABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABABABABABABABABABABABABABAEAAAEAAAEAEAAAEABABABAEAEAEAEABABABABABAAABAAABAAABABAEABABABAAABAAABMBAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABNBNBNBNBNBNBNBNBNBNCNCLCABNBNBNBAENBNBNBNBNBNBNCNCNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNCNCNBNBNBNBAAAAAAAAAAAAAAAEAENBNBNBNBNBNBNBNBNBNCNCNCNBNBNBNBNBNBABNBNBNBNCNCNCNBNBNBNBNBNBNBNBNBNCNCNCAAAEAENBABNBNBAANBNBNBNBNBNBNCNCNCAAAEAEAEAEAAAEAAAEMBMBABABABABABMBAEMBMBAEAEAEAAABAEAAAEAAAAAAAAABABAEAAAAAAAAABAAAEAEAAABABABABAAMBAEAAAEAEAEAEAAAAAAAAAAAAAEAEABABABABABABABABABAAAAAAAAAAABABABABABABABABAAAAAAAAAEAAAAAAAAAAAAAAAEAEAEAAAAAAAAAAAAAAABAAAAAEAEABAEAAAEAEAEAEAAAAAENBNBNBNBNBNBAENBNBNBNBNBAENBNBNBNBNBAANBNBAENBNBAENBNBNBNBAAAEAENBAANBNBNBNBNBNBAANBNBAENBNBAAAAAANBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBAANBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBABAEAENBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBAAAAAEAAAEAEAAABAAAAAAAAAAAAAAAANCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCOCNCNCNCNCNCNCOCOCOCOCOCOCOCOCNCNCNCNCNCNCOCOCOCOCOCOCOCOCNCNCNCNCNCNCOCOCOCOCOCOCOCOCNCNCNCNCNCNCOCOCOCOCOCOCOCOCNCNCNCNCNCNCOCOCOCOCOCOCOCOCNCNCNCNCNCNCOCOCOCOCOCOCOCOCNCNCNCNCNCNCOCOCOCOCOCOCOCOCNCNCNCNCNCNCOCOCOCOCOCOCOCOCNCNCNCNCNCNCOCOCOCOCOCOCOCOCNCNCNCNCNCNCOCOCOCOCOCOCOCOCNCNCNCNCNCNCOCOCOCOCOCOCOCOCNCNCNCNCNCNCOCOCOCOCOCOCOCOCNCNCNCNCNCNCOCOCOCOCOCOCOCOCNCNCNCNCNCNCOCOCOCOCOCOCOCOCNCNCNCNCNCNCOCOCOCOCOCOCOCOCNCNCNCNCNCNCOCOCOCOCOCOCOCOCNCNCNCNCNCNCOCOCOCOCOCOCOCOCNCNCNCNCNCNCOCOCOCOCOCOCOCOCNCNCNCNCNCNCOCOCOCOCOCOCOCOCNCNCNCNCNCNCOCOCOCOCOCOCOCOCNCNCNCNCNCNCOCOCOCOCOCOCOCOCNCNCNCNCNCNCOCOCOCOCOCOCOCOCNCNCNCNCNCNCOCOCOCOCOCOCOCOCAEAEAEAEAEAEAEAEAEAEAEAEABAEAEAEAEABAAABAAABAEABAAAAAEAEAEAEAAABAEAAAEAEAAAAAAAEAEABABAEAEABAEAEAAAEAEAEAEAAAEABAAAAAAAAAAAEAEAAAAAAAAAAAEAAAAAEAAAAABAEAAAAAEAAAAAAAEAAAAAAAAAAAAAAAEAAAAAEAEAEAAAAAAAAAEAEAEAEAAAAAAAEAEAEAEAEAAAAAAAAAAAAAAAAAAAEAEAEAEAEAEAEAEAEABABAEAEAEAAAEADADAEAENBNBAEAAAENBNBAENBAEAEAANBNBNBNBNBNBNBNBNBNBNBAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAENBNBNBABABAANBNBNBNBNBNBNBNBNBNBNBNBAAAEAEABAAAANBNBAAAAAAAAAAAANBAANBNBNBNBNBNCNCNCNBNBNBNBNBNBNBNBAANBNBAANBNBNBNBNBNBNCNBNCNCAANBAENBNBAENBNBNBAEABABAENBNBNBNBNBNBAENBNBNBNBNBNBAENBNBNBNBNBNBNBAENBNBNBNBNBNBNBNBNBAENBNBNBNBNBNBNBNBNBNBNBNBNBAANBNBNBAENBNBNBNBNCNCNCAENBNBNBNBNBNBNBNBNBNBNBNBNBAENBAENBAAAAAAAAAAAANBNBAAAANBAAAAAAAAAENBNBNBNBNBNBNBNBNBNBNCNCNCAAAAAAAENBAAAEAEAAMBMBAEAAAAAAAANBNBAEAENBNBAANBAAAANBAAAAAAAANBNBNBNBNBBCNBAAAAAAAAAAAANBAAAANBNBNBAAPBPBPBPBAENCNCNCNBNBNBNBNBNBNBNBAENBAENBNBNBPBPBPBPBNBNCNCABAEAEAAAENBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBAENBNBNBAENBNBNBNBPBNBPBPBPBNCNCNCAEAEAEAAAEAEAAAAPBNBNBNBNBAENBNBNBNBNBABAAAEAEAENBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBAENBNBNCNBNBNBNBNBNBABABAEAEAAAEAEAEAEAEAEAAAAAAJBABAAAENBNBNBNBNBNBNBNBNBNBNBAAAAAAAAAAAAAAAAAAAAAAAAAAABABAAAAAAABAAAAABAAABAENBNBNBNBNBNBNBAEAEPBPBPBPBNCNCNCNBNBNBNBNBAANBNBNBNBNBNBNBNBAENBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBPBNBNBNBNBNBPBPBPBNCAEAEAENBNBAENBNBNBNBNBNBNBNBNBNBNBNBNBAAABABNBNBNBNBNBAENBNBNBNBNBNBAENBNBNBABNBNBAANBNBNBNBNBNBAEABNBNBNBABAENBAANBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBABABABABABABABABABABABABAEAEAEAAABNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBAAAAAANBNBNBNBAEAEAENBAENBAANBNBNBNBAAAAAAAAAAAANBNBNBNBNBNBAANBAANBAENBAAAEAEAEABAENBNBNBAEAEAAAAAEAEAAAAAAAAABNCAAAANCNBNBNBNBNBAAMBABABAAAEAAAAABAAABAEAAAAAAAANBNBNBNBNBNBNBPBPBAEPBPBNCNCNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBPBPBPBPBNCNCNCNBNBNBNBNBNBNBNBNBNBAANBAEAEAAABAENBPBPBPBPBNCNCNCAANBABAANBNBNBNBNBNBNBNBNBNBNBNBNBNBNBPBPBPBPBNCNCNCAAAAAAAAAAAAAAAEAEAAABABNBAANBNBAENBNBABAANBNBNBNBNBNBAENBNBNBNBNBNBNBNBABABAAABABAEABNCNCNCNCNCNCNCABNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCPBNCNCNCPBNCNCPBNCNCNCNCNCNCPBNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNBABABNCNBNCNCNCNCNCNCNBNBABABABABAEAAABAAPCABAAAAAANBNBNBNBNBNBNBNBNBNBNBNBPBPBPBPBNCNCNCABABNBNBABABABAANBNBNBNBNBNBNBNBNBNBAEAAAEAEAEAEPBPBAAPBAEABNCNCNCBBBBBBBBBBBBABABABABABABABABABABABABAEAEAEAEAAAAAAAAAAAAAEAAAEAEAAABAAABABABAEAEAEAEAAAANBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBAANBNBNBNBNBNBNBNBNBNBNBNBNBNBAANBNBNBNBNBNBNBNBAANBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBAANBNBNBNBNBNBNBNBNBNBNBAANBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBABNBNBNBNBNBNBNBNBAANBNBNBNBNBNBNBAANBAANBNBNBNBAAAAAAAAAAAANBNBACAENBNBNBNBNBAAAAACNBNBNBNBNBNBAEAANBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBAEABNBABNBAENBNBNBNBNBNBNBNBNBNBABABABABAAAANBNBNBNBNBNBNBNBNBMBNBNBNBNBNBNBNBNBNBNBABNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBAAAAAANBNBNBAAAANBNBNBNBNBNBNBNBACNBNBNBABNBNBNBABAAAAAANBNBNBNBNBNBNBNBNBNBNBNBAANBNBNBAANBNBNBNBNBNBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAABABAAAANBABABABABABABABAANBAANBAAAAAAAAABABAEAAAAAEAAAAAAABABABABABABAAAAAABCAEABABPCAEAEAEAEAAAAAEAEAAAEAEAEABABABABABABABABABABABABACAAAEAAABAANBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBABABAAAAAAAAAAAAABABABAEABAEAAABAAABNCNCNCNCAAAAABAAAAABABABACNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCAANCAAAAAAAAAAAAAAAANCNCNCNCNCNCNCNCNCNCNCNCNCAAAAACAAAAAAABABABABABABABABABABABABABABAAAENBAAAAAAAAAEAAAAAAAEAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAELBAAAAAAAEAAAEBCAEAEAAAAAAAEAAAEAEAENBNBAANBNBNBNBNBNBNBNBNBNBNBAAABNBNBNBNBAEABABABABABABABAEAEAAAAABAAAAAEAEAAAEAEAEAAABAAAAAAAAAAAAAEAEAEABABABBBAAAAAAAAAAAAAAAAABABNCNCNCAAAAAAAAAAAAAAAEAEAAAAAAAAAEAEAAAAAENBAANBNBNBNBNBNBAEAEAEAEAEAEAAABAEABAEAEAEABABAAAAAAAEAEAEAAAAAEAAAAAAAAAAAAAAAAAAAAAEAAAEAEAEABAEABABABABABABABABABABABABABABABABAEAEAEAAAEAEAAAAAEAAAEAEAEAEABAAAAAAAAAEAEAEAAAEAEABAAAEAAAEAAABAEAEOBOBOBOBOBOBOBOBOBOBAAAAAAAAAAAAOBOBOBOBOBAEOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOBOBOBOBOBOBOBAAOBOBOBOBOBOBOBOBOBAAOBOBOBOBOBOBOBAAOBOBOBOBOBOBOBOBAEOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBAAOBAEOBOBOBOBOBOBOBOBNBNBNBOBOBOBOBOBOBOBOBNCNCNCNCNCNCOBOBOBOBOBOBOBOBOBOBOBOBAAOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBPBPBPBOBOBOBOBPBAAAAAAAEAAABAAAEAAAEAEAEAEAEAEAEAAAEABAEAENBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBAAAAAAAEPBPBPBPBPBPBPCPBPBPBPBPBPBAAAAAAAAAAAEAAABAAAAAAAAAAAAPBPBPBAAAAAAPBAAAAPBPBPBAEPBPBPBPBPBPBPBPCPBPBAEPBPBPBPBPBPBPBPBPBPBPBPBPBPBABPBPBPBPBPBPBPBPBPBPBAEAEAEPBAEAEPBPBPBPBPBPBPBPBPBPBPBPBPBPCPBPBABAAAAAAAAPBPBPBPBPBPBPBPBPBAAAEAAAAAAAEPBPBPBPBPCPBAAAEAEAEAEAAAEAEABAAABOBAEAAAEABABAEOBOBOBOBAAOBOBOBAAAAAAAAAAAAPBPBOBOBOBAAAAAAAAAAAAAAAAAAAAAAAAAAAEOBOBOBOBOBOBPBABAEOBOBOBOBOBOBOBPBOBAAAAOBAAOBPBOBPBPBPBPBPBPBPBPBPBPBPBPBOBPBOBPBPBPBOBPBPBPBOBOBOBOBOBPBPBPBAEPBPBPBPBPBPBPBPBPBOBOBOBOBOBOBAEOBOBOBOBOBOBOBOBOBOBOBOBAAOBOBOBOBOBOBOBOBAAOBOBOBOBOBOBOBOBOBOBPBPBAAPBOBPCPBOBNBABABNBOBOBOBOBNBNBNBNBNBNBACNBPBPBPBPBPBPBPBPBPBPBAAAAOBAEAAABBCOBBCAEAAAAAAPBPBAAPBPBPBAAPBAAPBAAAAAAAAPBPBPBPBAAAANBNBNBAAPBPBAEAEPBPBPBPBPBPBPBAAAAAAAAPBPBPBPBPBPBAAPBPBAAAAPBPBAEAAAAAAAAAEAEAEAEAEAEAEPBPBPBPBPBPBAAAAAAAAPBPBPBPBPBPBPBPBPBPBAEAEAAPBPBPBPBPBPBPBPBPBPBPBPBPBAEAEAEPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAEABAEAEAENBNBNBAENBNBAENBABNBAAAAAAAAAAAAAEAEAAAEABABABAAOBOBOBOBNBAANBNBNBAAAAAAAAAAAAAANBAEAAAAABAEAEAEAEAEAEAAAEPBPBPBPBAAPBOCOCNCNCNCPBABPBPBPBPCPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPCPBPBAAAEAEAEAEAAAAAAAAAAAAAEAEAAAAAAAAAAAAAAPBPBPBPBPBPBPCPBPBPBPBPBPBMBOBOBOBOBAAOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBAAOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBABOBOBOBOBABOBOBOBOBOBOBOBOBAAOBBCBCAABCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPBPBPBPBPBPBAEAAAAPBAAPBAAAAPBPBAAAAAAAAPBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPBPBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPBPBPBPCPBPBPBPBPBPBPBAAPBPBPBAAPBPBAAPBPBPBPCPBPBPBPBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPBPBPBPBPBPBPBPBPBPBPBPBPBPCPBAAPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPCPBPBPBPBPBAAPBPBPBPBPBPCPBPBPBPBPBPBPBNBNBNBNBPBNBPBPBPBPBPBPBPCPBPBPCPBAAAAAAAAAAAAAAAAPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPCPBPBPBPBPBPBPBPBPCPBPBPBPBPBNBLBAAAAAAAAAAAAAAPCPBAEPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAABAAAAAAAEPBPBAEPBPBPBPBPBPBAAPBPBPBPBPBPBAAPBAAPBPBPBPBPBPBPBPBPBPBPBAEPCPBPBPBPBPBPBPBAAAAAAPBPBPCABABABABABPBPBPBPBPBPBPBAAPBPBPBPBPBPBPBPBPBPBPBAAPBPBPBPBPBPBPBPBPBPCPBABABAAAAAAAAAEABAAAAPBAAPBPBNBPBABPBPBPBPBPBAAPBPBAAPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAAAAAAAAAAAPBAAPBAAPBPBPBPBPBPBPBPBAEPBPCPBPBPBPBPCPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAPBPBPBPBAEPBPBPBPBPBABPBAAAAAAAAAAAEABPBAEAAAAAAAAAAAAABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAEAEAEABAAAEAAAAAAAAAAAAAEABAAAAAAAAAAAAAAAAAAAAAAAAABAANCNCNCNCNCNCNCNCAEAAPBPBPBPBPBPBPBPBAEAAPBPBAEPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAAENCAEAAAEAEAEPCPCPCPCPCPCPCPCPCPBPBAEPBPBPBPBPBPBPBABABAANBNBNBNBAAAAAAAAAAAAAAAANCAAAAAAAAAAABAAABAAABABABABABABABABABABABABABAAAAAAAAAAAAAAABABABAAABABABABABABABABABAAAAAAAAAAAAABABABABABABNBABABABABABABAAAAAAAAAAAAAAABABABAAABABABAAABABABABABABAAAAAAAAAAAAABABABABABABABABABNCABNBABABAAAAAAAAAANBAAABABABABABABAAAAAAAAABABABAAAAAAAAAAJCAAAAABAAAAAAAAAAABABAAABAAAAAAAAAAAAAAAAAAAEABAAAAAAAAAAAAABABABAAAAABABABABAAAAABABABABAAAANCOCAEAAAEAEAANCNCNCOCOCOCOCOCOCOCOCABABABABAAAAABAAAAAEAEABABABABABABABAAAAAAAAABABAAAAABABABABABABABABAAAAAAAAABABABABAAAAABABABABAAAAABABABABABAAABABABABAAAAAAABABABABABAAAAABABABABAAAAABABABAAAAABABABABAAAAABABABABABAAAAABABAAAAAEABABAAAAABABABAAAAABABABAAAAABABABAAAAABABABABAAAAABABABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANCNCNCAENCNCAAAAABNBABABABAANCNCNCNCAEAEAEABABABABABAAAAABABABABAAAAAAAAABABABABAAAAABABABABAAAAABAEABAAAAAAAAAAPCABABABABABABAAAAAAAAAEAANCNCNCNCNCNBNBNBNBNBABABABABABABAEABABAAAAABABABABAAAAABABABABAAAAABABABABAAAAAAAAAAABABABAAAAABABABAAAAABABABAAAANCNCNCNCNCOCAANCAAAAAAAAAAAAAAAAAAAAAAPCAEAAAEAAAEAANCAEAAABABABABABABABABABAAAAABABABABAAAAABAAABABAAAAABABABABAAAAABABABAAAAABABABABAAAAAAABABABAAAAABABABABAAAAABABABAAAAABABABABAAAAABABABAAAAAAAEAAAAAAAEAEJBAANCNCNCNCNCNCNCNCNCNCNCNCNCNCAAAEAAAEAEAEAAAAAEAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAPCPCAAPCPCPCAAAEPCPCAEPCAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAABAAAEAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAEAEAAAAAAAANCNCAENCNCAAAANCNCNCNCNCAANCAAAANCAAAAAAAAAAAAAAAAAAAAAAAAAAAAOCOCOCOCAAOCOCOCOCAANCNCNCABAEAEABABABABABABABABABABABABABABABABABABABABABABABABAAAAABAAMBMBMBMBABABAAAAAAABACACACACAAAAAAAAAAAANCNCPCPCAAAEAAAEAEABABAAAAABABAAAAABABAAAAABABABAAAAABABABAAAAABABABAAAAABABABABABABABABAAAAABABABAAAAABABABABAAAAABABABABAAAAABABABAAAAABABABABAAAAABABABAAAAABABABABABAAABABABAAABABABABAAABABABABABABABABABABABABABABABAAAAABABABABABABABABABABABAAABAAABABABABABABABABABAAABABABAAAAABAAAAAAAAAAAAAANBAAOBOBOBOBOBOBOBAAABABABAAAAABABABABAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAABABABABABABABABABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANBNBABABABABNBNBAANBNBNBABABNBABABABAAAAABABAAAAABABAAAAAENBNBNBABABABABABABABABAAAAABABABAAAAABABABAAAAABABABAAAAABABABAAAAABABABABABAAAAABABAAAAABAANBNBABABAAAAABABABAAAAABABABAANBAAABABABAAAAABABABABAAAAABABABABAAAAABABABABAAAAABABNBABABAAAAABABABABAAAAABABABABAAAAABABABAAABAAAAABABABABAAAAABABABABAAAAABABABABAAAANCNCAAAAAAAAAAAAAAAANCNCNCNBAEAEABABABABAAAAABABABAAAAABABABABABAAAAABABABABAAAAABABABABAAAAABABABABABABABABABABABABABABABABABABABABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABABABABABABABABABABABABABABABABABABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANCAANCNCAAAAAAPCPCPCPCAEAEAEAEAEAEABPCABPCABABABABAAAAAAAAABABABAAABAAABABABABABAAAAAAAAAAABAAAAAAABABABABABAAABABABABABABABABABABABAEAEAAAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABABABABABABABABABABABABABABABABABABABABABABAEAAABABABABAAAAABABABABABABABABABABABABABAAABABABAAAAABABABAAAAABABABAAAAABABABAAAAAEABABABAAAAAEAAABABABAAAAABABABAAAAABABABAAAAABABABAAAAABABABAAAAABABABAAAAABABABAAAAABABABAAAAABABABABABABABABABABABABABABABABABABABABABABABABABAAAAABABABAAAAABABABAAAAABABABAAAANCNCNCNCNCNBABABABABABABAAAAABABABABAAAAABAAAAABAAAAABAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABABABAAAAABABABABAAAAAENBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANBAAAAAAAANBAEAAAAAEAEABABAAAAAAAAAAAAAAAAAAPCAAAAAAAAAAAEAENCABABABABABABABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAAAAAEAEAEABAAABABABAAAAABABABAAAAABABABAAAAAEAAABABABAAAAAAAAPCAAAEABABABABAAAAABABABABAAAAAAABABABAAAAAAABABABAAAAAAABABABAAAAAEAEAAAAAAAAAAAAPBPBPBPBPBPBPBABABABABABAAAAABABABAAAAABABABABAAAAAAAAAAABABABAAAAABABABAAAAABABABAAAAAAAAAAAAABABABAAAAABABABAAAAABABABAAAAAAAAABABABAAAAAAABABABAAAAAEABABABABABABABABABABABABABABABAEAAPCPCPCPCPCPCABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAEABABABABABABABABABABABABABABABABABABABABAEAAAAABABABABABABABABABABABABABABABABABABABABNCNCNCNCNCNCNCNCNCAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANBAANBNBNBNBAANBNBNBNBAEAEAAABAAAEAAAAAAAAAAAAAEAEAEAEOBOBOBOBOBOBOBOBOBOBOBOBAEOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBAEAEAEAEOBOBOBNBOBOBOBOBOBOBABABABAAAAAAOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBAAOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBAEOBOBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAEAAAAAAAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABABABABABABABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABAAPCPCPCPCABABAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAABABABABABABABABABABABABABABABABABABABABABABAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAABMBABMBMBABABMBMBABABMBMBABABMBAEPBAAAAAAABABAAAAAAABAEAEAAAAAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAENCNCNCNCNCABABAEAEAEAEAEABAEAEAEAAAAAEAEAEABAEAAAEABABABABAEAENBNBNBNBNBNBAENBNBAEAANBNBNBNBAANBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBAANBNBAANBNBNBNBOBAAAENBNBNBNBNBNBNBAEAEAAAEAEAAAAAAAAAAAAAEAAAAABAEAAAAAAAAAAAAAAAAAEAEAEAEABAENCNCNBNBOCOCNCNCNCNCAANCNCNCNCAENCNCNCNCNCNCNCAAAAAEAENCAENCAEAEAENBNBNBNBNBNBNBNBNBNBNBAEAEAEAEAAAAAAAAAAAAAEAEABAAABABABNBNBAAABNBNBNBNBNBAEAEAAABABABABAAAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABABABAAAAABNBAAAAAAAANBAAAAAAAANBAAAAAAAAAAAAAAAAAAAAAANBAAAAAAAAAAAANBAAAAAAAANBAAAAAAAAAAAAAAAAAAAAAAAAAANBNBNBNBNBNBNBNBNBNBAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANCNCNCNCNCNCNCAEAENCNCNCNCNCNCNCNCNCNCNCNCNCNCNCNCPCPCPBPCABAAAAAAAAAAAAPCABABABABAANBNBAAAAAAAAPCNCAAPCABAAAAAAAAAAAAAAABABPCAAABNCABPBAAPCAAABABABABABABABAEABAEAABCABABAAAAAAAAAAAAAEAAAEAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPBABAAAAAAAAAAAAAAAEPCPCAEAEABABAAAAPCAAAAAAAAAAAAAAAAPCPCPCPCPCPCPCABPCPCPCPCPCPCAAABAAABAAAAAAAAAAAAAAAAAEAEAEPCPCPCAAAEAEAAAAAAAAAAAAAAAAAAABABABABABABABABABABABABABABABABAAAAAAAAAAAAAAAAABAAAAAABCBCDCDCAAAAFCFCAEHCHCAEJCJCAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAEAEAEAAAEAAAAAAAEABAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAEPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAEPBAEABAAAAAAOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBAAAAAAAAAAOBOBOBOBOBNCOBOBOBNCNCOBAAAAAANCNCOBOBOBOBABOBOBOBOBOBOBOBOBOBAAOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBOBAAABABABABABABABAAABABAAABABABABAAAEAAAENCNCNCNCNCNCNCOBOBOBOBOBOBOBAEAEAAABAAPBPBPBPBPBPBPBPBPBAEPBAAPBAEPBPBPBPBPBPBPBAEAEPBABNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBAEAEABABABABABABABAAABABABABABABNBABABAAABABABAAABABABABABAAABAAAAABAAAAABAAAAABAAAAAAAAABABABABABABABABABABABABABABABABABABABABABABABABABABABABAAABABABABABABABAEAAABABABABABABABABABABABABABAAAAAAAAAAAAAAABABABABAEAAAAAAAAAAABABAAAAAAABAAABABABAAABABAAABABABABABABABABABABABAEAEAEABABABABABABABABABABABABABABABABABABABAAAAAAAAPCNCAEDCABDCABFCFCFCAEABAEABABABABAAABABABABAAAAABABAAAAAAABABABABABABABAEABABABABAEAAPCPCPCABABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAABABABABAAAAAEABABAEABABAEPCPCPCPCPCPCAAAAAAAAAAAEAEAEABABABAAAAAAAAAAAAAAAAPBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBAAAAAAAANBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBNBAAAAABABABABABABABABAAAAAAAAAAJBABABABAAAEAEABNCNCNCAANCNCNCNCNCNCACACACAAAEAAABAAAAAAAAAAAAABABABAEAAAAAAAAAAAAAAAAABABABAEAAAEAEAEAEAEAAAAABABABABABABABABABABAAABABABAAABAAAAAAABABPCNCAAAAAAABABABABABABABABABABABABABABABABABABABABAEABABABABABABABABABABABABABABABABABABABABABABABABAAABABABABABABABABABABABABABABABAAAAAAAAAAAAAEABAAABAAABABNBABABABABABABNBNBNBNBNBNBNBABAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANCAEAEAAAEAAAAAEPBPBPBPBPBPBAAPBPBNCNCNCNCNCNCNCNCNCNCNCNCAAAAAANCNCNCAANCNCNCNCABABNCAAAAAANCNCNCAAAAAAABABOCAEAAAAABNCAAABABAAABAAAAAAABABABAAAAAAABABABAAAAAAAAAAIBNCAANBNBNBAAABAANCNCNCAAAANBNBNBNBAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEABAAAAABAEAEABABABABAAAAAAAAAAABABAEABAAAAAEAAAEAEABABABAAAAAAAAABABABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABABAAAAAAAAABAAAAAAAAAAAAAAAAABABABABABAAAAAAAAAAAAABABABABABABABABABABABABABABABABAAAAAAAAAAAEPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAPBAAPBAAABABABABAAAEAAAAMBAAPCAAAAAAPCPCABABPBPBAAABABAAAAAAAAAAABAAAAAAPCPBAEAAAAAAABAAABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAABAEAAAAAEAAABAAAAAEABABABABABABABAEAAABABABAAAEAAAAAEAAAEAAAAAAAAAAABAAABABABABABABABABABABAAAAAAAEAAAEAEAEAEAEAEAEAEAEBBABABAAAAAAAAAAAEAEABAAAAABAAHCAAAAAAAAABAEABAAABAEABAEAAAAABAAAAAEAAABABPBPBPBPBPBAAAEAAAEAEAAPCPBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPBPCPBPBPBPBPBPBPBPBPBPBPBPBAAAEAEAAAAABABABPBPBPBNBPBPBPBPBPBPBPBPBPBPCPBPBPBPBPBPBPBPBPBPBNBNBNBNBNBPBPBNBNBPBPBNBPBPBPBPCPBPBPBPBAAAAAAAAABABABABABNBNBNBNBPBPBPBAAAAAAAAABPBAAAAAAAAAAAAAAAAAAPBPBPBNBNBPBNBPBNBPBNBPBNBNBNBNBNBNBNBPBNBPBPBPBPBPBABABABPBPBPBPBPBPCPBPBPBPBPBPBPBPBPBPCPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPCPBAAAAAEABAAAEPBPBPBPBPBPBPBPBAAPCPBPBPBPBPBPBPBPBPBPCPBPBPBPBPBPBPBPBPBPBPBPBPBPBPCPBPBPBPBPBPCAEPBPBPBPBAEPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPCPBPBPBPBPBPBPBPBPBPBPBPBPBPBPCPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAPBPBPCPBPBPBPBPBPBAAAAAAAAPBPCPBPBPBPBPBPBPBPBPBPBPBPBPCPBPBPBPBPBAAABPBPBPBPCPBABPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAPBAAPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAAAPBPBPBPCPCPCPCPCPCPCPCPCPCPCPCPCPCPCPCPCPCAEAEPBAAAAAAABAAAAABABABABABABABABABABPBPBABABABABABPBABABABAAPBAAAAAAAAAAPBAAPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAAAAAABAABCDCAAFCACHCABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAAPBAAPBAAAAAAAAAAAAAAAAAAPBPBPBAAPBPCAAPBAAAAPBPBPBPBPBPBPBAAABPBPBPBPBPBPBPBPBPBPBPCABABPBPBPCAAPBPBPBABABABABABABABABABABABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAACABAAAAAAAAAAAAAAAAAAAEAAAEAEAEAAAAAEAAAAAAAAABAAABAAAAABABAAAAAAAAAANCNCNCNCNCNCAEAEAEAEAAPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBNCNCNCNCNCNCAEAAABABPCABAAAAABPBPBPBPBPBPBPBPBPBPBPCABPBPBABAAAAAAAAAAAAAAPBPBPBAAAAAAPBPBPBPBABAEAAAAAAAAAEAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPCPBPBPBPBAAPBPBPBPBABABABPBPBAAPBAAPBPBPBABABABABABABABABABABABABABABABABABABABABABABABABPBPBPBPCPBAAAAAAAAAAPBABAAAAAAAAPBPBPBNBNBPBNCNCPBPBAAAAAAAAAAAAAAAEABABPBPCPBPBPBPBPBPBPBABPBPBAAPBPBAAPBPBAAABPBAAPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBABABAAAAAAPBPBPBPBPBPBPBPBPBPBPBPBABABPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAAAAAAAAAAAPBPBPBAAABABABABAAAAAAABAAABABABPBAAPBABPBPBPBPBPBPBPBPBPBPBPBPBPBAAPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBABPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBABPBAAAAPBPBAAAAAAAAAAAAPBPBPBPBNCAAAAAAAAAAAAAAAAAAAAAAAAAAAAPBPBPBPBPBPBPBPBPBABBBPBPBAAAAAAAAAAAAAAAAAAAAAEAAAEAAAAAEAAAAAAAAAAABAAAAAAAAAAAAAEAEAEAAAAAAAAAAAAAAAAAAAAAAAAAAABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABABABABABABABABABAAAAABABABABABABABABABABABABABAAAAAAAAAAAAAAAEAAAAABABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAABABABABABABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAEAAAAAAABABABABABABABABABABABAEAAAAAAAEAAAAAAAEAAAEAAABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAEABABAAPBPBPBPBPBPBPBPBPBPBPBPBPCPBPBPBPBPBPBPBABPBPBAAAAAAAAPBPBAAPBPBPBPBPBPBPBPBPBPBAAPBPBPBPBPBPBAAAEABABAEABABABAAAAABABABABABABABABABAAAAAAAAAAAEAAAAAAAEAAAEAEAEAAAAAAPBPBPBAAAAAAAAAEAAAAPBPBPBPBPBPBPBAAPBPBPBPBPBPBAAPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPCPBAAPBPBPBPBPBPBPBPBABABAAAAPBPCPBPBPBPBPBPBPBPBPBPBPBAAAAAAAAPBAAAAAAAAPBAAAAPBPBPBPBPBAAAAAAAAPBPBPBPBPBPBPBPBPBPBPBPCPBPBPBPBPBPBPBPBAAAAAAAAAAAAAAAAAAAAAAAAPBPBPBPBPBPBPBPBPBABABPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBABPBAAPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPCPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBABABPBPBPBABABPBPBPBPBPBPBPBPBPBPCPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPCPBPBPBPBPBPBPBPBPBPBPBPBPCPBPBPBPBPBPCPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPCPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAPBPBPBPBPBPBPBPBPBPBABPBPBPBPBPBAAPBAAPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAAAAAAAAAAAAAAAAAAAAAABAAAAAAPBPBPBPBPBPBPBPBPBPBAAAAABABABPBPBPBPBPBPBPBPBPBPBPCPCPCPCPCPCPCPCPBPCPCPCPCPCAAPCPCPCPCPCAAPCPCAAAAAAPCAAAAAAAAAAAAPCPCAAPCPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAAAPBAAPBPBPBAAAAPBAAAAPBAAAAAAAAAAAAAAPBAAPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAAAPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAPBPBPBPBAAAAAAPBAAAAAAAAAAAAAAAAAAAAPBAAAAAAPBPBPBAAPBPBAAAAAAPBPBPBPBPBAAPBAAAAAAAAAAAAAAAAAAAAPBAAPBPBPBPBAAAAAAPBPBPBPBPBPBPBPBPBPBAAAAAAAAAAAAAAAAAAAAAAAAPBPBAAPBAAPBPBPBPBPBAAAAAAAAAAAAAAAAAAAAPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAPBAAPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAAAAAPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAPBAAPBAAPBAAPBAAPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBPBAAAAAAAAAAPBAAAAAAPBPBAAPBAAPBPBAAPBAAPBPBAAAAAAPBAAAAAAAAAAAAAAAAAAAAPBAAPBAAPBPBAAPBAAPBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPBPBPBPBAAAAAAPBAAAAAAAAAAAAAAAAAAAAPBAAAAAAPBPBAAPBPBPBPBPBAAPBPBPBAAAAAAPBAAAAAAAAAAAAAAAAAAAAPBAAAAAAPBPBPBPBPBPBPBAAPBPBPBPBAAAAAAPBAAAAAAAAAAAAAAAAAAAAPBAAAAAAPBPBPBAAPBPBPBPBPBPBPBAAPBAAAAPBAAAAAAAAAAAAAAAAAAAAPBAAAAPBAAPBPBAAPBPBAAAAPBPBPBPBPBAAPBAAAAPBAAAAAAAAAAAAAAAAAAAAPBAAAAPBAAAAPBAAPBPBAAPBPBPBPBPBPBAAAAPBAAAAAAAAAAPBPBPBAAPBAAPBAAAAPBAAAAAAAAAAAAAAPBPBPBPBAAPBAAPBPBAAAAAAAAAAAAAAAAAAAAPBAAAAPBAAPBPBPBPBPBAAPBPBPBPBAAPBAAAAPBAAAAAAAAAAAAAAAAAAAAPBAAAAPBAAAAPBPBAAPBAAAAPBPBPBAAPBAAAAPBAAAAAAAAAAAAPBPBPBPBAAPBAAPBPBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPBAAAAAAAAAAAAAAAAPBAAAAPBPBAAAAPBAAPBAAAAPBAAPBPBPBPBAAAAPBAAAAAAAAAAAAAAAAAAAAPBAAPBAAPBAAPBAAAAPBAAAAAAAAAAAAAAAAAAAAPBAAAAPBAAAAPBPBPBPBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPBAAPBAAPBAAPBAAAAPBAAAAAAAAAAAAAAAAAAAAPBAAAAPBAAAAPBAAAAPBAAAAAAPBAAPBAAAAAAPBAAPBAAPBAAAAPBAAAAAAAAAAAAAAAAAAAAPBAAAAPBAAPBPBAAPBAAAAAAAAPBPBPBPBAAPBAAAAPBAAAAAAAAAAAAAAAAAAAAPBAAAAPBAAPBPBAAPBAAAAPBPBPBPBPBAAAAPBAAAAAAAAAAAAAAAAAAAAAAAAPBAAPBPBAAPBAAAAPBAAAAAAAAPBPBPBPBPBPBPBPBPBPBAAABAAAAAAABAAABAAABAAABAAABAAABAAPBAAPBAAPBAAPBAAPBAAPBAAPBAAAAPBPBPBPBPBPBPBAAABAAABAAAAAAPBAAPBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPBPBPBPBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPBPBPBPBPBPBPBPBPBPBAAAAAAPBPBAAPBPBPBPBPBAAAAPBPBPBPBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAABAAABAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANCAAAAAAPBPBPBPBPBPBPBPBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

-----------------------------------------

function Atr_GetBonding (itemID, vpstr)

	if (itemID == nil) then
		return 0;
	end

	-- temp patch for feasts
	if (itemID == 43015 or itemID == 34753 or itemID == 43480 or itemID == 43478) then
		return 0;
	end


	if (vpstr == nil) then
		vpstr = gAtr_MI;
	end

	local bonding = 0;		-- doesn't bind

	local x = ((itemID-1) * 2) + 2;
	
	if (x <= string.len (vpstr)) then

		local s = string.sub (vpstr, x, x);

		bonding = zc.dec64 (s);
	end

	return bonding;
end

-----------------------------------------

function Atr_DEReqLevel (itemID, vpstr)

	if (itemID == nil) then
		return 0;
	end

	if (vpstr == nil) then
		vpstr = gAtr_MI;
	end

	local reqlevel = 0;	

	local x = ((itemID-1) * 2) + 1;
	
	if (x <= string.len (vpstr)) then

		local s = string.sub (vpstr, x, x);

		local val = zc.dec64 (s);
		if (val == 1) then
			reqlevel = 1;
		else
			reqlevel = val * 25;
		end
	end

	return reqlevel;
end




-- Zirco's utilities

-- This module should contain no globals as it is intended to be "linked" in to each of Zirco's addons


local addonName, addonTable = ...; 
local zc = {};

addonTable.zc = zc;

-----------------------------------------

function zc.RGBtoHEX (r,g,b)

	local hex = "";
	
	return string.format ("%02x%02x%02x", r * 255, g * 255, b * 255);
 
end

-----------------------------------------

function zc.EnableDisable (elem, b)

	if (b) then
		elem:Enable();
	else
		elem:Disable();
	end
end

-----------------------------------------

function zc.ShowHide (elem, b)

	if (b) then
		elem:Show();
	else
		elem:Hide();
	end
end

-----------------------------------------

function zc.SetTextIf (elem, b, t1, t2)

	if (b) then
		elem:SetText(t1);
	else
		elem:SetText(t2);
	end
end

-----------------------------------------

function zc.Val (val, ifNilVal)

	if (val == nil) then
		return ifNilVal;
	end
	
	return val;
end

-----------------------------------------

function zc.Min (a, b)

	if (a == nil) then
		return b;
	end
	
	if (b == nil) then
		return a;
	end
	
	return math.min (tonumber (a), tonumber (b));
end

-----------------------------------------

function zc.Max (a, b)

	if (a == nil) then
		return b;
	end
	
	if (b == nil) then
		return a;
	end
	
	return math.max (tonumber (a), tonumber (b));
end

-----------------------------------------

function zc.If (b, x, y)

	if (b ~= nil and b ~= false) then
		return x;
	end
	
	return y;
end

-----------------------------------------

function zc.PrintKeysSorted (t)

	local ta = {};
	
	for a,v in pairs (t) do
		table.insert (ta, a);
	end

	table.sort (ta, function (a,b) return (a:lower() < b:lower()); end);

	for x = 1, #ta do
		zc.msg_pink (x.."   "..ta[x]);
	end

end

-----------------------------------------

function zc.UTF8_Truncate (s, newlen)

	if (s:len() <= newlen) then
		return s;
	end
	
	local x, c;
	
	for x = newlen, 1, -1 do
		
		c = s:byte(x+1);
		
		if (bit.band (c, 0xC0) == 0x80) then
			return s:sub (1, x-1);
		end
		
	end

end

-----------------------------------------

function zc.GetArrayElemOrFirst (a, x)

	if (a and #a > 0) then
		if (x == nil or x < 1 or x > #a) then
			x = 1;
		end
		
		return a[x];
	end

	return nil;
end

-----------------------------------------

function zc.GetArrayElemOrNil (a, x)

	if (a and #a > 0) then
		if (x == nil or x < 1 or x > #a) then
			return nil;
		end
		
		return a[x];
	end

	return nil;
end

-----------------------------------------

function zc.padstring (s, n, c)
	while (string.len (s) < n) do
		s = c..s;
	end
	
	return s;
end


-----------------------------------------

local encTable = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z", 
				  "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
				  "0","1","2","3","4","5","6","7","8","9",
				  "-", "_" };
				  

local decTable;

-----------------------------------------

local function BuildDecTable()

	if (decTable == nil) then
		decTable = {};
		local i;
		for i = 1,64 do
			decTable[encTable[i]] = i-1;
		end
	end

end

-----------------------------------------

function zc.enc64 (n)

	if (n == 0) then
		return encTable[1];
	end

	local k = n;
	local x;
	local result = "";
	
	while k ~= 0 do
		x = bit.band (k, 63);
		result = encTable[x+1]..result;
		k = bit.rshift (k, 6);
	end

	return result;
end

-----------------------------------------

function zc.dec64 (s)

	if (s == nil or s == "") then
		return 0;
	end

	BuildDecTable();

	local result = 0;
	local len = string.len (s);
	local x;
	
	for x = 1, len do
		result = result * 64;
		result = result + decTable[string.sub(s,x,x)];
	end
	
	return result;
end

-----------------------------------------

function ZF (s)
	BuildDecTable();

	local s2 = "";
	local n;
	
	for n = 1, s:len() do
		local c = s:sub(n,n);
		local x = decTable[c];
		
		if (x == nil) then
			s2 = s2..c;
		else
			if		(x < 32) then x = x + 32;
			else	x = x - 32;
			end;
			s2 = s2..encTable[x+1];
		end
	end

	return s2;

end

-----------------------------------------

function zc.words(str)
	local t = {}
	local function helper(word) table.insert(t, word) return "" end
	if (not str:gsub("%w+", helper):find"%S") then
		if (#t == 1) then return t[1]; end;	
		if (#t == 2) then return t[1],t[2]; end;	
		if (#t == 3) then return t[1],t[2],t[3]; end;	
		if (#t == 4) then return t[1],t[2],t[3],t[4]; end;
		if (#t == 5) then return t[1],t[2],t[3],t[4],t[5]; end;
		return t;
	end
end

-----------------------------------------

local gDeferredCalls = {};

-----------------------------------------

function zc.AddDeferredCall (seconds, funcname, param1, param2, tag)	-- tag is optional.  if present used to overwrite prior call with same tag

	local now = time();

	local cfdEntry = {};

	cfdEntry.funcname	= funcname;
	cfdEntry.param1		= param1;
	cfdEntry.param2		= param2;
	cfdEntry.when		= now + seconds;
	cfdEntry.tag		= "";
	
	if (tag) then
		cfdEntry.tag = tag;

		for i = 1, #gDeferredCalls do
			if (gDeferredCalls[i].tag == tag) then
				gDeferredCalls[i] = cfdEntry;		-- overwrite
				return;
			end
		end
	end

	table.insert (gDeferredCalls, cfdEntry);
end


-----------------------------------------

function zc.CheckDeferredCall ()

	local now = time();
	local i;
	
	for i = 1, #gDeferredCalls do
		if (gDeferredCalls[i].when < now) then
			local fcn = getglobal(gDeferredCalls[i].funcname);
			local p1 = gDeferredCalls[i].param1;
			local p2 = gDeferredCalls[i].param2;
			table.remove (gDeferredCalls, i);
			if (type(fcn) == 'function') then
				fcn(p1, p2);
			end
			
			return;		-- only do one
		end
	end

end

-----------------------------------------

function zc.periodic (elem, name, period, elapsed)
	
	local t = elem[name] or 0;
	
	t = t + elapsed;
	
	if (t > period) then
		elem[name] = 0;
		return true;
	end
	
	elem[name] = t;
	return false;
end
	

-----------------------------------------

function zc.tableIsEmpty (t)

	local n, v;
	for n, v in pairs (t) do
		return false;
	end
	
	return true;
end

-----------------------------------------

function zc.PrintTable (t, indent)

	if (not indent) then
		indent = 0;
	end
	
	local x
	local padding = "";
	for x = 1,indent do
		padding = padding.."  ";
	end

	zc.msg ("-------");
	
	for n, v in pairs (t) do
		if (type(v) == "table") then
			zc.msg (padding..n, "TABLE");
			zc.PrintTable(v, indent+1);
		elseif (type(v) == "userdata") then
			zc.msg (padding..n, "userdata");
		else
			zc.msg (padding..n, v);
		end
	end

end

-----------------------------------------

function zc.ItemIDfromLink (itemLink)

	if (itemLink == nil) then
		return 0,0,0;
	end
	
	local found, _, itemString = string.find(itemLink, "^|c%x+|H(.+)|h%[.*%]")
	local _, itemId, _, _, _, _, _, suffixId, uniqueId = strsplit(":", itemString)

	return itemId, suffixId, uniqueId;

end

-----------------------------------------

function zc.BoolToString (b)
	if (b) then
		return "true";
	end

	return "false";
end

-----------------------------------------

function zc.BoolToNum (b)
	if (b) then
		return 1;
	end

	return 0;
end

-----------------------------------------

function zc.NumToBool (n)
	if (n == 0) then
		return false;
	end

	return true;
end

-----------------------------------------

function zc.pluralizeIf (word, count)

	if (count and count == 1) then
		return word;
	else
		return zc.pluralize(word);
	end
end

-----------------------------------------

function zc.pluralize (word)

	return word.."s";

end

-----------------------------------------

function zc.round (v)
	return math.floor (v + 0.5);
end

-----------------------------------------

function zc.msg_red (...)		zc.msg_color (1,  0,  0, ...);	end
function zc.msg_pink (...)		zc.msg_color (1, .6, .6, ...);	end
function zc.msg_yellow (...)		zc.msg_color (1,  1,  0, ...);	end

-----------------------------------------

function zc.msg_color (r, g, b, ...)

	local options = {};
	options.r = r;
	options.g = g;
	options.b = b;
	
	zc.msg_ex (options, ...);
end


-----------------------------------------

function zc.msg_str (...)

	local options = {};
	options.str = true;
	
	return zc.msg_ex (options, ...);
end

-----------------------------------------

function zc.msg_atr (...)

	zc.msg_yellow ("|cff00ffff<Auctionator>|r", ...);
end


-----------------------------------------

function zc.HSV2RGB (h, s, v)

	local r, g, b;
	
	local hi = math.floor(h/60) % 6;
	local f  = h/60 - math.floor(h/60);
	local p  = v * (1-s);
	local q  = v * (1-(f*s));
	local t  = v * (1-((1-f)*s));
	
	if (hi == 0) then	return v, t, p;			end
	if (hi == 1) then	return q, v, p;			end
	if (hi == 2) then	return p, v, t;			end
	if (hi == 3) then	return p, q, v;			end
	if (hi == 4) then	return t, p, v;			end
	if (hi == 5) then	return v, p, q;			end
	
	return 
end

-----------------------------------------

function zc.md (...)

	if (Atr_IsDev) then

		local funcnames = zc.printstack ( { silent=true } );

		local fname = string.lower (funcnames[2]);

		if (zc.StringStartsWith (fname, "atr_")) then
			fname = fname:sub (5);
		end

		local color = "ffffff";

		local n = fname:len();

		if (n > 3) then

			local x = fname:byte(math.floor (n/2)) - string.byte("a");
			local y = fname:byte(n) - string.byte("a");
			
			local hue = 0;
			if (x > 0) then
				hue = math.floor ( (x/26) * 360 );
			end
			
			local sat = 0.5;
			if (y > 0) then
				sat = 0.3 + (y/26) * 0.7;
			end
			
			local r, g, b = zc.HSV2RGB (hue, sat, 1);
			
			r = math.floor (r * 255);
			g = math.floor (g * 255);
			b = math.floor (b * 255);
			
--			zc.msg (hue, sat, r, g, b);
			color = string.format ("%02x%02x%02x", r, g, b);
		end
		
		zc.msg ("|cff00ffff<".."|cff"..color..fname.."|cff00ffff>|r", ...);
	end
end

-----------------------------------------

function zc.msg (...)

	local options = {};
	
	zc.msg_ex (options, ...);
end

-----------------------------------------

function zc.msg_ex (options, ...)

	if (not DEFAULT_CHAT_FRAME) then
		return;
	end

	local msg = "";

	local i;
	local num = select("#", ...);
	
	for i = 1, num do
	
		local v = select (i, ...);

		if		(type(v) == "boolean")	then	m = zc.BoolToString(v);
		elseif	(type(v) == "table")	then	m = "<table>";
		elseif	(type(v) == "function")	then	m = "<function>";
		elseif	(v == nil)				then	m = "<nil>";
		else									m = v;
		end

		msg = msg.." "..m;

	end

	if (options.str) then
		return msg;
	end

	if (options.r ~= nil) then
		DEFAULT_CHAT_FRAME:AddMessage (msg, options.r, options.g, options.b);
	else
		DEFAULT_CHAT_FRAME:AddMessage (msg);
	end
end



-----------------------------------------

function zc.val2gsc (v)
	local rv = zc.round(v)

	local g = math.floor (rv/10000);

	rv = rv - g*10000;

	local s = math.floor (rv/100);

	rv = rv - s*100;

	local c = rv;

	return g, s, c
end

-----------------------------------------

function zc.priceToString (val)

	local gold, silver, copper  = zc.val2gsc(val);

	local st = "";


	if (gold ~= 0) then
		st = gold.."g ";
	end


	if (st ~= "") then
		st = st..format("%02is ", silver);
	elseif (silver ~= 0) then
		st = st..silver.."s ";
	end


	if (st ~= "") then
		st = st..format("%02ic", copper);
	elseif (copper ~= 0) then
		st = st..copper.."c";
	end

	return st;
end

-----------------------------------------

local goldicon		= "|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:4:0|t"
local silvericon	= "|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:4:0|t"
local coppericon	= "|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:4:0|t"

-----------------------------------------

function zc.priceToMoneyString (val, noZeroCoppers)

	local gold, silver, copper  = zc.val2gsc(val);

	local st = "";

	if (gold ~= 0) then
		st = gold..goldicon.."  ";
	end


	if (st ~= "") then
		st = st..format("%02i%s  ", silver, silvericon);
	elseif (silver ~= 0) then
		st = st..silver..silvericon.."  ";
	end

	if (noZeroCoppers and copper == 0) then
		return st;
	end

	if (st ~= "") then
		st = st..format("%02i%s", copper, coppericon);
	elseif (copper ~= 0) then
		st = st..copper..coppericon;
	end

	return st;

end

-----------------------------------------

function zc.StringSame (s1, s2)
	if (s1 == nil and s2 == nil) then
		return true;
	end
	
	if (s1 == nil or s2 == nil) then
		return false;
	end

	if (s1 == s2) then		-- maybe will fix german umlaut problem?
		return true;
	end

	return (string.lower (s1) == string.lower (s2));
end

-----------------------------------------

function zc.StringContains (s, sub)
	if (sub == nil or sub == "") then
		return false;
	end

	local start, stop = string.find (string.lower(s), string.lower(sub), 1, true);

	return (start ~= nil);
end

-----------------------------------------

function zc.StringEndsWith (s, sub)

	if (sub == nil or sub == "") then
		return false;
	end

	local i = string.len(s) - string.len(sub);

	if (i < 0) then
		return false;
	end

	local sEnd = string.sub (s, i+1);

	return (string.lower (sEnd) == string.lower (sub));

end

-----------------------------------------

function zc.StringStartsWith (s, sub)

	if (s == nil or sub == nil or sub == "") then
		return false;
	end

	local sublen = string.len (sub);

	if (string.len (s) < sublen) then
		return false;
	end

	return (string.lower (string.sub(s, 1, sublen)) == string.lower(sub));

end

-----------------------------------------

function zc.CopyDeep (src)

	local result = {};

	for n, v in pairs (src) do
		if (type(v) == "table") then
			result[n] = zc.CopyDeep(v);
		else
			result[n] = v;
		end
	end

	return result;

end

-----------------------------------------

function zc.printableLink (link)

	if (link == nil) then
		return "nil";
	end
	
	local printable = gsub(link, "\124", "\124\124");

	return printable;
end

-----------------------------------------

function zc.printmem ()

	local cmem = math.floor(collectgarbage ("count"))
	
	UpdateAddOnMemoryUsage();
	local mem = GetAddOnMemoryUsage("Auctionator");
	zc.msg_atr (math.floor(mem).." KB  (total LUA: "..cmem.." KB)");
end

-----------------------------------------

function zc.printstack (options)

	local cstr		= "";
	local funcnames	= {};
	
	if (options == nil) then
		options = {};
	end

	if (options.prefix) then
		cstr = options.prefix;
	end

	local s = debugstack (2);

	local lines = { strsplit("\n", s) };

	local x = 1;

	local v;
	for a,v in pairs(lines) do

		local filename = nil;
		local funcname = nil;

		local a,b = string.find (v, "\\[^\\]*:");

		if (a) then
			filename = string.sub (v,a+1,b-1);
			filename = string.gsub (filename, "\.lua", "");
		end

		local a,b = string.find (v, "in function `.*\'");
		if (a) then
			funcname = string.sub (v,a+13,b-1);
			table.insert (funcnames, funcname);
		end

		if (options.verbose) then
			if (filename ~= nil and funcname ~= nil) then
				local colwid = math.floor((100 - string.len(funcname)) / 2);
				local fs = "%-"..colwid.."s (%s)";
				zc.msg_color (.5, 1, .5, string.format (fs, funcname, filename));
			else
				zc.msg (v);
			end
		elseif (not options.silent) then
			if (funcname) then
				if (x == 2) then
					cstr = cstr.." > |cFFFFaa88"..funcname;
				else
					cstr = cstr.." > "..funcname;
				end
				x = x + 1;
			end
		end
	end

	if (not options.verbose and not options.silent) then
		zc.msg (cstr);
	end

	return funcnames;

end



-----------------------------------------

function zc.tallyAdd (ttable, value)

	if (ttable[value]) then
		ttable[value] = ttable[value] + 1;
	else
		ttable[value] = 1;
	end
end


-----------------------------------------

function zc.tallyPrint (ttable, options)

	local sortedTable = {};
	local total = 0;
	
	local n = 1;
	for value,count in pairs(ttable) do
		
		sortedTable[n] = {};
		sortedTable[n].value	= value;
		sortedTable[n].count	= count;
		
		total = total + count;
		
		n = n + 1;
	end


	if		(options.sortByValue and options.sortDesc) then			table.sort (sortedTable, function(x,y) return x.value > y.value; end);
	elseif	(options.sortByValue and not options.sortDesc) then		table.sort (sortedTable, function(x,y) return x.value < y.value; end);
	elseif	(options.sortDesc) then									table.sort (sortedTable, function(x,y) return x.count > y.count; end);
	else															table.sort (sortedTable, function(x,y) return x.count < y.count; end);
	end
	
	
	for n = 1, #sortedTable do
		
		if (not options.printCount or n < options.printCount) then
			zc.msg_pink (sortedTable[n].count.."    "..sortedTable[n].value);
		end
	end
	
	zc.msg_yellow ("Total: "..total);
end

-- Auctionator Buy All: buys all matching stacks at selected price/stack size (ignores the popup's "number")
do
  if _G["Auctionator_BuyAll_Attached"] then return end
  Auctionator_BuyAll_Attached = true

  local candidates = {
    "Atr_Buy_Confirm_OKBut","Atr_Buy_Confirm_OK","Atr_Buy_Confirm_YesBut","Atr_Buy_Confirm_OKBtn","AtrBuyConfirmBuyButton",
    "Atr_Buy1_Button","Atr_BuyButton","AuctionatorBuy_BuyoutButton","AuctionFrameBrowse_BuyoutButton","AuctionBuyButton"
  }

  local function BuyAll_OnClick()
    if not gCurrentPane or not gCurrentPane.currIndex or not gCurrentPane.activeScan then
      print("|cffff4444Auctionator Buy All|r: Please select an auction line (not summary/group)!")
      return
    end
    local scan = gCurrentPane.activeScan
    local offset = FauxScrollFrame_GetOffset(AuctionatorScrollFrame) or 0
    local dataIndex = offset + (gCurrentPane.currIndex or 0)
    local entry = scan.sortedData and scan.sortedData[dataIndex]
    if not entry or not entry.itemName or not entry.buyoutPrice or not entry.stackSize then
      print("DEBUG: entry=", entry and entry.itemName or "nil", entry and entry.buyoutPrice or "nil", entry and entry.stackSize or "nil")
      print("|cffff4444Auctionator Buy All|r: Could not read entry info. Try clicking a specific auction row.")
      return
    end
    local itemName, buyoutPrice, stackSize = entry.itemName, entry.buyoutPrice, entry.stackSize
    local bought, totalItems, totalSpent = 0, 0, 0
    local num = GetNumAuctionItems("list")
    for i = 1, num do
      local name, _, count, _, _, _, _, _, price = GetAuctionItemInfo("list", i)
      -- Buy ALL matching stacks at selected price/stack size
      if name == itemName and price == buyoutPrice and count == stackSize and price > 0 then
        PlaceAuctionBid("list", i, price)
        bought = bought + 1
        totalItems = totalItems + count
        totalSpent = totalSpent + price
      end
    end
    if bought > 0 then
      print(string.format("|cff44ee44Auctionator Buy All|r: Bought %d stacks (%d items) at %s.", bought, totalItems, GetCoinTextureString(buyoutPrice)))
    else
      print("|cffff4444Auctionator Buy All|r: No matching stacks found at this price/stack size.")
    end
  end

  local function MakeBuyAllButton(anchorButton)
    if not anchorButton or not anchorButton.IsShown or not anchorButton:IsShown() then return nil end
    if _G["Auctionator_BuyAll_Button"] and _G["Auctionator_BuyAll_Button"]:GetParent() == anchorButton:GetParent() then
      local btn = _G["Auctionator_BuyAll_Button"]
      btn:ClearAllPoints()
      btn:SetPoint("LEFT", anchorButton, "RIGHT", 8, 0)
      btn:Show()
      return btn
    end
    local parent = anchorButton:GetParent() or UIParent
    local btn = CreateFrame("Button", "Auctionator_BuyAll_Button", parent, "UIPanelButtonTemplate")
    btn:SetSize(90, 22)
    btn:SetText("BUY ALL")
    btn:SetScript("OnClick", BuyAll_OnClick)
    btn:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:AddLine("Buy ALL auctions at this price/stack size!", 1,1,1)
      GameTooltip:AddLine("Buys every identical stack in AH.", 1,1,1)
      GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    btn:ClearAllPoints()
    btn:SetPoint("LEFT", anchorButton, "RIGHT", 8, 0)
    btn:Show()
    return btn
  end

  local poller = CreateFrame("Frame")
  poller:SetScript("OnUpdate", function(self, elapsed)
    if AuctionFrame and AuctionFrame:IsShown() and Atr_IsTabSelected and Atr_IsTabSelected(3) then
      for _, name in ipairs(candidates) do
        local obj = _G[name]
        if obj and obj.IsShown and obj:IsShown() then
          MakeBuyAllButton(obj)
          return
        end
      end
      if _G["Auctionator_BuyAll_Button"] then _G["Auctionator_BuyAll_Button"]:Hide() end
    else
      if _G["Auctionator_BuyAll_Button"] then _G["Auctionator_BuyAll_Button"]:Hide() end
    end
  end)
end

AuctionatorVersion = "???";		-- set from toc upon loading
AuctionatorAuthor  = "Zirco";

local AuctionatorLoaded = false;
local AuctionatorInited = false;

local addonName, addonTable = ...; 
local zc = addonTable.zc;

gAtrZC = addonTable.zc;		-- share with AuctionatorDev


-----------------------------------------

local recommendElements			= {};

AUCTIONATOR_ENABLE_ALT		= 1;
AUCTIONATOR_OPEN_ALL_BAGS	= 1;
AUCTIONATOR_SHOW_ST_PRICE	= 0;
AUCTIONATOR_SHOW_TIPS		= 1;
AUCTIONATOR_DEF_DURATION	= "N";		-- none
AUCTIONATOR_V_TIPS			= 1;
AUCTIONATOR_A_TIPS			= 1;
AUCTIONATOR_D_TIPS			= 1;
AUCTIONATOR_SHIFT_TIPS		= 1;
AUCTIONATOR_DE_DETAILS_TIPS	= 4;		-- off by default
AUCTIONATOR_DEFTAB			= 1;

AUCTIONATOR_OPEN_FIRST		= 0;	-- obsolete - just needed for migration
AUCTIONATOR_OPEN_BUY		= 0;	-- obsolete - just needed for migration

local SELL_TAB		= 1;
local MORE_TAB		= 2;
local BUY_TAB 		= 3;

local MODE_LIST_ACTIVE	= 1;
local MODE_LIST_ALL		= 2;


-- saved variables - amounts to undercut

local auctionator_savedvars_defaults =
	{
	["_5000000"]			= 10000;	-- amount to undercut buyouts over 500 gold
	["_1000000"]			= 2500;
	["_200000"]				= 1000;
	["_50000"]				= 500;
	["_10000"]				= 200;
	["_2000"]				= 100;
	["_500"]				= 5;
	["STARTING_DISCOUNT"]	= 5;	-- PERCENT
	};


-----------------------------------------

local auctionator_orig_AuctionFrameTab_OnClick;
local auctionator_orig_ContainerFrameItemButton_OnModifiedClick;
local auctionator_orig_AuctionFrameAuctions_Update;
local auctionator_orig_CanShowRightUIPanel;
local auctionator_orig_ChatEdit_InsertLink;
local auctionator_orig_ChatFrame_OnEvent;
local auctionator_orig_FriendsFrame_OnEvent;

local gForceMsgAreaUpdate = true;
local gAtr_ClickAuctionSell = false;

local gOpenAllBags  	= AUCTIONATOR_OPEN_ALL_BAGS;
local gTimeZero;
local gTimeTightZero;

local cslots = {};
local gEmptyBScached = nil;

local gAutoSingleton = 0;

local gJustPosted_ItemName = nil;		-- set to the last item posted, even after the posting so that message and icon can be displayed
local gJustPosted_ItemLink;
local gJustPosted_BuyoutPrice;
local gJustPosted_StackSize;
local gJustPosted_NumInBagsAtStart;
local gJustPosted_NumStacks;

local auctionator_pending_message = nil;

local kBagIDs = {};

local Atr_Confirm_Proc_Yes = nil;

local gStartingTime			= time();
local gHentryTryAgain		= nil;
local gCondensedThisSession = {};

local ITEM_HIST_NUM_LINES = 20;

local gActiveAuctions = {};

local gHlistNeedsUpdate = false;

local gSellPane;
local gMorePane;
local gActivePane;
local gShopPane;

local gCurrentPane;

local gHistoryItemList = {};

local ATR_CACT_NULL							= 0;
local ATR_CACT_READY						= 1;
local ATR_CACT_PROCESSING					= 2;
local ATR_CACT_WAITING_ON_CANCEL_CONFIRM	= 3;


local gItemPostingInProgress = false;
local gQuietWho = 0;
local gSendZoneMsgs = false;

gAtr_ptime = nil;		-- a more precise timer but may not be updated very frequently

gAtr_ScanDB			= nil;
gAtr_PriceHistDB	= nil;

-----------------------------------------

ATR_SK_GLYPHS		= "*_glyphs";
ATR_SK_GEMS_CUT		= "*_gemscut";
ATR_SK_GEMS_UNCUT	= "*_gemsuncut";
ATR_SK_ITEM_ENH		= "*_itemenh";
ATR_SK_POT_ELIX		= "*_potelix";
ATR_SK_FLASKS		= "*_flasks";
ATR_SK_HERBS		= "*_herbs";     

-----------------------------------------

local roundPriceDown, ToTightTime, FromTightTime, monthDay;

-----------------------------------------

function Atr_RegisterEvents(self)

	self:RegisterEvent("VARIABLES_LOADED");
	self:RegisterEvent("ADDON_LOADED");
	
	self:RegisterEvent("AUCTION_ITEM_LIST_UPDATE");
	self:RegisterEvent("AUCTION_OWNED_LIST_UPDATE");

	self:RegisterEvent("AUCTION_MULTISELL_START");
	self:RegisterEvent("AUCTION_MULTISELL_UPDATE");
	self:RegisterEvent("AUCTION_MULTISELL_FAILURE");

	self:RegisterEvent("AUCTION_HOUSE_SHOW");
	self:RegisterEvent("AUCTION_HOUSE_CLOSED");

	self:RegisterEvent("NEW_AUCTION_UPDATE");
	self:RegisterEvent("CHAT_MSG_ADDON");
	self:RegisterEvent("WHO_LIST_UPDATE");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
			
end

-----------------------------------------

function Atr_EventHandler()

--	zc.md (event);

	if (event == "VARIABLES_LOADED")			then	Atr_OnLoad(); 					end;
	if (event == "ADDON_LOADED")				then	Atr_OnAddonLoaded(); 			end;
	if (event == "AUCTION_ITEM_LIST_UPDATE")	then	Atr_OnAuctionUpdate(); 			end;
	if (event == "AUCTION_OWNED_LIST_UPDATE")	then	Atr_OnAuctionOwnedUpdate(); 	end;
	
	if (event == "AUCTION_MULTISELL_START")		then	Atr_OnAuctionMultiSellStart(); 	end;
	if (event == "AUCTION_MULTISELL_UPDATE")	then	Atr_OnAuctionMultiSellUpdate(); end;
	if (event == "AUCTION_MULTISELL_FAILURE")	then	Atr_OnAuctionMultiSellFailure(); end;

	if (event == "AUCTION_HOUSE_SHOW")			then	Atr_OnAuctionHouseShow(); 		end;
	if (event == "AUCTION_HOUSE_CLOSED")		then	Atr_OnAuctionHouseClosed(); 	end;
	if (event == "NEW_AUCTION_UPDATE")			then	Atr_OnNewAuctionUpdate(); 		end;
	if (event == "CHAT_MSG_ADDON")				then	Atr_OnChatMsgAddon(); 			end;
	if (event == "WHO_LIST_UPDATE")				then	Atr_OnWhoListUpdate(); 			end;
	if (event == "PLAYER_ENTERING_WORLD")		then	Atr_OnPlayerEnteringWorld(); 	end;

end

-----------------------------------------

function Atr_SetupHookFunctionsEarly ()

	auctionator_orig_FriendsFrame_OnEvent = FriendsFrame_OnEvent;
	FriendsFrame_OnEvent = Atr_FriendsFrame_OnEvent;

	Atr_Hook_OnTooltipAddMoney ();
	
end


-----------------------------------------

function Atr_SetupHookFunctions ()

	auctionator_orig_AuctionFrameTab_OnClick = AuctionFrameTab_OnClick;
	AuctionFrameTab_OnClick = Atr_AuctionFrameTab_OnClick;

	auctionator_orig_ContainerFrameItemButton_OnModifiedClick = ContainerFrameItemButton_OnModifiedClick;
	ContainerFrameItemButton_OnModifiedClick = Atr_ContainerFrameItemButton_OnModifiedClick;

	auctionator_orig_AuctionFrameAuctions_Update = AuctionFrameAuctions_Update;
	AuctionFrameAuctions_Update = Atr_AuctionFrameAuctions_Update;

	auctionator_orig_CanShowRightUIPanel = CanShowRightUIPanel;
	CanShowRightUIPanel = auctionator_CanShowRightUIPanel;
	
	auctionator_orig_ChatEdit_InsertLink = ChatEdit_InsertLink;
	ChatEdit_InsertLink = auctionator_ChatEdit_InsertLink;
	
	auctionator_orig_ChatFrame_OnEvent = ChatFrame_OnEvent;
	ChatFrame_OnEvent = auctionator_ChatFrame_OnEvent;
	
--	auctionator_orig_AuctionFrameBrowse_Update = AuctionFrameBrowse_Update;
--	AuctionFrameBrowse_Update = auctionator_AuctionFrameBrowse_Update;
end

-----------------------------------------

local gItemLinkCache = {};
local gA2IC_prevName = "";

-----------------------------------------

function Atr_AddToItemLinkCache (itemName, itemLink)

	if (itemName == gA2IC_prevName) then		-- for performance reasons only
		return;
	end

	gA2IC_prevName = itemName;

	gItemLinkCache[string.lower(itemName)] = itemLink;
end

-----------------------------------------

function Atr_GetItemLink (itemName)
	if (itemName == nil or itemName == "") then
		return nil;
	end
	
	local itemLink = gItemLinkCache[string.lower(itemName)];
	
	if (itemLink == nil) then
		_, itemLink = GetItemInfo (itemName);
		if (itemLink) then
			Atr_AddToItemLinkCache (itemName, itemLink);
		end
	end
	
	return itemLink;

end

-----------------------------------------

local checkVerString		= nil;
local versionReminderCalled	= false;	-- make sure we don't bug user more than once

-----------------------------------------

local function CheckVersion (verString)
	
	if (checkVerString == nil) then
		checkVerString = AuctionatorVersion;
	end
	
	local a,b,c = strsplit (".", verString);

	if (tonumber(a) == nil or tonumber(b) == nil or tonumber(c) == nil) then
		return false;
	end
	
	if (verString > checkVerString) then
		checkVerString = verString;
		return true;	-- out of date
	end
	
	return false;
end

-----------------------------------------

function Atr_VersionReminder ()
	if (not versionReminderCalled) then
		versionReminderCalled = true;

		zc.msg_atr (ZT("There is a more recent version of Auctionator: VERSION").." "..checkVerString);
	end
end



-----------------------------------------

local VREQ_sent = 0;

-----------------------------------------

function Atr_SendAddon_VREQ (type, target)

	VREQ_sent = time();
	
	SendAddonMessage ("ATR", "VREQ_"..AuctionatorVersion, type, target);
	
end

-----------------------------------------

function Atr_OnChatMsgAddon ()

	local	prefix			= arg1;
	local	msg				= arg2;
	local	distribution	= arg3;
	local	sender			= arg4;
	
--	local s = string.format ("%s %s |cff88ffff %s |cffffffaa %s|r", prefix, distribution, sender, msg);
--	zc.md (s);

	if (arg1 == "ATR") then
	
		if (zc.StringStartsWith (msg, "VREQ_")) then
			SendAddonMessage ("ATR", "V_"..AuctionatorVersion, "WHISPER", sender);
		end
		
		if (zc.StringStartsWith (msg, "V_") and time() - VREQ_sent < 5) then

			local herVerString = string.sub (msg, 3);
			zc.md ("version found:", herVerString, "   ", sender, "     delta", time() - VREQ_sent);
			local outOfDate = CheckVersion (herVerString);
			if (outOfDate) then
				zc.AddDeferredCall (3, "Atr_VersionReminder", nil, nil, "VR");
			end
		end
	end

	if (Atr_OnChatMsgAddon_Dev) then
		Atr_OnChatMsgAddon_Dev (prefix, msg, distribution, sender);
	end
	
end


-----------------------------------------

local function Atr_GetAuctionatorMemString(msg)

	UpdateAddOnMemoryUsage();
	
	local mem  = GetAddOnMemoryUsage("Auctionator");
	return string.format ("%6i KB", math.floor(mem));
end

-----------------------------------------

local function Atr_SlashCmdFunction(msg)

	local cmd, param1u, param2u, param3u = zc.words (msg);

	if (cmd == nil or type (cmd) ~= "string") then
		return;
	end
	
		  cmd    = cmd     and cmd:lower()    or nil;
	local param1 = param1u and param1u:lower() or nil;
	local param2 = param2u and param2u:lower() or nil;
	local param3 = param3u and param3u:lower() or nil;
	
	if (cmd == "mem") then

		UpdateAddOnMemoryUsage();
		
		for i = 1, GetNumAddOns() do
			local mem  = GetAddOnMemoryUsage(i);
			local name = GetAddOnInfo(i);
			if (mem > 0) then
				local s = string.format ("%6i KB   %s", math.floor(mem), name);
				zc.msg_yellow (s);
			end
		end
	
	elseif (cmd == "locale") then
		Atr_PickLocalizationTable (param1u);

	elseif (cmd == "clear") then
	
		zc.msg_atr ("memory usage: "..Atr_GetAuctionatorMemString());
		
		if (param1 == "fullscandb") then
			gAtr_ScanDB = nil;
			AUCTIONATOR_PRICE_DATABASE = nil;
			Atr_InitScanDB();
			zc.msg_atr (ZT("full scan database cleared"));
			
		elseif (param1 == "posthistory") then
			AUCTIONATOR_PRICING_HISTORY = {};
			zc.msg_atr (ZT("pricing history cleared"));
		end
		
		collectgarbage  ("collect");
		
		zc.msg_atr ("memory usage: "..Atr_GetAuctionatorMemString());

	elseif (Atr_HandleDevCommands and Atr_HandleDevCommands (cmd, param1, param2)) then
		-- do nothing
	else
		zc.msg_atr (ZT("unrecognized command"));
	end
	
end


-----------------------------------------

function Atr_InitScanDB()

	local realm_Faction = GetRealmName().."_"..UnitFactionGroup ("player");

	if (AUCTIONATOR_PRICE_DATABASE and AUCTIONATOR_PRICE_DATABASE["__dbversion"] == nil) then	-- see if we need to migrate
	
		local temp = zc.CopyDeep (AUCTIONATOR_PRICE_DATABASE);
		
		AUCTIONATOR_PRICE_DATABASE = {};
		AUCTIONATOR_PRICE_DATABASE["__dbversion"] = 2;
	
		AUCTIONATOR_PRICE_DATABASE[realm_Faction] = zc.CopyDeep (temp);
		
		temp = {};
	end

	if (AUCTIONATOR_PRICE_DATABASE == nil) then
		AUCTIONATOR_PRICE_DATABASE = {};
		AUCTIONATOR_PRICE_DATABASE["__dbversion"] = 2;
	end
	
	if (AUCTIONATOR_PRICE_DATABASE[realm_Faction] == nil) then
		AUCTIONATOR_PRICE_DATABASE[realm_Faction] = {};
	end

	gAtr_ScanDB = AUCTIONATOR_PRICE_DATABASE[realm_Faction];

end


-----------------------------------------

function Atr_OnLoad()

	AuctionatorVersion = GetAddOnMetadata("Auctionator", "Version");

	gTimeZero		= time({year=2000, month=1, day=1, hour=0});
	gTimeTightZero	= time({year=2008, month=8, day=1, hour=0});

	local x;
	for x = 0, NUM_BAG_SLOTS do
		kBagIDs[x+1] = x;
	end
	
	kBagIDs[NUM_BAG_SLOTS+2] = KEYRING_CONTAINER;

	AuctionatorLoaded = true;

	SlashCmdList["Auctionator"] = Atr_SlashCmdFunction;
	
	SLASH_Auctionator1 = "/auctionator";
	SLASH_Auctionator2 = "/atr";

	Atr_InitScanDB ();
	
	if (AUCTIONATOR_PRICING_HISTORY == nil) then	-- the old history of postings
		AUCTIONATOR_PRICING_HISTORY = {};
	end
	
	if (AUCTIONATOR_TOONS == nil) then
		AUCTIONATOR_TOONS = {};
	end

	if (AUCTIONATOR_STACKING_PREFS == nil) then
		Atr_StackingPrefs_Init();
	end


	local playerName = UnitName("player");

	if (not AUCTIONATOR_TOONS[playerName]) then
		AUCTIONATOR_TOONS[playerName] = {};
		AUCTIONATOR_TOONS[playerName].firstSeen		= time();
		AUCTIONATOR_TOONS[playerName].firstVersion	= AuctionatorVersion;
	end

	AUCTIONATOR_TOONS[playerName].guid = UnitGUID ("player");

	if (AUCTIONATOR_SCAN_MINLEVEL == nil) then
		AUCTIONATOR_SCAN_MINLEVEL = 1;			-- poor (all) items
	end
	
	if (AUCTIONATOR_SHOW_TIPS == 0) then		-- migrate old option to new ones
		AUCTIONATOR_V_TIPS = 0;
		AUCTIONATOR_A_TIPS = 0;
		AUCTIONATOR_D_TIPS = 0;
		
		AUCTIONATOR_SHOW_TIPS = 2;
	end

	if (AUCTIONATOR_OPEN_FIRST < 2) then	-- set to 2 to indicate it's been migrated
		if		(AUCTIONATOR_OPEN_FIRST == 1)	then AUCTIONATOR_DEFTAB = 1;
		elseif	(AUCTIONATOR_OPEN_BUY == 1)		then AUCTIONATOR_DEFTAB = 2;
		else										 AUCTIONATOR_DEFTAB = 0; end;
	
		AUCTIONATOR_OPEN_FIRST = 2;
	end


	Atr_SetupHookFunctionsEarly();

	------------------

	CreateFrame( "GameTooltip", "AtrScanningTooltip" ); -- Tooltip name cannot be nil
	AtrScanningTooltip:SetOwner( WorldFrame, "ANCHOR_NONE" );
	-- Allow tooltip SetX() methods to dynamically add new lines based on these
	AtrScanningTooltip:AddFontStrings(
	AtrScanningTooltip:CreateFontString( "$parentTextLeft1", nil, "GameTooltipText" ),
	AtrScanningTooltip:CreateFontString( "$parentTextRight1", nil, "GameTooltipText" ) );

	------------------

	Atr_InitDETable();

	if ( IsAddOnLoaded("Blizzard_AuctionUI") ) then		-- need this for AH_QuickSearch since that mod forces Blizzard_AuctionUI to load at a startup
		Atr_Init();
	end

	

end

-----------------------------------------

local gPrevTime = 0;

function Atr_OnAddonLoaded()

	local addonName = arg1;

	if (zc.StringSame (addonName, "blizzard_auctionui")) then
		Atr_Init();
	end

	if (zc.StringSame (addonName, "lilsparkysWorkshop")) then

		local LSW_version = GetAddOnMetadata("lilsparkysWorkshop", "Version");

		if (LSW_version and (LSW_version == "0.72" or LSW_version == "0.90" or LSW_version == "0.91")) then

			if (LSW_itemPrice) then
				zc.msg ("** |cff00ffff"..ZT("Auctionator provided an auction module to LilSparky's Workshop."), 0, 1, 0);
				zc.msg ("** |cff00ffff"..ZT("Ignore any ERROR message to the contrary below."), 0, 1, 0);
				LSW_itemPrice = Atr_LSW_itemPriceGetAuctionBuyout;
			end
		end
	end

	Atr_Check_For_Conflicts (addonName);

	local now = time();

--	zc.md (addonName.."   time: "..now - gStartingTime);

	gPrevTime = now;

end


-----------------------------------------

function Atr_OnPlayerEnteringWorld()

	Atr_InitOptionsPanels();

--	Atr_MakeOptionsFrameOpaque();
end

-----------------------------------------

function Atr_LSW_itemPriceGetAuctionBuyout(link)

    sellPrice = Atr_GetAuctionBuyout(link)
    if sellPrice then
        return sellPrice, false
    else
        return 0, true
    end
 end
 
-----------------------------------------

function Atr_Init()

	if (AuctionatorInited) then
		return;
	end

--	zc.msg("Auctionator Initialized");

	AuctionatorInited = true;

	if (AUCTIONATOR_SAVEDVARS == nil) then
		Atr_ResetSavedVars();
	end


	if (AUCTIONATOR_SHOPPING_LISTS == nil) then
		AUCTIONATOR_SHOPPING_LISTS = {};
		Atr_SList.create (ZT("Recent Searches"), true);

		if (zc.IsEnglishLocale()) then
			local slist = Atr_SList.create ("Sample Shopping List #1");
			slist:AddItem ("Greater Cosmic Essence");
			slist:AddItem ("Infinite Dust");
			slist:AddItem ("Dream Shard");
			slist:AddItem ("Abyss Crystal");
		end
	else
		Atr_ShoppingListsInit();
	end

	gShopPane	= Atr_AddSellTab (ZT("Buy"),			BUY_TAB);
	gSellPane	= Atr_AddSellTab (ZT("Sell"),			SELL_TAB);
	gMorePane	= Atr_AddSellTab (ZT("More").."...",	MORE_TAB);

	Atr_AddMainPanel ();

	Atr_SetupHookFunctions ();

	recommendElements[1] = getglobal ("Atr_Recommend_Text");
	recommendElements[2] = getglobal ("Atr_RecommendPerItem_Text");
	recommendElements[3] = getglobal ("Atr_RecommendPerItem_Price");
	recommendElements[4] = getglobal ("Atr_RecommendPerStack_Text");
	recommendElements[5] = getglobal ("Atr_RecommendPerStack_Price");
	recommendElements[6] = getglobal ("Atr_Recommend_Basis_Text");
	recommendElements[7] = getglobal ("Atr_RecommendItem_Tex");

	-- create the lines that appear in the item history scroll pane

	local line, n;

	for n = 1, ITEM_HIST_NUM_LINES do
		local y = -5 - ((n-1)*16);
		line = CreateFrame("BUTTON", "AuctionatorHEntry"..n, Atr_Hlist, "Atr_HEntryTemplate");
		line:SetPoint("TOPLEFT", 0, y);
	end

	Atr_ShowHide_StartingPrice();
	
	Atr_LocalizeFrames();

end

-----------------------------------------

function Atr_ShowHide_StartingPrice()

	if (AUCTIONATOR_SHOW_ST_PRICE == 1) then
		Atr_StartingPriceText:Show();
		Atr_StartingPrice:Show();
		Atr_StartingPriceDiscountText:Hide();
		Atr_Duration_Text:SetPoint ("TOPLEFT", 10, -307);
	else
		Atr_StartingPriceText:Hide();
		Atr_StartingPrice:Hide();
		Atr_StartingPriceDiscountText:Show();
		Atr_Duration_Text:SetPoint ("TOPLEFT", 10, -304);
	end
end


-----------------------------------------

function Atr_GetSellItemInfo ()

	local auctionItemName, auctionTexture, auctionCount = GetAuctionSellItemInfo();

	if (auctionItemName == nil) then
		auctionItemName = "";
		auctionCount	= 0;
	end

	local auctionItemLink = nil;

	-- only way to get sell itemlink that I can figure

	if (auctionItemName ~= "") then
		AtrScanningTooltip:SetAuctionSellItem();
		local name;
		name, auctionItemLink = AtrScanningTooltip:GetItem();

		if (auctionItemLink == nil) then
			return "",0,nil;
		else
			Atr_AddToItemLinkCache (auctionItemName, auctionItemLink);
		end

	end

	return auctionItemName, auctionCount, auctionItemLink;

end


-----------------------------------------

function Atr_ResetSavedVars ()
	AUCTIONATOR_SAVEDVARS = zc.CopyDeep (auctionator_savedvars_defaults);
end


--------------------------------------------------------------------------------
-- don't reference these directly; use the function below instead

local _AUCTIONATOR_SELL_TAB_INDEX = 0;
local _AUCTIONATOR_MORE_TAB_INDEX = 0;
local _AUCTIONATOR_BUY_TAB_INDEX = 0;

--------------------------------------------------------------------------------

function Atr_FindTabIndex (whichTab)

	if (_AUCTIONATOR_SELL_TAB_INDEX == 0) then

		local i = 4;
		while (true)  do
			local tab = getglobal('AuctionFrameTab'..i);
			if (tab == nil) then
				break;
			end

			if (tab.auctionatorTab) then
				if (tab.auctionatorTab == SELL_TAB)		then _AUCTIONATOR_SELL_TAB_INDEX = i; end;
				if (tab.auctionatorTab == MORE_TAB)		then _AUCTIONATOR_MORE_TAB_INDEX = i; end;
				if (tab.auctionatorTab == BUY_TAB)		then _AUCTIONATOR_BUY_TAB_INDEX = i; end;
			end

			i = i + 1;
		end
	end

	if (whichTab == SELL_TAB)	then return _AUCTIONATOR_SELL_TAB_INDEX ; end;
	if (whichTab == MORE_TAB)	then return _AUCTIONATOR_MORE_TAB_INDEX; end;
	if (whichTab == BUY_TAB)	then return _AUCTIONATOR_BUY_TAB_INDEX; end;

	return 0;
end


-----------------------------------------

local gOrig_ContainerFrameItemButton_OnClick = nil;

-----------------------------------------

local function Atr_SwitchTo_OurItemOnClick ()

--	if (gOrig_ContainerFrameItemButton_OnClick == nil) then
--		gOrig_ContainerFrameItemButton_OnClick = ContainerFrameItemButton_OnClick;
--		ContainerFrameItemButton_OnClick = Atr_ContainerFrameItemButton_OnClick;
--	end

end

-----------------------------------------

local function Atr_SwitchTo_BlizzItemOnClick ()

--	if (gOrig_ContainerFrameItemButton_OnClick) then
--		ContainerFrameItemButton_OnClick = gOrig_ContainerFrameItemButton_OnClick;
--		gOrig_ContainerFrameItemButton_OnClick = nil;
--	end

end

-----------------------------------------


function Atr_AuctionFrameTab_OnClick (self, index, down)

	if ( index == nil or type(index) == "string") then
		index = self:GetID();
	end

	getglobal("Atr_Main_Panel"):Hide();

	gBuyState = ATR_BUY_NULL;			-- just in case
	gItemPostingInProgress = false;		-- just in case
	
	auctionator_orig_AuctionFrameTab_OnClick (self, index, down);

	if (index == 1 or index == 2 or Atr_IsAuctionatorTab(index)) then
		Atr_SwitchTo_OurItemOnClick();
	else
		Atr_SwitchTo_BlizzItemOnClick();
	end


	if (not Atr_IsAuctionatorTab(index)) then
		gForceMsgAreaUpdate = true;
		Atr_HideAllDialogs();
		AuctionFrameMoneyFrame:Show();

		if (AP_Bid_MoneyFrame) then		-- for the addon 'Auction Profit'
			if (AP_ShowBid)	then	AP_ShowHide_Bid_Button(1);	end;
			if (AP_ShowBO)	then	AP_ShowHide_BO_Button(1);	end;
		end


	elseif (Atr_IsAuctionatorTab(index)) then
	
		AuctionFrameAuctions:Hide();
		AuctionFrameBrowse:Hide();
		AuctionFrameBid:Hide();
		PlaySound("igCharacterInfoTab");

		PanelTemplates_SetTab(AuctionFrame, index);

		AuctionFrameTopLeft:SetTexture	("Interface\\AddOns\\Auctionator\\Images\\Atr_topleft");
		AuctionFrameBotLeft:SetTexture	("Interface\\AddOns\\Auctionator\\Images\\Atr_botleft");
		AuctionFrameTop:SetTexture		("Interface\\AddOns\\Auctionator\\Images\\Atr_top");
		AuctionFrameTopRight:SetTexture	("Interface\\AddOns\\Auctionator\\Images\\Atr_topright");
		AuctionFrameBot:SetTexture		("Interface\\AddOns\\Auctionator\\Images\\Atr_bot");
		AuctionFrameBotRight:SetTexture	("Interface\\AddOns\\Auctionator\\Images\\Atr_botright");

		if (index == Atr_FindTabIndex(SELL_TAB))	then gCurrentPane = gSellPane; end;
		if (index == Atr_FindTabIndex(BUY_TAB))		then gCurrentPane = gShopPane; end;
		if (index == Atr_FindTabIndex(MORE_TAB))	then gCurrentPane = gMorePane; end;

		if (index == Atr_FindTabIndex(SELL_TAB))	then AuctionatorTitle:SetText ("Auctionator - "..ZT("Sell"));			end;
		if (index == Atr_FindTabIndex(BUY_TAB))		then AuctionatorTitle:SetText ("Auctionator - "..ZT("Buy"));			end;
		if (index == Atr_FindTabIndex(MORE_TAB))	then AuctionatorTitle:SetText ("Auctionator - "..ZT("More").."...");	end;

		Atr_ClearHlist();
		Atr_SellControls:Hide();
		Atr_Hlist:Hide();
		Atr_Hlist_ScrollFrame:Hide();
		Atr_Search_Box:Hide();
		Atr_Search_Button:Hide();
		Atr_Adv_Search_Button:Hide();
		Atr_AddToSListButton:Hide();
		Atr_RemFromSListButton:Hide();
		Atr_NewSListButton:Hide();
		Atr_DelSListButton:Hide();
		Atr_DropDown1:Hide();
		Atr_DropDownSL:Hide();
		Atr_CheckActiveButton:Hide();
		Atr_Back_Button:Hide()
		
		AuctionFrameMoneyFrame:Hide();
		
		if (index == Atr_FindTabIndex(SELL_TAB)) then
			Atr_SellControls:Show();
		else
			Atr_Hlist:Show();
			Atr_Hlist_ScrollFrame:Show();
			if (gJustPosted_ItemName) then
				gJustPosted_ItemName = nil;
				gSellPane:ClearSearch ();
			end
		end


		if (index == Atr_FindTabIndex(MORE_TAB)) then
			FauxScrollFrame_SetOffset (Atr_Hlist_ScrollFrame, gCurrentPane.hlistScrollOffset);
			Atr_DisplayHlist();
			Atr_DropDown1:Show();
			
			if (UIDropDownMenu_GetSelectedValue(Atr_DropDown1) == MODE_LIST_ACTIVE) then
				Atr_CheckActiveButton:Show();
			end
		end
		
		
		if (index == Atr_FindTabIndex(BUY_TAB)) then
			Atr_Search_Box:Show();
			Atr_Search_Button:Show();
			Atr_Adv_Search_Button:Show();
			AuctionFrameMoneyFrame:Show();
			Atr_BuildGlobalHistoryList(true);
			Atr_AddToSListButton:Show();
			Atr_RemFromSListButton:Show();
			Atr_NewSListButton:Show();
			Atr_DelSListButton:Show();
			Atr_DropDownSL:Show();
			Atr_Hlist:SetHeight (252);
			Atr_Hlist_ScrollFrame:SetHeight (252);
		else
			Atr_Hlist:SetHeight (335);
			Atr_Hlist_ScrollFrame:SetHeight (335);
		end

		if (index == Atr_FindTabIndex(BUY_TAB) or index == Atr_FindTabIndex(SELL_TAB)) then
			Atr_Buy1_Button:Show();
			Atr_Buy1_Button:Disable();
		end

		Atr_HideElems (recommendElements);

		getglobal("Atr_Main_Panel"):Show();

		gCurrentPane.UINeedsUpdate = true;

		if (gOpenAllBags == 1) then
			OpenAllBags(true);
			gOpenAllBags = 0;
		end

	end

end

-----------------------------------------

function Atr_StackSize ()
	return Atr_Batch_Stacksize:GetNumber();
end

-----------------------------------------

function Atr_SetStackSize (n)
	return Atr_Batch_Stacksize:SetText(n);
end

-----------------------------------------

function Atr_SelectPane (whichTab)

	local index = Atr_FindTabIndex(whichTab);
	local tab   = getglobal('AuctionFrameTab'..index);
	
	Atr_AuctionFrameTab_OnClick (tab, index);

end

-----------------------------------------

function Atr_IsModeCreateAuction ()
	return (Atr_IsTabSelected(SELL_TAB));
end


-----------------------------------------

function Atr_IsModeBuy ()
	return (Atr_IsTabSelected(BUY_TAB));
end

-----------------------------------------

function Atr_IsModeActiveAuctions ()
	return (Atr_IsTabSelected(MORE_TAB) and UIDropDownMenu_GetSelectedValue(Atr_DropDown1) == MODE_LIST_ACTIVE);
end

-----------------------------------------

function Atr_ClickAuctionSellItemButton (self, button)

	gAtr_ClickAuctionSell = true;
	ClickAuctionSellItemButton(self, button);
end


-----------------------------------------

function Atr_OnDropItem (self, button)

	if (GetCursorInfo() ~= "item") then
		return;
	end

	if (not Atr_IsTabSelected(SELL_TAB)) then
		Atr_SelectPane (SELL_TAB);		-- then fall through
	end
	
	Atr_ClickAuctionSellItemButton (self, button);
	ClearCursor();
end

-----------------------------------------

function Atr_SellItemButton_OnClick (self, button, ...)

	Atr_ClickAuctionSellItemButton (self, button);
end

-----------------------------------------

function Atr_SellItemButton_OnEvent (self, event, ...)

	if ( event == "NEW_AUCTION_UPDATE") then
		local name, texture, count, quality, canUse, price = GetAuctionSellItemInfo();
		Atr_SellControls_Tex:SetNormalTexture(texture);
	end
	
end

-----------------------------------------

local function Atr_LoadContainerItemToSellPane()

	local bagID  = this:GetParent():GetID();
	local slotID = this:GetID();

	if (not Atr_IsTabSelected(SELL_TAB)) then
		Atr_SelectPane (SELL_TAB);
	end

	if (IsControlKeyDown()) then
		gAutoSingleton = time();
	end

	PickupContainerItem(bagID, slotID);

	local infoType = GetCursorInfo()

	if (infoType == "item") then
		Atr_ClearAll();
		Atr_ClickAuctionSellItemButton ();
		ClearCursor();
	end

end

-----------------------------------------

function Atr_ContainerFrameItemButton_OnClick (self, button)

	if (AuctionFrame and AuctionFrame:IsShown() and zc.StringSame (button, "RightButton")) then

		local selectedTab = PanelTemplates_GetSelectedTab (AuctionFrame);
	
		if (selectedTab == 1 or selectedTab == 2 or Atr_IsAuctionatorTab(selectedTab)) then
			Atr_LoadContainerItemToSellPane ();
		end
	end

end

-----------------------------------------

function Atr_ContainerFrameItemButton_OnModifiedClick (self, button)

	if (AUCTIONATOR_ENABLE_ALT ~= 0 and	AuctionFrame:IsShown() and IsAltKeyDown()) then
	
		Atr_LoadContainerItemToSellPane();
		return;
	end
	
	return auctionator_orig_ContainerFrameItemButton_OnModifiedClick (self, button);
end




-----------------------------------------

function Atr_CreateAuction_OnClick ()

	gJustPosted_ItemName			= gCurrentPane.activeScan.itemName;
	gJustPosted_ItemLink			= gCurrentPane.activeScan.itemLink;
	gJustPosted_BuyoutPrice			= MoneyInputFrame_GetCopper(Atr_StackPrice);
	gJustPosted_StackSize			= Atr_StackSize();
	gJustPosted_NumInBagsAtStart	= Atr_GetNumItemInBags(gJustPosted_ItemName);
	gJustPosted_NumStacks			= Atr_Batch_NumAuctions:GetNumber();

	local duration				= UIDropDownMenu_GetSelectedValue(Atr_Duration);
	local stackStartingPrice	= MoneyInputFrame_GetCopper(Atr_StartingPrice);
	local stackBuyoutPrice		= MoneyInputFrame_GetCopper(Atr_StackPrice);

	if (gJustPosted_StackSize == 1 and gCurrentPane.fullStackSize > 1) then
	
		local scan = gCurrentPane.activeScan;
		
		if (scan and scan.numYourSingletons + gJustPosted_NumStacks > 40) then
			local s = ZT("You may have at most 40 single-stack (x1)\nauctions posted for this item.\n\nYou already have %d such auctions and\nyou are trying to post %d more.");
			Atr_Error_Display (string.format (s, scan.numYourSingletons, gJustPosted_NumStacks));
			return;
		end
	end
	
	Atr_Memorize_Stacking_If();

	StartAuction (stackStartingPrice, stackBuyoutPrice, duration, gJustPosted_StackSize, gJustPosted_NumStacks);
end


-----------------------------------------

local gMS_stacksPrev;

-----------------------------------------

function Atr_OnAuctionMultiSellStart()

	gMS_stacksPrev = 0;

end

-----------------------------------------

function Atr_OnAuctionMultiSellUpdate()
	local stacksSoFar  = arg1;
	local stacksTotal  = arg2;
	
	local delta = stacksSoFar - gMS_stacksPrev;

--zc.md ("stacksSoFar: ", stacksSoFar, "stacksTotal: ", stacksTotal, "delta: ", delta);
	
	gMS_stacksPrev = stacksSoFar;
	
	Atr_AddToScan (gJustPosted_ItemName, gJustPosted_StackSize, gJustPosted_BuyoutPrice, delta);
	
	if (stacksSoFar == stacksTotal) then
		Atr_LogMsg (gJustPosted_ItemLink, gJustPosted_StackSize, gJustPosted_BuyoutPrice, stacksTotal);
		Atr_AddHistoricalPrice (gJustPosted_ItemName, gJustPosted_BuyoutPrice / gJustPosted_StackSize, gJustPosted_StackSize, gJustPosted_ItemLink);
	end
	
end

-----------------------------------------

function Atr_OnAuctionMultiSellFailure()

	-- add one more.  no good reason other than it just seems to work
	Atr_AddToScan (gJustPosted_ItemName, gJustPosted_StackSize, gJustPosted_BuyoutPrice, 1);

	Atr_LogMsg (gJustPosted_ItemLink, gJustPosted_StackSize, gJustPosted_BuyoutPrice, gMS_stacksPrev + 1);
	Atr_AddHistoricalPrice (gJustPosted_ItemName, gJustPosted_BuyoutPrice / gJustPosted_StackSize, gJustPosted_StackSize, gJustPosted_ItemLink);

	if (gCurrentPane.activeScan) then
		gCurrentPane.activeScan.whenScanned = 0;
	end
end


-----------------------------------------

function Atr_AuctionFrameAuctions_Update()

	auctionator_orig_AuctionFrameAuctions_Update();

end


-----------------------------------------

function Atr_LogMsg (itemlink, itemcount, price, numstacks)

	local logmsg = string.format (ZT("Auction created for %s"), itemlink);
	
	if (numstacks > 1) then
		logmsg = string.format (ZT("%d auctions created for %s"), numstacks, itemlink);
	end
	
	
	if (itemcount > 1) then
		logmsg = logmsg.."|cff00ddddx"..itemcount.."|r";
	end

	logmsg = logmsg.."   "..zc.priceToString(price);

	if (numstacks > 1 and itemcount > 1) then
		logmsg = logmsg.."  per stack";
	end
	

	zc.msg_yellow (logmsg);

end

-----------------------------------------

function Atr_OnAuctionOwnedUpdate ()

	gItemPostingInProgress = false;

	if (Atr_IsModeActiveAuctions()) then
		gHlistNeedsUpdate = true;
	end

	if (not Atr_IsTabSelected()) then
		Atr_ClearScanCache();		-- if not our tab, we have no idea what happened so must flush all caches
		return;
	end;

	gActiveAuctions = {};		-- always flush this cache

	if (gJustPosted_ItemName) then

		if (gJustPosted_NumStacks == 1) then
			Atr_LogMsg (gJustPosted_ItemLink, gJustPosted_StackSize, gJustPosted_BuyoutPrice, 1);
			Atr_AddHistoricalPrice (gJustPosted_ItemName, gJustPosted_BuyoutPrice / gJustPosted_StackSize, gJustPosted_StackSize, gJustPosted_ItemLink);
			Atr_AddToScan (gJustPosted_ItemName, gJustPosted_StackSize, gJustPosted_BuyoutPrice, 1);
		end
	end

	
end

-----------------------------------------

function Atr_ResetDuration()

	if (AUCTIONATOR_DEF_DURATION == "S") then UIDropDownMenu_SetSelectedValue(Atr_Duration, 1); end;
	if (AUCTIONATOR_DEF_DURATION == "M") then UIDropDownMenu_SetSelectedValue(Atr_Duration, 2); end;
	if (AUCTIONATOR_DEF_DURATION == "L") then UIDropDownMenu_SetSelectedValue(Atr_Duration, 3); end;

end

-----------------------------------------

function Atr_AddToScan (itemName, stackSize, buyoutPrice, numAuctions)

	local scan = Atr_FindScan (itemName);

	scan:AddScanItem (itemName, stackSize, buyoutPrice, UnitName("player"), numAuctions);

	scan:CondenseAndSort ();

	gCurrentPane.UINeedsUpdate = true;
end

-----------------------------------------

function AuctionatorSubtractFromScan (itemName, stackSize, buyoutPrice, howMany)

	if (howMany == nil) then
		howMany = 1;
	end
	
	local scan = Atr_FindScan (itemName);

	local x;
	for x = 1, howMany do
		scan:SubtractScanItem (itemName, stackSize, buyoutPrice);
	end
	
	scan:CondenseAndSort ();

	gCurrentPane.UINeedsUpdate = true;
end


-----------------------------------------

function auctionator_ChatEdit_InsertLink(text)

	if (AuctionFrame:IsShown() and IsShiftKeyDown() and Atr_IsTabSelected(BUY_TAB)) then	
		local item;
		if ( strfind(text, "item:", 1, true) ) then
			item = GetItemInfo(text);
		end
		if ( item ) then
			Atr_Search_Box:SetText (item);
			Atr_Search_Onclick ();
			return true;
		end
	end

	return auctionator_orig_ChatEdit_InsertLink(text);

end

-----------------------------------------

function auctionator_ChatFrame_OnEvent(self, event, ...)

	if (event == "CHAT_MSG_SYSTEM") then
		if (arg1 == ERR_AUCTION_STARTED) then		-- absorb the Auction Created message
			return;
		end
		if (arg1 == ERR_AUCTION_REMOVED) then		-- absorb the Auction Created message
			return;
		end
	end

	return auctionator_orig_ChatFrame_OnEvent (self, event, ...);

end




-----------------------------------------

function auctionator_CanShowRightUIPanel(frame)

	if (zc.StringSame (frame:GetName(), "TradeSkillFrame")) then
		return 1;
	end;

	return auctionator_orig_CanShowRightUIPanel(frame);

end

-----------------------------------------

function Atr_AddMainPanel ()

	local frame = CreateFrame("FRAME", "Atr_Main_Panel", AuctionFrame, "Atr_Sell_Template");
	frame:Hide();

	UIDropDownMenu_SetWidth (Atr_DropDownSL, 150);
	UIDropDownMenu_JustifyText (Atr_DropDownSL, "CENTER");
	
	UIDropDownMenu_SetWidth (Atr_Duration, 95);

end

-----------------------------------------

function Atr_AddSellTab (tabtext, whichTab)

	local n = AuctionFrame.numTabs+1;

	local framename = "AuctionFrameTab"..n;

	local frame = CreateFrame("Button", framename, AuctionFrame, "AuctionTabTemplate");

	frame:SetID(n);
	frame:SetText(tabtext);

	frame:SetNormalFontObject(getglobal("AtrFontOrange"));

	frame.auctionatorTab = whichTab;

	frame:SetPoint("LEFT", getglobal("AuctionFrameTab"..n-1), "RIGHT", -8, 0);

	PanelTemplates_SetNumTabs (AuctionFrame, n);
	PanelTemplates_EnableTab  (AuctionFrame, n);
	
	return AtrPane.create (whichTab);
end

-----------------------------------------

function Atr_HideElems (tt)

	if (not tt) then
		return;
	end

	for i,x in ipairs(tt) do
		x:Hide();
	end
end

-----------------------------------------

function Atr_ShowElems (tt)

	for i,x in ipairs(tt) do
		x:Show();
	end
end




-----------------------------------------

function Atr_OnAuctionUpdate ()

	if (gAtr_FullScanState == ATR_FS_STARTED) then
		Atr_FullScanAnalyze();
		return;
	end

	if (not Atr_IsTabSelected()) then
		Atr_ClearScanCache();		-- if not our tab, we have no idea what happened so must flush all caches
		return;
	end;

	if (Atr_Buy_OnAuctionUpdate()) then
		return;
	end

	if (gCurrentPane.activeSearch and gCurrentPane.activeSearch.processing_state == KM_POSTQUERY) then

		local isDup = gCurrentPane.activeSearch:CheckForDuplicatePage ();
		
		if (not isDup) then

			local done = gCurrentPane.activeSearch:AnalyzeResultsPage();

			if (done) then
				gCurrentPane.activeSearch:Finish();
				Atr_OnSearchComplete ();
			end
		end
	end

end

-----------------------------------------

function Atr_OnSearchComplete ()

	gCurrentPane.sortedHist = nil;

	local count = gCurrentPane.activeSearch:NumScans();
	if (count == 1) then
		gCurrentPane.activeScan = gCurrentPane.activeSearch:GetFirstScan();
	end

	if (Atr_IsModeCreateAuction()) then
			
		gCurrentPane:SetToShowCurrent();

		if (#gCurrentPane.activeScan.scanData == 0) then
			gCurrentPane.hints = Atr_BuildHints (gCurrentPane.activeScan.itemName);
			if (#gCurrentPane.hints > 0) then
				gCurrentPane:SetToShowHints();	
				gCurrentPane.hintsIndex = 1;
			end

		end
		
		if (gCurrentPane:ShowCurrent()) then
			Atr_FindBestCurrentAuction ();
		end

		Atr_UpdateRecommendation(true);
	else
		if (Atr_IsModeActiveAuctions()) then
			Atr_DisplayHlist();
		end
		
		Atr_FindBestCurrentAuction ();
	end
	
	if (Atr_IsModeBuy()) then
		Atr_Shop_OnFinishScan ();
	end

	Atr_CheckingActive_OnSearchComplete();

	gCurrentPane.UINeedsUpdate = true;

end

-----------------------------------------

function Atr_ClearTop ()
	Atr_HideElems (recommendElements);

	if (AuctionatorMessageFrame) then
		AuctionatorMessageFrame:Hide();
		AuctionatorMessage2Frame:Hide();
	end
end

-----------------------------------------

function Atr_ClearList ()

	Atr_Col1_Heading:Hide();
	Atr_Col3_Heading:Hide();
	Atr_Col4_Heading:Hide();

	Atr_Col1_Heading_Button:Hide();
	Atr_Col3_Heading_Button:Hide();

	local line;							-- 1 through 12 of our window to scroll

	FauxScrollFrame_Update (AuctionatorScrollFrame, 0, 12, 16);

	for line = 1,12 do
		local lineEntry = getglobal ("AuctionatorEntry"..line);
		lineEntry:Hide();
	end

end

-----------------------------------------

function Atr_ClearAll ()

	if (AuctionatorMessageFrame) then	-- just to make sure xml has been loaded

		Atr_ClearTop();
		Atr_ClearList();
	end
end

-----------------------------------------

function Atr_SetMessage (msg)
	Atr_HideElems (recommendElements);

	if (gCurrentPane.activeSearch.searchText) then
		
		Atr_ShowItemNameAndTexture (gCurrentPane.activeSearch.searchText);
		
		AuctionatorMessage2Frame:SetText (msg);
		AuctionatorMessage2Frame:Show();
		
	else
		AuctionatorMessageFrame:SetText (msg);
		AuctionatorMessageFrame:Show();
		AuctionatorMessage2Frame:Hide();
	end
end

-----------------------------------------

function Atr_ShowItemNameAndTexture(itemName)

	AuctionatorMessageFrame:Hide();
	AuctionatorMessage2Frame:Hide();

	local scn = gCurrentPane.activeScan;

	local color = "";
	if (scn and not scn:IsNil()) then
		color = "|cff"..zc.RGBtoHEX (scn.itemTextColor[1], scn.itemTextColor[2], scn.itemTextColor[3]);
		itemName = scn.itemName;
	end

	Atr_Recommend_Text:Show ();
	Atr_Recommend_Text:SetText (color..itemName);

	Atr_SetTextureButton ("Atr_RecommendItem_Tex", 1, gCurrentPane.activeScan.itemLink);
end



-----------------------------------------

function Atr_SortHistoryData (x, y)

	return x.when > y.when;

end

-----------------------------------------

function BuildHtag (type, y, m, d)

	local t = time({year=y, month=m, day=d, hour=0});

	return tostring (ToTightTime(t))..":"..type;
end

-----------------------------------------

function ParseHtag (tag)
	local when, type = strsplit(":", tag);

	if (type == nil) then
		type = "hx";
	end

	when = FromTightTime (tonumber (when));

	return when, type;
end

-----------------------------------------

function ParseHist (tag, hist)

	local when, type = ParseHtag(tag);

	local price, count	= strsplit(":", hist);

	price = tonumber (price);

	local stacksize, numauctions;

	if (type == "hx") then
		stacksize	= tonumber (count);
		numauctions	= 1;
	else
		stacksize = 0;
		numauctions	= tonumber (count);
	end

	return when, type, price, stacksize, numauctions;

end

-----------------------------------------

function CalcAbsTimes (when, whent)

	local absYear	= whent.year - 2000;
	local absMonth	= (absYear * 12) + whent.month;
	local absDay	= floor ((when - gTimeZero) / (60*60*24));

	return absYear, absMonth, absDay;

end

-----------------------------------------

function Atr_Condense_History (itemname)

	if (AUCTIONATOR_PRICING_HISTORY[itemname] == nil) then
		return;
	end

	local tempHistory = {};

	local now			= time();
	local nowt			= date("*t", now);

	local absNowYear, absNowMonth, absNowDay = CalcAbsTimes (now, nowt);

	local n = 1;
	local tag, hist, newtag, stacksize, numauctions;
	for tag, hist in pairs (AUCTIONATOR_PRICING_HISTORY[itemname]) do
		if (tag ~= "is") then

			local when, type, price, stacksize, numauctions = ParseHist (tag, hist);

			local whnt = date("*t", when);

			local absYear, absMonth, absDay	= CalcAbsTimes (when, whnt);

			if (absNowYear - absYear >= 3) then
				newtag = BuildHtag ("hy", whnt.year, 1, 1);
			elseif (absNowMonth - absMonth >= 2) then
				newtag = BuildHtag ("hm", whnt.year, whnt.month, 1);
			elseif (absNowDay - absDay >= 2) then
				newtag = BuildHtag ("hd", whnt.year, whnt.month, whnt.day);
			else
				newtag = tag;
			end

			tempHistory[n] = {};
			tempHistory[n].price		= price;
			tempHistory[n].numauctions	= numauctions;
			tempHistory[n].stacksize	= stacksize;
			tempHistory[n].when			= when;
			tempHistory[n].newtag		= newtag;
			n = n + 1;
		end
	end

	-- clear all the existing history

	local is = AUCTIONATOR_PRICING_HISTORY[itemname]["is"];

	AUCTIONATOR_PRICING_HISTORY[itemname] = {};
	AUCTIONATOR_PRICING_HISTORY[itemname]["is"] = is;

	-- repopulate the history

	local x;

	for x = 1,#tempHistory do

		local thist		= tempHistory[x];
		local newtag	= thist.newtag;

		if (AUCTIONATOR_PRICING_HISTORY[itemname][newtag] == nil) then

			local when, type = ParseHtag (newtag);

			local count = thist.numauctions;
			if (type == "hx") then
				count = thist.stacksize;
			end

			AUCTIONATOR_PRICING_HISTORY[itemname][newtag] = tostring(thist.price)..":"..tostring(count);

		else

			local hist = AUCTIONATOR_PRICING_HISTORY[itemname][newtag];

			local when, type, price, stacksize, numauctions = ParseHist (newtag, hist);

			local newNumAuctions = numauctions + thist.numauctions;
			local newPrice		 = ((price * numauctions) + (thist.price * thist.numauctions)) / newNumAuctions;

			AUCTIONATOR_PRICING_HISTORY[itemname][newtag] = tostring(newPrice)..":"..tostring(newNumAuctions);
		end
	end

end

-----------------------------------------

function Atr_Process_Historydata ()

	-- Condense the data if needed - only once per session for each item

	if (gCurrentPane:IsScanEmpty()) then
		return;
	end
	
	local itemName = gCurrentPane.activeScan.itemName;

	if (gCondensedThisSession[itemName] == nil) then

		gCondensedThisSession[itemName] = true;

		Atr_Condense_History(itemName);
	end

	-- build the sorted history list

	gCurrentPane.sortedHist = {};

	if (AUCTIONATOR_PRICING_HISTORY[itemName]) then
		local n = 1;
		local tag, hist;
		for tag, hist in pairs (AUCTIONATOR_PRICING_HISTORY[itemName]) do
			if (tag ~= "is") then
				local when, type, price, stacksize, numauctions = ParseHist (tag, hist);

				if (stacksize == 0) then
					stacksize = numauctions;
				end
				
				gCurrentPane.sortedHist[n]				= {};
				gCurrentPane.sortedHist[n].itemPrice	= price;
				gCurrentPane.sortedHist[n].buyoutPrice	= price * stacksize;
				gCurrentPane.sortedHist[n].stackSize	= stacksize;
				gCurrentPane.sortedHist[n].when			= when;
				gCurrentPane.sortedHist[n].yours		= true;
				gCurrentPane.sortedHist[n].type			= type;

				n = n + 1;
			end
		end
	end

	table.sort (gCurrentPane.sortedHist, Atr_SortHistoryData);

	if (#gCurrentPane.sortedHist > 0) then
		return gCurrentPane.sortedHist[1].itemPrice;
	end

end

-----------------------------------------

function Atr_GetMostRecentSale (itemName)

	local recentPrice;
	local recentWhen = 0;
	
	if (AUCTIONATOR_PRICING_HISTORY and AUCTIONATOR_PRICING_HISTORY[itemName]) then
		local n = 1;
		local tag, hist;
		for tag, hist in pairs (AUCTIONATOR_PRICING_HISTORY[itemName]) do
			if (tag ~= "is") then
				local when, type, price = ParseHist (tag, hist);

				if (when > recentWhen) then
					recentPrice = price;
					recentWhen  = when;
				end
			end
		end
	end

	return recentPrice;

end


-----------------------------------------

function Atr_ShowingSearchSummary ()

	if (gCurrentPane.activeSearch and gCurrentPane.activeSearch.searchText ~= "" and gCurrentPane:IsScanEmpty() and gCurrentPane.activeSearch:NumScans() > 0) then
		return true;
	end
	
	return false;
end

-----------------------------------------

function Atr_ShowingCurrentAuctions ()
	if (gCurrentPane) then
		return gCurrentPane:ShowCurrent();
	end
	
	return true;
end

-----------------------------------------

function Atr_ShowingHistory ()
	if (gCurrentPane) then
		return gCurrentPane:ShowHistory();
	end
	
	return false;
end

-----------------------------------------

function Atr_ShowingHints ()
	if (gCurrentPane) then
		return gCurrentPane:ShowHints();
	end
	
	return false;
end



-----------------------------------------

function Atr_UpdateRecommendation (updatePrices)

	if (gCurrentPane == gSellPane and gJustPosted_ItemLink and GetAuctionSellItemInfo() == nil) then
		return;
	end

	local basedata;

	if (Atr_ShowingSearchSummary()) then
	
	elseif (Atr_ShowingCurrentAuctions()) then

		if (gCurrentPane:GetProcessingState() ~= KM_NULL_STATE) then
			return;
		end

		if (#gCurrentPane.activeScan.sortedData == 0) then
			Atr_SetMessage (ZT("No current auctions found"));
			return;
		end

		if (not gCurrentPane.currIndex) then
			if (gCurrentPane.activeScan.numMatches == 0) then
				Atr_SetMessage (ZT("No current auctions found\n\n(related auctions shown)"));
			elseif (gCurrentPane.activeScan.numMatchesWithBuyout == 0) then
				Atr_SetMessage (ZT("No current auctions with buyouts found"));
			else
				Atr_SetMessage ("");
			end
			return;
		end

		basedata = gCurrentPane.activeScan.sortedData[gCurrentPane.currIndex];
		
	elseif (Atr_ShowingHistory()) then
	
		basedata = zc.GetArrayElemOrFirst (gCurrentPane.sortedHist, gCurrentPane.histIndex);
		
		if (basedata == nil) then
			Atr_SetMessage (ZT("Auctionator has yet to record any auctions for this item"));
			return;
		end
	
	else	-- hints
		
		local data = zc.GetArrayElemOrFirst (gCurrentPane.hints, gCurrentPane.hintsIndex);
		
		if (data) then		
			basedata = {};
			basedata.itemPrice		= data.price;
			basedata.buyoutPrice	= data.price;
			basedata.stackSize		= 1;
			basedata.sourceText		= data.text;
			basedata.yours			= true;		-- so no discounting
		end
	end

	if (Atr_StackSize() == 0) then
		return;
	end

	local new_Item_BuyoutPrice;
	
	if (gItemPostingInProgress and gCurrentPane.itemLink == gJustPosted_ItemLink) then	-- handle the unusual case where server is still in the process of creating the last auction

		new_Item_BuyoutPrice = gJustPosted_BuyoutPrice / gJustPosted_StackSize;
		
	elseif (basedata) then			-- the normal case
	
		new_Item_BuyoutPrice = basedata.itemPrice;

		if (not basedata.yours and not basedata.altname) then
			new_Item_BuyoutPrice = Atr_CalcUndercutPrice (new_Item_BuyoutPrice);
		end
	end

	if (new_Item_BuyoutPrice == nil) then
		return;
	end
	
	local new_Item_StartPrice = Atr_CalcStartPrice (new_Item_BuyoutPrice);

	Atr_ShowElems (recommendElements);
	AuctionatorMessageFrame:Hide();
	AuctionatorMessage2Frame:Hide();

	Atr_Recommend_Text:SetText (ZT("Recommended Buyout Price"));
	Atr_RecommendPerStack_Text:SetText (string.format (ZT("for your stack of %d"), Atr_StackSize()));

	Atr_SetTextureButton ("Atr_RecommendItem_Tex", Atr_StackSize(), gCurrentPane.activeScan.itemLink);

	MoneyFrame_Update ("Atr_RecommendPerItem_Price",  zc.round(new_Item_BuyoutPrice));
	MoneyFrame_Update ("Atr_RecommendPerStack_Price", zc.round(new_Item_BuyoutPrice * Atr_StackSize()));

	if (updatePrices) then
		MoneyInputFrame_SetCopper (Atr_StackPrice,		new_Item_BuyoutPrice * Atr_StackSize());
		MoneyInputFrame_SetCopper (Atr_StartingPrice, 	new_Item_StartPrice * Atr_StackSize());
		MoneyInputFrame_SetCopper (Atr_ItemPrice,		new_Item_BuyoutPrice);
	end
	
	local cheapestStack = gCurrentPane.activeScan.bestPrices[Atr_StackSize()];

	Atr_Recommend_Basis_Text:SetTextColor (1,1,1);

	if (Atr_ShowingHints()) then
		Atr_Recommend_Basis_Text:SetTextColor (.8,.8,1);
		Atr_Recommend_Basis_Text:SetText ("("..ZT("based on").." "..basedata.sourceText..")");
	elseif (gCurrentPane.activeScan.absoluteBest and basedata.stackSize == gCurrentPane.activeScan.absoluteBest.stackSize and basedata.buyoutPrice == gCurrentPane.activeScan.absoluteBest.buyoutPrice) then
		Atr_Recommend_Basis_Text:SetText ("("..ZT("based on cheapest current auction")..")");
	elseif (cheapestStack and basedata.stackSize == cheapestStack.stackSize and basedata.buyoutPrice == cheapestStack.buyoutPrice) then
		Atr_Recommend_Basis_Text:SetText ("("..ZT("based on cheapest stack of the same size")..")");
	else
		Atr_Recommend_Basis_Text:SetText ("("..ZT("based on selected auction")..")");
	end

end


-----------------------------------------

function Atr_StackPriceChangedFunc ()

	local new_Stack_BuyoutPrice = MoneyInputFrame_GetCopper (Atr_StackPrice);
	local new_Item_BuyoutPrice  = math.floor (new_Stack_BuyoutPrice / Atr_StackSize());
	local new_Item_StartPrice   = Atr_CalcStartPrice (new_Item_BuyoutPrice);

	local calculatedStackPrice = MoneyInputFrame_GetCopper(Atr_ItemPrice) * Atr_StackSize();

	-- check to prevent looping
	
	if (calculatedStackPrice ~= new_Stack_BuyoutPrice) then
		MoneyInputFrame_SetCopper (Atr_ItemPrice,		new_Item_BuyoutPrice);
		MoneyInputFrame_SetCopper (Atr_StartingPrice,	new_Item_StartPrice * Atr_StackSize());
	end
	
end

-----------------------------------------

function Atr_ItemPriceChangedFunc ()

	local new_Item_BuyoutPrice = MoneyInputFrame_GetCopper (Atr_ItemPrice);
	local new_Item_StartPrice  = Atr_CalcStartPrice (new_Item_BuyoutPrice);
	
	local calculatedItemPrice = math.floor (MoneyInputFrame_GetCopper (Atr_StackPrice) / Atr_StackSize());

	-- check to prevent looping
	
	if (calculatedItemPrice ~= new_Item_BuyoutPrice) then
		MoneyInputFrame_SetCopper (Atr_StackPrice, 		new_Item_BuyoutPrice * Atr_StackSize());
		MoneyInputFrame_SetCopper (Atr_StartingPrice,	new_Item_StartPrice  * Atr_StackSize());
	end

end

-----------------------------------------

function Atr_StackSizeChangedFunc ()

	local item_BuyoutPrice		= MoneyInputFrame_GetCopper (Atr_ItemPrice);
	local new_Item_StartPrice   = Atr_CalcStartPrice (item_BuyoutPrice);
	
	MoneyInputFrame_SetCopper (Atr_StackPrice, 		item_BuyoutPrice * Atr_StackSize());
	MoneyInputFrame_SetCopper (Atr_StartingPrice,	new_Item_StartPrice  * Atr_StackSize());

--	Atr_MemorizeButton:Show();

	gSellPane.UINeedsUpdate = true;

end

-----------------------------------------

function Atr_NumAuctionsChangedFunc (x)

--	Atr_MemorizeButton:Show();

	gSellPane.UINeedsUpdate = true;
end


-----------------------------------------

function Atr_SetTextureButton (elementName, count, itemlink)

	local texture = GetItemIcon (itemlink);

	local textureElement = getglobal (elementName);

	if (texture) then
		textureElement:Show();
		textureElement:SetNormalTexture (texture);
		Atr_SetTextureButtonCount (elementName, count);
	else
		Atr_SetTextureButtonCount (elementName, 0);
	end

end

-----------------------------------------

function Atr_SetTextureButtonCount (elementName, count)

	local countElement   = getglobal (elementName.."Count");

	if (count > 1) then
		countElement:SetText (count);
		countElement:Show();
	else
		countElement:Hide();
	end

end

-----------------------------------------

function Atr_ShowRecTooltip ()
	
	local link = gCurrentPane.activeScan.itemLink;
	local num  = Atr_StackSize();
	
	if (not link) then
		link = gJustPosted_ItemLink;
		num  = gJustPosted_StackSize;
	end
	
	if (link) then
		if (num < 1) then num = 1; end;
		
		GameTooltip:SetOwner(Atr_RecommendItem_Tex, "ANCHOR_RIGHT");
		GameTooltip:SetHyperlink (link, num);
		gCurrentPane.tooltipvisible = true;
	end

end

-----------------------------------------

function Atr_HideRecTooltip ()
	
	gCurrentPane.tooltipvisible = nil;
	GameTooltip:Hide();

end


-----------------------------------------

function Atr_OnAuctionHouseShow()

	gOpenAllBags = AUCTIONATOR_OPEN_ALL_BAGS;

	if (AUCTIONATOR_DEFTAB == 1) then		Atr_SelectPane (SELL_TAB);	end
	if (AUCTIONATOR_DEFTAB == 2) then		Atr_SelectPane (BUY_TAB);	end
	if (AUCTIONATOR_DEFTAB == 3) then		Atr_SelectPane (MORE_TAB);	end

	Atr_ResetDuration();

	gJustPosted_ItemName = nil;
	gSellPane:ClearSearch();

	if (gCurrentPane) then
		gCurrentPane.UINeedsUpdate = true;
	end
end

-----------------------------------------

function Atr_OnAuctionHouseClosed()

	Atr_SwitchTo_BlizzItemOnClick();
	
	Atr_HideAllDialogs();
	
	Atr_CheckingActive_Finish ();

	Atr_ClearScanCache();

	gSellPane:ClearSearch();
	gShopPane:ClearSearch();
	gMorePane:ClearSearch();

end

-----------------------------------------

function Atr_HideAllDialogs()

	Atr_CheckActives_Frame:Hide();
	Atr_Error_Frame:Hide();
	Atr_Buy_Confirm_Frame:Hide();
	Atr_FullScanFrame:Hide();
	Atr_Mask:Hide();

end



-----------------------------------------

function Atr_BasicOptionsUpdate(self, elapsed)

	self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed;

	if (self.TimeSinceLastUpdate > 0.25) then

		self.TimeSinceLastUpdate = 0;

		if (AuctionatorOption_Def_Duration_CB:GetChecked()) then
			AuctionatorOption_Durations:Show();
		else
			AuctionatorOption_Durations:Hide();
		end

	end
end


-----------------------------------------

function Atr_OnWhoListUpdate()

	if (gSendZoneMsgs) then
		gSendZoneMsgs = false;
		
		local numWhos, totalCount = GetNumWhoResults();
		local i;
		
		zc.md (numWhos.." out of "..totalCount.." users found");

		for i = 1,numWhos do
			local name, guildname, level = GetWhoInfo(i);
			Atr_SendAddon_VREQ ("WHISPER", name);
			if (Atr_Guildinfo) then
				Atr_Guildinfo[name] = guildname;
			end
			if (Atr_Levelinfo) then
				Atr_Levelinfo[name] = level;
			end
			
		end
	end
end

-----------------------------------------

function Atr_OnUpdate(self, elapsed)

	-- update the global "precision" timer
	
	gAtr_ptime = gAtr_ptime and gAtr_ptime + elapsed or 0;

	
	-- check deferred call queue

	if (zc.periodic (self, "dcq_lastUpdate", 0.05, elapsed)) then
		zc.CheckDeferredCall();
	end

	-- make sure all dusts and essences are in the local cache

	if (gAtr_dustCacheIndex > 0 and zc.periodic (self, "dust_lastUpdate", 0.1, elapsed)) then
		Atr_GetNextDustIntoCache();
	end
	
	-- the core Idle routine

	if (zc.periodic (self, "idle_lastUpdate", 0.2, elapsed)) then
		Atr_Idle (self, elapsed);
	end
end


-----------------------------------------
local verCheckMsgState = 0;
-----------------------------------------

function Atr_Idle(self, elapsed)


	if (gCurrentPane and gCurrentPane.tooltipvisible) then
		Atr_ShowRecTooltip();
	end


	if (gAtr_FullScanState ~= ATR_FS_NULL) then
		Atr_FullScanFrameIdle();
	end
	
	if (verCheckMsgState == 0) then
		verCheckMsgState = time();
	end
	
	if (verCheckMsgState > 1 and time() - verCheckMsgState > 5) then	-- wait 5 seconds
		verCheckMsgState = 1;
		
		local guildname = GetGuildInfo ("player");
		if (guildname) then
			Atr_SendAddon_VREQ ("GUILD");
		end
	end

	if (not Atr_IsTabSelected() or AuctionatorMessageFrame == nil) then
		return;
	end

	if (gHentryTryAgain) then
		Atr_HEntryOnClick();
		return;
	end

	if (gCurrentPane.activeSearch and gCurrentPane.activeSearch.processing_state == KM_PREQUERY) then		------- check whether to send a new auction query to get the next page -------
		gCurrentPane.activeSearch:Continue();
	end

	Atr_UpdateUI ();

	Atr_CheckingActiveIdle();
	
	Atr_Buy_Idle();
	
	if (gHideAPFrameCheck == nil) then	-- for the addon 'Auction Profit' (flags for efficiency so we only check one time)
		gHideAPFrameCheck = true;
		if (AP_Bid_MoneyFrame) then	
			AP_Bid_MoneyFrame:Hide();
			AP_Buy_MoneyFrame:Hide();
		end
	end
end

-----------------------------------------

local gPrevSellItemLink;

-----------------------------------------

function Atr_OnNewAuctionUpdate()
	
	if (not gAtr_ClickAuctionSell) then
		gPrevSellItemLink = nil;
		return;
	end
	
--	zc.md ("gAtr_ClickAuctionSell:", gAtr_ClickAuctionSell);
	
	gAtr_ClickAuctionSell = false;

	local auctionItemName, auctionCount, auctionLink = Atr_GetSellItemInfo();

	if (gPrevSellItemLink ~= auctionLink) then

		gPrevSellItemLink = auctionLink;
		
		if (auctionLink) then
			gJustPosted_ItemName = nil;
			Atr_AddToItemLinkCache (auctionItemName, auctionLink);
			Atr_ClearList();		-- better UE
			gSellPane:SetToShowCurrent();
		end
		
		MoneyInputFrame_SetCopper (Atr_StackPrice, 0);
		MoneyInputFrame_SetCopper (Atr_StartingPrice,  0);
		Atr_ResetDuration();
		
		if (gJustPosted_ItemName == nil) then
			local cacheHit = gSellPane:DoSearch (auctionItemName, true, 20);
			
			gSellPane.totalItems	= Atr_GetNumItemInBags (auctionItemName);
			gSellPane.fullStackSize = auctionLink and (select (8, GetItemInfo (auctionLink))) or 0;

			local prefNumStacks, prefStackSize = Atr_GetSellStacking (auctionLink, auctionCount, gSellPane.totalItems);
			
			if (time() - gAutoSingleton < 5) then
				Atr_SetInitialStacking (1, 1);
			else
				Atr_SetInitialStacking (prefNumStacks, prefStackSize);
			end
			
			if (cacheHit) then
				Atr_OnSearchComplete ();
			end
			
			Atr_SetTextureButton ("Atr_SellControls_Tex", Atr_StackSize(), auctionLink);
			Atr_SellControls_TexName:SetText (auctionItemName);
		else
			Atr_SetTextureButton ("Atr_SellControls_Tex", 0, nil);
			Atr_SellControls_TexName:SetText ("");
		end
		
	elseif (Atr_StackSize() ~= auctionCount) then
	
		local prefNumStacks, prefStackSize = Atr_GetSellStacking (auctionLink, auctionCount, gSellPane.totalItems);

		Atr_SetInitialStacking (prefNumStacks, prefStackSize);

		Atr_SetTextureButton ("Atr_SellControls_Tex", Atr_StackSize(), auctionLink);

		Atr_FindBestCurrentAuction();
		Atr_ResetDuration();
	end
		
	gSellPane.UINeedsUpdate = true;
	
end

---------------------------------------------------------

function Atr_UpdateUI ()

	local needsUpdate = gCurrentPane.UINeedsUpdate;
	
	if (gCurrentPane.UINeedsUpdate) then

		gCurrentPane.UINeedsUpdate = false;

		if (Atr_ShowingSearchSummary()) then
			Atr_ShowSearchSummary();
		elseif (gCurrentPane:ShowCurrent()) then
			PanelTemplates_SetTab(Atr_ListTabs, 1);
			Atr_ShowCurrentAuctions();
		elseif (gCurrentPane:ShowHistory()) then
			PanelTemplates_SetTab(Atr_ListTabs, 2);
			Atr_ShowHistory();
		else
			PanelTemplates_SetTab(Atr_ListTabs, 3);
			Atr_ShowHints();
		end
		
		if (gCurrentPane:IsScanEmpty()) then
			Atr_ListTabs:Hide();
		else
			Atr_ListTabs:Show();
		end

		Atr_SetMessage ("");
		local scn = gCurrentPane.activeScan;
		
		if (Atr_IsModeCreateAuction()) then
		
			Atr_UpdateRecommendation (false);
		else
			Atr_HideElems (recommendElements);
		
			if (scn:IsNil()) then
				Atr_ShowItemNameAndTexture (gCurrentPane.activeSearch.searchText);
			else
				Atr_ShowItemNameAndTexture (gCurrentPane.activeScan.itemName);
			end

			if (Atr_IsModeBuy()) then

				if (gCurrentPane.activeSearch.searchText == "") then
					Atr_SetMessage (ZT("Select an item from the list on the left\n or type a search term above to start a scan."));
				end
			end
		
		end
		
		
		if (Atr_IsTabSelected(BUY_TAB)) then
			Atr_Shop_UpdateUI();
		end
		
	end
	
	-- update the hlist if needed

	if (gHlistNeedsUpdate and Atr_IsModeActiveAuctions()) then
		gHlistNeedsUpdate = false;
		Atr_DisplayHlist();
	end
	
	if (Atr_IsTabSelected(SELL_TAB)) then
		Atr_UpdateUI_SellPane (needsUpdate);
	end

end

---------------------------------------------------------

function Atr_UpdateUI_SellPane (needsUpdate)

	local auctionItemName = GetAuctionSellItemInfo();

	if (needsUpdate) then

		if (gCurrentPane.activeSearch and gCurrentPane.activeSearch.processing_state ~= KM_NULL_STATE) then
			Atr_CreateAuctionButton:Disable();
			Atr_FullScanButton:Disable();
			Auctionator1Button:Disable();		
			MoneyInputFrame_SetCopper (Atr_StartingPrice,  0);
			return;
		else
			Atr_FullScanButton:Enable();
			Auctionator1Button:Enable();		


			if (Atr_Batch_Stacksize.oldStackSize ~= Atr_StackSize()) then
				Atr_Batch_Stacksize.oldStackSize = Atr_StackSize();
				local itemPrice = MoneyInputFrame_GetCopper(Atr_ItemPrice);
				MoneyInputFrame_SetCopper (Atr_StackPrice,  itemPrice * Atr_StackSize());
			end

			Atr_StartingPriceDiscountText:SetText (ZT("Starting Price Discount")..":  "..AUCTIONATOR_SAVEDVARS.STARTING_DISCOUNT.."%");
			
			if (Atr_Batch_NumAuctions:GetNumber() < 2) then
				Atr_Batch_Stacksize_Text:SetText (ZT("stack of"));
				Atr_CreateAuctionButton:SetText (ZT("Create Auction"));
			else
				Atr_Batch_Stacksize_Text:SetText (ZT("stacks of"));
				Atr_CreateAuctionButton:SetText (string.format (ZT("Create %d Auctions"), Atr_Batch_NumAuctions:GetNumber()));
			end

			if (Atr_StackSize() > 1) then
				Atr_StackPriceText:SetText (ZT("Buyout Price").." |cff55ddffx"..Atr_StackSize().."|r");
				Atr_ItemPriceText:SetText (ZT("Per Item"));
				Atr_ItemPriceText:Show();
				Atr_ItemPrice:Show();
			else
				Atr_StackPriceText:SetText (ZT("Buyout Price"));
				Atr_ItemPriceText:Hide();
				Atr_ItemPrice:Hide();
			end

			Atr_SetTextureButton ("Atr_SellControls_Tex", Atr_StackSize(), Atr_GetItemLink(auctionItemName));

			
			local maxAuctions = 0;
			if (Atr_StackSize() > 0) then
				maxAuctions = math.floor (gCurrentPane.totalItems / Atr_StackSize());
			end
			
			Atr_Batch_MaxAuctions_Text:SetText (ZT("max")..": "..maxAuctions);
			Atr_Batch_MaxStacksize_Text:SetText (ZT("max")..": "..gCurrentPane.fullStackSize);
			
			Atr_SetDepositText();			
		end

		if (gJustPosted_ItemName ~= nil) then

			Atr_Recommend_Text:SetText (string.format (ZT("Auction created for %s"), gJustPosted_ItemName));
			MoneyFrame_Update ("Atr_RecommendPerStack_Price", gJustPosted_BuyoutPrice);
			Atr_SetTextureButton ("Atr_RecommendItem_Tex", gJustPosted_StackSize, gJustPosted_ItemLink);

			gCurrentPane.currIndex = gCurrentPane.activeScan:FindInSortedData (gJustPosted_StackSize, gJustPosted_BuyoutPrice);

			if (gCurrentPane:ShowCurrent()) then
				Atr_HighlightEntry (gCurrentPane.currIndex);		-- highlight the newly created auction(s)
			else
				Atr_HighlightEntry (gCurrentPane.histIndex);
			end
		
		elseif (gCurrentPane:IsScanEmpty()) then
			Atr_SetMessage (ZT("Drag an item you want to sell to this area."));
		end
	end

	-- stuff we should do every time (not just when needsUpdate is true)
	
	local start		= MoneyInputFrame_GetCopper(Atr_StartingPrice);
	local buyout	= MoneyInputFrame_GetCopper(Atr_StackPrice);

	local pricesOK	= (start > 0 and (start <= buyout or buyout == 0) and (auctionItemName ~= nil));
	
	local numToSell = Atr_Batch_NumAuctions:GetNumber() * Atr_Batch_Stacksize:GetNumber();

	zc.EnableDisable (Atr_CreateAuctionButton,	pricesOK and (numToSell <= gCurrentPane.totalItems));
	
end

-----------------------------------------

function Atr_SetDepositText()
			
	_, auctionCount = Atr_GetSellItemInfo();
	
	if (auctionCount > 0) then
		local duration = UIDropDownMenu_GetSelectedValue(Atr_Duration);
	
		local deposit1 = CalculateAuctionDeposit (duration) / auctionCount;
		local numAuctionString = "";
		if (Atr_Batch_NumAuctions:GetNumber() > 1) then
			numAuctionString = "  |cffff55ff x"..Atr_Batch_NumAuctions:GetNumber();
		end
		
		Atr_Deposit_Text:SetText (ZT("Deposit")..":    "..zc.priceToMoneyString(deposit1 * Atr_StackSize(), true)..numAuctionString);
	else
		Atr_Deposit_Text:SetText ("");
	end
end


-----------------------------------------

function Atr_BuildActiveAuctions ()

	gActiveAuctions = {};
	
	local i = 1;
	while (true) do
		local name, _, count = GetAuctionItemInfo ("owner", i);
		if (name == nil) then
			break;
		end

		if (count > 0) then		-- count is 0 for sold items
			if (gActiveAuctions[name] == nil) then
				gActiveAuctions[name] = 1;
			else
				gActiveAuctions[name] = gActiveAuctions[name] + 1;
			end
		end
		
		i = i + 1;
	end
end

-----------------------------------------

function Atr_GetUCIcon (itemName)

	local icon = "|TInterface\\BUTTONS\\\UI-PassiveHighlight:18:18:0:0|t "

	local undercutFound = false;
	
	local scan = Atr_FindScan (itemName);
	if (scan and scan.absoluteBest and scan.whenScanned ~= 0 and scan.yourBestPrice and scan.yourWorstPrice) then
		
		local absBestPrice = scan.absoluteBest.itemPrice;
			
		if (scan.yourBestPrice <= absBestPrice and scan.yourWorstPrice > absBestPrice) then
			icon = "|TInterface\\AddOns\\Auctionator\\Images\\CrossAndCheck:18:18:0:0|t "
			undercutFound = true;
		elseif (scan.yourBestPrice <= absBestPrice) then
			icon = "|TInterface\\RAIDFRAME\\\ReadyCheck-Ready:18:18:0:0|t "
		else
			icon = "|TInterface\\RAIDFRAME\\\ReadyCheck-NotReady:18:18:0:0|t "
			undercutFound = true;
		end
	end

	if (gAtr_CheckingActive_State ~= ATR_CACT_NULL and undercutFound) then
		gAtr_CheckingActive_NumUndercuts = gAtr_CheckingActive_NumUndercuts + 1;
	end

	return icon;

end

-----------------------------------------

function Atr_DisplayHlist ()

	if (Atr_IsTabSelected (BUY_TAB)) then		-- done this way because OnScrollFrame always calls Atr_DisplayHlist
		Atr_DisplaySlist();
		return;
	end

	local doFull = (UIDropDownMenu_GetSelectedValue(Atr_DropDown1) == MODE_LIST_ALL);

	Atr_BuildGlobalHistoryList (doFull);
	
	local numrows = #gHistoryItemList;

	local line;							-- 1 through NN of our window to scroll
	local dataOffset;					-- an index into our data calculated from the scroll offset

	FauxScrollFrame_Update (Atr_Hlist_ScrollFrame, numrows, ITEM_HIST_NUM_LINES, 16);

	for line = 1,ITEM_HIST_NUM_LINES do

		gCurrentPane.hlistScrollOffset = FauxScrollFrame_GetOffset (Atr_Hlist_ScrollFrame);
		
		dataOffset = line + gCurrentPane.hlistScrollOffset;

		local lineEntry = getglobal ("AuctionatorHEntry"..line);

		lineEntry:SetID(dataOffset);

		if (dataOffset <= numrows and gHistoryItemList[dataOffset]) then

			local lineEntry_text = getglobal("AuctionatorHEntry"..line.."_EntryText");

			local iName = gHistoryItemList[dataOffset];

			local icon = "";
			
			if (not doFull) then
				icon = Atr_GetUCIcon (iName);
			end

			lineEntry_text:SetText	(icon..Atr_AbbrevItemName (iName));


			if (iName == gCurrentPane.activeSearch.searchText) then
				lineEntry:SetButtonState ("PUSHED", true);
			else
				lineEntry:SetButtonState ("NORMAL", false);
			end

			lineEntry:Show();
		else
			lineEntry:Hide();
		end
	end


end

-----------------------------------------

function Atr_ClearHlist ()
	local line;
	for line = 1,ITEM_HIST_NUM_LINES do
		local lineEntry = getglobal ("AuctionatorHEntry"..line);
		lineEntry:Hide();
		
		local lineEntry_text = getglobal("AuctionatorHEntry"..line.."_EntryText");
		lineEntry_text:SetText		("");
		lineEntry_text:SetTextColor	(.7,.7,.7);
	end

end

-----------------------------------------

function Atr_HEntryOnClick(itemName)

	if (gCurrentPane == gShopPane) then
		Atr_SEntryOnClick();
		return;
	end

	if (not itemName) then
		local line = this;

		if (gHentryTryAgain) then
			line = gHentryTryAgain;
			gHentryTryAgain = nil;
		end

		local _, itemLink;
		local entryIndex = line:GetID();
		
		itemName = gHistoryItemList[entryIndex];
	end

	if (IsAltKeyDown() and Atr_IsModeActiveAuctions()) then
		Atr_Cancel_Undercuts_OnClick (itemName)
		return;
	end
	
	if (AUCTIONATOR_PRICING_HISTORY[itemName]) then
		local itemId, suffixId, uniqueId = strsplit(":", AUCTIONATOR_PRICING_HISTORY[itemName]["is"])

		local itemId	= tonumber(itemId);

		if (suffixId == nil) then	suffixId = 0;
		else		 				suffixId = tonumber(suffixId);
		end

		if (uniqueId == nil) then	uniqueId = 0;
		else		 				uniqueId = tonumber(suffixId);
		end

		local itemString = "item:"..itemId..":0:0:0:0:0:"..suffixId..":"..uniqueId;

		_, itemLink = GetItemInfo(itemString);

		if (itemLink == nil) then		-- pull it into the cache and go back to the idle loop to wait for it to appear
			AtrScanningTooltip:SetHyperlink(itemString);
			gHentryTryAgain = line;
			zc.md ("pulling "..itemName.." into the local cache");
			return;
		end
	end
	
	gCurrentPane.UINeedsUpdate = true;
	
	Atr_ClearAll();
	
	local cacheHit = gCurrentPane:DoSearch (itemName, true, 20);

	Atr_Process_Historydata ();
	Atr_FindBestHistoricalAuction ();

	Atr_DisplayHlist();	 -- for the highlight

	if (cacheHit) then
		Atr_OnSearchComplete();
	end

	PlaySound ("igMainMenuOptionCheckBoxOn");
end

-----------------------------------------

function Atr_ShowWhichRB (id)

	if (gCurrentPane.activeSearch.processing_state ~= KM_NULL_STATE) then		-- if we're scanning auctions don't respond
		return;
	end

	PlaySound("igMainMenuOptionCheckBoxOn");

	if (id == 1) then
		gCurrentPane:SetToShowCurrent();
	elseif (id == 2) then
		gCurrentPane:SetToShowHistory();
	else
		gCurrentPane:SetToShowHints();
	end
	
	gCurrentPane.UINeedsUpdate = true;

end


-----------------------------------------

function Atr_RedisplayAuctions ()

	if (Atr_ShowingSearchSummary()) then
		Atr_ShowSearchSummary();
	elseif (Atr_ShowingCurrentAuctions()) then
		Atr_ShowCurrentAuctions();
	elseif Atr_ShowingHistory() then
		Atr_ShowHistory();
	else
		Atr_ShowHints();
	end
end

-----------------------------------------

function Atr_BuildHistItemText(data)

	local stacktext = "";
--	if (data.stackSize > 1) then
--		stacktext = " (stack of "..data.stackSize..")";
--	end

	local now		= time();
	local nowtime	= date ("*t");

	local when		= data.when;
	local whentime	= date ("*t", when);

	local numauctions = data.stackSize;

	local datestr = "";

	if (data.type == "hy") then
		return ZT("average of your auctions for").." "..whentime.year;
	elseif (data.type == "hm") then
		if (nowtime.year == whentime.year) then
			return ZT("average of your auctions for").." "..date("%B", when);
		else
			return ZT("average of your auctions for").." "..date("%B %Y", when);
		end
	elseif (data.type == "hd") then
		return ZT("average of your auctions for").." "..monthDay(whentime);
	else
		return ZT("your auction on").." "..monthDay(whentime)..date(" at %I:%M %p", when);
	end
end

-----------------------------------------

function monthDay (when)

	local t = time(when);

	local s = date("%b ", t);

	return s..when.day;

end

-----------------------------------------

function Atr_ShowLineTooltip (self)

	local itemLink = self.itemLink;
		
	if (itemLink) then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -280);
		GameTooltip:SetHyperlink (itemLink, 1);
	end
end

-----------------------------------------

function Atr_HideLineTooltip (self)
	GameTooltip:Hide();
end


-----------------------------------------

function Atr_Onclick_Back ()

	gCurrentPane.activeScan = Atr_FindScan (nil);
	gCurrentPane.UINeedsUpdate = true;

end

-----------------------------------------

function Atr_Onclick_Col1 ()

	if (gCurrentPane.activeSearch) then
		gCurrentPane.activeSearch:ClickPriceCol();
		gCurrentPane.UINeedsUpdate = true;
	end

end

-----------------------------------------

function Atr_Onclick_Col3 ()

	if (gCurrentPane.activeSearch) then
		gCurrentPane.activeSearch:ClickNameCol();
		gCurrentPane.UINeedsUpdate = true;
	end

end

-----------------------------------------

function Atr_ShowSearchSummary()

	Atr_Col1_Heading:Hide();
	Atr_Col3_Heading:Hide();
	Atr_Col1_Heading_Button:Show();
	Atr_Col3_Heading_Button:Show();
	Atr_Col4_Heading:Show();

	gCurrentPane.activeSearch:UpdateArrows ();

	local numrows = gCurrentPane.activeSearch:NumScans();

	if (gCurrentPane.activeScan.hasStack) then
		Atr_Col4_Heading:SetText (ZT("Total Price"));
	else
		Atr_Col4_Heading:SetText ("");
	end

	local highIndex  = 0;
	local line		 = 0;															-- 1 through 12 of our window to scroll
	local dataOffset = FauxScrollFrame_GetOffset (AuctionatorScrollFrame);			-- an index into our data calculated from the scroll offset

	FauxScrollFrame_Update (AuctionatorScrollFrame, numrows, 12, 16);

	while (line < 12) do

		dataOffset	= dataOffset + 1;
		line		= line + 1;

		local lineEntry = getglobal ("AuctionatorEntry"..line);

		lineEntry:SetID(dataOffset);

		local scn;
		
		if (gCurrentPane.activeSearch and gCurrentPane.activeSearch:NumSortedScans() > 0) then
			scn = gCurrentPane.activeSearch.sortedScans[dataOffset];
		end
		
		if (dataOffset > numrows or not scn) then

			lineEntry:Hide();

		else
			local data = scn.absoluteBest;

			local lineEntry_item_tag = "AuctionatorEntry"..line.."_PerItem_Price";

			local lineEntry_item		= getglobal(lineEntry_item_tag);
			local lineEntry_itemtext	= getglobal("AuctionatorEntry"..line.."_PerItem_Text");
			local lineEntry_text		= getglobal("AuctionatorEntry"..line.."_EntryText");
			local lineEntry_stack		= getglobal("AuctionatorEntry"..line.."_StackPrice");

			lineEntry_itemtext:SetText	("");
			lineEntry_text:SetText	("");
			lineEntry_stack:SetText	("");

			lineEntry_text:GetParent():SetPoint ("LEFT", 157, 0);
			
			Atr_SetMFcolor (lineEntry_item_tag);
			
			lineEntry:Show();

			lineEntry.itemLink = scn.itemLink;
			
			local r = scn.itemTextColor[1];
			local g = scn.itemTextColor[2];
			local b = scn.itemTextColor[3];
			
			lineEntry_text:SetTextColor (r, g, b);
			lineEntry_stack:SetTextColor (1, 1, 1);
			
			local icon = Atr_GetUCIcon (scn.itemName);
			
			lineEntry_text:SetText (icon.."  "..scn.itemName);
			lineEntry_stack:SetText (scn:GetNumAvailable().." "..ZT("available"));
			
			if (data == nil or data.buyoutPrice == 0) then
				lineEntry_item:Hide();
				lineEntry_itemtext:Show();
				lineEntry_itemtext:SetText (ZT("no buyout price"));
			else
				lineEntry_item:Show();
				lineEntry_itemtext:Hide();
				MoneyFrame_Update (lineEntry_item_tag, zc.round(data.buyoutPrice/data.stackSize) );
			end
			
			if (zc.StringSame (scn.itemName , gCurrentPane.SS_hilite_itemName)) then
				highIndex = dataOffset;
			end


		end
	end
	
	Atr_HighlightEntry (highIndex);		-- need this for when called from onVerticalScroll

end

-----------------------------------------

function Atr_ShowCurrentAuctions()

	Atr_Col1_Heading:Hide();
	Atr_Col3_Heading:Hide();
	Atr_Col4_Heading:Hide();
	Atr_Col1_Heading_Button:Hide();
	Atr_Col3_Heading_Button:Hide();


	local numrows = #gCurrentPane.activeScan.sortedData;

	if (numrows > 0) then
		Atr_Col1_Heading:Show();
		Atr_Col3_Heading:Show();
		Atr_Col4_Heading:Show();
	end

	Atr_Col1_Heading:SetText (ZT("Item Price"));
	Atr_Col3_Heading:SetText (ZT("Current Auctions"));

	if (gCurrentPane.activeScan.hasStack) then
		Atr_Col4_Heading:SetText (ZT("Stack Price"));
	else
		Atr_Col4_Heading:SetText ("");
	end

	local line		 = 0;															-- 1 through 12 of our window to scroll
	local dataOffset = FauxScrollFrame_GetOffset (AuctionatorScrollFrame);			-- an index into our data calculated from the scroll offset

	FauxScrollFrame_Update (AuctionatorScrollFrame, numrows, 12, 16);

	while (line < 12) do

		dataOffset	= dataOffset + 1;
		line		= line + 1;

		local lineEntry = getglobal ("AuctionatorEntry"..line);

		lineEntry:SetID(dataOffset);

		lineEntry.itemLink = nil;

		if (dataOffset > numrows or not gCurrentPane.activeScan.sortedData[dataOffset]) then

			lineEntry:Hide();

		else
			local data = gCurrentPane.activeScan.sortedData[dataOffset];

			local lineEntry_item_tag = "AuctionatorEntry"..line.."_PerItem_Price";

			local lineEntry_item		= getglobal(lineEntry_item_tag);
			local lineEntry_itemtext	= getglobal("AuctionatorEntry"..line.."_PerItem_Text");
			local lineEntry_text		= getglobal("AuctionatorEntry"..line.."_EntryText");
			local lineEntry_stack		= getglobal("AuctionatorEntry"..line.."_StackPrice");

			lineEntry_itemtext:SetText	("");
			lineEntry_text:SetText	("");
			lineEntry_stack:SetText	("");

			lineEntry_text:GetParent():SetPoint ("LEFT", 172, 0);

			Atr_SetMFcolor (lineEntry_item_tag);
			
			local entrytext = "";

			if (data.type == "n") then

				lineEntry:Show();

				if (data.count == 1) then
					entrytext = string.format ("%i %s %i", data.count, ZT ("stack of"), data.stackSize);
				else
					entrytext = string.format ("%i %s %i", data.count, ZT ("stacks of"), data.stackSize);
				end
				
				lineEntry_text:SetTextColor (0.6, 0.6, 0.6);
				
				if ( data.stackSize == Atr_StackSize() or Atr_StackSize() == 0 or gCurrentPane ~= gSellPane) then
					lineEntry_text:SetTextColor (1.0, 1.0, 1.0);
				end

				if (data.yours) then
					 entrytext = entrytext.." ("..ZT("yours")..")";
				elseif (data.altname) then
					 entrytext = entrytext.." ("..data.altname..")";
				end

				-- local ccc = zc.If (data.minpage ~= data.maxpage, "|cffff8888", "");
				-- entrytext = zc.msg_str (entrytext, "     ", ccc, data.minpage, " / ", data.maxpage, "         ", gCurrentPane.activeScan.searchWasExact);
				
				lineEntry_text:SetText (entrytext);

				if (data.buyoutPrice == 0) then
					lineEntry_item:Hide();
					lineEntry_itemtext:Show();
					lineEntry_itemtext:SetText (ZT("no buyout price"));
				else
					lineEntry_item:Show();
					lineEntry_itemtext:Hide();
					MoneyFrame_Update (lineEntry_item_tag, zc.round(data.buyoutPrice/data.stackSize) );

					if (data.stackSize > 1) then
						lineEntry_stack:SetText (zc.priceToString(data.buyoutPrice));
						lineEntry_stack:SetTextColor (0.6, 0.6, 0.6);
					end
				end
			
			else
				zc.msg_red ("Unknown datatype:");
				zc.msg_red (data.type);
			end
		end
	end
	
	Atr_HighlightEntry (gCurrentPane.currIndex);		-- need this for when called from onVerticalScroll
end

-----------------------------------------

function Atr_ShowHistory ()

	if (gCurrentPane.sortedHist == nil) then
		Atr_Process_Historydata ();
		Atr_FindBestHistoricalAuction ();
	end
		
	Atr_Col1_Heading:Hide();
	Atr_Col3_Heading:Hide();
	Atr_Col4_Heading:Hide();

	Atr_Col3_Heading:SetText (ZT("History"));

	local numrows = gCurrentPane.sortedHist and #gCurrentPane.sortedHist or 0;

--zc.msg ("gCurrentPane.sortedHist: "..numrows,1,0,0);

	if (numrows > 0) then
		Atr_Col1_Heading:Show();
		Atr_Col3_Heading:Show();
	end

	local line;							-- 1 through 12 of our window to scroll
	local dataOffset;					-- an index into our data calculated from the scroll offset

	FauxScrollFrame_Update (AuctionatorScrollFrame, numrows, 12, 16);

	for line = 1,12 do

		dataOffset = line + FauxScrollFrame_GetOffset (AuctionatorScrollFrame);

		local lineEntry = getglobal ("AuctionatorEntry"..line);

		lineEntry:SetID(dataOffset);

		if (dataOffset <= numrows and gCurrentPane.sortedHist[dataOffset]) then

			local data = gCurrentPane.sortedHist[dataOffset];

			local lineEntry_item_tag = "AuctionatorEntry"..line.."_PerItem_Price";

			local lineEntry_item		= getglobal(lineEntry_item_tag);
			local lineEntry_itemtext	= getglobal("AuctionatorEntry"..line.."_PerItem_Text");
			local lineEntry_text		= getglobal("AuctionatorEntry"..line.."_EntryText");
			local lineEntry_stack		= getglobal("AuctionatorEntry"..line.."_StackPrice");

			lineEntry_item:Show();
			lineEntry_itemtext:Hide();
			lineEntry_stack:SetText	("");

			Atr_SetMFcolor (lineEntry_item_tag);

			MoneyFrame_Update (lineEntry_item_tag, zc.round(data.itemPrice) );

			lineEntry_text:SetText (Atr_BuildHistItemText (data));
			lineEntry_text:SetTextColor (0.8, 0.8, 1.0);

			lineEntry:Show();
		else
			lineEntry:Hide();
		end
	end

	if (Atr_IsTabSelected (SELL_TAB)) then
		Atr_HighlightEntry (gCurrentPane.histIndex);		-- need this for when called from onVerticalScroll
	else
		Atr_HighlightEntry (-1);
	end
end


-----------------------------------------

function Atr_FindBestCurrentAuction()

	local scan = gCurrentPane.activeScan;
	
	if		(Atr_IsModeCreateAuction()) then	gCurrentPane.currIndex = scan:FindCheapest ();
	elseif	(Atr_IsModeBuy()) then				gCurrentPane.currIndex = scan:FindCheapest ();
	else										gCurrentPane.currIndex = scan:FindMatchByYours ();
	end

end

-----------------------------------------

function Atr_FindBestHistoricalAuction()

	gCurrentPane.histIndex = nil;

	if (gCurrentPane.sortedHist and #gCurrentPane.sortedHist > 0) then
		gCurrentPane.histIndex = 1;
	end
end

-----------------------------------------

function Atr_HighlightEntry(entryIndex)

	local line;				-- 1 through 12 of our window to scroll

	for line = 1,12 do

		local lineEntry = getglobal ("AuctionatorEntry"..line);

		if (lineEntry:GetID() == entryIndex) then
			lineEntry:SetButtonState ("PUSHED", true);
		else
			lineEntry:SetButtonState ("NORMAL", false);
		end
	end

	local doEnableCancel = false;
	local doEnableBuy = false;
	local data;
	
	if (Atr_ShowingCurrentAuctions() and entryIndex ~= nil and entryIndex > 0 and entryIndex <= #gCurrentPane.activeScan.sortedData) then
		data = gCurrentPane.activeScan.sortedData[entryIndex];
		if (data.yours) then
			doEnableCancel = true;
		end
		
		if (not data.yours and not data.altname and data.buyoutPrice > 0) then
			doEnableBuy = true;
		end
	end

	Atr_Buy1_Button:Disable();
	Atr_CancelSelectionButton:Disable();
	
	if (doEnableCancel) then
		Atr_CancelSelectionButton:Enable();

		if (data.count == 1) then
			Atr_CancelSelectionButton:SetText (CANCEL_AUCTION);
		else
			Atr_CancelSelectionButton:SetText (ZT("Cancel Auctions"));
		end
	end

	if (doEnableBuy) then
		Atr_Buy1_Button:Enable();
	end
	
end

-----------------------------------------

function Atr_EntryOnClick()

	local entryIndex = this:GetID();

	if     (Atr_ShowingSearchSummary()) 	then	
	elseif (Atr_ShowingCurrentAuctions())	then		gCurrentPane.currIndex = entryIndex;
	elseif (Atr_ShowingHistory())			then		gCurrentPane.histIndex = entryIndex;
	else												gCurrentPane.hintsIndex = entryIndex;
	end

	if (Atr_ShowingSearchSummary()) then
		local scn = gCurrentPane.activeSearch.sortedScans[entryIndex];

		FauxScrollFrame_SetOffset (AuctionatorScrollFrame, 0);
		gCurrentPane.activeScan = scn;
		gCurrentPane.currIndex = scn:FindMatchByYours ();
		gCurrentPane.SS_hilite_itemName = scn.itemName;
		gCurrentPane.UINeedsUpdate = true;
	else
		Atr_HighlightEntry (entryIndex);
		Atr_UpdateRecommendation(true);
	end

	PlaySound ("igMainMenuOptionCheckBoxOn");
end

-----------------------------------------

function AuctionatorMoneyFrame_OnLoad()

	this.small = 1;
	MoneyFrame_SetType(this, "AUCTION");
end


-----------------------------------------

function Atr_GetNumItemInBags (theItemName)

	local numItems = 0;
	local b, bagID, slotID, numslots;
	
	for b = 1, #kBagIDs do
		bagID = kBagIDs[b];
		
		numslots = GetContainerNumSlots (bagID);
		for slotID = 1,numslots do
			local itemLink = GetContainerItemLink(bagID, slotID);
			if (itemLink) then
				local itemName				= GetItemInfo(itemLink);
				local texture, itemCount	= GetContainerItemInfo(bagID, slotID);

				if (itemName == theItemName) then
					numItems = numItems + itemCount;
				end
			end
		end
	end

	return numItems;

end

-----------------------------------------

function Atr_CancelAuction(x)

	CancelAuction(x);

end

-----------------------------------------

function Atr_LogCancelAuction(numCancelled, itemLink, stackSize)
	
	local SSstring = "";
	if (stackSize and stackSize > 1) then
		SSstring = "|cff00ddddx"..stackSize;
	end

	if (numCancelled > 1) then
		zc.msg_yellow (numCancelled..ZT(" auctions cancelled for ")..itemLink..SSstring);
	elseif (numCancelled == 1) then
		zc.msg_yellow (ZT("Auction cancelled for ")..itemLink..SSstring);
	end
	
end

-----------------------------------------

function Atr_CancelSelection_OnClick()

	if (not Atr_ShowingCurrentAuctions()) then
		return;
	end
	
	Atr_CancelAuction_ByIndex (gCurrentPane.currIndex);
end

-----------------------------------------

function Atr_CancelAuction_ByIndex(index)

	local data = gCurrentPane.activeScan.sortedData[index];

	if (not data.yours) then
		return;
	end

	local numCancelled	= 0;
	local itemLink		= gCurrentPane.activeScan.itemLink;
	
	local i = 1;

	while (true) do
		local name, texture, count, quality, canUse, level,
		minBid, minIncrement, buyoutPrice, bidAmount,
		highBidder, owner = GetAuctionItemInfo ("owner", i);

		if (name == nil) then
			break;
		end

		if (name == gCurrentPane.activeScan.itemName and buyoutPrice == data.buyoutPrice and count == data.stackSize) then
			Atr_CancelAuction (i);
			numCancelled = numCancelled + 1;
			AuctionatorSubtractFromScan (name, count, buyoutPrice);
			gJustPosted_ItemName = nil;
		end

		i = i + 1;
	end

	Atr_LogCancelAuction (numCancelled, itemLink, data.stackSize);

end

-----------------------------------------

function Atr_StackingPrefs_Init ()

	AUCTIONATOR_STACKING_PREFS = {};                
end

-----------------------------------------

function Atr_Has_StackingPrefs (key)

	local lkey = key:lower();

	return (AUCTIONATOR_STACKING_PREFS[lkey] ~= nil);            
end

-----------------------------------------

function Atr_Clear_StackingPrefs (key)

	local lkey = key:lower();

	AUCTIONATOR_STACKING_PREFS[lkey] = nil;            
end

-----------------------------------------

function Atr_Get_StackingPrefs (key)

	local lkey = key:lower();

	if (Atr_Has_StackingPrefs(lkey)) then
		return AUCTIONATOR_STACKING_PREFS[lkey].numstacks, AUCTIONATOR_STACKING_PREFS[lkey].stacksize;            
	end

	return nil, nil;

end

-----------------------------------------

function Atr_Set_StackingPrefs_numstacks (key, numstacks)

	local lkey = key:lower();

	if (not Atr_Has_StackingPrefs(lkey)) then
		AUCTIONATOR_STACKING_PREFS[lkey] = { stacksize = 0 };
	end

	AUCTIONATOR_STACKING_PREFS[lkey].numstacks = zc.Val (numstacks, 1);            
end

-----------------------------------------

function Atr_Set_StackingPrefs_stacksize (key, stacksize)

	local lkey = key:lower();

	if (not Atr_Has_StackingPrefs(lkey)) then
		AUCTIONATOR_STACKING_PREFS[lkey] = { numstacks = 0};
	end

	AUCTIONATOR_STACKING_PREFS[lkey].stacksize = zc.Val (stacksize, 1);            
end

-----------------------------------------

function Atr_GetStackingPrefs_ByItem (itemLink)

	if (itemLink) then
	
		local itemName = GetItemInfo (itemLink);
		local text, spinfo;
		
		for text, spinfo in pairs (AUCTIONATOR_STACKING_PREFS) do

			if (zc.StringContains (itemName, text)) then
				return spinfo.numstacks, spinfo.stacksize;
			end
		end
		
		if		(Atr_IsGlyph (itemLink))								then		return Atr_Special_SP (ATR_SK_GLYPHS, 0, 1);
		elseif	(Atr_IsCutGem (itemLink))								then		return Atr_Special_SP (ATR_SK_GEMS_CUT, 0, 1);
		elseif	(Atr_IsGem (itemLink))									then		return Atr_Special_SP (ATR_SK_GEMS_UNCUT, 1, 0);
		elseif	(Atr_IsItemEnhancement (itemLink))						then		return Atr_Special_SP (ATR_SK_ITEM_ENH, 0, 1);
		elseif	(Atr_IsPotion (itemLink) or Atr_IsElixir (itemLink))	then		return Atr_Special_SP (ATR_SK_POT_ELIX, 1, 0);
		elseif	(Atr_IsFlask (itemLink))								then		return Atr_Special_SP (ATR_SK_FLASKS, 1, 0);
		elseif	(Atr_IsHerb (itemLink))									then		return Atr_Special_SP (ATR_SK_HERBS, 1, 0);
		end
	end
	
	return nil, nil;
end

-----------------------------------------

function Atr_Special_SP (key, numstack, stacksize)

	if (Atr_Has_StackingPrefs (key)) then
		return Atr_Get_StackingPrefs(key);
	end
	
	return numstack, stacksize;
end

-----------------------------------------

function Atr_GetSellStacking (itemLink, numDragged, numTotal)

	local prefNumStacks, prefStackSize = Atr_GetStackingPrefs_ByItem (itemLink);
	
	if (prefNumStacks == nil) then
		return 1, numDragged;
	end
	
	if (prefNumStacks <= 0 and prefStackSize <= 0) then		-- shouldn't happen but just in case
		prefStackSize = 1;
	end

--zc.msg (prefNumStacks, prefStackSize);

	local numStacks = prefNumStacks;
	local stackSize = prefStackSize;
	local numToSell = numDragged;
	
	if (numStacks == -1) then		-- max number of stacks
		numToSell = numTotal;

	elseif (stackSize == 0) then		-- auto stacksize
		stackSize = math.floor (numDragged / numStacks);
	
	elseif (numStacks > 0) then
		numToSell = math.min (numStacks * stackSize, numTotal);
	end

	numStacks = math.floor (numToSell / stackSize);

--zc.msg_pink (numStacks, stackSize);
	
	if (numStacks == 0) then
		numStacks = 1;
		stackSize = numToSell;
--zc.msg_red (numStacks, stackSize);
	end
	
	return numStacks, stackSize;

end



-----------------------------------------

local gInitial_NumStacks;
local gInitial_StackSize;

-----------------------------------------

function Atr_SetInitialStacking (numStacks, stackSize)

	gInitial_NumStacks = numStacks;
	gInitial_StackSize = stackSize;

	Atr_Batch_NumAuctions:SetText (numStacks);
	Atr_SetStackSize (stackSize);
end

-----------------------------------------

function Atr_Memorize_Stacking_If ()

	local newNumStacks = Atr_Batch_NumAuctions:GetNumber();
	local newStackSize = Atr_StackSize();
	
	local numStacksChanged = (tonumber (gInitial_NumStacks) ~= newNumStacks);
	local stackSizeChanged = (tonumber (gInitial_StackSize) ~= newStackSize);

	if (stackSizeChanged) then
	
		local itemName = string.lower(gCurrentPane.activeScan.itemName);

		if (itemName) then

			-- see if user is trying to set it back to default
			
			if (newNumStacks == 1) then
				local _, _, auctionCount = GetAuctionSellItemInfo();
				if (auctionCount == newStackSize) then
					Atr_Clear_StackingPrefs (itemName);
					return;
				end
			end
			
			-- else remember the new stack size
			
			Atr_Set_StackingPrefs_stacksize (itemName, Atr_StackSize());
		end
	end
end




-----------------------------------------

function Atr_Duration_OnLoad(self)
	UIDropDownMenu_Initialize (self, Atr_Duration_Initialize);
	UIDropDownMenu_SetSelectedValue (Atr_Duration, 1);
end

-----------------------------------------

function Atr_Duration_OnShow(self)
	UIDropDownMenu_Initialize (self, Atr_Duration_Initialize);
end

-----------------------------------------

function Atr_Duration_Initialize()

	local info = UIDropDownMenu_CreateInfo();

	info.text = AUCTION_DURATION_ONE;
	info.value = 1;
	info.checked = nil;
	info.func = Atr_Duration_OnClick;
	UIDropDownMenu_AddButton(info);

	info.text = AUCTION_DURATION_TWO;
	info.value = 2;
	info.checked = nil;
	info.func = Atr_Duration_OnClick;
	UIDropDownMenu_AddButton(info);

	info.text = AUCTION_DURATION_THREE;
	info.value = 3;
	info.checked = nil;
	info.func = Atr_Duration_OnClick;
	UIDropDownMenu_AddButton(info);

end

-----------------------------------------

function Atr_Duration_OnClick(self)

	UIDropDownMenu_SetSelectedValue(Atr_Duration, self.value);
	Atr_SetDepositText();
end

-----------------------------------------

function Atr_DropDown1_OnLoad (self)
	UIDropDownMenu_Initialize(self, Atr_DropDown1_Initialize);
	UIDropDownMenu_SetSelectedValue(Atr_DropDown1, MODE_LIST_ACTIVE);
	Atr_DropDown1:Show();
end

-----------------------------------------

function Atr_DropDown1_Initialize()
	local info = UIDropDownMenu_CreateInfo();
	
	info.text = ZT("Active Items");
	info.value = MODE_LIST_ACTIVE;
	info.func = Atr_DropDown1_OnClick;
	info.owner = this:GetParent();
	info.checked = nil;
	UIDropDownMenu_AddButton(info);

	info.text = ZT("All Items");
	info.value = MODE_LIST_ALL;
	info.func = Atr_DropDown1_OnClick;
	info.owner = this:GetParent();
	info.checked = nil;
	UIDropDownMenu_AddButton(info);

end

-----------------------------------------

function Atr_DropDown1_OnClick(self)
	
	UIDropDownMenu_SetSelectedValue(self.owner, self.value);
	
	local mode = self.value;
	
	if (mode == MODE_LIST_ALL) then
		Atr_DisplayHlist();
	end
	
	if (mode == MODE_LIST_ACTIVE) then
		Atr_DisplayHlist();
	end
	
end



-----------------------------------------

function Atr_AddMenuPick (info, text, value, func)

	info.text			= text;
	info.value			= value;
	info.func			= func;
	info.checked		= nil;
	info.owner			= this:GetParent();
	UIDropDownMenu_AddButton(info);

end

-----------------------------------------

function Atr_Dropdown_AddPick (frame, text, value, func)

	local info = UIDropDownMenu_CreateInfo();

	info.arg1			= frame;
	info.text			= text;
	info.value			= value;
	info.checked		= nil;

	if (func) then
		info.func = func;
	else
		info.func = Atr_Dropdown_OnClick;
	end
	
	UIDropDownMenu_AddButton(info);
end

-----------------------------------------

function Atr_Dropdown_OnClick (info, frame, arg2, checked)

	UIDropDownMenu_SetSelectedValue (frame, info.value);

end

-----------------------------------------

function Atr_IsTabSelected(whichTab)

	if (not AuctionFrame or not AuctionFrame:IsShown()) then
		return false;
	end

	if (not whichTab) then
		return (Atr_IsTabSelected(SELL_TAB) or Atr_IsTabSelected(MORE_TAB) or Atr_IsTabSelected(BUY_TAB));
	end

	return (PanelTemplates_GetSelectedTab (AuctionFrame) == Atr_FindTabIndex(whichTab));
end

-----------------------------------------

function Atr_IsAuctionatorTab (tabIndex)

	if (tabIndex == Atr_FindTabIndex(SELL_TAB) or tabIndex == Atr_FindTabIndex(MORE_TAB) or tabIndex == Atr_FindTabIndex(BUY_TAB) ) then

		return true;

	end

	return false;
end

-----------------------------------------

function Atr_Confirm_Yes()

	if (Atr_Confirm_Proc_Yes) then
		Atr_Confirm_Proc_Yes();
		Atr_Confirm_Proc_Yes = nil;
	end

	Atr_Confirm_Frame:Hide();

end


-----------------------------------------

function Atr_Confirm_No()

	Atr_Confirm_Frame:Hide();

end


-----------------------------------------

function Atr_AddHistoricalPrice (itemName, price, stacksize, itemLink, testwhen)

	if (not AUCTIONATOR_PRICING_HISTORY[itemName] ) then
		AUCTIONATOR_PRICING_HISTORY[itemName] = {};
	end

	local itemId, suffixId, uniqueId = zc.ItemIDfromLink (itemLink);

	local is = itemId;

	if (suffixId ~= 0) then
		is = is..":"..suffixId;
		if (tonumber(suffixId) < 0) then
			is = is..":"..uniqueId;
		end
	end

	AUCTIONATOR_PRICING_HISTORY[itemName]["is"]  = is;

	local hist = tostring (zc.round (price))..":"..stacksize;

	local roundtime = floor (time() / 60) * 60;		-- so multiple auctions close together don't generate too many entries

	local tag = tostring(ToTightTime(roundtime));

	if (testwhen) then
		tag = tostring(ToTightTime(testwhen));
	end

	AUCTIONATOR_PRICING_HISTORY[itemName][tag] = hist;

	gCurrentPane.sortedHist = nil;

end

-----------------------------------------

function Atr_HasHistoricalData (itemName)

	if (AUCTIONATOR_PRICING_HISTORY[itemName] ) then
		return true;
	end

	return false;
end


-----------------------------------------

function Atr_BuildGlobalHistoryList(full)

	gHistoryItemList	= {};
	
	local n = 1;

	if (full) then
		for name,hist in pairs (AUCTIONATOR_PRICING_HISTORY) do
			gHistoryItemList[n] = name;
			n = n + 1;
		end
	else
		if (zc.tableIsEmpty (gActiveAuctions)) then
			Atr_BuildActiveAuctions();
		end

		local name;
		for name, count in pairs (gActiveAuctions) do
			if (name and count ~= 0) then
				gHistoryItemList[n] = name;
				n = n + 1;
			end
		end
	end
	
	table.sort (gHistoryItemList);
end



-----------------------------------------

function Atr_FindHListIndexByName (itemName)

	local x;
	
	for x = 1, #gHistoryItemList do
		if (itemName == gHistoryItemList[x]) then
			return x;
		end
	end

	return 0;
	
end

-----------------------------------------

local gAtr_CheckingActive_State			= ATR_CACT_NULL;
local gAtr_CheckingActive_Index;
local gAtr_CheckingActive_NextItemName;
local gAtr_CheckingActive_AndCancel		= false;

gAtr_CheckingActive_NumUndercuts	= 0;


-----------------------------------------

function Atr_CheckActive_OnClick (andCancel)

	if (gAtr_CheckingActive_State == ATR_CACT_NULL) then
	
		Atr_CheckActiveList (andCancel);
--[[
		if (andCancel == nil) then
			Atr_CheckActives_Frame:Show();
		else
			Atr_CheckActives_Frame:Hide();
			Atr_CheckActiveList (andCancel);
		end
]]--
	else		-- stop checking
		Atr_CheckingActive_Finish ();
		gCurrentPane.activeSearch:Abort();
		gCurrentPane:ClearSearch();
		Atr_SetMessage(ZT("Checking stopped"));
	end
	
end


-----------------------------------------

function Atr_CheckActiveList (andCancel)

	gAtr_CheckingActive_State			= ATR_CACT_READY;
	gAtr_CheckingActive_NextItemName	= gHistoryItemList[1];
	gAtr_CheckingActive_AndCancel		= andCancel;
	gAtr_CheckingActive_NumUndercuts	= 0;
	
	gCurrentPane:SetToShowCurrent();

	Atr_CheckingActiveIdle ();
	
end

-----------------------------------------

function Atr_CheckingActive_Finish()

	gAtr_CheckingActive_State = ATR_CACT_NULL;		-- done
	
	Atr_CheckActiveButton:SetText(ZT("Check for Undercuts"));

end



-----------------------------------------

function Atr_CheckingActiveIdle()

	if (gAtr_CheckingActive_State == ATR_CACT_READY) then
	
		if (gAtr_CheckingActive_NextItemName == nil) then
		
			Atr_CheckingActive_Finish ();

			if (gAtr_CheckingActive_NumUndercuts > 0) then
				Atr_CheckActives_Frame:Show();
			end
			
		else
			gAtr_CheckingActive_State = ATR_CACT_PROCESSING;

			Atr_CheckActiveButton:SetText(ZT("Stop Checking"));

			local itemName = gAtr_CheckingActive_NextItemName;

			local x = Atr_FindHListIndexByName (itemName);
			gAtr_CheckingActive_NextItemName = (x > 0 and #gHistoryItemList >= x+1) and gHistoryItemList[x+1] or nil;

			local cacheHit = gCurrentPane:DoSearch (itemName, true, 15);
			
			Atr_Hilight_Hentry (itemName);
			
			if (cacheHit) then
				Atr_CheckingActive_OnSearchComplete();
			end
		end
	end
end


-----------------------------------------

function Atr_CheckActive_IsBusy()

	return (gAtr_CheckingActive_State ~= ATR_CACT_NULL);
	
end

-----------------------------------------

function Atr_CheckingActive_OnSearchComplete()

	if (gAtr_CheckingActive_State == ATR_CACT_PROCESSING) then
		
		if (gAtr_CheckingActive_AndCancel) then
			zc.AddDeferredCall (0.1, "Atr_CheckingActive_CheckCancel");		-- need to defer so UI can update and show auctions about to be canceled
		else
			zc.AddDeferredCall (0.1, "Atr_CheckingActive_Next");			-- need to defer so UI can update
		end
	end
end

-----------------------------------------

function Atr_CheckingActive_CheckCancel()

	if (gAtr_CheckingActive_State == ATR_CACT_PROCESSING) then

		Atr_CancelUndercuts_CurrentScan(false);

		if (gAtr_CheckingActive_State ~= ATR_CACT_WAITING_ON_CANCEL_CONFIRM) then
			zc.AddDeferredCall (0.1, "Atr_CheckingActive_Next");		-- need to defer so UI can update
		end
	end
	
end

-----------------------------------------

function Atr_CheckingActive_Next ()

	if (gAtr_CheckingActive_State == ATR_CACT_PROCESSING) then
		gAtr_CheckingActive_State = ATR_CACT_READY;
	end
end


-----------------------------------------

function Atr_CancelUndercut_Confirm (yesCancel)
	gAtr_CheckingActive_State = ATR_CACT_PROCESSING;
	Atr_CancelAuction_Confirm_Frame:Hide();
	if (yesCancel) then
		Atr_CancelUndercuts_CurrentScan(true);
	end
	zc.AddDeferredCall (0.1, "Atr_CheckingActive_Next");
end

-----------------------------------------

function Atr_CancelUndercuts_CurrentScan(confirmed)

	local scan = gCurrentPane.activeScan;

	for x = #scan.sortedData,1,-1 do
	
		local data = scan.sortedData[x];
		
		if (data.yours and data.itemPrice > scan.absoluteBest.itemPrice) then
			
			if (not confirmed) then
				gAtr_CheckingActive_State = ATR_CACT_WAITING_ON_CANCEL_CONFIRM;
				Atr_CancelAuction_Confirm_Frame_text:SetText (string.format (ZT("Your auction has been undercut:\n%s%s"), "|cffffffff", scan.itemName));
				Atr_CancelAuction_Confirm_Frame:Show ();
				return;
			end
			
			Atr_CancelAuction_ByIndex (x);
		end
	end

end


-----------------------------------------

function Atr_Cancel_Undercuts_OnClick (nameToCancel)

	local i;
	local num = GetNumAuctionItems ("owner");

	local cancelled = {};
	
	for i = num, 1, -1 do
		local name, _, stackSize, _, _, _, _, _, buyoutPrice = GetAuctionItemInfo ("owner", i);

		if (name == nil) then
			break;
		end
		
		if (nameToCancel == nil or zc.StringSame (name, nameToCancel)) then
			local scan = Atr_FindScan (name);
			if (scan and scan.absoluteBest and scan.whenScanned ~= 0 and scan.yourBestPrice and scan.yourWorstPrice) then
				
				local absBestPrice = scan.absoluteBest.itemPrice;
				
				local itemPrice = math.floor (buyoutPrice / stackSize);
		
				--	zc.md (i, name, "itemPrice: ", itemPrice, "absBestPrice: ", absBestPrice);

				if (itemPrice > absBestPrice) then

					Atr_CancelAuction (i);
					
					if (cancelled[name] == nil) then
						cancelled[name]				= {};
						cancelled[name].num			= 0;
						cancelled[name].link		= scan.itemLink;
						cancelled[name].stackSize	= stackSize;
					end
					
					cancelled[name].num = cancelled[name].num + 1;
					
					if (scan.yourBestPrice > absBestPrice) then
						gActiveAuctions[name] = nil;
					end

					AuctionatorSubtractFromScan (name, stackSize, buyoutPrice);
					gJustPosted_ItemName = nil;
				end
			end
		end
	end

	local nm, cancelInfo;
	for nm, cancelInfo in pairs (cancelled) do
		Atr_LogCancelAuction (cancelInfo.num, cancelInfo.link, cancelInfo.stackSize);
	end

	Atr_DisplayHlist();
	Atr_CheckActives_Frame:Hide();
end

-----------------------------------------

function Atr_Hilight_Hentry(itemName)

	for line = 1,ITEM_HIST_NUM_LINES do

		dataOffset = line + FauxScrollFrame_GetOffset (Atr_Hlist_ScrollFrame);

		local lineEntry = getglobal ("AuctionatorHEntry"..line);

		if (dataOffset <= #gHistoryItemList and gHistoryItemList[dataOffset]) then

			if (gHistoryItemList[dataOffset] == itemName) then
				lineEntry:SetButtonState ("PUSHED", true);
			else
				lineEntry:SetButtonState ("NORMAL", false);
			end
		end
	end
end

-----------------------------------------

function Atr_Item_Autocomplete(self)

	local text = self:GetText();
	local textlen = strlen(text);
	local name;

	-- first search shopping lists

	local numLists = #AUCTIONATOR_SHOPPING_LISTS;
	local n;
	
	for n = 1,numLists do
		local slist = AUCTIONATOR_SHOPPING_LISTS[n];

		local numItems = #slist.items;

		if ( numItems > 0 ) then
			for i=1, numItems do
				name = slist.items[i];
				if ( name and text and (strfind(strupper(name), strupper(text), 1, 1) == 1) ) then
					self:SetText(name);
					if ( self:IsInIMECompositionMode() ) then
						self:HighlightText(textlen - strlen(arg1), -1);
					else
						self:HighlightText(textlen, -1);
					end
					return;
				end
			end
		end
	end
	

	-- next search history list

	numItems = #gHistoryItemList;

	if ( numItems > 0 ) then
		for i=1, numItems do
			name = gHistoryItemList[i];
			if ( name and text and (strfind(strupper(name), strupper(text), 1, 1) == 1) ) then
				self:SetText(name);
				if ( self:IsInIMECompositionMode() ) then
					self:HighlightText(textlen - strlen(arg1), -1);
				else
					self:HighlightText(textlen, -1);
				end
				return;
			end
		end
	end
end

-----------------------------------------

function Atr_GetCurrentPane ()			-- so other modules can use gCurrentPane
	return gCurrentPane;
end

-----------------------------------------

function Atr_SetUINeedsUpdate ()			-- so other modules can easily set
	gCurrentPane.UINeedsUpdate = true;
end


-----------------------------------------

function Atr_CalcUndercutPrice (price)

	if	(price > 5000000)	then return roundPriceDown (price, AUCTIONATOR_SAVEDVARS._5000000);	end;
	if	(price > 1000000)	then return roundPriceDown (price, AUCTIONATOR_SAVEDVARS._1000000);	end;
	if	(price >  200000)	then return roundPriceDown (price, AUCTIONATOR_SAVEDVARS._200000);	end;
	if	(price >   50000)	then return roundPriceDown (price, AUCTIONATOR_SAVEDVARS._50000);	end;
	if	(price >   10000)	then return roundPriceDown (price, AUCTIONATOR_SAVEDVARS._10000);	end;
	if	(price >    2000)	then return roundPriceDown (price, AUCTIONATOR_SAVEDVARS._2000);	end;
	if	(price >     500)	then return roundPriceDown (price, AUCTIONATOR_SAVEDVARS._500);		end;
	if	(price >       0)	then return math.floor (price - 1);	end;

	return 0;
end

-----------------------------------------

function Atr_CalcStartPrice (buyoutPrice)

	local discount = 1.00 - (AUCTIONATOR_SAVEDVARS.STARTING_DISCOUNT / 100);

	local newStartPrice = Atr_CalcUndercutPrice(math.floor(buyoutPrice * discount));
	
	if (AUCTIONATOR_SAVEDVARS.STARTING_DISCOUNT == 0) then		-- zero means zero
		newStartPrice = buyoutPrice;
	end
	
	return newStartPrice;

end

-----------------------------------------

function Atr_AbbrevItemName (itemName)

	return string.gsub (itemName, "Scroll of Enchant", "SoE");

end

-----------------------------------------

function Atr_IsMyToon (name)

	if (name and (AUCTIONATOR_TOONS[name] or AUCTIONATOR_TOONS[string.lower(name)])) then
		return true;
	end
	
	return false;
end

-----------------------------------------

function Atr_Error_Display (errmsg)
	if (errmsg) then
		Atr_Error_Text:SetText (errmsg);
		Atr_Error_Frame:Show ();
		return;
	end
end

-----------------------------------------

function Atr_PollWho(s)

	gSendZoneMsgs = true;
	gQuietWho = time();

	SetWhoToUI(1);
	
	zc.md (s);
	
	SendWho (s);
end

-----------------------------------------

function Atr_FriendsFrame_OnEvent(self, event, ...)

	if (event == "WHO_LIST_UPDATE" and gQuietWho > 0 and time() - gQuietWho < 10) then
		return;
	end

	if (gQuietWho > 0) then
		SetWhoToUI(0);
	end
	
	gQuietWho = 0;
	
	return auctionator_orig_FriendsFrame_OnEvent (self, event, ...);

end



-----------------------------------------
-- roundPriceDown - rounds a price down to the next lowest multiple of a.
--				  - if the result is not at least a/2 lower, rounds down by a/2.
--
--	examples:  	(128790, 500)  ->  128500
--				(128700, 500)  ->  128000
--				(128400, 500)  ->  128000
-----------------------------------------

function roundPriceDown (price, a)

	if (a == 0) then
		return price;
	end

	local newprice = math.floor((price-1) / a) * a;

	if ((price - newprice) < a/2) then
		newprice = newprice - (a/2);
	end

	if (newprice == price) then
		newprice = newprice - 1;
	end

	return newprice;

end

-----------------------------------------

function ToTightHour(t)

	return floor((t - gTimeTightZero)/3600);

end

-----------------------------------------

function FromTightHour(tt)

	return (tt*3600) + gTimeTightZero;

end


-----------------------------------------

function ToTightTime(t)

	return floor((t - gTimeTightZero)/60);

end

-----------------------------------------

function FromTightTime(tt)

	return (tt*60) + gTimeTightZero;

end


--[[

- right click item in bag
- reset to 12 hours when switching tabs
- off by one when cancelling multisell
- cosmetic issue with the background
- collapsed multiple cancel messages

]]--

-- =========================================================================
-- UNIVERSAL BUY ALL ATTACHER (WOTLK SAFE) - APPEND THIS TO Auctionator.lua
-- =========================================================================
-- Tries multiple possible Auctionator Buy-confirm button names and attaches
-- a "BUY ALL" button next to whichever one exists in your build.
-- Includes debug prints so you can see what it found.
-- Works by executing PlaceAuctionBid inside your click (hardware event).
-- =========================================================================

do
  if _G["Auctionator_BuyAll_Attached"] then return end
  Auctionator_BuyAll_Attached = true

  -- list of candidate global names (common variants across builds)
  local candidates = {
    "Atr_Buy_Confirm_OKBut",
    "Atr_Buy_Confirm_OK",
    "Atr_Buy1_Button",
    "Atr_Buy_Confirm_YesBut",
    "Atr_Buy_Confirm_OKBtn",
    "Atr_Buy_Confirm_OKButton",
    "AtrBuyConfirmBuyButton",
    "Atr_BuyConfirm_OK",
    "Atr_BuyConfirm_OKBut",
    "Atr_Buy_Confirm_Button",
    -- fallback to Auctionator buy button frames
    "Atr_Buy1_Button", "Atr_BuyButton", "AuctionatorBuy_BuyoutButton", "AuctionFrameBrowse_BuyoutButton", "AuctionBuyButton"
  }

  local function MakeBuyAllButton(anchorButton)
    if not anchorButton or not anchorButton.IsShown then return nil end
    if _G["Auctionator_BuyAll_Button"] then return _G["Auctionator_BuyAll_Button"] end

    local parent = anchorButton:GetParent() or UIParent
    local btn = CreateFrame("Button", "Auctionator_BuyAll_Button", parent, "UIPanelButtonTemplate")
    btn:SetSize(90, 22)
    -- try to anchor to the right; use pcall in case of weird points
    local ok = pcall(function() btn:SetPoint("LEFT", anchorButton, "RIGHT", -250, 0) end)
    if not ok then
      btn:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 10)
    end
    btn:SetText("BUY ALL")

    btn:SetScript("OnClick", function(self)
      -- defensive checks for Auctionator's selection
      if not gCurrentPane or not gCurrentPane.currIndex or not gCurrentPane.activeScan then
        print("|cff12c2e0Auctionator Buy All|r: No Auctionator selection detected.")
        return
      end

      local scan = gCurrentPane.activeScan
      local offset = FauxScrollFrame_GetOffset(AuctionatorScrollFrame) or 0
      local dataIndex = offset + (gCurrentPane.currIndex or 0)
      local entry = scan.sortedData and scan.sortedData[dataIndex]
      if not entry or not entry.itemName or not entry.buyoutPrice then
        print("|cff12c2e0Auctionator Buy All|r: Could not read selected entry info.")
        return
      end

      local targetName = entry.itemName
      local targetPrice = entry.buyoutPrice
      local bought = 0
      local num = GetNumAuctionItems and GetNumAuctionItems("list") or 0

      for i = 1, num do
        local ok, name, count, _, buyout = GetAuctionItemInfo("list", i)
        if ok and name == targetName and buyout == targetPrice and count and count > 0 then
          -- attempt to buy inside click handler; pcall to avoid script errors
          local suc = pcall(function() PlaceAuctionBid("list", i, buyout) end)
          if not suc then
            pcall(function() PlaceBid(i, buyout, 1) end)
          end
          bought = bought + 1
        end
      end

      if bought > 0 then
        print(string.format("|cff12c2e0Auctionator Buy All|r: Attempted to buy %d auctions of |cff32ff32%s|r at price %s.", bought, targetName, GetCoinTextureString(targetPrice)))
      else
        print("|cff12c2e0Auctionator Buy All|r: No matching auctions found on the visible page.")
      end
    end)

    -- Optional tooltip
    btn:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:AddLine("Buy All")
      GameTooltip:AddLine("Attempts to buy all visible listings of", 1,1,1)
      GameTooltip:AddLine("the selected item at this buyout price.", 1,1,1)
      GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return btn
  end

  local attached = false
  local lastFoundName = nil

  -- Try immediate creation (in case frame is already present)
  for _, name in ipairs(candidates) do
    local obj = _G[name]
    if obj then
      local created = MakeBuyAllButton(obj)
      if created then
        attached = true
        lastFoundName = name
        break
      end
    end
  end

  -- If not attached yet, poll for frame appearance for a short time
  if not attached then
    local pollFrame = CreateFrame("Frame")
    local elapsedAcc = 0
    pollFrame:SetScript("OnUpdate", function(self, elapsed)
      elapsedAcc = elapsedAcc + elapsed
      -- poll fast first second, then every 0.5s
      if elapsedAcc < 0.05 then return end
      elapsedAcc = 0
      for _, name in ipairs(candidates) do
        local obj = _G[name]
        if obj and obj.IsShown and obj:IsShown() then
          local created = MakeBuyAllButton(obj)
          if created then
            attached = true
            lastFoundName = name
            self:SetScript("OnUpdate", nil)
            print("|cff12c2e0Auctionator Buy All|r: Attached to frame '" .. tostring(name) .. "'.")
            return
          end
        end
      end
      -- keep polling; stop after 10 seconds to be safe
      if not self._total then self._total = 0 end
      self._total = self._total + elapsed
      if self._total > 10 then
        self:SetScript("OnUpdate", nil)
        print("|cff12c2e0Auctionator Buy All|r: Could not find confirmation button to attach to (polled 10s).")
      end
    end)
  else
    print("|cff12c2e0Auctionator Buy All|r: Attached immediately to '" .. tostring(lastFoundName) .. "'.")
  end

  -- Also hook into AUCTIONATOR_INITED event as a fallback
  local hookFrame = CreateFrame("Frame")
  hookFrame:RegisterEvent("AUCTIONATOR_INITED")
  hookFrame:RegisterEvent("ADDON_LOADED")
  hookFrame:SetScript("OnEvent", function(self, event, arg1)
    -- try once more on init
    for _, name in ipairs(candidates) do
      local obj = _G[name]
      if obj and obj.IsShown and obj:IsShown() then
        if not _G["Auctionator_BuyAll_Button"] then
          local created = MakeBuyAllButton(obj)
          if created then
            print("|cff12c2e0Auctionator Buy All|r: Attached on event '"..tostring(event).."': "..tostring(name))
            return
          end
        end
      end
    end
  end)

end
-- =========================================================================
-- END UNIVERSAL BUY ALL ATTACHER
-- =========================================================================

## Interface: 30300
## Title: Auctionator
## Version: 2.6.3
## Author: Zirco
## X-Website: http://auctionator-addon.com
## X-Localizations: enUS, deDE, ruRU, svSE, frFR, esES
## Notes: A lightweight addon that makes it easy and fast to buy, sell and manage auctions
## SavedVariablesPerCharacter: AUCTIONATOR_SHOW_ST_PRICE, AUCTIONATOR_ENABLE_ALT, AUCTIONATOR_OPEN_FIRST, AUCTIONATOR_OPEN_BUY, AUCTIONATOR_OPEN_ALL_BAGS, AUCTIONATOR_DEF_DURATION, AUCTIONATOR_SHOW_TIPS, AUCTIONATOR_V_TIPS, AUCTIONATOR_A_TIPS, AUCTIONATOR_D_TIPS, AUCTIONATOR_SHIFT_TIPS, AUCTIONATOR_DE_DETAILS_TIPS, AUCTIONATOR_DEFTAB
## SavedVariables: AUCTIONATOR_SAVEDVARS, AUCTIONATOR_PRICING_HISTORY, AUCTIONATOR_SHOPPING_LISTS, AUCTIONATOR_PRICE_DATABASE, AUCTIONATOR_LAST_SCAN_TIME, AUCTIONATOR_TOONS, AUCTIONATOR_STACKING_PREFS, AUCTIONATOR_SCAN_MINLEVEL

Locales\enUS.lua
Locales\deDE.lua
Locales\ruRU.lua
Locales\frFR.lua
Locales\svSE.lua
Locales\esES.lua

zcUtils.lua

Auctionator.lua
AuctionatorShop.lua

Auctionator.xml

AuctionatorLocalize.lua
AuctionatorPane.lua
AuctionatorScan.lua
AuctionatorQuery.lua
AuctionatorHints.lua
AuctionatorVendor.lua
AuctionatorConflicts.lua
AuctionatorAPI.lua
AuctionatorConfig.lua
AuctionatorBuy.lua

AuctionatorConfig.xml
Auctionator_BuyAll_Version6



-----------------------------------------

local origGetSellValue		= GetSellValue;
local origGetAuctionBuyout	= GetAuctionBuyout;

-----------------------------------------

function GetSellValue (item)		-- Tekkub's API
	
	return Atr_GetSellValue(item);
end

-----------------------------------------

function GetAuctionBuyout (item)		-- Tekkub's API
	
	return Atr_GetAuctionBuyout(item);
end

-----------------------------------------

function Atr_GetSellValue (item)		-- Just like Tekkub's API but for when you want to be sure you're calling Auctionator's version of it

	local sellval = select (11, GetItemInfo(item));

	if (sellval ~= nil) then
		return sellval;
	end
	
	if (origGetSellValue) then
		return origGetSellValue(item);
	end
	
	return 0;
end


-----------------------------------------

function Atr_GetAuctionBuyout (item)  -- Just like Tekkub's API but for when you want to be sure you're calling Auctionator's version of it

	local sellval;
	
	if (type(item) == "string") then
		sellval = Atr_GetAuctionPrice(item);
	end
	
	if (sellval == nil) then
		local name = GetItemInfo(item);
		if (name) then
			sellval = Atr_GetAuctionPrice(name);
		end
	end
	
	if (sellval) then
		return sellval;
	end

	if (origGetAuctionBuyout) then
		return origGetAuctionBuyout(item);
	end
	
	return nil;
end

-----------------------------------------

function Atr_GetDisenchantValue (item)

	local itemName, itemLink, itemRarity, itemLevel, _, itemType = GetItemInfo (item);

	if (itemLink) then
		return Atr_CalcDisenchantPrice (itemType, itemRarity, itemLevel);
	end
	
	return nil;
end



local addonName, addonTable = ...; 
local zc = addonTable.zc;


local ATR_BUY_NULL						= 0;
local ATR_BUY_QUERY_SENT				= 1;
local ATR_BUY_JUST_BOUGHT				= 2;
local ATR_BUY_PROCESSING_QUERY_RESULTS	= 3;
local ATR_BUY_WAITING_FOR_AH_CAN_SEND	= 4;

local gBuyState = ATR_BUY_NULL;

-----------------------------------------

local gAtr_Buy_BuyoutPrice;
local gAtr_Buy_ItemName;
local gAtr_Buy_StackSize;
local gAtr_Buy_NumBought;
local gAtr_Buy_NumUserWants;
local gAtr_Buy_MaxCanBuy;
local gAtr_Buy_CurPage;
local gAtr_Buy_Waiting_Start;
local gAtr_Buy_Query;
local gAtr_Buy_Pass;

-----------------------------------------

function Atr_Buy_Debug1 (yellow)

	if (gBuyState == ATR_BUY_NULL)										then asstr = "ATR_BUY_NULL"; end;
	if (gBuyState == ATR_BUY_QUERY_SENT)								then asstr = "ATR_BUY_QUERY_SENT"; end;
	if (gBuyState == ATR_BUY_PROCESSING_QUERY_RESULTS)					then asstr = "ATR_BUY_PROCESSING_QUERY_RESULTS"; end;
	if (gBuyState == ATR_BUY_JUST_BOUGHT)								then asstr = "ATR_BUY_JUST_BOUGHT"; end;
	if (gBuyState == ATR_BUY_WAITING_FOR_AH_CAN_SEND)					then asstr = "ATR_BUY_WAITING_FOR_AH_CAN_SEND"; end;

	if (gBuyState ~= ATR_BUY_NULL) then
		if (yellow) then
			zc.msg (asstr, "curpage: ", gAtr_Buy_CurPage, "   gAtr_Buy_NumBought: ", gAtr_Buy_NumBought);
		else
			zc.msg_pink (asstr, "curpage: ", gAtr_Buy_CurPage, "   gAtr_Buy_NumBought: ", gAtr_Buy_NumBought);
		end
	end
	
end

-----------------------------------------

function Atr_ClearBuyState()

	gBuyState = ATR_BUY_NULL;

end


-----------------------------------------

function Atr_Buy1_Onclick ()

	if (not Atr_ShowingCurrentAuctions()) then
		return;
	end
	
	gAtr_Buy_Query			= Atr_NewQuery();
	gAtr_Buy_NumUserWants	= -1;
	gAtr_Buy_NumBought		= 0;
	
	local currentPane = Atr_GetCurrentPane();
	
	local scan = currentPane.activeScan;
	
	local data = scan.sortedData[currentPane.currIndex];

	gAtr_Buy_BuyoutPrice	= data.buyoutPrice;
	gAtr_Buy_ItemName		= scan.itemName;
	gAtr_Buy_StackSize		= data.stackSize;
	gAtr_Buy_MaxCanBuy		= data.count;
	gAtr_Buy_Pass			= 1;		-- - first pass
	
	Atr_Buy_Confirm_ItemName:SetText (gAtr_Buy_ItemName.." x"..gAtr_Buy_StackSize);
	Atr_Buy_Confirm_Numstacks:SetNumber (1);
	Atr_Buy_Confirm_Max_Text:SetText (ZT("max")..": "..gAtr_Buy_MaxCanBuy);
	
	Atr_Buy_Part1:Show();
	Atr_Buy_Part2:Hide();
	
	Atr_Buy_Confirm_OKBut:SetText (ZT("Buy"))
	Atr_Buy_Confirm_OKBut:Disable();
	Atr_Buy_Confirm_Frame:Show();

	if (scan.searchWasExact and data.minpage ~= nil) then
		Atr_Buy_QueueQuery(data.minpage);
	else
		Atr_Buy_QueueQuery(0);
	end


end

-----------------------------------------

function Atr_Buy_QueueQuery (page)

	gAtr_Buy_CurPage = page;

--zc.msg_pink ("Queuing query for page ", page);

	gBuyState = ATR_BUY_WAITING_FOR_AH_CAN_SEND;
	gAtr_Buy_Waiting_Start = time();
	
	Atr_Buy_SendQuery();		-- give it a shot
end

-----------------------------------------

function Atr_Buy_SendQuery ()

	if (CanSendAuctionQuery()) then

		gBuyState = ATR_BUY_QUERY_SENT;

		local queryString = zc.UTF8_Truncate (gAtr_Buy_ItemName,63);	-- attempting to reduce number of disconnects

		QueryAuctionItems (queryString, "", "", nil, 0, 0, gAtr_Buy_CurPage, nil, nil);
	end
		
end

-----------------------------------------
local prevBuyState;

-----------------------------------------

function Atr_Buy_Idle ()

	if (gBuyState ~= prevBuyState) then
		prevBuyState = gBuyState;
--		Atr_Buy_Debug1 (true);
	end
	
	if (gBuyState == ATR_BUY_WAITING_FOR_AH_CAN_SEND) then
	
--		zc.md ("WAITING_FOR_AH_CAN_SEND: ", time() - gAtr_Buy_Waiting_Start);
		
		if (GetMoney() < gAtr_Buy_BuyoutPrice) then
			Atr_Buy_Cancel (ZT("You do not have enough gold\n\nto make any more purchases."));
		elseif (time() - gAtr_Buy_Waiting_Start > 10) then
			Atr_Buy_Cancel (ZT("Auction House timed out"));
		else	
			Atr_Buy_SendQuery ();
		end
		
	elseif (gBuyState == ATR_BUY_JUST_BOUGHT) then

--		zc.msg_pink ("ATR_BUY_JUST_BOUGHT: ",  time() - gAtr_Buy_Waiting_Start);

		local queueIf = (time() - gAtr_Buy_Waiting_Start > 2);		-- wait a few seconds for Auction List to Update after buys
		
		Atr_Buy_NextPage_Or_Cancel (queueIf);
		
	end

end

-----------------------------------------

function Atr_Buy_OnAuctionUpdate()

--	Atr_Buy_Debug1();

	if (gBuyState == ATR_BUY_QUERY_SENT) then
		Atr_Buy_CheckForMatches ();
	end

	return (gBuyState ~= ATR_BUY_NULL);
end

-----------------------------------------

function Atr_Buy_CheckForMatches ()

	gBuyState = ATR_BUY_PROCESSING_QUERY_RESULTS;
	
	if (gAtr_Buy_Query:CheckForDuplicatePage(gAtr_Buy_CurPage)) then
		Atr_Buy_QueueQuery (gAtr_Buy_CurPage);
		return;
	end

	local isLastPage = gAtr_Buy_Query:IsLastPage(gAtr_Buy_CurPage);
	
	local numMatches = Atr_Buy_CountMatches();
	
	if (numMatches > 0) then		-- update the confirmation screen
	
		Atr_Buy_Confirm_OKBut:Enable();

		if (gAtr_Buy_NumUserWants ~= -1) then		
			Atr_Buy_Continue_Text:SetText (string.format (ZT("%d of %d bought so far"), gAtr_Buy_NumBought, gAtr_Buy_NumUserWants));
			Atr_Buy_Part1:Hide();
			Atr_Buy_Part2:Show();
			Atr_Buy_Confirm_OKBut:SetText (ZT("Continue"))
		end

	else
		Atr_Buy_NextPage_Or_Cancel();
	end

end


-----------------------------------------

function Atr_Buy_BuyMatches ()
	return Atr_Buy_CountMatches (true);
end

-----------------------------------------

function Atr_Buy_CountMatches (andBuy)

	local numMatches		= 0;
	local numBoughtThisPage	= 0;
	local i = 1;

	while (true) do
	
		local name, _, count, _, _, _, _, _, buyoutPrice, _ = GetAuctionItemInfo ("list", i);

		if (name == nil) then
			break;
		end

		if (zc.StringSame (name, gAtr_Buy_ItemName) and buyoutPrice == gAtr_Buy_BuyoutPrice and count == gAtr_Buy_StackSize) then
			
			numMatches = numMatches + 1;
			
			if (andBuy and gAtr_Buy_NumUserWants > gAtr_Buy_NumBought) then
				PlaceAuctionBid("list", i, gAtr_Buy_BuyoutPrice);
				
				numBoughtThisPage  = numBoughtThisPage + 1;
				gAtr_Buy_NumBought = gAtr_Buy_NumBought + 1;
			end
		end

		i = i + 1;
	end

	return numMatches, numBoughtThisPage;
end




-----------------------------------------

function Atr_Buy_Confirm_Update ()

	local num = Atr_Buy_Confirm_Numstacks:GetNumber();

	if (num == 1) then
		Atr_Buy_Confirm_Text2:SetText (ZT("stack for"));
	else
		Atr_Buy_Confirm_Text2:SetText (ZT("stacks for"));
	end

	MoneyFrame_Update ("Atr_Buy_Confirm_TotalPrice",  gAtr_Buy_BuyoutPrice * num);

end

-----------------------------------------

function Atr_Buy_NextPage_Or_Cancel ( queueIf )

	if (Atr_Buy_IsComplete()) then
	
		Atr_Buy_Cancel();
		
	elseif (queueIf == nil or queueIf == true) then
	
		if (Atr_Buy_IsFirstPassComplete()) then
			gAtr_Buy_Pass = 2;
			Atr_Buy_QueueQuery(0);
		else
			Atr_Buy_QueueQuery(gAtr_Buy_CurPage + 1);
		end
	end
end

-----------------------------------------

function Atr_Buy_IsComplete ()

	if (gAtr_Buy_NumUserWants ~= -1 and gAtr_Buy_NumUserWants <= gAtr_Buy_NumBought) then
		return true;
	end

	if (gAtr_Buy_Query:IsLastPage(gAtr_Buy_CurPage) and gAtr_Buy_Pass == 2) then
		return true;
	end

	return false;

end

-----------------------------------------

function Atr_Buy_IsFirstPassComplete ()

	if (gAtr_Buy_Query:IsLastPage(gAtr_Buy_CurPage) and gAtr_Buy_Pass == 1) then
		return true;
	end

	return false;

end

-----------------------------------------

function Atr_Buy_Confirm_OK ()

	if (gAtr_Buy_NumUserWants == -1) then
		local numToBuy = Atr_Buy_Confirm_Numstacks:GetNumber();

		if (numToBuy > gAtr_Buy_MaxCanBuy) then
			Atr_Error_Text:SetText (string.format (ZT("You can buy at most %d auctions"), gAtr_Buy_MaxCanBuy));
			Atr_Error_Frame:Show ();
			return;
		end
		
		gAtr_Buy_NumUserWants = numToBuy;
	end
	
	local _, numJustBought = Atr_Buy_BuyMatches ();

	if (numJustBought > 0) then

--zc.msg (numJustBought, " from page ", gAtr_Buy_CurPage);
	
		AuctionatorSubtractFromScan (gAtr_Buy_ItemName, gAtr_Buy_StackSize, gAtr_Buy_BuyoutPrice, gAtr_Buy_NumBought);
		gBuyState = ATR_BUY_JUST_BOUGHT;
		gAtr_Buy_Waiting_Start = time();
		Atr_Buy_Confirm_OKBut:Disable();
	else
		Atr_Buy_NextPage_Or_Cancel();
	end
	
end

-----------------------------------------

function Atr_Buy_Wait_For_Bought_To_Clear ()

	zc.md ("Atr_Buy_Wait_For_Bought_To_Clear: ", time() - gAtr_Buy_Waiting_Start);
	
end

-----------------------------------------

function Atr_Buy_Cancel (msg)
	
	gBuyState = ATR_BUY_NULL;

	Atr_Buy_Confirm_Frame:Hide();
	
	Atr_Error_Display(msg);
end



local addonName, addonTable = ...; 
local zc = addonTable.zc;

-----------------------------------------

function Atr_LoadOptionsSubPanel (f, name, title, subtitle)

	f.name		= name
	f.parent	= "Auctionator";
	f.cancel	= Atr_Options_Cancel;

	local frameName = f:GetName();
	
	f.okay   = getglobal (frameName.."_Save")

	if (title    == nil) then title = name; end
	if (subtitle == nil) then subtitle = ""; end
	
	getglobal (frameName.."_ATitle"):SetText (title);
	getglobal (frameName.."_BTitle"):SetText (subtitle);
	
	InterfaceOptions_AddCategory (f);

end


-----------------------------------------

function Atr_Options_Cancel ()

	Atr_InitOptionsPanels();

end


-----------------------------------------

function Atr_InitOptionsPanels()

	if (AUCTIONATOR_SAVEDVARS == nil) then
		Atr_ResetSavedVars();
	end

	Atr_SetupBasicOptionsFrame();
	Atr_SetupTooltipsOptionsFrame();
	Atr_SetupUCConfigFrame();
	Atr_SetupStackingFrame();
	Atr_SetupOptionsFrame();
	Atr_SetupScanningConfigFrame();

end

-----------------------------------------

function Atr_SetupOptionsFrame()

	local expText = "<html><body>"
					.."<p>"..ZT("The latest information on Auctionator can be found at").." auctionator-addon.com.".."</p>"
					.."<p><br/>"
					.."|cffaaaaaa"..string.format (ZT("German translation courtesy of %s"),  "|rCkaotik").."<br/>"
					.."|cffaaaaaa"..string.format (ZT("Russian translation courtesy of %s"), "|rStingerSoft").."<br/>"
					.."|cffaaaaaa"..string.format (ZT("Swedish translation courtesy of %s"), "|rHellManiac").."<br/>"
					.."|cffaaaaaa"..string.format (ZT("French translation courtesy of %s"),  "|rKiskewl").."<br/>"
					.."|cffaaaaaa"..string.format (ZT("Spanish translation courtesy of %s"),  "|rElfindor").."<br/>"
					.."</p>"
					.."</body></html>"
					;

	AuctionatorDescriptionHTML:SetText (expText);
	AuctionatorDescriptionHTML:SetSpacing (3);

	AuctionatorVersionText:SetText (ZT("Version")..": "..AuctionatorVersion);

end


-----------------------------------------

function Atr_SetDurationOptionRB(name)

	Atr_RB_S:SetChecked (zc.StringEndsWith (name, "S"));
	Atr_RB_M:SetChecked (zc.StringEndsWith (name, "M"));
	Atr_RB_L:SetChecked (zc.StringEndsWith (name, "L"));

end

-----------------------------------------

function Atr_BasicOptionsFrame_Save()

	local origValues = zc.msg_str (AUCTIONATOR_ENABLE_ALT, AUCTIONATOR_OPEN_ALL_BAGS, AUCTIONATOR_SHOW_ST_PRICE, AUCTIONATOR_DEFTAB, AUCTIONATOR_DEF_DURATION);

	AUCTIONATOR_ENABLE_ALT		= zc.BoolToNum(AuctionatorOption_Enable_Alt_CB:GetChecked ());
	AUCTIONATOR_OPEN_ALL_BAGS	= zc.BoolToNum(AuctionatorOption_Open_All_Bags_CB:GetChecked ());
	AUCTIONATOR_SHOW_ST_PRICE	= zc.BoolToNum(AuctionatorOption_Show_StartingPrice_CB:GetChecked ());

	AUCTIONATOR_DEFTAB			= UIDropDownMenu_GetSelectedValue(AuctionatorOption_Deftab);

	AUCTIONATOR_DEF_DURATION = "N";

	if (AuctionatorOption_Def_Duration_CB:GetChecked()) then
		if (Atr_RB_S:GetChecked())	then	AUCTIONATOR_DEF_DURATION = "S"; end;
		if (Atr_RB_M:GetChecked())	then	AUCTIONATOR_DEF_DURATION = "M"; end;
		if (Atr_RB_L:GetChecked())	then	AUCTIONATOR_DEF_DURATION = "L"; end;
	end

	local newValues = zc.msg_str (AUCTIONATOR_ENABLE_ALT, AUCTIONATOR_OPEN_ALL_BAGS, AUCTIONATOR_SHOW_ST_PRICE, AUCTIONATOR_DEFTAB, AUCTIONATOR_DEF_DURATION);

	if (origValues ~= newValues) then
		zc.msg_atr (ZT ("basic options saved"));
	end
	
	Atr_ShowHide_StartingPrice();
end


-----------------------------------------

function Atr_SetupBasicOptionsFrame()

	Atr_BasicOptionsFrame_BTitle:SetText (string.format (ZT("Basic Options for %s"), "|cffffff55"..UnitName("player")));

	AuctionatorOption_Enable_Alt_CB:SetChecked			(zc.NumToBool(AUCTIONATOR_ENABLE_ALT));
	AuctionatorOption_Open_All_Bags_CB:SetChecked		(zc.NumToBool(AUCTIONATOR_OPEN_ALL_BAGS));
	AuctionatorOption_Show_StartingPrice_CB:SetChecked	(zc.NumToBool(AUCTIONATOR_SHOW_ST_PRICE));

	UIDropDownMenu_Initialize		(AuctionatorOption_Deftab, AuctionatorOption_Deftab_Initialize);
	UIDropDownMenu_SetSelectedValue	(AuctionatorOption_Deftab, AUCTIONATOR_DEFTAB);

	AuctionatorOption_Def_Duration_CB:SetChecked (AUCTIONATOR_DEF_DURATION == "S" or AUCTIONATOR_DEF_DURATION == "M" or AUCTIONATOR_DEF_DURATION == "L");

	Atr_SetDurationOptionRB (AUCTIONATOR_DEF_DURATION);

end

-----------------------------------------

function Atr_SetupTooltipsOptionsFrame ()

	ATR_tipsVendorOpt_CB:SetChecked		(zc.NumToBool(AUCTIONATOR_V_TIPS));
	ATR_tipsAuctionOpt_CB:SetChecked	(zc.NumToBool(AUCTIONATOR_A_TIPS));
	ATR_tipsDisenchantOpt_CB:SetChecked	(zc.NumToBool(AUCTIONATOR_D_TIPS));

	UIDropDownMenu_Initialize(Atr_tipsShiftDD, Atr_tipsShiftDD_Initialize);
	UIDropDownMenu_SetSelectedValue(Atr_tipsShiftDD, AUCTIONATOR_SHIFT_TIPS);
	
	UIDropDownMenu_Initialize(Atr_deDetailsDD, Atr_deDetailsDD_Initialize);
	UIDropDownMenu_SetSelectedValue(Atr_deDetailsDD, AUCTIONATOR_DE_DETAILS_TIPS);
end


-----------------------------------------

function Atr_TooltipsOptionsFrame_Save()

	local origValues = zc.msg_str (AUCTIONATOR_V_TIPS, AUCTIONATOR_A_TIPS, AUCTIONATOR_D_TIPS, AUCTIONATOR_SHIFT_TIPS, AUCTIONATOR_DE_DETAILS_TIPS);

	AUCTIONATOR_V_TIPS		= zc.BoolToNum(ATR_tipsVendorOpt_CB:GetChecked ());
	AUCTIONATOR_A_TIPS		= zc.BoolToNum(ATR_tipsAuctionOpt_CB:GetChecked ());
	AUCTIONATOR_D_TIPS		= zc.BoolToNum(ATR_tipsDisenchantOpt_CB:GetChecked ());

	AUCTIONATOR_SHIFT_TIPS		= UIDropDownMenu_GetSelectedValue(Atr_tipsShiftDD);
	AUCTIONATOR_DE_DETAILS_TIPS	= UIDropDownMenu_GetSelectedValue(Atr_deDetailsDD);

	local newValues = zc.msg_str (AUCTIONATOR_V_TIPS, AUCTIONATOR_A_TIPS, AUCTIONATOR_D_TIPS, AUCTIONATOR_SHIFT_TIPS, AUCTIONATOR_DE_DETAILS_TIPS);

	if (origValues ~= newValues) then
		zc.msg_atr (ZT("tooltip configuration saved"));
	end


end


-----------------------------------------

function AuctionatorOption_Deftab_Initialize()

	local info = UIDropDownMenu_CreateInfo();
	
	Atr_AddMenuPick (info, ZT("None"),	0, AuctionatorOption_Deftab_OnClick);
	Atr_AddMenuPick (info, ZT("Sell"),	1, AuctionatorOption_Deftab_OnClick);
	Atr_AddMenuPick (info, ZT("Buy"),	2, AuctionatorOption_Deftab_OnClick);
	Atr_AddMenuPick (info, ZT("More"),	3, AuctionatorOption_Deftab_OnClick);

end

-----------------------------------------

function AuctionatorOption_Deftab_OnClick(self)
	UIDropDownMenu_SetSelectedValue(self.owner, self.value);
end

-----------------------------------------

function Atr_tipsShiftDD_Initialize()

	local info = UIDropDownMenu_CreateInfo();
	
	Atr_AddMenuPick (info, ZT("stack price"),		1, Atr_tipsShiftDD_OnClick);
	Atr_AddMenuPick (info, ZT("per item price"),	2, Atr_tipsShiftDD_OnClick);

end

-----------------------------------------

function Atr_tipsShiftDD_OnClick(self)
	UIDropDownMenu_SetSelectedValue(self.owner, self.value);
end

-----------------------------------------

function Atr_deDetailsDD_Initialize()

	local info = UIDropDownMenu_CreateInfo();
	
	Atr_AddMenuPick (info, ZT("when SHIFT is held down"),	1, Atr_deDetailsDD_OnClick);
	Atr_AddMenuPick (info, ZT("when CONTROL is held down"),	2, Atr_deDetailsDD_OnClick);
	Atr_AddMenuPick (info, ZT("when ALT is held down"),		3, Atr_deDetailsDD_OnClick);
	Atr_AddMenuPick (info, ZT("never"),						4, Atr_deDetailsDD_OnClick);
	Atr_AddMenuPick (info, ZT("always"),					5, Atr_deDetailsDD_OnClick);

end

-----------------------------------------

function Atr_deDetailsDD_OnClick(self)
	UIDropDownMenu_SetSelectedValue(self.owner, self.value);
end

-----------------------------------------

function Atr_Option_OnClick (self)

	if (zc.StringContains (self:GetName(), "Open_BUY") and self:GetChecked()) then
		AuctionatorOption_Open_SELL_CB:SetChecked (false);
	end

	if (zc.StringContains (self:GetName(), "Open_SELL") and self:GetChecked()) then
		AuctionatorOption_Open_BUY_CB:SetChecked (false);
	end

end


-----------------------------------------

local kThresh = {}

kThresh[1] = { amt=5000000,		text=ZT("over %d gold"),		v=500	};
kThresh[2] = { amt=1000000,		text=ZT("over %d gold"),		v=100	};
kThresh[3] = { amt=200000,		text=ZT("over %d gold"),		v=20	};
kThresh[4] = { amt=50000,		text=ZT("over %d gold"),		v=5		};
kThresh[5] = { amt=10000,		text=ZT("over 1 gold"),			v=1		};
kThresh[6] = { amt=2000,		text=ZT("over %d silver"),		v=20	};
kThresh[7] = { amt=500,			text=ZT("over %d silver"),		v=5		};
                 
-----------------------------------------

function Atr_SetupUCConfigFrame()

	for i = 1, #kThresh do

		local amt		= kThresh[i].amt;
		local linetext	= string.format (kThresh[i].text, kThresh[i].v);

		getglobal("UC_"..amt.."_RangeText"):SetText (linetext);

		MoneyInputFrame_SetCopper (getglobal("UC_"..amt.."_MoneyInput"), AUCTIONATOR_SAVEDVARS["_"..amt]);
	end

	Atr_Starting_Discount:SetText (AUCTIONATOR_SAVEDVARS.STARTING_DISCOUNT);

end


-----------------------------------------

function Atr_UCConfigFrame_Save()

	local origValues	= AUCTIONATOR_SAVEDVARS.STARTING_DISCOUNT;

	AUCTIONATOR_SAVEDVARS.STARTING_DISCOUNT = Atr_Starting_Discount:GetNumber ();

	local newValues		= AUCTIONATOR_SAVEDVARS.STARTING_DISCOUNT;

	for i = 1, #kThresh do
		local amt = kThresh[i].amt;
	
		origValues = origValues + AUCTIONATOR_SAVEDVARS["_"..amt];
		
		AUCTIONATOR_SAVEDVARS["_"..amt]	= MoneyInputFrame_GetCopper(getglobal("UC_"..amt.."_MoneyInput"));
		
		newValues = newValues + AUCTIONATOR_SAVEDVARS["_"..amt];
	end

	if (origValues ~= newValues) then
		zc.msg_atr (ZT("undercutting configuration saved"));
	end


end

-----------------------------------------

local function plistEntry (key, txt, num, size)

	return { sortkey=key, text=txt, numstacks=num, stacksize=size }

end

-----------------------------------------

local function plistSort (x, y)

	return x.sortkey < y.sortkey;

end

-----------------------------------------

local kStackList_LinesToDisplay = 12;
local gStackList_SelectedIndex = 0;
local gStackList_plist;


kStackList_categories = {};

kStackList_categories[ATR_SK_GLYPHS]		= { txt=ZT("Glyphs")			}
kStackList_categories[ATR_SK_GEMS_CUT]		= { txt=ZT("Gems - Cut")		}
kStackList_categories[ATR_SK_GEMS_UNCUT]	= { txt=ZT("Gems - Uncut")		}
kStackList_categories[ATR_SK_ITEM_ENH]		= { txt=ZT("Item Enhancements")	}
kStackList_categories[ATR_SK_POT_ELIX]		= { txt=ZT("Potions and Elixirs")	}
kStackList_categories[ATR_SK_FLASKS]		= { txt=ZT("Flasks")	}
kStackList_categories[ATR_SK_HERBS]			= { txt=ZT("Herbs")	}

-----------------------------------------

function Atr_SetupStackingFrame ()

	if (getglobal ("Atr_StackList1") == nil) then
		local line, n;

		for n = 1, kStackList_LinesToDisplay do
			local y = -5 - ((n-1)*16);
			line = CreateFrame("BUTTON", "Atr_StackList"..n, Atr_Stacking_List, "Atr_StackingEntryTemplate");
			line:SetPoint("TOP", 0, y);
		end
	end
	
	Atr_StackingList_Display();

end

-----------------------------------------

function Atr_StackingList_Display()

	gStackList_plist = {};

	local plist = gStackList_plist;
	local text, spinfo;
	local sortkey, info;
	local n = 1;
	
	for sortkey, info in pairs (kStackList_categories) do
		info.overrideFound = false;
	end

	for text, spinfo in pairs (AUCTIONATOR_STACKING_PREFS) do

		-- skip over any that were set automatically rather than explicitly by the user
		-- and mark the built-in categories

		if (spinfo.numstacks ~= 0) then
			local sortkey = text;
			
			if (kStackList_categories[text]) then
				kStackList_categories[text].overrideFound = true;
				text = kStackList_categories[text].txt;
			end

			plist[n] = plistEntry (sortkey, text, spinfo.numstacks, spinfo.stacksize);
			n = n + 1;
		end
	end
	
	for sortkey, info in pairs (kStackList_categories) do
		if (not info.overrideFound) then
			plist[n] = plistEntry (sortkey, info.txt, -2, 0);			
			n = n + 1;
		end
	end
	
	table.sort (plist, plistSort)
	
	local totalRows = #plist;

	local line;							-- 1 through NN of our window to scroll
	local dataOffset;					-- an index into our data calculated from the scroll offset

	FauxScrollFrame_Update (Atr_Stacking_ScrollFrame, totalRows, kStackList_LinesToDisplay, 16);

	for line = 1,kStackList_LinesToDisplay do

		dataOffset = line + FauxScrollFrame_GetOffset (Atr_Stacking_ScrollFrame);

		local lineEntry = getglobal ("Atr_StackList"..line);

		lineEntry:SetID (dataOffset);

		if (dataOffset <= totalRows and plist[dataOffset]) then

			local lineEntry_text = getglobal("Atr_StackList"..line.."_text");
			local lineEntry_info = getglobal("Atr_StackList"..line.."_info");

			local pdata = plist[dataOffset];
			
			local colorText = ((pdata.text == pdata.sortkey) and "" or "|cffffff88");
			
			lineEntry_text:SetText (colorText..pdata.text);

			local numstacks = plist[dataOffset].numstacks;
			local stacksize = plist[dataOffset].stacksize;
			local info = "???";
			
			if     (numstacks == -2) then	info = "|cff777777"..ZT("default behavior");														
			elseif (numstacks == -1) then	info = string.format (ZT("max. stacks of %d"), stacksize);		
			elseif (stacksize == 0)  then	info = "1 "..ZT("stack");	
			elseif (numstacks == 0)  then	info = ZT("stacks of").." "..stacksize;	
			elseif (numstacks > 0)   then	info = numstacks.." "..ZT("stacks of").." "..stacksize;	
			end
				
			lineEntry_info:SetText (info);
			
			if (gStackList_SelectedIndex == dataOffset) then
				lineEntry:SetButtonState ("PUSHED", true);
			else
				lineEntry:SetButtonState ("NORMAL", false);
			end
			
			lineEntry:Show();
		else
			lineEntry:Hide();
		end
	end

	zc.EnableDisable (Atr_StackingOptionsFrame_Edit, gStackList_SelectedIndex > 0);

end

-----------------------------------------

function Atr_StackingEntry_OnClick(self)

	gStackList_SelectedIndex = self:GetID();

	Atr_StackingList_Display();
end

-----------------------------------------

function Atr_StackingEntry_OnDoubleClick(self)

	Atr_StackingEntry_OnClick(self);
	Atr_StackingList_Edit_OnClick();
end

-----------------------------------------

function Atr_Memorize_Show (isNew)

	local numStacks = -1;
	local stackSize = 1;

	zc.ShowHide (Atr_Mem_itemName_static,	not isNew);
	zc.ShowHide (Atr_Mem_EB_itemName,		    isNew);
	zc.ShowHide (Atr_Mem_Forget,		   	not isNew);

	Atr_MemorizeFrame["isCategory"] = false;
	
	if (not isNew) then
		local x		= gStackList_SelectedIndex;
		local plist	= gStackList_plist;
		
		Atr_Mem_itemName_static:SetText (plist[x].text);
		
		stackSize = plist[x].stacksize
		numStacks = plist[x].numstacks

		local isCategory = (plist[x].sortkey ~= plist[x].text);

		Atr_MemorizeFrame["isCategory"] = isCategory;
		
		if (isCategory and numStacks == -2) then
			numStacks = -1;
			stackSize = 1;
		end
		
		zc.SetTextIf (Atr_Mem_itemName_text, isCategory, ZT("Category"), ZT("Item Name"));
		zc.SetTextIf (Atr_Mem_Forget,		 isCategory, ZT("Reset to Default"), ZT("Forget this Item"));
	end
		
	Atr_Mem_EB_stackSize:SetText (stackSize);

	UIDropDownMenu_Initialize		(Atr_Mem_DD_numStacks, Atr_SONumStacks_Initialize);
	UIDropDownMenu_SetSelectedValue	(Atr_Mem_DD_numStacks, numStacks);

	Atr_Mem_EB_itemName:SetText ("");
	
	ShowInterfaceOptionsMask();

	Atr_MemorizeFrame:Show();

end

-----------------------------------------

function Atr_StackingList_Edit_OnClick()

	Atr_Memorize_Show(false);

end

-----------------------------------------

function Atr_StackingList_New_OnClick()

	Atr_Memorize_Show(true);

end

-----------------------------------------

function Atr_Memorize_Save()

	local x		= gStackList_SelectedIndex;
	local plist	= gStackList_plist;

	local key = Atr_Mem_EB_itemName:GetText();
	if (key == nil or key == "") then
		key = plist[x].sortkey;
	end
	
	if (key and key ~= "") then
		Atr_Set_StackingPrefs_numstacks (key, UIDropDownMenu_GetSelectedValue (Atr_Mem_DD_numStacks));
		Atr_Set_StackingPrefs_stacksize (key, Atr_Mem_EB_stackSize:GetNumber ());
	end

	Atr_StackingList_Display();
	
end

-----------------------------------------

function Atr_Memorize_Forget()

	local x		= gStackList_SelectedIndex;
	local plist	= gStackList_plist;
	local key	= plist[x].sortkey;

	if (key) then
		Atr_Clear_StackingPrefs (key);
	end

	if (not Atr_MemorizeFrame["isCategory"]) then
		gStackList_SelectedIndex = 0;
	end

	Atr_StackingList_Display();

end


-----------------------------------------

function Atr_SONumStacks_OnLoad(self)

	UIDropDownMenu_Initialize		(self, Atr_SONumStacks_Initialize);
	UIDropDownMenu_SetSelectedValue	(self, -1);
	UIDropDownMenu_JustifyText		(self, "CENTER");
	UIDropDownMenu_SetWidth			(self, 150);

end

-----------------------------------------

function Atr_SONumStacks_Initialize()

	local info = UIDropDownMenu_CreateInfo();

	Atr_AddMenuPick (info, ZT("As many as possible"),		-1,  Atr_SONumStacks_OnClick)
	Atr_AddMenuPick (info, "1",								 1,  Atr_SONumStacks_OnClick)
	Atr_AddMenuPick (info, "2",								 2,  Atr_SONumStacks_OnClick)
	Atr_AddMenuPick (info, "3",								 3,  Atr_SONumStacks_OnClick)
	Atr_AddMenuPick (info, "4",								 4,  Atr_SONumStacks_OnClick)
	Atr_AddMenuPick (info, "5",								 5,  Atr_SONumStacks_OnClick)
	Atr_AddMenuPick (info, "10",							10,  Atr_SONumStacks_OnClick)
                                            
end

-----------------------------------------

function Atr_SONumStacks_OnClick(self)

	UIDropDownMenu_SetSelectedValue(self.owner, self.value);
	Atr_Mem_stacksOf_text:SetText (ZT ((self.value == 1) and "stack of" or "stacks of"));
end



-----------------------------------------

function Atr_ShowOptionTooltip (elem)

	local name = elem:GetName();
	local text;

	if (zc.StringContains (name, "Enable_Alt")) then
		text = ZT("If this option is checked, holding the Alt key down while clicking an item in your bags will switch to the Auctionator panel, place the item in the Auction Item area, and start the scan.");
	end

	if (zc.StringContains (name, "Deftab")) then
		text = ZT("Select the Auctionator panel to be displayed first whenever you open the Auction House window.");
	end

	if (zc.StringContains (name, "Open_BUY")) then
		text = ZT("If this option is checked, the Auctionator BUY panel will display first whenever you open the Auction House window.");
	end

	if (zc.StringContains (name, "Open_All_Bags")) then
		text = ZT("If this option is checked, ALL your bags will be opened when you first open the Auctionator panel.");
	end

	if (zc.StringContains (name, "Def_Duration")) then
		text = ZT("If this option is checked, every time you initiate a new auction the auction duration will be reset to the default duration you've selected.");
	end

	if (text) then
		local titleFrame = getglobal (name.."_CB_Text") or getglobal (name.."_Text");
		
		local titleText = titleFrame and titleFrame:GetText() or "???";
		
		GameTooltip:SetOwner(this, "ANCHOR_LEFT");
		GameTooltip:SetText(titleText, 0.9, 1.0, 1.0);
		GameTooltip:AddLine(text, 0.5, 0.5, 1.0, 1);
		GameTooltip:Show();
	end
	
end

-----------------------------------------

function Atr_SetupScanningConfigFrame ()

	UIDropDownMenu_Initialize(Atr_scanLevelDD, Atr_scanLevelDD_Initialize);
	UIDropDownMenu_SetSelectedValue(Atr_scanLevelDD, AUCTIONATOR_SCAN_MINLEVEL);
end

-----------------------------------------

function Atr_ScanningOptionsFrame_Save()

	local origValues = zc.msg_str (AUCTIONATOR_SCAN_MINLEVEL);

	AUCTIONATOR_SCAN_MINLEVEL = UIDropDownMenu_GetSelectedValue(Atr_scanLevelDD);

	local newValues = zc.msg_str (AUCTIONATOR_SCAN_MINLEVEL);

	if (origValues ~= newValues) then
		zc.msg_atr (ZT("scanning options saved"));
	end
	
end

-----------------------------------------

function Atr_scanLevelDD_Initialize()

	local info = UIDropDownMenu_CreateInfo();
	
	Atr_AddMenuPick (info, "|cffa335ee"..ZT("Epic").."|r",			5, Atr_scanLevelDD_OnClick);
	Atr_AddMenuPick (info, "|cff0070dd"..ZT("Rare").."|r",			4, Atr_scanLevelDD_OnClick);
	Atr_AddMenuPick (info, "|cff1eff00"..ZT("Uncommon").."|r",		3, Atr_scanLevelDD_OnClick);
	Atr_AddMenuPick (info, "|cffffffff"..ZT("Common").."|r",		2, Atr_scanLevelDD_OnClick);
	Atr_AddMenuPick (info, "|cff9d9d9d"..ZT("Poor (all)").."|r",	1, Atr_scanLevelDD_OnClick);

end

-----------------------------------------

function Atr_scanLevelDD_OnClick(self)
	UIDropDownMenu_SetSelectedValue(self.owner, self.value);
end

-----------------------------------------

function Atr_scanLevelDD_showTip(self)

	GameTooltip:SetOwner(this, "ANCHOR_LEFT");
	GameTooltip:SetText(ZT("Minimum Quality Level"), 0.9, 1.0, 1.0);
	GameTooltip:AddLine(ZT("Only include items in the scanning database that are this level or higher"), 0.5, 0.5, 1.0, 1);
	GameTooltip:Show();
end



-----------------------------------------

function Atr_MakeOptionsFrameOpaque ()

	local bd = { bgFile="Interface/RAIDFRAME/UI-RaidFrame-GroupBg",
				 edgeFile="Interface/DialogFrame/UI-DialogBox-Border", 
				 tile=false, edgeSize=32,
				 insets={left=11,right=11,top=10,bottom=10}
				};
	
	local list_bd = { 
					bgFile="Interface/CharacterFrame/UI-Party-Background",
					tile=true,
					insets={left=5,right=5,top=5,bottom=5}
					}

	InterfaceOptionsFrame:SetBackdrop ( bd );
	InterfaceOptionsFrameAddOns:SetBackdrop ( list_bd );
	InterfaceOptionsFrameCategories:SetBackdrop ( list_bd );
end

-----------------------------------------

local gInterfaceOptionsMask;

-----------------------------------------

function ShowInterfaceOptionsMask()

	if (gInterfaceOptionsMask == nil) then
		gInterfaceOptionsMask = CreateFrame ("Frame", "Atr_Mask_StdOptions", getglobal("InterfaceOptionsFrame"), "Atr_Mask_StdOptionsTempl");
		gInterfaceOptionsMask:SetFrameLevel (129);
	end
	
	gInterfaceOptionsMask:Show();
	
end

-----------------------------------------

function HideInterfaceOptionsMask()
	if (gInterfaceOptionsMask) then
		gInterfaceOptionsMask:Hide();
	end
end




local addonName, addonTable = ...; 
local zc = addonTable.zc;


local Atr_orig_RecipeKnown_EventScan;
local Atr_orig_LootLink_OnEvent;
local Atr_orig_WOWEcon_Scan_AH;

-----------------------------------------


local function Atr_RecipeKnown_EventScan (rkSelf, rkEvent, rkArg1)

	if (event == "AUCTION_ITEM_LIST_UPDATE") then

		if (Atr_IsTabSelected()) then
			return;
		end
	
		local numBatchAuctions = GetNumAuctionItems("list");
		if (numBatchAuctions > 50) then		-- full scan
			return;
		end
	end

	Atr_orig_RecipeKnown_EventScan (rkSelf, rkEvent, rkArg1);
end

-----------------------------------------

local function Atr_LootLink_OnEvent ()

	if (event == "AUCTION_ITEM_LIST_UPDATE") then

		if (Atr_IsTabSelected()) then
			return;
		end
	
		local numBatchAuctions = GetNumAuctionItems("list");
		if (numBatchAuctions > 50) then		-- full scan
			return;
		end
	end

	Atr_orig_LootLink_OnEvent ();
end

-----------------------------------------

local function Atr_WOWEcon_Scan_AH ()

	if (Atr_IsTabSelected()) then
		return;
	end

	local numBatchAuctions = GetNumAuctionItems("list");
	if (numBatchAuctions > 50) then		-- full scan
		return;
	end

	Atr_orig_WOWEcon_Scan_AH ();
end


-----------------------------------------

function Atr_Check_For_Conflicts (addonName)

	if (zc.StringSame (addonName, "recipeknown") and RecipeKnown_EventScan) then
		Atr_orig_RecipeKnown_EventScan = RecipeKnown_EventScan;
		RecipeKnown_EventScan = Atr_RecipeKnown_EventScan
		zc.msg_yellow ("Auctionator is patching RecipeKnown to prevent a known conflict.");
	end

	if (zc.StringContains (addonName, "lootlink") and LootLink_OnEvent) then
		Atr_orig_LootLink_OnEvent = LootLink_OnEvent;
		LootLink_OnEvent = Atr_LootLink_OnEvent
		zc.msg_yellow ("Auctionator is patching LootLink to prevent a known conflict.");
	end

	if (zc.StringContains (addonName, "wowecon") and WOWEcon_Scan_AH) then
		Atr_orig_WOWEcon_Scan_AH = WOWEcon_Scan_AH;
		WOWEcon_Scan_AH = Atr_WOWEcon_Scan_AH
		zc.msg_yellow ("Auctionator is patching WowEcon to prevent a known conflict.");
	end

end
