-- ===========================================================================
-- CityBannerManager for Basegame (Vanilla)
-- ===========================================================================
-- Functions and objects common to basegame and expansions
include("citybannermanager_CQUI.lua");

-- ===========================================================================
-- Cached Base Functions (Basegame only)
-- ===========================================================================
BASE_CQUI_CityBanner_Initialize = CityBanner.Initialize;
BASE_CQUI_CityBanner_UpdateProduction = CityBanner.UpdateProduction;
BASE_CQUI_CityBanner_UpdateStats = CityBanner.UpdateStats; -- Basegame only!  Not Expansion 1/2

-- ===========================================================================
-- CQUI Basegame Extension Functions
-- ===========================================================================
--function CityBanner.Initialize( self : CityBanner, playerID: number, cityID : number, districtID : number, bannerType : number, bannerStyle : number)
function CityBanner.Initialize( self, playerID, cityID, districtID, bannerType, bannerStyle)
    print_debug("CityBannerManager_CQUI_basegame: CityBanner:Initialize ENTRY: playerID:"..tostring(playerID).." cityID:"..tostring(cityID).." districtID:"..tostring(districtID).." bannerType:"..tostring(bannerType).." bannerStyle:"..tostring(bannerStyle));
    CQUI_Common_CityBanner_Initialize(self, playerID, cityID, districtID, bannerType, bannerStyle);
end

-- ===========================================================================
function CityBanner.UpdateProduction(self)
    -- Single line difference between this and the base version that allows the icon of that
    -- which is being built to appear in the CityBanner
    print_debug("CityBannerManager_CQUI_basegame: CityBanner.UpdateProduction ENTRY");
    BASE_CQUI_CityBanner_UpdateProduction(self);

    local localPlayerID :number = Game.GetLocalPlayer();
    local pCity         :table = self:GetCity();
    local pBuildQueue   :table  = pCity:GetBuildQueue();

    if (localPlayerID == pCity:GetOwner() and pBuildQueue ~= nil) then
        -- if there is anything in the build queue, it will have a hash, otherwise the hash is 0.
        local currentProductionHash :number = pBuildQueue:GetCurrentProductionTypeHash();

        if (currentProductionHash ~= 0) then
            -- This single line is responsible for the icon of what is being produced showing in the City Banner
            self.m_Instance.ProductionIndicator:SetHide(false);
        end
    end
end

