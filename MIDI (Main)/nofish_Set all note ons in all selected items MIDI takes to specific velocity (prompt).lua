--[[
 * ReaScript Name: Set all note ons in all selected items MIDI takes to specific velocity (prompt)
 * Version: 1.0
 * Author: nofish, thanks juliansader
 * Donation: https://paypal.me/nofish
 * About:
 *  Sets all note ons in all selected items MIDI takes to specific velocity  
 *  Opens a prompt at script start to set destination velocity (if at least one item conatining a MIDI take is selected)  
--]]

--[[
 * Changelog:
  
 * v1.0 - December 01 2018
   + initial release
--]]

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


velocitySet = false
userPressedCancel = false

function SetVelocityOfSelectedMIDIItems()
    
  -- First, loop through all selected items
    for i = 0, reaper.CountSelectedMediaItems(0)-1 do
      item = reaper.GetSelectedMediaItem(0, i)
      
        -- Loop through all takes within each selected item
        for t = 0, reaper.CountTakes(item)-1 do
          take = reaper.GetTake(item, t)

            if reaper.TakeIsMIDI(take) then -- -- Show prompt if at least one sel. take is MIDI

                if not velocitySet and not userPressedCancel then 
                    targetVelocity = GetUserInput() 
                end

                if (targetVelocity) then
                    gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")

                    if gotAllOK then
                        MIDIlen = MIDIstring:len()  
                    
                        -- As the MIDI string is parsed one-by-one, all events will be
                        --    stored in this table while awaiting re-concatenation.
                        tableEvents = {}
                        
                        stringPos = 1 -- Position in MIDIstring while parsing through events.
                        
                        -- Iterate through all events one-by-one   
                        while stringPos < MIDIlen do
                            offset, flags, msg, stringPos = string.unpack("i4Bs4", MIDIstring, stringPos)        
                            if msg:len() == 3
                            and msg:byte(1)>>4 == 9 -- Note-on MIDI event type
                            and not (msg:byte(3) == 0) -- Remember to exclude note-offs
                            then
                                msg = msg:sub(1,2) .. string.char(targetVelocity) -- Replace velocity
                            end
                            
                            table.insert(tableEvents, string.pack("i4Bs4", offset, flags, msg))
                        end
                        
                        -- Upload the edited MIDI into the take
                        reaper.MIDI_SetAllEvts(take, table.concat(tableEvents))
                    end -- if gotAllOK then
            
                end -- (targetVelocity) then

            end -- if reaper.TakeIsMIDI(take)
            
        end -- for t = 0, reaper.CountTakes(item)-1 do

    end -- for i = 0, reaper.CountSelectedMediaItems(0)-1 do

    reaper.Undo_OnStateChange("Script: Set velocity of sel. MIDI items")
end -- function SetVelocityOfSelectedMIDIItems()


function GetUserInput()
    local targetVelocity = ""
    retval, velocity_string = reaper.GetUserInputs("Set velocity of sel. MIDI items to...", 1, "Velocity: (1-127)", targetVelocity)
    if not retval then -- user pressed 'Cancel'
      userPressedCancel = true
      return 
    end 
    
    targetVelocity = tonumber(velocity_string)
    if (targetVelocity ~= nil) then -- conversion to number ok
      -- check if integer and bounds
      if (targetVelocity == math.floor(targetVelocity) and (targetVelocity > 0 and targetVelocity < 128)) then 
        targetVelocity = math.floor(targetVelocity) -- if user input e.g. 1.0
        velocitySet = true
        return targetVelocity
        
      else -- number not int or out of bounds
        SetVelocityOfSelectedMIDIItems()
      end
    else -- conversion to number failed
        SetVelocityOfSelectedMIDIItems()
    end --  if (targetVelocity ~= nil)
end


SetVelocityOfSelectedMIDIItems()
