--[[
 * ReaScript Name: nofish_'Intelligent' toggle mute note(s) (under mouse)
 * Version: 1.01
 * Author: nofish
 * About:
 *  Assign script to shortcut (MIDI editor section).  
 *  - If notes selected: toggle mute state for selected notes  
 *  - If no notes selected: toggle mute state for note under mouse (do nothing if mouse cursor isn't over note)  
 * Link: http://forum.cockos.com/showthread.php?t=192034
--]]


--[[
 * Changelog:
  
 * v1.0 - May 20 2017
   + initial release

  * v1.01 - May 21 2017
    # fix: selected CC's get unintentionally muted, thanks FnA
--]]


-- reaper.ShowConsoleMsg("") -- clear console

function msg(m)
  reaper.ShowConsoleMsg(tostring(m) .. "\n")
end
DEBUG = false


function toggleMuteNoteUnderMouse() -- thanks me2beats
  local r = reaper; local function nothing() end; local function bla() r.defer(nothing) end
  notes = r.MIDI_CountEvts(take)
  window, segment, details = r.BR_GetMouseCursorContext()
  __, __, noteRow, __, __, __ = reaper.BR_GetMouseCursorContext_MIDI()
  if noteRow == -1 then bla() return end
  
  mouse_time = r.BR_GetMouseCursorContext_Position()
  mouse_ppq_pos = r.MIDI_GetPPQPosFromProjTime(take, mouse_time)
  
  r.PreventUIRefresh(1)
  
  for i = 0, notes - 1 do
    _, sel, muted, start_note, end_note, chan, pitch, vel = r.MIDI_GetNote(take, i)
    if start_note < mouse_ppq_pos and end_note > mouse_ppq_pos and noteRow == pitch then
      
      if sel == false then
        reaper.Undo_BeginBlock()
        if (muted == false) then
          r.MIDI_SetNote(take, i, 0, 1, start_note, end_note, chan, pitch, vel) -- set muted
        elseif (muted == true) then
          r.MIDI_SetNote(take, i, 0, 0, start_note, end_note, chan, pitch, vel) -- set unmuted
        end
        reaper.Undo_EndBlock('Script: Toggle mute note(s)', -1)
      end
    --[[
    elseif sel == true then
      r.MIDI_SetNote(take, i, 0, muted, start_note, end_note, chan, pitch, vel)
    --]]
    end
  end
  r.PreventUIRefresh(-1)
end


--- main ---

local function nothing() end; local function bla() reaper.defer(nothing) end -- prevent undo point when script does nothing

take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive());

if (take) then
  notesSelected = reaper.MIDI_EnumSelNotes(take, -1)
  if (DEBUG) then msg(notesSelected) end
  if (notesSelected >= 0) then -- at least one note selected
    reaper.Undo_BeginBlock()
    reaper.MIDIEditor_OnCommand(reaper.MIDIEditor_GetActive(), 40055) -- Edit: Mute events (toggle)
    reaper.Undo_EndBlock('Script: Toggle mute note(s)', 2)
  else -- toggle mute note under mouse
    toggleMuteNoteUnderMouse()
  end
end

bla() return
