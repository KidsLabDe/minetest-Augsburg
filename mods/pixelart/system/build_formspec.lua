-- # vim: nowrap
--
-- Set Vim to no-wrapping mode because of some lines not fitting within the 80
-- characters width limit due to overall readability of the code.


-- Build palette buttons
--
--   {
--     width = 2.5,
--     height = 0.5,
--     spacing = 0.125
--     position = { top = 0.25, left = 0.25 }
--   }
--
-- `width` and `height` define the button size and `spacing` the spacing
-- between two buttons. The spacing is actualy the position of the “next”
-- button in the list. The `position` table is not used in THIS function but
-- for positioning the buttons container in `pixelart.build_formspec`
--
-- @see pixelart.build_formspec
-- @param parameters The table as described
-- @return string The parsed button list as formspec string
local get_palette_buttons = function (buttons)
    local buttons_table = {}
    local buttons_string = ''
    local button_position = 0
    local button_spacing = buttons.height + buttons.spacing

    for palette_id in pixelart.sorted_pairs(pixelart.palettes) do
        local button = ('button[0,+p;+w,+h;+i;+l]'):gsub('%+%a+', {
            ['+p'] = button_position,
            ['+w'] = buttons.width,
            ['+h'] = buttons.height,
            ['+i'] = 'palette_'..palette_id,
            ['+l'] = pixelart.palettes[palette_id].name
        })
        table.insert(buttons_table, button)
        button_position = button_position + button_spacing
    end

    buttons_string = table.concat(buttons_table, ' ')
    return 'container[+bleft,+btop]'..buttons_string..'container_end[]'
end


-- Validate the parameters table
--
-- This function takes the input and merges in all missing values in the input
-- table using the validation table as source. The source basically resembles
-- the node formspec.
--
-- @param input A parameters table to validate
-- @return table The validated and completed table
local validate_parameters_table = function (input)
    local valid = {
        formspec = { header = true, version = 2, width = 13, height = 9, for_player = '' },
        buttons = { width = 2.5, height = 0.5, spacing = 0.125, position = { top = 0.25, left = 0.25 } },
        palette = { title = { show = true, position = { top = 0.125+0.25, left = 2.5+0.25+0.25 } } },
        pixels = { size = 0.7, spacing = { left = 0.05, bottom = 0.05 }, position = { top = 0.25+0.25+0.125, left = 3 }, force_per_row = false }
    }
    return pixelart.merge_tables(valid, input)
end


-- Build the formspec based on the given parameters
--
-- The first parameter is the action defined in the interoperability file (see
-- provided files for examples). Basically those actions are references to
-- functions that will be executed when pressing any buttons in the formspec
-- to bring up the formspec again.
--
-- The second parameter is a parameters table as described here:
--
-- parameters_in = {
--   formspec = {
--     header = true,       -- Use formspec header (version & size)
--     version = 2,         -- Formspec version to use
--     width = 13,          -- Formspec width
--     height = 9m          -- Formspec height
--     for_player = 'Name'  -- Generate formspec for this player
--   },
--   buttons = {
--     width = 2.5,      -- Palette selection buttons width
--     height = 0.5,     -- Palette selection buttons height
--     spacing = 0.125,  -- Spacing between palette selection buttons
--     position = {}     -- Palette selection buttons position
--   },
--   palette = {
--     title = {
--       show = true,   -- Whether to show the palette title or not
--       position = {}  -- Position for the palette title
--     }
--   },
--   pixels = {
--     size = 0.7,    -- Size of the pixel buttons
--     position = {}  -- Position of the pixel buttons
--     spacing = {
--       left = 0.05    -- Left spacing of pixel buttons
--       bottom = 0.05  -- Bottom spacing of pixel buttons
--     }
--   }
-- }
--
-- All `position` entries are tables of the same style.
--
-- position = {
--   top = N,  -- Position of the element related to the top of the formspec
--   left = N  -- Position of the element related to the left of the formspec
-- }
--
-- Where `N` is a formspec units value.
--
-- @param action The formspec action to perform when clicking something
-- @param paramneters_in The formspec parameters as described
-- @return string The parsed formspec based on the parameters
pixelart.build_formspec = function (action, parameters_in)
    if not parameters_in.formspec then return '' end
    if not parameters_in.formspec.for_player then return '' end
    local parameters = validate_parameters_table(parameters_in)

    -- Check header usage
    local header = ''
    if parameters.formspec.header == true then
        header = 'formspec_version[+version] size[+width,+height]'
    end

    -- Generate formspec pattern
    local formspec_pattern = table.concat({
        header,
        'field[-1,-1;0,0;action_'..action..';;]',
        get_palette_buttons(parameters.buttons),
        pixelart.get_palette_pixels(parameters),
    }, ' ')

    -- Replace placeholder variables in pattern
    local parsed_formspec = (formspec_pattern):gsub('%+%a+', {
        ['+version'] = parameters.formspec.version,
        ['+width'] = parameters.formspec.width,
        ['+height'] = parameters.formspec.height,
        ['+tleft'] = parameters.palette.title.position.left,
        ['+ttop'] = parameters.palette.title.position.top,
        ['+bleft'] = parameters.buttons.position.left,
        ['+btop'] = parameters.buttons.position.top,
        ['+pleft'] = parameters.pixels.position.left,
        ['+ptop'] = parameters.pixels.position.top,
    })

    return parsed_formspec
end
