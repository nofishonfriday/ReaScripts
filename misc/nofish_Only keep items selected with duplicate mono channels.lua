--[[
nofish_Only keep items selected with duplicate mono channels.lua
v0.9

works on selected stereo (2-channel) items (1- or more-channel items are ignored) 
checks if left and right channel are 100% identical
--]]




-- DBG
function msg(m)
  if debug == 1 then reaper.ShowConsoleMsg(tostring(m) .. "\n")
  end
end

selItemsTable = {} -- init empty table
tablePos = 1


-- set item selection from selItemsTable
function RestoreSelectedItems (table)
  reaper.Main_OnCommand(40289, 0) -- unsel all items
  for _, item in ipairs(table) do
    reaper.SetMediaItemSelected(item, true)
  end
end





function main()
debug = 1
 

  reaper.Undo_BeginBlock() 
  -- LOOP THROUGH SELECTED ITEMS
  
  selected_items_count = reaper.CountSelectedMediaItems(0)
  
  -- INITIALIZE loop through selected items
  for i = 0, selected_items_count-1  do
    -- GET ITEMS
    item = reaper.GetSelectedMediaItem(0, i) -- Get selected item i
    itemIsStereo = false
        
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
       
    if item then
      
      -- comment for prod
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
     
     
      -- msg(selected_items_count)
      -- msg(take_source_num_channels) 
      if (take_source_num_channels == 2) then
      
      local take_source_sample_rate = reaper.GetMediaSourceSampleRate(take_pcm_source)
           -- How many samples are taken from audio accessor and put in the buffer
           local samples_per_channel = take_source_sample_rate
           -- msg(samples_per_channel)
           -- Samples are collected to this buffer
           local buffer = reaper.new_array(samples_per_channel * take_source_num_channels)
           
           local total_samples = math.ceil((aa_end - aa_start) * take_source_sample_rate)
           local block = 0
           local sample_count = 0
           local audio_end_reached = false
           local offs = aa_start
           
           local abs = math.abs
           
           
           -- *** Loop through samples *** ---
           
             while sample_count < total_samples do
               if audio_end_reached then
                 break
               end
           
               -- Get a block of samples from the audio accessor.
               -- Samples are extracted immediately pre-FX,
               -- and returned interleaved (first sample of first channel,
               -- first sample of second channel...). Returns 0 if no audio, 1 if audio, -1 on error.
               local aa_ret =
                       reaper.GetAudioAccessorSamples(
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
                 local buf_pos_right = i+1 -- right channel, interleaved
                 local curr_val_right = (buffer[buf_pos_right])
                 
                 if (curr_val_left ~= curr_val_right) then
                  -- uncomment here if want to see sample analysis (warning: big data output)
                  --[[
                  msg("is stereo: ")
                  msg(curr_val_left)
                  msg(curr_val_right)
                  msg("===")
                  --]]
                
                  -- reaper.SetMediaItemInfo_Value(item, "B_UISEL", 0)
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
            end
             reaper.DestroyAudioAccessor(aa)
      end -- if (take_source_num_channels == 2)
      -- msg("next item")
    end -- if item then
  end -- ENDLOOP through selected items
  reaper.Undo_EndBlock("nofish_Only keep items selected with duplicate mono channels", -1) -- End of the undo block. Leave it at the bottom of your main function.
end -- main()


main()

RestoreSelectedItems(selItemsTable)
reaper.UpdateArrange() -- Update the arrangement (often needed)
-- reaper.ShowMessageBox("Script executed in (s): "..tostring(reaper.time_precise() - time_os), "", 0)
