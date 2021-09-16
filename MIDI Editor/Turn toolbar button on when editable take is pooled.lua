-- @description Turn toolbar button on when editable take is pooled
-- @author nofish
-- @provides [main=midi_editor] .
-- @about
--   see http://forum.cockos.com/showthread.php?t=163359
-- @version 1.0.0
-- @changelog
--   initial release

-- Check whether the required version of REAPER is available
if not reaper.MIDIEditor_EnumTakes then
  reaper.ShowMessageBox("This script requires REAPER v6.37 or above.", "ERROR", 0)
  return(false) 
end

local _,filename,sectionID,cmdID = reaper.get_action_context()

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
      local i = 0
      local foundEditableTake = false
      while true do
        local take = reaper.MIDIEditor_EnumTakes(me, i, true)
        if take == nil then break end
        local sourceType = reaper.GetMediaSourceType(reaper.GetMediaItemTake_Source(take), '')
        if sourceType == "MIDIPOOL" then foundEditableTake = true end
        -- reaper.ShowConsoleMsg(sourceType)
        i = i+1
      end -- while true do
      reaper.SetToggleCommandState(sectionID, cmdID, foundEditableTake and 1 or 0) 
      -- reaper.ShowConsoleMsg(tostring(foundEditableTake and 1 or 0) .. "\n")
      reaper.RefreshToolbar2(sectionID, cmdID)
    end -- if me ~= nil then
  end -- if newtime - lasttime...

  reaper.defer(main) 
end -- main()

reaper.defer(main)

reaper.atexit(DoAtExit)









