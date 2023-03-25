-- Return an indexed table, but sorted
--
-- This function returns a a table iterator iterating over the given table but
-- sorted by the table indexes instead of “randomly” returning the intries
-- basing on whatever is used for determining the order.
--
-- @param t The table to be sorted
-- @return iterator The iterator as described
pixelart.sorted_pairs = function (t)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a)
    local i = 0      -- iterator variable
    local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
    end
    return iter
end


-- Merge two tables
--
-- This function merges all values from `merge_from` into `merge_to`
-- overwriting existing values in `merge_to` with values from `merge_from`
--
-- @param merge_to The table to merge to
-- @param merge_from The table to merge from
-- @return table the merged table as described
pixelart.merge_tables = function (merge_to, merge_from)
    for k,v in pairs(merge_from) do
        if type(v) == 'table' then
            if type(merge_to[k] or false) == 'table' then
                pixelart.merge_tables(merge_to[k] or {}, merge_from[k] or {})
            else
                merge_to[k] = v
            end
        else
            merge_to[k] = v
        end
    end
    return merge_to
end


-- Return opacity and color
--
-- When a palette and a PixelSpec are provided this function returns the
-- color and the opacity value for the given PixelSpec based on the palette.
--
-- @param palette The palette the PixelSpec is from
-- @param PixelSpec The PixelSpec to process
-- @return color,opacity The corresponding color and opacity values
pixelart.color_values = function (palette, PixelSpec)
    local default_opacity = palette.default_opacity or 150
    local default_color = palette.default_color or '#000000'
    local color = PixelSpec.color or default_color
    local opacity = PixelSpec.opacity or default_opacity

    if opacity > 255 then opacity = 255 end
    if opacity < 0 then opacity = 0 end

    return color:lower(),opacity
end


-- Return the node name (ID)
--
-- This function returns the correct node name (ID) for the node defined by
-- the palette_id and the color (no PixelSpec, a simple hex color!).
--
-- @param palette_id A palette ID
-- @param color A simple hex color value
-- @return string The built node name (ID)
pixelart.generate_nodename = function (palette_id, color)
    return ('+modname:+palette_+color'):gsub('%+%a+', {
        ['+modname'] = pixelart.modname,
        ['+palette'] = palette_id,
        ['+color'] = color:gsub('#', '')
    })
end
