--[[
 * Version: 1.0
 * ReaScript Name: Bypass master volume envelope
 * Author: nofish
 * Donation: https://paypal.me/nofish
 * Extensions: SWS
 * About:
 *  see URL, needs SWS installed: http://www.sws-extension.org/
 * Link:
 *	https://forum.cockos.com/showthread.php?t=221772
--]]

--[[
 * Changelog:
  
 * v1.0 - June 09 2019
  + initial release
--]]

masterTrack = reaper.GetMasterTrack(0)
masterVolEnv =  reaper.GetTrackEnvelopeByName(masterTrack, "Volume")

if masterVolEnv ~= nil then
  BR_masterVolEnv = reaper.BR_EnvAlloc(masterVolEnv, false)
  if BR_masterVolEnv ~= nil then
    active, visible, armed, inLane, laneHeight, defaultShape, minValue, maxValue, centerValue, _type, faderScaling 
      = reaper.BR_EnvGetProperties(BR_masterVolEnv)
    if active == true then
      reaper.BR_EnvSetProperties(BR_masterVolEnv, false, visible, armed, inLane, laneHeight, defaultShape, faderScaling)
    end
    reaper.BR_EnvFree(BR_masterVolEnv, true)
  end
end
