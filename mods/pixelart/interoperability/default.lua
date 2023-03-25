local node_name = pixelart.modname..':selector_node'

local pixelart_texture = '(('..table.concat({
    '[combine:32x32',
    '0,0=wool_red.png',
    '0,16=wool_green.png',
    '16,0=wool_blue.png',
    '16,16=wool_yellow.png',
}, ':')..')^[resize:8x8)'

local open_node_formspec = function (player, formname)
    local player_name = player:get_player_name()

    local formspec = pixelart.build_formspec('selector_node', {
        formspec = {
            header = true,
            version = 2,
            width = 13,
            height = 9,
            for_player = player_name
        },
        buttons = {
            width = 2.5,
            height = 0.5,
            spacing = 0.125,
            position = { top = 0.25, left = 0.25 }
        },
        palette = {
            title = {
                show = true,
                position = { top = 0.125+0.25, left = 2.5+0.25+0.25 }
            }
        },
        pixels = {
            size = 0.7,
            spacing = { left = 0.05, bottom = 0.05 },
            position = { top = 0.25+0.25+0.125, left = 3 }
        }
    })

    minetest.show_formspec(player_name, 'pixelart:selector', formspec)
end

pixelart.palette_actions['selector_node'] = open_node_formspec


minetest.register_node(':'..node_name, {
    description = pixelart.S('Pixelart'),
    groups = { oddly_breakable_by_hand = 1 },
    sounds = default.node_sound_defaults(),
    on_rightclick = function(pos, node, clicker)
        open_node_formspec(clicker, pixelart.modname..':selector')
    end,
    tiles = { pixelart_texture },
})


minetest.register_craft({
    output = node_name,
    recipe = {
        { 'wool:red',   'wool:blue',   '' },
        { 'wool:green', 'wool:yellow', '' },
        { '',           '',            '' }
    }
})
