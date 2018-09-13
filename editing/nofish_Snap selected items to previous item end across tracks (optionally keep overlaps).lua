--[[
 * ReaScript Name: Snap selected items to previous item end across tracks (optionally keep overlaps)
 * Version: 1.0
 * Author: nofish
 * Author URI: https://forum.cockos.com/member.php?u=6870
 * About:
 *  See this thread for the idea:  
 *  https://forum.cockos.com/showthread.php?t=206841  
 *  In the script's USER CONFIG AREA can be set if item overlaps should be kept or not  
--]]

--[[
 * Changelog:
 * v1.0 (September 13 2018)
  + Initial Release
--]]


-- USER CONFIG AREA -----------------------------------------------------------

KEEP_OVERLAPS = true -- keep relative positions of overlapping items or not

------------------------------------------------------- END OF USER CONFIG AREA


function PreventUndo()
end
reaper.defer(PreventUndo)

DBG = false
function Msg(m)
  if DBG == true then
    reaper.ShowConsoleMsg(tostring(m) .. "\n")
  end
end

selItemsTable = {}

function PrintTakeName(i)
  item = selItemsTable[i].item
  take = reaper.GetActiveTake(item)
  takeName = reaper.GetTakeName(take)
  Msg("Takename: " .. takeName)
end


-- Main() --
function Main()

  -- reaper.ClearConsole()
  
  -- Put sel. items in table
  for i = 0, selItemsCount - 1 do
    selItem = reaper.GetSelectedMediaItem(0, i)
    local tableIdx = i + 1 -- Lua uses 1-based tables
    selItemsTable[tableIdx] = {}
    selItemsTable[tableIdx].item = selItem
    selItemsTable[tableIdx].pos = reaper.GetMediaItemInfo_Value(selItem, "D_POSITION")
    selItemsTable[tableIdx].length = reaper.GetMediaItemInfo_Value(selItem, "D_LENGTH")
    selItemsTable[tableIdx]._end = selItemsTable[tableIdx].pos + selItemsTable[tableIdx].length
  end


  -- Sort table for item pos
  table.sort(selItemsTable, function( a,b )
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

  
  if KEEP_OVERLAPS == true then
    -- Loop through sorted items table and build 'item clusters' table
    -- the item clusters (consisting of 1 or 1+x item(s) which overlap)
    -- are then moved together (to keep overlaps)
    i = 1
    itemsclusterTable = {}
    itemsclusterCount = 0
    
    while i <= #selItemsTable do
      -- Msg("i: " .. i)
      -- PrintTakeName(i)

      itemsclusterCount = itemsclusterCount + 1
      itemsPerItemsclusterCount = 1
      
      startOfItemCluster = selItemsTable[i].pos
      endOfItemCluster = selItemsTable[i]._end
      for k = i + 1, #selItemsTable do -- check if following items overlap
        -- Msg("k: " .. k)
        -- PrintTakeName(k)

        if selItemsTable[k].pos < selItemsTable[i]._end then -- following item overlaps w/ cur. one, add to cluster
          Msg("Item " .. i .. " overlaps w/ item " .. k)
          itemsPerItemsclusterCount = itemsPerItemsclusterCount + 1
          
          if selItemsTable[k]._end > selItemsTable[i]._end then -- check where the cluster ends
            endOfItemCluster = selItemsTable[k]._end
          end

          i = i + 1
        end -- if selItemsTable[k].pos < selItemsTable[i]._end then
      end -- for k = i + 1, #selItemsTable do

      Msg("itemsPerItemsclusterCount: " .. itemsPerItemsclusterCount)
      Msg("Start of item cluster: " .. startOfItemCluster)
      Msg("End of item cluster: " .. endOfItemCluster)
      Msg("\n")
      
      itemsclusterTable[itemsclusterCount] = {}
      itemsclusterTable[itemsclusterCount]._itemsPerItemsclusterCount = itemsPerItemsclusterCount
      itemsclusterTable[itemsclusterCount]._startOfItemcluster = startOfItemCluster
      itemsclusterTable[itemsclusterCount]._endOfItemcluster = endOfItemCluster
      i = i + 1
      -- reaper.ShowMessageBox("", "", 0)
    end -- while i <= #selItemsTable do
    

    -- Loop through itemClusterTable, move items in cluster to end of prev. cluster
    if #itemsclusterTable < 2 then return end
    Msg("Move item clusters...")

    curItemIdx = itemsclusterTable[1]._itemsPerItemsclusterCount + 1 -- first cluster stays put
    accumulatedDistanceToMove = 0

    reaper.Undo_BeginBlock()
      for i = 2, #itemsclusterTable do -- loop through item clusters
        Msg("i: " .. i)
        for k = 1, itemsclusterTable[i]._itemsPerItemsclusterCount do -- move items per cluster together
          Msg("k: " .. k)
          Msg("curItmIdx: " .. curItemIdx)
          endOfPrevItemcluster = itemsclusterTable[i-1]._endOfItemcluster
          distanceToMovePerItemcluster = (itemsclusterTable[i]._startOfItemcluster -  endOfPrevItemcluster)
          Msg("distanceToMovePerItemcluster".. distanceToMovePerItemcluster)
          
          item = selItemsTable[curItemIdx].item
          totalDistanceToMoveItemCluster = distanceToMovePerItemcluster + accumulatedDistanceToMove
          reaper.SetMediaItemInfo_Value(item, "D_POSITION",  selItemsTable[curItemIdx].pos - totalDistanceToMoveItemCluster)
          curItemIdx = curItemIdx + 1
        end -- for k = 1, itemsclusterTable[i]._itemsPerItemsclusterCount do
          accumulatedDistanceToMove = accumulatedDistanceToMove + distanceToMovePerItemcluster
          Msg(" accumulatedDistanceToMove: " ..  accumulatedDistanceToMove)
          Msg("\n")
      end -- for i = 2, #itemsclusterTable do
    reaper.Undo_EndBlock("Script: Snap sel. items to prev. items end across tracks", -1)

  else -- KEEP_OVERLAPS == false
    -- Loop through items table and reposition items
    reaper.Undo_BeginBlock()
      movedDistanceTotal = 0
    
      for i = 2, #selItemsTable do -- first item stays put
        prevItemPos = selItemsTable[i-1].pos
        newPos = prevItemPos + selItemsTable[i-1].length
        item = selItemsTable[i].item
        reaper.SetMediaItemInfo_Value(item, "D_POSITION", newPos - movedDistanceTotal)
        movedDistanceTotal = movedDistanceTotal + (selItemsTable[i].pos - newPos)
      end
    reaper.Undo_EndBlock("Script: Snap sel. items to prev. items end across tracks", -1)
  
  end -- if KEEP_OVERLAPS == true then

end -- Main()

-- START
--reaper.SelectAllMediaItems(0, true) -- DBG
selItemsCount = reaper.CountSelectedMediaItems(0)
if selItemsCount > 1 then
  reaper.PreventUIRefresh(1)
  Main()
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange() 
end
