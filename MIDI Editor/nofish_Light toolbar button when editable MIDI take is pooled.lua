-- @description Light toolbar button when editable MIDI take is pooled
-- @author nofish
-- @about
--   thread: http://forum.cockos.com/showthread.php?t=163359  
--   screen capture: https://i.imgur.com/mz8kmGU.gif   
--   assign script to a MIDI editor toolbar button, button lights up when a pooled take is set to editable in the MIDI editor  
--   optionally make the script auto-start with REAPER, see https://forum.cockos.com/showthread.php?t=257588
-- @version 1.0.0
-- @changelog
--   initial release

-- Check whether the required version of REAPER is available
if reaper.MIDIEditor_EnumTakes == nil then
  reaper.ShowMessageBox("This script requires REAPER v6.37 or above.", "ERROR", 0)
  return(false) 
end

local _,_,sectionID,cmdID = reaper.get_action_context()

function DoAtExit()
  -- set toolbar button to off
  reaper.SetToggleCommandState(sectionID, cmdID, 0)
  reaper.RefreshToolbar2(sectionID, cmdID);
end

local lasttime = os.time()
function main()
  local newtime=os.time()
  -- slow down script frequency
  -- https://forum.cockos.com/showpost.php?p=1591089&postcount=14
  if newtime-lasttime >= 0.5 then -- run ~every 0.5 sec.
    lasttime = newtime
    local me = reaper.MIDIEditor_GetActive()
    if me ~= nil then
      -- iterate (enum) editable takes
      local i = 0
      local foundPooledTake = false
      while true do
        local take = reaper.MIDIEditor_EnumTakes(me, i, true)
        if take == nil then break end
        -- reaper.ShowConsoleMsg(tostring(take))
        local sourceType = reaper.GetMediaSourceType(reaper.GetMediaItemTake_Source(take), '')
        -- reaper.ShowConsoleMsg(sourceType)
        if sourceType == "MIDIPOOL" then 
          foundPooledTake = true
          break
        end
        i = i+1
      end -- while true do
      reaper.SetToggleCommandState(sectionID, cmdID, foundPooledTake and 1 or 0) -- convert boolean to 0/1
      -- reaper.ShowConsoleMsg(tostring(foundEditableTake and 1 or 0) .. "\n")
      reaper.RefreshToolbar2(sectionID, cmdID)
    end -- if me ~= nil then
  end -- if newtime - lasttime...

  reaper.defer(main) 
end -- main()

reaper.defer(main)

reaper.atexit(DoAtExit)









