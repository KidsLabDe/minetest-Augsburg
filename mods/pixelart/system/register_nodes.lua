local log = minetest.log
local logstring = '[pixelart] Palette “+n” loaded with +a colors'


-- Process tiles
--
-- Apply color with given opacity level to the tiles of the base node. The
-- function copies the original tiles so the base node will not be affected
-- in any way.
--
-- @param base_tiles Tiles of the base node
-- @param color The color to be used
-- @param opacity The opacity level (0..255)
-- @return table the processed tiles
local tiles_processor = function (base_tiles, color, opacity)
    local tiles = table.copy(base_tiles)

    local tile_addition = '^[colorize:'..color..':'..opacity

    for id,tiledef in pairs(tiles) do
        if type(tiledef) == 'table' then
            tiles[id].name = '(('..tiledef.name..')'..tile_addition..')'
        else
            tiles[id] = '(('..tiledef..')'..tile_addition..')'
        end
    end

    return tiles
end


-- Register nodes based on palette files
--
-- Ach palette is stored in p.palettes. This code iterates over all of the
-- palettes and registers a node for each of the colors in a palette. There is
-- a maximum of 128 colors per palette. Excess colors are ignored.
--
-- The node ID is generated from the mod name, die palette ID and the color
-- string: `modname:palette_id_color`. For example: The palette with the ID
-- `my_cool_palette` contains a color `#729fcf` then the generated node for
-- this color is `pixelart:my_cool_palette_729fcf`.
--
-- There is also a custom node data entry registered named `_pixelart`. This
-- entry contains a table with relevant information.
--
--   _pixelart = {
--     base = 'mymod:my_cool_node',
--     palette = 'my_cool_palette'
--     color = '#729fcf'
--     opacity = 255
--   }
--
-- This information is used by the function for getting the pixel/node from the
-- sfinv page when not in creative mode.
--
-- There are also two additional groups set:
--
--   pixelart_pixel_node = 1              -- For easily get all pixel nodes
--   pixelart_palette_my_cool_palette = 1 -- For easy palette association
--
-- The _pixelart.palette value and the group association are redundant to allow
-- maximum flexibility (for exampple: allow sorting/filtering by group in
-- advanced inventory management mods).
for palette_id,palette in pairs(pixelart.palettes) do
    local base_node = minetest.registered_nodes[palette.base_node]
    local amount = 0

    for _,PixelSpec in pairs(palette.pixels) do
        local color,opacity = pixelart.color_values(palette, PixelSpec)
        local nodename = pixelart.generate_nodename(palette_id, color)
        local namepart = PixelSpec.name or color

        local node_description = table.concat({
            pixelart.S('Pixel @1', minetest.colorize(color, namepart)),
            pixelart.S('Palette: @1', palette.name)
        }, '\n')

        minetest.register_node(nodename, {
            description = node_description,
            sounds = base_node.sounds,
            _pixelart = {
                base = palette.base_node,
                palette = palette_id,
                color = color,
                opacity = opacity,
            },
            tiles = tiles_processor(base_node.tiles, color, opacity),
            groups = {
                oddly_breakable_by_hand = 1,
                dig_immediate = 3,
                not_in_creative_inventory = 1,
                pixelart_pixel_node = 1,
                ['pixelart_palette_'..palette_id] = 1
            }
        })

        amount = amount + 1
        if amount > 128 then
            amount = 0
            break
        end
    end


    log('info', logstring:gsub('%+%a+', {
        ['+n'] = palette.name,
        ['+a'] = amount,
    }))
end
