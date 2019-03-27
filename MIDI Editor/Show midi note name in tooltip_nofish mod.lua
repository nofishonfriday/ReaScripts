--[[
 * ReaScript Name: Show midi note name in tooltip_nofish mod.lua 
 * About: Show tooltip with note name and position under mouse cursor
 *        
 * Author: SeXan / mod by nofish
 * Licence: GPL v3
 * REAPER: 5.0
 * Extensions: SWS
 * Version: 1.01
 * Provides: [main=midi_editor] .
--]]
 
--[[
 * Changelog:
 * v1.0 (2018-15-11)
  + Initial release by SeXan
 * v1.01 (2019-03-26)
  + Support assigning script to toolbar button (lights when active)
  + Register in MIDI editor section (instead of Main section)
  + Display 16th (instead of ticks)
  # Account for Pref: MIDI octave name display offset
  # Remove tooltip if mouse cursor outside piano roll
--]]

-- set toolbar button to on
local _, _, section_ID, cmd_ID = reaper.get_action_context()
reaper.SetToggleCommandState(section_ID, cmd_ID, 1)
reaper.RefreshToolbar2(section_ID, cmd_ID)

function DoAtExit()
  -- set toolbar button to off
  reaper.SetToggleCommandState(section_ID,  cmd_ID, 0);
  reaper.RefreshToolbar2(section_ID,  cmd_ID);
end

-- account for Pref: MIDI octave name display offset
-- in reaper.ini: midioctoffs = 0 => offset set in REAPER prefs = -1
local oct_offset = reaper.SNM_GetIntConfigVar("midioctoffs", -666) - 1

local oct_tbl = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function main()
local x,y = reaper.GetMousePosition()
local window, segment, details = reaper.BR_GetMouseCursorContext()
  if segment == "notes" and window == "midi_editor" then
    local retval, inlineEditor, noteRow, ccLane, ccLaneVal, ccLaneId = reaper.BR_GetMouseCursorContext_MIDI()
    local pos =  reaper.BR_GetMouseCursorContext_Position()
    local retval, measures, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats( 0, pos )
    local beats, frac = math.modf(retval + 1)
    local sixteenth = math.floor(frac / (cdenom / 16)) + 1
    local oct =  math.floor(noteRow / 12) -- get OCTAVE (1,2,3,4....)
    local cur_oct = oct * 12 -- GET OCAVE RANGE (12,24,36...)
    local cur_oct_note = ((cur_oct - noteRow ) * -1) + 1 -- GET OCTAVE NOTE (1,2,3,4...)
    
    for i = 1,#oct_tbl do
      if i == cur_oct_note then
        local note = oct_tbl[i] .. oct - 1 + oct_offset .. " - " .. measures + 1 .. "." .. beats .. "." .. sixteenth
        if last_x ~= x or last_y ~= y then -- DO NOT UPDATE ALL THE TIME, JUST IF MOUSE POSITION CHANGED 
          reaper.TrackCtl_SetToolTip( note, x, y - 25, true )
          last_x, last_y = x, y
        end
      end
    end
  else -- remove tooltip if mouse cursor outside piano roll
    reaper.TrackCtl_SetToolTip("", x, y - 25, true)
  end
reaper.defer(main)  
end
main()

reaper.atexit(DoAtExit)
