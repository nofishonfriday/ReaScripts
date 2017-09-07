--[[
 * ReaScript Name: nofish_Normalize loudness of selected items active take to X LUFS max short term
 * Version: 1.0
 * Author: nofish
 * About:
 *  Normalizes active take of selected audio items to a user defineable LUFS max short term value (sets Item take volume).   
 *  Note: 'Short term loudness' uses a time window of 3 sec. for analysis, so items shorter than this can't be analyzed / normalized correctly.  
 *  In the script's USER CONFIG AREA can be set if info / progress should be displayed in the console.  
 *    
 *  Requires REAPER v5.21 / SWS v2.9.6 or above  
--]]


--[[
 * Changelog:
  
 * v1.0 - September 7 2017
   + initial version
--]]


-- USER CONFIG AREA -----------------------------------------------------------

showInfo = true -- true/false: display info / progress in cosole

------------------------------------------------------- END OF USER CONFIG AREA

--[[
-- Start off with a little 'trick' to prevent REAPER from automatically
--    creating an undo point if no changes are made. (thanks JS)
function preventUndo()
end
reaper.defer(preventUndo)
--]]


reaper.ClearConsole()

function msg(m)
  return reaper.ShowConsoleMsg(tostring(m) .. "\n")
end

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


function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end


gotUserInput = false
userPressedCancel = false
analyzedAtLeastOneItem = false


function promptUser()
  if reaper.HasExtState("NF_normalizeToMaxShrtTermLUFS", "shortTermTargetLUFS") then
    caption = reaper.GetExtState("NF_normalizeToMaxShrtTermLUFS", "shortTermTargetLUFS")
  else
    caption = "-23"
  end
    
  retval, target_string = reaper.GetUserInputs("Normalize to short term max. LUFS", 1, "Target level:", caption)
  
  if retval then 
    if tonumber(target_string) then
      LUFSshortTermMaxTarget = tonumber(target_string)
      reaper.SetExtState("NF_normalizeToMaxShrtTermLUFS", "shortTermTargetLUFS", target_string, true)
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
      
      -- only shortTermMax is used here
      success, lufsIntegrated, range, truePeak, truePeakPos, shortTermMax, momentaryMax = reaper.NF_AnalyzeTakeLoudness(take, false)
      -- msg("short term max: " .. shortTermMax)
      
      if (showInfo) then
        msg(reaper.GetTakeName(take) .. ":" .. "\n" .. "short term max: " .. round(shortTermMax, 2))
      end
      
      deltaVol = LUFSshortTermMaxTarget - shortTermMax + origTakeVol
      
      if (showInfo) then
        msg("adjustment: " .. round((LUFSshortTermMaxTarget - shortTermMax), 2))
        msg("") -- empty line
      end
      
      reaper.SetMediaItemTakeInfo_Value(take, "D_VOL", (DB2VAL(deltaVol)))
      
    else -- if take ~= nil and not reaper.TakeIsMIDI(take)...
      if (showInfo) then
        msg("Processing item " .. i+1 .. " of " .. selected_items_count .. "...")
        msg("skipped (not an audio item)")
        msg("")
      end
     
    analyzedAtLeastOneItem = true 
    end -- ENDIF active take
  end -- ENDLOOP through selected items
  
  if (showInfo and analyzedAtLeastOneItem) then
    msg("Done.")
  end
  
  reaper.Undo_EndBlock("Script: Normalize loudness of sel. items act. take to X LUFS max short term", -1)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end


main()




