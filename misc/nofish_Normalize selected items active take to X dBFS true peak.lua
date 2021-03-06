--[[
 * ReaScript Name: Normalize selected items active take to X dBFS true peak
 * Version: 1.05
 * Author: nofish
 * About:
 *  Normalizes active take of selected audio items to a user defineable dBFS value (sets Item take volume).   
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
    
 * v1.03 - September 14 2017
    # warn when item is too short for analysis, avoid applying crazy gain in this case
    
 * v1.05 - October 1 2017
    # change VAL/DB conversion functions
    # make more variables local
--]]


-- USER CONFIG AREA -----------------------------------------------------------

showInfo = true -- true/false: display info / progress in cosole

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


gotUserInput = false
userPressedCancel = false
analyzedAtLeastOneItem = false


function promptUser()
  if reaper.HasExtState("NF_normalizeToDBFStruePeak", "truePeakTargetDB") then
    caption = reaper.GetExtState("NF_normalizeToDBFStruePeak", "truePeakTargetDB")
  else
    caption = "-1.0"
  end
    
  retval, target_string = reaper.GetUserInputs("Normalize to dBFS TP", 1, "Target level:", caption)
  
  if retval then 
    if tonumber(target_string) then
      LUFStruePeakTarget = tonumber(target_string)
      reaper.SetExtState("NF_normalizeToDBFStruePeak", "truePeakTargetDB", target_string, true)
      -- gets stored in "reaper-extstate.ini"
      gotUserInput = true
    else -- not a number
      promptUser()
    end
  else -- pressed 'Cancel'
    userPressedCancel = true
  end
end


function main()

  selected_items_count = reaper.CountSelectedMediaItems(0)
  
  for i = 0, selected_items_count-1  do

    local item = reaper.GetSelectedMediaItem(0, i)
   
    local take = reaper.GetActiveTake(item)
    if take ~= nil and not reaper.TakeIsMIDI(take) then -- at least one audio item is selected
    
      if gotUserInput == false then
        promptUser()
        if userPressedCancel == true then
          break
        end
      end
      
      -- do the actual analyzing and normalizing
      reaper.PreventUIRefresh(1)
      reaper.Undo_BeginBlock()
        
      -- take into account if take vol. is other than 0 db 
      origTakeVol = VAL2DB(reaper.GetMediaItemTakeInfo_Value(take, "D_VOL"))
      
      if (showInfo) then
        msg("Processing item " .. i+1 .. " of " .. selected_items_count .. "...")
      end
      
      -- only truePeak is used here
      -- success, lufsIntegrated, range, truePeak, truePeakPos, truePeak, momentaryMax = reaper.NF_AnalyzeTakeLoudness(take, false)
      local _ local truePeak
      _, _, _, truePeak, _, _, _ = reaper.NF_AnalyzeTakeLoudness(take, true)
      -- msg("dB FS TP: " .. truePeak)
      
      if (showInfo) then
        msg(reaper.GetTakeName(take) .. ":" .. "\n" .. "dB FS TP: " .. round(truePeak, 2))
      end
      
      -- check if item is (not) too short for analysis
      if (truePeak > -100.0) then
        deltaVol = LUFStruePeakTarget - truePeak + origTakeVol
        
        if (showInfo) then
          msg("adjustment: " .. round((LUFStruePeakTarget - truePeak), 2))
          msg("") -- empty line
        end
      
        reaper.SetMediaItemTakeInfo_Value(take, "D_VOL", (DB2VAL(deltaVol)))
      
        analyzedAtLeastOneItem = true 
      
      else -- dB FS TP is < -100.0
        if (showInfo) then
          msg("Can't normalize. Something went wrong.")
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
    msg("Done normalizing to " .. LUFStruePeakTarget .. "dB FS true peak")
  end
  
  reaper.Undo_EndBlock("Script: Normalize loudness of sel. items act. take to X LUFS max short term", -1)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end


main()




