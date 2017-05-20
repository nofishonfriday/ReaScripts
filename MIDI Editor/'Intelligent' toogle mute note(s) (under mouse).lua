--[[
 * ReaScript Name: nofish_'Intelligent' toggle mute note(s) (under mouse)
 * Version: 1.0
 * Author: nofish
 * About:
 *  Assign script to shortcut (MIDI editor section).  
 *  - If notes selected: toggle mute state for selected notes  
 *  - If no notes selected: toggle mute state for note under mouse (do nothing if mouse cursor isn't over note)  
 * Link: http://forum.cockos.com/showthread.php?t=192034
--]]

--[[
 Changelog:
 * v1.0, May 20 2017
    + Initial release
--]]


-- reaper.ShowConsoleMsg("") -- clear console

function msg(m)
  reaper.ShowConsoleMsg(tostring(m) .. "\n")
end
DEBUG = false


function selectNoteUnderMouse() -- thanks me2beats
  local r = reaper; local function nothing() end; local function bla() r.defer(nothing) end
  notes = r.MIDI_CountEvts(take)
  window, segment, details = r.BR_GetMouseCursorContext()
  __, __, noteRow, __, __, __ = reaper.BR_GetMouseCursorContext_MIDI()
  if noteRow == -1 then bla() return end
  
  mouse_time = r.BR_GetMouseCursorContext_Position()
  mouse_ppq_pos = r.MIDI_GetPPQPosFromProjTime(take, mouse_time)
  
  -- r.Undo_BeginBlock() r.PreventUIRefresh(1)
  r.PreventUIRefresh(1)
  
  for i = 0, notes - 1 do
    _, sel, muted, start_note, end_note, chan, pitch, vel = r.MIDI_GetNote(take, i)
    if start_note < mouse_ppq_pos and end_note > mouse_ppq_pos and noteRow == pitch then
      
      if sel == false then
        r.MIDI_SetNote(take, i, 1, muted, start_note, end_note, chan, pitch, vel) -- select note
        r.MIDIEditor_OnCommand(reaper.MIDIEditor_GetActive(), 40055) -- Edit: Mute events (toggle)
        reaper.MIDIEditor_OnCommand(reaper.MIDIEditor_GetActive(), 40214) -- Edit: Unselect all
        
      end
    --[[
    elseif sel == true then
      r.MIDI_SetNote(take, i, 0, muted, start_note, end_note, chan, pitch, vel)
    --]]
    end
    
  end
  r.PreventUIRefresh(-1) -- r.Undo_EndBlock('Select only note under mouse', 2)
end

---------------------------------------------------------------------------


take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive());

if (take) then
  notesSelected = reaper.MIDI_EnumSelNotes(take, -1)
  if (DEBUG) then msg(notesSelected) end
  if (notesSelected >= 0) then -- at least one note selected
    reaper.Undo_BeginBlock()
    reaper.MIDIEditor_OnCommand(reaper.MIDIEditor_GetActive(), 40055) -- Edit: Mute events (toggle)
    reaper.Undo_EndBlock('Script: Toggle mute note(s)', 2)
  else -- toggle mute note under mouse
    reaper.Undo_BeginBlock()
    selectNoteUnderMouse()
    reaper.Undo_EndBlock('Script: Toggle mute note(s)', 2)
  end
end
