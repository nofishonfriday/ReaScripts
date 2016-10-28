--[[
-- ----- DEBUGGING ====>

local info = debug.getinfo(1,'S');

local full_script_path = info.source

local script_path = full_script_path:sub(2,-5) -- remove "@" and "file extension" from file name

if reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32" then
  package.path = package.path .. ";" .. script_path:match("(.*".."\\"..")") .. "..\\Functions\\?.lua"
else
  package.path = package.path .. ";" .. script_path:match("(.*".."/"..")") .. "../Functions/?.lua"
end

require("X-Raym_Functions - console debug messages")


debug = 1 -- 0 => No console. 1 => Display console messages for debugging.
clean = 1 -- 0 => No console cleaning before every script execution. 1 => Console cleaning before every script execution.

time_os = reaper.time_precise()

msg_clean()
-- <==== DEBUGGING -----
--]]

function msg(m)
  if debug == 1 then reaper.ShowConsoleMsg(tostring(m) .. "\n")
  end
end


function main() -- local (i, j, item, take, track)
debug = 1
 

  reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

  -- YOUR CODE BELOW

  -- LOOP THROUGH SELECTED ITEMS
  
  selected_items_count = reaper.CountSelectedMediaItems(0)
  
  -- INITIALIZE loop through selected items
  for i = 0, selected_items_count-1  do
    -- GET ITEMS
    item = reaper.GetSelectedMediaItem(0, i) -- Get selected item i
    
    --[[
       algo:
       https://www.gearslutz.com/board/5826380-post7.html
       
       A = wavread('filename');
       A_left = A(:,1);
       A_right = A(:,2);
       mono_test = sum(A_left - A_right);
       if (mono_test > 0)
       disp('Input file is stereo');
       else
       disp('Input file is dual mono');
       end %if
       --]]
       
    if item then
      local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      local take = reaper.GetActiveTake(item) -- Get the active take   
      -- Get media source of media item take
      local take_pcm_source = reaper.GetMediaItemTake_Source(take)   
      -- Get media source of media item take       
      local take_pcm_source = reaper.GetMediaItemTake_Source(take)
      
      -- Create take audio accessor
      local aa = reaper.CreateTakeAudioAccessor(take)
      -- Get the start time of the audio that can be returned from this accessor
        local aa_start = reaper.GetAudioAccessorStartTime(aa)
        -- Get the end time of the audio that can be returned from this accessor
        local aa_end = reaper.GetAudioAccessorEndTime(aa)
        local take_source_len, length_is_QN = reaper.GetMediaSourceLength(take_pcm_source)
        -- Get the number of channels in the source media.
         local take_source_num_channels = reaper.GetMediaSourceNumChannels(take_pcm_source)
         msg(take_source_num_channels)
    end
        
        
      
       
    

    -- GET INFOS
    -- value_get = reaper.GetMediaItemInfo_Value(item, "D_VOL") -- Get the value of a the parameter
    --[[
    B_MUTE : bool * to muted state
    B_LOOPSRC : bool * to loop source
    B_ALLTAKESPLAY : bool * to all takes play
    B_UISEL : bool * to ui selected
    C_BEATATTACHMODE : char * to one char of beat attached mode, -1=def, 0=time, 1=allbeats, 2=beatsosonly
    C_LOCK : char * to one char of lock flags (&1 is locked, currently)
    D_VOL : double * of item volume (volume bar)
    D_POSITION : double * of item position (seconds)
    D_LENGTH : double * of item length (seconds)
    D_SNAPOFFSET : double * of item snap offset (seconds)
    D_FADEINLEN : double * of item fade in length (manual, seconds)
    D_FADEOUTLEN : double * of item fade out length (manual, seconds)
    D_FADEINLEN_AUTO : double * of item autofade in length (seconds, -1 for no autofade set)
    D_FADEOUTLEN_AUTO : double * of item autofade out length (seconds, -1 for no autofade set)
    C_FADEINSHAPE : int * to fadein shape, 0=linear, ...
    C_FADEOUTSHAPE : int * to fadeout shape
    I_GROUPID : int * to group ID (0 = no group)
    I_LASTY : int * to last y position in track (readonly)
    I_LASTH : int * to last height in track (readonly)
    I_CUSTOMCOLOR : int * : custom color, windows standard color order (i.e. RGB(r,g,b)|0x100000). if you do not |0x100000, then it will not be used (though will store the color anyway)
    I_CURTAKE : int * to active take
    IP_ITEMNUMBER : int, item number within the track (read-only, returns the item number directly)
    F_FREEMODE_Y : float * to free mode y position (0..1)
    F_FREEMODE_H : float * to free mode height (0..1)
    ]]
    
    
    -- MODIFY INFOS
   --  value_set = value_get -- Prepare value output
    
    -- SET INFOS
    -- reaper.SetMediaItemInfo_Value(item, "D_VOL", value_set) -- Set the value to the parameter
    
   
    
    
  end -- ENDLOOP through selected items
  

 

  reaper.Undo_EndBlock("My action", -1) -- End of the undo block. Leave it at the bottom of your main function.

