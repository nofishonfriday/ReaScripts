--[[
 * Version: 1.02
 * ReaScript Name: Analyze loudness of master output in time selection (via temp render)
 * Author: nofish
 * About:
 *  Renders a file, analyzes and displays loudness values and deletes the file  
 *  In the scripts USER CONFIG AREA can be set if True Peak should be analyzed (slower) or not  
 *  Requires REAPER v5.974, SWS v2.9.6
--]]

--[[
 Changelog:
 * v1.0 April 30 2018
    + Initial release
 * v1.01 July 31 2018
     + Set 'Source: Master mix' and 'Add rendered items to new tracks in project' automatically
 * v1.02 April 03 2019
     + Use Render API (required render settings are set automatically)
--]]

-- USER CONFIG AREA -----------------------------------------------------------

analyzeTruePeak  = false -- true/false: analyze true peak (slower) or not
keepRenderedFile = false -- true/false: keep the rendered file in REAPER or delete it automatically

------------------------------------------------------- END OF USER CONFIG AREA

function preventUndo()
end
reaper.defer(preventUndo)

-- Check whether the required version of REAPER / SWS is available
if not reaper.NF_AnalyzeTakeLoudness or not reaper.GetSetProjectInfo then
  reaper.ShowMessageBox("This script requires REAPER v5.bla / SWS v2.9.6 or above.", "ERROR", 0)
  return
end

reaper.ClearConsole()

function msg(m)
  return reaper.ShowConsoleMsg(tostring(m) .. "\n")
end

local function errorHandler(errObj, errMsg)
  -- set orig. render settings back
  SetRenderSettings(rendersettings, boundsflag, addtoproj, renderpattern)
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- render settings (constants), see API doc
c_source_mastermix = 0
c_bounds_timesel = 2
c_add_rendered_to_proj = 1
c_renderpattern = "_temp_$project_masterLoudnessAnalyze"


-- simple function wrappers for a bit less typing
function GetProjInfo(desc, value)
  return  reaper.GetSetProjectInfo(0, desc, value, false)
end
function SetProjInfo(desc, value)
  return  reaper.GetSetProjectInfo(0, desc, value, true)
end

function GetRenderSettings()
  rendersettings   = GetProjInfo("RENDER_SETTINGS", -1)
  boundsflag       = GetProjInfo("RENDER_BOUNDSFLAG", -1)
  addtoproj        = GetProjInfo("RENDER_ADDTOPROJ", -1)
  
  _, renderpattern = reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "", false)
end

function SetRenderSettings(_rendersettings, _boundsflag, _addtoproj, _renderpattern, _renderclose)
  SetProjInfo("RENDER_SETTINGS", _rendersettings)
  SetProjInfo("RENDER_BOUNDSFLAG", _boundsflag) 
  SetProjInfo("RENDER_ADDTOPROJ",  _addtoproj)
  
  reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", _renderpattern, true) 
end


local function Main()
   
  tracksCountBeforeRender = reaper.CountTracks(0)
  reaper.Main_OnCommand(42230, 0) -- File: Render project, using the most recent render settings, auto-close render dialog
  tracksCountAfterRender = reaper.CountTracks(0)
  
  if tracksCountAfterRender ~= tracksCountBeforeRender+1 then 
    msg("Seems like something went wrong...")
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
  if not keepRenderedFile then
    pcmSource  = reaper.GetMediaItemTake_Source(renderedItemActTake)
    mediaItem  = reaper.GetMediaItemTake_Item(renderedItemActTake)
    fileName   = reaper.GetMediaSourceFileName(pcmSource, '')
    mediaTrack = reaper.GetMediaItem_Track(mediaItem)
    reaper.DeleteTrack(mediaTrack)
    os.remove(fileName)
    reaper.UpdateArrange()
  end
  
end -- Main()


reaper.Undo_BeginBlock()
  -- get orig. (current) render settings
  GetRenderSettings()
  -- set appropriate render settings for Loudness analysis
  SetRenderSettings(c_source_mastermix, c_bounds_timesel, c_add_rendered_to_proj, c_renderpattern) 
  
  xpcall(Main, errorHandler)
  
  -- set orig. render settings back
  SetRenderSettings(rendersettings, boundsflag, addtoproj, renderpattern)
reaper.Undo_EndBlock("Script: Analyze loudness of master output in time sel.", -1)
