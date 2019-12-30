--[[
 * Version: 1.00
 * ReaScript Name: Analyze loudness (integrated) per channel of selected items active take
 * Author: nofish
 * About:  
 *  Requires REAPER v5.21 / SWS v2.9.6 or above  
--]]

--[[
 Changelog:
 * v1.0 - December 30 2019
    + initial release
--]]

-- USER CONFIG AREA -----------------------------------------------------------

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
  reaper.PreventUIRefresh(1)
  local selItemsCount = reaper.CountSelectedMediaItems(0)
  
  for i = 0, selItemsCount-1  do
    local item =  reaper.GetSelectedMediaItem(0, i)
    local take = reaper.GetActiveTake(item)
    
    if take ~= nil and not reaper.TakeIsMIDI(take) then
      Msg("Processing item " .. i+1 .. " of " ..  selItemsCount .. "...")
      Msg((reaper.GetTakeName(take)))

      local source = reaper.GetMediaItemTake_Source(take)
      local numChan = reaper.GetMediaSourceNumChannels( source )
      local origChanMode = reaper.GetMediaItemTakeInfo_Value(take, "I_CHANMODE") 
      local loudnessLeft, loudnessRight

      for j = 0, numChan-1 do
        reaper.SetMediaItemTakeInfo_Value( take, "I_CHANMODE", j+3) -- 3=left, 4=right etc.
        retVal, LUintegr = reaper.NF_AnalyzeTakeLoudness_IntegratedOnly(take)
        Msg("Channel " .. j+1 .. ": " .. LUintegr .. " LUFSi")
        if j == 0 then
          LUintegrLeft = LUintegr
        elseif j == 1 then
          Msg("difference: " .. math.abs(LUintegr - LUintegrLeft))
        end
      end 
      reaper.SetMediaItemTakeInfo_Value( take, "I_CHANMODE", origChanMode)
      Msg("")
    end -- if take ~= nil then
  end --  for i = 0, selItemsCount-1  do
  
  reaper.PreventUIRefresh(-1)
end -- main()

Main()
