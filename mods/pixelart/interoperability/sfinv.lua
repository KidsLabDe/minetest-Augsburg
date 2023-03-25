pixelart.palette_actions['sfinv_page'] = sfinv.set_page


-- Register the sfinv page
--
-- This code registers the sfinv page using the `build_formspec` function. The
-- player object is always the player accessing the sfinv page.
sfinv.register_page(pixelart.modname..':selector', {
    title = pixelart.S('Pixelart'),
    get = function(self, player, context)
        local formspec = pixelart.build_formspec('sfinv_page', {
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
        })
        return sfinv.make_formspec(player, context, formspec, false)
    end
})

