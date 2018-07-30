--[[
 * ReaScript Name:
 * Version: 0.9
 * Author: nofish
 * About:
 *  
 *  
 *  In the script's USER CONFIG AREA can be set if info / progress should be displayed in the console.  
 *    
 *  Requires REAPER v5.21 / SWS v2.9.6 or above  
--]]


--[[
 * Changelog:
  
 * v0.9 - 
    + initial release
--]]

-- USER CONFIG AREA -----------------------------------------------------------

showInfo = true -- true/false: display info / progress in cosole

------------------------------------------------------- END OF USER CONFIG AREA


local function Msg(str)
   reaper.ShowConsoleMsg(tostring(str) .. "\n")
end

function DB2VAL(x)
  return math.exp(x*0.11512925464970228420089957273422)
end

-- Check whether the required version of REAPER / SWS is available
if not reaper.NF_AnalyzeTakeLoudness then
  reaper.ShowMessageBox("This script requires REAPER v5.21 / SWS v2.9.6 or above.", "ERROR", 0)
  return(false) 
end

function Round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

--- Main() ---

function Main()
  local selItemsCount = reaper.CountSelectedMediaItems(0)
  
  for i = 0, selItemsCount-1  do
    local item =  reaper.GetSelectedMediaItem(0, i)
    local take = reaper.GetActiveTake(item)
    
    if take ~= nil then
      local source = reaper.GetMediaItemTake_Source(take)
      local numChan = reaper.GetMediaSourceNumChannels( source )
      
      if numChan == 2 then
      
        if (showInfo) then
           Msg("Processing item " .. i+1 .. " of " ..  selItemsCount .. "...")
           Msg((reaper.GetTakeName(take)))
        end
         
        reaper.PreventUIRefresh(1)
        
        reaper.SetMediaItemTakeInfo_Value( take, "I_CHANMODE", 3) -- left chan
        retVal, LUintegrLeft = reaper.NF_AnalyzeTakeLoudness_IntegratedOnly(take) 
        
        reaper.SetMediaItemTakeInfo_Value( take, "I_CHANMODE", 4) -- right chan
        retVal, LUintegrRight = reaper.NF_AnalyzeTakeLoudness_IntegratedOnly(take) 
        
        reaper.SetMediaItemTakeInfo_Value( take, "I_CHANMODE", 0) -- set chan mode back to normal
        
        LoudnessRatio = LUintegrLeft / LUintegrRight 
       
        takePan = 0.0 -- -- -1:100% L, 0:center, +1:100% R
        if LoudnessRatio > 1 then
          takePan = -LoudnessRatio+1
        else 
          takePan = 1/LoudnessRatio-1
        end
       
        -- Msg(takePan)
        if takePan <= 1.0 and takePan >= -1.0 then
          
          
          if (showInfo) then
            Msg("Loudness left channel: " ..  LUintegrLeft)
            Msg("Loudness right channel: " ..  LUintegrRight)
            if takePan < 0 then
              Msg("Adjusting take pan: " .. Round(takePan*100) .. "%" .."L\n")
            elseif takePan > 0 then
              Msg("Adjusting take pan: " .. Round(takePan*100) .. "%" .. "R\n")
            end
          end
          
          reaper.Undo_BeginBlock()
          reaper.SetMediaItemTakeInfo_Value(take, "D_PAN", takePan) 
          reaper.Undo_EndBlock("My action", -1)
        else
          Msg("\ncouldn't be Pan normalized.\nToo much loudness difference between l and r channels") 
        end 
        
        reaper.PreventUIRefresh(-1)
      end -- if numChan == 2 then
    end -- if take ~= nil then
  end --  for i = 0, selItemsCount-1  do
end -- main()

Main()
