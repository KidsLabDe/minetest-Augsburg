-- Localize/Set relevant variables
local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)..DIR_DELIM
local worldpath = minetest.get_worldpath()..DIR_DELIM
local syspath = modpath..'system'..DIR_DELIM
local interpath = modpath..'interoperability'..DIR_DELIM
local palettes_path = modpath..'palettes'..DIR_DELIM
local worldpath_subdirectory = worldpath..'_'..modname..DIR_DELIM
local world_palettes = worldpath_subdirectory..'palettes'..DIR_DELIM
local world_customization = worldpath_subdirectory..'customization'..DIR_DELIM
local get_dir_list = minetest.get_dir_list


-- Initialize global table
pixelart = {
    modname = modname,
    S = minetest.get_translator(modname),
    palette_meta = modname..':palette',
    palettes = {},
    palette_actions = {}
}


-- Load built-in palettes
for _,palette_file in pairs(get_dir_list(palettes_path, false)) do
    local palette = dofile(palettes_path..palette_file)
    local id = palette_file:gsub('%.lua', '')
    pixelart.palettes[id] = palette
end


-- Load world-specific palettes
for _,palette_file in pairs(get_dir_list(world_palettes, false)) do
    local palette = dofile(world_palettes..palette_file)
    local id = palette_file:gsub('%.lua', '')
    if #palette.pixels == 0 then
        pixelart.palettes[id] = nil
    else
        palette.name = palette.name..' (w)'
        pixelart.palettes[id] = palette
    end
end


-- Convert all ColorSpoecs to tables
for palette_id,palette in pairs(pixelart.palettes) do
    local conv = {}
    for _,ps in pairs(palette.pixels) do
        if type(ps) == 'string' then table.insert(conv, { color = ps}) end
        if type(ps) == 'table' then table.insert(conv, ps) end
    end
    pixelart.palettes[palette_id].pixels = conv
end


-- Apply world-specific customization
for _,customization_file in pairs(get_dir_list(world_customization, false)) do
    local c = dofile(world_customization..customization_file)
    local id = customization_file:gsub('%.lua', '')
    local target = pixelart.palettes[id]
    local basenode_ok = c.base_node and minetest.registered_nodes[c.base_node]
    local logline = '[pixelart] Applied +amount +mods for palette "+palette"'
    local amount = 0

    if c.name then target.name = c.name end
    if basenode_ok then target.base_node = c.base_node end
    if c.default_opacity then target.default_opacity = c.default_opacity end

    for _,target_ps in pairs(target.pixels) do
        for color,changes in pairs(c.pixels) do
            if target_ps.color:lower() == color:lower() then
                amount = amount + 1
                for key,value in pairs(changes) do
                    target_ps[key] = value
                end
            end
        end
    end

    minetest.log('action', logline:gsub('%+%w+', {
        ['+amount'] = amount,
        ['+palette'] = id,
        ['+mods'] = amount == 1 and 'modification' or 'modifications'
    }))
end


-- Initialize mod files
for _,system_file in pairs(get_dir_list(syspath, false)) do
    if system_file ~= 'register_nodes.lua' then
        minetest.log('verbose', '[pixelart] Loading mod file '..system_file)
        dofile(syspath..system_file)
    end
end


-- Register the nodes pased on the palettes
minetest.log('action', '[pixelart] Registering nodes from pixels')
dofile(syspath..'register_nodes.lua')


-- Initialize interoperability files after all mods are loaded. Doing so allows
-- for “arbitrary” mods being supported by the i14y functionality withoiut
-- having to opt-depend on all of them.
minetest.register_on_mods_loaded(function()
    for _,i14y_file in pairs(get_dir_list(interpath, false)) do
        local mod = i14y_file:gsub('%.lua', '')
        local logline = '[pixelart] loaded additional support for +m'
        if minetest.get_modpath(i14y_file:gsub('%.lua', '')) ~= nil then
            dofile(interpath..i14y_file)
            minetest.log('action', logline:gsub('%+m', mod))
        end
    end
end)


-- Log loaded state with pixel counter
local pixels = 0
for id,def in pairs(minetest.registered_nodes) do
    if def.groups.pixelart_pixel_node then pixels = pixels + 1 end
end
minetest.log('action', '[pixelart] Mod loaded with '..pixels..' pixels')
