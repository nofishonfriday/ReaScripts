--[[
 * ReaScript Name: Set normalize loudness to X LUFS max short term target value
 * Version: 1.0
 * Author: nofish
 * About:
 *  This script works together with "nofish_Normalize loudness of selected items active take to X LUFS max short term - no prompt.lua"  
 *  Set the LUFS max short term target value here than use above script to normalize to this target value.   
 *  The target value is persistent across REAPER projects.  
--]]


--[[
 * Changelog:
  
 * v1.0 - September 8 2017
    + initial release
--]]

function preventUndo()
end
reaper.defer(preventUndo)

function promptUser()
  if reaper.HasExtState("NF_normalizeToMaxShrtTermLUFS_noPrompt", "shortTermTargetLUFS_noPrompt") then
    caption = reaper.GetExtState("NF_normalizeToMaxShrtTermLUFS_noPrompt", "shortTermTargetLUFS_noPrompt")
  else
    caption = "-23"
  end
    
  retval, target_string = reaper.GetUserInputs("Normalize to short term max. LUFS", 1, "Target level:", caption)
  
  if retval then 
    if tonumber(target_string) then
      reaper.SetExtState("NF_normalizeToMaxShrtTermLUFS_noPrompt", "shortTermTargetLUFS_noPrompt", target_string, true)
      -- gets stored in "reaper-extstate.ini"
    else -- not a number
      promptUser()
    end
  else -- pressed 'Cancel'
    reaper.SetExtState("NF_normalizeToMaxShrtTermLUFS_noPrompt", "shortTermTargetLUFS_noPrompt", caption, true)
  end
end

promptUser()
