--[[
 * ReaScript Name: nofish_Only keep items selected with duplicate mono channels.lua
 * Version: 0.9
 * Author: nofish
 * About:
 *   checks if stereo items contain identical l / r
	see http://forum.cockos.com/showthread.php?t=183153
--]]

--[[
 Changelog:
 * v0.9
    + beta test version
--]]





--[[
works on selected stereo (2-channel) items (selected 1- or more than 2-channels items are ignored in the test)
checks against user-setable threshold if left and right channel are identical (= double-mono items)
and if so it keeps only these items selected

play around with threshold for different sources

Reaper may temporary freeze (spinning circle) during analysis, be patient... :)

Audio accessor code bits by spk77, thanks
https://github.com/X-Raym/REAPER-ReaScripts/blob/master/Functions/spk77_Get%20max%20peak%20val%20and%20pos%20from%20take_function.lua
--]]


-- *** user area *** ---

-- differences in sample values below this threshold will be ignored
detection_threshold = -20

-- *** end of user area *** ---


-- *** aux functions *** ---

-- DBG
reaper.ShowConsoleMsg("")
function msg(m)
  if debug == 1 then reaper.ShowConsoleMsg(tostring(m) .. "\n")
  end
end

function trunc(num, digits) -- not used currently
  local mult = 10^(digits)
  return math.modf(num*mult)/mult
end

-- set item selection from selItemsTable
function selectDoubleMonoItems (table)
  reaper.Main_OnCommand(40289, 0) -- unsel all items
  for _, item in ipairs(table) do
    reaper.SetMediaItemSelected(item, true)
  end
end

-- db to linear
function dbToLin(x)
  return 10^(x/20)
end


-- *** init *** --

selItemsTable = {} -- init empty table
tablePos = 1


-- *** main *** ---

