local registered_nodes = minetest.registered_nodes
local chat_send_player = minetest.chat_send_player
local selector_formname = pixelart.modname..':selector'


-- Return the after-palette update action based on the formspec fields
--
-- This function checks the formspec results (the transferred fields) for a
-- field where the ID starts with `action_` and returns the field’s ID without
-- the `action_` part of the string (i.e. returns the desired action).
--
-- @param fields The formspecs transferred fields
-- @return string The determined action
local get_action = function(fields)
    local action = ''

    for id,label in pairs(fields) do
        if id:sub(1, 7) == 'action_' then
            action = id:gsub('action_', '')
        end
    end

    if action == '' then action = 'sfinv' end

    return action
end


-- Register actions for the sfinv page
--
-- When a player interacts with the sfinv page the fields are sent to the
-- server and handled here. There are two actions that are handled depending on
-- the sent fields.
--
-- 1. A player selects a palette. When a palette is selected `fields` contains
--    the palette’s ID in the palette button’s value: `palette_palette_id`.
--    The `palette_` is filtered out and the `palette_id` gets set as player
--    meta value and the sfinv page is reloaded.
--
-- 2. A player selects a pixel. Then a pixel (node) is selected via the item
--    buttons for that the `fields` contains the item’s ID in the field value
--    `pixel_mymod:my_cool_palette_729fcf`. The `pixel_` suffix gets filtered
--    out and depending on mode (creative/survival) and available materials
--    when not in creative mode the node gets added to the player’s inventory
--    if there is enough room for it.
--
-- Both cases are within an iteration over the `fields` entries because how
-- formspecs work. The button value unfortunately always useless so the
-- differentiation is done by parsing the button’s name.
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if not formname == selector_formname then return end
    local meta = player:get_meta()
    local inv = player:get_inventory()
    local name = player:get_player_name()
    local is_creative = minetest.is_yes(minetest.settings:get('creative_mode'))
    local after_selection_action = pixelart.palette_actions[get_action(fields)]

    for id,label in pairs(fields) do
        -- When a palette is selected
        if id:sub(1, 8) == 'palette_' then
            meta:set_string(pixelart.palette_meta, id:gsub('palette_', ''))
            after_selection_action(player, selector_formname)
        end

        -- When a pixel is selected
        if id:sub(1, 6) == 'pixel_' then
            local node_name = id:gsub('pixel_', '')
            local base_node = registered_nodes[node_name]._pixelart.base
            local base_name = registered_nodes[base_node].description
            local has_room =inv:room_for_item('main', node_name)
            local has_base = inv:contains_item('main', base_node)
            local full = pixelart.S('Not enough room for this pixel!')
            local base = pixelart.S('You need @1 for this pixel!', base_name)

            -- Continue when inventory has room for the pixel, give the pixel
            -- when in creative mode or stop when not in creative mode and
            -- missing the base node.
            if not has_room then chat_send_player(name, full) return end
            if is_creative then inv:add_item('main', node_name) return end
            if not has_base then chat_send_player(name, base) return end

            -- At this point the server runs in normal mode and the player has
            -- the needed base node and the player’s inventory has enough room
            -- to store the requested pixel.
            inv:remove_item('main', base_node)
            inv:add_item('main', node_name)
        end
    end
end)
