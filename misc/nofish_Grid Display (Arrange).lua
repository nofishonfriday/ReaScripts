--[[
 * ReaScript Name: nofish_Grid Display (Arrange)
 * Version: 1.0
 * Author: nofish
 * About:
 * displays current arrange grid setting, including swing
 * see http://forum.cockos.com/showthread.php?t=189700
--]]

--[[
 Changelog:
 * v1.0
    + Initial release
--]]


--

defer_cnt=0

function cooldown()
  if defer_cnt >= 10 then -- run mainloop() every ~900ms
    defer_cnt=0
    reaper.PreventUIRefresh(1)
    mainloop()
    reaper.PreventUIRefresh(-1)
  else
    defer_cnt=defer_cnt+1
  end
  reaper.defer(cooldown)
end



-- [[ 
-- for debugging
function msg(m)
  return reaper.ShowConsoleMsg(tostring(m) .. "\n")
end
-- ]]


-- GUI template by spk77, thanks --
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
  
  gfx.init("Grid", 0, 30, gui.settings.docker_id)
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
  
  gfx.x = 5
  gfx.y = 8
  
  
  
 -------------------
  --- grid stuff ---
  ------------------
  
  -- integer retval, optional number divisionIn, optional number swingmodeIn, optional number swingamtIn = 
  -- reaper.GetSetProjectGrid(ReaProject project, boolean set)
  
  -- Get or set the arrange view grid division. 0.25=quarter note, 1.0/3.0=half note triplet, etc. 
  -- swingmode can be 1 for swing enabled, swingamt is -1..1. Returns grid configuration flags
  
  notRelevant, divisionIn, swingmodeIn, swingamtIn = reaper.GetSetProjectGrid(0, false)
  trpDot = ""
  
  -- transform divisionIn to 1/1, 1/4 etc.
  denNorm = -1 
  
  -- straight grid
  den = 1
  for x=1, 8, 1 do
    -- msg(den)
    recDen = 1/den
    if (recDen == divisionIn) then -- straight grid
      denNorm = den 
      trpDot = ""
      break
    elseif (recDen * (2/3) == divisionIn) then -- triplet grid
      denNorm = den 
      trpDot = "T" 
      break
    elseif (recDen * 1.5 == divisionIn) then -- dotted grid
      denNorm = den 
      trpDot = "D" 
      break              
    end
    -- msg(1/den)
    -- msg(divisionIn)
    den = den*2
  end
  
  -- swing grid
  swingEnabled = ""
  swingAmnt = ""
  
  if (swingmodeIn == 1) then 
    swingEnabled = "S"
    swingAmnt = tostring(math.floor((swingamtIn*100) + 0.5)).."%%"
  end
    
  gfx.printf("1".."/"..denNorm.." "..trpDot.." "..swingEnabled.." "..swingAmnt)
  gfx.update()
  -- if gfx.getchar() >= 0 then reaper.defer(mainloop) end
end

init() 

cooldown()



