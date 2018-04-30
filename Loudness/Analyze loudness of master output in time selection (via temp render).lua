--[[
 * Version: 1.0
 * ReaScript Name: Analyze loudness of master output in time selection (via temp render)
 * Author: nofish
 * About:
 *  Renders a file, analyzes and displays loudness values and deletes the file
 *  Note: In the 'Render' dialog:
 *  'Source: Master mix', 'Bounds: Time selection', 'Add rendered items to new tracks in project' must be set 
--]]

--[[
 Changelog:
 * v1.0 April 30 2018
    + Initial release
--]]

-- USER CONFIG AREA -----------------------------------------------------------

analyzeTruePeak = true -- true/false: analyze true peak (slower) or not

------------------------------------------------------- END OF USER CONFIG AREA

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

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function main()

  reaper.Undo_BeginBlock()
  tracksCountBeforeRender = reaper.CountTracks(0)
  reaper.Main_OnCommand(41824, 0) -- File: Render project, using the most recent render settings
  tracksCountAfterRender = reaper.CountTracks(0)
  
  if tracksCountAfterRender ~= tracksCountBeforeRender+1 then 
    msg("Seems like something went wrong.\nIs 'Add rendered items to new tracks in project' in 'Render'dialog ?")
    return
  end
  
  lastTrack = reaper.GetTrack(0, tracksCountAfterRender-1)
  reaper.SetMediaTrackInfo_Value(lastTrack, "D_VOL", 1) -- set to 0 dB in case tracks get inserted with other default vol.
  
  
  renderedItem = reaper.GetTrackMediaItem(lastTrack, 0)
  renderedItemActTake =  reaper.GetActiveTake(renderedItem)
  
  if renderedItemActTake == nil then return end
  
  -- takeName =  reaper.GetTakeName(renderedItemActTake)  
  -- msg("Analyzing " .. takeName .. "...")
  
  success, lufsIntegrated, range, truePeak, truePeakPos, shortTermMax, momentaryMax = 
    reaper.NF_AnalyzeTakeLoudness(renderedItemActTake, analyzeTruePeak)
    
  msg("integrated: " .. round(lufsIntegrated, 2))
  msg("range: " .. round(range, 2))
  msg("short term max: " .. round(shortTermMax, 2))
  msg("momentary max: " .. round(momentaryMax, 2))
  if analyzeTruePeak == true then
    msg("true peak: " .. round(truePeak, 2))
  end
  
  -- delete temp track + temp file on HD
  pcmSource = reaper.GetMediaItemTake_Source(renderedItemActTake)
  mediaItem =  reaper.GetMediaItemTake_Item(renderedItemActTake)
  fileName = reaper.GetMediaSourceFileName(pcmSource, '')
  mediaTrack = reaper.GetMediaItem_Track(mediaItem)
  reaper.DeleteTrack(mediaTrack)
  os.remove(fileName)
  reaper.UpdateArrange()
  
  reaper.Undo_EndBlock("Script: Analyze loudness of master output in time sel.", -1)
end

main()