-- ===========================================================================
function CityBanner.UpdateStats(self)
    -- Most of the logic here is basegame only, XP1/XP2 do this work in the CityBanner.UpdatePopulation function
    print_debug("CityBannerManager_CQUI_basegame: CityBanner.UpdateStats ENTRY");
    BASE_CQUI_CityBanner_UpdateStats(self);

    -- CQUI get real housing from improvements value (do this regardless of whether or not the banners will be updated)
    local pCity   :table  = self:GetCity();
    local pCityID :number = pCity:GetID();
    local localPlayerID :number = Game.GetLocalPlayer();

    if (CQUI_HousingUpdated[localPlayerID] == nil or CQUI_HousingUpdated[localPlayerID][pCityID] ~= true) then
        CQUI_RealHousingFromImprovements(pCity, localPlayerID, pCityID);
    end

    if (self.m_Type ~= BANNERTYPE_CITY_CENTER) then
        return;
    end

    if (self.m_Player ~= Players[localPlayerID]) then
        return;
    end

    if (CQUI_SmartBanner == false) then
        return;
    end

    if (CQUI_SmartBanner_Cultural) then
        -- Show the turns left until border expansion to the left of the population
        local pCityCulture = pCity:GetCulture();
        local turnsUntilBorderGrowth = pCityCulture:GetTurnsUntilExpansion();
        self.m_Instance.CityCultureTurnsLeft:SetText(turnsUntilBorderGrowth);
        self.m_Instance.CityCultureTurnsLeft:SetHide(false);
    else
        self.m_Instance.CityCultureTurnsLeft:SetHide(true);
    end

    if (CQUI_SmartBanner_Population) then
        -- TODO: This logic in this if statement appears in all 3 of the citybannermanager files, can be put into single common file
        local cqui_HousingFromImprovementsCalc = CQUI_HousingFromImprovementsTable[localPlayerID][pCityID];    -- CQUI real housing from improvements value
        if (cqui_HousingFromImprovementsCalc ~= nil) then
            -- Basegame text includes the number of turns remaining before city growth
            local currentPopulation :number  = pCity:GetPopulation();
            local pCityGrowth       :table   = pCity:GetGrowth();
            local foodSurplus       :number  = pCityGrowth:GetFoodSurplus();
            local isGrowing         :boolean = pCityGrowth:GetTurnsUntilGrowth() ~= -1;
            local isStarving        :boolean = pCityGrowth:GetTurnsUntilStarvation() ~= -1;

            local turnsUntilGrowth  :number  = 0; -- It is possible for zero... no growth and no starving.
            local popTurnLeftColor  :string  = "StatNormalCS"; -- Value if 0
            if (isGrowing) then
                turnsUntilGrowth = pCityGrowth:GetTurnsUntilGrowth();
                popTurnLeftColor = "StatGoodCS";
            elseif (isStarving) then
                turnsUntilGrowth = -1 * pCityGrowth:GetTurnsUntilStarvation();
                popTurnLeftColor = "StatBadCS";
            end

            -- CQUI real housing from improvements fix to show correct values when waiting for the next turn
            local housingString, housingLeft = CQUI_GetHousingString(pCity, cqui_HousingFromImprovementsCalc);
            housingString = "[COLOR:"..popTurnLeftColor.."]"..turnsUntilGrowth.."[ENDCOLOR] ["..housingString.."] ";
            --local CTLS = "[COLOR:"..popTurnLeftColor.."]"..turnsUntilGrowth.."[ENDCOLOR]  [[COLOR:"..housingLeftColor.."]"..housingLeftText.."[ENDCOLOR]]  ";
            self.m_Instance.CityPopTurnsLeft:SetText(housingString);
            self.m_Instance.CityPopTurnsLeft:SetHide(false);

            -- CQUI : add housing left to tooltip
            local popTooltip = GetPopulationTooltip(self, turnsUntilGrowth, currentPopulation, foodSurplus); -- self.m_Instance.CityPopulation:GetToolTipString(); --populationInstance.FillMeter:GetToolTipString();
            local CQUI_housingLeftPopupText = "[NEWLINE] [ICON_Housing]" .. Locale.Lookup("LOC_HUD_CITY_HOUSING") .. ": " .. housingLeft;
            popTooltip = popTooltip .. CQUI_housingLeftPopupText;
            self.m_Instance.CityPopulation:SetToolTipString(popTooltip);
        end
    else
        self.m_Instance.CityPopTurnsLeft:SetHide(true);
    end
end

