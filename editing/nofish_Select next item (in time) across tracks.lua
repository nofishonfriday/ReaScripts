--[[
 * ReaScript Name: nofish_Select next item (in time) across tracks
 * Version: 1.0
 * Author: nofish
 * Author URI: https://forum.cockos.com/member.php?u=6870
 * Extensions: SWS/S&M 2.8.1
 * About:
 *  Selects next item in the timeline of the currently selected one across all tracks  
 *  In the script's USER CONFIG AREA can be set if cursor should move to beginning of next selected item
--]]

--[[
 * Changelog:
 * v1.0 (Oktober 3 2017)
  + Initial Release
--]]

--- mod of X-Raym's "Find and go to next items on selected tracks with input text as notes.lua", thanks


-- USER CONFIG AREA -----------------------------------------------------------

move_cursor = false -- true/false: move cursor to start of the next selcted item

------------------------------------------------------- END OF USER CONFIG AREA


function preventUndo()
end
reaper.defer(preventUndo)


function main() -- local (i, j, item, take, track)

	-- reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.
	
	-- get position of currently sel. item
	selItem = reaper.GetSelectedMediaItem(0, 0)
	if selItem ~= nil then
		selItemPos = reaper.GetMediaItemInfo_Value(selItem, "D_POSITION")
	else
		return
	end
	

	reaper.SelectAllMediaItems(0, false) -- Unselect all items

	items = {}
	items_total = 0

	-- LOOP THROUGH TRACKS
	for i = 0, tracks_count - 1 do

		track = reaper.GetTrack(0, i)

		count_items_tracks = reaper.GetTrackNumMediaItems(track)

		for j = 0, count_items_tracks - 1 do

			item = reaper.GetTrackMediaItem(track, j)

			items_total = items_total + 1

			items[items_total] = {}

			items[items_total].item = item
			items[items_total].pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
		end
		
	end

	table.sort(items, function( a,b )
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


	-- INITIALIZE loop through items
	for i = 1, #items do
		-- GET ITEMS
		item = items[i].item -- Get selected item i

		item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")

		if item_pos > selItemPos then
			
			if (move_cursor) then
				reaper.SetEditCurPos(item_pos, true, true)
			end
			
			reaper.SetMediaItemSelected(item, true)
		
			break
		end

	end -- ENDLOOP through selected items
	
	-- if this is the last item, keep it selected
	if selItemPos == items[#items].pos then
			   
		reaper.SetMediaItemSelected(item, true)
	end
		    
	-- reaper.Undo_EndBlock("Select next item (in time) across tracks", -1) -- End of the undo block. Leave it at the bottom of your main function.

end

-- START
tracks_count = reaper.CountTracks(0)

if tracks_count > 0 then
	reaper.PreventUIRefresh(1)
	
	main() -- Execute your main function
	
	reaper.PreventUIRefresh(-1)
	
	reaper.UpdateArrange() -- Update the arrangement (often needed)
end
