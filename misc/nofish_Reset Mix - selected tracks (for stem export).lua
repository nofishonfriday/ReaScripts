--[[
 * ReaScript Name: nofish_Reset Mix - selected tracks (for stem export)
 * Version: 1.0
 * Author: nofish
 * About:
 *  Does the following:
 *  - Bypass all automation
 *  - Bypass sel. tracks FX (except VSTi)
 *  - Reset sel. tracks volume, reset sel. tracks pan
 *  - Reset master volume, Bypass master FX
 *  - Optionally: Reset all item and take volume
--]]

--[[
 Changelog:
 * v1.0 - October 21 2017
    + Initial release
--]]


reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()


reaper.Main_OnCommand(40885, 0) -- Global automation override: Bypass all automation

reaper.Main_OnCommand(reaper.NamedCommandLookup("_NF_BYPASS_FX_EXCEPT_VSTI_FOR_SEL_TRACKS"), 0) -- Bypass FX (except VSTi) for sel. tracks
reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_RESETTRACKVOLANDPAN1"), 0) -- Reset volume and pan of selected tracks

reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_SETMASTVOLTO0"), 0) -- Set master volume to 0 dB
reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_DISMASTERFX"), 0) -- Disable master FX

--[[
-- optionally reset item and take volume
reaper.Main_OnCommand(40182, 0) -- Select all items
reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_RESETITEMVOL"), 0) -- Reset item volume to 0.0 dB
reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_RESETTAKEVOL"), 0) -- Reset active take volume to 0.0 dB
reaper.Main_OnCommand(40289, 0) -- Unselect all items
--]]


reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Script: nofish_Reset Mix", -1)



