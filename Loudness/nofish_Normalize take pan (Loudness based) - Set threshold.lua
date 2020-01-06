-- @noindex

function promptUser()
  if reaper.HasExtState("nofish", "normalizeTakePanLoudnessBased_threshold") then
    caption = reaper.GetExtState("nofish", "normalizeTakePanLoudnessBased_threshold")
  else
    caption = "1.5"
  end
    
  retval, targetString = reaper.GetUserInputs("Normalize take pan (Loudness based) - Query", 1, "Difference threshold:", caption)
  
  if retval then 
    if tonumber(targetString) then
      reaper.SetExtState("nofish", "normalizeTakePanLoudnessBased_threshold", targetString, true)
      -- gets stored in "reaper-extstate.ini"
    else -- not a number
      promptUser()
    end
  else -- pressed 'Cancel'
    reaper.SetExtState("nofish", "normalizeTakePanLoudnessBased_threshold", caption, true)
  end
end

promptUser()
reaper.defer(function() end)