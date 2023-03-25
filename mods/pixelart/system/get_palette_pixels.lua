-- Get pixels and title for requested palette
--
-- This function loads all pixels from the given palette ID and returns them as
-- a string being the clickable buttons for the formspec. The colors are taken
-- from the palette definition as set there and are not sorted any further.
--
-- If the palette does not exist an empty string is returned.
--
-- If requested and available the title of the palette is shown, too.
--
-- @see pixelart.build_formspec
-- @param parameters a parameters table as per `pixelart.build_formspec`
-- @return string The “button string” for the palette formspec
pixelart.get_palette_pixels = function (parameters)
    -- Shorthand for parameter entries
    local formspec = parameters.formspec
    local buttons = parameters.buttons
    local pixels = parameters.pixels

    -- Player data and current palette
    local player_name = formspec.for_player
    local player = minetest.get_player_by_name(player_name)
    local meta = player:get_meta()
    local current_palette = meta:get(pixelart.palette_meta)

    -- Empty string return or preparing palette processing
    if not pixelart.palettes[current_palette] then return '' end
    local palette = pixelart.palettes[current_palette]
    local pixels_table = {}
    local pixels_string = ''

    -- Palette title Processing
    local title_string = ''
    if parameters.palette.title.show == true then
        title_string = ('+c'):gsub('%+%a+', {
            ['+c'] = pixelart.S('Current Palette: @1', palette.name)
        })
    end

    -- Pixel button base positions
    local button_x = 0 -- from left
    local button_y = 0 -- from top
    local buttons_in_row = 1
    local buttons_per_row = pixels.force_per_row

    -- Calculate buttons per row
    if pixels.force_per_row == false then
        local available_width = formspec.width - pixels.position.left
        local button_size = pixels.size + pixels.spacing.left
        buttons_per_row = math.floor(available_width / button_size)
    end

    for _,PixelSpec in pairs(palette.pixels) do
        local color,opacity =  pixelart.color_values(palette, PixelSpec)
        local nodename = pixelart.generate_nodename(current_palette, color)

        local pixel = ('item_image_button[+x,+y;+s,+s;+i;+n;]'):gsub('%+%a+', {
            ['+x'] = button_x,
            ['+y'] = button_y,
            ['+s'] = pixels.size,
            ['+i'] = nodename,
            ['+n'] = 'pixel_'..nodename
        })

        if buttons_in_row < buttons_per_row then
            button_x = button_x + pixels.size + pixels.spacing.left
        else
            button_x = 0
            button_y = button_y + pixels.size + pixels.spacing.bottom
            buttons_in_row = 0
        end

        pixels_table[#pixels_table+1] = pixel
        buttons_in_row = buttons_in_row + 1

        if #pixels_table == 128 then break end
    end

    return table.concat({
        'label[+tleft,+ttop;'..title_string..']',
        'container[+pleft,+ptop]',
        table.concat(pixels_table, ' '),
        'container_end[]'
    }, ' ')
end
