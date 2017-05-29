--[[
 * ReaScript Name: nofish_Set all events of selected MIDI items to specific channel
 * Version: 1.01
 * Author: juliansader, nofish
 * About:
 *  Changes the channel of all notes, CCs and  notation events in all selected MIDI items to a specific channel   
 *  - At least one MIDI take must be selected while the script is run to show a prompt to enter new channel for events  
 * Link: http://forum.cockos.com/showthread.php?t=192336
--]]


--[[
 * Changelog:
  
 * v1.0 - May 26 2017
   + initial version by juliansader

  * v1.01 - May 29 2017
    + nofish: added user prompt, check for required Reaper version
--]]
---------------

function msg(m)
  reaper.ShowConsoleMsg(tostring(m) .. "\n")
end


-- Start off with a little 'trick' to prevent REAPER from automatically
--    creating an undo point if no changes are made.
function preventUndo()
end
reaper.defer(preventUndo)


-- Check whether the required version of REAPER is available
if not reaper.APIExists("MIDI_GetAllEvts") then
    reaper.ShowMessageBox("This script requires REAPER v5.30 or higher.", "ERROR", 0)
    return(false) 
end


channelSet = false
userPressedCancel = false
notationReplacementText = ""


function SetEventsChannelForSelectedItem()
    
  -- First, loop through all selected items
  for i = 0, reaper.CountSelectedMediaItems(0)-1 do
      item = reaper.GetSelectedMediaItem(0, i)
      
      -- Loop through all takes within each selected item
      for t = 0, reaper.CountTakes(item)-1 do
          take = reaper.GetTake(item, t)
          if reaper.TakeIsMIDI(take) then -- show prompt if at least one sel. take is MIDI
              if not channelSet and not userPressedCancel then 
                newChannel = GetUserInput() 
              end
              if (newChannel) then
               
                -- Use the new Get/SetAllEvts functions to directly (and quickly) edit the MIDI data
                  local gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
                  if gotAllOK then
                  
                  
                      local tableEvents = {} -- MIDI events will temporarily be stored in this table until they are concatenated into a string again
                      local t = 1 -- Index inside tableEvents
                      local MIDIlen = MIDIstring:len()
                      local positionInString = 1 -- Position inside MIDIstring while parsing
                      local offset, flags, msg
                      -- Now parse through all events in the MIDI string, one-by-one
                      -- (Excluding the final 12 bytes, which provides REAPER's All-notes-off end-of-take message)
                      while positionInString < MIDIlen-12 do 
                          offset, flags, msg, positionInString = string.unpack("i4Bs4", MIDIstring, positionInString)
                          local msg1 = msg:byte(1) -- The first byte contains the event type and channel
                          if msg1 then -- If empty event that simply changes PPQ position, msg1 will be nil
                              if msg1>>4 ~= 0xF then -- First nybble gives event type; exclude text/sysex messages, which do not carry channel info
                                  msg = string.char(((msg1 & 0xF0) | newChannel)) .. msg:sub(2) -- 2nd nybble gives channel
                              elseif msg1 == 0xFF then -- REAPER's notation events also refer to the note channel
                                  msg = msg:gsub("NOTE %d+ ", notationReplacementText, 1)
                              end                    
                          end
                          tableEvents[t] = string.pack("i4Bs4", offset, flags, msg)
                          t = t + 1
                      end
                      
                      -- This script does not change the order of events, so no need to call MIDI_Sort after updating take's MIDI
                      reaper.MIDI_SetAllEvts(take, table.concat(tableEvents) .. MIDIstring:sub(-12))
                  end -- if gotAllOK
              end
          end -- if reaper.TakeIsMIDI(take)
      end
  end
  if newChannel then
    reaper.Undo_OnStateChange("Set all evts. of sel. items to channel " .. newChannel+1)
  end
end


function GetUserInput()
  local channel = ""
  retval, channel_string = reaper.GetUserInputs("Set evts. of sel. items to...", 1, "Channel: (1-16)", channel)
  if not retval then -- user pressed 'Cancel'
    userPressedCancel = true
    return 
  end 
  
  channel = tonumber(channel_string)
  if (channel ~= nil) then -- conversion to number ok
    -- check if integer and bounds
    if (channel == math.floor(channel) and (channel < 17 and channel > 0)) then 
      channel = math.floor(channel) -- if user input e.g. 1.0
      -- reaper.Undo_OnStateChange("Set all evts. of sel. items to channel " .. channel)
      channelSet = true
      
      -- SetEventsChannelForSelectedItem() works on 0-15 range, NOT 1-16 range !
      notationReplacementText = string.format("NOTE %i ", channel-1) -- Will be used to replace channel info in REAPER's notation events
      return (channel-1)
      
    else -- number not int or out of bounds
      SetEventsChannelForSelectedItem()
    end
  else -- conversion to number failed
    SetEventsChannelForSelectedItem()
  end --  if (channel ~= nil)
end

SetEventsChannelForSelectedItem()





