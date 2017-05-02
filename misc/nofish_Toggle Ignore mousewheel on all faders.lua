--[[
 * ReaScript Name: nofish_Toggle "Ignore mousewheel on all faders".lua
 * Version: 1.0
 * Author: nofish
 * About:
 *  Toggles Preference "Ignore mousewheel on all faders"
 *  can be assigned to toolbar button
--]]

--[[
 Changelog:
 * v1.0
    + Initial release
--]]

function msg(m)
  reaper.ShowConsoleMsg(tostring(m) .. "\n")
end


ret = reaper.SNM_GetIntConfigVar("mousewheelmode", -666)
-- msg(ret)

if (ret ~= -666) then
  if (ret == 0) then -- mw not ignored
    reaper.SNM_SetIntConfigVar("mousewheelmode", 2) -- ignore mw
    toggleState = 1
  else
    reaper.SNM_SetIntConfigVar("mousewheelmode", 0) -- don't ignore mw
    toggleState = 0
  end
end

is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()
reaper.SetToggleCommandState(sec, cmd, toggleState);  
reaper.RefreshToolbar2(sec, cmd);  
