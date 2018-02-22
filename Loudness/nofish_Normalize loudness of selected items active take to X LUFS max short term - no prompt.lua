--[[
 * ReaScript Name: Normalize loudness of selected items active take to X LUFS max short term - no prompt
 * Version: 1.05
 * Author: nofish
 * About:
 *  Normalizes active take of selected audio items to a user defineable LUFS max short term value (sets Item take volume).   
 *  This version of the script doesn't give a user prompt to set the target value (for use in custom actions),  
 *  but instead uses the target value set in the related script "nofish_Set normalize loudness to X LUFS max short term target vaulue.lua"  
 *  Note: 'Short term loudness' uses a time window of 3 sec. for analysis, so items shorter than this can't be analyzed / normalized correctly.    
 *  In the script's USER CONFIG AREA can be set if info / progress should be displayed in the console.  
 *    
 *  Requires REAPER v5.21 / SWS v2.9.6 or above  
--]]


--[[
 * Changelog:
  
 * v1.0 - September 7 2017
    + initial release

 * v1.01 - September 7 2017
    # added required REAPER / SWS version check
    
 * v1.02 - September 8 2017
    # better console output
    
 * v1.03 - September 8 2017
    # fixed nil value
    
 * v1.04 - September 14 2017
    # warn when item is too short for analysis, avoid applying crazy gain in this case
    
 * v1.05 - October 1 2017
    # change VAL/DB conversion functions
    # make more variables local
--]]


-- USER CONFIG AREA -----------------------------------------------------------

showInfo = false -- true/false: display info / progress in cosole

------------------------------------------------------- END OF USER CONFIG AREA


-- Start off with a little 'trick' to prevent REAPER from automatically
--    creating an undo point if no changes are made. (thanks JS)
function preventUndo()
end
reaper.defer(preventUndo)


-- Check whether the required version of REAPER / SWS is available
if not reaper.NF_AnalyzeTakeLoudness then
  reaper.ShowMessageBox("This script requires REAPER v5.21 / SWS v2.9.6 or above.", "ERROR", 0)
  return(false) 
end


reaper.ClearConsole()

function msg(m)
  return reaper.ShowConsoleMsg(tostring(m) .. "\n")
end

--[[
-- from Justin
function DB2VAL(x)
  return math.exp(x*0.11512925464970228420089957273422)
end

function VAL2DB(x)
  if x < 0.0000000298023223876953125 then 
    x = -150
  else
    x = math.max(-150, math.log(x)* 8.6858896380650365530225783783321)
  end
  return x
end
--]]

--https://github.com/ReaTeam/ReaScripts-Templates/blob/master/Values/X-Raym_Val%20to%20dB%20-%20dB%20to%20Val.lua
-- thanks X-Raym
function VAL2DB(val) return 20*math.log(val, 10) end
function DB2VAL(dB_val) return 10^(dB_val/20) end



-- only used for console display
function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end


LUFSshortTermMaxTarget = -23
analyzedAtLeastOneItem = false


if reaper.HasExtState("NF_normalizeToMaxShrtTermLUFS_noPrompt", "shortTermTargetLUFS_noPrompt") then
  shortTermTargetLUFS_noPrompt = reaper.GetExtState("NF_normalizeToMaxShrtTermLUFS_noPrompt", "shortTermTargetLUFS_noPrompt")
  if tonumber(shortTermTargetLUFS_noPrompt) then
    LUFSshortTermMaxTarget = tonumber(shortTermTargetLUFS_noPrompt)
  end 
end


function main()

  selected_items_count = reaper.CountSelectedMediaItems(0)
  
  for i = 0, selected_items_count-1  do

    local item = reaper.GetSelectedMediaItem(0, i)
   
    local take = reaper.GetActiveTake(item)
    if take ~= nil and not reaper.TakeIsMIDI(take) then -- at least one audio item is selected
    
      
      -- do the actual analyzing and normalizing
      reaper.PreventUIRefresh(1)
      reaper.Undo_BeginBlock()
        
      -- take into account if take vol. is other than 0 db 
      origTakeVol = VAL2DB(reaper.GetMediaItemTakeInfo_Value(take, "D_VOL"))
      
      if (showInfo) then
        msg("Processing item " .. i+1 .. " of " .. selected_items_count .. "...")
      end
      
      -- only shortTermMax is used here
      -- success, lufsIntegrated, range, truePeak, truePeakPos, shortTermMax, momentaryMax = reaper.NF_AnalyzeTakeLoudness(take, false)
      local _ local shortTermMax
      _, _, _, _, _, shortTermMax, _ = reaper.NF_AnalyzeTakeLoudness(take, false)
      -- msg("short term max: " .. shortTermMax)
      
      if (showInfo) then
        msg(reaper.GetTakeName(take) .. ":" .. "\n" .. "short term max: " .. round(shortTermMax, 2))
      end
      
      -- check if item is (not) too short for analysis
      if (shortTermMax > -100.0) then
        deltaVol = LUFSshortTermMaxTarget - shortTermMax + origTakeVol
        
        if (showInfo) then
          msg("adjustment: " .. round((LUFSshortTermMaxTarget - shortTermMax), 2))
          msg("") -- empty line
        end
      
        reaper.SetMediaItemTakeInfo_Value(take, "D_VOL", (DB2VAL(deltaVol)))
      
        analyzedAtLeastOneItem = true 
      
      else -- short term max is < -100.0
        if (showInfo) then
          msg("Can't normalize. Item probably too short.")
          msg("") -- empty line
        end
      end
      
    else -- if take ~= nil and not reaper.TakeIsMIDI(take)...
      if (showInfo) then
        msg("Processing item " .. i+1 .. " of " .. selected_items_count .. "...")
        msg("skipped (not an audio item)")
        msg("")
      end
    end -- ENDIF active take
  end -- ENDLOOP through selected items
  
  if (showInfo and analyzedAtLeastOneItem) then
    msg("Done normalizing to " .. LUFSshortTermMaxTarget .. "LUFS max short term")
  end
  
  reaper.Undo_EndBlock("Script: Normalize loudness of sel. items act. take to X LUFS max short term", -1)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end


main()
  
 





