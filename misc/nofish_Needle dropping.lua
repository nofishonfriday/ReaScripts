--[[
 * ReaScript Name: nofish_Needle dropping.lua
 * Version: 1.0
 * Author: nofish
 * Author URI: https://forum.cockos.com/member.php?u=6870
 * Extensions: SWS/S&M 2.8.1
 * About:
 *  Jumps to random item positions
 *  See https://forum.cockos.com/showthread.php?t=200261
--]]

--[[
 * Changelog:

 * v1.0 - December 6 2017
  + Initial Release

 * v1.01 - December 8 2017
  + Added 'Exclusively select currently playing item' auto-selection mode
--]]

-- Using some code snippets from X-Raym, thanks :)


-- USER CONFIG AREA -----------------------------------------------------------

IGNORE_BEGINNING = 10 -- Ignore first x seconds of item start (useful to skip intros)
IGNORE_END = 10 -- Ignore last x seconds of item end (useful to skip outros)


-- true/false:
MOVE_VIEW = true -- Move currently played item into view
SEEK_PLAYBACK = true -- Move play cursor immediately while playing

ROUND_ROBIN_MODE = false -- false: Random jumps, true: Jumps to next item in timeline


AUTO_SELECT_PLAYING_ITEMS = 1
-- 0: Don't auto-select any items
-- 1: Exclusively select currently playing item
-- 2: Add currently playing item to selection (leave already played items selected)

------------------------------------------------------- END OF USER CONFIG AREA


function msg(m)
  reaper.ShowConsoleMsg(tostring(m) .. "\n")
end

function preventUndo()
end
reaper.defer(preventUndo)

if (ROUND_ROBIN_MODE) then
  if reaper.HasExtState("nofish_Reascripts", "NeedleDropping_lastRRItemNr") then
    lastRRItemNr = tonumber(reaper.GetExtState("nofish_Reascripts", "NeedleDropping_lastRRItemNr"))
  else
    lastRRItemNr = 1
  end
else -- random mode
  if reaper.HasExtState("nofish_Reascripts", "NeedleDropping_lastRndItemNr") then
    lastRndItemNr = tonumber(reaper.GetExtState("nofish_Reascripts", "NeedleDropping_lastRndItemNr"))
  else
    lastRndItemNr = -1
  end
end

function ShowError()
  reaper.ShowMessageBox("At least two unmuted items must be present on sel. track(s) !", "Error", 0 )
end


--------------
--- main() ---
--------------
function main()

  itemsTable = {}
  itemsTotal = 0

  -- store items + startPos in two-dim. table
  for i = 0, selTracksCount - 1 do
  track = reaper.GetSelectedTrack(0, i)

  trackNumItems = reaper.GetTrackNumMediaItems(track)

    for j = 0, trackNumItems - 1 do
      item = reaper.GetTrackMediaItem(track, j)
      -- only store non-muted items
      if reaper.GetMediaItemInfo_Value(item, "B_MUTE") == 0 then
        itemsTotal = itemsTotal + 1
        itemsTable[itemsTotal] = {}
        itemsTable[itemsTotal].item = item
        itemsTable[itemsTotal].pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      end
    end
  end

  if itemsTotal < 2 then
    ShowError()
    return
  end

  --[[
  table.sort(itemsTable, function( a,b )
    if (a.pos < b.pos) then
      -- primary sort on position -> a before b
      return true
    elseif (a.pos > b.pos) then
      -- primary sort on position -> b before a
      return false
    else
      -- primary sort tied, resolve w secondary sort on rank
      return a.pos < b.pos
    end
  end)
  --]]


  if not ROUND_ROBIN_MODE then
    -- choose random item
    nextItemNr = math.random(1, #itemsTable)

    -- make sure the same item is not played consecutively
    while (nextItemNr == lastRndItemNr) do
      nextItemNr = math.random(1, #itemsTable)
    end
    reaper.SetExtState("nofish_Reascripts", "NeedleDropping_lastRndItemNr", nextItemNr, false)

  else -- RR mode, choose next item
    lastRRItemNr = lastRRItemNr + 1
    if lastRRItemNr > #itemsTable then lastRRItemNr = 1 end
    nextItemNr = lastRRItemNr
    reaper.SetExtState("nofish_Reascripts", "NeedleDropping_lastRRItemNr", lastRRItemNr, false)
  end

  nextItem = itemsTable[nextItemNr].item -- Get next item

  -- itemStart = reaper.GetMediaItemInfo_Value(nextItem, "D_POSITION")
  itemStart = itemsTable[nextItemNr].pos
  itemEnd = itemStart + reaper.GetMediaItemInfo_Value(nextItem, "D_LENGTH")

  -- apply ignore values
  itemStart = itemStart + IGNORE_BEGINNING
  itemEnd = itemEnd - IGNORE_END

  -- reaper.GetSet_LoopTimeRange(true, false, itemStart, itemEnd, false )
  if (itemEnd - itemStart > 0) then
    if (AUTO_SELECT_PLAYING_ITEMS == 1) then
      reaper.Main_OnCommand(40289, 0) -- Item: Unselect all items
      -- SWS: Unselect all items on selected track(s)
      -- reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_UNSELONTRACKS"), 0)
      reaper.SetMediaItemInfo_Value(nextItem, "B_UISEL", 1)
    end
    if (AUTO_SELECT_PLAYING_ITEMS == 2) then
      reaper.SetMediaItemInfo_Value(nextItem, "B_UISEL", 1)
    end
    rndPos = math.random() * (itemEnd - itemStart) + itemStart
    reaper.SetEditCurPos(rndPos, MOVE_VIEW, SEEK_PLAYBACK)

  else
    reaper.ShowMessageBox("Ignore intervall > item duration ! \nPlease lower ignore values.", "Error", 0)
    return
  end

end -- end of main()

-- START --
selTracksCount = reaper.CountSelectedTracks(0)
if selTracksCount > 0 then
  main()
else
  ShowError()
  return
end