end


-- The following functions may be passed as global if needed
--[[ ----- INITIAL SAVE AND RESTORE ====> ]]

-- ITEMS
--[[ UNSELECT ALL ITEMS
function UnselectAllItems()
  for  i = 0, reaper.CountMediaItems(0) do
    reaper.SetMediaItemSelected(reaper.GetMediaItem(0, i), false)
  end
end

-- SAVE INITIAL SELECTED ITEMS
init_sel_items = {}
local function SaveSelectedItems (table)
  for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    table[i+1] = reaper.GetSelectedMediaItem(0, i)
  end
end

-- RESTORE INITIAL SELECTED ITEMS
local function RestoreSelectedItems (table)
  UnselectAllItems() -- Unselect all items
  for _, item in ipairs(table) do
    reaper.SetMediaItemSelected(item, true)
  end
end]]

-- TRACKS
--[[ UNSELECT ALL TRACKS
function UnselectAllTracks()
  first_track = reaper.GetTrack(0, 0)
  reaper.SetOnlyTrackSelected(first_track)
  reaper.SetTrackSelected(first_track, false)
end

-- SAVE INITIAL TRACKS SELECTION
init_sel_tracks = {}
local function SaveSelectedTracks (table)
  for i = 0, reaper.CountSelectedTracks(0)-1 do
    table[i+1] = reaper.GetSelectedTrack(0, i)
  end
end

-- RESTORE INITIAL TRACKS SELECTION
local function RestoreSelectedTracks (table)
  UnselectAllTracks()
  for _, track in ipairs(table) do
    reaper.SetTrackSelected(track, true)
  end
end

-- LOOP AND TIME SELECTION
--[[ SAVE INITIAL LOOP AND TIME SELECTION
function SaveLoopTimesel()
  init_start_timesel, init_end_timesel = reaper.GetSet_LoopTimeRange(0, 0, 0, 0, 0)
  init_start_loop, init_end_loop = reaper.GetSet_LoopTimeRange(0, 1, 0, 0, 0)
end

-- RESTORE INITIAL LOOP AND TIME SELECTION
function RestoreLoopTimesel()
  reaper.GetSet_LoopTimeRange(1, 0, init_start_timesel, init_end_timesel, 0)
  reaper.GetSet_LoopTimeRange(1, 1, init_start_loop, init_end_loop, 0)
end]]

-- CURSOR
--[[ SAVE INITIAL CURSOR POS
function SaveCursorPos()
  init_cursor_pos = reaper.GetCursorPosition()
end

-- RESTORE INITIAL CURSOR POS
function RestoreCursorPos()
  reaper.SetEditCurPos(init_cursor_pos, false, false)
end]]

-- VIEW
--[[ SAVE INITIAL VIEW
function SaveView()
  start_time_view, end_time_view = reaper.BR_GetArrangeView(0)
end


-- RESTORE INITIAL VIEW
function RestoreView()
  reaper.BR_SetArrangeView(0, start_time_view, end_time_view)
end]]

--[[ <==== INITIAL SAVE AND RESTORE ----- ]]




--msg_start() -- Display characters in the console to show you the begining of the script execution.

--[[ reaper.PreventUIRefresh(1) ]]-- Prevent UI refreshing. Uncomment it only if the script works.

--SaveView()
--SaveCursorPos()
--SaveLoopTimesel()
--SaveSelectedItems(init_sel_items)
--SaveSelectedTracks(init_sel_tracks)

main() -- Execute your main function

--RestoreCursorPos()
--RestoreLoopTimesel()
--RestoreSelectedItems(init_sel_items)
--RestoreSelectedTracks(init_sel_tracks)
--RestoreView()

--[[ reaper.PreventUIRefresh(-1) ]] -- Restore UI Refresh. Uncomment it only if the script works.

reaper.UpdateArrange() -- Update the arrangement (often needed)

--msg_end() -- Display characters in the console to show you the end of the script execution.

-- reaper.ShowMessageBox("Script executed in (s): "..tostring(reaper.time_precise() - time_os), "", 0)
