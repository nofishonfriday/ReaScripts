--[[
 * Version: 1.0
 * Author: nofish
 * About:
 *  http://forum.cockos.com/showpost.php?p=1759449&postcount=11
--]]


--[[
 * Changelog:
 * v1.0 (Dec 26 2016)
  + Initial Release
--]]



function main() 
  didSomething = false
  retval, tracknum, fxnum = reaper.GetFocusedFX()  
  local cur_track = reaper.GetTrack(0, tracknum-1)
  if (cur_track) then
    reaper.Main_OnCommand(40340, 0) -- unsolo all tracks
    reaper.SetMediaTrackInfo_Value(cur_track, "I_SOLO", 1)
    didSomething = true
  end
end

reaper.Undo_BeginBlock() 
main()
reaper.Undo_EndBlock("nofish_Solo (exclusive) last focused FX", -1)




