-- @description Zoom horizontally, change grid relatively (mousewheel) (no Grid Snap auto-toggle)
-- @version 1.2
-- @author MPL, mod by nofish
-- @changelog
--   + prevent spam undo history
--   + nofish mod: no Grid / Snap auto-toggle (https://forum.cockos.com/showpost.php?p=1868963&postcount=1500)
-- @website http://forum.cockos.com/member.php?u=70694
 
 
  function main()
--------------------------------------------------------------------
  zoom_adjust = 1  
  stages = {0.38, -- no snap / no grid
            5, -- 2
            16,--1
            22.84,
            48.84, -- 1/4
            117.86,
            351.95,-- 1/16
            1050.92,
            3200.07,
            6077} -- no snap / no grid
            
            
------------------------------------------------------------------            
  function log(value, base) return math.log(value) /math.log(base)end      
  function msg(s) reaper.ShowConsoleMsg(s..'\n') end
  
  _,_,_,_,_,_,mouse_scroll  = reaper.get_action_context() 
  if mouse_scroll > 0 then 
    reaper.adjustZoom( zoom_adjust,
                       0,--forceset, 
                       true,--doupd, 
                       -1)--centermode )
   else
    reaper.adjustZoom( -zoom_adjust,
                       0,--forceset, 
                       true,--doupd, 
                       -1)--centermode )    
  end
  
  
  grid_t = {}
  for i = 2, -7, -1 do grid_t[#grid_t+1] = 2^i end
 
  zoom_lev = reaper.GetHZoomLevel()   
  
  --[[
  if zoom_lev < stages[2] or zoom_lev > stages[10] then 
    reaper.Main_OnCommand(40753,0) -- disable snap
    if reaper.GetToggleCommandState( 40145 ) == 1 then
      reaper.Main_OnCommand(40145,0) -- toggle grid lines
    end
   else
    reaper.Main_OnCommand(40754,0) -- enable snap
    if reaper.GetToggleCommandState( 40145 ) == 0 then
      reaper.Main_OnCommand(40145,0) -- toggle grid lines
    end
  end
  --]]


  --[[
  mod:
  Grid lines get automatically enabled when using SetProjectGrid()
  https://forum.cockos.com/showthread.php?t=194348
  which is undesired here.
  So we check if grid is enabled before...
  --]]
  gridEnabled = reaper.GetToggleCommandState( 40145 )
  
  for i = 1, #stages-1 do
    if zoom_lev > stages[i] and zoom_lev <= stages[i+1] then
      -- gridEnabled = reaper.GetToggleCommandState( 40145 )
      reaper.SetProjectGrid( 0, grid_t[i] ) 
     
        
      --[[reaper.ShowConsoleMsg("")
      msg('zoom_lev '..zoom_lev)
      msg('grid_t '..i..' // '..grid_t[i]..'\n 2 ^'..log(grid_t[i], 2) )
      msg('stages '..i..'  '..stages[i]) ]]  
      break
    end
  end
  
  -- ...and disable grid again afterwards
  if gridEnabled == 0 and reaper.GetToggleCommandState( 40145 ) == 1 then 
    reaper.Main_OnCommand(40145, 0)
  end
  
  end -- end of main()
  
  
  reaper.defer(main)
