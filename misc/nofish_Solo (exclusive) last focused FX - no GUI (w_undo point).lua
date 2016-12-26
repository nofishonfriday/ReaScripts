--[[
 * ReaScript Name: Solo (exclusive) last focused FX
 * Description: solos the track which contains the last focused FX
 * Instructions: Run (bind to toolbar/shortcut).
 * Screenshot: http://i.imgur.com/RgUGGNg.gif
 * Author: nofish
 * Author URI: http://forum.cockos.com/member.php?u=6870
 * Repository:
 * Repository URI: https://github.com/nofishonfriday/ReaScripts
 * File URI: 
 * Licence: GPL v3
 * Forum Thread: Solo for every plugin
 * Forum Thread URI: http://forum.cockos.com/showpost.php?p=1759449&postcount=11
 * REAPER: 5.0
 * Extensions: None
 * Version: 1.0
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




