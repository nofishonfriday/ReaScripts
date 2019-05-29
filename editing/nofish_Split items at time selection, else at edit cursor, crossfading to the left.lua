--[[
 * ReaScript Name: Split items at time selection, else at edit cursor, crossfading to the left
 * Version: 1.0
 * Author: nofish
 * Author URI: https://forum.cockos.com/member.php?u=6870
 * Extensions: SWS/S&M 2.8.1
 * About:
 *  Split sel. items at time sel., in case no split happened: split sel. items at edit cursor w/crossfade on left (using SWS/AW action)  
--]]

--[[
 * Changelog:
 * v1.0 (May 29 2019)
  + Initial Release
 * v1.01 (May 29 2019)
  # Fix typo in title
--]]

-- thanks X-Raym
-- https://github.com/ReaTeam/ReaScripts-Templates/blob/master/Various/X-Raym_Check%20if%20SWS%20is%20installed%20and%20download%20if%20not.lua
function Open_URL(url)
  if not OS then local OS = reaper.GetOS() end
  if OS=="OSX32" or OS=="OSX64" then
    os.execute("start \"\" \"".. url .. "\"")
   else
    os.execute("start ".. url)
  end
end

function CheckSWS()
  if reaper.NamedCommandLookup("_BR_VERSION_CHECK") == nil then 
    local retval = reaper.ShowMessageBox("SWS extension is required by this script.\nHowever, it doesn't seem to be present for this REAPER installation.\n\nDo you want to download it now ?", "Warning", 1)
    if retval == 1 then
      Open_URL("http://www.sws-extension.org/")
    end
  else
    return true
  end
end


--- Main() ---
function Main()
  reaper.Undo_BeginBlock()
 
  itemsCount1 =  reaper.CountMediaItems(0)
  reaper.Main_OnCommand(40061, 0) -- Split items at time selection
  itemsCount2 =  reaper.CountMediaItems(0)
  
  if itemsCount1 == itemsCount2 then -- no 'Split items at time selection' happened
    -- SWS/AW: Split selected items at edit cursor w/crossfade on left
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_AWSPLITXFADELEFT"), 0) 
  end
     
  reaper.Undo_EndBlock("Script: Split items at TS, else at edit cursor w/crossfade on left", 0)
end -- end Main()

--- Start ---
sws = CheckSWS()
if sws == true then
  reaper.PreventUIRefresh(1)
  reaper.defer(Main)
  reaper.PreventUIRefresh(-1) 
  reaper.UpdateArrange()
end
