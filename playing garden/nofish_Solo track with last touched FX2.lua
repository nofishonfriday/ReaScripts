

-- based on spk77's GUI template, thanks
-- http://forum.cockos.com/showthread.php?t=161557 

-- cooldown function (CPU saver) by Jeffos, thanks
-- http://forum.cockos.com/showpost.php?p=1567657&postcount=39

defer_cnt=0

function cooldown()
  -- if defer_cnt >= 30 then -- run mainloop() every ~900ms
  if defer_cnt >= 5 then
    defer_cnt=0
    reaper.PreventUIRefresh(1)
    mainloop()
    reaper.PreventUIRefresh(-1)
  else
    defer_cnt=defer_cnt+1
  end
  -- reaper.defer(cooldown)
  gfxchar=gfx.getchar(); if gfxchar >= 0 then reaper.defer(cooldown); end
end



-- Empty GUI template


-- for debugging
function msg(m)
  return reaper.ShowConsoleMsg(tostring(m) .. "\n")
end




-----------------
-- Mouse table --
-----------------

local mouse = {  
                  -- Constants
                  LB = 1,
                  RB = 2,
                  CTRL = 4,
                  SHIFT = 8,
                  ALT = 16,
                  
                  -- "cap" function
                  cap = function (mask)
                          if mask == nil then
                            return gfx.mouse_cap end
                          return gfx.mouse_cap&mask == mask
                        end,
                  
                  -- Returns true if LMB down, else false
                  lb_down = function() return gfx.mouse_cap&1 == 1 end,
                  
                  -- Returns true if RMB down, else false
                  rb_down = function() return gfx.mouse_cap&2 == 2 end,
       
                  uptime = 0,
                  
                  last_x = -1, last_y = -1,
                  
                  -- Updated when LMB/RMB down and mouse is moving.
                  -- Both values are set to 0 when LMB/RMB is released
                  dx = 0, 
                  dy = 0,
                  
                  ox = 0, oy = 0,    -- left/right click coordinates
                  cap_count = 0,
                  
                  last_LMB_state = false,
                  last_RMB_state = false
               }
               
----------------------------------
-- Mouse event handling         --
-- (from Schwa's GUI example)   --
----------------------------------

function OnMouseDown(x, y, lmb_down, rmb_down)
  -- LMB clicked
  if not rmb_down and lmb_down and mouse.last_LMB_state == false then
    mouse.last_LMB_state = true
  end
  -- RMB clicked
  if not lmb_down and rmb_down and mouse.last_RMB_state == false then
    mouse.last_RMB_state = true
  end
  mouse.ox, mouse.oy = x, y -- mouse click coordinates
  mouse.cap_count = 0       -- reset mouse capture count
end


function OnMouseUp(x, y, lmb_down, rmb_down)
  -- handle "mouse button up" here
  mouse.uptime = os.clock()
  mouse.dx = 0
  mouse.dy = 0
  -- left mouse button was released
  if not lmb_down and mouse.last_LMB_state then mouse.last_LMB_state = false end
  -- right mouse button was released
  if not rmb_down and mouse.last_RMB_state then mouse.last_RMB_state = false end
end


function OnMouseDoubleClick(x, y)
  -- handle mouse double click here
end


function OnMouseMove(x, y)
  -- handle mouse move here, use mouse.down and mouse.capcnt
  mouse.last_x, mouse.last_y = x, y
  mouse.dx = gfx.mouse_x - mouse.ox
  mouse.dy = gfx.mouse_y - mouse.oy
  mouse.cap_count = mouse.cap_count + 1
end


----------
-- Init --
----------
          
---------------------------------------------------------------------------

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
  
  gfx.init("Solo switcher", 150, 30, gui.settings.docker_id)
  gfx.setfont(1,"Arial", gui.settings.font_size)
  gfx.clear = 3355443  -- matches with "FUSION: Pro&Clean Theme :: BETA 01" http://forum.cockos.com/showthread.php?t=155329
  -- (Double click in ReaScript IDE to open the link)
  gfx.set(1, 1, 1, 1) -- set color white

  -- mainloop()  
  
  solo_engaged = false
end


--------------
-- Mainloop --
--------------

function mainloop()
  --------------
  -- Draw GUI --
  --------------
  
  local LB_DOWN = mouse.lb_down()           -- current left mouse button state is stored to "LB_DOWN"
    local RB_DOWN = mouse.rb_down()           -- current right mouse button state is stored to "RB_DOWN"
    local mx, my = gfx.mouse_x, gfx.mouse_y   -- current mouse coordinates are stored to "mx" and "my"
    
    -- (modded Schwa's GUI example)
    if (LB_DOWN and not RB_DOWN) or (RB_DOWN and not LB_DOWN) then   -- LMB or RMB pressed down?
      if (mouse.last_LMB_state == false and not RB_DOWN) or (mouse.last_RMB_state == false and not LB_DOWN) then
        OnMouseDown(mx, my, LB_DOWN, RB_DOWN)
        if mouse.uptime and os.clock() - mouse.uptime < 0.20 then
          OnMouseDoubleClick(mx, my)
        end
      elseif mx ~= mouse.last_x or my ~= mouse.last_y then
        OnMouseMove(mx, my)
      end
        
    elseif not LB_DOWN and mouse.last_RMB_state or not RB_DOWN and mouse.last_LMB_state then
      OnMouseUp(mx, my, LB_DOWN, RB_DOWN)
    end
  
  gfx.x = 10
  gfx.y = 10
  
  -- retval, tracknum, fxnum = reaper.GetLastTouchedFX() 
  retval, tracknum, fxnum = reaper.GetFocusedFX() 
 
  track = reaper.GetTrack(0, tracknum-1)
  if (track) then
    trackname = reaper.GetTrackState(track)
    solo_state = reaper.GetMediaTrackInfo_Value(track, "I_SOLO")
  end
  if (solo_state and solo_state > 0) then
    gfx.set(1, 0.5, 0.5, 1) -- set color red
    solo_engaged = true
  else
    gfx.set(1, 1, 1, 1)
    solo_engaged = false
  end
  
  if (not trackname) then
    gfx.printf("[no current track]")
  elseif  
  (trackname == "") then
    gfx.printf(tracknum) else
    gfx.printf(trackname)
  end
  
  
  if (track and gfx.mouse_cap == 1 and solo_engaged == false) then 
    -- reaper.Main_OnCommand(40340, 0) -- unsolo all tacks
    reaper.SetMediaTrackInfo_Value(track, "I_SOLO", 1) 
    gfx.printf("")
    gfx.set(1, 0.5, 0.5, 1) 
    solo_engaged = true
  elseif (track and gfx.mouse_cap == 1 and solo_engaged == true) then 
     -- reaper.Main_OnCommand(40340, 0)
     reaper.SetMediaTrackInfo_Value(track, "I_SOLO", 0) 
     gfx.printf("")
     gfx.set(1, 1, 1, 1) 
     solo_engaged = false
  end
  gfx.update() 
  -- if gfx.getchar() >= 0 then reaper.defer(mainloop) end
end

init() 
cooldown()

