-- Photon is a World of Warcraft® user interface addon.
-- Copyright (c) 2026- Linus Olsson
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
addonTable.utilities = addonTable.utilities or {}

--the C_SpellBook functions the spell cache uses. Classic Era only has the older spellbook functions,
--so each one falls back to them when the client doesn't have it, and uses the real one as soon as it does

--the old functions take a book type string instead of an Enum.SpellBookSpellBank
local function bookType(bank)
  return bank == Enum.SpellBookSpellBank.Pet and (BOOKTYPE_PET or "pet") or (BOOKTYPE_SPELL or "spell")
end

--the old item info gives the type as a string
local ITEM_TYPES = {
  SPELL = Enum.SpellBookItemType.Spell,
  FUTURESPELL = Enum.SpellBookItemType.FutureSpell,
  PETACTION = Enum.SpellBookItemType.PetAction,
  FLYOUT = Enum.SpellBookItemType.Flyout,
}

local SpellBook = {
  GetNumSpellBookSkillLines = C_SpellBook.GetNumSpellBookSkillLines or GetNumSpellTabs,

  GetSpellBookSkillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo or function(skillLine)
    local name, iconID, itemIndexOffset, numSpellBookItems = GetSpellTabInfo(skillLine)
    if name then
      return {name = name, iconID = iconID, itemIndexOffset = itemIndexOffset, numSpellBookItems = numSpellBookItems}
    end
  end,

  GetSpellBookItemName = C_SpellBook.GetSpellBookItemName or function(index, bank)
    return GetSpellBookItemName(index, bookType(bank))
  end,

  GetSpellBookItemInfo = C_SpellBook.GetSpellBookItemInfo or function(index, bank)
    local itemType, spellID = GetSpellBookItemInfo(index, bookType(bank))
    if itemType then
      return {itemType = ITEM_TYPES[itemType], spellID = spellID}
    end
  end,

  IsSpellBookItemPassive = C_SpellBook.IsSpellBookItemPassive or function(index, bank)
    return IsPassiveSpell(index, bookType(bank))
  end,
}

addonTable.utilities.SpellBook = SpellBook
