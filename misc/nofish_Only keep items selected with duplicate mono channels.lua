--[[
nofish_Only keep items selected with duplicate mono channels.lua
v0.1

works on selected stereo (2-channel) items (selected 1- or more than 2-channels items are ignored in the test)
checks if left and right channel are identical (= double mono items)
and if so it keeps only these items selected
--]]


--[[
set rounding precision here...
not used currently
--]]
decimals = 4


function trunc(num, digits)
  local mult = 10^(digits)
  return math.modf(num*mult)/mult
end

-- DBG
reaper.ShowConsoleMsg("")
function msg(m)
  if debug == 1 then reaper.ShowConsoleMsg(tostring(m) .. "\n")
  end
end

selItemsTable = {} -- init empty table
tablePos = 1


-- set item selection from selItemsTable
function selectDoubleMonoItems (table)
  reaper.Main_OnCommand(40289, 0) -- unsel all items
  for _, item in ipairs(table) do
    reaper.SetMediaItemSelected(item, true)
  end
end



function main()
debug = 1
  reaper.Undo_BeginBlock() 
 
  selected_items_count = reaper.CountSelectedMediaItems(0)
  msg(selected_items_count .. " items selected")
  
  -- loop through selected items
  for i = 0, selected_items_count-1  do
    -- GET ITEMS
    item = reaper.GetSelectedMediaItem(0, i) -- Get selected item i
    itemIsStereo = false
           
    if item then
      local progressDisplay = "processing item " .. (i+1)
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
     
     
      if (take_source_num_channels == 2) then
      
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
           
           
           -- *** Loop through samples *** ---
           -- Audio accessor code bits by spk77, thanks
           
           
             while sample_count < total_samples do
               if audio_end_reached then
                 break
               end
           
               -- Get a block of samples from the audio accessor.
               -- Samples are extracted immediately pre-FX,
               -- and returned interleaved (first sample of first channel,
               -- first sample of second channel...). Returns 0 if no audio, 1 if audio, -1 on error.
               
               --[[
               Audio accessor rescript example:
               tr = RPR_GetTrack(0, 0)
               aa = RPR_CreateTrackAudioAccessor(tr)
               buf = list([0]*2*1024) # 2 channels, 1024 samples each, initialized to zero
               pos = 0.0
               (ret, buf) = GetAudioAccessorSamples(aa, 44100, 2, pos, 1024, buf)
               # buf now holds the first 2*1024 audio samples from the track.
               # typically GetAudioAccessorSamples() would be called within a loop, increasing pos each time.
               --]]
               
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
               
               -- loop through cur buffer
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
                 local curr_val_left = (buffer[buf_pos_left])
                 -- truncate to x decimals
                 trunc_val_left = trunc(curr_val_left, decimals)
                 
                 local buf_pos_right = i+1 -- right channel, interleaved
                 local curr_val_right = (buffer[buf_pos_right])
                 -- truncate
                 trunc_val_right = trunc(curr_val_right, decimals)
              
                 if (curr_val_left ~= curr_val_right) then
                 
                  -- uncomment here if want to see sample analysis (warning: huge data output)
                  
                  msg("is stereo: ")
                  reaper.ShowConsoleMsg(curr_val_left)
                  reaper.ShowConsoleMsg("\n")
                  reaper.ShowConsoleMsg(curr_val_right)
                  reaper.ShowConsoleMsg("\n")
                  msg("===")
                
                  itemIsStereo = true
                  break
                  end 
                 sample_count = sample_count + 1
               end
               block = block + 1
               offs = offs + samples_per_channel / take_source_sample_rate -- new offset in take source (seconds)
             end -- loop through samples 
             if (itemIsStereo == false) then -- 2-channel item is double-mono
              selItemsTable[tablePos] = item -- store this item in item selection table for later
              tablePos = tablePos+1
              msg("double mono item detected")
            end
          reaper.DestroyAudioAccessor(aa)
      end -- if (take_source_num_channels == 2)
      -- msg("next item")
    end -- if item then
  end -- ENDLOOP through selected items
  reaper.Undo_EndBlock("nofish_Only keep items selected with duplicate mono channels", -1) -- End of the undo block. Leave it at the bottom of your main function.
end -- main()


main()

selectDoubleMonoItems(selItemsTable)
reaper.UpdateArrange()
msg("Done !")

