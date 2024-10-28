hook.Add("PlayerNoClip", "opsNoclip", function(ply, state)
    if ( hook.Run("CanPlayerEnterObserver", ply) == true ) then
        if ( state ) then
            if ( hook.Run("ShouldHidePlayerObserver", ply) == true ) then
                ply:SetNoDraw(true)
                ply:SetNotSolid(true)
                ply:DrawShadow(false)

                if ( SERVER ) then
                    ply:DrawWorldModel(false)
                    ply:GodEnable()
                    ply:SetNoTarget(true)
                end
            end

            hook.Run("OnPlayerObserve", ply, state)
        else
            ply:SetNoDraw(false)
            ply:SetNotSolid(false)
            ply:DrawShadow(true)

            if ( SERVER ) then
                ply:DrawWorldModel(true)
                ply:GodDisable()
                ply:SetNoTarget(false)
            end

            hook.Run("OnPlayerObserve", ply, state)
        end

        return true
    end

    return false
end)

hook.Add("CanPlayerEnterObserver", "opsNoclip", function(ply)
    return ply:IsAdmin()
end)

hook.Add("ShouldHidePlayerObserver", "opsNoclip", function(ply)
    return ply:GetSyncVar(SYNC_OBSERVER_HIDE, true)
end)