-- ===========================================================================
-- CQUI Basegame Replacement Functions
-- Functions that override the unmodified versions in the game
-- ===========================================================================
function CityBanner.UpdateName( self )
    print_debug("CityBannerManager_CQUI_basegame: CityBanner.UpdateName ENTRY");

    if (self.m_Type ~= BANNERTYPE_CITY_CENTER) then
        return;
    end

    local pCity : table = self:GetCity();
    if (pCity == nil) then
        return;
    end

    local owner       :number = pCity:GetOwner();
    local pPlayer     :table  = Players[owner];
    local capitalIcon :string = (pPlayer ~= nil and pPlayer:IsMajor() and pCity:IsCapital()) and "[ICON_Capital]" or "";
    local cityName    :string = capitalIcon .. Locale.ToUpper(pCity:GetName());

    if (not self:IsTeam()) then
        local civType:string = PlayerConfigurations[owner]:GetCivilizationTypeName();
        if (civType ~= nil) then
            self.m_Instance.CivIcon:SetIcon("ICON_" .. civType);
        else
            UI.DataError("Invalid type name returned by GetCivilizationTypeName");
        end
    end

    local questsManager : table = Game.GetQuestsManager();
    local questTooltip  : string = Locale.Lookup("LOC_CITY_STATES_QUESTS");
    local statusString  : string = "";
    if (questsManager ~= nil) then
        for questInfo in GameInfo.Quests() do
            if (questsManager:HasActiveQuestFromPlayer(Game.GetLocalPlayer(), owner, questInfo.Index)) then
                statusString = "[ICON_CityStateQuest]";
                questTooltip = questTooltip .. "[NEWLINE]" .. questInfo.IconString .. questsManager:GetActiveQuestName(Game.GetLocalPlayer(), owner, questInfo.Index);
            end
        end
    end

    -- Update under siege icon
    local pDistrict:table = self:GetDistrict();
    if (pDistrict and pDistrict:IsUnderSiege()) then
        self.m_Instance.CityUnderSiegeIcon:SetHide(false);
    else
        self.m_Instance.CityUnderSiegeIcon:SetHide(true);
    end

    -- Update district icons
    -- districtType:number == Index
    local iAquaduct       = CQUI_GetDistrictIndexSafe("DISTRICT_AQUEDUCT");
    local iBath           = CQUI_GetDistrictIndexSafe("DISTRICT_BATH");
    local iNeighborhood   = CQUI_GetDistrictIndexSafe("DISTRICT_NEIGHBORHOOD");
    local iMbanza         = CQUI_GetDistrictIndexSafe("DISTRICT_MBANZA");
    local iCampus         = CQUI_GetDistrictIndexSafe("DISTRICT_CAMPUS");
    local iTheater        = CQUI_GetDistrictIndexSafe("DISTRICT_THEATER");
    local iAcropolis      = CQUI_GetDistrictIndexSafe("DISTRICT_ACROPOLIS");
    local iIndustrial     = CQUI_GetDistrictIndexSafe("DISTRICT_INDUSTRIAL_ZONE");
    local iHansa          = CQUI_GetDistrictIndexSafe("DISTRICT_HANSA");
    local iCommerce       = CQUI_GetDistrictIndexSafe("DISTRICT_COMMERCIAL_HUB");
    local iEncampment     = CQUI_GetDistrictIndexSafe("DISTRICT_ENCAMPMENT");
    local iHarbor         = CQUI_GetDistrictIndexSafe("DISTRICT_HARBOR");
    local iRoyalNavy      = CQUI_GetDistrictIndexSafe("DISTRICT_ROYAL_NAVY_DOCKYARD");
    local iSpaceport      = CQUI_GetDistrictIndexSafe("DISTRICT_SPACEPORT");
    local iEntComplex     = CQUI_GetDistrictIndexSafe("DISTRICT_ENTERTAINMENT_COMPLEX");
    local iHolySite       = CQUI_GetDistrictIndexSafe("DISTRICT_HOLY_SITE");
    local iAerodrome      = CQUI_GetDistrictIndexSafe("DISTRICT_AERODROME");
    local iStreetCarnival = CQUI_GetDistrictIndexSafe("DISTRICT_STREET_CARNIVAL");
    local iLavra          = CQUI_GetDistrictIndexSafe("DISTRICT_LAVRA");

    if (self.m_Instance.CityBuiltDistrictAquaduct ~= nil) then
        self.m_Instance.CityUnlockedCitizen:SetHide(true);
        self.m_Instance.CityBuiltDistrictAquaduct:SetHide(true);
        self.m_Instance.CityBuiltDistrictBath:SetHide(true);
        self.m_Instance.CityBuiltDistrictNeighborhood:SetHide(true);
        self.m_Instance.CityBuiltDistrictMbanza:SetHide(true);
        self.m_Instance.CityBuiltDistrictCampus:SetHide(true);
        self.m_Instance.CityBuiltDistrictCommercial:SetHide(true);
        self.m_Instance.CityBuiltDistrictEncampment:SetHide(true);
        self.m_Instance.CityBuiltDistrictTheatre:SetHide(true);
        self.m_Instance.CityBuiltDistrictAcropolis:SetHide(true);
        self.m_Instance.CityBuiltDistrictIndustrial:SetHide(true);
        self.m_Instance.CityBuiltDistrictHansa:SetHide(true);
        self.m_Instance.CityBuiltDistrictHarbor:SetHide(true);
        self.m_Instance.CityBuiltDistrictRoyalNavy:SetHide(true);
        self.m_Instance.CityBuiltDistrictSpaceport:SetHide(true);
        self.m_Instance.CityBuiltDistrictEntertainment:SetHide(true);
        self.m_Instance.CityBuiltDistrictHoly:SetHide(true);
        self.m_Instance.CityBuiltDistrictAerodrome:SetHide(true);
        self.m_Instance.CityBuiltDistrictStreetCarnival:SetHide(true);
        self.m_Instance.CityBuiltDistrictLavra:SetHide(true);
    end

    local pCityDistricts:table  = pCity:GetDistricts();
    if (CQUI_SmartBanner and self.m_Instance.CityBuiltDistrictAquaduct ~= nil) then
        --Unlocked citizen check
        if CQUI_SmartBanner_Unmanaged_Citizen then
            local tParameters :table = {};
            tParameters[CityCommandTypes.PARAM_MANAGE_CITIZEN] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_MANAGE_CITIZEN);

            local tResults  :table = CityManager.GetCommandTargets( pCity, CityCommandTypes.MANAGE, tParameters );
            if tResults ~= nil then
                local tPlots       :table = tResults[CityCommandResults.PLOTS];
                local tUnits       :table = tResults[CityCommandResults.CITIZENS];
                local tMaxUnits    :table = tResults[CityCommandResults.MAX_CITIZENS];
                local tLockedUnits :table = tResults[CityCommandResults.LOCKED_CITIZENS];
                if tPlots ~= nil and (table.count(tPlots) > 0) then
                    for i,plotId in pairs(tPlots) do
                        local kPlot :table = Map.GetPlotByIndex(plotId);
                        if(tMaxUnits[i] >= 1 and tUnits[i] >= 1 and tLockedUnits[i] <= 0) then
                            self.m_Instance.CityUnlockedCitizen:SetHide(false);
                        end
                    end
                end
            end
        end
        -- End Unlocked Citizen Check

        if (CQUI_SmartBanner and CQUI_SmartBanner_Districts) then
            for i, district in pCityDistricts:Members() do
                local districtType = district:GetType();
                local districtInfo:table = GameInfo.Districts[districtType];
                local isBuilt = pCityDistricts:HasDistrict(districtInfo.Index, true);
                if (isBuilt) then
                    if (districtType == iAquaduct)       then self.m_Instance.CityBuiltDistrictAquaduct:SetHide(false);       end
                    if (districtType == iBath)           then self.m_Instance.CityBuiltDistrictBath:SetHide(false);           end
                    if (districtType == iNeighborhood)   then self.m_Instance.CityBuiltDistrictNeighborhood:SetHide(false);   end
                    if (districtType == iMbanza)         then self.m_Instance.CityBuiltDistrictMbanza:SetHide(false);         end
                    if (districtType == iCampus)         then self.m_Instance.CityBuiltDistrictCampus:SetHide(false);         end
                    if (districtType == iCommerce)       then self.m_Instance.CityBuiltDistrictCommercial:SetHide(false);     end
                    if (districtType == iEncampment)     then self.m_Instance.CityBuiltDistrictEncampment:SetHide(false);     end
                    if (districtType == iTheater)        then self.m_Instance.CityBuiltDistrictTheatre:SetHide(false);        end
                    if (districtType == iAcropolis)      then self.m_Instance.CityBuiltDistrictAcropolis:SetHide(false);      end
                    if (districtType == iIndustrial)     then self.m_Instance.CityBuiltDistrictIndustrial:SetHide(false);     end
                    if (districtType == iHansa)          then self.m_Instance.CityBuiltDistrictHansa:SetHide(false);          end
                    if (districtType == iHarbor)         then self.m_Instance.CityBuiltDistrictHarbor:SetHide(false);         end
                    if (districtType == iRoyalNavy)      then self.m_Instance.CityBuiltDistrictRoyalNavy:SetHide(false);      end
                    if (districtType == iSpaceport)      then self.m_Instance.CityBuiltDistrictSpaceport:SetHide(false);      end
                    if (districtType == iEntComplex)     then self.m_Instance.CityBuiltDistrictEntertainment:SetHide(false);  end
                    if (districtType == iHolySite)       then self.m_Instance.CityBuiltDistrictHoly:SetHide(false);           end
                    if (districtType == iAerodrome)      then self.m_Instance.CityBuiltDistrictAerodrome:SetHide(false);      end
                    if (districtType == iStreetCarnival) then self.m_Instance.CityBuiltDistrictStreetCarnival:SetHide(false); end
                    if (districtType == iLavra)          then self.m_Instance.CityBuiltDistrictLavra:SetHide(false);          end
                end -- if isBuilt
            end -- for loop
        end -- if CQUI_SmartBanner_Districts
    end -- if CQUI_SmartBanner and there's a district to show

    -- Update insufficient housing icon
    if (self.m_Instance.CityHousingInsufficientIcon ~= nil) then
        local pCityGrowth:table = pCity:GetGrowth();
        if (pCityGrowth and pCityGrowth:GetHousing() < pCity:GetPopulation()) then
            self.m_Instance.CityHousingInsufficientIcon:SetHide(false);
        else
            self.m_Instance.CityHousingInsufficientIcon:SetHide(true);
        end
    end

    -- Update insufficient amenities icon
    if (self.m_Instance.CityAmenitiesInsufficientIcon ~= nil) then
        local pCityGrowth:table = pCity:GetGrowth();
        if pCityGrowth and pCityGrowth:GetAmenitiesNeeded() > pCityGrowth:GetAmenities() then
            self.m_Instance.CityAmenitiesInsufficientIcon:SetHide(false);
        else
            self.m_Instance.CityAmenitiesInsufficientIcon:SetHide(true);
        end
    end

    -- Update occupied icon
    if (self.m_Instance.CityOccupiedIcon ~= nil) then
        if pCity:IsOccupied() then
            self.m_Instance.CityOccupiedIcon:SetHide(false);
        else
            self.m_Instance.CityOccupiedIcon:SetHide(true);
        end
    end

    -- CQUI: Show leader icon for the suzerain
    local pPlayerConfig :table = PlayerConfigurations[owner];
    local isMinorCiv :boolean = pPlayerConfig:GetCivilizationLevelTypeID() ~= CivilizationLevelTypes.CIVILIZATION_LEVEL_FULL_CIV;
    if (isMinorCiv) then
        CQUI_UpdateSuzerainIcon(pPlayer, self);
    end

    self.m_Instance.CityQuestIcon:SetToolTipString(questTooltip);
    self.m_Instance.CityQuestIcon:SetText(statusString);
    self.m_Instance.CityName:SetText( cityName );
    self.m_Instance.CityNameStack:ReprocessAnchoring();
    self.m_Instance.ContentStack:ReprocessAnchoring();
    self:Resize();
end

-- ===========================================================================
-- Basegame and Expansions call this two different things (OnCityRangeStrikeButtonClick and OnCityStrikeButtonClick, respectively)
function OnCityRangeStrikeButtonClick( playerID, cityID )
    print_debug("CityBannerManager_CQUI_basegame: OnCityRangeStrikeButtonClick ENTRY");

    -- Call the common code for handling the City Strike button
    CQUI_OnCityRangeStrikeButtonClick(playerID, cityID);
end

-- ===========================================================================
-- CQUI Custom Functions (Common to basegame only)
-- ===========================================================================
function CQUI_GetDistrictIndexSafe(sDistrict)
    if GameInfo.Districts[sDistrict] == nil then
        return -1;
    else 
        return GameInfo.Districts[sDistrict].Index;
    end
end

-- ===========================================================================
-- CQUI Initialize Function
-- ===========================================================================
function Initialize()
    print_debug("CityBannerManager_CQUI_basegame: Initialize CQUI CityBannerManager");
    -- LuaEvents are initialized in the common file
end
Initialize();
