--[[
 * Version: 1.00
 * ReaScript Name: Set all items to timebase Time if at least containing one audio or video take, else to timebase Beats (pos., length, rate)
 * Author: nofish
 * About:  
 *  Request: https://forum.cockos.com/showthread.php?t=229817 
--]]

--[[
 Changelog:
 * v1.0 - January 06 2020
    + initial release
--]]

function Msg(m)
  reaper.ShowConsoleMsg(tostring(m) .. "\n")
end

function Main()
  local itemsCount = reaper.CountMediaItems(0)
  if itemsCount == 0 then return end
    -- loop through items
  for i = 0, itemsCount-1 do
    local item = reaper.GetMediaItem(0, i)
    -- loop through takes of current item
    local containsAudioTake
    for t = 0, reaper.CountTakes(item)-1 do
      local take = reaper.GetTake(item, t)
      -- check if audio/video take
      local source = reaper.GetMediaItemTake_Source(take)
      if source ~= nil and  reaper.GetMediaSourceSampleRate(source) > 0 then
        containsAudioTake = true
      break
      end
    end
              
    if containsAudioTake == true then
    reaper.SetMediaItemInfo_Value(item, "C_BEATATTACHMODE", 0 ) -- set to 'Time'
    else
    reaper.SetMediaItemInfo_Value(item, "C_BEATATTACHMODE", 1 ) -- set to 'Beats (pos length rate)'
    end
  end
  reaper.Undo_OnStateChange("Script: Set all items to timebase Time if at least containing one audio/video take, else to timebase Beats (pos., length, rate)")
end

Main()
reaper.defer(function() end) -- avoid creating redundant undo point

