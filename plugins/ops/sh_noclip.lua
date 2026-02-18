hook.Add("PlayerNoClip", "opsNoclip", function(client, state)
    if ( hook.Run("CanPlayerEnterObserver", client) == true ) then
        if ( state ) then
            if ( hook.Run("ShouldHidePlayerObserver", client) == true ) then
                client:SetNoDraw(true)
                client:SetNotSolid(true)
                client:DrawShadow(false)

                if ( SERVER ) then
                    client:DrawWorldModel(false)
                    client:GodEnable()
                    client:SetNoTarget(true)
                end
            end

            hook.Run("OnPlayerObserve", client, state)
        else
            client:SetNoDraw(false)
            client:SetNotSolid(false)
            client:DrawShadow(true)

            if ( SERVER ) then
                client:DrawWorldModel(true)
                client:GodDisable()
                client:SetNoTarget(false)
            end

            hook.Run("OnPlayerObserve", client, state)
        end

        return true
    end

    return false
end)

hook.Add("CanPlayerEnterObserver", "opsNoclip", function(client)
    return client:HasPrivilege("impulse: Noclip")
end)

hook.Add("ShouldHidePlayerObserver", "opsNoclip", function(client)
    return client:GetRelay("observerHide", true)
end)
