impulse.Vendor = impulse.Vendor or {}
impulse.Vendor.Data = impulse.Vendor.Data or {}

function impulse.Vendor:Register(vendor)
    if ( !vendor or type(vendor) != "table" ) then
        error("Vendor is not a table!")
        return
    end

    if ( !vendor.UniqueID ) then
        error("Vendor is missing a UniqueID!")
        return
    end

    impulse.Vendor.Data[vendor.UniqueID] = vendor
end
