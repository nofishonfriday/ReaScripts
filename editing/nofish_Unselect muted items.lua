--[[
 * Version: 1.0
 * ReaScript Name: Unselect muted items
 * Author: nofish
 * About:
 *   Unselects muted items.
--]]

--[[
 Changelog:
 * v1.0 Feb. 22 2018
    + Initial release
--]]


-- for debugging
function msg(m)
  reaper.ShowConsoleMsg(tostring(m) .. "\n")
end

function UnselectMutedItems()
  reaper.Undo_BeginBlock2()
  
  selected_items_count = reaper.CountSelectedMediaItems(0) -- count sel. items 
  
  -- store sel. items in array
  local selected_items_table = {} -- init table
  for i = 0, selected_items_count do
    item = reaper.GetSelectedMediaItem(0, i) -- get selected item
    selected_items_table[#selected_items_table + 1] = item -- ...store this item to end of table
  end
  
  -- loop through array
  reaper.PreventUIRefresh(1)
  for i=1, #selected_items_table do 
    -- reaper.ShowConsoleMsg("Stored item pointer " .. i .. " :")
    -- msg(selected_items_table[i])
    if selected_items_table[i] ~= nil then
      mute_state = reaper.GetMediaItemInfo_Value(selected_items_table[i], "B_MUTE") -- check if item is muted
      if mute_state == 1.0 then -- if item is muted...
        reaper.SetMediaItemSelected(selected_items_table[i], false)
      end 
    end
  end -- end of loop through array
  reaper.PreventUIRefresh(-1)
  
  reaper.UpdateArrange() 
  reaper.Undo_EndBlock2(0, "Script: Unselect muted items",-1)
end -- end of function delete_muted_items_from_selection()

UnselectMutedItems() -- call the function
  
    
