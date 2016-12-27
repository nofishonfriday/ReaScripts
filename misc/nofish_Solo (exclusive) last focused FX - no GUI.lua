--[[
 * Version: 1.0
 * Author: nofish
 * About:
 *  http://forum.cockos.com/showpost.php?p=1759098&postcount=8
--]]


--[[
 * Changelog:
 * v1.0 (Dec 26 2016)
  + Initial Release
--]]


local function unsolo_all_tracks()
  for i = 0, reaper.CountTracks(0)-1 do
    local track = reaper.GetTrack(0, i)
    if (track) then
      reaper.SetMediaTrackInfo_Value(track, "I_SOLO", 0)
    end
  end
end



function main() 
  retval, tracknum, fxnum = reaper.GetFocusedFX()  
  local cur_track = reaper.GetTrack(0, tracknum-1)
  if (cur_track) then
    -- reaper.Main_OnCommand(40340, 0) -- unsolo all tracks
    unsolo_all_tracks() -- used this rather than native action to not create an undo point
    reaper.SetMediaTrackInfo_Value(cur_track, "I_SOLO", 1)
  end
end

--reaper.Undo_BeginBlock()
reaper.defer(main)
-- reaper.Undo_EndBlock("nofish_Solo (exclusive) last focused FX", -1)


