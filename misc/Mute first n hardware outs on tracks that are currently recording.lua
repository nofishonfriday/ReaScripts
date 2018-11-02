--[[
 * ReaScript Name: Mute first n hardware outs on tracks that are currently recording
 * Version: 1.02
 * Author: nofish
 * Author URI: https://forum.cockos.com/member.php?u=6870  
 * Donation: https://paypal.me/nofish
 * About:
 *  See this thread for the idea:  
 *  https://forum.cockos.com/showthread.php?t=197728   
 *  Known issues:  
 *  - Doesn't work correctly in 'Record mode: auto-punch selected items'
--]]

--[[
 * Changelog:
 * v0.90 (October 02 2018)
  + Initial Pre-Release
 * v0.91 (October 07 2018)
  + Make working with 'Record mode: time selection auto punch'
  # Move user setting to script's USER CONFIG AREA (instead of prompt)
 * v0.92 (October 09 2018)
  + Fix bug with unmuting (wrong table index)
 * v1.0 (October 10 2018)
  + Initial Release
  + Script can be assigned to a toolbar button (lights when active), press again to exit
 * v1.01 (October 30 2018)
  + Add option to disable input monitoring during pre-roll
 * v1.02 (November 02 2018)
  # Only disable input monitoring when in Tape Auto Style mode
  # Fix ever growing tables (init at each rec. start)
--]]


-- USER CONFIG AREA -----------------------------------------------------------

NUM_HW_OUTS_TO_MUTE = 1 -- number of first hardware outs to mute
DISABLE_INPUT_MONITORING_DURING_PRE_ROLL = true

------------------------------------------------------- END OF USER CONFIG AREA


reaper.ClearConsole()

DEBUG = false
function Msg(m)
  if DEBUG then
    return reaper.ShowConsoleMsg(tostring(m) .. "\n")
  end
end

--[[
function PromptUser()
  retval, NUM_HW_OUTS_TO_MUTEString = reaper.GetUserInputs("User prompt", 1, "Number of first HW outs to mute:", "")
  if retval then 
    NUM_HW_OUTS_TO_MUTE = tonumber(NUM_HW_OUTS_TO_MUTEString)
    if NUM_HW_OUTS_TO_MUTE and NUM_HW_OUTS_TO_MUTE > 0 then
      Main()
    else -- not a number or <= 0
      PromptUser()
    end
  else -- pressed 'Cancel'
    reaper.ShowConsoleMsg("Script terminated.")
  end
end
--]]

function InitTables() -- init global tables and tables idx's
  tracksWhoseHWoutsWereSetToMute_Table = {}
  tracksWhoseHWoutsWereSetToMute_Table_Idx = 1
  
  tracksWhoseRecMonWereDisabled_Table = {}
  tracksWhoseRecMonWereDisabled_Table_Idx = 1
end

-- https://github.com/Ultraschall/ultraschall-and-reaper-docs/blob/master/Docs/Reaper-ConfigVariables-Documentation.txt#L4371
recModeNormalNoPreroll, recModeNormalWithPreroll, recModeTimeSelAutopunch, recModeAutopunchSelItems = 0, 1, 2, 3
function GetRecMode()
  projrecmode = reaper.SNM_GetIntConfigVar("projrecmode", -666)
  if projrecmode == 1 then -- Record mode: normal
    prerollSettings = reaper.SNM_GetIntConfigVar("preroll", -666)
    if prerollSettings&2  then -- Pre-roll before recording = On
      return recModeNormalWithPreroll
    else
      return recModeNormalNoPreroll
    end
  elseif projrecmode == 0 then
      return recModeAutopunchSelItems
  elseif projrecmode == 2 then
      return recModeTimeSelAutopunch
  end
end

function DoAtExit()
  -- set toggle state to off
  reaper.SetToggleCommandState(sectionID, cmdID, 0);
  reaper.RefreshToolbar2(sectionID, cmdID);
end

--------------------------------------
-- Mute/Unmute HW outs
--------------------------------------
function WaitForPrerollAndMuteHWouts()
  playPos = reaper.GetPlayPosition()
  if playPos >= prerollStopPos then
    MuteHWOuts()
    return
  else 
    -- Msg("Defer WaitForPreroll")
    reaper.defer(WaitForPrerollAndMuteHWouts)
  end
end


function WaitForTimeSelStartAndMuteHWOuts()
  playPos = reaper.GetPlayPosition()
  if playPos >= timeSelStart then
    MuteHWOuts()
    WaitForTimeSelEndAndUnmuteHWouts()
    return
  else 
    reaper.defer(WaitForTimeSelStartAndMuteHWOuts)
    -- Msg("Defer WaitForTimeSelStartAndMuteHWOuts")
  end
end


function WaitForTimeSelEndAndUnmuteHWouts()
  playPos = reaper.GetPlayPosition()
  if playPos >= timeSelEnd then
    UnmuteHWouts()
    return
  else 
    reaper.defer(WaitForTimeSelEndAndUnmuteHWouts)
    -- Msg("Defer WaitForTimeSelEndAndUnmuteHWouts")
  end
end

function MuteHWOuts()
  
  tracksCount = reaper.CountTracks(0)
  for i = 0, tracksCount-1  do
    HWoutWasSetToMute = false
    local tr =  reaper.GetTrack(0, i)
    isRecArmed = reaper.GetMediaTrackInfo_Value(tr, "I_RECARM")
    if isRecArmed == 1 then
      -- Msg(isRecArmed)
      numHWouts = reaper.GetTrackNumSends(tr, 1)
      -- Msg(numHWouts)
      for j = 0, numHWouts-1 do
        if j+1 <= NUM_HW_OUTS_TO_MUTE then
          reaper.SetTrackSendInfo_Value(tr, 1, j, "B_MUTE", 1)
          HWoutWasSetToMute = true
        else
          break
        end
      end -- loop through HW outs 

    end -- if isRecArmed == 1 then
    
    if (HWoutWasSetToMute) then
      tracksWhoseHWoutsWereSetToMute_Table[tracksWhoseHWoutsWereSetToMute_Table_Idx] = tr
      tracksWhoseHWoutsWereSetToMute_Table_Idx = tracksWhoseHWoutsWereSetToMute_Table_Idx + 1 
    end

  end -- loop through tracks
