-- @description Print visible (within item start end) take markers on selected tracks to console  
-- @author nofish
-- @about
--   thread: https://forum.cockos.com/showthread.php?t=271513  
--   Note: for takes with active stretch markers this script doesn't work correctly currently (take marker positions are wrong)!
-- @version 1.0.4
-- @changelog
--   # add note about stretch markers not supported currently

function preventUndo() end
reaper.defer(preventUndo)

local function Msg(str)
  reaper.ShowConsoleMsg(tostring(str))
end

-- https://gist.github.com/Hristiyanii/3fe3a4d9f5522bdd8a3f5ce93104f48f
function SecondsToClock(seconds)
  local seconds = tonumber(seconds)

  if seconds <= 0 then
    return "00:00:00";
  else
    hours = string.format("%02.f", math.floor(seconds/3600));
    mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
    secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
    return hours..":"..mins..":"..secs
  end
end

function Main()
  reaper.ClearConsole()
  
  lastTrackNumber = -1
  selectedTracksCount = reaper.CountSelectedTracks(0)
  for i = 0, selectedTracksCount-1  do
    track = reaper.GetSelectedTrack(0, i)
    trackNumber =  reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
    _, trackName = reaper.GetTrackName(track) 
    trackItemsCount =  reaper.CountTrackMediaItems(track)
    
    for j = 0, trackItemsCount-1  do
      item = reaper.GetTrackMediaItem(track, j)
      itemPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION") 
      itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      take = reaper.GetActiveTake(item) -- only check active take for now
      takeStartOffset =  reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
      takeMarkersCount = reaper.GetNumTakeMarkers(take)
      
      for k = 0, takeMarkersCount-1 do
        takeMarkerPos, takeMarkerName, color = reaper.GetTakeMarker(take, k) 
        if takeMarkerPos ~= -1 and takeMarkerPos >= takeStartOffset and takeMarkerPos <= takeStartOffset+itemLength then 
          -- Msg("tn: " .. trackNumber .. " ltn: " .. lastTrackNumber)
          if lastTrackNumber ~= trackNumber then
            Msg("Track " .. math.floor(trackNumber) .. ":" .. trackName .. "\n")
            lastTrackNumber = trackNumber
          end
          takeMarkerPosInProjTimeInSec = itemPos - takeStartOffset + takeMarkerPos
          takeMarkerPosInProjTimeInClock = SecondsToClock(takeMarkerPosInProjTimeInSec)
          Msg(takeMarkerPosInProjTimeInClock .. " " .. takeMarkerName .. "\n")
        end
      end
    end -- ENDLOOP through items on track
    Msg("\n")
  end -- ENDLOOP through selected tracks
end

Main()

