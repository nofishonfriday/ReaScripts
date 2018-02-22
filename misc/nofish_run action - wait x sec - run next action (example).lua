--[[
 * ReaScript Name: Run action - wait x sec - run next action (example)
 * Version: 1.0
 * Author: nofish
 * About:
 *  example script for waiting x seconds between running two actions  
 *  see http://forum.cockos.com/showthread.php?t=189856
--]]

--[[
 Changelog:
 * v1.0
    + Initial release
--]]

--- reaper.ShowConsoleMsg("") -- clear console


----------------------------------------------------
-- EDIT THE WAITING TIME IN SECONDS BETWEEN RUNNING ACTIONS HERE

wait_time_in_seconds = 5

----------------------------------------------------



----------------------------------------------------
-- PUT ACTION(S) YOU WANT TO RUN IMMEDIATELY HERE

reaper.Main_OnCommand(1007, 0) -- Transport: Play

----------------------------------------------------


-- waiting code taken from schwa, thanks
-- http://forum.cockos.com/showthread.php?t=168270
lasttime=os.time()
loopcount=0

function runloop()
  local newtime=os.time()
  
  if (loopcount < 1) then
    if newtime-lasttime >= wait_time_in_seconds then
      lasttime=newtime
      -- do whatever you want to do every x seconds
      -- reaper.ShowConsoleMsg("waited ".. wait_time_in_seconds .. " seconds")
      loopcount = loopcount+1
    end
  else
    ----------------------------------------------------
    -- PUT ACTION(S) YOU WANT TO RUN AFTER WAITING HERE
    
    reaper.Main_OnCommand(1016, 0) -- Transport: Stop
    
    ----------------------------------------------------
    
    -- reaper.ShowConsoleMsg("stop !")
    loopcount = loopcount+1
  end
  if 
    (loopcount < 2) then reaper.defer(runloop) 
  end
end

reaper.defer(runloop)
