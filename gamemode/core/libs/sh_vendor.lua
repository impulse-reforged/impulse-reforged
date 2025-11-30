impulse.Vendor = impulse.Vendor or {}
impulse.Vendor.Data = impulse.Vendor.Data or {}

function impulse.Vendor:Register(vendor)
    impulse.Vendor.Data[vendor.UniqueID] = vendor
end