end -- MuteHWOuts()


function UnmuteHWouts()

  for _, tr in ipairs(tracksWhoseHWoutsWereSetToMute_Table) do
    -- Msg("In table")
    if reaper.ValidatePtr(tr, "MediaTrack*") then
      -- Msg("Validated!")
      numHWouts = reaper.GetTrackNumSends(tr, 1)
      for j = 0, numHWouts-1 do
        if j+1 <= NUM_HW_OUTS_TO_MUTE then
          reaper.SetTrackSendInfo_Value(tr, 1, j, "B_MUTE", 0)
        else
          break
        end
      end -- loop through HW outs    
    end -- if reaper.ValidatePtr(tr, "MediaTrack*")
  end -- loop through tracksWhoseHWoutsWereSetToMute_Table

end

--------------------------------------
-- Disable/Enable Input monitoring   
--------------------------------------
function GetPrerollMeasures()
  local prm = reaper.SNM_GetDoubleConfigVar("prerollmeas", -666)
  -- Msg("prm: " .. prm)
  return prm
end

function WaitForPrerollEndandReenableInputMonitoring()
  playPos = reaper.GetPlayPosition()
  if playPos >= prerollStopPos then
    ReenableInputMonitoring()
    return
  else 
    -- Msg("Defer WaitForPreroll")
    reaper.defer(WaitForPrerollEndandReenableInputMonitoring)
  end
end

function DisableInputMonitoring()
  recMonDisabledOnAtLeastOneTrack = false
  
  tracksCount = reaper.CountTracks(0)
  for i = 0, tracksCount-1  do
    local tr =  reaper.GetTrack(0, i)
    isRecArmed = reaper.GetMediaTrackInfo_Value(tr, "I_RECARM")
    if isRecArmed == 1 then
      -- Msg(isRecArmed)
      recMonMode =  reaper.GetMediaTrackInfo_Value(tr, "I_RECMON")
      -- Msg("Mon mode" .. recMonMode)
      if recMonMode == 2 then -- tapestyle
        reaper.SetMediaTrackInfo_Value( tr, "I_RECMON", 0) -- off
        recMonDisabledOnAtLeastOneTrack = true
        
        tracksWhoseRecMonWereDisabled_Table[tracksWhoseRecMonWereDisabled_Table_Idx] = tr
        tracksWhoseRecMonWereDisabled_Table_Idx = tracksWhoseRecMonWereDisabled_Table_Idx + 1 
      end
    end -- if isRecArmed == 1 then  
  end -- loop through tracks
  if recMonDisabledOnAtLeastOneTrack then 
    WaitForPrerollEndandReenableInputMonitoring()
  end
  
end

function ReenableInputMonitoring()
  for _, tr in ipairs(tracksWhoseRecMonWereDisabled_Table) do
    -- Msg("In table")
    if reaper.ValidatePtr(tr, "MediaTrack*") then
      -- Msg("Validated!")
      reaper.SetMediaTrackInfo_Value(tr, "I_RECMON", 2)
    end
  end
end

--------------------------------------
-- Main()
--------------------------------------
lastIsRecording = -1
function Main()     
  isRecording = reaper.GetToggleCommandState(1013) -- "Transport: Record", return values: 0 = not recording, 1 = recording
  
  if lastIsRecording ~= isRecording then
    -- Msg("Recording state: " .. isRecording)
    
    if isRecording == 1 then
      InitTables()
      recMode = GetRecMode()
      prerollStopPos = reaper.GetCursorPosition()
      if recMode == recModeNormalNoPreroll then
        MuteHWOuts()
      elseif recMode == recModeNormalWithPreroll then

        -- prerollStopPos = reaper.GetCursorPosition()
        WaitForPrerollAndMuteHWouts()

      elseif recMode == recModeTimeSelAutopunch then

        timeSelStart, timeSelEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false) -- get cur. time sel. values
        if timeSelEnd > timeSelStart then
          WaitForTimeSelStartAndMuteHWOuts()
        end

      elseif recMode == recModeAutopunchSelItems then
        -- TODO --
      end

      if DISABLE_INPUT_MONITORING_DURING_PRE_ROLL and GetRecMode() ~= recModeNormalNoPreroll and GetPrerollMeasures() >= 1 then
        DisableInputMonitoring()
      end
    
    else --  isRecording == 0, unmute the HWouts
      -- Msg("Unmute HW outs called")
      UnmuteHWouts()
      
    end -- if isRecording

    lastIsRecording = isRecording
  end -- if lastIsRecording ~= isRecording
  
  reaper.defer(Main)
end -- Main()


--------------------------------------
-- start
--------------------------------------
InitTables()

-- set toggle state to on
_, _, sectionID, cmdID, _, _, _ = reaper.get_action_context()
reaper.SetToggleCommandState(sectionID, cmdID, 1);
reaper.RefreshToolbar2(sectionID, cmdID);

recMode = GetRecMode()
if recMode == recModeAutopunchSelItems then
  reaper.ShowConsoleMsg("'Recording mode: auto-punch selected items' not implemented currently.\nScript terminated.")
else
  -- PromptUser()
  Main()
end

reaper.atexit(DoAtExit)

