-- Photon is a World of Warcraft® user interface addon.
-- Copyright (c) 2026- Linus Olsson
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
addonTable.utilities = addonTable.utilities or {}

--the C_Reputation functions the reputation bar uses. Classic Era only has the older faction functions,
--so each one falls back to them when the client doesn't have it, and uses the real one as soon as it does

local Reputation = {
  GetNumFactions = C_Reputation.GetNumFactions or GetNumFactions,

  --the old GetFactionInfo returns the values one by one, this packs them like the newer FactionData
  GetFactionDataByIndex = C_Reputation.GetFactionDataByIndex or function(index)
    local name, description, reaction, currentReactionThreshold, nextReactionThreshold, currentStanding,
      atWarWith, canToggleAtWar, isHeader, isCollapsed, isHeaderWithRep, isWatched, isChild, factionID = GetFactionInfo(index)
    if name then
      return {
        name = name,
        description = description,
        reaction = reaction,
        currentReactionThreshold = currentReactionThreshold,
        nextReactionThreshold = nextReactionThreshold,
        currentStanding = currentStanding,
        atWarWith = atWarWith,
        canToggleAtWar = canToggleAtWar,
        isHeader = isHeader,
        isCollapsed = isCollapsed,
        isHeaderWithRep = isHeaderWithRep,
        isWatched = isWatched,
        isChild = isChild,
        factionID = factionID,
      }
    end
  end,

  IsFactionActive = C_Reputation.IsFactionActive or function(index)
    return not IsFactionInactive(index)
  end,

  --paragons came with Legion
  IsFactionParagon = C_Reputation.IsFactionParagon or function() return false end,
  GetFactionParagonInfo = C_Reputation.GetFactionParagonInfo,
}

addonTable.utilities.Reputation = Reputation
