--[[
 * Version: 1.0
 * ReaScript Name: Set inactive takes of selected audio items offline (no undo)
 * Author: nofish
 * Donation: https://paypal.me/nofish
 * Extensions: SWS
 * About: As script name says. Needs SWS v2.10.0+ installed: http://www.sws-extension.org/
--]]

--[[
 * Changelog:
  
 * v1.0 - July 02 2019
  + initial release
--]]

function Main()  
  selItemsCount = reaper.CountSelectedMediaItems(0)
  for i = 0, selItemsCount-1  do
    local item = reaper.GetSelectedMediaItem(0, i)
    local activeTakeNr =  reaper.GetMediaItemInfo_Value(item, "I_CURTAKE")
    takesCount = reaper.CountTakes(item)
    for j = 0, takesCount-1  do
      take =  reaper.GetTake(item, j)
      if take == nil then goto continueTakeLoop end
      source =  reaper.GetMediaItemTake_Source(take)
      if source == nil then goto continueTakeLoop end
      sampleRate =  reaper.GetMediaSourceSampleRate(source)
      if sampleRate > 0 and j ~= activeTakeNr then
        reaper.CF_SetMediaSourceOnline(source, false)
      end
    ::continueTakeLoop::
    end -- end loop through takes
  end -- end loop through sel. items
   
  reaper.UpdateArrange()
end

reaper.defer(Main)



