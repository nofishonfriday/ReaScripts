--- user area ---
wait_time_in_seconds = 5
--- end of user area ---


reaper.ShowConsoleMsg("") -- clear console

reaper.Main_OnCommand(1007, 0) -- Transport: Play

lasttime=os.time()
loopcount=0


function runloop()
  local newtime=os.time()
  
  if (loopcount < 1) then
    if newtime-lasttime >= wait_time_in_seconds then
      lasttime=newtime
      -- do whatever you want to do every 10 seconds
      reaper.ShowConsoleMsg("waited 2 seconds\n...")
      loopcount = loopcount+1
    end
  else
    reaper.Main_OnCommand(1016, 0) -- Transport: Stop
    
    reaper.ShowConsoleMsg("stop !")
    loopcount = loopcount+1
    
    -- is_new,name,sec,cmd,rel,res,val = reaper.get_action_context();  
    -- reaper.ShowConsoleMsg(cmd)
    -- reaper.ShowConsoleMsg("\n")
    
    -- gfx.quit()
  end
    
  
 

  -- note, this program will run forever, until terminated by the action
  -- "close all running reascripts", which is possibly not ideal.
  if (loopcount < 2) then reaper.defer(runloop) end

end

reaper.defer(runloop)
