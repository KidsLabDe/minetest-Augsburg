pixelart.palette_actions['ui_page'] = unified_inventory.set_inventory_formspec


local pixelart_texture = '(('..table.concat({
    '[combine:32x32',
    '0,0=wool_red.png',
    '0,16=wool_green.png',
    '16,0=wool_blue.png',
    '16,16=wool_yellow.png',
}, ':')..')^[resize:16x16)'


-- Register the selector page
unified_inventory.register_page('pixelart:selector', {
    get_formspec = function(player)
        return {
            formspec = pixelart.build_formspec('ui_page', {
                formspec = {
                    header = false,
                    for_player = player:get_player_name()
                },
                buttons = {
                    width = 1.85,
                    height = 1,
                    spacing = -1+0.8,
                    position = { top = -0.125, left = 0 }
                },
                palette = {
                    title = {
                        show = true,
                        position = { top = 0.3-0.45, left = 1.85 }
                    }
                },
                pixels = {
                    size = 0.75,
                    spacing = { left = -0.2, bottom = -0.125 },
                    position = { top = 0.4125, left = 1.83 },
                    force_per_row = 11
                }
            }),
            draw_inventory = false
        }
    end,
})


-- Register the button that opens the selector page
unified_inventory.register_button('pixelart:selector', {
    type = 'image',
    image = minetest.inventorycube(pixelart_texture),
    tooltip = pixelart.S('Pixelart'),
})
