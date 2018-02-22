--[[
 * ReaScript Name: Set normalize loudness to X LUFS max momentary target value
 * Version: 1.0
 * Author: nofish
 * About:
 *  This script works together with "nofish_Normalize loudness of selected items active take to X LUFS max momentary - no prompt.lua"  
 *  Set the LUFS max momentary target value here than use above script to normalize to this target value.   
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
  if reaper.HasExtState("NF_normalizeToMaxMomentaryLUFS_noPrompt", "momentaryTargetLUFS_noPrompt") then
    caption = reaper.GetExtState("NF_normalizeToMaxMomentaryLUFS_noPrompt", "momentaryTargetLUFS_noPrompt")
  else
    caption = "-23"
  end
    
  retval, target_string = reaper.GetUserInputs("Normalize to momentary max. LUFS", 1, "Target level:", caption)
  
  if retval then 
    if tonumber(target_string) then
      reaper.SetExtState("NF_normalizeToMaxMomentaryLUFS_noPrompt", "momentaryTargetLUFS_noPrompt", target_string, true)
      -- gets stored in "reaper-extstate.ini"
    else -- not a number
      promptUser()
    end
  else -- pressed 'Cancel'
    reaper.SetExtState("NF_normalizeToMaxMomentaryLUFS_noPrompt", "momentaryTargetLUFS_noPrompt", caption, true)
  end
end

promptUser()
