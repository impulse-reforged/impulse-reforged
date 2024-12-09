screenscale_cache = screenscale_cache or {}

function ScreenScale(size)
    if ( screenscale_cache[size] ) then
        return screenscale_cache[size]
    end

    local scale = size * ( ScrW() / 640 )
    screenscale_cache[size] = scale

    return scale
end

hook.Add("OnScreenSizeChanged", "impulseScreenScaleReset", function()
    screenscale_cache = {}
end)