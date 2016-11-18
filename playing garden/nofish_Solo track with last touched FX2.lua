-- Realtime clock
-- see http://forum.cockos.com/showthread.php?t=165884


-- based on spk77's GUI template, thanks
-- http://forum.cockos.com/showthread.php?t=161557 

-- cooldown function (CPU saver) by Jeffos, thanks
-- http://forum.cockos.com/showpost.php?p=1567657&postcount=39

defer_cnt=0

function cooldown()
  if defer_cnt >= 30 then -- run mainloop() every ~900ms
    defer_cnt=0
    reaper.PreventUIRefresh(1)
    mainloop()
    reaper.PreventUIRefresh(-1)
  else
    defer_cnt=defer_cnt+1
  end
  reaper.defer(cooldown)
end



-- Empty GUI template

-- [[ 
-- for debugging
function msg(m)
  return reaper.ShowConsoleMsg(tostring(m) .. "\n")
end
-- ]]



----------
-- Init --
----------

-- GUI table ----------------------------------------------------------------------------------
--   contains GUI related settings (some basic user definable settings), initial values etc. --
-----------------------------------------------------------------------------------------------
local gui = {}

function init()
  
  -- Add stuff to "gui" table
  gui.settings = {}                 -- Add "settings" table to "gui" table 
  gui.settings.font_size = 20       -- font size
  gui.settings.docker_id = 0        -- try 0, 1, 257, 513, 1027 etc.
  
  ---------------------------
  -- Initialize gfx window --
  ---------------------------
  
  gfx.init("", 0, 30, gui.settings.docker_id)
  gfx.setfont(1,"Arial", gui.settings.font_size)
  gfx.clear = 3355443  -- matches with "FUSION: Pro&Clean Theme :: BETA 01" http://forum.cockos.com/showthread.php?t=155329
  -- (Double click in ReaScript IDE to open the link)

  -- mainloop()
end


--------------
-- Mainloop --
--------------

function mainloop()
 
 
 
  --------------
  -- Draw GUI --
  --------------
  
  gfx.x = 10
  gfx.y = 10
  
  retval, tracknum, fxnum = reaper.GetLastTouchedFX() 
  track = reaper.GetTrack(0, tracknum-1)
  trackname = reaper.GetTrackState(track)
  if (trackname == "") then
    gfx.printf(tracknum) else
    gfx.printf(trackname)
  end
 
  gfx.update()
  -- if gfx.getchar() >= 0 then reaper.defer(mainloop) end
end

init() 

cooldown()
