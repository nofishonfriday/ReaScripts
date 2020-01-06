--[[
 * Version: 1.00
 * ReaScript Name: Normalize take pan (Loudness based)
 * Author: nofish
 * Provides: [main] nofish_Normalize take pan (Loudness based) - Set threshold.lua
 * About:
 *  Request: https://forum.cockos.com/showthread.php?t=178277  
 *  Thread: https://forum.cockos.com/showthread.php?t=229544 (thanks ashcat_lt!)  
 *  works via adjusting take pan (stereo takes only)  
 *  in the accompanying script "Normalize take pan (Loudness based) - Set threshold.lua" can be set a a difference threshold (Loudness difference between l/r) over which the script starts processing
--]]

--[[
 * Changelog:
  
 * v1.00 - January 01 2020
  + initial release
--]]

-- USER CONFIG AREA -----------------------------------------------------------

SHOW_INFO = true -- true/false: display info / progress in cosole

------------------------------------------------------- END OF USER CONFIG AREA

-- Check whether the required version of REAPER / SWS is available
if not reaper.NF_AnalyzeTakeLoudness then
  reaper.ShowMessageBox("This script requires REAPER v5.21 / SWS v2.9.6 or above.", "ERROR", 0)
  return false 
end

-- check if user has set threshold
if not reaper.HasExtState("nofish", "normalizeTakePanLoudnessBased_threshold") then
  reaper.ShowMessageBox("Threshold not set. Please run script 'Normalize take pan (Loudness based) - Set threshold.lua'", "ERROR", 0)
  return false
else
  DIFFERENCE_THRESHOLD = tonumber(reaper.GetExtState("nofish", "normalizeTakePanLoudnessBased_threshold"))
end

local function Msg(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end

function DB2VAL(x)
  return math.exp(x*0.11512925464970228420089957273422)
end

function Round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

--------------
--- Main() ---
--------------
function Main()
  reaper.PreventUIRefresh(1)
  local selItemsCount = reaper.CountSelectedMediaItems(0)
  for i = 0, selItemsCount-1  do
    local item =  reaper.GetSelectedMediaItem(0, i)
    local take = reaper.GetActiveTake(item)
    
    if take ~= nil then
      local source = reaper.GetMediaItemTake_Source(take)
      local numChan = reaper.GetMediaSourceNumChannels( source )
      
      if (SHOW_INFO) then
         Msg("Processing item " .. i+1 .. " of " .. selItemsCount .. "...")
         Msg((reaper.GetTakeName(take)))
      end
      
      if numChan == 2 then
        origChanMode = reaper.GetMediaItemTakeInfo_Value(take, "I_CHANMODE")
        
        reaper.SetMediaItemTakeInfo_Value( take, "I_CHANMODE", 3) -- left chan
        retVal, LUintegrLeft = reaper.NF_AnalyzeTakeLoudness_IntegratedOnly(take) 
        reaper.SetMediaItemTakeInfo_Value( take, "I_CHANMODE", 4) -- right chan
        retVal, LUintegrRight = reaper.NF_AnalyzeTakeLoudness_IntegratedOnly(take) 
        
        reaper.SetMediaItemTakeInfo_Value( take, "I_CHANMODE", origChanMode) -- set chan mode back to original
        
        difference = LUintegrLeft - LUintegrRight
        differenceAbs = math.abs(difference)
        -- not totally sure what I'm doing here :/
        val = DB2VAL(difference)
        if (val > 1) then 
          val = 1 - 1 / val 
        else 
          val = -val
        end
        if (val < 0) then
          val = -1 - val 
        end
        
        if (SHOW_INFO) then
          Msg("Loudness left channel: " ..  LUintegrLeft .. " LUFSi")
          Msg("Loudness right channel: " ..  LUintegrRight .. " LUFSi")
          Msg("difference: " .. differenceAbs)
        end
        
        if val <= 1.0 and val >= -1.0 and differenceAbs > DIFFERENCE_THRESHOLD then
          if (SHOW_INFO) then
            if val < 0 then
              Msg("Adjusting take pan: " .. Round(val*100) .. "%" .."L\n")
            else
              Msg("Adjusting take pan: " .. Round(val*100) .. "%" .. "R\n")
            end
          end
          reaper.SetMediaItemTakeInfo_Value(take, "D_PAN", val) 
        else
          Msg("nothing processed.\n") 
        end 
      else -- if numChan == 2 then
        Msg("Not a stereo take, skipping..\n")
      end
    end -- if take ~= nil then
  end --  for i = 0, selItemsCount-1  do
  -- Msg("")
  reaper.PreventUIRefresh(-1)
  reaper.Undo_OnStateChange("Script: Normalize take pan (Loudness based)")
end -- main()

Main()
reaper.defer(function() end) -- don't create unnecessary undo point

