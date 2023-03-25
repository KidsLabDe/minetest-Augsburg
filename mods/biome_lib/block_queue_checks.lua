-- Iterate through the mapblock log,
-- populating blocks with new stuff in the process.

minetest.register_globalstep(function(dtime)
	if not biome_lib.block_log[1] then return end -- the block log is empty

	if math.random(100) > biome_lib.queue_ratio then return end
	for s = 1, biome_lib.entries_per_step do
		biome_lib.generate_block()
	end
end)

-- Periodically wake-up the queue to give old blocks a chance to time-out
-- if the player isn't currently exploring (i.e. they're just playing in one area)

function biome_lib.wake_up_queue()
	if #biome_lib.block_recheck_list > 1
	  and #biome_lib.block_log == 0 then
		biome_lib.block_log[#biome_lib.block_log + 1] =
			table.copy(biome_lib.block_recheck_list[#biome_lib.block_recheck_list])
		biome_lib.block_recheck_list[#biome_lib.block_recheck_list] = nil
		biome_lib.run_block_recheck_list = true
		biome_lib.dbg("Woke-up the map queue to give old blocks a chance to time-out.", 3)
	end
	minetest.after(biome_lib.block_queue_wakeup_time, biome_lib.wake_up_queue)
end

biome_lib.wake_up_queue()

-- Play out the entire log all at once on shutdown
-- to prevent unpopulated map areas

local function format_time(t)
	if t > 59999999 then
		return os.date("!%M minutes and %S seconds", math.ceil(t/1000000))
	else
		return os.date("!%S seconds", math.ceil(t/1000000))
	end
end

function biome_lib.check_remaining_time()
	if minetest.get_us_time() > (biome_lib.shutdown_last_timestamp + 10000000) then -- report progress every 10s
		biome_lib.shutdown_last_timestamp = minetest.get_us_time()

		local entries_remaining = #biome_lib.block_log + #biome_lib.block_recheck_list

		local total_purged = biome_lib.starting_count - entries_remaining
		local elapsed_time = biome_lib.shutdown_last_timestamp - biome_lib.shutdown_start_time
		biome_lib.dbg(string.format("%i entries, approximately %s remaining.",
			entries_remaining, format_time(elapsed_time/total_purged * entries_remaining)))
	end
end

--Purge the block log at shutdown

minetest.register_on_shutdown(function()

	biome_lib.shutdown_start_time = minetest.get_us_time()
	biome_lib.shutdown_last_timestamp = minetest.get_us_time()+1

	biome_lib.starting_count = #biome_lib.block_log + #biome_lib.block_recheck_list

	if biome_lib.starting_count == 0 then
		return
	end

	biome_lib.dbg("Stand by, purging the mapblock log "..
		"(there are "..biome_lib.starting_count.." entries) ...", 0)

	while #biome_lib.block_log > 0 do
		biome_lib.generate_block(true)
		biome_lib.check_remaining_time()
	end

	if #biome_lib.block_recheck_list > 0 then
		biome_lib.block_log = table.copy(biome_lib.block_recheck_list)
		biome_lib.block_recheck_list = {}
		while #biome_lib.block_log > 0 do
			biome_lib.generate_block(true)
			biome_lib.check_remaining_time()
		end
	end
	biome_lib.dbg("Log purge completed after "..
		format_time(minetest.get_us_time() - biome_lib.shutdown_start_time)..".", 0)
end)

-- "Record" the map chunks being generated by the core mapgen,
-- split into individual mapblocks to reduce lag

minetest.register_on_generated(function(minp, maxp, blockseed)
	local timestamp = minetest.get_us_time()
	for y = 0, 4 do
		local miny = minp.y + y*16

		if miny >= biome_lib.mapgen_elevation_limit.min
		  and (miny + 15) <= biome_lib.mapgen_elevation_limit.max then

			for x = 0, 4 do
				local minx = minp.x + x*16

				for z = 0, 4 do
					local minz = minp.z + z*16

					local bmin = {x=minx, y=miny, z=minz}
					local bmax = {x=minx + 15, y=miny + 15, z=minz + 15}
					biome_lib.block_log[#biome_lib.block_log + 1] = { bmin, bmax, true, timestamp }
					biome_lib.block_log[#biome_lib.block_log + 1] = { bmin, bmax, false, timestamp }
				end
			end
		else
			biome_lib.dbg("Did not enqueue mapblocks at elevation "..miny..
					"m, they're out of range of any generate_plant() calls.", 4)
		end
	end
	biome_lib.run_block_recheck_list = true
end)

if biome_lib.debug_log_level >= 3 then
	biome_lib.last_count = 0

	function biome_lib.show_pending_block_count()
		if biome_lib.last_count ~= #biome_lib.block_log then
			biome_lib.dbg(string.format("Pending block counts - ready to process: %-8icurrently deferred: %i",
				#biome_lib.block_log, #biome_lib.block_recheck_list), 3)
			biome_lib.last_count = #biome_lib.block_log
			biome_lib.queue_idle_flag = false
		elseif not biome_lib.queue_idle_flag then
			if #biome_lib.block_recheck_list > 0 then
				biome_lib.dbg("Mapblock queue only contains blocks that can't yet be processed.",  3)
				biome_lib.dbg("Idling the queue until new blocks arrive or the next wake-up call occurs.",  3)
			else
				biome_lib.dbg("Mapblock queue has run dry.",  3)
				biome_lib.dbg("Idling the queue until new blocks arrive.",  3)
			end
			biome_lib.queue_idle_flag = true
		end
		minetest.after(1, biome_lib.show_pending_block_count)
	end

	biome_lib.show_pending_block_count()
end