function main()
debug = 1
  reaper.Undo_BeginBlock() 
 
  selected_items_count = reaper.CountSelectedMediaItems(0)
  msg(selected_items_count .. " items selected")
  
  detection_threshold_lin = dbToLin(detection_threshold)
  
  -- loop through selected items
  for i = 0, selected_items_count-1  do
    -- GET ITEMS
    item = reaper.GetSelectedMediaItem(0, i) -- Get selected item i
    itemIsStereo = false
		 
    if item then
	 local progressDisplay = "\nprocessing item " .. (i+1)
	 msg(progressDisplay)
	 
	 local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
	 local take = reaper.GetActiveTake(item) -- Get the active take   
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
	
	
	 if (take_source_num_channels == 2) then -- get samples and check block per block
	 
	  local take_source_sample_rate = reaper.GetMediaSourceSampleRate(take_pcm_source)
	  -- How many samples are taken from audio accessor and put in the buffer
	  local samples_per_channel = take_source_sample_rate

	  -- Samples are collected to this buffer
	  local buffer = reaper.new_array(samples_per_channel * take_source_num_channels)
	  
	  local total_samples = math.ceil((aa_end - aa_start) * take_source_sample_rate)
	  local block = 0
	  local sample_count = 0
	  local audio_end_reached = false
	  local offs = aa_start
	  
	  local abs = math.abs
	  -- sample value to db FS, x dbFS = 20*log10(x)
	  local log10 = function(x) return math.log(x, 10) end
	 
	  -- *** Loop through samples *** ---
	  -- Audio accessor code bits by spk77, thanks
	  
	  
	    while sample_count < total_samples do
		 if audio_end_reached then
		   break
		 end
		 
		 
		 local aa_ret = reaper.GetAudioAccessorSamples(
		   aa,                       -- AudioAccessor accessor
		   take_source_sample_rate,  -- integer samplerate
		   take_source_num_channels, -- integer numchannels
		   offs,                     -- number starttime_sec
		   samples_per_channel,      -- integer numsamplesperchannel
		   buffer                    -- reaper.array samplebuffer
		  )
		  
		 -- msg(buffer)
		 if aa_ret <= 0 then
		   --msg("no audio or other error")
		   --return
		 end
		 -- msg(aa_ret)
		 
		 samples_sum_L = 0
		 samples_sum_R = 0
		 -- Ixix method
		 difference = 0
		 
		 --[[
		 loop through cur. buffer
		 sum left samples, sum right samples
		 if (sum left - sum right) > detection_threshold => item is stereo
		 --]]
		 
		 for i=1, #buffer, take_source_num_channels do 
		   if sample_count == total_samples then
			audio_end_reached = true
			break
		   end
		   
		   --[[
		   -- loop through channels
		   for j=1, take_source_num_channels do
			local buf_pos = i+j-1
			-- local curr_val = abs(buffer[buf_pos])
			local curr_val = (buffer[buf_pos])
			msg(curr_val)
		   end
		   --]]
		   
		   local buf_pos_left = i -- left channel
		   local cur_val_left = (buffer[buf_pos_left])
		   -- local cur_val_left = math.abs( (buffer[buf_pos_left]) )
		   samples_sum_L = samples_sum_L + cur_val_left
		  
		   
		   local buf_pos_right = i+1 -- right channel, interleaved
		   local cur_val_right = (buffer[buf_pos_right])
		   -- local cur_val_right = math.abs( (buffer[buf_pos_right]) )
		   samples_sum_R = samples_sum_R + cur_val_right
		   
		   -- Ixix
		   difference = difference + (cur_val_left - cur_val_right)
		   
		    -- uncomment here if want to see sample analysis (warning: huge data output)
		    --[[
		    msg("is stereo: ")
		    reaper.ShowConsoleMsg(cur_val_left)
		    reaper.ShowConsoleMsg("\n")
		    reaper.ShowConsoleMsg(cur_val_right)
		    reaper.ShowConsoleMsg("\n")
		    msg("===")
		    --]]
		    
		   sample_count = sample_count + 1
		 end -- loop through cur buffer
		 
		 -- msg(samples_sum_L)
		 -- msg(samples_sum_R)
		 -- msg(block)
		 -- reaper.ShowConsoleMsg(".") -- progress display
		 
		 local LR_diff = abs(samples_sum_L - samples_sum_R)
		 -- local LR_diff = (samples_sum_L - samples_sum_R)
		
		 
		 -- msg(detection_threshold_lin)               
		 -- msg(LR_diff)
		 -- msg("\n")
		 
		 -- if (LR_diff > detection_threshold_lin) then
		 if (difference > detection_threshold_lin) then
		  itemIsStereo = true
		  break
		 end
		 
		 block = block + 1
		 offs = offs + samples_per_channel / take_source_sample_rate -- new offset in take source (seconds)
	    end -- while sample_count < total_samples
	    if (itemIsStereo == false) then -- 2-channel item is double-mono
		selItemsTable[tablePos] = item -- store this item in item selection table for later
		tablePos = tablePos+1
		msg("\ndouble mono item detected")
	    end
	 reaper.DestroyAudioAccessor(aa)
	 end -- if (take_source_num_channels == 2)
	 -- msg("next item")
    end -- if item then
  end -- END LOOP through selected items
  reaper.Undo_EndBlock("nofish_Only keep items selected with duplicate mono channels", -1) -- End of the undo block. Leave it at the bottom of your main function.
end -- main()


main()

selectDoubleMonoItems(selItemsTable)
reaper.UpdateArrange()
msg("\nDone !")

--[[
Audio accessor rescript example:
tr = RPR_GetTrack(0, 0)
aa = RPR_CreateTrackAudioAccessor(tr)
buf = list([0]*2*1024) # 2 channels, 1024 samples each, initialized to zero
pos = 0.0
(ret, buf) = GetAudioAccessorSamples(aa, 44100, 2, pos, 1024, buf)
# buf now holds the first 2*1024 audio samples from the track.
# typically GetAudioAccessorSamples() would be called within a loop, increasing pos each time.

Get a block of samples from the audio accessor.
Samples are extracted immediately pre-FX,
and returned interleaved (first sample of first channel,
first sample of second channel...). Returns 0 if no audio, 1 if audio, -1 on error.
 --]]



