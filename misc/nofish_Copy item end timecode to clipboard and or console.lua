--[[
 * ReaScript Name: Copy item end timecode to clipboard and or console.lua
 * Version: 1.01
 * Author: nofish
 * Donation: https://paypal.me/nofish
 * About: Copies first sel. item's end timecode to cliboard and / or shows it in console (see script's USER CONFIG AREA)
--[[
 * Changelog:
  
 * v1.0 - June 25 2019
    + initial release
 * v1.01 - June 25 2019
    # tweak string formatting
--]]


-- USER CONFIG AREA -----------------------------------------------------------

showInConsole   = true -- true/false: display item end timecode in console
copyToClipboard = false -- true/false: auto copy item end timecode to clipboard (needs SWS)

------------------------------------------------------- END OF USER CONFIG AREA


function msg(m)
  return reaper.ShowConsoleMsg(tostring(m) .. "\n")
end

function SecondsToTimecode(seconds)
  local tc = ""
  local isNegative = false
  if seconds < 0 then
    seconds = math.abs(seconds)
    isNegative = true
  end
  fullsecs, secsfrac  = math.modf(seconds)
  -- https://gist.github.com/jesseadams/791673
  hours     = string.format("%01.f", math.floor(fullsecs/3600))
  mins      = string.format("%01.f", math.floor(fullsecs/60 - (hours*60)))
  secs      = string.format("%02.f", math.floor(fullsecs - hours*3600 - mins*60))
  millisecs = string.sub(secsfrac, 2, 5)
  -- add trailing zero(s) for milliseconds
  msLength = string.len(millisecs)
  if msLength == 2 then
    millisecs = millisecs .. "00"
  elseif msLength == 3 then
    millisecs = millisecs .. "0"
  end
  
  if isNegative == true then
    tc = tc .. "-"
  end
  if tonumber(hours) > 0 then
    tc = tc .. hours .. ":".. mins .. ":" .. secs .. "." .. millisecs
  else
    tc = tc .. mins .. ":" .. secs .. "." .. millisecs
  end
  if showInConsole == true then
    msg(tc)
  end
  return tc
end

function Main()
  item =  reaper.GetSelectedMediaItem(0, 0)
  if item ~= nil then
    pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    endpos = pos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH") + reaper.GetProjectTimeOffset(0, 0)
    endposTimecode = SecondsToTimecode(endpos)
    if copyToClipboard == true then
      reaper.CF_SetClipboard(endposTimecode)
    end 
  end
end

reaper.defer(Main)
